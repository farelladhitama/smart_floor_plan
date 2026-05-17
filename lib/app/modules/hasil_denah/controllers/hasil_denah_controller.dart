import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/edit_denah/controllers/edit_denah_controller.dart';
import 'package:smart_floor_plan/app/modules/edit_denah/views/edit_denah_page.dart';
import 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';
import 'package:smart_floor_plan/app/modules/rab/views/rab_page.dart';

class HasilDenahController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);

  final double skala = 20.0;

  final currentRooms = <RoomModel>[].obs;
  final isSaved = false.obs;

  void setInitialRooms(List<RoomModel> rooms) {
    if (currentRooms.isEmpty) {
      currentRooms.assignAll(rooms);
      isSaved.value = false;
    }
  }

  void resetRooms(List<RoomModel> rooms) {
    currentRooms.assignAll(rooms);
    isSaved.value = false;
  }

  void simpanDenah() {
    isSaved.value = true;

    Get.snackbar(
      'Berhasil',
      'Denah telah disimpan ke koleksi Anda',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(15),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> editDenah() async {
    if (Get.isRegistered<EditDenahController>()) {
      Get.delete<EditDenahController>();
    }

    Get.put(EditDenahController());

    final result = await Get.to(
      () => EditDenahPage(
        initialRooms: currentRooms.toList(),
      ),
    );

    if (result != null && result is List<RoomModel>) {
      currentRooms.assignAll(result);
      isSaved.value = false;
    }
  }

  void lihatRAB() {
    if (Get.isRegistered<RABController>()) {
      Get.delete<RABController>();
    }

    Get.put(RABController());

    Get.to(
      () => RABPage(
        rooms: currentRooms.toList(),
      ),
    );
  }

  @override
  void onClose() {
    currentRooms.clear();

    if (Get.isRegistered<EditDenahController>()) {
      Get.delete<EditDenahController>();
    }

    if (Get.isRegistered<RABController>()) {
      Get.delete<RABController>();
    }

    super.onClose();
  }
}