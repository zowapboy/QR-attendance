import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../utils/constants.dart';
import 'loading_progress.dart';

class AttendanceScanner extends StatefulWidget {
  const AttendanceScanner({
    super.key,
    required this.onQrScanned,
  });

  final Future<bool> Function(String qrData) onQrScanned;

  @override
  State<AttendanceScanner> createState() => _AttendanceScannerState();
}

class _AttendanceScannerState extends State<AttendanceScanner> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isSubmitting = false;

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isSubmitting || capture.barcodes.isEmpty) return;
    final qrData = capture.barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() => _isSubmitting = true);
    await _controller.stop();
    final recorded = await widget.onQrScanned(qrData);
    if (!mounted) return;

    if (!recorded) {
      setState(() => _isSubmitting = false);
      await _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .24),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.wifi_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Correct Wi-Fi and GPS are required to scan.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _handleDetect,
                    errorBuilder: (context, error) => const _CameraError(),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _ScannerOverlay(),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .62),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isSubmitting
                          ? const LoadingProgressBar(
                              label: 'Recording attendance',
                              color: AppColors.primary,
                              trackColor: Color(0xFF3F424B),
                              textColor: Colors.white,
                            )
                          : const Text(
                              'Position the shop QR code inside the frame',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Camera access is required to scan the attendance QR code. Allow camera permission in Android settings, then reopen the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ),
        ),
      );
}

class _ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frame = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * .68,
      height: size.width * .68,
    );
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: .35);
    final fullPath = Path()..addRect(Offset.zero & size);
    final framePath = Path()
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(16)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, framePath),
      dimPaint,
    );

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(16)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlay oldDelegate) => false;
}
