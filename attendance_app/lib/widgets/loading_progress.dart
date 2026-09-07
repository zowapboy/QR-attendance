import 'package:flutter/material.dart';

/// A compact, indeterminate progress bar for actions that are waiting on the
/// attendance server. It deliberately has no percentage because the server
/// controls when each request completes.
class LoadingProgressBar extends StatefulWidget {
  const LoadingProgressBar({
    super.key,
    required this.label,
    required this.color,
    required this.trackColor,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color trackColor;
  final Color textColor;

  @override
  State<LoadingProgressBar> createState() => _LoadingProgressBarState();
}

class _LoadingProgressBarState extends State<LoadingProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.label,
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) => ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: 5,
                  width: constraints.maxWidth,
                  child: ColoredBox(
                    color: widget.trackColor,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Align(
                        alignment: Alignment(
                          -1.5 + (_controller.value * 3),
                          0,
                        ),
                        child: child,
                      ),
                      child: FractionallySizedBox(
                        widthFactor: .48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
