import 'package:flutter/material.dart';

import '../models/dashboard_model.dart';
import '../utils/constants.dart';

class MonthlyStats extends StatelessWidget {
  const MonthlyStats({super.key, required this.month});

  final MonthlyAttendance month;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Late',
          value: '${month.lateMinutes} min',
          days: '${month.lateDays} days',
          color: AppColors.late,
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Early',
          value: '${month.earlyMinutes} min',
          days: '${month.earlyDays} days',
          color: AppColors.early,
          icon: Icons.wb_sunny_outlined,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.days,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String days;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 14),
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 25, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(days,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
