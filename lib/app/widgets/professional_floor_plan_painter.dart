import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
enum _PlanSide { top, right, bottom, left }

class ProfessionalFloorPlanPainter extends CustomPainter {
  final List<RoomModel> rooms;
  final double landWidth;
  final double landLength;
  final String title;

  ProfessionalFloorPlanPainter({
    required this.rooms,
    double? landWidth,
    double? landLength,
    double? inputLebarRumah,
    double? inputPanjangRumah,
    this.title = 'SMARTFLOORPLAN RENDER',
  })  : landWidth = landWidth ?? inputLebarRumah ?? 1,
        landLength = landLength ?? inputPanjangRumah ?? 1;

  static const Color _paperBg = Color(0xFFF3F4F6);
  static const Color _canvasBg = Color(0xFFE7E3DC);
  static const Color _plotBg = Color(0xFFF7F3EA);
  static const Color _wall = Color(0xFF171717);
  static const Color _wallSoft = Color(0xFF343434);
  static const Color _window = Color(0xFF77C7FF);
  static const Color _textDark = Color(0xFF1F2933);
  static const Color _textSoft = Color(0xFF667085);

  double get _safeLandWidth => landWidth <= 0 ? 1 : landWidth;
  double get _safeLandLength => landLength <= 0 ? 1 : landLength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _paperBg,
    );

    final Rect boardRect = Rect.fromLTWH(
      18,
      18,
      size.width - 36,
      size.height - 36,
    );

    _drawPresentationBoard(canvas, boardRect);

    final Rect plotRect = _computePlotRect(boardRect);

    _drawPlotShadow(canvas, plotRect);
    _drawPlotBase(canvas, plotRect);
    _drawHeader(canvas, boardRect);
    _drawDimension(canvas, plotRect);
    _drawNorthArrow(canvas, boardRect);

    final List<RoomModel> outdoorRooms = rooms
        .where((room) => _isOutdoor(room.nama, room.category))
        .toList();

    final List<RoomModel> indoorRooms = rooms
        .where((room) => !_isOutdoor(room.nama, room.category))
        .toList();

    for (final RoomModel room in outdoorRooms) {
      final Rect rect = _roomToRect(room, plotRect);
      _drawOutdoorArea(canvas, rect, room);
    }

    for (final RoomModel room in indoorRooms) {
      final Rect rect = _roomToRect(room, plotRect);
      _drawRoomDropShadow(canvas, rect);
    }

    for (final RoomModel room in indoorRooms) {
      final Rect rect = _roomToRect(room, plotRect);
      _drawIndoorFloor(canvas, rect, room);
    }

    for (final RoomModel room in rooms) {
      final Rect rect = _roomToRect(room, plotRect);
      _drawRoomWall(canvas, rect, room);
    }

    for (final RoomModel room in indoorRooms) {
      final Rect rect = _roomToRect(room, plotRect);
      _drawWindows(canvas, rect, plotRect);
    }

    for (final RoomModel room in indoorRooms) {
      final Rect rect = _roomToRect(room, plotRect);
      _drawDoor(canvas, rect, plotRect, room);
    }
    // Object outdoor bawaan dimatikan karena sekarang memakai asset image overlay.
    for (final RoomModel room in indoorRooms) {
      final Rect rect = _roomToRect(room, plotRect);
      _drawFurniture(canvas, rect, room);
    }
