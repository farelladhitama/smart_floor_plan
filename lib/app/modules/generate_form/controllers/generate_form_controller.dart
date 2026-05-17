import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  final RxInt jumlahKamar = 1.obs;
  final RxString selectedMaterial = 'Batu Bata'.obs;
  final RxList<String> listRuangCustom = <String>[].obs;

  final List<String> materialOptions = [
    'Batu Bata',
    'Hebel (Bata Ringan)',
    'Batako',
  ];

  final double skala = 20.0;

  void tambahKamar() {
    jumlahKamar.value++;
  }

  void kurangKamar() {
    if (jumlahKamar.value > 1) {
      jumlahKamar.value--;
    }
  }

  void changeMaterial(String value) {
    selectedMaterial.value = value;
  }

  void tambahRuang() {
    final ruang = ruangTambahanController.text.trim();

    if (ruang.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Nama ruang tambahan tidak boleh kosong.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: navy,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    listRuangCustom.add(ruang);
    ruangTambahanController.clear();
  }

  void hapusRuang(String ruang) {
    listRuangCustom.remove(ruang);
  }

  void prosesGenerate() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final double lebarRumah = double.parse(lebarController.text.trim());
    final double panjangRumah = double.parse(panjangController.text.trim());

    final List<RoomModel> generatedRooms = _generateRuleBasedLayout(
      lebarRumah: lebarRumah,
      panjangRumah: panjangRumah,
      jumlahKamarTidur: jumlahKamar.value,
      ruangTambahan: listRuangCustom.toList(),
    );

    if (Get.isRegistered<hasil_controller.HasilDenahController>()) {
      Get.delete<hasil_controller.HasilDenahController>();
    }

    Get.put(hasil_controller.HasilDenahController());

    Get.to(
      () => hasil_view.HasilDenahPage(
        rooms: generatedRooms,
        inputLebarRumah: lebarRumah,
        inputPanjangRumah: panjangRumah,
      ),
    );
  }

  List<RoomModel> _generateRuleBasedLayout({
    required double lebarRumah,
    required double panjangRumah,
    required int jumlahKamarTidur,
    required List<String> ruangTambahan,
  }) {
    final double canvasWidth = lebarRumah * skala;
    final double canvasHeight = panjangRumah * skala;

    final List<_RoomSpec> roomSpecs = [];

    // RULE 1: Ruang tamu selalu di depan
    roomSpecs.add(
      _RoomSpec(
        nama: 'Ruang Tamu',
        widthMeter: lebarRumah,
        heightMeter: _clampDouble(panjangRumah * 0.22, 2.4, 3.5),
      ),
    );

    // RULE 2: Kamar tidur dibuat sesuai input user
    for (int i = 1; i <= jumlahKamarTidur; i++) {
      roomSpecs.add(
        _RoomSpec(
          nama: 'Kamar Tidur $i',
          widthMeter: lebarRumah >= 7 ? lebarRumah / 2 : lebarRumah,
          heightMeter: 3.0,
        ),
      );
    }

    // RULE 3: Kamar mandi otomatis ditambahkan
    roomSpecs.add(
      _RoomSpec(
        nama: 'Kamar Mandi',
        widthMeter: lebarRumah >= 7 ? lebarRumah / 2 : lebarRumah,
        heightMeter: 2.0,
      ),
    );

    // RULE 4: Dapur otomatis ditambahkan di area belakang
    roomSpecs.add(
      _RoomSpec(
        nama: 'Dapur',
        widthMeter: lebarRumah >= 7 ? lebarRumah / 2 : lebarRumah,
        heightMeter: 2.5,
      ),
    );

    // RULE 5: Ruang tambahan dari user
    for (final ruang in ruangTambahan) {
      roomSpecs.add(
        _RoomSpec(
          nama: ruang,
          widthMeter: lebarRumah >= 7 ? lebarRumah / 2 : lebarRumah,
          heightMeter: 2.4,
        ),
      );
    }

    return _packRoomsIntoCanvas(
      specs: roomSpecs,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );
  }

  List<RoomModel> _packRoomsIntoCanvas({
    required List<_RoomSpec> specs,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    const double gap = 6.0;
    const double startX = 8.0;
    const double startY = 8.0;

    final List<RoomModel> result = [];

    double currentX = startX;
    double currentY = startY;
    double rowHeight = 0;

    for (final spec in specs) {
      double roomWidth = spec.widthMeter * skala;
      double roomHeight = spec.heightMeter * skala;

      final double maxAllowedWidth = canvasWidth - (startX * 2);

      if (roomWidth > maxAllowedWidth) {
        roomWidth = maxAllowedWidth;
      }

      if (currentX + roomWidth > canvasWidth - startX) {
        currentX = startX;
        currentY += rowHeight + gap;
        rowHeight = 0;
      }

      result.add(
        RoomModel(
          nama: spec.nama,
          x: currentX,
          y: currentY,
          width: roomWidth,
          height: roomHeight,
        ),
      );

      currentX += roomWidth + gap;

      if (roomHeight > rowHeight) {
        rowHeight = roomHeight;
      }
    }

    final double contentBottom = result.isEmpty
        ? 0
        : result
            .map((room) => room.y + room.height)
            .reduce((a, b) => a > b ? a : b);

    if (contentBottom <= canvasHeight - startY) {
      return result;
    }

    final double availableHeight = canvasHeight - (startY * 2);
    final double scaleFactor = availableHeight / contentBottom;

    return result.map((room) {
      return RoomModel(
        nama: room.nama,
        x: room.x,
        y: room.y * scaleFactor,
        width: room.width,
        height: room.height * scaleFactor,
      );
    }).toList();
  }

  double _clampDouble(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
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
    lebarController.dispose();
    panjangController.dispose();
    ruangTambahanController.dispose();
    super.onClose();
  }
}

class _RoomSpec {
  final String nama;
  final double widthMeter;
  final double heightMeter;

  _RoomSpec({
    required this.nama,
    required this.widthMeter,
    required this.heightMeter,
  });
}