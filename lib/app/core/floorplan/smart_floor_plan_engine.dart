import 'dart:math' as math;

import 'package:smart_floor_plan/app/core/floorplan/room_recommendation.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';

class SmartFloorPlanResult {
  final double landWidth;
  final double landLength;
  final List<RoomModel> rooms;

  const SmartFloorPlanResult({
    required this.landWidth,
    required this.landLength,
    required this.rooms,
  });

  double get landArea => landWidth * landLength;

  double get usedArea {
    return rooms.fold<double>(
      0,
      (total, room) => total + (room.width * room.height),
    );
  }
}

class SmartFloorPlanEngine {
  static const double minRoomSize = 1.2;

  static List<RoomRecommendation> getRecommendations({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
  }) {
    final int roomCount = bedroomCount <= 0
        ? estimateBedroomCount(
            landWidth: landWidth,
            landLength: landLength,
          )
        : bedroomCount.clamp(1, 5);

    final SmartFloorPlanResult result = generate(
      landWidth: landWidth,
      landLength: landLength,
      bedroomCount: roomCount,
      extraRooms: const <RoomRecommendation>[],
    );

    return result.rooms
        .where((room) => !_isHiddenFromRecommendation(room.nama))
        .map(
          (room) => RoomRecommendation(
            name: room.nama,
            category: room.category,
            width: room.width,
            height: room.height,
            selected: true,
          ),
        )
        .toList();
  }

  static SmartFloorPlanResult generate({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
    List<RoomRecommendation> extraRooms = const <RoomRecommendation>[],
  }) {
    final double safeWidth = _safeDimension(landWidth, fallback: 8);
    final double safeLength = _safeDimension(landLength, fallback: 12);
    final double area = safeWidth * safeLength;
    final double ratio = safeWidth / safeLength;

    final int roomCount = bedroomCount <= 0
        ? estimateBedroomCount(
            landWidth: safeWidth,
            landLength: safeLength,
          )
        : bedroomCount.clamp(1, 5);

    final List<RoomModel> rooms;

    if (area <= 60) {
      rooms = _buildCompactNaturalHouse(
        landWidth: safeWidth,
        landLength: safeLength,
        bedroomCount: roomCount.clamp(1, 2),
        extraRooms: extraRooms,
      );
    } else if (area <= 140) {
      if (ratio >= 0.85) {
        rooms = _buildWideMediumHouse(
          landWidth: safeWidth,
          landLength: safeLength,
          bedroomCount: roomCount.clamp(2, 3),
          extraRooms: extraRooms,
        );
      } else {
        rooms = _buildMediumNaturalHouse(
          landWidth: safeWidth,
          landLength: safeLength,
          bedroomCount: roomCount.clamp(2, 3),
          extraRooms: extraRooms,
        );
      }
    } else {
      if (ratio >= 0.78) {
        rooms = _buildWideLargeHouse(
          landWidth: safeWidth,
          landLength: safeLength,
          bedroomCount: roomCount.clamp(3, 5),
          extraRooms: extraRooms,
        );
      } else {
        rooms = _buildLargeNaturalHouse(
          landWidth: safeWidth,
          landLength: safeLength,
          bedroomCount: roomCount.clamp(3, 5),
          extraRooms: extraRooms,
        );
      }
    }

    return SmartFloorPlanResult(
      landWidth: safeWidth,
      landLength: safeLength,
      rooms: _normalizeRooms(rooms, safeWidth, safeLength),
    );
  }

  static int estimateBedroomCount({
    required double landWidth,
    required double landLength,
  }) {
    final double area = landWidth * landLength;

    if (area <= 55) return 1;
    if (area <= 100) return 2;
    if (area <= 170) return 3;
    return 4;
  }

