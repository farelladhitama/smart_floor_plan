# ============================================================
# PATCH MATERIAL FINAL SESUAI LIST USER
# Kategori:
# Material Dinding, Semen, Pasir, Keramik Lantai, Cat Dinding,
# Genteng / Atap, Plafon, Pipa
# Tidak ada Besi, pasir beton, panel dinding, keramik dinding.
# Jalankan dari root project smart_floor_plan
# ============================================================

$generateController = "lib\app\modules\generate_form\controllers\generate_form_controller.dart"
$rabController = "lib\app\modules\rab\controllers\rab_controller.dart"
$rabPage = "lib\app\modules\rab\views\rab_page.dart"

if (!(Test-Path $generateController)) {
  Write-Host "ERROR: generate_form_controller.dart tidak ditemukan" -ForegroundColor Red
  exit 1
}

if (!(Test-Path $rabController)) {
  Write-Host "ERROR: rab_controller.dart tidak ditemukan" -ForegroundColor Red
  exit 1
}

Copy-Item $generateController "$generateController.before-user-final-list.bak" -Force
Copy-Item $rabController "$rabController.before-user-final-list.bak" -Force

# ------------------------------------------------------------
# Generate Form Controller
# ------------------------------------------------------------
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
    if (!formKey.currentState!.validate()) return;

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
        selectedMaterials['Material Dinding'] ?? selectedMaterial.value;

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

    lebarController.dispose();
    panjangController.dispose();

    super.onClose();
  }
}
'@ | Set-Content $generateController -Encoding UTF8

# ------------------------------------------------------------
# RAB Controller
# ------------------------------------------------------------
@'
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_floor_plan/app/services/material_price_service.dart';

class RabMaterialResult {
  final String namaMaterial;
  final String kategori;
  final String satuan;
  final double volume;
  final double hargaSatuan;

  RabMaterialResult({
    required this.namaMaterial,
    required this.kategori,
    required this.satuan,
    required this.volume,
    required this.hargaSatuan,
  });

  double get totalHarga => volume * hargaSatuan;
}

class RabController extends GetxController {
  final MaterialPriceService service = MaterialPriceService();

  final isLoading = false.obs;
  final rabItems = <RabMaterialResult>[].obs;

  final luasController = TextEditingController(text: '100');
  final luasBangunan = 100.0.obs;

  final selectedMaterials = <String, String>{}.obs;

  List<Map<String, dynamic>> rawMaterialOptions = [];
  dynamic rooms;

  final List<String> tampilKategori = const [
    'Material Dinding',
    'Semen',
    'Pasir',
    'Keramik Lantai',
    'Cat Dinding',
    'Genteng / Atap',
    'Plafon',
    'Pipa',
  ];

  @override
  void onInit() {
    super.onInit();
    readArguments();
    loadRabMaterials();
  }

  void readArguments() {
    final args = Get.arguments;

    if (args is Map) {
      final selected = args['selectedMaterials'];

      if (selected is Map) {
        selected.forEach((key, value) {
          selectedMaterials[key.toString()] = value.toString();
        });
      }

      final singleMaterial = args['material'];
      if (singleMaterial != null &&
          !selectedMaterials.containsKey('Material Dinding')) {
        selectedMaterials['Material Dinding'] = singleMaterial.toString();
      }

      final luas = args['luasBangunan'] ??
          args['totalLuas'] ??
          args['total_luas'] ??
          args['luasRuang'] ??
          args['totalLuasRuang'] ??
          args['inputLuas'];

      if (luas != null) {
        final parsed = double.tryParse(luas.toString());
        if (parsed != null && parsed > 0) {
          luasBangunan.value = parsed;
          luasController.text = parsed.toStringAsFixed(1);
        }
      }

      final lebar = args['inputLebarRumah'] ?? args['lebar_lahan'];
      final panjang = args['inputPanjangRumah'] ?? args['panjang_lahan'];

      if (lebar != null && panjang != null) {
        final w = double.tryParse(lebar.toString());
        final l = double.tryParse(panjang.toString());

        if (w != null && l != null && w > 0 && l > 0) {
          luasBangunan.value = w * l;
          luasController.text = luasBangunan.value.toStringAsFixed(1);
        }
      }
    }
  }

  void setRooms(dynamic value) {
    rooms = value;
  }

