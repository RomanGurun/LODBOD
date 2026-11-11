import 'package:flutter/material.dart';

import 'package:lodbod/core/theme/tokens.dart';

/// A thin horizontal dashed rule, as used between card rows.
class DashedDivider extends StatelessWidget {
  const DashedDivider({
    super.key,
    this.color = AppColors.surfaceVariant,
    this.thickness = 1.5,
    this.dashWidth = 4,
    this.gapWidth = 3,
  });

  final Color color;
  final double thickness;
  final double dashWidth;
  final double gapWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, thickness),
      painter: _DashedLinePainter(
        color: color,
        dashWidth: dashWidth,
        gapWidth: gapWidth,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.gapWidth,
  });

  final Color color;
  final double dashWidth;
  final double gapWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    var x = 0.0;
    while (x < size.width) {
      final remaining = size.width - x;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, dashWidth.clamp(0.0, remaining), size.height),
        paint,
      );
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.gapWidth != gapWidth;
  }
}
