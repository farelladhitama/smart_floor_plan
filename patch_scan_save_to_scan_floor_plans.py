from pathlib import Path
import re

# ============================================================
# 1) PATCH SCAN CONTROLLER: kirim nama file gambar scan
# ============================================================

scan_controller = Path(r"lib\app\modules\scan_denah\controllers\scan_denah_controller.dart")

if not scan_controller.exists():
    raise SystemExit("ERROR: scan_denah_controller.dart tidak ditemukan.")

scan_text = scan_controller.read_text(encoding="utf-8").replace("\r\n", "\n")

scan_backup = scan_controller.with_suffix(scan_controller.suffix + ".before-scan-save-db.bak")
scan_backup.write_text(scan_text, encoding="utf-8")

if "'scanImageName': selectedImageName.value," not in scan_text:
    scan_text = scan_text.replace(
"""        'scanMode': true,
""",
"""        'scanMode': true,
        'scanImageName': selectedImageName.value,
""",
        1
    )

scan_controller.write_text(scan_text, encoding="utf-8")


# ============================================================
# 2) PATCH HASIL DENAH CONTROLLER: kalau scanMode simpan ke scan_floor_plans
# ============================================================

hasil_controller = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart")

if not hasil_controller.exists():
    raise SystemExit("ERROR: hasil_denah_controller.dart tidak ditemukan.")

text = hasil_controller.read_text(encoding="utf-8").replace("\r\n", "\n")

backup = hasil_controller.with_suffix(hasil_controller.suffix + ".before-scan-floor-plans-save.bak")
backup.write_text(text, encoding="utf-8")

if "package:supabase_flutter/supabase_flutter.dart" not in text:
    text = text.replace(
        "import 'package:get/get.dart';",
        "import 'package:get/get.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';"
    )

helper = r'''
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

      double total = 0;

      for (final Map<String, dynamic> row in rows) {
        final String kategori = (row['kategori'] ?? '').toString();
        final String namaMaterial = (row['nama_material'] ?? '').toString();

        if (kategori.isEmpty || namaMaterial.isEmpty) continue;

        final String? selectedName = selectedMaterials[kategori];

        if (selectedName == null) continue;

        if (selectedName.toLowerCase().trim() !=
            namaMaterial.toLowerCase().trim()) {
          continue;
        }

        final double hargaRab = _scanToDouble(row['harga_rab']);
        final double hargaRataRata = _scanToDouble(row['harga_rata_rata']);
        final double harga = hargaRab > 0 ? hargaRab : hargaRataRata;

        if (harga > 0) {
          total += harga * luasBangunan;
        }
      }

      if (total <= 0) {
        return luasBangunan * 3500000;
      }

      return total;
    } catch (_) {
      return luasBangunan * 3500000;
    }
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
                'name': room.name,
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
      };

      if (floorPlanId != null && floorPlanId!.isNotEmpty && isSaved.value) {
        await supabase
            .from('scan_floor_plans')
            .update(payload)
            .eq('id', floorPlanId!);

        Get.snackbar(
          'Berhasil',
          'Hasil scan berhasil diperbarui.',
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
          'Hasil scan berhasil disimpan ke riwayat scan.',
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

'''

if "_simpanScanDenah()" not in text:
    marker = "  Future<void> simpanDenah() async {"

    if marker not in text:
        raise SystemExit("ERROR: method simpanDenah tidak ditemukan.")

    text = text.replace(marker, helper + "\n" + marker, 1)

if "await _simpanScanDenah();" not in text:
    text = text.replace(
"""  Future<void> simpanDenah() async {
""",
"""  Future<void> simpanDenah() async {
    if (_isScanModeFromArguments()) {
      await _simpanScanDenah();
      return;
    }

""",
        1
    )

hasil_controller.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: scanMode sekarang simpan ke scan_floor_plans.")
