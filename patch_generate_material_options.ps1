# ============================================================
# PATCH STEP 3 - GENERATE FORM MATERIAL OPTIONS DARI SUPABASE
# Tujuan:
# - Hapus RAB awal dari halaman input
# - Ganti 1 dropdown material menjadi beberapa dropdown material utama
# - Pilihan material diambil dari tabel Supabase rab_material_options
# Jalankan dari root project: C:\Users\MyBook Hype AMD\smart_floor_plan
# ============================================================

Write-Host "==> Patch Generate Form material options dimulai..." -ForegroundColor Cyan

$controllerPath = "lib\app\modules\generate_form\controllers\generate_form_controller.dart"
$pagePath = "lib\app\modules\generate_form\views\generate_form_page.dart"

if (!(Test-Path $controllerPath)) {
  Write-Host "ERROR: Controller tidak ditemukan: $controllerPath" -ForegroundColor Red
  exit 1
}

if (!(Test-Path $pagePath)) {
  Write-Host "ERROR: Page tidak ditemukan: $pagePath" -ForegroundColor Red
  exit 1
}

Copy-Item $controllerPath "$controllerPath.before-material-options.bak" -Force
Copy-Item $pagePath "$pagePath.before-material-options.bak" -Force

# ============================================================
# 1. Overwrite generate_form_controller.dart
# ============================================================

@'
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

class GenerateFormController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController lebarController = TextEditingController();
  final TextEditingController panjangController = TextEditingController();

  // Tetap dipertahankan agar kode lama yang memakai selectedMaterial tidak rusak.
  final RxString selectedMaterial = 'bata ringan'.obs;

  // Pilihan material utama sesuai kategori dari hasil Big Data/API.
  final List<String> materialCategories = const [
    'Bata dan Dinding',
    'Semen dan Mortar',
    'Keramik dan Lantai',
    'Cat dan Finishing',
    'Kayu dan Plafon',
    'Pipa dan Instalasi',
  ];

  final RxMap<String, List<String>> materialOptionsByCategory =
      <String, List<String>>{}.obs;

  final RxMap<String, String> selectedMaterials = <String, String>{}.obs;

  final RxBool isLoadingMaterials = false.obs;
  final RxBool isAnalyzingRecommendation = false.obs;
  final RxBool hasAnalyzedRecommendation = false.obs;

  final RxList<RoomRecommendation> rekomendasiRuang =
      <RoomRecommendation>[].obs;

  // Kompatibilitas untuk view lama. View baru memakai materialOptionsByCategory.
  final List<String> materialOptions = const [
    'batu bata merah',
    'bata ringan',
    'gypsum board',
  ];

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();

    lebarController.addListener(_clearRecommendationOnInputChange);
    panjangController.addListener(_clearRecommendationOnInputChange);

    loadMaterialOptions();
  }

  Future<void> loadMaterialOptions() async {
    try {
      isLoadingMaterials.value = true;

      final response = await _supabase
          .from('rab_material_options')
          .select('kategori, nama_material, harga_rata_rata, is_active')
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

        if (kategori.isEmpty || namaMaterial.isEmpty) {
          continue;
        }

        grouped.putIfAbsent(kategori, () => <String>[]);

        if (!grouped[kategori]!.contains(namaMaterial)) {
          grouped[kategori]!.add(namaMaterial);
        }
      }

      if (grouped.isEmpty) {
        _setFallbackMaterialOptions();
      } else {
        materialOptionsByCategory.assignAll(grouped);
        _ensureDefaultSelectedMaterials();
      }
    } catch (_) {
      _setFallbackMaterialOptions();
    } finally {
      isLoadingMaterials.value = false;
    }
  }

  void _setFallbackMaterialOptions() {
    materialOptionsByCategory.assignAll({
      'Bata dan Dinding': [
        'bata ringan',
        'batu bata merah',
        'gypsum board',
      ],
      'Semen dan Mortar': [
        'semen tiga roda',
        'semen gresik',
        'semen mortar',
        'semen instan',
      ],
      'Keramik dan Lantai': [
        'keramik lantai',
        'granit lantai',
      ],
      'Cat dan Finishing': [
        'cat tembok',
        'cat tembok dulux',
        'cat tembok avian',
        'acian dinding',
      ],
      'Kayu dan Plafon': [
        'plafon pvc',
        'rangka plafon',
        'gypsum board',
        'triplek',
      ],
      'Pipa dan Instalasi': [
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

      if (options.isEmpty) {
        continue;
      }

      if (!selectedMaterials.containsKey(kategori) ||
          !options.contains(selectedMaterials[kategori])) {
        selectedMaterials[kategori] = options.first;
      }
    }

    final String? dinding = selectedMaterials['Bata dan Dinding'];
    if (dinding != null && dinding.isNotEmpty) {
      selectedMaterial.value = dinding;
    }
  }

  void changeMaterialForCategory(String kategori, String value) {
    selectedMaterials[kategori] = value;

    if (kategori == 'Bata dan Dinding') {
      selectedMaterial.value = value;
    }
  }

  void _clearRecommendationOnInputChange() {
    if (rekomendasiRuang.isNotEmpty || hasAnalyzedRecommendation.value) {
      rekomendasiRuang.clear();
      hasAnalyzedRecommendation.value = false;
    }
  }

  // Fungsi lama tetap ada agar tidak merusak pemanggilan lama.
  void changeMaterial(String value) {
    selectedMaterial.value = value;
    selectedMaterials['Bata dan Dinding'] = value;
  }

  int estimateBedroomCount({
    required double landWidth,
    required double landLength,
  }) {
    final double area = landWidth * landLength;

    if (area <= 45) {
      return 1;
    }

    if (area <= 90) {
      return 2;
    }

    if (area <= 140) {
      return 3;
    }

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

    if (isAnalyzingRecommendation.value) {
      return;
    }

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

      final List<RoomRecommendation> result =
          SmartFloorPlanEngine.getRecommendations(
        landWidth: lebarRumah,
        landLength: panjangRumah,
        bedroomCount: bedroomCount,
      );

      rekomendasiRuang.assignAll(result);
      hasAnalyzedRecommendation.value = true;
    } finally {
      isAnalyzingRecommendation.value = false;
      _closeLoadingDialogIfOpen();
    }
  }

  void prosesGenerate() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final double lebarRumah = double.parse(lebarController.text.trim());
    final double panjangRumah = double.parse(panjangController.text.trim());

    final int bedroomCount = estimateBedroomCount(
      landWidth: lebarRumah,
      landLength: panjangRumah,
    );

    final SmartFloorPlanResult result = SmartFloorPlanEngine.generate(
      landWidth: lebarRumah,
      landLength: panjangRumah,
      bedroomCount: bedroomCount,
      extraRooms: const <RoomRecommendation>[],
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
        selectedMaterials['Bata dan Dinding'] ?? selectedMaterial.value;

    Get.to(
      () => hasil_view.HasilDenahPage(
        rooms: generatedRooms,
        inputLebarRumah: result.landWidth,
        inputPanjangRumah: result.landLength,
        material: materialDinding,
        jumlahKamar: bedroomCount,
        ruangTambahan: const [],
      ),
      arguments: {
        'selectedMaterials': Map<String, String>.from(selectedMaterials),
        'material': materialDinding,
        'luasBangunan': result.landWidth * result.landLength,
        'totalLuas': result.landWidth * result.landLength,
        'inputLebarRumah': result.landWidth,
        'inputPanjangRumah': result.landLength,
      },
    );
  }

  void updateRekomendasiRuang() {
    analisisRekomendasiRuang();
  }

  void _showLoadingDialog() {
    if (Get.isDialogOpen == true) {
      return;
    }

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
    if (Get.isDialogOpen == true) {
      Get.back();
    }
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

    final double? number = double.tryParse(value.trim());

    if (number == null) {
      return 'Harus angka';
    }

    if (number <= 0) {
      return 'Minimal lebih dari 0';
    }

    return null;
  }

  @override
  void onClose() {
    _closeLoadingDialogIfOpen();

    lebarController.removeListener(_clearRecommendationOnInputChange);
    panjangController.removeListener(_clearRecommendationOnInputChange);

    lebarController.dispose();
    panjangController.dispose();

    super.onClose();
  }
}
'@ | Set-Content $controllerPath -Encoding UTF8

