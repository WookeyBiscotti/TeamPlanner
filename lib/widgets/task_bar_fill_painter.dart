import 'package:flutter/material.dart';
import 'package:patterns_canvas/patterns_canvas.dart';

class TaskBarFillPainter extends CustomPainter {
  TaskBarFillPainter({
    required this.color,
    this.pattern,
    this.borderRadius = 6,
  });

  final Color color;
  final Pattern? pattern;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    if (pattern != null) {
      pattern!.paintOnRRect(canvas, size, rrect);
      return;
    }
    canvas.drawRRect(rrect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant TaskBarFillPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.pattern?.patternType != pattern?.patternType ||
        oldDelegate.pattern?.bgColor != pattern?.bgColor ||
        oldDelegate.pattern?.fgColor != pattern?.fgColor;
  }
}
