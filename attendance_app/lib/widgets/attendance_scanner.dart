import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AttendanceScanner extends StatelessWidget {
  const AttendanceScanner({super.key});
  @override
  Widget build(BuildContext c) => Container(
      height: 190,
      decoration: BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.circular(18)),
      child: Stack(alignment: Alignment.center, children: [
        const CustomPaint(size: Size(150, 150), painter: _Corners()),
        Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: .8), width: 2),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.qr_code_2_rounded,
                size: 75, color: Colors.white)),
        const Positioned(
            bottom: 12,
            child: Text('Position QR code inside the frame',
                style: TextStyle(color: AppColors.muted, fontSize: 12)))
      ]));
}

class _Corners extends CustomPainter {
  const _Corners();

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    const l = 28.0;
    for (final d in [0, 1, 2, 3]) {
      final double x = d % 2 == 0 ? 0.0 : s.width, y = d < 2 ? 0.0 : s.height;
      final double sx = d % 2 == 0 ? 1.0 : -1.0, sy = d < 2 ? 1.0 : -1.0;
      c.drawLine(Offset(x, y), Offset(x + sx * l, y), p);
      c.drawLine(Offset(x, y), Offset(x, y + sy * l), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
