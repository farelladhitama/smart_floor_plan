# ============================================================
# PATCH RAB SMARTFLOORPLAN
# Mengubah RAB dari kategori material menjadi kebutuhan bahan rumah
# Jalankan dari root project: C:\Users\MyBook Hype AMD\smart_floor_plan
# ============================================================

Write-Host "==> Patch RAB kebutuhan bahan bangunan dimulai..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force "lib\app\services" | Out-Null
New-Item -ItemType Directory -Force "lib\app\modules\rab\bindings" | Out-Null
New-Item -ItemType Directory -Force "lib\app\modules\rab\controllers" | Out-Null
New-Item -ItemType Directory -Force "lib\app\modules\rab\views" | Out-Null

$files = @(
  "lib\app\services\material_price_service.dart",
  "lib\app\modules\rab\bindings\rab_binding.dart",
  "lib\app\modules\rab\controllers\rab_controller.dart",
  "lib\app\modules\rab\views\rab_page.dart"
)

foreach ($file in $files) {
  if (Test-Path $file) {
    Copy-Item $file "$file.before-material-rab.bak" -Force
  }
}

@'
import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialPriceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRabMaterialItems() async {
    final response = await _supabase
        .from('rab_material_items')
        .select()
        .order('nama_material', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}
'@ | Set-Content "lib\app\services\material_price_service.dart" -Encoding UTF8

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

  List<Map<String, dynamic>> rawMaterials = [];
  dynamic rooms;

  @override
  void onInit() {
    super.onInit();
    readArguments();
    loadRabMaterials();
  }

  void readArguments() {
    final args = Get.arguments;

    if (args is Map) {
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
      rawMaterials = await service.getRabMaterialItems();
      calculateRab();
    } catch (e) {
      Get.snackbar('Gagal', 'Gagal mengambil data bahan RAB: $e');
      rawMaterials = fallbackMaterials();
      calculateRab();
    } finally {
      isLoading.value = false;
    }
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

    rabItems.assignAll([
      RabMaterialResult(
        namaMaterial: 'Batu Bata Merah',
        kategori: 'Dinding',
        satuan: 'pcs',
        volume: (dindingM2 * 70).ceilToDouble(),
        hargaSatuan: priceOf('Batu Bata Merah', 1200),
      ),
      RabMaterialResult(
        namaMaterial: 'Semen',
        kategori: 'Semen dan Mortar',
        satuan: 'sak',
        volume: (luas * 0.45).ceilToDouble(),
        hargaSatuan: priceOf('Semen', 65000),
      ),
      RabMaterialResult(
        namaMaterial: 'Pasir Pasang',
        kategori: 'Pasir dan Batu',
        satuan: 'm³',
        volume: round1(luas * 0.10),
        hargaSatuan: priceOf('Pasir Pasang', 250000),
      ),
      RabMaterialResult(
        namaMaterial: 'Besi Beton',
        kategori: 'Struktur',
        satuan: 'kg',
        volume: (luas * 8).ceilToDouble(),
        hargaSatuan: priceOf('Besi Beton', 16000),
      ),
      RabMaterialResult(
        namaMaterial: 'Keramik Lantai',
        kategori: 'Lantai',
        satuan: 'm²',
        volume: round1(lantaiM2),
        hargaSatuan: priceOf('Keramik Lantai', 90000),
      ),
      RabMaterialResult(
        namaMaterial: 'Cat Tembok',
        kategori: 'Finishing',
        satuan: 'liter',
        volume: (catM2 / 10).ceilToDouble(),
        hargaSatuan: priceOf('Cat Tembok', 55000),
      ),
      RabMaterialResult(
        namaMaterial: 'Pipa PVC',
        kategori: 'Instalasi Air',
        satuan: 'meter',
        volume: (luas * 0.35).ceilToDouble(),
        hargaSatuan: priceOf('Pipa PVC', 18000),
      ),
      RabMaterialResult(
        namaMaterial: 'Kabel Listrik',
        kategori: 'Instalasi Listrik',
        satuan: 'meter',
        volume: (luas * 1.5).ceilToDouble(),
        hargaSatuan: priceOf('Kabel Listrik', 12000),
      ),
      RabMaterialResult(
        namaMaterial: 'Plafon Gypsum',
        kategori: 'Plafon',
        satuan: 'm²',
        volume: round1(plafonM2),
        hargaSatuan: priceOf('Plafon Gypsum', 75000),
      ),
    ]);
  }

  double priceOf(String namaMaterial, double fallback) {
    final target = namaMaterial.toLowerCase();

    for (final item in rawMaterials) {
      final name = item['nama_material']?.toString().toLowerCase() ?? '';

      if (name == target) {
        final value = item['harga_satuan'];
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString()) ?? fallback;
      }
    }

    return fallback;
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

  List<Map<String, dynamic>> fallbackMaterials() {
    return [
      {'nama_material': 'Batu Bata Merah', 'harga_satuan': 1200},
      {'nama_material': 'Semen', 'harga_satuan': 65000},
      {'nama_material': 'Pasir Pasang', 'harga_satuan': 250000},
      {'nama_material': 'Besi Beton', 'harga_satuan': 16000},
      {'nama_material': 'Keramik Lantai', 'harga_satuan': 90000},
      {'nama_material': 'Cat Tembok', 'harga_satuan': 55000},
      {'nama_material': 'Pipa PVC', 'harga_satuan': 18000},
      {'nama_material': 'Kabel Listrik', 'harga_satuan': 12000},
      {'nama_material': 'Plafon Gypsum', 'harga_satuan': 75000},
    ];
  }

  @override
  void onClose() {
    luasController.dispose();
    super.onClose();
  }
}
'@ | Set-Content "lib\app\modules\rab\controllers\rab_controller.dart" -Encoding UTF8