  Future<void> loadRabMaterials() async {
    try {
      isLoading.value = true;
      rawMaterialOptions = await service.getRabMaterialOptions();

      if (rawMaterialOptions.isEmpty) {
        rawMaterialOptions = fallbackMaterials();
      }

      ensureDefaultSelectedMaterials();
      calculateRab();
    } catch (e) {
      Get.snackbar('Gagal', 'Gagal mengambil data bahan RAB: $e');
      rawMaterialOptions = fallbackMaterials();
      ensureDefaultSelectedMaterials();
      calculateRab();
    } finally {
      isLoading.value = false;
    }
  }

  void ensureDefaultSelectedMaterials() {
    final defaults = {
      'Material Dinding': 'batu bata merah',
      'Semen': 'semen tiga roda',
      'Pasir': 'pasir pasang',
      'Keramik Lantai': 'keramik lantai standar',
      'Cat Dinding': 'cat tembok standar',
      'Genteng / Atap': 'genteng tanah liat',
      'Plafon': 'plafon gypsum',
      'Pipa': 'pipa pvc',
    };

    defaults.forEach((kategori, namaDefault) {
      if (!selectedMaterials.containsKey(kategori) ||
          selectedMaterials[kategori]!.trim().isEmpty) {
        selectedMaterials[kategori] =
            findExistingMaterialName(kategori, namaDefault);
      }
    });
  }

  String findExistingMaterialName(String kategori, String fallbackName) {
    final target = fallbackName.toLowerCase();

    for (final item in rawMaterialOptions) {
      final itemKategori = (item['kategori'] ?? '').toString();
      final itemName = (item['nama_material'] ?? '').toString();

      if (itemKategori == kategori && itemName.toLowerCase() == target) {
        return itemName;
      }
    }

    for (final item in rawMaterialOptions) {
      final itemKategori = (item['kategori'] ?? '').toString();
      final itemName = (item['nama_material'] ?? '').toString();

      if (itemKategori == kategori && itemName.isNotEmpty) {
        return itemName;
      }
    }

    return fallbackName;
  }

