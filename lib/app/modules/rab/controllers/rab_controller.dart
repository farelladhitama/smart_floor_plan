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

      final lebar = args['inputLebarRumah'];
      final panjang = args['inputPanjangRumah'];

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
        satuan: 'mÂ³',
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
        satuan: 'mÂ²',
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
        satuan: 'mÂ²',
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
