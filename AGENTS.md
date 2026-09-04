# QR Attendance App — Project Instructions

This file is the project source of truth. Keep the implementation small, straightforward, and production-friendly. Do not add features outside this specification unless the user explicitly requests them.

## Product scope

Build a Flutter employee-attendance app backed by a Google Apps Script JSON API and one Google Spreadsheet. The spreadsheet is the permanent database. Users are predefined, each account is bound to one device after its first successful login, the shop uses one fixed QR code, and attendance is allowed only from one of the configured Wi-Fi BSSIDs.

V1 has exactly two main screens:

1. Login
2. Home / Dashboard

The QR scanner and current-month statistics belong directly on the dashboard. Do not add separate scanner, reports, registration, payroll, leave, shifts, sign-out, or employee-management screens. Do not add bottom navigation or unnecessary tabs.

## Required stack and architecture

- Flutter for the mobile app.
- Google Apps Script for the backend API.
- Google Sheets for storage.
- One simple state-management approach.
- No unnecessary Clean Architecture, repository layers, BLoC complexity, or multiple state-management abstractions.

Keep Google Sheets, Apps Script, Flutter, the two-screen UX, server-side validation, one-device-per-user, fixed QR and BSSID validation, the 07:00 scanner rule, and current-month-only dashboard analytics.

Do not add Firebase Authentication, Firestore, Cloud Run, WordPress, GPS, geofencing, maps, face recognition, biometric attendance, dynamic QR codes, complex anti-tamper measures, or other HR features.

## Core attendance behavior

- Before 07:00 Asia/Kolkata, the scanner is closed.
- At or after 07:00, the scanner is open until that day's attendance is successfully recorded.
- A successful attendance record closes the scanner immediately.
- The scanner may open again only at 07:00 the next day.
- There is no midday or other closing time.
- The backend is always the source of truth for scanner state and whether today's attendance exists; never rely only on Flutter local state or time.
- Enforce at most one attendance record per username and server date, including during retries, restarts, reinstalls, and local-state corruption.

When the dashboard opens, call `getDashboard`. Render scanner availability from `server.scanner_open` and `today.recorded`. Refresh the dashboard after a successful submission.

## Attendance validation

Flutter submits:

```text
username
device_id
qr_data
current_bssid
```

The backend must verify all of these before inserting an attendance row:

1. The username exists.
2. The account is active.
3. The submitted device ID matches the bound device ID.
4. The QR content matches the configured fixed token.
5. The current BSSID matches one of the allowed shop BSSIDs.
6. No attendance record already exists for that username and the current server date.
7. Server time is at or after the configured scanner opening time.

Use Apps Script server time in the `Asia/Kolkata` timezone. Never trust a timestamp supplied by Flutter.

On success, return and display exactly `Recorded`, refresh dashboard data, and hide the scanner. On QR, BSSID, or attendance validation failure, create no row, keep the scanner available when otherwise eligible, and display exactly `Fail, check your QR or Wifi network connected`. For network errors, display `Unable to connect. Please try again.` Do not expose validation details, stack traces, or raw backend errors to workers; detailed reasons may be logged internally.

If a duplicate already exists, do not insert another row. Return the existing attendance state and keep the scanner closed.

## Reporting-time calculation

The fixed reporting baseline is 09:00 Asia/Kolkata:

- 08:52 is `EARLY`, 8 minutes.
- 09:00 is `ON_TIME`, 0 minutes.
- 09:07 is `LATE`, 7 minutes.

Store absolute `difference_minutes`, with `status` determining early versus late. Use this convention consistently in the backend and Flutter app.

## Authentication and device binding

Users are predefined in the `Members` sheet. There is no registration, OTP, forgot-password flow, or self-service account creation.

At login, validate username, the configured numeric PIN, active status, and the persistent device identifier. This project deliberately stores numeric PINs as plain values in the private spreadsheet; do not add a separate display-name field or PIN-hashing layer unless explicitly requested later.

