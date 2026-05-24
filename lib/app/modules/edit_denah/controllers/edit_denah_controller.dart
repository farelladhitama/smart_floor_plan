import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';

class EditDenahController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);

  final listRuangan = <RoomModel>[].obs;

  double landWidth = 0;
  double landLength = 0;

  bool _hasInitialised = false;

  void initialisePlan({
    required List<RoomModel> rooms,
    required double inputLandWidth,
    required double inputLandLength,
  }) {
    if (_hasInitialised) return;

    landWidth = inputLandWidth;
    landLength = inputLandLength;

    listRuangan.assignAll(
      rooms.map((room) => room.copyWith()).toList(),
    );

    _hasInitialised = true;
  }

  void updatePosition({
    required int index,
    required double deltaXMeter,
    required double deltaYMeter,
  }) {
    if (index < 0 || index >= listRuangan.length) return;

    final room = listRuangan[index];

    final maxX = math.max(0.0, landWidth - room.width);
    final maxY = math.max(0.0, landLength - room.height);

    final candidate = room.copyWith(
      x: (room.x + deltaXMeter).clamp(0.0, maxX).toDouble(),
      y: (room.y + deltaYMeter).clamp(0.0, maxY).toDouble(),
    );

    if (_canPlace(candidate, index)) {
      listRuangan[index] = candidate;
    }
  }

  void updateSize({
    required int index,
    required double deltaWidthMeter,
    required double deltaHeightMeter,
  }) {
    if (index < 0 || index >= listRuangan.length) return;

    final room = listRuangan[index];

    final maxWidth = math.max(1.0, landWidth - room.x);
    final maxHeight = math.max(1.0, landLength - room.y);

    final candidate = room.copyWith(
      width: (room.width + deltaWidthMeter)
          .clamp(1.0, maxWidth)
          .toDouble(),
      height: (room.height + deltaHeightMeter)
          .clamp(1.0, maxHeight)
          .toDouble(),
    );

    if (_canPlace(candidate, index)) {
      listRuangan[index] = candidate;
    }
  }

  void rotateRoom(int index) {
    if (index < 0 || index >= listRuangan.length) return;

    final room = listRuangan[index];

    final rotatedWidth = room.height;
    final rotatedHeight = room.width;

    final maxX = math.max(0.0, landWidth - rotatedWidth);
    final maxY = math.max(0.0, landLength - rotatedHeight);

    final candidate = room.copyWith(
      x: room.x.clamp(0.0, maxX).toDouble(),
      y: room.y.clamp(0.0, maxY).toDouble(),
      width: rotatedWidth,
      height: rotatedHeight,
      doorSide: _rotateDoorSide(room.doorSide),
    );

    if (!_canPlace(candidate, index)) {
      Get.snackbar(
        'Rotasi Tidak Bisa',
        'Ruangan bertabrakan dengan ruang lain setelah diputar. Geser ruang terlebih dahulu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: navy,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    listRuangan[index] = candidate;

    Get.snackbar(
      'Ruangan Diputar',
      '${room.nama} berhasil dirotasi 90°.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 1),
    );
  }

  bool _canPlace(RoomModel candidate, int currentIndex) {
    if (candidate.x < 0 ||
        candidate.y < 0 ||
        candidate.x + candidate.width > landWidth ||
        candidate.y + candidate.height > landLength) {
      return false;
    }

    for (int i = 0; i < listRuangan.length; i++) {
      if (i == currentIndex) continue;

      if (_isOverlapping(candidate, listRuangan[i])) {
        return false;
      }
    }

    return true;
  }

  bool _isOverlapping(RoomModel first, RoomModel second) {
    const double safeGap = 0.06;

    return first.x + safeGap < second.x + second.width &&
        first.x + first.width - safeGap > second.x &&
        first.y + safeGap < second.y + second.height &&
        first.y + first.height - safeGap > second.y;
  }

  String _rotateDoorSide(String side) {
    switch (side) {
      case 'bottom':
        return 'left';
      case 'left':
        return 'top';
      case 'top':
        return 'right';
      case 'right':
        return 'bottom';
      default:
        return 'bottom';
    }
  }

  void saveResult() {
    Get.back(
      result: listRuangan.map((room) => room.copyWith()).toList(),
    );
  }
}