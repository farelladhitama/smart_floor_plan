import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';

class ProfessionalFloorPlanPainter extends CustomPainter {
  final double landWidth;
  final double landLength;
  final List<RoomModel> rooms;

  static const Color wallColor = Color(0xFF172433);
  static const Color backgroundColor = Color(0xFFF4F7FA);
  static const Color planBackgroundColor = Color(0xFFFFFFFF);
  static const Color gridMinorColor = Color(0xFFE4EBF2);
  static const Color gridMajorColor = Color(0xFFD3DEE8);
  static const Color doorColor = Color(0xFF334155);
  static const Color windowColor = Color(0xFF38BDF8);

  ProfessionalFloorPlanPainter({
    required this.landWidth,
    required this.landLength,
    required this.rooms,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landWidth <= 0 || landLength <= 0) return;

    const double margin = 52;
    final double usableWidth = size.width - (margin * 2);
    final double usableHeight = size.height - (margin * 2);

    final double scaleX = usableWidth / landWidth;
    final double scaleY = usableHeight / landLength;
    final double scale = math.min(scaleX, scaleY);

    final double planWidth = landWidth * scale;
    final double planHeight = landLength * scale;

    final Offset origin = Offset(
      (size.width - planWidth) / 2,
      (size.height - planHeight) / 2,
    );

    _drawBackground(canvas, size);
    _drawGrid(canvas, size);
    _drawLand(canvas, origin, planWidth, planHeight);
    _drawRooms(canvas, origin, scale);
    _drawOuterBoundary(canvas, origin, planWidth, planHeight);
    _drawDimensions(canvas, origin, planWidth, planHeight);
    _drawOrientation(canvas, origin, planWidth);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    const double grid = 16;

    final minorPaint = Paint()
      ..color = gridMinorColor
      ..strokeWidth = 0.6;

    final majorPaint = Paint()
      ..color = gridMajorColor
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += grid) {
      final bool major = ((x / grid).round() % 5) == 0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        major ? majorPaint : minorPaint,
      );
    }

    for (double y = 0; y <= size.height; y += grid) {
      final bool major = ((y / grid).round() % 5) == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        major ? majorPaint : minorPaint,
      );
    }
  }

  void _drawLand(
    Canvas canvas,
    Offset origin,
    double planWidth,
    double planHeight,
  ) {
    final rect = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      planWidth,
      planHeight,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color = planBackgroundColor
        ..style = PaintingStyle.fill,
    );
  }

  void _drawOuterBoundary(
    Canvas canvas,
    Offset origin,
    double planWidth,
    double planHeight,
  ) {
    final rect = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      planWidth,
      planHeight,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color = wallColor
        ..strokeWidth = 5.2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawRooms(Canvas canvas, Offset origin, double scale) {
    for (final room in rooms) {
      final Rect rect = Rect.fromLTWH(
        origin.dx + (room.x * scale),
        origin.dy + (room.y * scale),
        room.width * scale,
        room.height * scale,
      );

      _drawRoomFill(canvas, rect, room);
      _drawArchitecturalTexture(canvas, rect, room);
      _drawRoomWall(canvas, rect, room);
      _drawDoor(canvas, rect, room);
      _drawWindow(canvas, rect, room);
      _drawFurnitureSymbol(canvas, rect, room);
      _drawRoomLabel(canvas, rect, room);
    }
  }

  void _drawRoomFill(Canvas canvas, Rect rect, RoomModel room) {
    canvas.drawRect(
      rect,
      Paint()
        ..color = _roomColor(room)
        ..style = PaintingStyle.fill,
    );
  }

  Color _roomColor(RoomModel room) {
    switch (room.category) {
      case 'bedroom':
        return const Color(0xFFFFF3DD);
      case 'living':
        return const Color(0xFFFFF9EC);
      case 'family':
        return const Color(0xFFF7F1E7);
      case 'kitchen':
        return const Color(0xFFEAF4FD);
      case 'dining':
        return const Color(0xFFFFF4E6);
      case 'bath':
        return const Color(0xFFE0F2FE);
      case 'service':
        return const Color(0xFFF1F5F9);
      case 'outdoor':
        if (room.nama.toLowerCase().contains('taman')) {
          return const Color(0xFFD8F3DC);
        }
        if (room.nama.toLowerCase().contains('carport') ||
            room.nama.toLowerCase().contains('garasi')) {
          return const Color(0xFFE5E7EB);
        }
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFF8FAFC);
    }
  }

  void _drawArchitecturalTexture(Canvas canvas, Rect rect, RoomModel room) {
    final name = room.nama.toLowerCase();

    if (name.contains('taman')) {
      final grassPaint = Paint()
        ..color = const Color(0xFF86C28B).withValues(alpha: 0.32)
        ..strokeWidth = 1.2;

      for (double x = rect.left + 8; x < rect.right - 6; x += 12) {
        for (double y = rect.top + 10; y < rect.bottom - 6; y += 14) {
          canvas.drawLine(
            Offset(x, y + 5),
            Offset(x + 3, y),
            grassPaint,
          );
          canvas.drawLine(
            Offset(x + 3, y),
            Offset(x + 6, y + 5),
            grassPaint,
          );
        }
      }
    }

    if (name.contains('carport') || name.contains('garasi')) {
      final tilePaint = Paint()
        ..color = const Color(0xFF94A3B8).withValues(alpha: 0.20)
        ..strokeWidth = 0.8;

      for (double y = rect.top + 8; y < rect.bottom; y += 12) {
        canvas.drawLine(
          Offset(rect.left, y),
          Offset(rect.right, y),
          tilePaint,
        );
      }
    }

    if (room.category == 'bath') {
      final tilePaint = Paint()
        ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.18)
        ..strokeWidth = 0.7;

      for (double x = rect.left + 10; x < rect.right; x += 14) {
        canvas.drawLine(
          Offset(x, rect.top),
          Offset(x, rect.bottom),
          tilePaint,
        );
      }
    }
  }

  void _drawRoomWall(Canvas canvas, Rect rect, RoomModel room) {
    final paint = Paint()
      ..color = wallColor
      ..strokeWidth = room.isOutdoor ? 2.6 : 4.2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);
  }

  void _drawDoor(Canvas canvas, Rect rect, RoomModel room) {
    final double maxDoor = room.isOutdoor ? 24 : 34;
    final double doorSize = math.min(
      maxDoor,
      math.min(rect.width, rect.height) * 0.36,
    );

    if (doorSize < 10) return;

    final erasePaint = Paint()
      ..color = _roomColor(room)
      ..strokeWidth = room.isOutdoor ? 4 : 7
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final doorPaint = Paint()
      ..color = doorColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    switch (room.doorSide) {
      case 'top':
        final x = rect.center.dx;
        canvas.drawLine(
          Offset(x - doorSize / 2, rect.top),
          Offset(x + doorSize / 2, rect.top),
          erasePaint,
        );
        canvas.drawLine(
          Offset(x - doorSize / 2, rect.top),
          Offset(x - doorSize / 2, rect.top + doorSize),
          doorPaint,
        );
        canvas.drawArc(
          Rect.fromLTWH(
            x - doorSize / 2,
            rect.top,
            doorSize,
            doorSize,
          ),
          math.pi,
          -math.pi / 2,
          false,
          doorPaint,
        );
        break;

      case 'left':
        final y = rect.center.dy;
        canvas.drawLine(
          Offset(rect.left, y - doorSize / 2),
          Offset(rect.left, y + doorSize / 2),
          erasePaint,
        );
        canvas.drawLine(
          Offset(rect.left, y + doorSize / 2),
          Offset(rect.left + doorSize, y + doorSize / 2),
          doorPaint,
        );
        canvas.drawArc(
          Rect.fromLTWH(
            rect.left,
            y - doorSize / 2,
            doorSize,
            doorSize,
          ),
          math.pi / 2,
          math.pi / 2,
          false,
          doorPaint,
        );
        break;

      case 'right':
        final y = rect.center.dy;
        canvas.drawLine(
          Offset(rect.right, y - doorSize / 2),
          Offset(rect.right, y + doorSize / 2),
          erasePaint,
        );
        canvas.drawLine(
          Offset(rect.right, y - doorSize / 2),
          Offset(rect.right - doorSize, y - doorSize / 2),
          doorPaint,
        );
        canvas.drawArc(
          Rect.fromLTWH(
            rect.right - doorSize,
            y - doorSize / 2,
            doorSize,
            doorSize,
          ),
          -math.pi / 2,
          math.pi / 2,
          false,
          doorPaint,
        );
        break;

      case 'bottom':
      default:
        final x = rect.center.dx;
        canvas.drawLine(
          Offset(x - doorSize / 2, rect.bottom),
          Offset(x + doorSize / 2, rect.bottom),
          erasePaint,
        );
        canvas.drawLine(
          Offset(x + doorSize / 2, rect.bottom),
          Offset(x + doorSize / 2, rect.bottom - doorSize),
          doorPaint,
        );
        canvas.drawArc(
          Rect.fromLTWH(
            x - doorSize / 2,
            rect.bottom - doorSize,
            doorSize,
            doorSize,
          ),
          0,
          -math.pi / 2,
          false,
          doorPaint,
        );
        break;
    }
  }

  void _drawWindow(Canvas canvas, Rect rect, RoomModel room) {
    if (room.isOutdoor || rect.width < 34) return;

    final double windowWidth = math.min(36, rect.width * 0.30);

    final paint = Paint()
      ..color = windowColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(rect.center.dx - windowWidth / 2, rect.top + 2),
      Offset(rect.center.dx + windowWidth / 2, rect.top + 2),
      paint,
    );
  }

  void _drawFurnitureSymbol(Canvas canvas, Rect rect, RoomModel room) {
    if (rect.width < 50 || rect.height < 48) return;

    final symbolPaint = Paint()
      ..color = wallColor.withValues(alpha: 0.14)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final name = room.nama.toLowerCase();

    if (room.category == 'bedroom') {
      final bedRect = Rect.fromLTWH(
        rect.left + 8,
        rect.top + 13,
        math.min(rect.width * 0.38, 42),
        math.min(rect.height * 0.30, 30),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bedRect, const Radius.circular(3)),
        symbolPaint,
      );

      canvas.drawLine(
        Offset(bedRect.left + 4, bedRect.top + 8),
        Offset(bedRect.right - 4, bedRect.top + 8),
        symbolPaint,
      );
    } else if (room.category == 'living' || room.category == 'family') {
      final sofaRect = Rect.fromLTWH(
        rect.left + 8,
        rect.top + 14,
        math.min(rect.width * 0.46, 46),
        14,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(sofaRect, const Radius.circular(4)),
        symbolPaint,
      );

      canvas.drawCircle(
        Offset(rect.center.dx, rect.center.dy - 4),
        8,
        symbolPaint,
      );
    } else if (room.category == 'dining') {
      final table = Rect.fromCenter(
        center: Offset(rect.center.dx, rect.center.dy - 6),
        width: math.min(34, rect.width * 0.38),
        height: 18,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(table, const Radius.circular(3)),
        symbolPaint,
      );
    } else if (room.category == 'kitchen') {
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 6, rect.top + 10, rect.width - 12, 11),
        symbolPaint,
      );

      canvas.drawCircle(
        Offset(rect.right - 18, rect.top + 15),
        4,
        symbolPaint,
      );
    } else if (room.category == 'bath') {
      canvas.drawOval(
        Rect.fromLTWH(
          rect.left + 10,
          rect.top + 14,
          math.min(16, rect.width * 0.25),
          math.min(21, rect.height * 0.28),
        ),
        symbolPaint,
      );
    } else if (name.contains('carport') || name.contains('garasi')) {
      final car = Rect.fromCenter(
        center: rect.center,
        width: math.min(30, rect.width * 0.44),
        height: math.min(56, rect.height * 0.50),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(car, const Radius.circular(8)),
        symbolPaint,
      );
    }
  }

  void _drawRoomLabel(Canvas canvas, Rect rect, RoomModel room) {
    if (rect.width < 34 || rect.height < 28) return;

    final double titleSize = math.max(8, math.min(12.5, rect.width / 8.5));
    final double detailSize = math.max(7, math.min(10, rect.width / 11));

    final titlePainter = TextPainter(
      text: TextSpan(
        text: room.nama,
        style: TextStyle(
          color: wallColor,
          fontSize: titleSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(18, rect.width - 12));

    final detailPainter = TextPainter(
      text: TextSpan(
        text:
            '${room.width.toStringAsFixed(1)} × ${room.height.toStringAsFixed(1)} m\n${room.area.toStringAsFixed(1)} m²',
        style: TextStyle(
          color: const Color(0xFF475569),
          fontSize: detailSize,
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(18, rect.width - 12));

    final double totalHeight =
        titlePainter.height + detailPainter.height + 3;

    final double startY = rect.center.dy - totalHeight / 2 + 10;

    titlePainter.paint(
      canvas,
      Offset(
        rect.center.dx - titlePainter.width / 2,
        startY,
      ),
    );

    detailPainter.paint(
      canvas,
      Offset(
        rect.center.dx - detailPainter.width / 2,
        startY + titlePainter.height + 3,
      ),
    );
  }

  void _drawDimensions(
    Canvas canvas,
    Offset origin,
    double planWidth,
    double planHeight,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.1;

    final double topY = origin.dy - 22;
    final double leftX = origin.dx - 25;

    canvas.drawLine(
      Offset(origin.dx, topY),
      Offset(origin.dx + planWidth, topY),
      paint,
    );

    canvas.drawLine(
      Offset(origin.dx, topY - 5),
      Offset(origin.dx, topY + 5),
      paint,
    );

    canvas.drawLine(
      Offset(origin.dx + planWidth, topY - 5),
      Offset(origin.dx + planWidth, topY + 5),
      paint,
    );

    canvas.drawLine(
      Offset(leftX, origin.dy),
      Offset(leftX, origin.dy + planHeight),
      paint,
    );

    canvas.drawLine(
      Offset(leftX - 5, origin.dy),
      Offset(leftX + 5, origin.dy),
      paint,
    );

    canvas.drawLine(
      Offset(leftX - 5, origin.dy + planHeight),
      Offset(leftX + 5, origin.dy + planHeight),
      paint,
    );

    _paintText(
      canvas,
      '${landWidth.toStringAsFixed(1)} m',
      Offset(origin.dx + planWidth / 2, topY - 17),
      fontSize: 11,
      center: true,
    );

    canvas.save();
    canvas.translate(leftX - 12, origin.dy + planHeight / 2);
    canvas.rotate(-math.pi / 2);
    _paintText(
      canvas,
      '${landLength.toStringAsFixed(1)} m',
      Offset.zero,
      fontSize: 11,
      center: true,
    );
    canvas.restore();
  }

  void _drawOrientation(Canvas canvas, Offset origin, double planWidth) {
    _paintText(
      canvas,
      'BELAKANG',
      Offset(origin.dx + planWidth / 2, origin.dy + 8),
      fontSize: 8,
      center: true,
      color: const Color(0xFF94A3B8),
    );

    _paintText(
      canvas,
      'DEPAN',
      Offset(origin.dx + planWidth / 2, origin.dy + landLength * _scaleForLabel(origin, planWidth) - 18),
      fontSize: 8,
      center: true,
      color: const Color(0xFF94A3B8),
    );
  }

  double _scaleForLabel(Offset origin, double planWidth) {
    return planWidth / landWidth;
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset position, {
    required double fontSize,
    bool center = false,
    Color color = const Color(0xFF64748B),
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      center
          ? Offset(
              position.dx - painter.width / 2,
              position.dy - painter.height / 2,
            )
          : position,
    );
  }

  @override
  bool shouldRepaint(covariant ProfessionalFloorPlanPainter oldDelegate) {
    return oldDelegate.landWidth != landWidth ||
        oldDelegate.landLength != landLength ||
        oldDelegate.rooms != rooms;
  }
}