  static List<RoomModel> _buildCompactNaturalHouse({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
    required List<RoomRecommendation> extraRooms,
  }) {
    final List<RoomModel> rooms = <RoomModel>[];

    final double w = landWidth;
    final double l = landLength;

    final double side = _clamp(w * 0.06, 0.35, 0.70);
    final double frontYard = _clamp(l * 0.12, 1.0, 1.6);
    final double backYard = _clamp(l * 0.08, 0.8, 1.2);

    final double buildX = side;
    final double buildW = w - (side * 2);
    final double buildY = backYard;
    final double buildH = l - frontYard - backYard;

    final double frontDepth = _clamp(buildH * 0.24, 2.1, 2.8);
    final double middleDepth = _clamp(buildH * 0.34, 2.8, 3.7);
    final double backDepth = math.max(
      minRoomSize,
      buildH - frontDepth - middleDepth,
    );

    final double yBack = buildY;
    final double yMiddle = buildY + backDepth;
    final double yFront = buildY + backDepth + middleDepth;

    final double terraceW = _clamp(buildW * 0.32, 1.7, 2.4);
    final double livingW = buildW - terraceW;

    _addRoom(
      rooms,
      nama: 'Taman Depan',
      category: 'outdoor',
      x: side,
      y: yFront + frontDepth,
      width: buildW,
      height: frontYard,
    );

    _addRoom(
      rooms,
      nama: 'Teras',
      category: 'outdoor',
      x: buildX,
      y: yFront,
      width: terraceW,
      height: frontDepth,
    );

    _addRoom(
      rooms,
      nama: 'Ruang Tamu',
      category: 'living',
      x: buildX + terraceW,
      y: yFront,
      width: livingW,
      height: frontDepth,
    );

    _addRoom(
      rooms,
      nama: 'R. Keluarga',
      category: 'family',
      x: buildX,
      y: yMiddle,
      width: buildW,
      height: middleDepth,
    );

    if (bedroomCount <= 1) {
      final double bathW = _clamp(buildW * 0.30, 1.6, 2.2);
      final double kitchenW = buildW - bathW;

      _addRoom(
        rooms,
        nama: 'K. Tidur Utama',
        category: 'bedroom',
        x: buildX,
        y: yBack,
        width: kitchenW,
        height: backDepth * 0.56,
      );

      _addRoom(
        rooms,
        nama: 'Dapur',
        category: 'kitchen',
        x: buildX,
        y: yBack + backDepth * 0.56,
        width: kitchenW,
        height: backDepth * 0.44,
      );

      _addRoom(
        rooms,
        nama: 'KM/WC',
        category: 'bath',
        x: buildX + kitchenW,
        y: yBack,
        width: bathW,
        height: backDepth * 0.52,
      );

      _addRoom(
        rooms,
        nama: 'Area Cuci',
        category: 'service',
        x: buildX + kitchenW,
        y: yBack + backDepth * 0.52,
        width: bathW,
        height: backDepth * 0.48,
      );
    } else {
      final double leftW = _clamp(buildW * 0.54, 2.6, buildW - 2.2);
      final double rightW = buildW - leftW;
      final double upperH = backDepth * 0.52;
      final double lowerH = backDepth - upperH;

      _addRoom(
        rooms,
        nama: 'K. Tidur Utama',
        category: 'bedroom',
        x: buildX,
        y: yBack,
        width: leftW,
        height: upperH,
      );

      _addRoom(
        rooms,
        nama: 'K. Tidur 1',
        category: 'bedroom',
        x: buildX,
        y: yBack + upperH,
        width: leftW,
        height: lowerH,
      );

      _addRoom(
        rooms,
        nama: 'KM/WC',
        category: 'bath',
        x: buildX + leftW,
        y: yBack,
        width: rightW,
        height: upperH,
      );

      _addRoom(
        rooms,
        nama: 'Dapur',
        category: 'kitchen',
        x: buildX + leftW,
        y: yBack + upperH,
        width: rightW,
        height: lowerH,
      );
    }

    _placeExtraRooms(
      rooms: rooms,
      extraRooms: extraRooms,
      landWidth: w,
      landLength: l,
      baseX: buildX,
      baseY: yMiddle,
      maxWidth: buildW,
    );

    return rooms;
  }