# ============================================================
# 2. Patch generate_form_page.dart
# ============================================================

$text = Get-Content $pagePath -Raw

# Hapus card RAB awal dari urutan UI
$text = $text -replace "\s*const SizedBox\(height: 16\),\s*_buildInitialRabPreview\(\),", ""

# Ubah judul section material
$text = $text -replace "title: 'Pilihan Material Dinding'", "title: 'Pilihan Material Utama'"
$text = $text -replace "Material digunakan sebagai dasar estimasi biaya RAB\.", "Pilih material utama sesuai data harga dari hasil Big Data/API."

# Ganti method _buildMaterialDropdown
$replacement = @'
Widget _buildMaterialDropdown() {
    return Obx(
      () {
        if (controller.isLoadingMaterials.value &&
            controller.materialOptionsByCategory.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: orange,
                    strokeWidth: 2.4,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Memuat pilihan material dari Supabase...',
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: controller.materialCategories.map((category) {
            final options =
                controller.materialOptionsByCategory[category] ?? <String>[];

            if (options.isEmpty) {
              return const SizedBox.shrink();
            }

            final selected = controller.selectedMaterials[category];

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 13),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: navy.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected != null && options.contains(selected)
                      ? selected
                      : options.first,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: navy,
                    size: 28,
                  ),
                  items: options.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: navy.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.layers_rounded,
                              color: navy,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: mutedText,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: navy,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    controller.changeMaterialForCategory(category, value);
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
'@

$text = [regex]::Replace(
  $text,
  "Widget _buildMaterialDropdown\(\) \{[\s\S]*?\n  Widget _buildInitialRabPreview",
  "$replacement`r`n`r`n  Widget _buildInitialRabPreview",
  1
)

Set-Content $pagePath $text -Encoding UTF8

Write-Host "==> Patch selesai. Mengecek error Flutter..." -ForegroundColor Green
flutter analyze 2>&1 | Select-String -Pattern "error -|Error:"
