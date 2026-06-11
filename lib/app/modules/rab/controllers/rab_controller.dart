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
  static Map<String, dynamic>? pendingArguments;
  String _lastAppliedArgumentsSignature = '';
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
    final dynamic routeArgs = Get.arguments;
    final dynamic args = routeArgs is Map ? routeArgs : pendingArguments;
    applyArgumentsFromPage(args);
  }

  void applyArgumentsFromPage(dynamic value) {
    final dynamic args = value is Map ? value : pendingArguments;

    if (args is! Map) {
      return;
    }

    final String signature = args.toString();

    if (_lastAppliedArgumentsSignature == signature) {
      return;
    }

    _lastAppliedArgumentsSignature = signature;
    pendingArguments = null;

    final selected = args['selectedMaterials'];

    if (selected is Map) {
      selected.forEach((key, value) {
        selectedMaterials[key.toString()] = value.toString();
      });
    }

    final singleMaterial = args['material'];
    if (singleMaterial != null &&
        singleMaterial.toString().trim().isNotEmpty) {
      selectedMaterials['Material Dinding'] = singleMaterial.toString();
    }

    final luas = args['luasBangunan'] ??
        args['totalLuas'] ??
        args['total_luas'] ??
        args['luasRuang'] ??
        args['totalLuasRuang'] ??
        args['inputLuas'];

    if (luas != null) {
      final parsed = double.tryParse(luas.toString().replaceAll(',', '.'));

      if (parsed != null && parsed > 0) {
        luasBangunan.value = parsed;
        luasController.text = parsed.toStringAsFixed(1);
      }
    }

    final lebar = args['inputLebarRumah'] ?? args['lebar_lahan'];
    final panjang = args['inputPanjangRumah'] ?? args['panjang_lahan'];

    if (lebar != null && panjang != null) {
      final w = double.tryParse(lebar.toString().replaceAll(',', '.'));
      final l = double.tryParse(panjang.toString().replaceAll(',', '.'));

      if (w != null && l != null && w > 0 && l > 0) {
        luasBangunan.value = w * l;
        luasController.text = luasBangunan.value.toStringAsFixed(1);
      }
    }

    if (rawMaterialOptions.isNotEmpty) {
      ensureDefaultSelectedMaterials();
      calculateRab();
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
    if (value == 'mÂ²' || value == 'mÃ‚Â²' || value == 'm2') return 'm2';
    if (value == 'mÂ³' || value == 'mÃ‚Â³' || value == 'm3') return 'm3';
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


