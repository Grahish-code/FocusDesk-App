import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ScrollableGraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> history;
  final double dayWidth;
  final int selectedIndex;

  ScrollableGraphPainter({
    required this.history,
    required this.dayWidth,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.4)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    final double topY = 0;
    final double bottomY = size.height;

    // Draw grid lines
    canvas.drawLine(Offset(0, topY), Offset(size.width, topY), gridPaint);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );
    canvas.drawLine(Offset(0, bottomY), Offset(size.width, bottomY), gridPaint);

    for (int i = 0; i < history.length; i++) {
      double x = i * dayWidth + (dayWidth / 2);
      canvas.drawLine(
        Offset(x, topY),
        Offset(x, bottomY),
        gridPaint..color = Colors.white.withValues(alpha: 0.02),
      );
    }

    // Build the wave path
    Path path = Path();

    for (int i = 0; i < history.length; i++) {
      List<dynamic> total = history[i]['total_goals'] ?? [];
      List<dynamic> completed = history[i]['completed_goals'] ?? [];

      double ratio = total.isNotEmpty ? completed.length / total.length : 0.0;

      double x = i * dayWidth + (dayWidth / 2);
      double y = (bottomY - (ratio * (bottomY - topY))).clamp(topY + 10, bottomY - 10);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        double prevX = (i - 1) * dayWidth + (dayWidth / 2);

        List<dynamic> prevTotal = history[i - 1]['total_goals'] ?? [];
        List<dynamic> prevCompleted = history[i - 1]['completed_goals'] ?? [];
        double prevRatio = prevTotal.isNotEmpty ? prevCompleted.length / prevTotal.length : 0.0;

        double prevY = (bottomY - (prevRatio * (bottomY - topY))).clamp(topY + 10, bottomY - 10);
        path.cubicTo(prevX + dayWidth / 2, prevY, prevX + dayWidth / 2, y, x, y);
      }

      // Draw node dot
      double dotRadius = dayWidth < 30 ? 2 : 4;
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);

      // Draw selected indicator
      if (i == selectedIndex) {
        final Paint selectPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(Offset(x, y), dotRadius + 6, selectPaint);

        final Paint indicatorPaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(x, y),
            Offset(x, bottomY),
            [Colors.cyanAccent, Colors.transparent],
          )
          ..strokeWidth = 1;

        canvas.drawLine(Offset(x, y + 10), Offset(x, bottomY), indicatorPaint);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}