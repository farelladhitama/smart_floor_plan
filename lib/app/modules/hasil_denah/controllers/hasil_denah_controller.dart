import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/edit_denah/controllers/edit_denah_controller.dart';
import 'package:smart_floor_plan/app/modules/edit_denah/views/edit_denah_page.dart';
import 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';
import 'package:smart_floor_plan/app/modules/rab/views/rab_page.dart';
import 'package:smart_floor_plan/app/modules/riwayat/controllers/riwayat_controller.dart';
import 'package:smart_floor_plan/app/services/material_price_service.dart';
import 'package:smart_floor_plan/app/services/activity_log_service.dart';

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
  Map<String, String> selectedMaterials = <String, String>{};
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
    selectedMaterials = _effectiveSelectedMaterials();
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

  double _cachedEstimasiRab = 0;

double get estimasiRab {
  if (_cachedEstimasiRab > 0) {
    return _cachedEstimasiRab;
  }

  return totalLandArea * 3500000;
}

  int get indoorRoomCount {
    return currentRooms.where((room) => !room.isOutdoor).length;
  }

  Map<String, String> _selectedMaterialsFromArguments() {
    final dynamic args = Get.arguments;

    if (args is Map) {
      final dynamic selected = args['selectedMaterials'];

      if (selected is Map) {
        final Map<String, String> result = <String, String>{};

        selected.forEach((key, value) {
          final String kategori = key.toString().trim();
          final String materialName = value.toString().trim();

          if (kategori.isNotEmpty && materialName.isNotEmpty) {
            result[kategori] = materialName;
          }
        });

        return result;
      }
    }

    return <String, String>{};
  }

  Map<String, String> _effectiveSelectedMaterials() {
    final Map<String, String> fromArgs = _selectedMaterialsFromArguments();

    if (fromArgs.isNotEmpty) {
      selectedMaterials = fromArgs;
      return Map<String, String>.from(fromArgs);
    }

    if (selectedMaterials.isNotEmpty) {
      return Map<String, String>.from(selectedMaterials);
    }

    return <String, String>{
      'Material Dinding': material,
    };
  }

  Map<String, dynamic> _buildRabArguments() {
  final double luas = totalLandArea;
  final Map<String, String> selected = _effectiveSelectedMaterials();

  return {
    'luasBangunan': luas,
    'totalLuas': luas,
    'total_luas': luas,
    'estimasi_rab': estimasiRab,
    'inputLuas': luas,
    'inputLebarRumah': landWidth,
    'inputPanjangRumah': landLength,
    'lebar_lahan': landWidth,
    'panjang_lahan': landLength,
    'material': selected['Material Dinding'] ?? material,
    'selectedMaterials': selected,
    'jenisTukang':
    Get.arguments?['jenisTukang'] ?? 'Tukang Harian',
  };
}


  bool _isScanModeFromArguments() {
    final dynamic args = Get.arguments;

    if (args is Map) {
      return args['scanMode'] == true;
    }

    return false;
  }

  String? _scanImageNameFromArguments() {
    final dynamic args = Get.arguments;

    if (args is Map) {
      final dynamic value = args['scanImageName'];

      if (value == null) return null;

      final String text = value.toString().trim();

      if (text.isEmpty) return null;

      return text;
    }

    return null;
  }

  Map<String, String> _scanSelectedMaterialsFromArguments() {
    final dynamic args = Get.arguments;
    final Map<String, String> result = <String, String>{};

    if (args is Map) {
      final dynamic selected = args['selectedMaterials'];

      if (selected is Map) {
        selected.forEach((dynamic key, dynamic value) {
          final String mapKey = key.toString().trim();
          final String mapValue = value.toString().trim();

          if (mapKey.isNotEmpty && mapValue.isNotEmpty) {
            result[mapKey] = mapValue;
          }
        });
      }
    }

    if (!result.containsKey('Material Dinding')) {
      result['Material Dinding'] = material;
    }

    return result;
  }

  double _scanToDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    final String cleaned = value
        .toString()
        .replaceAll('Rp', '')
        .replaceAll('rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .trim();

    return double.tryParse(cleaned) ?? 0;
  }

  Future<double> _calculateScanEstimasiRab({
    required Map<String, String> selectedMaterials,
    required double luasBangunan,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('rab_material_options')
          .select('kategori, nama_material, harga_rab, harga_rata_rata');

      final List<Map<String, dynamic>> rows = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final double luas = luasBangunan;

      final double dindingM2 = luas * 2.7;
      final double lantaiM2 = luas * 1.1;
      final double plafonM2 = luas;
      final double catM2 = dindingM2 * 1.5;
      final double atapM2 = luas * 1.15;

      final List<String> kategoriList = const [
        'Material Dinding',
        'Semen',
        'Pasir',
        'Keramik Lantai',
        'Cat Dinding',
        'Genteng / Atap',
        'Plafon',
        'Pipa',
      ];

      double total = 0;

      for (final String kategori in kategoriList) {
        final String? namaMaterial = selectedMaterials[kategori];

        if (namaMaterial == null || namaMaterial.trim().isEmpty) {
          continue;
        }

        double volume = 0;
        double fallbackHarga = 0;

        if (kategori == 'Material Dinding') {
          volume = _scanVolumeDinding(namaMaterial, dindingM2);
          fallbackHarga = 1200;
        } else if (kategori == 'Semen') {
          volume = (luas * 0.45).ceilToDouble();
          fallbackHarga = 65000;
        } else if (kategori == 'Pasir') {
          volume = _scanRound1(luas * 0.10);
          fallbackHarga = 250000;
        } else if (kategori == 'Keramik Lantai') {
          volume = _scanRound1(lantaiM2);
          fallbackHarga = 90000;
        } else if (kategori == 'Cat Dinding') {
          volume = (catM2 / 10).ceilToDouble();
          fallbackHarga = 55000;
        } else if (kategori == 'Genteng / Atap') {
          volume = _scanVolumeAtap(namaMaterial, atapM2);
          fallbackHarga = 3500;
        } else if (kategori == 'Plafon') {
          volume = _scanRound1(plafonM2);
          fallbackHarga = 75000;
        } else if (kategori == 'Pipa') {
          volume = (luas * 0.35).ceilToDouble();
          fallbackHarga = 18000;
        }

        final double harga = _scanHargaMaterial(
          rows: rows,
          kategori: kategori,
          namaMaterial: namaMaterial,
          fallbackHarga: fallbackHarga,
        );

        total += volume * harga;
      }

      if (total <= 0) {
        return luasBangunan * 3500000;
      }

      return total;
    } catch (_) {
      return luasBangunan * 3500000;
    }
  }

  double _scanHargaMaterial({
    required List<Map<String, dynamic>> rows,
    required String kategori,
    required String namaMaterial,
    required double fallbackHarga,
  }) {
    final Map<String, dynamic>? item = _scanFindMaterial(
      rows: rows,
      kategori: kategori,
      namaMaterial: namaMaterial,
    );

    dynamic hargaValue = item?['harga_rab'] ?? item?['harga_rata_rata'];

    if (hargaValue == null) {
      final Map<String, dynamic>? itemByName = _scanFindMaterialByName(
        rows: rows,
        namaMaterial: namaMaterial,
      );

      hargaValue = itemByName?['harga_rab'] ?? itemByName?['harga_rata_rata'];
    }

    final double harga = _scanToDouble(hargaValue);

    if (harga > 0) {
      return harga;
    }

    return fallbackHarga;
  }

  Map<String, dynamic>? _scanFindMaterial({
    required List<Map<String, dynamic>> rows,
    required String kategori,
    required String namaMaterial,
  }) {
    final String targetKategori = kategori.toLowerCase().trim();
    final String targetName = namaMaterial.toLowerCase().trim();

    for (final Map<String, dynamic> item in rows) {
      final String itemKategori =
          (item['kategori'] ?? '').toString().toLowerCase().trim();
      final String itemName =
          (item['nama_material'] ?? '').toString().toLowerCase().trim();

      if (itemKategori == targetKategori && itemName == targetName) {
        return item;
      }
    }

    return null;
  }

  Map<String, dynamic>? _scanFindMaterialByName({
    required List<Map<String, dynamic>> rows,
    required String namaMaterial,
  }) {
    final String targetName = namaMaterial.toLowerCase().trim();

    for (final Map<String, dynamic> item in rows) {
      final String itemName =
          (item['nama_material'] ?? '').toString().toLowerCase().trim();

      if (itemName == targetName) {
        return item;
      }
    }

    return null;
  }

  double _scanVolumeDinding(String material, double dindingM2) {
    final String name = material.toLowerCase();

    if (name.contains('bata ringan') || name.contains('hebel')) {
      return (dindingM2 * 8.5).ceilToDouble();
    }

    if (name.contains('batako')) {
      return (dindingM2 * 12.5).ceilToDouble();
    }

    return (dindingM2 * 70).ceilToDouble();
  }

  double _scanVolumeAtap(String material, double atapM2) {
    final String name = material.toLowerCase();

    if (name.contains('spandek')) {
      return _scanRound1(atapM2);
    }

    if (name.contains('beton')) {
      return (atapM2 * 10).ceilToDouble();
    }

    return (atapM2 * 25).ceilToDouble();
  }

  double _scanRound1(double value) {
    return (value * 10).round() / 10;
  }

  Future<void> _simpanScanDenah() async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        Get.snackbar(
          'Gagal',
          'User belum login, hasil scan tidak bisa disimpan.',
        );
        return;
      }

      final Map<String, String> selectedMaterials =
          _scanSelectedMaterialsFromArguments();

      final double totalLuas = landWidth * landLength;

      final double estimasiRab = await _calculateScanEstimasiRab(
        selectedMaterials: selectedMaterials,
        luasBangunan: totalLuas,
      );

      final List<Map<String, dynamic>> detectedRoomsJson = currentRooms
          .map((room) => {
                'name': room.nama,
                'x': room.x,
                'y': room.y,
                'width': room.width,
                'height': room.height,
                'area': room.width * room.height,
              })
          .toList();

      final String userName =
          user.userMetadata?['full_name']?.toString() ??
          user.userMetadata?['name']?.toString() ??
          user.email ??
          '';

      final Map<String, dynamic> payload = {
        'user_id': user.id,
        'user_name': userName,
        'title': 'Hasil Scan Denah',
        'panjang_lahan': landLength,
        'lebar_lahan': landWidth,
        'jumlah_ruang': currentRooms.length,
        'material_dinding': selectedMaterials['Material Dinding'],
        'material_semen': selectedMaterials['Semen'],
        'material_pasir': selectedMaterials['Pasir'],
        'material_keramik_lantai': selectedMaterials['Keramik Lantai'],
        'material_cat_dinding': selectedMaterials['Cat Dinding'],
        'material_genteng_atap': selectedMaterials['Genteng / Atap'],
        'material_plafon': selectedMaterials['Plafon'],
        'material_pipa': selectedMaterials['Pipa'],
        'total_luas': totalLuas,
        'estimasi_rab': estimasiRab,
        'detected_rooms_json': detectedRoomsJson,
        'scan_image_name': _scanImageNameFromArguments(),
        'updated_at': DateTime.now().toIso8601String(),
        'jenis_tukang': Get.arguments?['jenisTukang'] ?? 'Tukang Harian',
      };

      if (floorPlanId != null && floorPlanId!.isNotEmpty && isSaved.value) {
        await supabase
            .from('scan_floor_plans')
            .update(payload)
            .eq('id', floorPlanId!);

        Get.snackbar(
          'Berhasil',
          'Hasil scan berhasil diperbarui di Riwayat Desain.',
        );
      } else {
        final response = await supabase
            .from('scan_floor_plans')
            .insert(payload)
            .select('id')
            .single();

        floorPlanId = response['id']?.toString();
        isSaved.value = true;

        Get.snackbar(
          'Berhasil',
          'Hasil scan berhasil disimpan ke Riwayat Desain.',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Gagal simpan scan',
        e.toString(),
      );
    } finally {
      isSaving.value = false;
    }
  }


  Future<void> simpanDenah() async {
    if (_isScanModeFromArguments()) {
      await _simpanScanDenah();
      return;
    }

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
      final Map<String, String> selected = _effectiveSelectedMaterials();
final double estimasiMaterialRab =
    await _calculateEstimasiMaterialRab(
      selectedMaterials: selected,
      luasBangunan: totalLandArea,
    );

_cachedEstimasiRab = estimasiMaterialRab;

print('==============');
print('JENIS TUKANG = ${Get.arguments?['jenisTukang']}');
print('=============='); 

      final Map<String, dynamic> payload = {
        'user_id': user.id,
        'user_name': _getUserName(user),
        'title': title,
        'panjang_lahan': landLength,
        'lebar_lahan': landWidth,
        'jumlah_kamar': jumlahKamar,
        'jenis_tukang': Get.arguments?['jenisTukang'] ?? 'Tukang Harian',
        'material_dinding': selected['Material Dinding'] ?? material,
        'material_semen': selected['Semen'],
        'material_pasir': selected['Pasir'],
        'material_keramik_lantai': selected['Keramik Lantai'],
        'material_cat_dinding': selected['Cat Dinding'],
        'material_genteng_atap': selected['Genteng / Atap'],
        'material_plafon': selected['Plafon'],
        'material_pipa': selected['Pipa'],
        'ruang_tambahan': ruangTambahan,
        'total_luas': totalLandArea,
        'estimasi_rab': estimasiMaterialRab,
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
      await ActivityLogService.addLog(
  title: "Simpan Denah",
  description:
      "Denah ${landWidth.toStringAsFixed(1)} x ${landLength.toStringAsFixed(1)} berhasil disimpan",
  icon: "save",
);

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

  Future<double> _calculateEstimasiMaterialRab({
    required Map<String, String> selectedMaterials,
    required double luasBangunan,
  }) async {
    List<Map<String, dynamic>> materialOptions = <Map<String, dynamic>>[];

    try {
      materialOptions = await MaterialPriceService().getRabMaterialOptions();
    } catch (_) {
      materialOptions = <Map<String, dynamic>>[];
    }

    if (materialOptions.isEmpty) {
      materialOptions = _fallbackRabMaterials();
    }

    final Map<String, String> selected = Map<String, String>.from(
      selectedMaterials,
    );

    _ensureDefaultRabMaterials(
      selected: selected,
      materialOptions: materialOptions,
    );

    final double luas = luasBangunan;
    final double dindingM2 = luas * 2.7;
    final double lantaiM2 = luas * 1.1;
    final double plafonM2 = luas;
    final double catM2 = dindingM2 * 1.5;
    final double atapM2 = luas * 1.15;

    double total = 0;

    for (final String kategori in _rabCategories) {
      final String? namaMaterial = selected[kategori];

      if (namaMaterial == null || namaMaterial.trim().isEmpty) {
        continue;
      }

      double volume = 0;
      double fallbackHarga = 0;

      if (kategori == 'Material Dinding') {
        volume = _volumeDindingRab(namaMaterial, dindingM2);
        fallbackHarga = 1200;
      } else if (kategori == 'Semen') {
        volume = (luas * 0.45).ceilToDouble();
        fallbackHarga = 65000;
      } else if (kategori == 'Pasir') {
        volume = _roundRab(luas * 0.10);
        fallbackHarga = 250000;
      } else if (kategori == 'Keramik Lantai') {
        volume = _roundRab(lantaiM2);
        fallbackHarga = 90000;
      } else if (kategori == 'Cat Dinding') {
        volume = (catM2 / 10).ceilToDouble();
        fallbackHarga = 55000;
      } else if (kategori == 'Genteng / Atap') {
        volume = _volumeAtapRab(namaMaterial, atapM2);
        fallbackHarga = 3500;
      } else if (kategori == 'Plafon') {
        volume = _roundRab(plafonM2);
        fallbackHarga = 75000;
      } else if (kategori == 'Pipa') {
        volume = (luas * 0.35).ceilToDouble();
        fallbackHarga = 18000;
      }

      final double harga = _hargaRabMaterial(
        materialOptions: materialOptions,
        namaMaterial: namaMaterial,
        fallbackHarga: fallbackHarga,
      );

      total += volume * harga;
    }

    return total;
  }

  static const List<String> _rabCategories = [
    'Material Dinding',
    'Semen',
    'Pasir',
    'Keramik Lantai',
    'Cat Dinding',
    'Genteng / Atap',
    'Plafon',
    'Pipa',
  ];

  void _ensureDefaultRabMaterials({
    required Map<String, String> selected,
    required List<Map<String, dynamic>> materialOptions,
  }) {
    final Map<String, String> defaults = {
      'Material Dinding': material,
      'Semen': 'semen tiga roda',
      'Pasir': 'pasir pasang',
      'Keramik Lantai': 'keramik lantai standar',
      'Cat Dinding': 'cat tembok standar',
      'Genteng / Atap': 'genteng tanah liat',
      'Plafon': 'plafon gypsum',
      'Pipa': 'pipa pvc',
    };

    defaults.forEach((kategori, namaDefault) {
      if (!selected.containsKey(kategori) ||
          selected[kategori]!.trim().isEmpty) {
        selected[kategori] = _findExistingRabMaterialName(
          materialOptions,
          kategori,
          namaDefault,
        );
      }
    });
  }

  String _findExistingRabMaterialName(
    List<Map<String, dynamic>> materialOptions,
    String kategori,
    String fallbackName,
  ) {
    final String target = fallbackName.toLowerCase();

    for (final Map<String, dynamic> item in materialOptions) {
      final String itemKategori = (item['kategori'] ?? '').toString();
      final String itemName = (item['nama_material'] ?? '').toString();

      if (itemKategori == kategori && itemName.toLowerCase() == target) {
        return itemName;
      }
    }

    for (final Map<String, dynamic> item in materialOptions) {
      final String itemKategori = (item['kategori'] ?? '').toString();
      final String itemName = (item['nama_material'] ?? '').toString();

      if (itemKategori == kategori && itemName.isNotEmpty) {
        return itemName;
      }
    }

    return fallbackName;
  }

  double _hargaRabMaterial({
    required List<Map<String, dynamic>> materialOptions,
    required String namaMaterial,
    required double fallbackHarga,
  }) {
    final String target = namaMaterial.toLowerCase();

    for (final Map<String, dynamic> item in materialOptions) {
      final String name = (item['nama_material'] ?? '').toString().toLowerCase();

      if (name == target) {
        final dynamic value = item['harga_rab'] ?? item['harga_rata_rata'];

        if (value is num) {
          return value.toDouble();
        }

        if (value != null) {
          return double.tryParse(value.toString()) ?? fallbackHarga;
        }
      }
    }

    return fallbackHarga;
  }

  double _volumeDindingRab(String material, double dindingM2) {
    final String name = material.toLowerCase();

    if (name.contains('bata ringan') || name.contains('hebel')) {
      return (dindingM2 * 8.5).ceilToDouble();
    }

    if (name.contains('batako')) {
      return (dindingM2 * 12.5).ceilToDouble();
    }

    return (dindingM2 * 70).ceilToDouble();
  }

  double _volumeAtapRab(String material, double atapM2) {
    final String name = material.toLowerCase();

    if (name.contains('spandek')) {
      return _roundRab(atapM2);
    }

    if (name.contains('beton')) {
      return (atapM2 * 10).ceilToDouble();
    }

    return (atapM2 * 25).ceilToDouble();
  }

  double _roundRab(double value) {
    return (value * 10).round() / 10;
  }

  List<Map<String, dynamic>> _fallbackRabMaterials() {
    return [
      {'kategori': 'Material Dinding', 'nama_material': 'batu bata merah', 'harga_rab': 1200},
      {'kategori': 'Material Dinding', 'nama_material': 'batako', 'harga_rab': 3500},
      {'kategori': 'Material Dinding', 'nama_material': 'bata ringan / hebel', 'harga_rab': 8500},
      {'kategori': 'Semen', 'nama_material': 'semen tiga roda', 'harga_rab': 65000},
      {'kategori': 'Semen', 'nama_material': 'semen gresik', 'harga_rab': 65000},
      {'kategori': 'Semen', 'nama_material': 'semen padang', 'harga_rab': 65000},
      {'kategori': 'Semen', 'nama_material': 'semen mortar', 'harga_rab': 75000},
      {'kategori': 'Semen', 'nama_material': 'semen instan', 'harga_rab': 75000},
      {'kategori': 'Pasir', 'nama_material': 'pasir pasang', 'harga_rab': 250000},
      {'kategori': 'Pasir', 'nama_material': 'pasir urug', 'harga_rab': 180000},
      {'kategori': 'Keramik Lantai', 'nama_material': 'keramik lantai standar', 'harga_rab': 90000},
      {'kategori': 'Keramik Lantai', 'nama_material': 'keramik lantai premium', 'harga_rab': 130000},
      {'kategori': 'Keramik Lantai', 'nama_material': 'granit lantai', 'harga_rab': 180000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok standar', 'harga_rab': 55000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok avian', 'harga_rab': 60000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok dulux', 'harga_rab': 75000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok nippon paint', 'harga_rab': 75000},
      {'kategori': 'Genteng / Atap', 'nama_material': 'genteng tanah liat', 'harga_rab': 3500},
      {'kategori': 'Genteng / Atap', 'nama_material': 'genteng beton', 'harga_rab': 7000},
      {'kategori': 'Genteng / Atap', 'nama_material': 'atap spandek', 'harga_rab': 85000},
      {'kategori': 'Plafon', 'nama_material': 'plafon gypsum', 'harga_rab': 75000},
      {'kategori': 'Plafon', 'nama_material': 'plafon pvc', 'harga_rab': 75000},
      {'kategori': 'Plafon', 'nama_material': 'plafon grc', 'harga_rab': 90000},
      {'kategori': 'Pipa', 'nama_material': 'pipa pvc', 'harga_rab': 18000},
      {'kategori': 'Pipa', 'nama_material': 'pipa air', 'harga_rab': 20000},
      {'kategori': 'Pipa', 'nama_material': 'pipa conduit', 'harga_rab': 15000},
    ];
  }
  String _getUserName(User user) {
    final Map<String, dynamic>? metadata = user.userMetadata;

    final dynamic name = metadata?['name'] ??
        metadata?['full_name'] ??
        metadata?['username'] ??
        metadata?['display_name'];

    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }

    if (user.email != null && user.email!.trim().isNotEmpty) {
      return user.email!.trim();
    }

    return 'User';
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
      await ActivityLogService.addLog(
  title: "Edit Denah",
  description:
      "Denah ${landWidth.toStringAsFixed(1)} x ${landLength.toStringAsFixed(1)} berhasil diedit",
  icon: "edit",
);
      isSaved.value = false;
      await simpanDenah();
    }
  }

  void lihatRAB() {
    final Map<String, dynamic> rabArgs = _buildRabArguments();

    if (Get.isRegistered<RabController>()) {
      Get.delete<RabController>(force: true);
    }

    Get.to(
      () => RabPage(
        rooms: currentRooms.map((room) => room.copyWith()).toList(),
      ),
      arguments: rabArgs,
      binding: BindingsBuilder(() {
        Get.put(RabController());
      }),
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

    if (Get.isRegistered<RabController>()) {
      Get.delete<RabController>();
    }

    super.onClose();
  }
}