- If the stored `device_id` is empty, bind it to the submitted ID and allow login.
- If it matches, allow login.
- If it differs, reject login with `Invalid account or device`.

Generate the installation/device identifier once, store it securely, and reuse it for every request. This is casual device locking, not high-security hardware fingerprinting. Store session/authentication information securely and keep the user signed in unless they explicitly log out. An administrator may manually clear `device_id` in Google Sheets to permit a replacement phone.

## Spreadsheet schema

Use one spreadsheet with exactly these tabs; do not add an Analytics tab:

### `Members`

| Column | Purpose |
|---|---|
| `username` | Unique predefined login |
| `pin` | Plain numeric PIN |
| `device_id` | Bound installation/device ID |
| `active` | `TRUE` or `FALSE` |
| `created_at` | Optional creation timestamp |

### `Attendance`

| Column | Purpose |
|---|---|
| `timestamp` | Full server timestamp |
| `date` | Server attendance date |
| `username` | User account |
| `arrival_time` | Human-readable arrival time |
| `difference_minutes` | Absolute early/late minutes |
| `status` | `EARLY`, `LATE`, or `ON_TIME` |
| `device_id` | Submitted device ID |
| `bssid` | Submitted Wi-Fi BSSID |

### `Settings`

Use a key/value layout with at least:

```text
shop_name          Jeune Fashion
reporting_time     09:00
scanner_open_time  07:00
timezone           Asia/Kolkata
qr_token           fixed_secret_token_here
allowed_bssid_1    AA:BB:CC:11:22:33
allowed_bssid_2    AA:BB:CC:11:22:44
allowed_bssid_3    AA:BB:CC:11:22:55
```

Support one or more allowed BSSIDs. BSSID is the Wi-Fi security identifier; SSID is not required for validation. Request only the minimum Android permissions needed by the chosen Flutter implementation.

## Fixed QR content

Use one permanent printed QR code. A suitable format is:

```text
JFATTEND:v1:SHOP01:<long-random-token>
```

The initial fixed QR value is:

```text
JFATTEND:v1:SHOP01:JralxmcP8pbWY2KGeeGXfd4NwYITcgtOVLYcGxOXJLQ
```

Store this exact full value as `qr_token` in the Settings sheet and encode this exact full value in the printed QR image. Do not alter it after the app is deployed unless the Settings value and printed QR are replaced together.

It contains an app identifier, version, shop identifier, and a long random token. It must not contain a username, user ID, timestamp, or current date. Validate it against the Settings value on the backend.

## Backend API

A single `doPost(e)` router may expose these actions:

```text
login
getDashboard
submitAttendance
logout
```

Example attendance request:

```json
{
  "action": "submitAttendance",
  "username": "john",
  "device_id": "device_abc123",
  "qr_data": "JFATTEND:v1:SHOP01:...",
  "bssid": "AA:BB:CC:11:22:33"
}
```

Example success:

```json
{
  "success": true,
  "message": "Recorded",
  "attendance": {
    "arrival_time": "08:52",
    "status": "EARLY",
    "minutes": 8
  }
}
```

Example validation failure:

```json
{
  "success": false,
  "message": "Fail, check your QR or Wifi network connected"
}
```

`getDashboard` must return everything the dashboard needs in one call to minimize Sheet/API traffic:

```json
{
  "success": true,
  "user": {
    "username": "john"
  },
  "server": {
    "date": "2026-09-04",
    "time": "08:55",
    "scanner_open": true
  },
  "today": {
    "recorded": false,
    "arrival_time": null,
    "status": null,
    "minutes": 0
  },
  "month": {
    "late_minutes": 35,
    "late_days": 7,
    "early_minutes": 30,
    "early_days": 4
  },
  "history": [
    {
      "date": "2026-09-03",
      "arrival_time": "08:52",
      "status": "EARLY",
      "minutes": 8
    }
  ]
}
```

Suggested Apps Script files and responsibilities:

