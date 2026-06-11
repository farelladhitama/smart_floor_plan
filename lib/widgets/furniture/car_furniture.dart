import 'dart:math' as math;

import 'package:flutter/material.dart';

class CarFurniture {
  static void draw(
    Canvas canvas,
    Rect roomRect, {
    required Color lineColor,
  }) {
    if (roomRect.width < 42 || roomRect.height < 65) return;

    final Paint fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    final Paint outlinePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.23)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final double carWidth = math.min(roomRect.width * 0.52, 46);
    final double carHeight = math.min(roomRect.height * 0.47, 78);

    final Rect carRect = Rect.fromCenter(
      center: Offset(
        roomRect.center.dx,
        roomRect.top + 14 + carHeight / 2,
      ),
      width: carWidth,
      height: carHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(carRect, const Radius.circular(9)),
      fillPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(carRect, const Radius.circular(9)),
      outlinePaint,
    );

    final Rect frontGlass = Rect.fromLTWH(
      carRect.left + 6,
      carRect.top + carRect.height * 0.20,
      carRect.width - 12,
      carRect.height * 0.18,
    );

    final Rect rearGlass = Rect.fromLTWH(
      carRect.left + 6,
      carRect.bottom - carRect.height * 0.35,
      carRect.width - 12,
      carRect.height * 0.16,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(frontGlass, const Radius.circular(3)),
      outlinePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rearGlass, const Radius.circular(3)),
      outlinePaint,
    );

    final double wheelWidth = 3.5;
    final double wheelHeight = 12;

    final List<Rect> wheels = [
      Rect.fromLTWH(
        carRect.left - wheelWidth,
        carRect.top + 13,
        wheelWidth,
        wheelHeight,
      ),
      Rect.fromLTWH(
        carRect.right,
        carRect.top + 13,
        wheelWidth,
        wheelHeight,
      ),
      Rect.fromLTWH(
        carRect.left - wheelWidth,
        carRect.bottom - 25,
        wheelWidth,
        wheelHeight,
      ),
      Rect.fromLTWH(
        carRect.right,
        carRect.bottom - 25,
        wheelWidth,
        wheelHeight,
      ),
    ];

    for (final Rect wheel in wheels) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(wheel, const Radius.circular(2)),
        outlinePaint,
      );
    }
  }
}