  static List<RoomModel> _buildMediumNaturalHouse({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
    required List<RoomRecommendation> extraRooms,
  }) {
    final List<RoomModel> rooms = <RoomModel>[];

    final double w = landWidth;
    final double l = landLength;

    final double sideLeft = _clamp(w * 0.06, 0.45, 0.85);
    final double sideRight = _clamp(w * 0.05, 0.35, 0.70);
    final double frontYard = _clamp(l * 0.13, 1.4, 2.2);
    final double backYard = _clamp(l * 0.08, 0.9, 1.5);

    final double buildX = sideLeft;
    final double buildW = w - sideLeft - sideRight;
    final double buildY = backYard;
    final double buildH = l - frontYard - backYard;

    final double frontDepth = _clamp(buildH * 0.23, 2.5, 3.5);
    final double publicDepth = _clamp(buildH * 0.27, 3.0, 4.3);
    final double privateDepth = _clamp(buildH * 0.28, 3.2, 4.6);
    final double serviceDepth = math.max(
      minRoomSize,
      buildH - frontDepth - publicDepth - privateDepth,
    );

    final double yService = buildY;
    final double yPrivate = yService + serviceDepth;
    final double yPublic = yPrivate + privateDepth;
    final double yFront = yPublic + publicDepth;

    final bool hasCarport = w >= 7.2;
    final double carportW = hasCarport ? _clamp(w * 0.30, 2.6, 3.4) : 0;
    final double terraceW = _clamp(buildW * 0.22, 1.8, 2.7);
    final double livingW = buildW - carportW - terraceW;

    if (hasCarport) {
      _addRoom(
        rooms,
        nama: 'Carport',
        category: 'outdoor',
        x: buildX,
        y: yFront,
        width: carportW,
        height: frontDepth,
      );
    }

    _addRoom(
      rooms,
      nama: 'Teras',
      category: 'outdoor',
      x: buildX + carportW,
      y: yFront + _clamp(frontDepth * 0.20, 0.3, 0.6),
      width: terraceW,
      height: frontDepth * 0.80,
    );

    _addRoom(
      rooms,
      nama: 'Ruang Tamu',
      category: 'living',
      x: buildX + carportW + terraceW,
      y: yFront,
      width: livingW,
      height: frontDepth,
    );

    _addRoom(
      rooms,
      nama: 'Taman Depan',
      category: 'outdoor',
      x: buildX,
      y: yFront + frontDepth,
      width: buildW,
      height: frontYard,
    );

    final double familyW = _clamp(buildW * 0.58, 3.8, buildW - 2.2);
    final double sideGardenW = buildW - familyW;

    _addRoom(
      rooms,
      nama: 'R. Keluarga',
      category: 'family',
      x: buildX,
      y: yPublic,
      width: familyW,
      height: publicDepth,
    );

    _addRoom(
      rooms,
      nama: 'Taman Samping',
      category: 'outdoor',
      x: buildX + familyW,
      y: yPublic + publicDepth * 0.18,
      width: sideGardenW,
      height: publicDepth * 0.82,
    );

    if (bedroomCount <= 2) {
      final double masterW = _clamp(buildW * 0.52, 3.0, buildW - 2.6);

      _addRoom(
        rooms,
        nama: 'K. Tidur Utama',
        category: 'bedroom',
        x: buildX,
        y: yPrivate,
        width: masterW,
        height: privateDepth,
      );

      _addRoom(
        rooms,
        nama: 'K. Tidur 1',
        category: 'bedroom',
        x: buildX + masterW,
        y: yPrivate + privateDepth * 0.12,
        width: buildW - masterW,
        height: privateDepth * 0.88,
      );
    } else {
      final double leftW = _clamp(buildW * 0.46, 3.0, buildW * 0.55);
      final double corridorW = _clamp(buildW * 0.12, 1.0, 1.4);
      final double rightW = buildW - leftW - corridorW;
      final double splitH = privateDepth / 2;

      _addRoom(
        rooms,
        nama: 'K. Tidur Utama',
        category: 'bedroom',
        x: buildX,
        y: yPrivate,
        width: leftW,
        height: privateDepth,
      );

      _addRoom(
        rooms,
        nama: 'Koridor',
        category: 'service',
        x: buildX + leftW,
        y: yPrivate + privateDepth * 0.12,
        width: corridorW,
        height: privateDepth * 0.76,
      );

      _addRoom(
        rooms,
        nama: 'K. Tidur 1',
        category: 'bedroom',
        x: buildX + leftW + corridorW,
        y: yPrivate,
        width: rightW,
        height: splitH,
      );

      _addRoom(
        rooms,
        nama: 'K. Tidur 2',
        category: 'bedroom',
        x: buildX + leftW + corridorW,
        y: yPrivate + splitH,
        width: rightW,
        height: splitH,
      );
    }

    final double kitchenW = _clamp(buildW * 0.30, 2.4, 3.4);
    final double diningW = _clamp(buildW * 0.28, 2.4, 3.5);
    final double bathW = _clamp(buildW * 0.18, 1.7, 2.4);
    final double laundryW = buildW - kitchenW - diningW - bathW;

    _addRoom(
      rooms,
      nama: 'Dapur',
      category: 'kitchen',
      x: buildX,
      y: yService,
      width: kitchenW,
      height: serviceDepth,
    );

    _addRoom(
      rooms,
      nama: 'R. Makan',
      category: 'dining',
      x: buildX + kitchenW,
      y: yService + serviceDepth * 0.10,
      width: diningW,
      height: serviceDepth * 0.90,
    );

    _addRoom(
      rooms,
      nama: 'KM/WC',
      category: 'bath',
      x: buildX + kitchenW + diningW,
      y: yService,
      width: bathW,
      height: serviceDepth * 0.78,
    );

    _addRoom(
      rooms,
      nama: 'Area Cuci',
      category: 'service',
      x: buildX + kitchenW + diningW + bathW,
      y: yService + serviceDepth * 0.15,
      width: laundryW,
      height: serviceDepth * 0.85,
    );

    _placeExtraRooms(
      rooms: rooms,
      extraRooms: extraRooms,
      landWidth: w,
      landLength: l,
      baseX: buildX + buildW * 0.55,
      baseY: yPublic,
      maxWidth: buildW * 0.40,
    );

    return rooms;
  }

