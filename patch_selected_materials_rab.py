from pathlib import Path
import re

hasil_path = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart")
riwayat_controller_path = Path(r"lib\app\modules\riwayat\controllers\riwayat_controller.dart")
riwayat_page_path = Path(r"lib\app\modules\riwayat\views\riwayat_page.dart")

for path in [hasil_path, riwayat_controller_path, riwayat_page_path]:
    if not path.exists():
        raise SystemExit(f"ERROR: File tidak ditemukan: {path}")
    backup = path.with_suffix(path.suffix + ".before-selected-materials.bak")
    backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

# ============================================================
# 1) PATCH HasilDenahController
# ============================================================

text = hasil_path.read_text(encoding="utf-8").replace("\r\n", "\n")

if "Map<String, String> selectedMaterials" not in text:
    text = text.replace(
        "  String material = 'Batu Bata';\n",
        "  String material = 'Batu Bata';\n  Map<String, String> selectedMaterials = <String, String>{};\n"
    )

if "selectedMaterials = _effectiveSelectedMaterials();" not in text:
    text = text.replace(
        "    material = inputMaterial;\n    ruangTambahan = inputRuangTambahan;\n",
        "    material = inputMaterial;\n    ruangTambahan = inputRuangTambahan;\n    selectedMaterials = _effectiveSelectedMaterials();\n"
    )

if "'selected_materials':" not in text:
    text = text.replace(
        "        'material': material,\n",
        "        'material': material,\n        'selected_materials': _effectiveSelectedMaterials(),\n"
    )

helpers = r'''  Map<String, String> _selectedMaterialsFromArguments() {
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
      'inputLuas': luas,
      'inputLebarRumah': landWidth,
      'inputPanjangRumah': landLength,
      'lebar_lahan': landWidth,
      'panjang_lahan': landLength,
      'material': selected['Material Dinding'] ?? material,
      'selectedMaterials': selected,
    };
  }

'''

if "_effectiveSelectedMaterials()" not in text.split("Future<void> simpanDenah")[0]:
    text = text.replace("  Future<void> simpanDenah() async {", helpers + "  Future<void> simpanDenah() async {")

new_lihat_rab = r'''  void lihatRAB() {
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

  void _showSnackBar'''

text, count = re.subn(
    r"  void lihatRAB\(\) \{.*?\n  \}\n\n  void _showSnackBar",
    new_lihat_rab,
    text,
    flags=re.S,
)

if count == 0:
    raise SystemExit("ERROR: Gagal patch lihatRAB di HasilDenahController.")

hasil_path.write_text(text, encoding="utf-8")

# ============================================================
# 2) PATCH RiwayatController
# ============================================================

text = riwayat_controller_path.read_text(encoding="utf-8").replace("\r\n", "\n")

if "selected_materials" not in text:
    text = text.replace(
        "id, title, panjang_lahan, lebar_lahan, jumlah_kamar, material, ruang_tambahan, total_luas, estimasi_rab, rooms_json, created_at, updated_at",
        "id, title, panjang_lahan, lebar_lahan, jumlah_kamar, material, selected_materials, ruang_tambahan, total_luas, estimasi_rab, rooms_json, created_at, updated_at"
    )

if "'selectedMaterials': _selectedMaterialsFromItem(item)," not in text:
    text = text.replace(
        "        'material': (item['material'] ?? '').toString(),\n        'rooms': item['rooms_json'],\n",
        "        'material': (item['material'] ?? '').toString(),\n        'selectedMaterials': _selectedMaterialsFromItem(item),\n        'rooms': item['rooms_json'],\n"
    )

helper = r'''  Map<String, String> _selectedMaterialsFromItem(Map<String, dynamic> item) {
    final dynamic selected = item['selected_materials'];

    if (selected is Map) {
      final Map<String, String> result = <String, String>{};

      selected.forEach((key, value) {
        final String kategori = key.toString().trim();
        final String materialName = value.toString().trim();

        if (kategori.isNotEmpty && materialName.isNotEmpty) {
          result[kategori] = materialName;
        }
      });

      if (result.isNotEmpty) {
        return result;
      }
    }

    final String materialDinding = (item['material'] ?? 'batu bata merah').toString();

    return <String, String>{
      'Material Dinding': materialDinding,
    };
  }

'''

if "_selectedMaterialsFromItem" not in text:
    text = text.replace("  Future<void> openEdit", helper + "  Future<void> openEdit")

riwayat_controller_path.write_text(text, encoding="utf-8")

# ============================================================
# 3) PATCH RiwayatPage direct LIHAT RAB
# ============================================================

text = riwayat_page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

if "app/modules/rab/controllers/rab_controller.dart" not in text:
    text = text.replace(
        "import 'package:get/get.dart';",
        "import 'package:get/get.dart';\nimport 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';\nimport 'package:smart_floor_plan/app/modules/rab/views/rab_page.dart';"
    )

new_open_rab = r'''  void _openRabDirect(Map<String, dynamic> item) {
    final double luas = _readRabArea(item);
    final double lebar = _readNumberRab(item['lebar_lahan']);
    final double panjang = _readNumberRab(item['panjang_lahan']);
    final Map<String, String> selectedMaterials = _selectedMaterialsFromHistory(item);
    final String material = selectedMaterials['Material Dinding'] ??
        (item['material'] ?? 'batu bata merah').toString();

    final Map<String, dynamic> rabArgs = {
      'luasBangunan': luas,
      'totalLuas': luas,
      'total_luas': luas,
      'inputLuas': luas,
      'inputLebarRumah': lebar,
      'inputPanjangRumah': panjang,
      'lebar_lahan': lebar,
      'panjang_lahan': panjang,
      'material': material,
      'selectedMaterials': selectedMaterials,
      'rooms_json': item['rooms_json'],
    };

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    if (Get.isRegistered<RabController>()) {
      Get.delete<RabController>(force: true);
    }

    Get.to(
      () => const RabPage(),
      arguments: rabArgs,
      binding: BindingsBuilder(() {
        Get.put(RabController());
      }),
    );
  }

  double _readRabArea'''

text, count = re.subn(
    r"  void _openRabDirect\(Map<String, dynamic> item\) \{.*?\n  \}\n\n  double _readRabArea",
    new_open_rab,
    text,
    flags=re.S,
)

if count == 0:
    raise SystemExit("ERROR: Gagal patch _openRabDirect di RiwayatPage.")

helper_page = r'''  Map<String, String> _selectedMaterialsFromHistory(Map<String, dynamic> item) {
    final dynamic selected = item['selected_materials'];

    if (selected is Map) {
      final Map<String, String> result = <String, String>{};

      selected.forEach((key, value) {
        final String kategori = key.toString().trim();
        final String materialName = value.toString().trim();

        if (kategori.isNotEmpty && materialName.isNotEmpty) {
          result[kategori] = materialName;
        }
      });

      if (result.isNotEmpty) {
        return result;
      }
    }

    final String materialDinding = (item['material'] ?? 'batu bata merah').toString();

    return <String, String>{
      'Material Dinding': materialDinding,
    };
  }

'''

if "_selectedMaterialsFromHistory" not in text:
    text = text.replace("  double _readRabArea", helper_page + "  double _readRabArea")

riwayat_page_path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: selectedMaterials lengkap sekarang disimpan dan dipakai lagi dari Riwayat.")
