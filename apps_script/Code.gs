/**
 * QR Attendance backend — complete single-file Google Apps Script API.
 *
 * Paste this file into Code.gs, set spreadsheetId below, then deploy as a Web app.
 * The spreadsheet remains private; this script runs as its owner.
 */

const APP_CONFIG = {
  // From: https://docs.google.com/spreadsheets/d/THIS_IS_THE_ID/edit
  spreadsheetId: 'PASTE_YOUR_SPREADSHEET_ID_HERE',
  sheetNames: { members: 'Members', attendance: 'Attendance', settings: 'Settings' },
  requiredHeaders: {
    members: ['username', 'pin', 'device_id', 'active', 'created_at'],
    attendance: ['timestamp', 'date', 'username', 'arrival_time', 'difference_minutes', 'status', 'device_id', 'bssid'],
    settings: ['key', 'value']
  },
  sessionLifetimeHours: 24 * 30,
  historyLimit: 31
};

const WORKER_MESSAGES = {
  invalidAccount: 'Invalid account or device',
  attendanceFailure: 'Fail, check your QR or Wifi network connected',
  networkFailure: 'Unable to connect. Please try again.',
  recorded: 'Recorded'
};

function doPost(e) {
  try {
    const request = parseRequest_(e);
    switch (request.action) {
      case 'login': return jsonResponse_(login_(request));
      case 'getDashboard': return jsonResponse_(getDashboard_(request));
      case 'submitAttendance': return jsonResponse_(submitAttendance_(request));
      case 'logout': return jsonResponse_(logout_(request));
      default: return jsonResponse_({ success: false, message: WORKER_MESSAGES.networkFailure });
    }
  } catch (error) {
    console.error(error && error.stack ? error.stack : error);
    return jsonResponse_({ success: false, message: WORKER_MESSAGES.networkFailure });
  }
}

/** Request: action, username, pin, device_id. */
function login_(request) {
  const username = normaliseUsername_(request.username);
  const pin = stringValue_(request.pin);
  const deviceId = stringValue_(request.device_id);
  if (!username || !pin || !deviceId) return invalidAccount_();

  const lock = LockService.getScriptLock();
  lock.waitLock(30000);
  try {
    const members = readTable_('members');
    const member = findMember_(members.rows, username);
    if (!member || !isActive_(member.active) || stringValue_(member.pin) !== pin) return invalidAccount_();

    const savedDeviceId = stringValue_(member.device_id);
    if (savedDeviceId && savedDeviceId !== deviceId) return invalidAccount_();
    if (!savedDeviceId) writeCell_(members.sheet, member.rowNumber, members.headerIndex.device_id, deviceId);

    return {
      success: true,
      message: 'Login successful',
      session_token: createSession_(username, deviceId),
      user: { username: username }
    };
  } finally {
    lock.releaseLock();
  }
}

/** Request: action, username, device_id, session_token. */
function getDashboard_(request) {
  const session = validateSession_(request);
  if (!session) return invalidAccount_();

  const settings = getSettings_();
  const now = new Date();
  const todayDate = formatDate_(now, settings.timezone, 'yyyy-MM-dd');
  const serverTime = formatDate_(now, settings.timezone, 'HH:mm');
  const rows = readTable_('attendance').rows.filter(function(row) {
    return normaliseUsername_(row.username) === session.username;
  });
  const today = rows.find(function(row) {
    return normaliseDate_(row.date, settings.timezone) === todayDate;
  });
  const monthRows = rows.filter(function(row) {
    return normaliseDate_(row.date, settings.timezone).indexOf(todayDate.substring(0, 7)) === 0;
  });

  return {
    success: true,
    user: { username: session.username },
    server: { date: todayDate, time: serverTime, scanner_open: !today && isAtOrAfter_(serverTime, settings.scannerOpenTime) },
    today: today ? Object.assign({ recorded: true }, attendancePayload_(today)) :
      { recorded: false, arrival_time: null, status: null, minutes: 0 },
    month: calculateMonthStats_(monthRows),
    history: rows.slice().sort(newestFirst_).slice(0, APP_CONFIG.historyLimit).map(attendancePayload_)
  };
}

