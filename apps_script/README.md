# Google Apps Script backend

Copy all of [`Code.gs`](Code.gs) into the single `Code.gs` file of a new Apps Script project. Set `APP_CONFIG.spreadsheetId` to the ID in the Google Sheets URL, then deploy the script as an HTTPS web app that executes as the spreadsheet owner.

The API actions are `health`, `login`, `getDashboard`, `submitAttendance`, and `logout`. The Flutter app uses public `health` only to validate a manually entered web-app `/exec` URL before Login. Protected actions require the `username`, `device_id`, and `session_token` returned by `login`.

The backend is the source of truth for server time, scanner state, QR/BSSID checks, device binding, sessions, and duplicate attendance protection.
