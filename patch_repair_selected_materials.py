from pathlib import Path

hasil_path = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart")
riwayat_controller_path = Path(r"lib\app\modules\riwayat\controllers\riwayat_controller.dart")
riwayat_page_path = Path(r"lib\app\modules\riwayat\views\riwayat_page.dart")

for path in [hasil_path, riwayat_controller_path, riwayat_page_path]:
    if not path.exists():
        raise SystemExit(f"ERROR: File tidak ditemukan: {path}")
    backup = path.with_suffix(path.suffix + ".before-repair-selected-materials.bak")
    backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

# ============================================================
# 1) REPAIR HasilDenahController
# ============================================================

text = hasil_path.read_text(encoding="utf-8").replace("\r\n", "\n")

hasil_helpers = r'''  Map<String, String> _selectedMaterialsFromArguments() {
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

if "Map<String, String> _effectiveSelectedMaterials()" not in text:
    marker = "  Future<void> simpanDenah() async {"
    if marker not in text:
        raise SystemExit("ERROR: Marker simpanDenah tidak ditemukan di HasilDenahController.")
    text = text.replace(marker, hasil_helpers + marker)

hasil_path.write_text(text, encoding="utf-8")

# ============================================================
# 2) REPAIR RiwayatController
# ============================================================

text = riwayat_controller_path.read_text(encoding="utf-8").replace("\r\n", "\n")

riwayat_controller_helper = r'''  Map<String, String> _selectedMaterialsFromItem(Map<String, dynamic> item) {
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

    final String materialDinding =
        (item['material'] ?? 'batu bata merah').toString();

    return <String, String>{
      'Material Dinding': materialDinding,
    };
  }

'''

if "Map<String, String> _selectedMaterialsFromItem(" not in text:
    marker = "  Future<void> openEdit"
    if marker not in text:
        raise SystemExit("ERROR: Marker openEdit tidak ditemukan di RiwayatController.")
    text = text.replace(marker, riwayat_controller_helper + marker)

riwayat_controller_path.write_text(text, encoding="utf-8")

# ============================================================
# 3) REPAIR RiwayatPage
# ============================================================

text = riwayat_page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

riwayat_page_helper = r'''  Map<String, String> _selectedMaterialsFromHistory(Map<String, dynamic> item) {
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

    final String materialDinding =
        (item['material'] ?? 'batu bata merah').toString();

    return <String, String>{
      'Material Dinding': materialDinding,
    };
  }

'''

if "Map<String, String> _selectedMaterialsFromHistory(" not in text:
    marker = "  double _readRabArea"
    if marker not in text:
        raise SystemExit("ERROR: Marker _readRabArea tidak ditemukan di RiwayatPage.")
    text = text.replace(marker, riwayat_page_helper + marker)

riwayat_page_path.write_text(text, encoding="utf-8")

print("REPAIR BERHASIL: method selectedMaterials yang hilang sudah ditambahkan.")