  void setLuas(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));

    if (parsed != null && parsed > 0) {
      luasBangunan.value = parsed;
      calculateRab();
    }
  }

  void calculateRab() {
    final luas = luasBangunan.value;

    final dindingM2 = luas * 2.7;
    final lantaiM2 = luas * 1.1;
    final plafonM2 = luas;
    final catM2 = dindingM2 * 1.5;
    final atapM2 = luas * 1.15;

    final results = <RabMaterialResult>[];

    for (final kategori in tampilKategori) {
      final namaMaterial = selectedMaterials[kategori];

      if (namaMaterial == null || namaMaterial.trim().isEmpty) continue;

      double volume = 0;
      String fallbackSatuan = 'pcs';
      double fallbackHarga = 0;

      if (kategori == 'Material Dinding') {
        volume = volumeDinding(namaMaterial, dindingM2);
        fallbackSatuan = satuanDinding(namaMaterial);
        fallbackHarga = 1200;
      } else if (kategori == 'Semen') {
        volume = (luas * 0.45).ceilToDouble();
        fallbackSatuan = 'sak';
        fallbackHarga = 65000;
      } else if (kategori == 'Pasir') {
        volume = round1(luas * 0.10);
        fallbackSatuan = 'm3';
        fallbackHarga = 250000;
      } else if (kategori == 'Keramik Lantai') {
        volume = round1(lantaiM2);
        fallbackSatuan = 'm2';
        fallbackHarga = 90000;
      } else if (kategori == 'Cat Dinding') {
        volume = (catM2 / 10).ceilToDouble();
        fallbackSatuan = 'liter';
        fallbackHarga = 55000;
      } else if (kategori == 'Genteng / Atap') {
        volume = volumeAtap(namaMaterial, atapM2);
        fallbackSatuan = satuanAtap(namaMaterial);
        fallbackHarga = 3500;
      } else if (kategori == 'Plafon') {
        volume = round1(plafonM2);
        fallbackSatuan = 'm2';
        fallbackHarga = 75000;
      } else if (kategori == 'Pipa') {
        volume = (luas * 0.35).ceilToDouble();
        fallbackSatuan = 'meter';
        fallbackHarga = 18000;
      }

      results.add(
        buildResult(
          kategori: kategori,
          namaMaterial: namaMaterial,
          volume: volume,
          fallbackSatuan: fallbackSatuan,
          fallbackHarga: hargaFallback(namaMaterial, fallbackHarga),
        ),
      );
    }

    rabItems.assignAll(results);
  }

  RabMaterialResult buildResult({
    required String kategori,
    required String namaMaterial,
    required double volume,
    required String fallbackSatuan,
    required double fallbackHarga,
  }) {
    final item = findMaterial(kategori, namaMaterial);

    final satuan =
        item?['satuan_rab']?.toString() ?? item?['satuan']?.toString() ?? fallbackSatuan;

    final hargaValue = item?['harga_rab'] ?? item?['harga_rata_rata'];
    double harga = fallbackHarga;

    if (hargaValue is num) {
      harga = hargaValue.toDouble();
    } else if (hargaValue != null) {
      harga = double.tryParse(hargaValue.toString()) ?? fallbackHarga;
    }

    return RabMaterialResult(
      namaMaterial: titleCase(namaMaterial),
      kategori: kategori,
      satuan: normalizeSatuan(satuan),
      volume: volume,
      hargaSatuan: harga,
    );
  }

  Map<String, dynamic>? findMaterial(String kategori, String namaMaterial) {
    final targetName = namaMaterial.toLowerCase();

    for (final item in rawMaterialOptions) {
      final itemKategori = (item['kategori'] ?? '').toString();
      final itemName = (item['nama_material'] ?? '').toString().toLowerCase();

      if (itemKategori == kategori && itemName == targetName) {
        return item;
      }
    }

    return null;
  }

  double volumeDinding(String material, double dindingM2) {
    final name = material.toLowerCase();

    if (name.contains('bata ringan') || name.contains('hebel')) {
      return (dindingM2 * 8.5).ceilToDouble();
    }

    if (name.contains('batako')) {
      return (dindingM2 * 12.5).ceilToDouble();
    }

    return (dindingM2 * 70).ceilToDouble();
  }

  String satuanDinding(String material) {
    return 'pcs';
  }

  double volumeAtap(String material, double atapM2) {
    final name = material.toLowerCase();

    if (name.contains('spandek')) {
      return round1(atapM2);
    }

    if (name.contains('beton')) {
      return (atapM2 * 10).ceilToDouble();
    }

    return (atapM2 * 25).ceilToDouble();
  }

  String satuanAtap(String material) {
    final name = material.toLowerCase();
    if (name.contains('spandek')) return 'm2';
    return 'pcs';
  }

  double hargaFallback(String material, double defaultValue) {
    final item = findMaterialByName(material);
    final value = item?['harga_rab'] ?? item?['harga_rata_rata'];

    if (value is num) return value.toDouble();
    if (value != null) return double.tryParse(value.toString()) ?? defaultValue;

    return defaultValue;
  }

  Map<String, dynamic>? findMaterialByName(String namaMaterial) {
    final target = namaMaterial.toLowerCase();

    for (final item in rawMaterialOptions) {
      final name = (item['nama_material'] ?? '').toString().toLowerCase();

      if (name == target) return item;
    }

    return null;
  }

  double round1(double value) {
    return (value * 10).round() / 10;
  }

  double get totalRab {
    return rabItems.fold(0, (sum, item) => sum + item.totalHarga);
  }

  String rupiah(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final pos = text.length - i;
      buffer.write(text[i]);
      if (pos > 1 && pos % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp${buffer.toString()}';
  }

  String formatVolume(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
      final lower = part.toLowerCase();

      if (lower == 'pvc' || lower == 'sni' || lower == 'grc') {
        return lower.toUpperCase();
      }

      if (lower.isEmpty) return lower;

      return lower[0].toUpperCase() + lower.substring(1);
    }).join(' ');
  }

  String normalizeSatuan(String value) {
    if (value == 'm²' || value == 'mÂ²' || value == 'm2') return 'm2';
    if (value == 'm³' || value == 'mÂ³' || value == 'm3') return 'm3';
    return value;
  }

  List<Map<String, dynamic>> fallbackMaterials() {
    return [
      {'kategori': 'Material Dinding', 'nama_material': 'batu bata merah', 'satuan_rab': 'pcs', 'harga_rab': 1200},
      {'kategori': 'Material Dinding', 'nama_material': 'batako', 'satuan_rab': 'pcs', 'harga_rab': 3500},
      {'kategori': 'Material Dinding', 'nama_material': 'bata ringan / hebel', 'satuan_rab': 'pcs', 'harga_rab': 8500},

      {'kategori': 'Semen', 'nama_material': 'semen tiga roda', 'satuan_rab': 'sak', 'harga_rab': 65000},
      {'kategori': 'Semen', 'nama_material': 'semen gresik', 'satuan_rab': 'sak', 'harga_rab': 65000},
      {'kategori': 'Semen', 'nama_material': 'semen padang', 'satuan_rab': 'sak', 'harga_rab': 65000},
      {'kategori': 'Semen', 'nama_material': 'semen mortar', 'satuan_rab': 'sak', 'harga_rab': 75000},
      {'kategori': 'Semen', 'nama_material': 'semen instan', 'satuan_rab': 'sak', 'harga_rab': 75000},

      {'kategori': 'Pasir', 'nama_material': 'pasir pasang', 'satuan_rab': 'm3', 'harga_rab': 250000},
      {'kategori': 'Pasir', 'nama_material': 'pasir urug', 'satuan_rab': 'm3', 'harga_rab': 180000},

      {'kategori': 'Keramik Lantai', 'nama_material': 'keramik lantai standar', 'satuan_rab': 'm2', 'harga_rab': 90000},
      {'kategori': 'Keramik Lantai', 'nama_material': 'keramik lantai premium', 'satuan_rab': 'm2', 'harga_rab': 130000},
      {'kategori': 'Keramik Lantai', 'nama_material': 'granit lantai', 'satuan_rab': 'm2', 'harga_rab': 180000},

      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok standar', 'satuan_rab': 'liter', 'harga_rab': 55000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok avian', 'satuan_rab': 'liter', 'harga_rab': 60000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok dulux', 'satuan_rab': 'liter', 'harga_rab': 75000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok nippon paint', 'satuan_rab': 'liter', 'harga_rab': 75000},

      {'kategori': 'Genteng / Atap', 'nama_material': 'genteng tanah liat', 'satuan_rab': 'pcs', 'harga_rab': 3500},
      {'kategori': 'Genteng / Atap', 'nama_material': 'genteng beton', 'satuan_rab': 'pcs', 'harga_rab': 7000},
      {'kategori': 'Genteng / Atap', 'nama_material': 'atap spandek', 'satuan_rab': 'm2', 'harga_rab': 85000},

      {'kategori': 'Plafon', 'nama_material': 'plafon gypsum', 'satuan_rab': 'm2', 'harga_rab': 75000},
      {'kategori': 'Plafon', 'nama_material': 'plafon pvc', 'satuan_rab': 'm2', 'harga_rab': 75000},
      {'kategori': 'Plafon', 'nama_material': 'plafon grc', 'satuan_rab': 'm2', 'harga_rab': 90000},

      {'kategori': 'Pipa', 'nama_material': 'pipa pvc', 'satuan_rab': 'meter', 'harga_rab': 18000},
      {'kategori': 'Pipa', 'nama_material': 'pipa air', 'satuan_rab': 'meter', 'harga_rab': 20000},
      {'kategori': 'Pipa', 'nama_material': 'pipa conduit', 'satuan_rab': 'meter', 'harga_rab': 15000},
    ];
  }

  @override
  void onClose() {
    luasController.dispose();
    super.onClose();
  }
}
'@ | Set-Content $rabController -Encoding UTF8

# ------------------------------------------------------------
# RAB Page: label harga dibuat jelas per satuan
# ------------------------------------------------------------
if (Test-Path $rabPage) {
  Copy-Item $rabPage "$rabPage.before-user-final-list.bak" -Force
  $pageText = Get-Content $rabPage -Raw

  $replacement = @'
miniInfo(
                  'Harga per 1 ${item.satuan}',
                  '${controller.rupiah(item.hargaSatuan)} / ${item.satuan}',
                )
'@

  $pageText = [regex]::Replace(
    $pageText,
    "miniInfo\(\s*'Harga satuan',\s*controller\.rupiah\(item\.hargaSatuan\),\s*\)",
    $replacement,
    1
  )

  Set-Content $rabPage $pageText -Encoding UTF8
}

flutter analyze 2>&1 | Select-String -Pattern "error -|Error:"
