import 'dart:math';

import 'package:smart_floor_plan/app/core/floorplan/room_recommendation.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';

class SmartFloorPlanResult {
  final double landWidth;
  final double landLength;
  final List<RoomModel> rooms;
  final List<RoomRecommendation> recommendations;

  const SmartFloorPlanResult({
    required this.landWidth,
    required this.landLength,
    required this.rooms,
    required this.recommendations,
  });
}

class SmartFloorPlanEngine {
  static List<RoomRecommendation> getRecommendations({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
  }) {
    final area = landWidth * landLength;

    final rooms = <RoomRecommendation>[
      const RoomRecommendation(
        name: 'Teras',
        category: 'outdoor',
        width: 3.0,
        height: 1.2,
      ),
      const RoomRecommendation(
        name: 'Ruang Tamu',
        category: 'living',
        width: 3.2,
        height: 3.4,
      ),
      const RoomRecommendation(
        name: 'Dapur',
        category: 'kitchen',
        width: 2.5,
        height: 2.8,
      ),
      const RoomRecommendation(
        name: 'Kamar Mandi',
        category: 'bath',
        width: 1.6,
        height: 2.0,
      ),
      const RoomRecommendation(
        name: 'K. Tidur Utama',
        category: 'bedroom',
        width: 3.2,
        height: 4.0,
      ),
    ];

    if (bedroomCount >= 2 || area >= 70) {
      rooms.add(
        const RoomRecommendation(
          name: 'K. Tidur 1',
          category: 'bedroom',
          width: 3.0,
          height: 3.2,
        ),
      );
    }

    if (bedroomCount >= 3 || area >= 100) {
      rooms.add(
        const RoomRecommendation(
          name: 'K. Tidur 2',
          category: 'bedroom',
          width: 3.0,
          height: 3.2,
        ),
      );
    }

    if (area >= 75) {
      rooms.add(
        const RoomRecommendation(
          name: 'Ruang Keluarga',
          category: 'family',
          width: 3.5,
          height: 4.0,
        ),
      );
    }

    if (area >= 85) {
      rooms.add(
        const RoomRecommendation(
          name: 'R. Makan',
          category: 'dining',
          width: 3.0,
          height: 2.8,
        ),
      );
    }

    if (area >= 95) {
      rooms.add(
        const RoomRecommendation(
          name: 'Carport',
          category: 'outdoor',
          width: 3.0,
          height: 4.5,
        ),
      );
    }

    if (area >= 100) {
      rooms.add(
        const RoomRecommendation(
          name: 'Taman',
          category: 'outdoor',
          width: 2.5,
          height: 3.5,
        ),
      );
    }

    if (area >= 115) {
      rooms.add(
        const RoomRecommendation(
          name: 'Jemuran',
          category: 'service',
          width: 3.0,
          height: 2.0,
        ),
      );
    }

    return rooms;
  }

