# ============================================================
# PATCH RAB FINAL - HANYA TAMPILKAN MATERIAL YANG DIPILIH DI INPUT
# Fix:
# - Hilangkan material otomatis lama seperti Pasir Pasang dan Besi Beton
# - RAB hanya menampilkan pilihan user dari Generate Form
# - Hilangkan teks aneh mÂ² / mÂ³ dengan satuan aman: m2 / m3
# Jalankan dari root project: C:\Users\MyBook Hype AMD\smart_floor_plan
# ============================================================

Write-Host "==> Patch RAB final dimulai..." -ForegroundColor Cyan

$controllerPath = "lib\app\modules\rab\controllers\rab_controller.dart"
$pagePath = "lib\app\modules\rab\views\rab_page.dart"

if (!(Test-Path $controllerPath)) {
  Write-Host "ERROR: File tidak ditemukan: $controllerPath" -ForegroundColor Red
  exit 1
}

Copy-Item $controllerPath "$controllerPath.before-final-selected-only.bak" -Force

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
    'Bata dan Dinding',
    'Semen dan Mortar',
    'Keramik dan Lantai',
    'Cat dan Finishing',
    'Kayu dan Plafon',
    'Pipa dan Instalasi',
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
          !selectedMaterials.containsKey('Bata dan Dinding')) {
        selectedMaterials['Bata dan Dinding'] = singleMaterial.toString();
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
      'Bata dan Dinding': 'bata ringan',
      'Semen dan Mortar': 'semen tiga roda',
      'Keramik dan Lantai': 'keramik lantai',
      'Cat dan Finishing': 'cat tembok',
      'Kayu dan Plafon': 'plafon pvc',
      'Pipa dan Instalasi': 'pipa pvc',
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

    final results = <RabMaterialResult>[];

    for (final kategori in tampilKategori) {
      final namaMaterial = selectedMaterials[kategori];

      if (namaMaterial == null || namaMaterial.trim().isEmpty) {
        continue;
      }

      double volume = 0;
      String fallbackSatuan = 'pcs';
      double fallbackHarga = 0;

      if (kategori == 'Bata dan Dinding') {
        volume = volumeDinding(namaMaterial, dindingM2);
        fallbackSatuan = satuanDinding(namaMaterial);
        fallbackHarga = 1200;
      } else if (kategori == 'Semen dan Mortar') {
        volume = (luas * 0.45).ceilToDouble();
        fallbackSatuan = 'sak';
        fallbackHarga = 65000;
      } else if (kategori == 'Keramik dan Lantai') {
        volume = round1(lantaiM2);
        fallbackSatuan = 'm2';
        fallbackHarga = 90000;
      } else if (kategori == 'Cat dan Finishing') {
        volume = volumeCat(namaMaterial, catM2, dindingM2);
        fallbackSatuan = satuanCat(namaMaterial);
        fallbackHarga = 55000;
      } else if (kategori == 'Kayu dan Plafon') {
        volume = volumePlafon(namaMaterial, plafonM2);
        fallbackSatuan = satuanPlafon(namaMaterial);
        fallbackHarga = 75000;
      } else if (kategori == 'Pipa dan Instalasi') {
        volume = (luas * 0.35).ceilToDouble();
        fallbackSatuan = satuanPipa(namaMaterial);
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

    final satuan = item?['satuan']?.toString() ?? fallbackSatuan;

    final hargaValue = item?['harga_rata_rata'];
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

    for (final item in rawMaterialOptions) {
      final itemKategori = (item['kategori'] ?? '').toString();
      final itemName = (item['nama_material'] ?? '').toString().toLowerCase();

      if (itemKategori == kategori &&
          (itemName.contains(targetName) || targetName.contains(itemName))) {
        return item;
      }
    }

    return null;
  }

  double volumeDinding(String material, double dindingM2) {
    final name = material.toLowerCase();

    if (name.contains('hebel') || name.contains('bata ringan')) {
      return (dindingM2 * 8.5).ceilToDouble();
    }

    if (name.contains('gypsum') ||
        name.contains('panel') ||
        name.contains('board')) {
      return (dindingM2 / 2.88).ceilToDouble();
    }

    return (dindingM2 * 70).ceilToDouble();
  }

  String satuanDinding(String material) {
    final name = material.toLowerCase();

    if (name.contains('gypsum') ||
        name.contains('panel') ||
        name.contains('board')) {
      return 'lembar';
    }

    return 'pcs';
  }

  double volumeCat(String material, double catM2, double dindingM2) {
    final name = material.toLowerCase();

    if (name.contains('acian') || name.contains('plamir')) {
      return (dindingM2 * 0.20).ceilToDouble();
    }

    return (catM2 / 10).ceilToDouble();
  }

  String satuanCat(String material) {
    final name = material.toLowerCase();

    if (name.contains('acian')) return 'sak';
    if (name.contains('plamir')) return 'kg';

    return 'liter';
  }

  double volumePlafon(String material, double plafonM2) {
    final name = material.toLowerCase();

    if (name.contains('rangka')) {
      return (plafonM2 * 1.5).ceilToDouble();
    }

    if (name.contains('triplek') ||
        name.contains('multiplek') ||
        name.contains('papan')) {
      return (plafonM2 / 2.88).ceilToDouble();
    }

    return round1(plafonM2);
  }

  String satuanPlafon(String material) {
    final name = material.toLowerCase();

    if (name.contains('rangka')) return 'batang';

    if (name.contains('triplek') ||
        name.contains('multiplek') ||
        name.contains('papan')) {
      return 'lembar';
    }

    return 'm2';
  }

  String satuanPipa(String material) {
    final name = material.toLowerCase();

    if (name.contains('elbow') || name.contains('sambungan')) {
      return 'pcs';
    }

    return 'meter';
  }

  double hargaFallback(String material, double defaultValue) {
    final item = findMaterialByName(material);

    final value = item?['harga_rata_rata'];

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
      {'kategori': 'Bata dan Dinding', 'nama_material': 'bata ringan', 'satuan': 'pcs', 'harga_rata_rata': 4284656},
      {'kategori': 'Bata dan Dinding', 'nama_material': 'batu bata merah', 'satuan': 'pcs', 'harga_rata_rata': 269000},
      {'kategori': 'Bata dan Dinding', 'nama_material': 'gypsum board', 'satuan': 'lembar', 'harga_rata_rata': 456652},

      {'kategori': 'Semen dan Mortar', 'nama_material': 'semen tiga roda', 'satuan': 'sak', 'harga_rata_rata': 289000},
      {'kategori': 'Semen dan Mortar', 'nama_material': 'semen padang', 'satuan': 'sak', 'harga_rata_rata': 289000},
      {'kategori': 'Semen dan Mortar', 'nama_material': 'semen gresik', 'satuan': 'sak', 'harga_rata_rata': 289000},
      {'kategori': 'Semen dan Mortar', 'nama_material': 'semen mortar', 'satuan': 'sak', 'harga_rata_rata': 289000},

      {'kategori': 'Keramik dan Lantai', 'nama_material': 'keramik lantai', 'satuan': 'm2', 'harga_rata_rata': 50000},
      {'kategori': 'Keramik dan Lantai', 'nama_material': 'granit lantai', 'satuan': 'm2', 'harga_rata_rata': 354000},

      {'kategori': 'Cat dan Finishing', 'nama_material': 'cat tembok', 'satuan': 'liter', 'harga_rata_rata': 1594076},
      {'kategori': 'Cat dan Finishing', 'nama_material': 'cat tembok dulux', 'satuan': 'liter', 'harga_rata_rata': 112100},
      {'kategori': 'Cat dan Finishing', 'nama_material': 'cat tembok avian', 'satuan': 'liter', 'harga_rata_rata': 112100},
      {'kategori': 'Cat dan Finishing', 'nama_material': 'acian dinding', 'satuan': 'sak', 'harga_rata_rata': 519463},

      {'kategori': 'Kayu dan Plafon', 'nama_material': 'plafon pvc', 'satuan': 'm2', 'harga_rata_rata': 419000},
      {'kategori': 'Kayu dan Plafon', 'nama_material': 'rangka plafon', 'satuan': 'batang', 'harga_rata_rata': 3900000},
      {'kategori': 'Kayu dan Plafon', 'nama_material': 'triplek', 'satuan': 'lembar', 'harga_rata_rata': 937000},

      {'kategori': 'Pipa dan Instalasi', 'nama_material': 'pipa pvc', 'satuan': 'meter', 'harga_rata_rata': 806571},
      {'kategori': 'Pipa dan Instalasi', 'nama_material': 'pipa air', 'satuan': 'meter', 'harga_rata_rata': 598000},
      {'kategori': 'Pipa dan Instalasi', 'nama_material': 'pipa conduit', 'satuan': 'meter', 'harga_rata_rata': 598000},
    ];
  }

  @override
  void onClose() {
    luasController.dispose();
    super.onClose();
  }
}
'@ | Set-Content $controllerPath -Encoding UTF8

# Bersihkan simbol m aneh di page kalau ada
if (Test-Path $pagePath) {
  Copy-Item $pagePath "$pagePath.before-unit-fix.bak" -Force
  $pageText = Get-Content $pagePath -Raw
  $pageText = $pageText -replace "mÂ²", "m2"
  $pageText = $pageText -replace "mÂ³", "m3"
  $pageText = $pageText -replace "m²", "m2"
  $pageText = $pageText -replace "m³", "m3"
  Set-Content $pagePath $pageText -Encoding UTF8
}

Write-Host "==> Patch selesai. Mengecek error Flutter..." -ForegroundColor Green
flutter analyze 2>&1 | Select-String -Pattern "error -|Error:"
