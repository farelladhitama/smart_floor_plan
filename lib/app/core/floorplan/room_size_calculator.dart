import 'package:smart_floor_plan/app/core/floorplan/room_recommendation.dart';

class RoomSizeCalculator {
  static List<RoomRecommendation> calculate({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
    required List<String> extraRooms,
  }) {
    final List<RoomRecommendation> rooms = [];

    final double landArea = landWidth * landLength;

    // =========================
    // BEDROOM
    // =========================

    if (bedroomCount > 0) {
      rooms.add(
        const RoomRecommendation(
          name: "K. Tidur Utama",
          category: "bedroom",
          width: 4,
          height: 4,
        ),
      );
    }

    for (int i = 1; i < bedroomCount; i++) {
      rooms.add(
        RoomRecommendation(
          name: "K. Tidur ${i + 1}",
          category: "bedroom",
          width: 3,
          height: 3,
        ),
      );
    }

    // =========================
    // RUANG WAJIB
    // =========================

    rooms.add(
      const RoomRecommendation(
        name: "Ruang Tamu",
        category: "living",
        width: 4,
        height: 3.5,
      ),
    );

    rooms.add(
      const RoomRecommendation(
        name: "Ruang Keluarga",
        category: "family",
        width: 4,
        height: 4,
      ),
    );

    rooms.add(
      const RoomRecommendation(
        name: "Dapur",
        category: "kitchen",
        width: 3,
        height: 3,
      ),
    );

    rooms.add(
      const RoomRecommendation(
        name: "KM/WC",
        category: "bath",
        width: 2,
        height: 2,
      ),
    );

    // =========================
    // EXTRA ROOM
    // =========================

    for (String room in extraRooms) {
      switch (room.toLowerCase()) {
        case "ruang makan":
          rooms.add(
            const RoomRecommendation(
              name: "Ruang Makan",
              category: "dining",
              width: 3,
              height: 3,
            ),
          );
          break;

        case "carport":
          rooms.add(
            const RoomRecommendation(
              name: "Carport",
              category: "outdoor",
              width: 3,
              height: 5,
            ),
          );
          break;

        case "teras":
          rooms.add(
            const RoomRecommendation(
              name: "Teras",
              category: "outdoor",
              width: 2,
              height: 3,
            ),
          );
          break;

        case "taman":
          rooms.add(
            const RoomRecommendation(
              name: "Taman",
              category: "outdoor",
              width: 3,
              height: 3,
            ),
          );
          break;

        case "inner court":
          rooms.add(
            const RoomRecommendation(
              name: "Inner Court",
              category: "outdoor",
              width: 2.5,
              height: 2.5,
            ),
          );
          break;

        case "kolam":
          rooms.add(
            const RoomRecommendation(
              name: "Kolam",
              category: "outdoor",
              width: 2.5,
              height: 3,
            ),
          );
          break;

        case "gudang":
          rooms.add(
            const RoomRecommendation(
              name: "Gudang",
              category: "service",
              width: 2,
              height: 2,
            ),
          );
          break;

        case "ruang cuci":
          rooms.add(
            const RoomRecommendation(
              name: "Ruang Cuci",
              category: "service",
              width: 2,
              height: 2,
            ),
          );
          break;
      }
    }

    // =========================
    // AUTO SCALE
    // =========================

    double usedArea = 0;

    for (final room in rooms) {
      usedArea += room.area;
    }

    final double maxArea = landArea * 0.82;

    if (usedArea > maxArea) {
      final double scale = (maxArea / usedArea).sqrt();

      for (int i = 0; i < rooms.length; i++) {
        rooms[i] = rooms[i].copyWith(
          width: rooms[i].width * scale,
          height: rooms[i].height * scale,
        );
      }
    }

    return rooms;
  }
}

extension DoubleSqrt on double {
  double sqrt() {
    return this <= 0 ? 0 : (this).toDouble().pow(0.5);
  }

  double pow(double value) {
    return value == 0
        ? 1
        : value == 0.5
            ? _sqrtNewton(this)
            : this;
  }

  static double _sqrtNewton(double x) {
    double guess = x / 2;

    for (int i = 0; i < 15; i++) {
      guess = (guess + x / guess) / 2;
    }

    return guess;
  }
}