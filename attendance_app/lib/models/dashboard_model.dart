class DashboardData {
  const DashboardData({
    required this.username,
    required this.serverDate,
    required this.reportingTime,
    required this.scannerOpen,
    required this.today,
    required this.month,
    required this.history,
  });

  final String username;
  final String serverDate;
  final String reportingTime;
  final bool scannerOpen;
  final TodayAttendance today;
  final MonthlyAttendance month;
  final List<AttendanceHistoryItem> history;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final user = _map(json['user']);
    final server = _map(json['server']);
    final today = _map(json['today']);
    final month = _map(json['month']);
    final history = (json['history'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => AttendanceHistoryItem.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    return DashboardData(
      username: user['username']?.toString() ?? '',
      serverDate: server['date']?.toString() ?? '',
      reportingTime: server['reporting_time']?.toString() ?? '09:00 AM',
      scannerOpen:
          server['scanner_open'] == true || server['scanner_open'] == 'true',
      today: TodayAttendance.fromJson(today),
      month: MonthlyAttendance.fromJson(month),
      history: history,
    );
  }
}

class TodayAttendance {
  const TodayAttendance({
    required this.recorded,
    required this.arrivalTime,
    required this.status,
    required this.minutes,
  });

  final bool recorded;
  final String? arrivalTime;
  final String? status;
  final int minutes;

  factory TodayAttendance.fromJson(Map<String, dynamic> json) =>
      TodayAttendance(
        recorded: json['recorded'] == true || json['recorded'] == 'true',
        arrivalTime: json['arrival_time']?.toString(),
        status: json['status']?.toString(),
        minutes: _int(json['minutes']),
      );
}

class MonthlyAttendance {
  const MonthlyAttendance({
    required this.lateMinutes,
    required this.lateDays,
    required this.earlyMinutes,
    required this.earlyDays,
  });

  final int lateMinutes;
  final int lateDays;
  final int earlyMinutes;
  final int earlyDays;

  factory MonthlyAttendance.fromJson(Map<String, dynamic> json) =>
      MonthlyAttendance(
        lateMinutes: _int(json['late_minutes']),
        lateDays: _int(json['late_days']),
        earlyMinutes: _int(json['early_minutes']),
        earlyDays: _int(json['early_days']),
      );
}

class AttendanceHistoryItem {
  const AttendanceHistoryItem({
    required this.date,
    required this.arrivalTime,
    required this.status,
    required this.minutes,
  });

  final String date;
  final String arrivalTime;
  final String status;
  final int minutes;

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) =>
      AttendanceHistoryItem(
        date: json['date']?.toString() ?? '',
        arrivalTime: json['arrival_time']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        minutes: _int(json['minutes']),
      );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
