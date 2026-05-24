import 'dart:math' as math;

import 'package:flutter/material.dart';

class DiningFurniture {
  static void draw(
    Canvas canvas,
    Rect roomRect, {
    required Color lineColor,
  }) {
    if (roomRect.width < 42 || roomRect.height < 40) return;

    final Paint fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    final Paint outlinePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.22)
      ..strokeWidth = 0.95
      ..style = PaintingStyle.stroke;

    final double tableWidth = math.min(roomRect.width * 0.42, 43);
    final double tableHeight = math.min(roomRect.height * 0.20, 17);

    final Rect table = Rect.fromLTWH(
      roomRect.left + 10,
      roomRect.top + 18,
      tableWidth,
      tableHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(3)),
      fillPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(3)),
      outlinePaint,
    );

    final double chairSize = math.min(7, tableHeight * 0.45);

    final List<Rect> chairs = [
      Rect.fromCenter(
        center: Offset(table.left + table.width * 0.28, table.top - 5),
        width: chairSize,
        height: chairSize,
      ),
      Rect.fromCenter(
        center: Offset(table.left + table.width * 0.72, table.top - 5),
        width: chairSize,
        height: chairSize,
      ),
      Rect.fromCenter(
        center: Offset(table.left + table.width * 0.28, table.bottom + 5),
        width: chairSize,
        height: chairSize,
      ),
      Rect.fromCenter(
        center: Offset(table.left + table.width * 0.72, table.bottom + 5),
        width: chairSize,
        height: chairSize,
      ),
    ];

    for (final Rect chair in chairs) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(chair, const Radius.circular(1.5)),
        outlinePaint,
      );
    }
  }
}