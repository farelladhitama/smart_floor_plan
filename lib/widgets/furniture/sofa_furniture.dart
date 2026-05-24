import 'dart:math' as math;

import 'package:flutter/material.dart';

class SofaFurniture {
  static void draw(
    Canvas canvas,
    Rect roomRect, {
    required Color lineColor,
    bool familyRoom = false,
  }) {
    if (roomRect.width < 46 || roomRect.height < 42) return;

    final Paint fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    final Paint outlinePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.21)
      ..strokeWidth = 1.05
      ..style = PaintingStyle.stroke;

    final double sofaWidth = math.min(
      roomRect.width * (familyRoom ? 0.48 : 0.44),
      familyRoom ? 62.0 : 54.0,
    );

    final double sofaHeight = math.min(
      roomRect.height * 0.18,
      18.0,
    );

    final Rect sofaRect = Rect.fromLTWH(
      roomRect.left + 8,
      roomRect.top + 12,
      sofaWidth,
      sofaHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaRect, const Radius.circular(4)),
      fillPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaRect, const Radius.circular(4)),
      outlinePaint,
    );

    canvas.drawLine(
      Offset(sofaRect.left + sofaRect.width * 0.34, sofaRect.top + 2),
      Offset(sofaRect.left + sofaRect.width * 0.34, sofaRect.bottom - 2),
      outlinePaint,
    );

    canvas.drawLine(
      Offset(sofaRect.left + sofaRect.width * 0.68, sofaRect.top + 2),
      Offset(sofaRect.left + sofaRect.width * 0.68, sofaRect.bottom - 2),
      outlinePaint,
    );

    final Rect coffeeTable = Rect.fromCenter(
      center: Offset(
        sofaRect.center.dx,
        sofaRect.bottom + 13,
      ),
      width: math.min(sofaRect.width * 0.56, 30),
      height: 9,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(coffeeTable, const Radius.circular(3)),
      fillPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(coffeeTable, const Radius.circular(3)),
      outlinePaint,
    );

    if (familyRoom && roomRect.width > 82) {
      final Rect sideSofa = Rect.fromLTWH(
        sofaRect.right - 10,
        sofaRect.bottom,
        10,
        math.min(roomRect.height * 0.18, 21),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(sideSofa, const Radius.circular(3)),
        fillPaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(sideSofa, const Radius.circular(3)),
        outlinePaint,
      );
    }
  }
}