  static List<RoomModel> _buildWideMediumHouse({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
    required List<RoomRecommendation> extraRooms,
  }) {
    final List<RoomModel> rooms = <RoomModel>[];

    final double w = landWidth;
    final double l = landLength;

    final double side = _clamp(w * 0.06, 0.5, 0.9);
    final double frontYard = _clamp(l * 0.12, 1.3, 2.0);
    final double backYard = _clamp(l * 0.08, 0.8, 1.3);

    final double buildX = side;
    final double buildY = backYard;
    final double buildW = w - side * 2;
    final double buildH = l - frontYard - backYard;

    final double frontDepth = _clamp(buildH * 0.26, 2.6, 3.5);
    final double middleDepth = _clamp(buildH * 0.34, 3.0, 4.4);
    final double backDepth = buildH - frontDepth - middleDepth;

    final double yBack = buildY;
    final double yMid = buildY + backDepth;
    final double yFront = buildY + backDepth + middleDepth;

    final double carportW = _clamp(buildW * 0.30, 2.8, 3.7);
    final double publicW = buildW - carportW;

    _addRoom(
      rooms,
      nama: 'Carport',
      category: 'outdoor',
      x: buildX,
      y: yFront,
      width: carportW,
      height: frontDepth,
    );

    _addRoom(
      rooms,
      nama: 'Teras',
      category: 'outdoor',
      x: buildX + carportW,
      y: yFront + frontDepth * 0.55,
      width: publicW * 0.36,
      height: frontDepth * 0.45,
    );

    _addRoom(
      rooms,
      nama: 'Ruang Tamu',
      category: 'living',
      x: buildX + carportW + publicW * 0.36,
      y: yFront,
      width: publicW * 0.64,
      height: frontDepth,
    );

    _addRoom(
      rooms,
      nama: 'R. Keluarga',
      category: 'family',
      x: buildX + carportW,
      y: yMid,
      width: publicW,
      height: middleDepth,
    );

    _addRoom(
      rooms,
      nama: 'Taman Samping',
      category: 'outdoor',
      x: buildX,
      y: yMid + middleDepth * 0.10,
      width: carportW,
      height: middleDepth * 0.90,
    );

    final double leftW = _clamp(buildW * 0.38, 3.2, 4.4);
    final double rightW = buildW - leftW;
    final double splitH = backDepth / 2;

    _addRoom(
      rooms,
      nama: 'K. Tidur Utama',
      category: 'bedroom',
      x: buildX,
      y: yBack,
      width: leftW,
      height: backDepth,
    );

    _addRoom(
      rooms,
      nama: 'K. Tidur 1',
      category: 'bedroom',
      x: buildX + leftW,
      y: yBack,
      width: rightW * 0.55,
      height: splitH,
    );

    if (bedroomCount >= 3) {
      _addRoom(
        rooms,
        nama: 'K. Tidur 2',
        category: 'bedroom',
        x: buildX + leftW,
        y: yBack + splitH,
        width: rightW * 0.55,
        height: splitH,
      );
    }

    _addRoom(
      rooms,
      nama: 'Dapur',
      category: 'kitchen',
      x: buildX + leftW + rightW * 0.55,
      y: yBack,
      width: rightW * 0.45,
      height: splitH,
    );

    _addRoom(
      rooms,
      nama: 'KM/WC',
      category: 'bath',
      x: buildX + leftW + rightW * 0.55,
      y: yBack + splitH,
      width: rightW * 0.45,
      height: splitH,
    );

    _addRoom(
      rooms,
      nama: 'Taman Depan',
      category: 'outdoor',
      x: buildX,
      y: yFront + frontDepth,
      width: buildW,
      height: frontYard,
    );

    _placeExtraRooms(
      rooms: rooms,
      extraRooms: extraRooms,
      landWidth: w,
      landLength: l,
      baseX: buildX + carportW,
      baseY: yMid,
      maxWidth: publicW,
    );

    return rooms;
  }

