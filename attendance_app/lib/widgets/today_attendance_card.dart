import 'package:flutter/material.dart';

import '../models/dashboard_model.dart';
import '../utils/constants.dart';
import 'attendance_scanner.dart';

class TodayAttendanceCard extends StatelessWidget {
  const TodayAttendanceCard({
    super.key,
    required this.today,
    required this.scannerOpen,
  });

  final TodayAttendance today;
  final bool scannerOpen;

  @override
  Widget build(BuildContext context) {
    final recorded = today.recorded;
    final accent = recorded
        ? AppColors.early
        : scannerOpen
            ? AppColors.primary
            : AppColors.muted;
    final label = recorded
        ? 'RECORDED'
        : scannerOpen
            ? 'READY'
            : 'CLOSED';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                recorded
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_checked,
                color: accent,
                size: 15,
              ),
              const SizedBox(width: 8),
              Text(
                "Today's attendance",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              _StatusBadge(label: label, color: accent),
            ],
          ),
          const SizedBox(height: 8),
          if (recorded)
            _RecordedState(today: today)
          else if (scannerOpen)
            const AttendanceScanner()
          else
            const _ClosedState(),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class _RecordedState extends StatelessWidget {
  const _RecordedState({required this.today});

  final TodayAttendance today;

  @override
  Widget build(BuildContext context) {
    final status =
        today.status?.replaceAll('_', ' ').toLowerCase() ?? 'on time';
    final minutes =
        today.minutes == 0 ? 'On time' : '${today.minutes} minutes $status';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.early.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.done_rounded, color: AppColors.early),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                today.arrivalTime == null
                    ? 'Attendance recorded'
                    : 'Arrival ${today.arrivalTime}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(minutes,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClosedState extends StatelessWidget {
  const _ClosedState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        'Attendance opens at 7:00 AM.',
        style: TextStyle(color: AppColors.muted, fontSize: 13),
      ),
    );
  }
}