@'
import 'package:get/get.dart';
import 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';

class RabBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RabController>(() => RabController());
  }
}
'@ | Set-Content "lib\app\modules\rab\bindings\rab_binding.dart" -Encoding UTF8

@'
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';

class RabPage extends GetView<RabController> {
  final dynamic rooms;

  const RabPage({
    super.key,
    this.rooms,
  });

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        title: const Text(
          'Estimasi RAB',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: orange),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerCard(),
                  const SizedBox(height: 18),
                  inputCard(),
                  const SizedBox(height: 18),
                  totalCard(),
                  const SizedBox(height: 18),
                  materialListCard(),
                  const SizedBox(height: 18),
                  noteCard(),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: orange,
            radius: 26,
            child: Icon(Icons.receipt_long_rounded, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Estimasi awal bahan bangunan rumah berdasarkan luas lahan/denah dan data harga dari Supabase.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget inputCard() {
    return card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Perhitungan',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.luasController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: controller.setLuas,
            decoration: InputDecoration(
              labelText: 'Luas bangunan',
              suffixText: 'm²',
              prefixIcon: const Icon(Icons.square_foot_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: orange,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Estimasi Kebutuhan Material',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.rupiah(controller.totalRab),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Berdasarkan luas ${controller.luasBangunan.value.toStringAsFixed(1)} m²',
            style: const TextStyle(
              color: Color(0xFFFFEFE6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget materialListCard() {
    return card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kebutuhan Bahan Bangunan',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Jumlah bahan dihitung otomatis dari luas bangunan menggunakan koefisien estimasi awal.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...controller.rabItems.map(materialItem),
        ],
      ),
    );
  }

  Widget materialItem(RabMaterialResult item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.namaMaterial,
            style: const TextStyle(
              color: navy,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.kategori,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: miniInfo(
                  'Kebutuhan',
                  '${controller.formatVolume(item.volume)} ${item.satuan}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: miniInfo(
                  'Harga satuan',
                  controller.rupiah(item.hargaSatuan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          miniInfo(
            'Subtotal',
            controller.rupiah(item.totalHarga),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget miniInfo(String label, String value, {bool highlight = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFEFE6) : Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: highlight ? orange : navy,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget noteCard() {
    return card(
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Catatan: hasil RAB ini berupa estimasi awal. Jumlah bahan dan harga dapat berubah sesuai desain akhir, lokasi pembangunan, kualitas material, dan harga pasar terbaru.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: child,
    );
  }
}
'@ | Set-Content "lib\app\modules\rab\views\rab_page.dart" -Encoding UTF8

if (Test-Path "lib\services\material_price_service.dart") {
  Remove-Item "lib\services\material_price_service.dart" -Force
}

Write-Host "==> Patch selesai. Mengecek error Flutter..." -ForegroundColor Green
flutter analyze 2>&1 | Select-String -Pattern "error -|Error:"