  static List<RoomModel> _buildLargeNaturalHouse({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
    required List<RoomRecommendation> extraRooms,
  }) {
    final List<RoomModel> rooms = <RoomModel>[];

    final double w = landWidth;
    final double l = landLength;

    final double sideLeft = _clamp(w * 0.07, 0.7, 1.2);
    final double sideRight = _clamp(w * 0.06, 0.6, 1.0);
    final double frontYard = _clamp(l * 0.14, 1.8, 2.8);
    final double backYard = _clamp(l * 0.08, 1.0, 1.8);

    final double buildX = sideLeft;
    final double buildW = w - sideLeft - sideRight;
    final double buildY = backYard;
    final double buildH = l - frontYard - backYard;

    final double frontDepth = _clamp(buildH * 0.20, 3.0, 4.2);
    final double publicDepth = _clamp(buildH * 0.25, 3.8, 5.2);
    final double privateDepth = _clamp(buildH * 0.32, 4.3, 6.0);
    final double serviceDepth = math.max(
      minRoomSize,
      buildH - frontDepth - publicDepth - privateDepth,
    );

    final double yService = buildY;
    final double yPrivate = yService + serviceDepth;
    final double yPublic = yPrivate + privateDepth;
    final double yFront = yPublic + publicDepth;

    final double carportW = _clamp(buildW * 0.28, 3.0, 4.2);
    final double terraceW = _clamp(buildW * 0.22, 2.2, 3.4);
    final double livingW = buildW - carportW - terraceW;

    _addRoom(
      rooms,
      nama: 'Carport',
      category: 'outdoor',
      x: buildX,
      y: yFront,
      width: carportW,
      height: frontDepth,
    );

    _addRoom(
      rooms,
      nama: 'Teras',
      category: 'outdoor',
      x: buildX + carportW,
      y: yFront + frontDepth * 0.22,
      width: terraceW,
      height: frontDepth * 0.78,
    );

    _addRoom(
      rooms,
      nama: 'Ruang Tamu',
      category: 'living',
      x: buildX + carportW + terraceW,
      y: yFront,
      width: livingW,
      height: frontDepth,
    );

    _addRoom(
      rooms,
      nama: 'Taman Depan',
      category: 'outdoor',
      x: buildX,
      y: yFront + frontDepth,
      width: buildW,
      height: frontYard,
    );

    final double familyW = _clamp(buildW * 0.56, 4.8, buildW - 3.0);
    final double voidW = buildW - familyW;

    _addRoom(
      rooms,
      nama: 'R. Keluarga',
      category: 'family',
      x: buildX,
      y: yPublic,
      width: familyW,
      height: publicDepth,
    );

    _addRoom(
      rooms,
      nama: 'Inner Court',
      category: 'outdoor',
      x: buildX + familyW,
      y: yPublic + publicDepth * 0.16,
      width: voidW,
      height: publicDepth * 0.84,
    );

    final double masterW = _clamp(buildW * 0.34, 3.4, 4.8);
    final double corridorW = _clamp(buildW * 0.12, 1.2, 1.8);
    final double rightW = buildW - masterW - corridorW;
    final double splitH = privateDepth / 2;

    _addRoom(
      rooms,
      nama: 'K. Tidur Utama',
      category: 'bedroom',
      x: buildX,
      y: yPrivate,
      width: masterW,
      height: privateDepth * 0.58,
    );

    _addRoom(
      rooms,
      nama: 'KM Utama',
      category: 'bath',
      x: buildX,
      y: yPrivate + privateDepth * 0.58,
      width: masterW,
      height: privateDepth * 0.42,
    );

    _addRoom(
      rooms,
      nama: 'Koridor',
      category: 'service',
      x: buildX + masterW,
      y: yPrivate + privateDepth * 0.08,
      width: corridorW,
      height: privateDepth * 0.84,
    );

    _addRoom(
      rooms,
      nama: 'K. Tidur 1',
      category: 'bedroom',
      x: buildX + masterW + corridorW,
      y: yPrivate,
      width: rightW,
      height: splitH,
    );

    _addRoom(
      rooms,
      nama: 'K. Tidur 2',
      category: 'bedroom',
      x: buildX + masterW + corridorW,
      y: yPrivate + splitH,
      width: rightW,
      height: splitH,
    );

    if (bedroomCount >= 4) {
      final double guestW = _clamp(buildW * 0.28, 2.8, 3.8);
      final double guestH = _clamp(publicDepth * 0.58, 2.4, 3.2);

      _addRoom(
        rooms,
        nama: 'K. Tidur 3',
        category: 'bedroom',
        x: buildX + familyW - guestW,
        y: yPublic,
        width: guestW,
        height: guestH,
      );
    }

    if (bedroomCount >= 5) {
      final double workW = _clamp(buildW * 0.24, 2.6, 3.4);
      final double workH = _clamp(publicDepth * 0.42, 2.0, 2.8);

      _addRoom(
        rooms,
        nama: 'Ruang Kerja',
        category: 'room',
        x: buildX + familyW - workW,
        y: yPublic + publicDepth - workH,
        width: workW,
        height: workH,
      );
    }

    final double kitchenW = _clamp(buildW * 0.28, 3.0, 4.2);
    final double diningW = _clamp(buildW * 0.26, 2.8, 4.0);
    final double bathW = _clamp(buildW * 0.16, 1.8, 2.5);
    final double laundryW = buildW - kitchenW - diningW - bathW;

    _addRoom(
      rooms,
      nama: 'Dapur',
      category: 'kitchen',
      x: buildX,
      y: yService + serviceDepth * 0.04,
      width: kitchenW,
      height: serviceDepth * 0.96,
    );

    _addRoom(
      rooms,
      nama: 'R. Makan',
      category: 'dining',
      x: buildX + kitchenW,
      y: yService + serviceDepth * 0.12,
      width: diningW,
      height: serviceDepth * 0.88,
    );

    _addRoom(
      rooms,
      nama: 'KM/WC',
      category: 'bath',
      x: buildX + kitchenW + diningW,
      y: yService,
      width: bathW,
      height: serviceDepth * 0.78,
    );

    _addRoom(
      rooms,
      nama: 'Area Cuci',
      category: 'service',
      x: buildX + kitchenW + diningW + bathW,
      y: yService + serviceDepth * 0.14,
      width: laundryW,
      height: serviceDepth * 0.86,
    );

    _addRoom(
      rooms,
      nama: 'Taman Belakang',
      category: 'outdoor',
      x: buildX,
      y: 0,
      width: buildW,
      height: backYard,
    );

    _placeExtraRooms(
      rooms: rooms,
      extraRooms: extraRooms,
      landWidth: w,
      landLength: l,
      baseX: buildX + buildW * 0.62,
      baseY: yPublic,
      maxWidth: buildW * 0.34,
    );

    return rooms;
  }