  static SmartFloorPlanResult generate({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
    List<RoomRecommendation> extraRooms = const [],
  }) {
    final safeLandWidth = max(5.0, landWidth);
    final safeLandLength = max(7.0, landLength);

    final recommendations = getRecommendations(
      landWidth: safeLandWidth,
      landLength: safeLandLength,
      bedroomCount: bedroomCount,
    );

    final rooms = <RoomModel>[];

    void addSmart(RoomModel room) {
      final safeRoom = _clampToLand(
        room,
        safeLandWidth,
        safeLandLength,
      );

      if (!_hasCollision(safeRoom, rooms)) {
        rooms.add(safeRoom);
        return;
      }

      final freeRoom = _findFreePosition(
        room: safeRoom,
        placedRooms: rooms,
        landWidth: safeLandWidth,
        landLength: safeLandLength,
      );

      if (freeRoom != null) {
        rooms.add(freeRoom);
      }
    }

    final totalArea = safeLandWidth * safeLandLength;
    final isMediumLand = totalArea >= 70;
    final isLargeLand = totalArea >= 100;

    if (isLargeLand) {
      addSmart(
        RoomModel(
          nama: 'Carport',
          x: 0.3,
          y: 0.3,
          width: min(3.2, safeLandWidth * 0.30),
          height: min(4.5, safeLandLength * 0.28),
          category: 'outdoor',
          doorSide: 'right',
          isOutdoor: true,
        ),
      );

      addSmart(
        RoomModel(
          nama: 'Taman',
          x: 0.3,
          y: 5.1,
          width: min(3.2, safeLandWidth * 0.30),
          height: min(3.6, safeLandLength * 0.22),
          category: 'outdoor',
          doorSide: 'right',
          isOutdoor: true,
        ),
      );
    }

    addSmart(
      RoomModel(
        nama: 'Teras',
        x: max(0.4, (safeLandWidth / 2) - 1.8),
        y: safeLandLength - 1.45,
        width: min(3.6, safeLandWidth * 0.42),
        height: 1.15,
        category: 'outdoor',
        doorSide: 'top',
        isOutdoor: true,
      ),
    );

    addSmart(
      RoomModel(
        nama: 'Ruang Tamu',
        x: max(0.5, (safeLandWidth / 2) - 1.8),
        y: safeLandLength - 5.2,
        width: min(3.8, safeLandWidth * 0.40),
        height: min(3.5, safeLandLength * 0.24),
        category: 'living',
        doorSide: 'bottom',
      ),
    );

    addSmart(
      RoomModel(
        nama: 'K. Tidur Utama',
        x: 0.35,
        y: safeLandLength - 6.4,
        width: min(3.4, safeLandWidth * 0.36),
        height: min(4.4, safeLandLength * 0.28),
        category: 'bedroom',
        doorSide: 'right',
      ),
    );

    if (bedroomCount >= 2) {
      addSmart(
        RoomModel(
          nama: 'K. Tidur 1',
          x: safeLandWidth - min(3.2, safeLandWidth * 0.34) - 0.35,
          y: safeLandLength - 5.4,
          width: min(3.2, safeLandWidth * 0.34),
          height: min(3.6, safeLandLength * 0.23),
          category: 'bedroom',
          doorSide: 'left',
        ),
      );
    }

    if (isMediumLand) {
      addSmart(
        RoomModel(
          nama: 'R. Keluarga',
          x: max(0.5, (safeLandWidth / 2) - 1.9),
          y: max(4.7, safeLandLength - 9.6),
          width: min(3.8, safeLandWidth * 0.42),
          height: min(3.8, safeLandLength * 0.25),
          category: 'family',
          doorSide: 'bottom',
        ),
      );
    }

    if (bedroomCount >= 3) {
      addSmart(
        RoomModel(
          nama: 'K. Tidur 2',
          x: safeLandWidth - min(3.2, safeLandWidth * 0.34) - 0.35,
          y: max(4.5, safeLandLength - 9.4),
          width: min(3.2, safeLandWidth * 0.34),
          height: min(3.6, safeLandLength * 0.23),
          category: 'bedroom',
          doorSide: 'left',
        ),
      );
    }

    addSmart(
      RoomModel(
        nama: 'Kamar Mandi',
        x: max(0.5, (safeLandWidth / 2) - 3.0),
        y: max(4.0, safeLandLength - 8.0),
        width: 1.7,
        height: 2.0,
        category: 'bath',
        doorSide: 'right',
      ),
    );

    if (isLargeLand) {
      addSmart(
        RoomModel(
          nama: 'Kamar Mandi',
          x: safeLandWidth - 2.3,
          y: max(6.8, safeLandLength - 8.0),
          width: 1.8,
          height: 2.0,
          category: 'bath',
          doorSide: 'left',
        ),
      );
    }

    addSmart(
      RoomModel(
        nama: 'Dapur',
        x: max(0.5, (safeLandWidth / 2) - 1.6),
        y: 1.2,
        width: min(2.8, safeLandWidth * 0.32),
        height: min(3.0, safeLandLength * 0.22),
        category: 'kitchen',
        doorSide: 'left',
      ),
    );

    if (isMediumLand) {
      addSmart(
        RoomModel(
          nama: 'R. Makan',
          x: safeLandWidth - min(3.6, safeLandWidth * 0.38) - 0.35,
          y: 2.4,
          width: min(3.6, safeLandWidth * 0.38),
          height: min(3.0, safeLandLength * 0.22),
          category: 'dining',
          doorSide: 'left',
        ),
      );
    }

    if (totalArea >= 115) {
      addSmart(
        RoomModel(
          nama: 'Jemuran',
          x: safeLandWidth - min(4.0, safeLandWidth * 0.42) - 0.35,
          y: 0.35,
          width: min(4.0, safeLandWidth * 0.42),
          height: min(1.8, safeLandLength * 0.12),
          category: 'service',
          doorSide: 'left',
          isOutdoor: true,
        ),
      );
    }

    for (final extra in extraRooms.where((item) => item.selected)) {
      final alreadyExists = rooms.any(
        (room) => room.nama.toLowerCase() == extra.name.toLowerCase(),
      );

      if (alreadyExists) continue;

      addSmart(
        RoomModel(
          nama: extra.name,
          x: 0.5,
          y: 0.5,
          width: extra.width,
          height: extra.height,
          category: extra.category,
          doorSide: 'bottom',
          isOutdoor: extra.category == 'outdoor',
        ),
      );
    }

    return SmartFloorPlanResult(
      landWidth: safeLandWidth,
      landLength: safeLandLength,
      rooms: rooms,
      recommendations: recommendations,
    );
  }