- `Code.gs`: `doPost(e)`, parsing, routing, and JSON responses.
- `Auth.gs`: login, PIN verification, device binding, and session validation.
- `Attendance.gs`: QR/BSSID checks, duplicate prevention, insertion, and timing calculation.
- `Dashboard.gs`: today's state, scanner state, current-month summaries, and history.
- `SheetService.gs`: spreadsheet access, lookups, and safe writes.
- `Config.gs`: sheet names and application constants.
- `Utils.gs`: date/time and response helpers.

## Dashboard requirements

Use a clean, mobile-first dashboard containing:

- Greeting and current server date.
- Reporting time.
- Today's attendance state.
- Before 07:00: `Attendance opens at 7:00 AM`.
- At/after 07:00 when unrecorded: embedded QR scanner.
- After success: `Recorded`, arrival time, and early/on-time/late result.
- Current calendar month's Late total minutes and day count, styled red.
- Current calendar month's Early total minutes and day count, styled green.
- Recent day-to-day attendance history, including on-time records.

For the current user and current calendar month:

- `late_days` counts rows with `LATE`; `late_minutes` sums their minutes.
- `early_days` counts rows with `EARLY`; `early_minutes` sums their minutes.
- On-time records need no large summary card.

Never delete or reset attendance rows at month boundaries. Query only the current month's rows for dashboard analytics, so a new month starts at zero while all historical records remain stored.

## Flutter structure

Use this simple structure unless a concrete technical reason requires a small change:

```text
attendance_app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── attendance_model.dart
│   │   └── dashboard_model.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   └── dashboard_screen.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── device_service.dart
│   │   ├── wifi_service.dart
│   │   └── local_storage_service.dart
│   ├── widgets/
│   │   ├── attendance_scanner.dart
│   │   ├── today_attendance_card.dart
│   │   ├── monthly_stats.dart
│   │   └── attendance_history.dart
│   └── utils/
│       ├── constants.dart
│       └── formatters.dart
├── android/
├── assets/
├── pubspec.yaml
└── README.md
```

## Implementation order

1. Document and seed `Members`, `Attendance`, and `Settings` with sample rows.
2. Implement and independently test settings access, member lookup, login/device binding, sessions, dashboard data, QR/BSSID validation, duplicate-safe attendance insertion, server timestamps, timing calculation, analytics, and JSON error handling.
3. Build the Flutter theme, API client, secure storage, persistent device ID, login/persistence, and dashboard shell.
4. Add BSSID access, QR scanning, submission states, scanner visibility, and post-success refresh.
5. Add monthly summaries, required colors, history, and today's state.
6. Complete final scenario testing.

## Minimum test matrix

Test all of the following:

- Valid first login and initial device binding.
- Future login from the bound device.
- Same user from the wrong device.
- Inactive and invalid users.
- Correct and incorrect BSSID.
- Correct and incorrect QR content.
- Scan before and after 07:00.
- Successful attendance and a second scan on the same day.
- App restart after attendance.
- New day before and after 07:00.
- Arrivals at 08:59, 09:00, and 09:01.
- Month-end transition: new month summaries start at zero and old rows remain.
- Network failure and Apps Script error responses.
- Concurrent/retried requests cannot create duplicate attendance rows.

## Non-goals

Do not implement registration, logout attendance, working hours, shift management, breaks, payroll, leave, holiday calendars, Sunday rules, an admin app, notifications, GPS, maps, dynamic QR codes, face recognition, multiple branches, a cloud database, complex reporting, or export tools in V1.

## Definition of done

V1 is complete only when a predefined active member can log in and bind one device; other devices are rejected; the dashboard reflects backend-derived attendance and scanner state; the scanner is unavailable before 07:00 and after success; QR, device, account, session, and BSSID checks run server-side; a valid request creates exactly one server-timestamped row; failures create none; the required messages and scanner behavior are correct; current-month early/late statistics and daily history are displayed; and month changes do not delete historical data.

If an implementation detail is unspecified, choose the simplest reliable production-friendly option.