  static List<RoomModel> _buildWideLargeHouse({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
    required List<RoomRecommendation> extraRooms,
  }) {
    final List<RoomModel> rooms = <RoomModel>[];

    final double w = landWidth;
    final double l = landLength;

    final double side = _clamp(w * 0.06, 0.7, 1.2);
    final double frontYard = _clamp(l * 0.13, 1.8, 2.8);
    final double backYard = _clamp(l * 0.08, 1.0, 1.6);

    final double buildX = side;
    final double buildY = backYard;
    final double buildW = w - side * 2;
    final double buildH = l - frontYard - backYard;

    final double frontDepth = _clamp(buildH * 0.22, 3.0, 4.2);
    final double publicDepth = _clamp(buildH * 0.34, 4.0, 5.8);
    final double privateDepth = buildH - frontDepth - publicDepth;

    final double yPrivate = buildY;
    final double yPublic = buildY + privateDepth;
    final double yFront = buildY + privateDepth + publicDepth;

    final double leftWingW = _clamp(buildW * 0.34, 3.6, 5.0);
    final double centerW = _clamp(buildW * 0.30, 3.2, 4.6);
    final double rightWingW = buildW - leftWingW - centerW;

    _addRoom(
      rooms,
      nama: 'Carport',
      category: 'outdoor',
      x: buildX,
      y: yFront,
      width: leftWingW,
      height: frontDepth,
    );

    _addRoom(
      rooms,
      nama: 'Teras',
      category: 'outdoor',
      x: buildX + leftWingW,
      y: yFront + frontDepth * 0.50,
      width: centerW,
      height: frontDepth * 0.50,
    );

    _addRoom(
      rooms,
      nama: 'Ruang Tamu',
      category: 'living',
      x: buildX + leftWingW + centerW,
      y: yFront,
      width: rightWingW,
      height: frontDepth,
    );

    _addRoom(
      rooms,
      nama: 'R. Keluarga',
      category: 'family',
      x: buildX + leftWingW,
      y: yPublic,
      width: centerW + rightWingW,
      height: publicDepth,
    );

    _addRoom(
      rooms,
      nama: 'Inner Court',
      category: 'outdoor',
      x: buildX,
      y: yPublic + publicDepth * 0.18,
      width: leftWingW,
      height: publicDepth * 0.82,
    );

    final double splitH = privateDepth / 2;

    _addRoom(
      rooms,
      nama: 'K. Tidur Utama',
      category: 'bedroom',
      x: buildX,
      y: yPrivate,
      width: leftWingW,
      height: splitH,
    );

    _addRoom(
      rooms,
      nama: 'KM Utama',
      category: 'bath',
      x: buildX,
      y: yPrivate + splitH,
      width: leftWingW,
      height: splitH,
    );

    _addRoom(
      rooms,
      nama: 'K. Tidur 1',
      category: 'bedroom',
      x: buildX + leftWingW,
      y: yPrivate,
      width: centerW,
      height: splitH,
    );

    _addRoom(
      rooms,
      nama: 'K. Tidur 2',
      category: 'bedroom',
      x: buildX + leftWingW,
      y: yPrivate + splitH,
      width: centerW,
      height: splitH,
    );

    if (bedroomCount >= 4) {
      _addRoom(
        rooms,
        nama: 'K. Tidur 3',
        category: 'bedroom',
        x: buildX + leftWingW + centerW,
        y: yPrivate,
        width: rightWingW,
        height: splitH,
      );
    }

    _addRoom(
      rooms,
      nama: 'Dapur',
      category: 'kitchen',
      x: buildX + leftWingW + centerW,
      y: yPrivate + splitH,
      width: rightWingW * 0.52,
      height: splitH,
    );

    _addRoom(
      rooms,
      nama: 'KM/WC',
      category: 'bath',
      x: buildX + leftWingW + centerW + rightWingW * 0.52,
      y: yPrivate + splitH,
      width: rightWingW * 0.48,
      height: splitH,
    );

    _addRoom(
      rooms,
      nama: 'Taman Depan',
      category: 'outdoor',
      x: buildX,
      y: yFront + frontDepth,
      width: buildW,
      height: frontYard,
    );

    _addRoom(
      rooms,
      nama: 'Taman Belakang',
      category: 'outdoor',
      x: buildX,
      y: 0,
      width: buildW,
      height: backYard,
    );

    _placeExtraRooms(
      rooms: rooms,
      extraRooms: extraRooms,
      landWidth: w,
      landLength: l,
      baseX: buildX + leftWingW,
      baseY: yPublic,
      maxWidth: centerW + rightWingW,
    );

    return rooms;
  }