  static RoomModel _clampToLand(
    RoomModel room,
    double landWidth,
    double landLength,
  ) {
    final newWidth = min(room.width, landWidth - 0.6);
    final newHeight = min(room.height, landLength - 0.6);

    final newX = room.x
        .clamp(0.3, landWidth - newWidth - 0.3)
        .toDouble();

    final newY = room.y
        .clamp(0.3, landLength - newHeight - 0.3)
        .toDouble();

    return room.copyWith(
      x: newX,
      y: newY,
      width: newWidth,
      height: newHeight,
    );
  }

  static bool _hasCollision(
    RoomModel room,
    List<RoomModel> placedRooms,
  ) {
    for (final other in placedRooms) {
      if (_intersects(room, other)) {
        return true;
      }
    }

    return false;
  }

  static bool _intersects(RoomModel a, RoomModel b) {
    const gap = 0.12;

    final aLeft = a.x - gap;
    final aRight = a.x + a.width + gap;
    final aTop = a.y - gap;
    final aBottom = a.y + a.height + gap;

    final bLeft = b.x;
    final bRight = b.x + b.width;
    final bTop = b.y;
    final bBottom = b.y + b.height;

    return aLeft < bRight &&
        aRight > bLeft &&
        aTop < bBottom &&
        aBottom > bTop;
  }

  static RoomModel? _findFreePosition({
    required RoomModel room,
    required List<RoomModel> placedRooms,
    required double landWidth,
    required double landLength,
  }) {
    final scaleOptions = [1.0, 0.92, 0.85, 0.78];

    for (final scaleFactor in scaleOptions) {
      final newWidth = max(1.3, room.width * scaleFactor);
      final newHeight = max(1.3, room.height * scaleFactor);

      for (double y = 0.3; y <= landLength - newHeight - 0.3; y += 0.35) {
        for (double x = 0.3; x <= landWidth - newWidth - 0.3; x += 0.35) {
          final candidate = room.copyWith(
            x: x,
            y: y,
            width: newWidth,
            height: newHeight,
          );

          if (!_hasCollision(candidate, placedRooms)) {
            return candidate;
          }
        }
      }
    }

    return null;
  }
}