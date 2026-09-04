import 'package:flutter/material.dart';

import '../models/dashboard_model.dart';
import '../utils/constants.dart';

class AttendanceHistory extends StatelessWidget {
  const AttendanceHistory({super.key, required this.history});

  final List<AttendanceHistoryItem> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text('No attendance records this month.',
              style: TextStyle(color: AppColors.muted)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          for (var index = 0; index < history.length; index++) ...[
            _HistoryRow(item: history[index]),
            if (index < history.length - 1)
              Divider(height: 1, color: Colors.white.withValues(alpha: .05)),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final AttendanceHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status.toUpperCase()) {
      'EARLY' => AppColors.early,
      'LATE' => AppColors.late,
      _ => AppColors.primary,
    };
    final status = item.status.replaceAll('_', ' ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item.date,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text(item.arrivalTime,
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 16),
          SizedBox(
            width: 62,
            child: Text(
              status,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
