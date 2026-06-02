import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/edit_denah/controllers/edit_denah_controller.dart';
import 'package:smart_floor_plan/app/modules/edit_denah/views/edit_denah_page.dart';
import 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';
import 'package:smart_floor_plan/app/modules/rab/views/rab_page.dart';
import 'package:smart_floor_plan/app/modules/riwayat/controllers/riwayat_controller.dart';

class HasilDenahController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  final RxList<RoomModel> currentRooms = <RoomModel>[].obs;
  final RxBool isSaved = false.obs;
  final RxBool isSaving = false.obs;

  String? floorPlanId;

  double landWidth = 0;
  double landLength = 0;
  int jumlahKamar = 1;
  String material = 'Batu Bata';
  List<String> ruangTambahan = <String>[];

  SupabaseClient get _supabase => Supabase.instance.client;

  void setInitialRooms(List<RoomModel> rooms) {
    if (currentRooms.isEmpty) {
      currentRooms.assignAll(
        rooms.map((room) => room.copyWith()).toList(),
      );

      isSaved.value = floorPlanId != null && floorPlanId!.isNotEmpty;
    }
  }

  void setMetadata({
    String? inputFloorPlanId,
    required double inputLebarRumah,
    required double inputPanjangRumah,
    required int inputJumlahKamar,
    required String inputMaterial,
    required List<String> inputRuangTambahan,
  }) {
    if (inputFloorPlanId != null && inputFloorPlanId.trim().isNotEmpty) {
      floorPlanId = inputFloorPlanId.trim();
      isSaved.value = true;
    }

    landWidth = inputLebarRumah;
    landLength = inputPanjangRumah;
    jumlahKamar = inputJumlahKamar;
    material = inputMaterial;
    ruangTambahan = inputRuangTambahan;
  }

  void resetRooms(List<RoomModel> rooms) {
    currentRooms.assignAll(
      rooms.map((room) => room.copyWith()).toList(),
    );
    isSaved.value = false;
  }

  double get totalRoomArea {
    return currentRooms.fold<double>(
      0.0,
      (total, room) => total + room.area,
    );
  }

  double get totalLandArea {
    if (landWidth <= 0 || landLength <= 0) {
      return totalRoomArea;
    }

    return landWidth * landLength;
  }

  double get estimasiRab {
    return totalRoomArea * 3500000;
  }

  int get indoorRoomCount {
    return currentRooms.where((room) => !room.isOutdoor).length;
  }

  Future<void> simpanDenah() async {
    if (isSaving.value) {
      return;
    }

    final User? user = _supabase.auth.currentUser;

    if (user == null) {
      _showSnackBar(
        title: 'Belum Login',
        message: 'Silakan login terlebih dahulu untuk menyimpan denah.',
      );
      return;
    }

    if (currentRooms.isEmpty) {
      _showSnackBar(
        title: 'Gagal Simpan',
        message: 'Tidak ada data ruangan yang dapat disimpan.',
      );
      return;
    }

    try {
      isSaving.value = true;

      final String title =
          'Denah ${landWidth.toStringAsFixed(1)} x ${landLength.toStringAsFixed(1)} m';

      final List<Map<String, dynamic>> roomsJson =
          currentRooms.map((room) => _roomToJson(room)).toList();

      final Map<String, dynamic> payload = {
        'user_id': user.id,
        'title': title,
        'panjang_lahan': landLength,
        'lebar_lahan': landWidth,
        'jumlah_kamar': jumlahKamar,
        'material': material,
        'ruang_tambahan': ruangTambahan,
        'total_luas': totalLandArea,
        'estimasi_rab': estimasiRab,
        'rooms_json': roomsJson,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (floorPlanId != null && floorPlanId!.isNotEmpty) {
        await _supabase
            .from('floor_plans')
            .update(payload)
            .eq('id', floorPlanId!)
            .eq('user_id', user.id);

        _showSnackBar(
          title: 'Berhasil',
          message: 'Perubahan denah berhasil diperbarui di riwayat.',
        );
      } else {
        final Map<String, dynamic> inserted = await _supabase
            .from('floor_plans')
            .insert(payload)
            .select('id')
            .single();

        floorPlanId = (inserted['id'] ?? '').toString();

        _showSnackBar(
          title: 'Berhasil',
          message: 'Denah berhasil disimpan ke database Supabase.',
        );
      }

      isSaved.value = true;

      if (Get.isRegistered<RiwayatController>()) {
        await Get.find<RiwayatController>().loadHistories();
      }
    } on PostgrestException catch (error) {
      _showSnackBar(
        title: 'Gagal Simpan Database',
        message: error.message,
      );
    } catch (error) {
      _showSnackBar(
        title: 'Gagal Simpan',
        message: 'Terjadi kesalahan: $error',
      );
    } finally {
      isSaving.value = false;
    }
  }

  Map<String, dynamic> _roomToJson(RoomModel room) {
    final dynamic dynamicRoom = room;

    return {
      'nama': room.nama,
      'category': room.category,
      'area': room.area,
      'is_outdoor': room.isOutdoor,
      'x': _safeRead(() => dynamicRoom.x),
      'y': _safeRead(() => dynamicRoom.y),
      'width': _safeRead(() => dynamicRoom.width),
      'height': _safeRead(() => dynamicRoom.height),
      'rotation': _safeRead(() => dynamicRoom.rotation),
    };
  }

  dynamic _safeRead(dynamic Function() reader) {
    try {
      return reader();
    } catch (_) {
      return null;
    }
  }

  Future<void> editDenah({
    required double landWidth,
    required double landLength,
  }) async {
    if (Get.isRegistered<EditDenahController>()) {
      Get.delete<EditDenahController>();
    }

    Get.put(EditDenahController());

    final dynamic result = await Get.to(
      () => EditDenahPage(
        initialRooms: currentRooms.map((room) => room.copyWith()).toList(),
        landWidth: landWidth,
        landLength: landLength,
      ),
    );

    if (result != null && result is List<RoomModel>) {
      currentRooms.assignAll(
        result.map((room) => room.copyWith()).toList(),
      );
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
        rooms: currentRooms.map((room) => room.copyWith()).toList(),
      ),
    );
  }

  void _showSnackBar({
    required String title,
    required String message,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(15),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      icon: const Icon(
        Icons.info_outline_rounded,
        color: orange,
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