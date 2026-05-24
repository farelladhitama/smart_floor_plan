import 'dart:math' as math;

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
    final double area = landWidth * landLength;
    final int bedrooms = _recommendedBedroomCount(area);
    final int bathrooms = _recommendedBathroomCount(area);

    final List<RoomRecommendation> rooms = [
      const RoomRecommendation(
        name: 'Teras',
        category: 'outdoor',
        width: 2.8,
        height: 1.2,
      ),
      const RoomRecommendation(
        name: 'Ruang Tamu',
        category: 'living',
        width: 3.6,
        height: 3.4,
      ),
      const RoomRecommendation(
        name: 'Dapur',
        category: 'kitchen',
        width: 2.8,
        height: 2.8,
      ),
    ];

    if (area >= 70) {
      rooms.add(
        const RoomRecommendation(
          name: 'Ruang Keluarga',
          category: 'family',
          width: 3.8,
          height: 3.6,
        ),
      );

      rooms.add(
        const RoomRecommendation(
          name: 'R. Makan',
          category: 'dining',
          width: 3.0,
          height: 2.8,
        ),
      );
    }

    for (int i = 0; i < bedrooms; i++) {
      rooms.add(
        RoomRecommendation(
          name: i == 0 ? 'K. Tidur Utama' : 'K. Tidur $i',
          category: 'bedroom',
          width: i == 0 ? 3.4 : 3.0,
          height: i == 0 ? 3.8 : 3.2,
        ),
      );
    }

    for (int i = 0; i < bathrooms; i++) {
      rooms.add(
        RoomRecommendation(
          name: i == 0 ? 'Kamar Mandi' : 'KM/WC 2',
          category: 'bath',
          width: 1.7,
          height: 2.0,
        ),
      );
    }

    if (area >= 100) {
      rooms.add(
        const RoomRecommendation(
          name: 'Carport',
          category: 'outdoor',
          width: 3.0,
          height: 4.5,
        ),
      );
    }

    if (area >= 120) {
      rooms.add(
        const RoomRecommendation(
          name: 'Taman',
          category: 'outdoor',
          width: 2.8,
          height: 3.0,
        ),
      );
    }

    if (area >= 150) {
      rooms.add(
        const RoomRecommendation(
          name: 'Area Cuci / Jemuran',
          category: 'service',
          width: 2.6,
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
    final double safeWidth = math.max(5.0, landWidth);
    final double safeLength = math.max(7.0, landLength);
    final double area = safeWidth * safeLength;

    final List<RoomModel> generatedRooms;

    if (area >= 120 && safeWidth >= 9 && safeLength >= 10) {
      generatedRooms = _generateFamilyLayout(
        landWidth: safeWidth,
        landLength: safeLength,
        includeSecondBathroom: area >= 120,
        includeGarden: area >= 120,
        includeServiceArea: area >= 150,
      );
    } else if (area >= 70 && safeWidth >= 7) {
      generatedRooms = _generateMediumLayout(
        landWidth: safeWidth,
        landLength: safeLength,
      );
    } else {
      generatedRooms = _generateCompactLayout(
        landWidth: safeWidth,
        landLength: safeLength,
      );
    }

    return SmartFloorPlanResult(
      landWidth: safeWidth,
      landLength: safeLength,
      rooms: generatedRooms,
      recommendations: getRecommendations(
        landWidth: safeWidth,
        landLength: safeLength,
        bedroomCount: _recommendedBedroomCount(area),
      ),
    );
  }

  /// Layout untuk lahan keluarga sedang-besar.
  ///
  /// Arah denah:
  /// - y kecil   = belakang rumah
  /// - y besar   = depan rumah
  ///
  /// Konsep:
  /// - Dapur dan ruang makan di belakang.
  /// - Ruang keluarga menjadi pusat sirkulasi.
  /// - Ruang tamu dekat teras/pintu masuk.
  /// - Kamar berada di sisi area keluarga.
  /// - Carport dan taman berada di luar massa indoor.
  static List<RoomModel> _generateFamilyLayout({
    required double landWidth,
    required double landLength,
    required bool includeSecondBathroom,
    required bool includeGarden,
    required bool includeServiceArea,
  }) {
    const double margin = 0.35;

    final double insideWidth = landWidth - (margin * 2);
    final double insideLength = landLength - (margin * 2);

    final double sideOutdoorWidth =
        (insideWidth * 0.27).clamp(2.55, 3.35).toDouble();

    final double mainX = margin + sideOutdoorWidth;
    final double mainWidth = insideWidth - sideOutdoorWidth;

    final double rearDepth =
        (insideLength * 0.23).clamp(2.75, 3.35).toDouble();

    final double middleDepth =
        (insideLength * 0.28).clamp(3.30, 4.10).toDouble();

    const double terraceDepth = 1.15;

    final double rearY = margin;
    final double middleY = rearY + rearDepth;
    final double frontY = middleY + middleDepth;
    final double terraceY = landLength - margin - terraceDepth;

    final double frontDepth = terraceY - frontY;

    final double familyWidth = mainWidth * 0.54;
    final double rightBedroomWidth = mainWidth - familyWidth;

    final double diningWidth = mainWidth * 0.29;
    final double masterWidth = mainWidth * 0.45;
    final double bathroomWidth = mainWidth - diningWidth - masterWidth;

    final List<RoomModel> rooms = [];

    // ===== AREA BELAKANG =====
    rooms.add(
      _room(
        name: 'Dapur',
        x: margin,
        y: rearY,
        width: sideOutdoorWidth,
        height: rearDepth,
        category: 'kitchen',
        doorSide: 'right',
      ),
    );

    rooms.add(
      _room(
        name: 'R. Makan',
        x: mainX,
        y: rearY,
        width: diningWidth,
        height: rearDepth,
        category: 'dining',
        doorSide: 'bottom',
      ),
    );

    rooms.add(
      _room(
        name: 'K. Tidur Utama',
        x: mainX + diningWidth,
        y: rearY,
        width: masterWidth,
        height: rearDepth,
        category: 'bedroom',
        doorSide: 'bottom',
      ),
    );

    if (includeSecondBathroom) {
      rooms.add(
        _room(
          name: 'KM Utama',
          x: mainX + diningWidth + masterWidth,
          y: rearY,
          width: bathroomWidth,
          height: rearDepth / 2,
          category: 'bath',
          doorSide: 'left',
        ),
      );

      rooms.add(
        _room(
          name: 'KM/WC',
          x: mainX + diningWidth + masterWidth,
          y: rearY + (rearDepth / 2),
          width: bathroomWidth,
          height: rearDepth / 2,
          category: 'bath',
          doorSide: 'left',
        ),
      );
    } else {
      rooms.add(
        _room(
          name: 'Kamar Mandi',
          x: mainX + diningWidth + masterWidth,
          y: rearY,
          width: bathroomWidth,
          height: rearDepth,
          category: 'bath',
          doorSide: 'left',
        ),
      );
    }

    // ===== AREA TENGAH =====
    final double sideUpperHeight = includeServiceArea
        ? middleDepth * 0.44
        : middleDepth * 0.36;

    if (includeServiceArea) {
      rooms.add(
        _room(
          name: 'Area Cuci',
          x: margin,
          y: middleY,
          width: sideOutdoorWidth,
          height: sideUpperHeight,
          category: 'service',
          doorSide: 'right',
          isOutdoor: true,
        ),
      );
    }

    if (includeGarden) {
      rooms.add(
        _room(
          name: 'Taman',
          x: margin,
          y: middleY + (includeServiceArea ? sideUpperHeight : 0),
          width: sideOutdoorWidth,
          height: includeServiceArea
              ? middleDepth - sideUpperHeight
              : middleDepth,
          category: 'outdoor',
          doorSide: 'right',
          isOutdoor: true,
        ),
      );
    }

    rooms.add(
      _room(
        name: 'R. Keluarga',
        x: mainX,
        y: middleY,
        width: familyWidth,
        height: middleDepth,
        category: 'family',
        doorSide: 'bottom',
      ),
    );

    rooms.add(
      _room(
        name: 'K. Tidur 2',
        x: mainX + familyWidth,
        y: middleY,
        width: rightBedroomWidth,
        height: middleDepth,
        category: 'bedroom',
        doorSide: 'left',
      ),
    );

    // ===== AREA DEPAN =====
    rooms.add(
      _room(
        name: 'Carport',
        x: margin,
        y: frontY,
        width: sideOutdoorWidth,
        height: frontDepth + terraceDepth,
        category: 'outdoor',
        doorSide: 'right',
        isOutdoor: true,
      ),
    );

    rooms.add(
      _room(
        name: 'Ruang Tamu',
        x: mainX,
        y: frontY,
        width: familyWidth,
        height: frontDepth,
        category: 'living',
        doorSide: 'bottom',
      ),
    );

    rooms.add(
      _room(
        name: 'K. Tidur 1',
        x: mainX + familyWidth,
        y: frontY,
        width: rightBedroomWidth,
        height: frontDepth,
        category: 'bedroom',
        doorSide: 'left',
      ),
    );

    rooms.add(
      _room(
        name: 'Teras',
        x: mainX,
        y: terraceY,
        width: familyWidth,
        height: terraceDepth,
        category: 'outdoor',
        doorSide: 'top',
        isOutdoor: true,
      ),
    );

    return rooms;
  }

  /// Layout lahan sedang: 2 kamar, satu kamar mandi, dan ruang inti.
  static List<RoomModel> _generateMediumLayout({
    required double landWidth,
    required double landLength,
  }) {
    const double margin = 0.35;
    const double terraceDepth = 1.0;

    final double width = landWidth - (margin * 2);
    final double usableLength = landLength - (margin * 2) - terraceDepth;

    final double rearDepth = usableLength * 0.30;
    final double middleDepth = usableLength * 0.33;
    final double frontDepth = usableLength - rearDepth - middleDepth;

    final double leftWidth = width * 0.48;
    final double rightWidth = width - leftWidth;

    final double yRear = margin;
    final double yMiddle = yRear + rearDepth;
    final double yFront = yMiddle + middleDepth;
    final double yTerrace = yFront + frontDepth;

    return [
      _room(
        name: 'Dapur',
        x: margin,
        y: yRear,
        width: leftWidth,
        height: rearDepth,
        category: 'kitchen',
        doorSide: 'right',
      ),
      _room(
        name: 'Kamar Mandi',
        x: margin + leftWidth,
        y: yRear,
        width: rightWidth * 0.44,
        height: rearDepth,
        category: 'bath',
        doorSide: 'bottom',
      ),
      _room(
        name: 'K. Tidur Utama',
        x: margin + leftWidth + (rightWidth * 0.44),
        y: yRear,
        width: rightWidth * 0.56,
        height: rearDepth,
        category: 'bedroom',
        doorSide: 'bottom',
      ),
      _room(
        name: 'R. Keluarga',
        x: margin,
        y: yMiddle,
        width: leftWidth,
        height: middleDepth,
        category: 'family',
        doorSide: 'bottom',
      ),
      _room(
        name: 'K. Tidur 1',
        x: margin + leftWidth,
        y: yMiddle,
        width: rightWidth,
        height: middleDepth,
        category: 'bedroom',
        doorSide: 'left',
      ),
      _room(
        name: 'Ruang Tamu',
        x: margin,
        y: yFront,
        width: width,
        height: frontDepth,
        category: 'living',
        doorSide: 'bottom',
      ),
      _room(
        name: 'Teras',
        x: margin + (width * 0.24),
        y: yTerrace,
        width: width * 0.52,
        height: terraceDepth,
        category: 'outdoor',
        doorSide: 'top',
        isOutdoor: true,
      ),
    ];
  }

  /// Layout lahan kecil: fungsi inti saja supaya tidak dipaksakan penuh.
  static List<RoomModel> _generateCompactLayout({
    required double landWidth,
    required double landLength,
  }) {
    const double margin = 0.30;
    const double terraceDepth = 0.90;

    final double width = landWidth - (margin * 2);
    final double indoorLength = landLength - (margin * 2) - terraceDepth;

    final double rearDepth = indoorLength * 0.32;
    final double bedroomDepth = indoorLength * 0.34;
    final double livingDepth = indoorLength - rearDepth - bedroomDepth;

    final double kitchenWidth = width * 0.60;
    final double bathWidth = width - kitchenWidth;

    final double yRear = margin;
    final double yBedroom = yRear + rearDepth;
    final double yLiving = yBedroom + bedroomDepth;
    final double yTerrace = yLiving + livingDepth;

    return [
      _room(
        name: 'Dapur',
        x: margin,
        y: yRear,
        width: kitchenWidth,
        height: rearDepth,
        category: 'kitchen',
        doorSide: 'bottom',
      ),
      _room(
        name: 'Kamar Mandi',
        x: margin + kitchenWidth,
        y: yRear,
        width: bathWidth,
        height: rearDepth,
        category: 'bath',
        doorSide: 'bottom',
      ),
      _room(
        name: 'K. Tidur',
        x: margin,
        y: yBedroom,
        width: width,
        height: bedroomDepth,
        category: 'bedroom',
        doorSide: 'bottom',
      ),
      _room(
        name: 'Ruang Tamu',
        x: margin,
        y: yLiving,
        width: width,
        height: livingDepth,
        category: 'living',
        doorSide: 'bottom',
      ),
      _room(
        name: 'Teras',
        x: margin + (width * 0.22),
        y: yTerrace,
        width: width * 0.56,
        height: terraceDepth,
        category: 'outdoor',
        doorSide: 'top',
        isOutdoor: true,
      ),
    ];
  }

  static RoomModel _room({
    required String name,
    required double x,
    required double y,
    required double width,
    required double height,
    required String category,
    required String doorSide,
    bool isOutdoor = false,
  }) {
    return RoomModel(
      nama: name,
      x: x,
      y: y,
      width: math.max(width, 0.75),
      height: math.max(height, 0.75),
      category: category,
      doorSide: doorSide,
      isOutdoor: isOutdoor,
    );
  }

  static int _recommendedBedroomCount(double area) {
    if (area >= 120) {
      return 3;
    }

    if (area >= 70) {
      return 2;
    }

    return 1;
  }

  static int _recommendedBathroomCount(double area) {
    if (area >= 120) {
      return 2;
    }

    return 1;
  }
}