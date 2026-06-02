import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/core/floorplan/room_recommendation.dart';
import 'package:smart_floor_plan/app/core/floorplan/smart_floor_plan_engine.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/hasil_denah/controllers/hasil_denah_controller.dart'
    as hasil_controller;
import 'package:smart_floor_plan/app/modules/hasil_denah/views/hasil_denah_page.dart'
    as hasil_view;

class GenerateFormController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);

  final formKey = GlobalKey<FormState>();

  final TextEditingController lebarController = TextEditingController();
  final TextEditingController panjangController = TextEditingController();

  final TextEditingController ruangTambahanController =
      TextEditingController();

  final TextEditingController lebarRuangTambahanController =
      TextEditingController(text: '2.5');

  final TextEditingController panjangRuangTambahanController =
      TextEditingController(text: '2.5');

  final RxInt jumlahKamar = 1.obs;
  final RxString selectedMaterial = 'Batu Bata'.obs;

  final RxString selectedJenisRuang = 'Mushola'.obs;

  final RxList<String> listRuangCustom = <String>[].obs;

  final RxList<RoomRecommendation> rekomendasiRuang =
      <RoomRecommendation>[].obs;

  final RxList<RoomRecommendation> ruangTambahanDetail =
      <RoomRecommendation>[].obs;

  final List<String> materialOptions = [
    'Batu Bata',
    'Hebel (Bata Ringan)',
    'Batako',
  ];

  final List<String> jenisRuangOptions = [
    'Mushola',
    'Gudang',
    'Area Cuci',
    'Jemuran',
    'Taman',
    'Garasi',
    'Carport',
    'Ruang Kerja',
    'Ruang Makan',
    'Ruang Keluarga',
    'Kamar Mandi',
    'Kamar Tidur',
  ];

  @override
  void onInit() {
    super.onInit();

    lebarController.addListener(updateRekomendasiRuang);
    panjangController.addListener(updateRekomendasiRuang);

    ever(jumlahKamar, (_) {
      updateRekomendasiRuang();
    });
  }

  void tambahKamar() {
    jumlahKamar.value++;
    updateRekomendasiRuang();
  }

  void kurangKamar() {
    if (jumlahKamar.value > 1) {
      jumlahKamar.value--;
      updateRekomendasiRuang();
    }
  }

  void changeMaterial(String value) {
    selectedMaterial.value = value;
  }

  void changeJenisRuang(String value) {
    selectedJenisRuang.value = value;
  }

  void updateRekomendasiRuang() {
    final double? lebarRumah = double.tryParse(lebarController.text.trim());
    final double? panjangRumah = double.tryParse(panjangController.text.trim());

    if (lebarRumah == null ||
        panjangRumah == null ||
        lebarRumah <= 0 ||
        panjangRumah <= 0) {
      rekomendasiRuang.clear();
      return;
    }

    final result = SmartFloorPlanEngine.getRecommendations(
      landWidth: lebarRumah,
      landLength: panjangRumah,
      bedroomCount: jumlahKamar.value,
    );

    rekomendasiRuang.assignAll(result);
  }

  void tambahRuang() {
    final String namaManual = ruangTambahanController.text.trim();
    final String namaRuang =
        namaManual.isEmpty ? selectedJenisRuang.value : namaManual;

    final double? lebarRuang =
        double.tryParse(lebarRuangTambahanController.text.trim());

    final double? panjangRuang =
        double.tryParse(panjangRuangTambahanController.text.trim());

    if (namaRuang.trim().isEmpty) {
      _showSnackBar(
        title: 'Peringatan',
        message: 'Nama ruang tambahan tidak boleh kosong.',
      );
      return;
    }

    if (lebarRuang == null || panjangRuang == null) {
      _showSnackBar(
        title: 'Peringatan',
        message: 'Ukuran ruang tambahan harus berupa angka.',
      );
      return;
    }

    if (lebarRuang <= 0 || panjangRuang <= 0) {
      _showSnackBar(
        title: 'Peringatan',
        message: 'Ukuran ruang tambahan harus lebih dari 0.',
      );
      return;
    }

    final bool isDuplicate = ruangTambahanDetail.any(
      (item) => item.name.toLowerCase() == namaRuang.toLowerCase(),
    );

    if (isDuplicate) {
      _showSnackBar(
        title: 'Peringatan',
        message: 'Ruang tambahan "$namaRuang" sudah ditambahkan.',
      );
      return;
    }

    final recommendation = RoomRecommendation(
      name: namaRuang,
      category: _getCategoryFromRoomName(namaRuang),
      width: lebarRuang,
      height: panjangRuang,
      selected: true,
    );

    ruangTambahanDetail.add(recommendation);

    if (!listRuangCustom.contains(namaRuang)) {
      listRuangCustom.add(namaRuang);
    }

    ruangTambahanController.clear();

    _showSnackBar(
      title: 'Berhasil',
      message: '$namaRuang berhasil ditambahkan.',
    );
  }

  void hapusRuang(String ruang) {
    listRuangCustom.remove(ruang);

    ruangTambahanDetail.removeWhere(
      (item) => item.name.toLowerCase() == ruang.toLowerCase(),
    );
  }

  void hapusRuangDetail(RoomRecommendation room) {
    ruangTambahanDetail.remove(room);
    listRuangCustom.remove(room.name);
  }

  void prosesGenerate() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final double lebarRumah = double.parse(lebarController.text.trim());
    final double panjangRumah = double.parse(panjangController.text.trim());

    final SmartFloorPlanResult result = SmartFloorPlanEngine.generate(
      landWidth: lebarRumah,
      landLength: panjangRumah,
      bedroomCount: jumlahKamar.value,
      extraRooms: ruangTambahanDetail.toList(),
    );

    final List<RoomModel> generatedRooms = result.rooms;

    if (generatedRooms.isEmpty) {
      _showSnackBar(
        title: 'Gagal Generate',
        message:
            'Denah belum dapat dibuat. Coba perbesar ukuran lahan atau kurangi ruang tambahan.',
      );
      return;
    }

    if (Get.isRegistered<hasil_controller.HasilDenahController>()) {
      Get.delete<hasil_controller.HasilDenahController>();
    }

    Get.put(hasil_controller.HasilDenahController());

    Get.to(
      () => hasil_view.HasilDenahPage(
        rooms: generatedRooms,
        inputLebarRumah: result.landWidth,
        inputPanjangRumah: result.landLength,
        material: selectedMaterial.value,
        jumlahKamar: jumlahKamar.value,
        ruangTambahan: ruangTambahanDetail.map((item) => item.name).toList(),
      ),
    );
  }

  String _getCategoryFromRoomName(String roomName) {
    final String name = roomName.toLowerCase();

    if (name.contains('tidur') || name.contains('kamar')) {
      if (name.contains('mandi') || name.contains('wc')) {
        return 'bath';
      }

      return 'bedroom';
    }

    if (name.contains('mandi') || name.contains('wc')) {
      return 'bath';
    }

    if (name.contains('dapur')) {
      return 'kitchen';
    }

    if (name.contains('makan')) {
      return 'dining';
    }

    if (name.contains('keluarga')) {
      return 'family';
    }

    if (name.contains('tamu')) {
      return 'living';
    }

    if (name.contains('taman') ||
        name.contains('teras') ||
        name.contains('garasi') ||
        name.contains('carport')) {
      return 'outdoor';
    }

    if (name.contains('cuci') ||
        name.contains('jemur') ||
        name.contains('gudang')) {
      return 'service';
    }

    return 'room';
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
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }

  String? validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Isi angka';
    }

    final number = double.tryParse(value.trim());

    if (number == null) {
      return 'Harus angka';
    }

    if (number <= 0) {
      return 'Minimal > 0';
    }

    return null;
  }

  @override
  void onClose() {
    lebarController.removeListener(updateRekomendasiRuang);
    panjangController.removeListener(updateRekomendasiRuang);

    lebarController.dispose();
    panjangController.dispose();
    ruangTambahanController.dispose();
    lebarRuangTambahanController.dispose();
    panjangRuangTambahanController.dispose();

    super.onClose();
  }
}