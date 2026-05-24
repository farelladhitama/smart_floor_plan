import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/widgets/furniture/room_furniture_renderer.dart';

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
  static const Color dimensionColor = Color(0xFF64748B);
  static const Color orientationColor = Color(0xFF94A3B8);

  ProfessionalFloorPlanPainter({
    required this.landWidth,
    required this.landLength,
    required this.rooms,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landWidth <= 0 || landLength <= 0) return;

    const double margin = 52;

    final double usableWidth = math.max(1, size.width - (margin * 2));
    final double usableHeight = math.max(1, size.height - (margin * 2));

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
    _drawOrientation(canvas, origin, planWidth, planHeight);
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

    final Paint minorPaint = Paint()
      ..color = gridMinorColor
      ..strokeWidth = 0.6;

    final Paint majorPaint = Paint()
      ..color = gridMajorColor
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += grid) {
      final bool isMajor = ((x / grid).round() % 5) == 0;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }

    for (double y = 0; y <= size.height; y += grid) {
      final bool isMajor = ((y / grid).round() % 5) == 0;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  void _drawLand(
    Canvas canvas,
    Offset origin,
    double planWidth,
    double planHeight,
  ) {
    final Rect landRect = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      planWidth,
      planHeight,
    );

    canvas.drawRect(
      landRect,
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
    final Rect landRect = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      planWidth,
      planHeight,
    );

    canvas.drawRect(
      landRect,
      Paint()
        ..color = wallColor
        ..strokeWidth = 5.2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawRooms(Canvas canvas, Offset origin, double scale) {
    for (final RoomModel room in rooms) {
      final Rect roomRect = Rect.fromLTWH(
        origin.dx + (room.x * scale),
        origin.dy + (room.y * scale),
        room.width * scale,
        room.height * scale,
      );

      _drawRoomFill(canvas, roomRect, room);
      _drawArchitecturalTexture(canvas, roomRect, room);

      RoomFurnitureRenderer.draw(
        canvas: canvas,
        roomRect: roomRect,
        room: room,
        lineColor: wallColor,
      );

      _drawRoomWall(canvas, roomRect, room);
      _drawDoor(canvas, roomRect, room);
      _drawWindow(canvas, roomRect, room);
      _drawRoomLabel(canvas, roomRect, room);
    }
  }

  void _drawRoomFill(Canvas canvas, Rect roomRect, RoomModel room) {
    canvas.drawRect(
      roomRect,
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

  void _drawArchitecturalTexture(
    Canvas canvas,
    Rect roomRect,
    RoomModel room,
  ) {
    final String roomName = room.nama.toLowerCase();

    if (roomName.contains('taman')) {
      _drawGardenTexture(canvas, roomRect);
    }

    if (roomName.contains('carport') || roomName.contains('garasi')) {
      _drawCarportTexture(canvas, roomRect);
    }

    if (room.category == 'bath') {
      _drawBathroomTileTexture(canvas, roomRect);
    }

    if (room.category == 'kitchen') {
      _drawKitchenTileTexture(canvas, roomRect);
    }
  }

  void _drawGardenTexture(Canvas canvas, Rect roomRect) {
    final Paint grassPaint = Paint()
      ..color = const Color(0xFF86C28B).withValues(alpha: 0.30)
      ..strokeWidth = 1.1;

    for (double x = roomRect.left + 8;
        x < roomRect.right - 6;
        x += 12) {
      for (double y = roomRect.top + 10;
          y < roomRect.bottom - 6;
          y += 14) {
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

  void _drawCarportTexture(Canvas canvas, Rect roomRect) {
    final Paint tilePaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.18)
      ..strokeWidth = 0.75;

    for (double y = roomRect.top + 8;
        y < roomRect.bottom;
        y += 12) {
      canvas.drawLine(
        Offset(roomRect.left, y),
        Offset(roomRect.right, y),
        tilePaint,
      );
    }

    for (double x = roomRect.left + 12;
        x < roomRect.right;
        x += 18) {
      canvas.drawLine(
        Offset(x, roomRect.top),
        Offset(x, roomRect.bottom),
        tilePaint,
      );
    }
  }

  void _drawBathroomTileTexture(Canvas canvas, Rect roomRect) {
    final Paint tilePaint = Paint()
      ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.17)
      ..strokeWidth = 0.65;

    for (double x = roomRect.left + 10;
        x < roomRect.right;
        x += 14) {
      canvas.drawLine(
        Offset(x, roomRect.top),
        Offset(x, roomRect.bottom),
        tilePaint,
      );
    }

    for (double y = roomRect.top + 10;
        y < roomRect.bottom;
        y += 14) {
      canvas.drawLine(
        Offset(roomRect.left, y),
        Offset(roomRect.right, y),
        tilePaint,
      );
    }
  }

  void _drawKitchenTileTexture(Canvas canvas, Rect roomRect) {
    final Paint tilePaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.10)
      ..strokeWidth = 0.6;

    for (double x = roomRect.left + 14;
        x < roomRect.right;
        x += 18) {
      canvas.drawLine(
        Offset(x, roomRect.top),
        Offset(x, roomRect.bottom),
        tilePaint,
      );
    }
  }

  void _drawRoomWall(Canvas canvas, Rect roomRect, RoomModel room) {
    final Paint wallPaint = Paint()
      ..color = wallColor
      ..strokeWidth = room.isOutdoor ? 2.6 : 4.2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(roomRect, wallPaint);
  }

  void _drawDoor(Canvas canvas, Rect roomRect, RoomModel room) {
    final double maxDoorSize = room.isOutdoor ? 24 : 34;

    final double doorSize = math.min(
      maxDoorSize,
      math.min(roomRect.width, roomRect.height) * 0.36,
    );

    if (doorSize < 10) return;

    final Paint eraseWallPaint = Paint()
      ..color = _roomColor(room)
      ..strokeWidth = room.isOutdoor ? 4 : 7
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final Paint doorPaint = Paint()
      ..color = doorColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    switch (room.doorSide) {
      case 'top':
        _drawTopDoor(
          canvas,
          roomRect,
          doorSize,
          eraseWallPaint,
          doorPaint,
        );
        break;

      case 'left':
        _drawLeftDoor(
          canvas,
          roomRect,
          doorSize,
          eraseWallPaint,
          doorPaint,
        );
        break;

      case 'right':
        _drawRightDoor(
          canvas,
          roomRect,
          doorSize,
          eraseWallPaint,
          doorPaint,
        );
        break;

      case 'bottom':
      default:
        _drawBottomDoor(
          canvas,
          roomRect,
          doorSize,
          eraseWallPaint,
          doorPaint,
        );
        break;
    }
  }

  void _drawTopDoor(
    Canvas canvas,
    Rect roomRect,
    double doorSize,
    Paint eraseWallPaint,
    Paint doorPaint,
  ) {
    final double centerX = roomRect.center.dx;

    canvas.drawLine(
      Offset(centerX - doorSize / 2, roomRect.top),
      Offset(centerX + doorSize / 2, roomRect.top),
      eraseWallPaint,
    );

    canvas.drawLine(
      Offset(centerX - doorSize / 2, roomRect.top),
      Offset(centerX - doorSize / 2, roomRect.top + doorSize),
      doorPaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        centerX - doorSize / 2,
        roomRect.top,
        doorSize,
        doorSize,
      ),
      math.pi,
      -math.pi / 2,
      false,
      doorPaint,
    );
  }

  void _drawLeftDoor(
    Canvas canvas,
    Rect roomRect,
    double doorSize,
    Paint eraseWallPaint,
    Paint doorPaint,
  ) {
    final double centerY = roomRect.center.dy;

    canvas.drawLine(
      Offset(roomRect.left, centerY - doorSize / 2),
      Offset(roomRect.left, centerY + doorSize / 2),
      eraseWallPaint,
    );

    canvas.drawLine(
      Offset(roomRect.left, centerY + doorSize / 2),
      Offset(roomRect.left + doorSize, centerY + doorSize / 2),
      doorPaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        roomRect.left,
        centerY - doorSize / 2,
        doorSize,
        doorSize,
      ),
      math.pi / 2,
      math.pi / 2,
      false,
      doorPaint,
    );
  }

  void _drawRightDoor(
    Canvas canvas,
    Rect roomRect,
    double doorSize,
    Paint eraseWallPaint,
    Paint doorPaint,
  ) {
    final double centerY = roomRect.center.dy;

    canvas.drawLine(
      Offset(roomRect.right, centerY - doorSize / 2),
      Offset(roomRect.right, centerY + doorSize / 2),
      eraseWallPaint,
    );

    canvas.drawLine(
      Offset(roomRect.right, centerY - doorSize / 2),
      Offset(roomRect.right - doorSize, centerY - doorSize / 2),
      doorPaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        roomRect.right - doorSize,
        centerY - doorSize / 2,
        doorSize,
        doorSize,
      ),
      -math.pi / 2,
      math.pi / 2,
      false,
      doorPaint,
    );
  }

  void _drawBottomDoor(
    Canvas canvas,
    Rect roomRect,
    double doorSize,
    Paint eraseWallPaint,
    Paint doorPaint,
  ) {
    final double centerX = roomRect.center.dx;

    canvas.drawLine(
      Offset(centerX - doorSize / 2, roomRect.bottom),
      Offset(centerX + doorSize / 2, roomRect.bottom),
      eraseWallPaint,
    );

    canvas.drawLine(
      Offset(centerX + doorSize / 2, roomRect.bottom),
      Offset(centerX + doorSize / 2, roomRect.bottom - doorSize),
      doorPaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        centerX - doorSize / 2,
        roomRect.bottom - doorSize,
        doorSize,
        doorSize,
      ),
      0,
      -math.pi / 2,
      false,
      doorPaint,
    );
  }

  void _drawWindow(Canvas canvas, Rect roomRect, RoomModel room) {
    if (room.isOutdoor || roomRect.width < 34) return;

    final double windowWidth = math.min(36, roomRect.width * 0.30);

    final Paint windowPaint = Paint()
      ..color = windowColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(roomRect.center.dx - windowWidth / 2, roomRect.top + 2),
      Offset(roomRect.center.dx + windowWidth / 2, roomRect.top + 2),
      windowPaint,
    );
  }

  void _drawRoomLabel(Canvas canvas, Rect roomRect, RoomModel room) {
    if (roomRect.width < 34 || roomRect.height < 28) return;

    final double titleSize = math.max(
      7,
      math.min(11.5, roomRect.width / 9),
    );

    final double detailSize = math.max(
      6,
      math.min(8.7, roomRect.width / 12),
    );

    final TextPainter titlePainter = TextPainter(
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
    )..layout(
        maxWidth: math.max(18, roomRect.width - 10),
      );

    final TextPainter detailPainter = TextPainter(
      text: TextSpan(
        text:
            '${room.width.toStringAsFixed(1)} × ${room.height.toStringAsFixed(1)} m\n${room.area.toStringAsFixed(1)} m²',
        style: TextStyle(
          color: const Color(0xFF475569),
          fontSize: detailSize,
          fontWeight: FontWeight.w500,
          height: 1.22,
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(
        maxWidth: math.max(18, roomRect.width - 10),
      );

    final double totalHeight =
        titlePainter.height + detailPainter.height + 3;

    final double labelCenterY = roomRect.center.dy + (roomRect.height * 0.10);

    final double titleY = labelCenterY - totalHeight / 2;

    final Rect backgroundRect = Rect.fromCenter(
      center: Offset(
        roomRect.center.dx,
        labelCenterY + 1,
      ),
      width: math.min(
        roomRect.width - 8,
        math.max(titlePainter.width, detailPainter.width) + 8,
      ),
      height: totalHeight + 5,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        backgroundRect,
        const Radius.circular(3),
      ),
      Paint()
        ..color = _roomColor(room).withValues(alpha: 0.80)
        ..style = PaintingStyle.fill,
    );

    titlePainter.paint(
      canvas,
      Offset(
        roomRect.center.dx - titlePainter.width / 2,
        titleY,
      ),
    );

    detailPainter.paint(
      canvas,
      Offset(
        roomRect.center.dx - detailPainter.width / 2,
        titleY + titlePainter.height + 3,
      ),
    );
  }

  void _drawDimensions(
    Canvas canvas,
    Offset origin,
    double planWidth,
    double planHeight,
  ) {
    final Paint dimensionPaint = Paint()
      ..color = dimensionColor
      ..strokeWidth = 1.1;

    final double topY = origin.dy - 22;
    final double leftX = origin.dx - 25;

    canvas.drawLine(
      Offset(origin.dx, topY),
      Offset(origin.dx + planWidth, topY),
      dimensionPaint,
    );

    canvas.drawLine(
      Offset(origin.dx, topY - 5),
      Offset(origin.dx, topY + 5),
      dimensionPaint,
    );

    canvas.drawLine(
      Offset(origin.dx + planWidth, topY - 5),
      Offset(origin.dx + planWidth, topY + 5),
      dimensionPaint,
    );

    canvas.drawLine(
      Offset(leftX, origin.dy),
      Offset(leftX, origin.dy + planHeight),
      dimensionPaint,
    );

    canvas.drawLine(
      Offset(leftX - 5, origin.dy),
      Offset(leftX + 5, origin.dy),
      dimensionPaint,
    );

    canvas.drawLine(
      Offset(leftX - 5, origin.dy + planHeight),
      Offset(leftX + 5, origin.dy + planHeight),
      dimensionPaint,
    );

    _paintText(
      canvas,
      '${landWidth.toStringAsFixed(1)} m',
      Offset(origin.dx + planWidth / 2, topY - 17),
      fontSize: 11,
      center: true,
      color: dimensionColor,
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
      color: dimensionColor,
    );

    canvas.restore();
  }

  void _drawOrientation(
    Canvas canvas,
    Offset origin,
    double planWidth,
    double planHeight,
  ) {
    _paintText(
      canvas,
      'BELAKANG',
      Offset(origin.dx + planWidth / 2, origin.dy + 8),
      fontSize: 8,
      center: true,
      color: orientationColor,
    );

    _paintText(
      canvas,
      'DEPAN',
      Offset(
        origin.dx + planWidth / 2,
        origin.dy + planHeight - 16,
      ),
      fontSize: 8,
      center: true,
      color: orientationColor,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset position, {
    required double fontSize,
    bool center = false,
    Color color = dimensionColor,
  }) {
    final TextPainter painter = TextPainter(
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