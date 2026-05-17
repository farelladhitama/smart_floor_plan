import 'package:get/get.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';

class EditDenahController extends GetxController {
  final listRuangan = <RoomModel>[].obs;

  final double skala = 20.0;

  void setInitialRooms(List<RoomModel> rooms) {
    listRuangan.assignAll(rooms);
  }

  void updatePosition({
    required int index,
    required double deltaX,
    required double deltaY,
    required double maxWidth,
    required double maxHeight,
  }) {
    final room = listRuangan[index];

    final updatedRoom = room.copyWith(
      x: (room.x + deltaX).clamp(
        0.0,
        maxWidth - room.width,
      ),
      y: (room.y + deltaY).clamp(
        0.0,
        maxHeight - room.height,
      ),
    );

    listRuangan[index] = updatedRoom;
  }

  void updateSize({
    required int index,
    required double deltaX,
    required double deltaY,
  }) {
    final room = listRuangan[index];

    final updatedRoom = room.copyWith(
      width: (room.width + deltaX).clamp(
        40.0,
        500.0,
      ),
      height: (room.height + deltaY).clamp(
        40.0,
        500.0,
      ),
    );

    listRuangan[index] = updatedRoom;
  }

  void saveResult() {
    Get.back(
      result: listRuangan.toList(),
    );
  }
}