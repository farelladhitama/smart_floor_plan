import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_floor_plan/app/core/floorplan/room_recommendation.dart';
import 'package:smart_floor_plan/app/core/floorplan/smart_floor_plan_engine.dart';
import 'package:smart_floor_plan/app/modules/hasil_denah/controllers/hasil_denah_controller.dart'
    as hasil_controller;
import 'package:smart_floor_plan/app/modules/hasil_denah/views/hasil_denah_page.dart'
    as hasil_view;
import 'package:smart_floor_plan/app/services/activity_log_service.dart';

class GenerateFormController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  

  final TextEditingController lebarController = TextEditingController();
  final TextEditingController panjangController = TextEditingController();
  final TextEditingController tambahanRuanganController = TextEditingController();

  final RxString selectedMaterial = 'batu bata merah'.obs;

  final List<String> materialCategories = const [
    'Material Dinding',
    'Semen',
    'Pasir',
    'Keramik Lantai',
    'Cat Dinding',
    'Genteng / Atap',
    'Plafon',
    'Pipa',
  ];

  final RxMap<String, List<String>> materialOptionsByCategory =
      <String, List<String>>{}.obs;

  final RxMap<String, String> selectedMaterials = <String, String>{}.obs;

  final RxBool isLoadingMaterials = false.obs;
  final RxBool isAnalyzingRecommendation = false.obs;
  final RxBool hasAnalyzedRecommendation = false.obs;

  final RxList<RoomRecommendation> rekomendasiRuang =
      <RoomRecommendation>[].obs;

  final List<String> materialOptions = const [
    'batu bata merah',
    'batako',
    'bata ringan / hebel',
  ];

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();

    lebarController.addListener(_clearRecommendationOnInputChange);
    panjangController.addListener(_clearRecommendationOnInputChange);
    tambahanRuanganController.addListener(_clearRecommendationOnInputChange);

    loadMaterialOptions();
  }

  Future<void> loadMaterialOptions() async {
    try {
      isLoadingMaterials.value = true;

      final response = await _supabase
          .from('rab_material_options')
          .select('kategori, nama_material, is_active')
          .eq('is_active', true)
          .order('kategori', ascending: true)
          .order('nama_material', ascending: true);

      final List<Map<String, dynamic>> rows = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final Map<String, List<String>> grouped = {};

      for (final row in rows) {
        final String kategori = (row['kategori'] ?? '').toString();
        final String namaMaterial = (row['nama_material'] ?? '').toString();

        if (kategori.isEmpty || namaMaterial.isEmpty) continue;
        if (!materialCategories.contains(kategori)) continue;

        grouped.putIfAbsent(kategori, () => <String>[]);

        if (!grouped[kategori]!.contains(namaMaterial)) {
          grouped[kategori]!.add(namaMaterial);
        }
      }

      if (grouped.isEmpty) {
        _setFallbackMaterialOptions();
      } else {
        materialOptionsByCategory.assignAll(_sortGroupedMaterials(grouped));
        _ensureDefaultSelectedMaterials();
      }
    } catch (_) {
      _setFallbackMaterialOptions();
    } finally {
      isLoadingMaterials.value = false;
    }
  }

  Map<String, List<String>> _sortGroupedMaterials(Map<String, List<String>> data) {
    final Map<String, List<String>> sorted = {};

    for (final category in materialCategories) {
      final options = data[category];
      if (options != null && options.isNotEmpty) {
        sorted[category] = options;
      }
    }

    return sorted;
  }

  void _setFallbackMaterialOptions() {
    materialOptionsByCategory.assignAll({
      'Material Dinding': [
        'batu bata merah',
        'batako',
        'bata ringan / hebel',
      ],
      'Semen': [
        'semen tiga roda',
        'semen gresik',
        'semen padang',
        'semen mortar',
        'semen instan',
      ],
      'Pasir': [
        'pasir pasang',
        'pasir urug',
      ],
      'Keramik Lantai': [
        'keramik lantai standar',
        'keramik lantai premium',
        'granit lantai',
      ],
      'Cat Dinding': [
        'cat tembok standar',
        'cat tembok avian',
        'cat tembok dulux',
        'cat tembok nippon paint',
      ],
      'Genteng / Atap': [
        'genteng tanah liat',
        'genteng beton',
        'atap spandek',
      ],
      'Plafon': [
        'plafon gypsum',
        'plafon pvc',
        'plafon grc',
      ],
      'Pipa': [
        'pipa pvc',
        'pipa air',
        'pipa conduit',
      ],
    });

    _ensureDefaultSelectedMaterials();
  }

  void _ensureDefaultSelectedMaterials() {
    for (final kategori in materialCategories) {
      final options = materialOptionsByCategory[kategori] ?? <String>[];

      if (options.isEmpty) continue;

      if (!selectedMaterials.containsKey(kategori) ||
          !options.contains(selectedMaterials[kategori])) {
        selectedMaterials[kategori] = options.first;
      }
    }

    final String? dinding = selectedMaterials['Material Dinding'];
    if (dinding != null && dinding.isNotEmpty) {
      selectedMaterial.value = dinding;
    }
  }

  void changeMaterialForCategory(String kategori, String value) {
    selectedMaterials[kategori] = value;

    if (kategori == 'Material Dinding') {
      selectedMaterial.value = value;
    }
  }

  void _clearRecommendationOnInputChange() {
    if (rekomendasiRuang.isNotEmpty || hasAnalyzedRecommendation.value) {
      rekomendasiRuang.clear();
      hasAnalyzedRecommendation.value = false;
    }
  }

  void changeMaterial(String value) {
    selectedMaterial.value = value;
    selectedMaterials['Material Dinding'] = value;
  }

  int estimateBedroomCount({
    required double landWidth,
    required double landLength,
  }) {
    final double area = landWidth * landLength;

    if (area <= 45) return 1;
    if (area <= 90) return 2;
    if (area <= 140) return 3;

    return 4;
  }

  Future<void> analisisRekomendasiRuang() async {
    final double? lebarRumah = double.tryParse(lebarController.text.trim());
    final double? panjangRumah = double.tryParse(panjangController.text.trim());

    if (lebarRumah == null ||
        panjangRumah == null ||
        lebarRumah <= 0 ||
        panjangRumah <= 0) {
      _showSnackBar(
        title: 'Input Belum Lengkap',
        message: 'Isi lebar dan panjang lahan terlebih dahulu.',
      );
      return;
    }

    if (isAnalyzingRecommendation.value) return;

    try {
      isAnalyzingRecommendation.value = true;
      hasAnalyzedRecommendation.value = false;
      rekomendasiRuang.clear();

      _showLoadingDialog();

      await Future.delayed(const Duration(milliseconds: 900));
      await Future.delayed(const Duration(milliseconds: 700));

      final int bedroomCount = estimateBedroomCount(
        landWidth: lebarRumah,
        landLength: panjangRumah,
      );

      final List<RoomRecommendation> extraRooms = _buildExtraRoomRecommendations(
        landWidth: lebarRumah,
        landLength: panjangRumah,
      );

      final List<RoomRecommendation> result =
          SmartFloorPlanEngine.getRecommendations(
        landWidth: lebarRumah,
        landLength: panjangRumah,
        bedroomCount: bedroomCount,
      );

      for (final RoomRecommendation extra in extraRooms) {
        final bool alreadyExists = result.any(
          (room) => room.name.toLowerCase() == extra.name.toLowerCase(),
        );

        if (!alreadyExists) {
          result.add(extra);
        }
      }

      rekomendasiRuang.assignAll(result);
      hasAnalyzedRecommendation.value = true;
    } finally {
      isAnalyzingRecommendation.value = false;
      _closeLoadingDialogIfOpen();    
    }
  }

  Future<void> prosesGenerate() async {
    if (!formKey.currentState!.validate()) return;

    final double lebarRumah = double.parse(lebarController.text.trim());
    final double panjangRumah = double.parse(panjangController.text.trim());

    final int bedroomCount = estimateBedroomCount(
      landWidth: lebarRumah,
      landLength: panjangRumah,
    );

    final List<RoomRecommendation> extraRooms = _buildExtraRoomRecommendations(
      landWidth: lebarRumah,
      landLength: panjangRumah,
    );

    final List<String> extraRoomNames = _extraRoomNames(extraRooms);

    final SmartFloorPlanResult result = SmartFloorPlanEngine.generate(
      
      landWidth: lebarRumah,
      landLength: panjangRumah,
      bedroomCount: bedroomCount,
      extraRooms: extraRooms,
    );

    final List<RoomModel> generatedRooms = result.rooms;

    if (generatedRooms.isEmpty) {
      _showSnackBar(
        title: 'Gagal Generate',
        message:
            'Denah belum dapat dibuat. Coba perbesar ukuran lahan atau ubah dimensi.',
      );
      return;
    }

    if (Get.isRegistered<hasil_controller.HasilDenahController>()) {
      Get.delete<hasil_controller.HasilDenahController>();
    }

    Get.put(hasil_controller.HasilDenahController());

    final String materialDinding =
        selectedMaterials['Material Dinding'] ?? selectedMaterial.value;

await ActivityLogService.addLog(
  title: "Generate Denah",
  description:
      "Generate denah ${result.landWidth} x ${result.landLength} m ($bedroomCount kamar)",
  icon: "home",
);
    Get.to(
      () => hasil_view.HasilDenahPage(
        rooms: generatedRooms,
        inputLebarRumah: result.landWidth,
        inputPanjangRumah: result.landLength,
        material: materialDinding,
        jumlahKamar: bedroomCount,
        ruangTambahan: extraRoomNames,
      ),
      arguments: {
        'selectedMaterials': Map<String, String>.from(selectedMaterials),
        'ruangTambahan': extraRoomNames,
        'material': materialDinding,
        'luasBangunan': result.landWidth * result.landLength,
        'totalLuas': result.landWidth * result.landLength,
        'inputLebarRumah': result.landWidth,
        'inputPanjangRumah': result.landLength,
      },
    );
  }


  List<RoomRecommendation> _buildExtraRoomRecommendations({
    required double landWidth,
    required double landLength,
  }) {
    final List<String> names = _parseTambahanRuanganInput();

    if (names.isEmpty) {
      return <RoomRecommendation>[];
    }

    final double area = landWidth * landLength;
    final List<RoomRecommendation> extras = <RoomRecommendation>[];

    for (final String name in names.take(6)) {
      final String lowerName = name.toLowerCase();

      String category = 'room';
      double width = area <= 60 ? 1.8 : area <= 140 ? 2.2 : 2.8;
      double height = area <= 60 ? 1.6 : area <= 140 ? 2.0 : 2.4;

      if (lowerName.contains('mushola') ||
          lowerName.contains('musola') ||
          lowerName.contains('sholat') ||
          lowerName.contains('ibadah')) {
        category = 'room';
        width = area <= 60 ? 1.8 : 2.4;
        height = area <= 60 ? 1.8 : 2.4;
      } else if (lowerName.contains('gudang') ||
          lowerName.contains('storage')) {
        category = 'service';
        width = area <= 60 ? 1.5 : 1.8;
        height = area <= 60 ? 1.5 : 1.8;
      } else if (lowerName.contains('kerja') ||
          lowerName.contains('office') ||
          lowerName.contains('belajar')) {
        category = 'room';
        width = area <= 60 ? 1.8 : area <= 140 ? 2.4 : 3.0;
        height = area <= 60 ? 1.7 : area <= 140 ? 2.2 : 2.6;
      } else if (lowerName.contains('tamu')) {
        category = 'living';
        width = area <= 60 ? 2.2 : area <= 140 ? 3.0 : 3.6;
        height = area <= 60 ? 2.0 : area <= 140 ? 2.6 : 3.0;
      } else if (lowerName.contains('keluarga')) {
        category = 'family';
        width = area <= 60 ? 2.4 : area <= 140 ? 3.2 : 4.0;
        height = area <= 60 ? 2.0 : area <= 140 ? 2.8 : 3.2;
      } else if (lowerName.contains('cuci') ||
          lowerName.contains('laundry')) {
        category = 'service';
        width = area <= 60 ? 1.5 : 1.8;
        height = area <= 60 ? 1.5 : 1.9;
      } else if (lowerName.contains('garasi') ||
          lowerName.contains('carport')) {
        category = 'outdoor';
        width = area <= 60 ? 2.4 : 3.0;
        height = area <= 60 ? 3.0 : 4.0;
      } else if (lowerName.contains('wc') ||
          lowerName.contains('mandi') ||
          lowerName.contains('toilet')) {
        category = 'bath';
        width = 1.6;
        height = 1.8;
      } else if (lowerName.contains('dapur')) {
        category = 'kitchen';
        width = area <= 60 ? 2.0 : 2.6;
        height = area <= 60 ? 1.8 : 2.4;
      }

      extras.add(
        RoomRecommendation(
          name: _formatRoomName(name),
          category: category,
          width: width,
          height: height,
          selected: true,
        ),
      );
    }

    return extras;
  }

  List<String> _parseTambahanRuanganInput() {
    final String rawInput = tambahanRuanganController.text.trim();

    if (rawInput.isEmpty) {
      return <String>[];
    }

    final List<String> result = <String>[];
    final Set<String> usedNames = <String>{};

    final List<String> parts = rawInput
        .split(RegExp(r'[,;\n]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    for (final String part in parts) {
      final String key = part.toLowerCase();

      if (usedNames.contains(key)) {
        continue;
      }

      usedNames.add(key);
      result.add(part);
    }

    return result;
  }

  String _formatRoomName(String value) {
    final String cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleaned.isEmpty) {
      return cleaned;
    }

    return cleaned
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  List<String> _extraRoomNames(List<RoomRecommendation> extraRooms) {
    return extraRooms.map((room) => room.name).toList();
  }

  void updateRekomendasiRuang() {
    analisisRekomendasiRuang();
  }

  void _showLoadingDialog() {
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.architecture_rounded,
                  color: orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Menganalisis Kebutuhan Ruang',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sistem sedang menyusun rekomendasi ruang berdasarkan ukuran lahan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: orange,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _closeLoadingDialogIfOpen() {
    if (Get.isDialogOpen == true) Get.back();
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
    if (value == null || value.trim().isEmpty) return 'Isi angka';

    final double? number = double.tryParse(value.trim());

    if (number == null) return 'Harus angka';
    if (number <= 0) return 'Minimal lebih dari 0';

    return null;
  }

  @override
  void onClose() {
    _closeLoadingDialogIfOpen();

    lebarController.removeListener(_clearRecommendationOnInputChange);
    panjangController.removeListener(_clearRecommendationOnInputChange);
    tambahanRuanganController.removeListener(_clearRecommendationOnInputChange);

    lebarController.dispose();
    panjangController.dispose();
    tambahanRuanganController.dispose();

    super.onClose();
  }
}
