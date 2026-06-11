import 'dart:math' as math;

import 'package:smart_floor_plan/app/data/models/room_model.dart';

enum LandShape {
  portrait,
  balanced,
  landscape,
}

enum LandSizeClass {
  compact,
  medium,
  family,
  premium,
}

class LayoutSlot {
  final String nama;
  final String category;
  final String doorSide;

  /// Posisi dan ukuran relatif 0.0 - 1.0 pada lahan.
  final double x;
  final double y;
  final double width;
  final double height;

  final bool isOutdoor;

  const LayoutSlot({
    required this.nama,
    required this.category,
    required this.doorSide,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isOutdoor = false,
  });

  RoomModel toRoom({
    required double originX,
    required double originY,
    required double usableWidth,
    required double usableLength,
  }) {
    return RoomModel(
      nama: nama,
      category: category,
      doorSide: doorSide,
      isOutdoor: isOutdoor,
      x: originX + (x * usableWidth),
      y: originY + (y * usableLength),
      width: math.max(0.85, width * usableWidth).toDouble(),
      height: math.max(0.85, height * usableLength).toDouble(),
    );
  }
}

class FloorPlanTemplate {
  final String id;
  final String name;
  final String description;
  final LandShape shape;
  final LandSizeClass sizeClass;
  final List<LayoutSlot> slots;

  const FloorPlanTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.shape,
    required this.sizeClass,
    required this.slots,
  });

  List<RoomModel> buildRooms({
    required double landWidth,
    required double landLength,
  }) {
    final double smallestSide = math.min(landWidth, landLength);
    final double margin =
        (smallestSide * 0.032).clamp(0.18, 0.40).toDouble();

    final double usableWidth = landWidth - (margin * 2);
    final double usableLength = landLength - (margin * 2);

    return slots.map((slot) {
      return slot.toRoom(
        originX: margin,
        originY: margin,
        usableWidth: usableWidth,
        usableLength: usableLength,
      );
    }).toList();
  }
}