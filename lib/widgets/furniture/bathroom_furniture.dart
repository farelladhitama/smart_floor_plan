import 'dart:math' as math;

import 'package:flutter/material.dart';

class BathroomFurniture {
  static void draw(
    Canvas canvas,
    Rect roomRect, {
    required Color lineColor,
  }) {
    if (roomRect.width < 30 || roomRect.height < 30) return;

    final Paint fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    final Paint outlinePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.23)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final double showerSize = math.min(
      roomRect.width * 0.32,
      roomRect.height * 0.27,
    );

    if (showerSize >= 8) {
      final Rect shower = Rect.fromLTWH(
        roomRect.right - showerSize - 6,
        roomRect.top + 7,
        showerSize,
        showerSize,
      );

      canvas.drawRect(shower, fillPaint);
      canvas.drawRect(shower, outlinePaint);

      canvas.drawLine(shower.topLeft, shower.bottomRight, outlinePaint);
      canvas.drawLine(shower.topRight, shower.bottomLeft, outlinePaint);
    }

    final double toiletWidth = math.min(13, roomRect.width * 0.26);
    final double toiletHeight = math.min(20, roomRect.height * 0.34);

    final Rect toilet = Rect.fromLTWH(
      roomRect.left + 7,
      roomRect.top + 9,
      toiletWidth,
      toiletHeight,
    );

    canvas.drawOval(toilet, fillPaint);
    canvas.drawOval(toilet, outlinePaint);

    if (roomRect.height > 46) {
      final Rect basin = Rect.fromLTWH(
        roomRect.left + 7,
        roomRect.bottom - 17,
        math.min(16, roomRect.width * 0.29),
        9,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(basin, const Radius.circular(2)),
        outlinePaint,
      );
    }
  }
}