  static void _placeExtraRooms({
    required List<RoomModel> rooms,
    required List<RoomRecommendation> extraRooms,
    required double landWidth,
    required double landLength,
    required double baseX,
    required double baseY,
    required double maxWidth,
  }) {
    final List<RoomRecommendation> selectedExtras =
        extraRooms.where((room) => room.selected).toList();

    if (selectedExtras.isEmpty) return;

    double currentY = baseY;

    for (final RoomRecommendation extra in selectedExtras) {
      final double roomWidth = _clamp(extra.width, 1.5, maxWidth);
      final double roomHeight = _clamp(extra.height, 1.3, landLength * 0.18);

      if (baseX + roomWidth > landWidth) {
        continue;
      }

      if (currentY + roomHeight > landLength) {
        break;
      }

      _addRoom(
        rooms,
        nama: extra.name,
        category: extra.category,
        x: baseX,
        y: currentY,
        width: roomWidth,
        height: roomHeight,
      );

      currentY += roomHeight + 0.2;
    }
  }

  static void _addRoom(
    List<RoomModel> rooms, {
    required String nama,
    required String category,
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    if (width < minRoomSize || height < minRoomSize) {
      return;
    }

    rooms.add(
      RoomModel(
        nama: nama,
        category: category,
        x: x,
        y: y,
        width: width,
        height: height,
      ),
    );
  }

  static List<RoomModel> _normalizeRooms(
    List<RoomModel> rooms,
    double landWidth,
    double landLength,
  ) {
    final List<RoomModel> normalized = <RoomModel>[];

    for (final RoomModel room in rooms) {
      final double x = _clamp(room.x, 0, landWidth);
      final double y = _clamp(room.y, 0, landLength);

      final double width = _clamp(
        room.width,
        minRoomSize,
        math.max(minRoomSize, landWidth - x),
      );

      final double height = _clamp(
        room.height,
        minRoomSize,
        math.max(minRoomSize, landLength - y),
      );

      if (x + width <= landWidth + 0.001 &&
          y + height <= landLength + 0.001) {
        normalized.add(
          RoomModel(
            nama: room.nama,
            category: room.category,
            x: x,
            y: y,
            width: width,
            height: height,
          ),
        );
      }
    }

    return normalized;
  }

  static bool _isHiddenFromRecommendation(String name) {
    final String lowerName = name.toLowerCase();

    return lowerName.contains('koridor') ||
        lowerName.contains('sirkulasi') ||
        lowerName.contains('inner court');
  }

  static double _safeDimension(double value, {required double fallback}) {
    if (value.isNaN || value.isInfinite || value <= 0) {
      return fallback;
    }

    return value;
  }

  static double _clamp(double value, double min, double max) {
    if (max < min) return min;
    return value.clamp(min, max).toDouble();
  }
}
