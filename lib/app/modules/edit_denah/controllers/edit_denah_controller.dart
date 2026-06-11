import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';

class EditDenahController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);

  final RxList<RoomModel> listRuangan = <RoomModel>[].obs;
  final RxInt selectedRoomIndex = (-1).obs;

  double landWidth = 0.0;
  double landLength = 0.0;

  bool _hasInitialised = false;
  List<RoomModel> _initialRooms = <RoomModel>[];

  RoomModel? get selectedRoom {
    final int index = selectedRoomIndex.value;

    if (index < 0 || index >= listRuangan.length) {
      return null;
    }

    return listRuangan[index];
  }

  bool get hasSelectedRoom {
    final int index = selectedRoomIndex.value;
    return index >= 0 && index < listRuangan.length;
  }

  void initialisePlan({
    required List<RoomModel> rooms,
    required double inputLandWidth,
    required double inputLandLength,
  }) {
    if (_hasInitialised) return;

    landWidth = inputLandWidth;
    landLength = inputLandLength;

    _initialRooms = rooms.map((room) => room.copyWith()).toList();

    listRuangan.assignAll(
      rooms.map((room) => room.copyWith()).toList(),
    );

    _hasInitialised = true;
  }

  void selectRoom(int index) {
    if (index < 0 || index >= listRuangan.length) return;

    selectedRoomIndex.value = index;
  }

  void clearSelection() {
    selectedRoomIndex.value = -1;
  }

  /// Geser langsung dari canvas.
  /// Ruangan boleh bertabrakan, tetapi tidak boleh keluar batas lahan.
  void updatePosition({
    required int index,
    required double deltaXMeter,
    required double deltaYMeter,
  }) {
    if (index < 0 || index >= listRuangan.length) return;

    final RoomModel room = listRuangan[index];

    final double maxX = math.max(0.0, landWidth - room.width);
    final double maxY = math.max(0.0, landLength - room.height);

    final RoomModel updatedRoom = room.copyWith(
      x: (room.x + deltaXMeter).clamp(0.0, maxX).toDouble(),
      y: (room.y + deltaYMeter).clamp(0.0, maxY).toDouble(),
    );

    listRuangan[index] = updatedRoom;
  }

  /// Geser presisi dari tombol arah pada panel kontrol.
  /// Ruangan boleh melewati/menutupi ruang lain.
  void moveSelectedRoom({
    required double deltaX,
    required double deltaY,
  }) {
    final int index = selectedRoomIndex.value;

    if (index < 0 || index >= listRuangan.length) return;

    final RoomModel room = listRuangan[index];

    final double maxX = math.max(0.0, landWidth - room.width);
    final double maxY = math.max(0.0, landLength - room.height);

    final RoomModel updatedRoom = room.copyWith(
      x: (room.x + deltaX).clamp(0.0, maxX).toDouble(),
      y: (room.y + deltaY).clamp(0.0, maxY).toDouble(),
    );

    listRuangan[index] = updatedRoom;
  }

  /// Tambah/kurangi lebar ruangan.
  /// Overlap diperbolehkan, tetapi ukuran tidak boleh melewati batas kanan lahan.
  
  ///   /// Resize langsung dengan menarik handle pada pojok kanan bawah ruang.
  /// Ruangan boleh bertabrakan, tetapi tetap tidak boleh keluar batas lahan.
  void resizeSelectedByDrag({
    required int index,
    required double deltaWidthMeter,
    required double deltaHeightMeter,
  }) {
    if (index < 0 || index >= listRuangan.length) return;

    selectedRoomIndex.value = index;

    final RoomModel room = listRuangan[index];

    final double minimumWidth = _minimumWidth(room);
    final double minimumHeight = _minimumHeight(room);

    final double maximumWidth = math.max(
      minimumWidth,
      landWidth - room.x,
    );

    final double maximumHeight = math.max(
      minimumHeight,
      landLength - room.y,
    );

    final RoomModel updatedRoom = room.copyWith(
      width: (room.width + deltaWidthMeter)
          .clamp(minimumWidth, maximumWidth)
          .toDouble(),
      height: (room.height + deltaHeightMeter)
          .clamp(minimumHeight, maximumHeight)
          .toDouble(),
    );

    listRuangan[index] = updatedRoom;
  }
  void adjustSelectedWidth(double delta) {
    final int index = selectedRoomIndex.value;

    if (index < 0 || index >= listRuangan.length) return;

    final RoomModel room = listRuangan[index];

    final double minimumWidth = _minimumWidth(room);
    final double maximumWidth = math.max(
      minimumWidth,
      landWidth - room.x,
    );

    final RoomModel updatedRoom = room.copyWith(
      width: (room.width + delta)
          .clamp(minimumWidth, maximumWidth)
          .toDouble(),
    );

    listRuangan[index] = updatedRoom;
  }

  /// Tambah/kurangi panjang ruangan.
  /// Overlap diperbolehkan, tetapi ukuran tidak boleh melewati batas bawah lahan.
  void adjustSelectedHeight(double delta) {
    final int index = selectedRoomIndex.value;

    if (index < 0 || index >= listRuangan.length) return;

    final RoomModel room = listRuangan[index];

    final double minimumHeight = _minimumHeight(room);
    final double maximumHeight = math.max(
      minimumHeight,
      landLength - room.y,
    );

    final RoomModel updatedRoom = room.copyWith(
      height: (room.height + delta)
          .clamp(minimumHeight, maximumHeight)
          .toDouble(),
    );

    listRuangan[index] = updatedRoom;
  }

  /// Putar ruang 90 derajat.
  /// Setelah diputar, posisi otomatis digeser sedikit bila menyentuh batas lahan.
  /// Ruang tetap boleh bertabrakan dengan ruang lain.
  void rotateSelectedRoom() {
    final int index = selectedRoomIndex.value;

    if (index < 0 || index >= listRuangan.length) return;

    final RoomModel room = listRuangan[index];

    final double rotatedWidth = room.height;
    final double rotatedHeight = room.width;

    if (rotatedWidth > landWidth || rotatedHeight > landLength) {
      _showMessage(
        title: 'Rotasi Tidak Bisa',
        message: 'Ukuran ruang lebih besar dari batas lahan setelah diputar.',
      );
      return;
    }

    final double maxX = math.max(0.0, landWidth - rotatedWidth);
    final double maxY = math.max(0.0, landLength - rotatedHeight);

    final RoomModel updatedRoom = room.copyWith(
      x: room.x.clamp(0.0, maxX).toDouble(),
      y: room.y.clamp(0.0, maxY).toDouble(),
      width: rotatedWidth,
      height: rotatedHeight,
      doorSide: _rotateDoorSide(room.doorSide),
    );

    listRuangan[index] = updatedRoom;

    _showMessage(
      title: 'Rotasi Berhasil',
      message: '${room.nama} berhasil diputar 90°.',
      duration: const Duration(seconds: 1),
    );
  }

  void resetLayout() {
    listRuangan.assignAll(
      _initialRooms.map((room) => room.copyWith()).toList(),
    );

    selectedRoomIndex.value = -1;

    _showMessage(
      title: 'Layout Direset',
      message: 'Denah dikembalikan ke hasil generate awal.',
    );
  }

  double _minimumWidth(RoomModel room) {
    switch (room.category) {
      case 'bath':
        return 1.0;
      case 'outdoor':
        return 1.0;
      case 'service':
        return 1.2;
      default:
        return 1.5;
    }
  }

  double _minimumHeight(RoomModel room) {
    switch (room.category) {
      case 'bath':
        return 1.0;
      case 'outdoor':
        return 1.0;
      case 'service':
        return 1.2;
      default:
        return 1.5;
    }
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

  void _showMessage({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: duration,
    );
  }

  void saveResult() {
    Get.back(
      result: listRuangan.map((room) => room.copyWith()).toList(),
    );
  }
}
