import 'dart:math' as math;

import 'package:flutter/material.dart';

class KitchenFurniture {
  static void draw(
    Canvas canvas,
    Rect roomRect, {
    required Color lineColor,
  }) {
    if (roomRect.width < 43 || roomRect.height < 40) return;

    final Paint fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    final Paint outlinePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.22)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double counterDepth = math.min(12.0, roomRect.height * 0.18);

    final Rect topCounter = Rect.fromLTWH(
      roomRect.left + 7,
      roomRect.top + 10,
      roomRect.width - 14,
      counterDepth,
    );

    canvas.drawRect(topCounter, fillPaint);
    canvas.drawRect(topCounter, outlinePaint);

    if (roomRect.height > 62) {
      final Rect sideCounter = Rect.fromLTWH(
        roomRect.left + 7,
        topCounter.bottom,
        counterDepth,
        math.min(roomRect.height * 0.30, 31),
      );

      canvas.drawRect(sideCounter, fillPaint);
      canvas.drawRect(sideCounter, outlinePaint);
    }

    final double stoveRadius = math.min(3.5, counterDepth * 0.27);

    final Offset stoveOne = Offset(
      topCounter.right - 17,
      topCounter.center.dy,
    );

    final Offset stoveTwo = Offset(
      topCounter.right - 8,
      topCounter.center.dy,
    );

    canvas.drawCircle(stoveOne, stoveRadius, outlinePaint);
    canvas.drawCircle(stoveTwo, stoveRadius, outlinePaint);

    final Rect sink = Rect.fromLTWH(
      topCounter.left + 8,
      topCounter.top + 3,
      math.min(17, topCounter.width * 0.25),
      math.max(4, topCounter.height - 6),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(sink, const Radius.circular(2)),
      outlinePaint,
    );
  }
}