/** Request: action, username, device_id, session_token, qr_data, bssid. */
function submitAttendance_(request) {
  if (!validateSession_(request)) return attendanceFailure_();
  const submittedQr = stringValue_(request.qr_data);
  const submittedBssid = normaliseBssid_(request.bssid);
  if (!submittedQr || !submittedBssid) return attendanceFailure_();

  const lock = LockService.getScriptLock();
  lock.waitLock(30000);
  try {
    const session = validateSession_(request); // Re-check under the write lock.
    if (!session) return attendanceFailure_();

    const settings = getSettings_();
    const now = new Date();
    const todayDate = formatDate_(now, settings.timezone, 'yyyy-MM-dd');
    const serverTime = formatDate_(now, settings.timezone, 'HH:mm');
    const attendance = readTable_('attendance');
    const existing = attendance.rows.find(function(row) {
      return normaliseUsername_(row.username) === session.username &&
        normaliseDate_(row.date, settings.timezone) === todayDate;
    });

    // Network retries and repeat scans never create another attendance row.
    if (existing) {
      return { success: true, message: WORKER_MESSAGES.recorded, duplicate: true, attendance: attendancePayload_(existing) };
    }

    if (!isAtOrAfter_(serverTime, settings.scannerOpenTime) ||
        submittedQr !== settings.qrToken || settings.allowedBssids.indexOf(submittedBssid) === -1) {
      return attendanceFailure_();
    }

    const result = calculateArrival_(serverTime, settings.reportingTime);
    const record = {
      timestamp: formatDate_(now, settings.timezone, 'yyyy-MM-dd HH:mm:ss'),
      date: todayDate,
      username: session.username,
      arrival_time: result.arrival_time,
      difference_minutes: result.minutes,
      status: result.status,
      device_id: session.deviceId,
      bssid: submittedBssid
    };
    appendObjectRow_(attendance.sheet, attendance.headers, record);
    return { success: true, message: WORKER_MESSAGES.recorded, attendance: result };
  } finally {
    lock.releaseLock();
  }
}

/** Request: action, session_token. */
function logout_(request) {
  const token = stringValue_(request.session_token);
  if (token) PropertiesService.getScriptProperties().deleteProperty(sessionKey_(token));
  return { success: true, message: 'Logged out' };
}

function parseRequest_(e) {
  if (!e || !e.postData || !e.postData.contents) throw new Error('Missing JSON request body.');
  const request = JSON.parse(e.postData.contents);
  if (!request || typeof request !== 'object') throw new Error('Invalid JSON request body.');
  return request;
}

function jsonResponse_(payload) {
  return ContentService.createTextOutput(JSON.stringify(payload))
    .setMimeType(ContentService.MimeType.JSON);
}

function getSettings_() {
  const settings = {};
  readTable_('settings').rows.forEach(function(row) {
    const key = stringValue_(row.key);
    if (key) settings[key] = stringValue_(row.value);
  });
  const allowedBssids = Object.keys(settings)
    .filter(function(key) { return key.indexOf('allowed_bssid_') === 0; })
    .map(function(key) { return normaliseBssid_(settings[key]); })
    .filter(Boolean);
  const qrToken = stringValue_(settings.qr_token);
  if (!qrToken || !allowedBssids.length) throw new Error('Settings require qr_token and an allowed_bssid_ value.');
  return {
    timezone: stringValue_(settings.timezone) || 'Asia/Kolkata',
    reportingTime: validateTime_(settings.reporting_time, 'reporting_time'),
    scannerOpenTime: validateTime_(settings.scanner_open_time, 'scanner_open_time'),
    qrToken: qrToken,
    allowedBssids: allowedBssids
  };
}

function validateSession_(request) {
  const username = normaliseUsername_(request.username);
  const deviceId = stringValue_(request.device_id);
  const token = stringValue_(request.session_token);
  if (!username || !deviceId || !token) return null;

  const properties = PropertiesService.getScriptProperties();
  const stored = properties.getProperty(sessionKey_(token));
  if (!stored) return null;
  let session;
  try { session = JSON.parse(stored); } catch (error) { properties.deleteProperty(sessionKey_(token)); return null; }
  if (session.expiresAt <= Date.now() || session.username !== username || session.deviceId !== deviceId) {
    properties.deleteProperty(sessionKey_(token));
    return null;
  }

  const member = findMember_(readTable_('members').rows, username);
  if (!member || !isActive_(member.active) || stringValue_(member.device_id) !== deviceId) {
    properties.deleteProperty(sessionKey_(token));
    return null;
  }
  return { username: username, deviceId: deviceId };
}

function createSession_(username, deviceId) {
  cleanupExpiredSessions_();
  const token = Utilities.getUuid().replace(/-/g, '') + Utilities.getUuid().replace(/-/g, '');
  PropertiesService.getScriptProperties().setProperty(sessionKey_(token), JSON.stringify({
    username: username,
    deviceId: deviceId,
    expiresAt: Date.now() + APP_CONFIG.sessionLifetimeHours * 60 * 60 * 1000
  }));
  return token;
}

function cleanupExpiredSessions_() {
  const properties = PropertiesService.getScriptProperties();
  Object.keys(properties.getProperties()).forEach(function(key) {
    if (key.indexOf('session:') !== 0) return;
    try {
      if (JSON.parse(properties.getProperty(key)).expiresAt <= Date.now()) properties.deleteProperty(key);
    } catch (error) { properties.deleteProperty(key); }
  });
}

function sessionKey_(token) { return 'session:' + token; }

