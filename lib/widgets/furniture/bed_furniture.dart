import 'dart:math' as math;

import 'package:flutter/material.dart';

class BedFurniture {
  static void draw(
    Canvas canvas,
    Rect roomRect, {
    required Color lineColor,
    bool isMaster = false,
  }) {
    if (roomRect.width < 42 || roomRect.height < 40) return;

    final double bedWidth = math.min(
      roomRect.width * (isMaster ? 0.48 : 0.40),
      isMaster ? 58.0 : 47.0,
    );

    final double bedHeight = math.min(
      roomRect.height * 0.42,
      isMaster ? 62.0 : 52.0,
    );

    final Rect bedRect = Rect.fromLTWH(
      roomRect.left + 8,
      roomRect.top + 11,
      bedWidth,
      bedHeight,
    );

    final Paint fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    final Paint outlinePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.22)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final Paint detailPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.17)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bedRect, const Radius.circular(3.5)),
      fillPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bedRect, const Radius.circular(3.5)),
      outlinePaint,
    );

    final double pillowWidth = math.max(8.0, bedWidth * 0.38);
    final double pillowHeight = math.max(6.0, bedHeight * 0.17);

    final Rect pillowOne = Rect.fromLTWH(
      bedRect.left + 4,
      bedRect.top + 4,
      pillowWidth,
      pillowHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(pillowOne, const Radius.circular(2)),
      detailPaint,
    );

    if (isMaster && bedWidth > 38) {
      final Rect pillowTwo = Rect.fromLTWH(
        bedRect.right - pillowWidth - 4,
        bedRect.top + 4,
        pillowWidth,
        pillowHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(pillowTwo, const Radius.circular(2)),
        detailPaint,
      );
    }

    canvas.drawLine(
      Offset(bedRect.left + 4, bedRect.top + pillowHeight + 9),
      Offset(bedRect.right - 4, bedRect.top + pillowHeight + 9),
      detailPaint,
    );

    canvas.drawLine(
      Offset(bedRect.left + 4, bedRect.bottom - 8),
      Offset(bedRect.right - 4, bedRect.bottom - 8),
      detailPaint,
    );

    if (roomRect.width > 72 && roomRect.height > 60) {
      final Rect wardrobe = Rect.fromLTWH(
        roomRect.right - 20,
        roomRect.top + 10,
        12,
        math.min(roomRect.height * 0.30, 34),
      );

      canvas.drawRect(wardrobe, fillPaint);
      canvas.drawRect(wardrobe, detailPaint);

      canvas.drawLine(
        Offset(wardrobe.center.dx, wardrobe.top + 2),
        Offset(wardrobe.center.dx, wardrobe.bottom - 2),
        detailPaint,
      );
    }
  }
}