for (final RoomModel room in rooms) {
      final Rect rect = _roomToRect(room, plotRect);
      _drawCleanLabel(canvas, rect, room);
    }

    _drawPlotBorder(canvas, plotRect);
    _drawLegend(canvas, boardRect);
  }

  Rect _computePlotRect(Rect boardRect) {
    const double leftPad = 58;
    const double rightPad = 52;
    const double topPad = 54;
    const double bottomPad = 54;

    final double availableWidth = boardRect.width - leftPad - rightPad;
    final double availableHeight = boardRect.height - topPad - bottomPad;

    final double scale = math.min(
      availableWidth / _safeLandWidth,
      availableHeight / _safeLandLength,
    );

    final double plotWidth = _safeLandWidth * scale;
    final double plotHeight = _safeLandLength * scale;

    final double left =
        boardRect.left + leftPad + ((availableWidth - plotWidth) / 2);
    final double top =
        boardRect.top + topPad + ((availableHeight - plotHeight) / 2);

    return Rect.fromLTWH(left, top, plotWidth, plotHeight);
  }

  Rect _roomToRect(RoomModel room, Rect plotRect) {
    final double scaleX = plotRect.width / _safeLandWidth;
    final double scaleY = plotRect.height / _safeLandLength;

    return Rect.fromLTWH(
      plotRect.left + (room.x * scaleX),
      plotRect.top + (room.y * scaleY),
      math.max(0, room.width * scaleX),
      math.max(0, room.height * scaleY),
    );
  }

  bool _isOutdoor(String name, String category) {
    final String lowerName = name.toLowerCase();
    final String lowerCategory = category.toLowerCase();

    return lowerCategory == 'outdoor' ||
        lowerName.contains('taman') ||
        lowerName.contains('garden') ||
        lowerName.contains('carport') ||
        lowerName.contains('teras') ||
        lowerName.contains('inner court') ||
        lowerName.contains('halaman') ||
        lowerName.contains('kolam');
  }

  String _roomCategory(String roomName, String category) {
    final String name = roomName.toLowerCase();
    final String cat = category.toLowerCase();

    if (name.contains('tidur')) return 'bedroom';
    if (name.contains('tamu')) return 'living';
    if (name.contains('keluarga')) return 'family';
    if (name.contains('makan')) return 'dining';
    if (name.contains('dapur')) return 'kitchen';
    if (name.contains('mandi') || name.contains('wc') || name.contains('km')) {
      return 'bath';
    }

    if (name.contains('cuci') ||
        name.contains('koridor') ||
        name.contains('sirkulasi') ||
        name.contains('service')) {
      return 'service';
    }

    if (cat.isNotEmpty) return cat;

    return 'default';
  }

  void _drawPresentationBoard(Canvas canvas, Rect rect) {
    final RRect shadow = RRect.fromRectAndRadius(
      rect.shift(const Offset(5, 7)),
      const Radius.circular(18),
    );

    canvas.drawRRect(
      shadow,
      Paint()..color = const Color(0x14000000),
    );

    final RRect board = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(18),
    );

    canvas.drawRRect(
      board,
      Paint()..color = _canvasBg,
    );
  }

  void _drawPlotShadow(Canvas canvas, Rect plotRect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        plotRect.inflate(9).shift(const Offset(4, 6)),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0x26000000),
    );
  }

  void _drawPlotBase(Canvas canvas, Rect plotRect) {
    canvas.drawRect(
      plotRect,
      Paint()..color = _plotBg,
    );
  }

  void _drawHeader(Canvas canvas, Rect boardRect) {
    _drawText(
      canvas,
      title,
      Offset(boardRect.left + 15, boardRect.top + 13),
      fontSize: 12.5,
      fontWeight: FontWeight.w900,
      color: _textDark,
      maxWidth: 260,
    );

    _drawText(
      canvas,
      'Rendered top-view floor plan preview with furniture, landscape, and material texture',
      Offset(boardRect.left + 15, boardRect.top + 29),
      fontSize: 8.3,
      fontWeight: FontWeight.w500,
      color: _textSoft,
      maxWidth: 330,
    );

    final Rect badge = Rect.fromLTWH(
      boardRect.right - 104,
      boardRect.top + 12,
      88,
      24,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        badge,
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFFF7D8C2),
    );

    _drawCenteredText(
      canvas,
      'SMART PLAN',
      badge.center,
      fontSize: 7.6,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFE47B3E),
      maxWidth: badge.width - 8,
    );
  }

  void _drawDimension(Canvas canvas, Rect plotRect) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFF8A8A8A)
      ..strokeWidth = 1;

    final double topY = plotRect.top - 12;

    canvas.drawLine(
      Offset(plotRect.left, topY),
      Offset(plotRect.right, topY),
      linePaint,
    );

    canvas.drawLine(
      Offset(plotRect.left, topY - 5),
      Offset(plotRect.left, plotRect.top),
      linePaint,
    );

    canvas.drawLine(
      Offset(plotRect.right, topY - 5),
      Offset(plotRect.right, plotRect.top),
      linePaint,
    );

    _drawCenteredText(
      canvas,
      '${_safeLandWidth.toStringAsFixed(1)} m',
      Offset(plotRect.center.dx, topY - 9),
      fontSize: 8,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF5C5C5C),
      maxWidth: 90,
    );

    final double leftX = plotRect.left - 13;

    canvas.drawLine(
      Offset(leftX, plotRect.top),
      Offset(leftX, plotRect.bottom),
      linePaint,
    );

    canvas.drawLine(
      Offset(leftX - 5, plotRect.top),
      Offset(plotRect.left, plotRect.top),
      linePaint,
    );

    canvas.drawLine(
      Offset(leftX - 5, plotRect.bottom),
      Offset(plotRect.left, plotRect.bottom),
      linePaint,
    );

    canvas.save();
    canvas.translate(leftX - 12, plotRect.center.dy);
    canvas.rotate(-math.pi / 2);

    _drawCenteredText(
      canvas,
      '${_safeLandLength.toStringAsFixed(1)} m',
      Offset.zero,
      fontSize: 8,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF5C5C5C),
      maxWidth: 90,
    );

    canvas.restore();
  }

  void _drawNorthArrow(Canvas canvas, Rect boardRect) {
    final Offset center = Offset(boardRect.right - 32, boardRect.top + 67);

    final Paint p = Paint()
      ..color = const Color(0xFF202020)
      ..strokeWidth = 1.7;

    canvas.drawLine(
      Offset(center.dx, center.dy + 18),
      Offset(center.dx, center.dy - 10),
      p,
    );

    final Path arrow = Path()
      ..moveTo(center.dx, center.dy - 17)
      ..lineTo(center.dx - 5, center.dy - 7)
      ..lineTo(center.dx + 5, center.dy - 7)
      ..close();

    canvas.drawPath(
      arrow,
      Paint()..color = const Color(0xFF202020),
    );

    _drawCenteredText(
      canvas,
      'N',
      Offset(center.dx, center.dy + 26),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF202020),
      maxWidth: 24,
    );
  }

  void _drawOutdoorArea(Canvas canvas, Rect rect, RoomModel room) {
    final String name = room.nama.toLowerCase();

    if (name.contains('carport')) {
      _drawPaving(canvas, rect, const Color(0xFF8A8A8A), darker: true);
      return;
    }

    if (name.contains('teras')) {
      _drawWoodDeck(canvas, rect);
      return;
    }

    if (name.contains('kolam')) {
      _drawWater(canvas, rect);
      return;
    }

    _drawPremiumGrass(canvas, rect);
  }

  void _drawIndoorFloor(Canvas canvas, Rect rect, RoomModel room) {
    final String category = _roomCategory(room.nama, room.category);

    switch (category) {
      case 'bedroom':
        _drawPremiumWood(canvas, rect, const Color(0xFFC18A55));
        break;
      case 'bath':
        _drawPremiumTiles(canvas, rect, const Color(0xFF7AC8D7), small: true);
        break;
      case 'kitchen':
        _drawMarbleTiles(canvas, rect, const Color(0xFFE6DDC8));
        break;
      case 'dining':
      case 'living':
      case 'family':
        _drawLargeFormatTiles(canvas, rect, const Color(0xFFE6D8B7));
        break;
      case 'service':
        _drawPremiumTiles(canvas, rect, const Color(0xFFD7D7D7), small: true);
        break;
      default:
        _drawLargeFormatTiles(canvas, rect, const Color(0xFFE9DFC8));
        break;
    }
  }

  void _drawRoomDropShadow(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect.shift(const Offset(2.4, 2.4)),
      Paint()..color = const Color(0x16000000),
    );
  }

  void _drawRoomWall(Canvas canvas, Rect rect, RoomModel room) {
    final bool outdoor = _isOutdoor(room.nama, room.category);

    if (outdoor) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );
      return;
    }

    canvas.drawRect(
      rect,
      Paint()
        ..color = _wall
        ..strokeWidth = 3.8
        ..style = PaintingStyle.stroke,
    );

    canvas.drawRect(
      rect.deflate(2.2),
      Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawPlotBorder(Canvas canvas, Rect plotRect) {
    canvas.drawRect(
      plotRect,
      Paint()
        ..color = const Color(0xFF9B9B9B)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawWindows(Canvas canvas, Rect rect, Rect plotRect) {
    const double tolerance = 1.6;

    final bool left = (rect.left - plotRect.left).abs() < tolerance;
    final bool right = (rect.right - plotRect.right).abs() < tolerance;
    final bool top = (rect.top - plotRect.top).abs() < tolerance;
    final bool bottom = (rect.bottom - plotRect.bottom).abs() < tolerance;

    if (left) _drawWindowOnSide(canvas, rect, _PlanSide.left);
    if (right) _drawWindowOnSide(canvas, rect, _PlanSide.right);
    if (top) _drawWindowOnSide(canvas, rect, _PlanSide.top);
    if (bottom) _drawWindowOnSide(canvas, rect, _PlanSide.bottom);
  }

  void _drawWindowOnSide(Canvas canvas, Rect rect, _PlanSide side) {
    final Paint cut = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final Paint glass = Paint()
      ..color = _window
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final double len = math.min(24, math.max(14, math.min(rect.width, rect.height) * 0.42));

    switch (side) {
      case _PlanSide.top:
        final double y = rect.top;
        final double x1 = rect.center.dx - len / 2;
        final double x2 = rect.center.dx + len / 2;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), cut);
        canvas.drawLine(Offset(x1, y), Offset(x2, y), glass);
        break;
      case _PlanSide.right:
        final double x = rect.right;
        final double y1 = rect.center.dy - len / 2;
        final double y2 = rect.center.dy + len / 2;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), cut);
        canvas.drawLine(Offset(x, y1), Offset(x, y2), glass);
        break;
      case _PlanSide.bottom:
        final double y = rect.bottom;
        final double x1 = rect.center.dx - len / 2;
        final double x2 = rect.center.dx + len / 2;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), cut);
        canvas.drawLine(Offset(x1, y), Offset(x2, y), glass);
        break;
      case _PlanSide.left:
        final double x = rect.left;
        final double y1 = rect.center.dy - len / 2;
        final double y2 = rect.center.dy + len / 2;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), cut);
        canvas.drawLine(Offset(x, y1), Offset(x, y2), glass);
        break;
    }
  }

  void _drawDoor(Canvas canvas, Rect rect, Rect plotRect, RoomModel room) {
    final _PlanSide side = _chooseDoorSide(rect, plotRect, room.nama);

    final Paint erase = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round;

    final Paint line = Paint()
      ..color = _wallSoft
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke;

    final double doorLen = math.min(
      20,
      math.max(11, math.min(rect.width, rect.height) * 0.30),
    );

    switch (side) {
      case _PlanSide.top:
        final double y = rect.top;
        final double x1 = rect.center.dx - doorLen / 2;
        final double x2 = rect.center.dx + doorLen / 2;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), erase);
        final Offset hinge = Offset(x1, y);
        canvas.drawLine(hinge, Offset(x2, y), line);
        canvas.drawArc(
          Rect.fromCircle(center: hinge, radius: doorLen),
          0,
          math.pi / 2,
          false,
          line,
        );
        break;

      case _PlanSide.right:
        final double x = rect.right;
        final double y1 = rect.center.dy - doorLen / 2;
        final double y2 = rect.center.dy + doorLen / 2;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), erase);
        final Offset hinge = Offset(x, y1);
        canvas.drawLine(hinge, Offset(x, y2), line);
        canvas.drawArc(
          Rect.fromCircle(center: hinge, radius: doorLen),
          math.pi / 2,
          math.pi / 2,
          false,
          line,
        );
        break;

      case _PlanSide.bottom:
        final double y = rect.bottom;
        final double x1 = rect.center.dx + doorLen / 2;
        final double x2 = rect.center.dx - doorLen / 2;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), erase);
        final Offset hinge = Offset(x1, y);
        canvas.drawLine(hinge, Offset(x2, y), line);
        canvas.drawArc(
          Rect.fromCircle(center: hinge, radius: doorLen),
          math.pi,
          math.pi / 2,
          false,
          line,
        );
        break;

      case _PlanSide.left:
        final double x = rect.left;
        final double y1 = rect.center.dy + doorLen / 2;
        final double y2 = rect.center.dy - doorLen / 2;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), erase);
        final Offset hinge = Offset(x, y1);
        canvas.drawLine(hinge, Offset(x, y2), line);
        canvas.drawArc(
          Rect.fromCircle(center: hinge, radius: doorLen),
          -math.pi / 2,
          math.pi / 2,
          false,
          line,
        );
        break;
    }
  }

  _PlanSide _chooseDoorSide(Rect rect, Rect plotRect, String roomName) {
    final String name = roomName.toLowerCase();

    if (name.contains('ruang tamu') || name.contains('tamu')) {
      return _PlanSide.bottom;
    }

    if (name.contains('dapur')) {
      return _PlanSide.left;
    }

    if (name.contains('tidur')) {
      return _PlanSide.left;
    }

    if (name.contains('mandi') || name.contains('wc') || name.contains('km')) {
      return _PlanSide.bottom;
    }

    final Offset center = rect.center;
    final Offset target = plotRect.center;

    final double dx = target.dx - center.dx;
    final double dy = target.dy - center.dy;

    if (dx.abs() > dy.abs()) {
      return dx > 0 ? _PlanSide.right : _PlanSide.left;
    }

    return dy > 0 ? _PlanSide.bottom : _PlanSide.top;
  }

  void _drawFurniture(Canvas canvas, Rect rect, RoomModel room) {
    final String category = _roomCategory(room.nama, room.category);

    switch (category) {
      case 'bedroom':
        _drawBedroom(canvas, rect);
        break;
      case 'living':
        _drawLivingRoom(canvas, rect);
        break;
      case 'family':
        _drawFamilyRoom(canvas, rect);
        break;
      case 'dining':
        _drawDining(canvas, rect);
        break;
      case 'kitchen':
        _drawKitchen(canvas, rect);
        break;
      case 'bath':
        _drawBathroom(canvas, rect);
        break;
      case 'service':
        _drawService(canvas, rect);
        break;
      default:
        _drawAccent(canvas, rect);
        break;
    }
  }

  void _drawOutdoorObject(Canvas canvas, Rect rect, RoomModel room) {
    final String name = room.nama.toLowerCase();

    if (name.contains('carport')) {
      _drawCarport(canvas, rect);
      return;
    }

    if (name.contains('teras')) {
      _drawTerraceSet(canvas, rect);
      return;
    }

    if (name.contains('taman') ||
        name.contains('inner court') ||
        name.contains('garden')) {
      _drawLandscape(canvas, rect);
    }
  }

  void _drawBedroom(Canvas canvas, Rect rect) {
    if (rect.width < 32 || rect.height < 26) return;

    final Paint bedFill = Paint()..color = const Color(0xFFF7E6D0);
    final Paint stroke = Paint()
      ..color = const Color(0xFF6C4A2E)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final bool horizontal = rect.width >= rect.height;

    final double bedW = horizontal
        ? math.min(rect.width * 0.48, 54)
        : math.min(rect.width * 0.62, 48);

    final double bedH = horizontal
        ? math.min(rect.height * 0.36, 36)
        : math.min(rect.height * 0.42, 44);

    final Rect bed = Rect.fromLTWH(
      rect.left + rect.width * 0.08,
      rect.top + rect.height * 0.10,
      bedW,
      bedH,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bed, const Radius.circular(5)),
      bedFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bed, const Radius.circular(5)),
      stroke,
    );

    final double pillowH = math.max(5, bed.height * 0.18);
    final double pillowW = math.max(10, bed.width * 0.36);

    final Rect p1 = Rect.fromLTWH(
      bed.left + 4,
      bed.top + 4,
      pillowW,
      pillowH,
    );

    final Rect p2 = Rect.fromLTWH(
      bed.right - pillowW - 4,
      bed.top + 4,
      pillowW,
      pillowH,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(p1, const Radius.circular(2)),
      stroke,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(p2, const Radius.circular(2)),
      stroke,
    );

    final Rect blanket = Rect.fromLTWH(
      bed.left + 4,
      bed.top + pillowH + 9,
      bed.width - 8,
      math.max(7, bed.height - pillowH - 13),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(blanket, const Radius.circular(3)),
      Paint()..color = const Color(0xFFE4C49D),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(blanket, const Radius.circular(3)),
      stroke,
    );

    if (rect.width > 48) {
      final Rect wardrobe = Rect.fromLTWH(
        rect.right - math.max(13, rect.width * 0.17),
        rect.top + rect.height * 0.10,
        math.max(11, rect.width * 0.12),
        math.max(17, rect.height * 0.30),
      );

      canvas.drawRect(
        wardrobe,
        Paint()..color = const Color(0xFFC4925F),
      );

      canvas.drawRect(wardrobe, stroke);

      canvas.drawLine(
        Offset(wardrobe.center.dx, wardrobe.top),
        Offset(wardrobe.center.dx, wardrobe.bottom),
        stroke,
      );
    }

    if (rect.width > 68 && rect.height > 52) {
      final Rect sideTable = Rect.fromLTWH(
        bed.right + 5,
        bed.top + 3,
        9,
        9,
      );

      if (rect.contains(sideTable.center)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(sideTable, const Radius.circular(2)),
          Paint()..color = const Color(0xFFD5AA7C),
        );
        canvas.drawCircle(
          sideTable.center,
          2.2,
          Paint()..color = const Color(0xFFFDECC8),
        );
      }
    }
  }

  void _drawLivingRoom(Canvas canvas, Rect rect) {
    if (rect.width < 40 || rect.height < 32) return;

    final Paint sofaFill = Paint()..color = const Color(0xFFF4EEE2);
    final Paint stroke = Paint()
      ..color = const Color(0xFF756C5E)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Rect rug = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.62,
      height: rect.height * 0.46,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rug, const Radius.circular(6)),
      Paint()..color = const Color(0x55D8C8AE),
    );

    final Rect sofaA = Rect.fromLTWH(
      rect.left + rect.width * 0.12,
      rect.top + rect.height * 0.18,
      rect.width * 0.45,
      math.min(rect.height * 0.15, 18),
    );

    final Rect sofaB = Rect.fromLTWH(
      sofaA.left,
      sofaA.bottom + 5,
      math.min(rect.width * 0.18, 22),
      math.min(rect.height * 0.25, 25),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaA, const Radius.circular(6)),
      sofaFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaA, const Radius.circular(6)),
      stroke,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaB, const Radius.circular(6)),
      sofaFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaB, const Radius.circular(6)),
      stroke,
    );

    final Rect table = Rect.fromCenter(
      center: Offset(rect.center.dx + rect.width * 0.06, rect.center.dy),
      width: math.min(rect.width * 0.24, 30),
      height: math.min(rect.height * 0.13, 14),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(5)),
      Paint()..color = const Color(0xFFD2B184),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(5)),
      stroke,
    );
  }

  void _drawFamilyRoom(Canvas canvas, Rect rect) {
    if (rect.width < 46 || rect.height < 34) return;

    final Paint sofaFill = Paint()..color = const Color(0xFFF1E8D9);
    final Paint stroke = Paint()
      ..color = const Color(0xFF756C5E)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Rect rug = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.66,
      height: rect.height * 0.52,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rug, const Radius.circular(7)),
      Paint()..color = const Color(0x4FC9BCA2),
    );

    final Rect sofaLong = Rect.fromLTWH(
      rect.left + rect.width * 0.10,
      rect.top + rect.height * 0.13,
      rect.width * 0.44,
      math.min(rect.height * 0.16, 19),
    );

    final Rect sofaSide = Rect.fromLTWH(
      sofaLong.left,
      sofaLong.bottom + 5,
      math.min(rect.width * 0.20, 24),
      math.min(rect.height * 0.26, 28),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaLong, const Radius.circular(6)),
      sofaFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaLong, const Radius.circular(6)),
      stroke,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaSide, const Radius.circular(6)),
      sofaFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sofaSide, const Radius.circular(6)),
      stroke,
    );

    final Rect table = Rect.fromCenter(
      center: rect.center,
      width: math.min(rect.width * 0.27, 36),
      height: math.min(rect.height * 0.13, 15),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(5)),
      Paint()..color = const Color(0xFFD2B184),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(5)),
      stroke,
    );

    if (rect.width > 75) {
      final Rect tv = Rect.fromLTWH(
        rect.right - rect.width * 0.18,
        rect.top + rect.height * 0.18,
        math.max(13, rect.width * 0.12),
        math.max(8, rect.height * 0.10),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(tv, const Radius.circular(2)),
        Paint()..color = const Color(0xFF3F3F3F),
      );
    }
  }

  void _drawDining(Canvas canvas, Rect rect) {
    if (rect.width < 36 || rect.height < 28) return;

    final Paint stroke = Paint()
      ..color = const Color(0xFF735737)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Rect table = Rect.fromCenter(
      center: rect.center,
      width: math.min(rect.width * 0.42, 42),
      height: math.min(rect.height * 0.26, 26),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(6)),
      Paint()..color = const Color(0xFFB57D48),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(6)),
      stroke,
    );

    final List<Offset> chairs = <Offset>[
      Offset(table.left - 7, table.center.dy),
      Offset(table.right + 7, table.center.dy),
      Offset(table.center.dx - table.width * 0.25, table.top - 7),
      Offset(table.center.dx + table.width * 0.25, table.top - 7),
      Offset(table.center.dx - table.width * 0.25, table.bottom + 7),
      Offset(table.center.dx + table.width * 0.25, table.bottom + 7),
    ];

    for (final Offset chair in chairs) {
      if (rect.contains(chair)) {
        canvas.drawCircle(
          chair,
          3.2,
          Paint()..color = const Color(0xFFE2C6A5),
        );
        canvas.drawCircle(chair, 3.2, stroke);
      }
    }

    canvas.drawCircle(
      table.center,
      3,
      Paint()..color = const Color(0xFF5E8C48),
    );
  }

  void _drawKitchen(Canvas canvas, Rect rect) {
    if (rect.width < 32 || rect.height < 24) return;

    final Paint stroke = Paint()
      ..color = const Color(0xFF6F6859)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Paint cabinet = Paint()..color = const Color(0xFFEFE5D3);

    final double counterDepth = math.min(rect.height * 0.20, 17);
    final double sideDepth = math.min(rect.width * 0.20, 16);

    final Rect topCounter = Rect.fromLTWH(
      rect.left + 4,
      rect.top + 4,
      rect.width - 8,
      counterDepth,
    );

    final Rect sideCounter = Rect.fromLTWH(
      rect.right - sideDepth - 4,
      rect.top + 4,
      sideDepth,
      rect.height - 8,
    );

    canvas.drawRect(topCounter, cabinet);
    canvas.drawRect(topCounter, stroke);

    canvas.drawRect(sideCounter, cabinet);
    canvas.drawRect(sideCounter, stroke);

    final Rect sink = Rect.fromLTWH(
      topCounter.left + topCounter.width * 0.55,
      topCounter.top + 3,
      math.min(13, topCounter.width * 0.16),
      math.max(6, topCounter.height - 6),
    );

    canvas.drawRect(sink, stroke);

    final Offset stoveCenter = Offset(
      sideCounter.center.dx,
      sideCounter.top + sideCounter.height * 0.35,
    );

    canvas.drawCircle(stoveCenter, 3.2, stroke);
    canvas.drawCircle(
      Offset(stoveCenter.dx, stoveCenter.dy + 8),
      3.2,
      stroke,
    );

    if (rect.width > 55 && rect.height > 42) {
      final Rect island = Rect.fromCenter(
        center: Offset(rect.center.dx - rect.width * 0.05, rect.center.dy + 3),
        width: math.min(rect.width * 0.35, 34),
        height: math.min(rect.height * 0.18, 15),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(island, const Radius.circular(4)),
        Paint()..color = const Color(0xFFF6F1E8),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(island, const Radius.circular(4)),
        stroke,
      );
    }
  }

  void _drawBathroom(Canvas canvas, Rect rect) {
    if (rect.width < 24 || rect.height < 22) return;

    final Paint stroke = Paint()
      ..color = const Color(0xFF4E7A86)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Rect shower = Rect.fromLTWH(
      rect.left + 4,
      rect.top + 4,
      math.min(rect.width * 0.30, 13),
      math.min(rect.height * 0.30, 13),
    );

    final Rect wc = Rect.fromLTWH(
      rect.left + rect.width * 0.17,
      rect.bottom - rect.height * 0.34,
      math.min(rect.width * 0.22, 10),
      math.min(rect.height * 0.22, 10),
    );

    final Rect sink = Rect.fromLTWH(
      rect.right - rect.width * 0.25,
      rect.top + rect.height * 0.18,
      math.min(rect.width * 0.18, 9),
      math.min(rect.height * 0.16, 8),
    );

    canvas.drawRect(shower, stroke);
    canvas.drawOval(wc, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sink, const Radius.circular(2)),
      stroke,
    );

    if (rect.width > 35 && rect.height > 32) {
      canvas.drawCircle(
        Offset(rect.left + rect.width * 0.55, rect.bottom - rect.height * 0.25),
        3,
        Paint()..color = const Color(0xAAFFFFFF),
      );
    }
  }

  void _drawService(Canvas canvas, Rect rect) {
    if (rect.width < 22 || rect.height < 20) return;

    final Paint stroke = Paint()
      ..color = const Color(0xFF777777)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Rect machine = Rect.fromCenter(
      center: rect.center,
      width: math.min(16, rect.width * 0.42),
      height: math.min(16, rect.height * 0.42),
    );

    canvas.drawRect(machine, stroke);
    canvas.drawCircle(machine.center, machine.width * 0.28, stroke);
  }

  void _drawAccent(Canvas canvas, Rect rect) {
    if (rect.width < 26 || rect.height < 22) return;

    final Rect table = Rect.fromCenter(
      center: rect.center,
      width: math.min(rect.width * 0.35, 22),
      height: math.min(rect.height * 0.16, 10),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(table, const Radius.circular(4)),
      Paint()..color = const Color(0xFFE7D2B5),
    );
  }

  void _drawCarport(Canvas canvas, Rect rect) {
    if (rect.width < 28 || rect.height < 28) return;

    final bool twoCars = rect.width > 48;
    final int count = twoCars ? 2 : 1;
    final double slotW = rect.width / count;

    for (int i = 0; i < count; i++) {
      final double cx = rect.left + slotW * (i + 0.5);

      final Rect car = Rect.fromCenter(
        center: Offset(cx, rect.center.dy),
        width: math.min(slotW * 0.55, 20),
        height: math.min(rect.height * 0.70, 42),
      );

      final Paint body = Paint()
        ..color = i == 0 ? const Color(0xFFE6E6E6) : const Color(0xFF2F2F2F);

      canvas.drawRRect(
        RRect.fromRectAndRadius(car, const Radius.circular(5)),
        body,
      );

      final Rect windshield = Rect.fromLTWH(
        car.left + 3,
        car.top + car.height * 0.16,
        car.width - 6,
        car.height * 0.20,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(windshield, const Radius.circular(2)),
        Paint()..color = const Color(0xFFBBD8E8),
      );

      final Rect rearGlass = Rect.fromLTWH(
        car.left + 3,
        car.bottom - car.height * 0.28,
        car.width - 6,
        car.height * 0.16,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rearGlass, const Radius.circular(2)),
        Paint()..color = const Color(0xFFBBD8E8),
      );
    }
  }

  void _drawTerraceSet(Canvas canvas, Rect rect) {
    if (rect.width < 28 || rect.height < 24) return;

    final Offset center = rect.center;

    canvas.drawCircle(
      center,
      math.min(rect.width, rect.height) * 0.12,
      Paint()..color = const Color(0xFFD6AC78),
    );

    final Paint chair = Paint()..color = const Color(0xFFE8D5B8);

    final List<Offset> chairs = <Offset>[
      Offset(center.dx - 11, center.dy),
      Offset(center.dx + 11, center.dy),
      Offset(center.dx, center.dy - 10),
    ];

    for (final Offset item in chairs) {
      if (rect.contains(item)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: item, width: 8, height: 6),
            const Radius.circular(2),
          ),
          chair,
        );
      }
    }
  }

  void _drawLandscape(Canvas canvas, Rect rect) {
    if (rect.width < 18 || rect.height < 18) return;

    final List<Offset> treeCenters = <Offset>[
      Offset(rect.left + rect.width * 0.20, rect.top + rect.height * 0.34),
      Offset(rect.left + rect.width * 0.48, rect.top + rect.height * 0.58),
      Offset(rect.left + rect.width * 0.75, rect.top + rect.height * 0.36),
    ];

    final Paint trunk = Paint()..color = const Color(0xFF805C38);
    final Paint leafA = Paint()..color = const Color(0xFF4F8737);
    final Paint leafB = Paint()..color = const Color(0xFF79AA59);
    final Paint flower = Paint()..color = const Color(0xFFEAC0CA);

    for (final Offset c in treeCenters) {
      if (!rect.contains(c)) continue;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy + 6),
          width: 2.5,
          height: 8,
        ),
        trunk,
      );

      canvas.drawCircle(c, 5.2, leafA);
      canvas.drawCircle(Offset(c.dx + 4, c.dy - 1), 4.1, leafB);
      canvas.drawCircle(Offset(c.dx - 4, c.dy - 1), 4.0, leafB);
    }

    for (int i = 0; i < 8; i++) {
      final double x = rect.left + rect.width * ((i * 0.13 + 0.12) % 0.9);
      final double y = rect.top + rect.height * ((i * 0.21 + 0.2) % 0.8);

      canvas.drawCircle(
        Offset(x, y),
        1.3,
        flower,
      );
    }
  }

  void _drawPremiumGrass(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF84AE65),
    );

    canvas.save();
    canvas.clipRect(rect);

    final Paint diagonalA = Paint()
      ..color = const Color(0xFF6F9A52)
      ..strokeWidth = 1;

    final Paint diagonalB = Paint()
      ..color = const Color(0xFFA5CA84)
      ..strokeWidth = 1;

    for (double x = rect.left - rect.height;
        x < rect.right + rect.height;
        x += 11) {
      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(x + rect.height, rect.top),
        diagonalA,
      );
    }

    for (double x = rect.left - rect.height;
        x < rect.right + rect.height;
        x += 17) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x + rect.height, rect.bottom),
        diagonalB,
      );
    }

    final Paint dot = Paint()..color = const Color(0x33577C42);

    for (double x = rect.left + 4; x < rect.right; x += 10) {
      for (double y = rect.top + 4; y < rect.bottom; y += 10) {
        canvas.drawCircle(Offset(x, y), 0.7, dot);
      }
    }

    canvas.restore();
  }

  void _drawPaving(Canvas canvas, Rect rect, Color baseColor, {bool darker = false}) {
    canvas.drawRect(
      rect,
      Paint()..color = baseColor,
    );

    canvas.save();
    canvas.clipRect(rect);

    final Paint line = Paint()
      ..color = Colors.white.withOpacity(darker ? 0.25 : 0.38)
      ..strokeWidth = 1;

    for (double x = rect.left; x < rect.right; x += 12) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        line,
      );
    }

    for (double y = rect.top; y < rect.bottom; y += 12) {
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        line,
      );
    }

    canvas.restore();
  }

  void _drawWoodDeck(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFFB47A47),
    );

    canvas.save();
    canvas.clipRect(rect);

    final Paint line = Paint()
      ..color = const Color(0xFF875632)
      ..strokeWidth = 1.1;

    for (double x = rect.left + 4; x < rect.right; x += 8) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        line,
      );
    }

    canvas.restore();
  }

  void _drawWater(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF78C2DA),
    );

    canvas.save();
    canvas.clipRect(rect);

    final Paint wave = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 1.1;

    for (double y = rect.top + 5; y < rect.bottom; y += 8) {
      for (double x = rect.left; x < rect.right; x += 16) {
        final Path path = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 4, y - 2, x + 8, y)
          ..quadraticBezierTo(x + 12, y + 2, x + 16, y);

        canvas.drawPath(path, wave);
      }
    }

    canvas.restore();
  }

  void _drawPremiumWood(Canvas canvas, Rect rect, Color baseColor) {
    canvas.drawRect(
      rect,
      Paint()..color = baseColor,
    );

    canvas.save();
    canvas.clipRect(rect);

    final Paint plank = Paint()
      ..color = const Color(0xAA7E4F2E)
      ..strokeWidth = 1;

    for (double x = rect.left + 6; x < rect.right; x += 8) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        plank,
      );
    }

    final Paint grain = Paint()
      ..color = const Color(0x33845C3F)
      ..strokeWidth = 0.7;

    for (double y = rect.top + 9; y < rect.bottom; y += 14) {
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y + 2),
        grain,
      );
    }

    canvas.restore();
  }

  void _drawPremiumTiles(Canvas canvas, Rect rect, Color baseColor, {bool small = false}) {
    canvas.drawRect(
      rect,
      Paint()..color = baseColor,
    );

    canvas.save();
    canvas.clipRect(rect);

    final double spacing = small ? 9 : 13;

    final Paint grout = Paint()
      ..color = Colors.white.withOpacity(0.50)
      ..strokeWidth = 0.9;

    for (double x = rect.left; x < rect.right; x += spacing) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        grout,
      );
    }

    for (double y = rect.top; y < rect.bottom; y += spacing) {
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        grout,
      );
    }

    canvas.restore();
  }

  void _drawLargeFormatTiles(Canvas canvas, Rect rect, Color baseColor) {
    canvas.drawRect(
      rect,
      Paint()..color = baseColor,
    );

    canvas.save();
    canvas.clipRect(rect);

    final Paint grout = Paint()
      ..color = const Color(0x80C5B893)
      ..strokeWidth = 1;

    for (double x = rect.left + 10; x < rect.right; x += 22) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        grout,
      );
    }

    for (double y = rect.top + 10; y < rect.bottom; y += 22) {
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        grout,
      );
    }

    canvas.restore();
  }

  void _drawMarbleTiles(Canvas canvas, Rect rect, Color baseColor) {
    canvas.drawRect(
      rect,
      Paint()..color = baseColor,
    );

    canvas.save();
    canvas.clipRect(rect);

    final Paint vein = Paint()
      ..color = const Color(0x55A0907A)
      ..strokeWidth = 0.8;

    for (double x = rect.left - 20; x < rect.right; x += 18) {
      final Path p = Path()
        ..moveTo(x, rect.top)
        ..quadraticBezierTo(
          x + 8,
          rect.center.dy,
          x + 2,
          rect.bottom,
        );

      canvas.drawPath(p, vein);
    }

    final Paint grout = Paint()
      ..color = Colors.white.withOpacity(0.42)
      ..strokeWidth = 0.8;

    for (double x = rect.left; x < rect.right; x += 14) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        grout,
      );
    }

    for (double y = rect.top; y < rect.bottom; y += 14) {
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        grout,
      );
    }

    canvas.restore();
  }

  void _drawCleanLabel(Canvas canvas, Rect rect, RoomModel room) {
    if (rect.width < 20 || rect.height < 18) return;

    final String name = room.nama;
    final String lower = name.toLowerCase();

    final bool tiny = rect.width < 44 || rect.height < 32;
    final bool small = rect.width < 66 || rect.height < 44;
    final bool outdoor = _isOutdoor(room.nama, room.category);
    final bool circulation = lower.contains('koridor') ||
        lower.contains('sirkulasi') ||
        lower.contains('hall');

    if (circulation && (rect.width < 50 || rect.height < 80)) {
      _drawCenteredText(
        canvas,
        'Koridor',
        rect.center,
        fontSize: 5.5,
        fontWeight: FontWeight.w700,
        color: _textDark,
        maxWidth: rect.width - 6,
      );
      return;
    }

    final double area = room.width * room.height;

    final List<String> lines = <String>[];

    if (tiny) {
      lines.add(_shortName(name));
    } else if (small) {
      lines.add(_shortName(name));
      lines.add('${area.toStringAsFixed(1)} m2');
    } else {
      lines.add(name);
      lines.add('${area.toStringAsFixed(1)} m2');
    }

    final double titleSize = tiny
        ? 5.6
        : small
            ? 6.2
            : outdoor
                ? 6.8
                : 7.3;

    final double subSize = tiny
        ? 4.9
        : small
            ? 5.4
            : 6.0;

    final double lineHeight = tiny ? 6.1 : 7.2;

    final double chipW = math.min(
      rect.width - 7,
      tiny
          ? 40
          : small
              ? 58
              : 84,
    );

    final double chipH = math.min(
      rect.height - 6,
      8 + (lines.length * lineHeight),
    );

    if (chipW < 24 || chipH < 12) return;

    final Offset desired = _smartLabelPosition(rect, room.nama);

    final Rect rawChip = Rect.fromCenter(
      center: desired,
      width: chipW,
      height: chipH,
    );

    final Rect chip = Rect.fromLTWH(
      rawChip.left.clamp(rect.left + 3, rect.right - chipW - 3).toDouble(),
      rawChip.top.clamp(rect.top + 3, rect.bottom - chipH - 3).toDouble(),
      chipW,
      chipH,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(chip, const Radius.circular(5)),
      Paint()..color = Colors.white.withOpacity(0.84),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(chip, const Radius.circular(5)),
      Paint()
        ..color = Colors.black.withOpacity(0.09)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke,
    );

    double y = chip.top + 4;

    for (int i = 0; i < lines.length; i++) {
      final bool first = i == 0;

      _drawCenteredText(
        canvas,
        lines[i],
        Offset(chip.center.dx, y + (first ? titleSize : subSize) / 2),
        fontSize: first ? titleSize : subSize,
        fontWeight: first ? FontWeight.w900 : FontWeight.w600,
        color: _textDark,
        maxWidth: chip.width - 7,
      );

      y += lineHeight;
    }
  }

  Offset _smartLabelPosition(Rect rect, String roomName) {
    final String name = roomName.toLowerCase();

    if (name.contains('tidur')) {
      return Offset(rect.center.dx, rect.bottom - rect.height * 0.22);
    }

    if (name.contains('keluarga') || name.contains('tamu')) {
      return Offset(rect.center.dx, rect.bottom - rect.height * 0.22);
    }

    if (name.contains('dapur') || name.contains('makan')) {
      return Offset(rect.center.dx, rect.center.dy + rect.height * 0.18);
    }

    if (name.contains('mandi') || name.contains('wc') || name.contains('km')) {
      return Offset(rect.center.dx, rect.center.dy + rect.height * 0.12);
    }

    if (name.contains('carport') ||
        name.contains('teras') ||
        name.contains('taman') ||
        name.contains('inner court')) {
      return rect.center;
    }

    return rect.center;
  }

  String _shortName(String name) {
    final String lower = name.toLowerCase();

    if (lower.contains('tidur utama')) return 'KT Utama';

    if (lower.contains('tidur')) {
      return name.replaceAll('K. Tidur', 'KT');
    }

    if (lower.contains('keluarga')) return 'Keluarga';
    if (lower.contains('ruang tamu')) return 'Tamu';
    if (lower.contains('makan')) return 'Makan';
    if (lower.contains('dapur')) return 'Dapur';
    if (lower.contains('mandi') || lower.contains('wc')) return 'KM/WC';
    if (lower.contains('cuci')) return 'Cuci';
    if (lower.contains('carport')) return 'Carport';
    if (lower.contains('teras')) return 'Teras';
    if (lower.contains('taman depan')) return 'Taman Depan';
    if (lower.contains('taman belakang')) return 'Taman Belakang';
    if (lower.contains('inner court')) return 'Inner Court';
    if (lower.contains('koridor')) return 'Koridor';

    return name;
  }

  void _drawLegend(Canvas canvas, Rect boardRect) {
    final Rect box = Rect.fromLTWH(
      boardRect.right - 128,
      boardRect.bottom - 54,
      116,
      42,
    );

    final RRect r = RRect.fromRectAndRadius(
      box,
      const Radius.circular(10),
    );

    canvas.drawRRect(
      r.shift(const Offset(2, 3)),
      Paint()..color = const Color(0x16000000),
    );

    canvas.drawRRect(
      r,
      Paint()..color = const Color(0xFAFFFFFF),
    );

    canvas.drawRRect(
      r,
      Paint()
        ..color = const Color(0xFFD0D0D0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _drawText(
      canvas,
      'Legenda',
      Offset(box.left + 8, box.top + 5),
      fontSize: 7.4,
      fontWeight: FontWeight.w900,
      color: _textDark,
      maxWidth: 60,
    );

    canvas.drawLine(
      Offset(box.left + 8, box.top + 22),
      Offset(box.left + 25, box.top + 22),
      Paint()
        ..color = _wall
        ..strokeWidth = 3.2,
    );

    _drawText(
      canvas,
      'Dinding',
      Offset(box.left + 31, box.top + 18),
      fontSize: 6.5,
      fontWeight: FontWeight.w600,
      color: _textDark,
      maxWidth: 48,
    );

    canvas.drawLine(
      Offset(box.left + 8, box.top + 32),
      Offset(box.left + 25, box.top + 32),
      Paint()
        ..color = _window
        ..strokeWidth = 2.2,
    );

    _drawText(
      canvas,
      'Jendela',
      Offset(box.left + 31, box.top + 28),
      fontSize: 6.5,
      fontWeight: FontWeight.w600,
      color: _textDark,
      maxWidth: 48,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    required double maxWidth,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, offset);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    required double maxWidth,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: 1.0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);

    painter.paint(
      canvas,
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant ProfessionalFloorPlanPainter oldDelegate) {
    if (oldDelegate.landWidth != landWidth) return true;
    if (oldDelegate.landLength != landLength) return true;
    if (oldDelegate.title != title) return true;
    if (oldDelegate.rooms.length != rooms.length) return true;

    for (int i = 0; i < rooms.length; i++) {
      final RoomModel oldRoom = oldDelegate.rooms[i];
      final RoomModel newRoom = rooms[i];

      if (oldRoom.nama != newRoom.nama ||
          oldRoom.category != newRoom.category ||
          oldRoom.x != newRoom.x ||
          oldRoom.y != newRoom.y ||
          oldRoom.width != newRoom.width ||
          oldRoom.height != newRoom.height) {
        return true;
      }
    }

    return false;
  }
}