function readTable_(tableName) {
  const sheet = getSheet_(tableName);
  // Reads what Sheets displays. Format the Members pin column as Plain text if a PIN starts with 0.
  const values = sheet.getDataRange().getDisplayValues();
  if (!values.length || !values[0].length) throw new Error('Missing headers in ' + APP_CONFIG.sheetNames[tableName] + '.');
  const headers = values[0].map(stringValue_);
  const headerIndex = {};
  headers.forEach(function(header, index) { if (header) headerIndex[header] = index + 1; });
  APP_CONFIG.requiredHeaders[tableName].forEach(function(header) {
    if (!headerIndex[header]) throw new Error('Missing ' + header + ' column in ' + APP_CONFIG.sheetNames[tableName] + '.');
  });
  const rows = values.slice(1).map(function(row, index) {
    const item = { rowNumber: index + 2 };
    headers.forEach(function(header, column) { item[header] = stringValue_(row[column]); });
    return item;
  }).filter(function(row) {
    return headers.some(function(header) { return Boolean(row[header]); });
  });
  return { sheet: sheet, headers: headers, headerIndex: headerIndex, rows: rows };
}

function getSheet_(tableName) {
  if (!APP_CONFIG.spreadsheetId || APP_CONFIG.spreadsheetId === 'PASTE_YOUR_SPREADSHEET_ID_HERE') {
    throw new Error('Set APP_CONFIG.spreadsheetId before deployment.');
  }
  const sheet = SpreadsheetApp.openById(APP_CONFIG.spreadsheetId).getSheetByName(APP_CONFIG.sheetNames[tableName]);
  if (!sheet) throw new Error('Missing required tab: ' + APP_CONFIG.sheetNames[tableName]);
  return sheet;
}

function findMember_(rows, username) {
  return rows.find(function(row) { return normaliseUsername_(row.username) === username; });
}

function writeCell_(sheet, row, column, value) { sheet.getRange(row, column).setValue(value); }
function appendObjectRow_(sheet, headers, record) {
  sheet.appendRow(headers.map(function(header) { return Object.prototype.hasOwnProperty.call(record, header) ? record[header] : ''; }));
}

function calculateArrival_(arrivalTime, reportingTime) {
  const difference = timeToMinutes_(arrivalTime) - timeToMinutes_(reportingTime);
  if (difference < 0) return { arrival_time: arrivalTime, status: 'EARLY', minutes: Math.abs(difference) };
  if (difference > 0) return { arrival_time: arrivalTime, status: 'LATE', minutes: difference };
  return { arrival_time: arrivalTime, status: 'ON_TIME', minutes: 0 };
}

function calculateMonthStats_(rows) {
  return rows.reduce(function(stats, row) {
    const minutes = Number(row.difference_minutes) || 0;
    if (stringValue_(row.status).toUpperCase() === 'LATE') { stats.late_days++; stats.late_minutes += minutes; }
    if (stringValue_(row.status).toUpperCase() === 'EARLY') { stats.early_days++; stats.early_minutes += minutes; }
    return stats;
  }, { late_minutes: 0, late_days: 0, early_minutes: 0, early_days: 0 });
}

function attendancePayload_(row) {
  return { date: stringValue_(row.date), arrival_time: stringValue_(row.arrival_time), status: stringValue_(row.status).toUpperCase(), minutes: Number(row.difference_minutes) || 0 };
}

function newestFirst_(a, b) {
  return (stringValue_(b.timestamp) || stringValue_(b.date)).localeCompare(stringValue_(a.timestamp) || stringValue_(a.date));
}
function isAtOrAfter_(actual, threshold) { return timeToMinutes_(actual) >= timeToMinutes_(threshold); }
function timeToMinutes_(time) {
  const match = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(stringValue_(time));
  if (!match) throw new Error('Invalid 24-hour time: ' + time);
  return Number(match[1]) * 60 + Number(match[2]);
}
function validateTime_(time, setting) {
  const value = stringValue_(time);
  if (!/^([01]\d|2[0-3]):([0-5]\d)$/.test(value)) throw new Error(setting + ' must use HH:mm.');
  return value;
}
function normaliseUsername_(value) { return stringValue_(value).toLowerCase(); }
function normaliseBssid_(value) { return stringValue_(value).toUpperCase().replace(/-/g, ':'); }
function normaliseDate_(value, timezone) {
  const text = stringValue_(value);
  if (/^\d{4}-\d{2}-\d{2}$/.test(text)) return text;
  const parsed = new Date(text);
  return isNaN(parsed.getTime()) ? text : formatDate_(parsed, timezone, 'yyyy-MM-dd');
}
function isActive_(value) { return ['TRUE', 'YES', '1'].indexOf(stringValue_(value).toUpperCase()) !== -1; }
function formatDate_(date, timezone, pattern) { return Utilities.formatDate(date, timezone, pattern); }
function stringValue_(value) { return value === null || value === undefined ? '' : String(value).trim(); }
function invalidAccount_() { return { success: false, message: WORKER_MESSAGES.invalidAccount }; }
function attendanceFailure_() { return { success: false, message: WORKER_MESSAGES.attendanceFailure }; }
