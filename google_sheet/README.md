# Google Sheet setup

Create one spreadsheet with exactly these tabs:

- `Members`: `username`, `pin`, `device_id`, `active`, `created_at`
- `Attendance`: `timestamp`, `date`, `username`, `arrival_time`, `difference_minutes`, `status`, `device_id`, `bssid`
- `Settings`: key/value rows for `shop_name`, `reporting_time`, `scanner_open_time`, `timezone`, `qr_token`, and one or more `allowed_bssid_*` values.

Set the initial `qr_token` row to this exact full value. The matching printable PNG is in `attendance_app/assets/shop_attendance_qr.png`:

```text
JFATTEND:v1:SHOP01:JralxmcP8pbWY2KGeeGXfd4NwYITcgtOVLYcGxOXJLQ
```

Keep all attendance rows permanently. Monthly analytics query the current calendar month; they must not delete or reset historical data.

Format the `Members` `pin` column as **Plain text** before entering PINs if any PIN begins with `0`.
