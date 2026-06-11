from pathlib import Path
import re

hasil_path = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart")
riwayat_controller_path = Path(r"lib\app\modules\riwayat\controllers\riwayat_controller.dart")
riwayat_page_path = Path(r"lib\app\modules\riwayat\views\riwayat_page.dart")
pdf_path = Path(r"lib\app\services\floor_plan_pdf_exporter.dart")

paths = [hasil_path, riwayat_controller_path, riwayat_page_path, pdf_path]

for path in paths:
    if path.exists():
        backup = path.with_suffix(path.suffix + ".before-material-columns.bak")
        backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

# ============================================================
# 1) PATCH HasilDenahController
# ============================================================

if hasil_path.exists():
    text = hasil_path.read_text(encoding="utf-8").replace("\r\n", "\n")

    # Pastikan helper effective selectedMaterials ada
    if "Map<String, String> _effectiveSelectedMaterials()" not in text:
        helper = r'''  Map<String, String> _selectedMaterialsFromArguments() {
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

'''
        marker = "  Future<void> simpanDenah() async {"
        if marker in text:
            text = text.replace(marker, helper + marker)

    # Pastikan field selectedMaterials ada
    if "Map<String, String> selectedMaterials" not in text:
        text = text.replace(
            "  String material = 'Batu Bata';\n",
            "  String material = 'Batu Bata';\n  Map<String, String> selectedMaterials = <String, String>{};\n"
        )

    # Tambahkan selected sebelum payload
    if "final Map<String, String> selected = _effectiveSelectedMaterials();" not in text:
        text = text.replace(
            "      final List<Map<String, dynamic>> roomsJson =\n          currentRooms.map((room) => _roomToJson(room)).toList();",
            "      final List<Map<String, dynamic>> roomsJson =\n          currentRooms.map((room) => _roomToJson(room)).toList();\n\n      final Map<String, String> selected = _effectiveSelectedMaterials();"
        )

    # Hapus payload kolom lama material/selected_materials, ganti kolom baru
    text = text.replace("        'material': material,\n", "")
    text = text.replace("        'selected_materials': _effectiveSelectedMaterials(),\n", "")

    if "'material_dinding':" not in text:
        text = text.replace(
            "        'jumlah_kamar': jumlahKamar,\n",
            """        'jumlah_kamar': jumlahKamar,
        'material_dinding': selected['Material Dinding'] ?? material,
        'material_semen': selected['Semen'],
        'material_pasir': selected['Pasir'],
        'material_keramik_lantai': selected['Keramik Lantai'],
        'material_cat_dinding': selected['Cat Dinding'],
        'material_genteng_atap': selected['Genteng / Atap'],
        'material_plafon': selected['Plafon'],
        'material_pipa': selected['Pipa'],
"""
        )

    hasil_path.write_text(text, encoding="utf-8")

# ============================================================
# 2) PATCH RiwayatController
# ============================================================

if riwayat_controller_path.exists():
    text = riwayat_controller_path.read_text(encoding="utf-8").replace("\r\n", "\n")

    # Select kolom baru
    text = re.sub(
        r"'id, title, panjang_lahan, lebar_lahan, jumlah_kamar,.*?created_at, updated_at'",
        "'id, title, panjang_lahan, lebar_lahan, jumlah_kamar, material_dinding, material_semen, material_pasir, material_keramik_lantai, material_cat_dinding, material_genteng_atap, material_plafon, material_pipa, ruang_tambahan, total_luas, estimasi_rab, rooms_json, created_at, updated_at'",
        text,
        flags=re.S
    )

    # Subtitle pakai material_dinding
    text = text.replace(
        "final String material = (item['material'] ?? '-').toString();",
        "final String material = (item['material_dinding'] ?? item['material'] ?? '-').toString();"
    )

    # openRab material
    text = text.replace(
        "'material': (item['material'] ?? '').toString(),",
        "'material': (item['material_dinding'] ?? item['material'] ?? '').toString(),"
    )

    # openEdit material
    text = text.replace(
        "material: (item['material'] ?? 'Batu Bata').toString(),",
        "material: (item['material_dinding'] ?? item['material'] ?? 'Batu Bata').toString(),"
    )

    # Tambahkan helper selected materials per kolom kalau ada / ganti yang lama
    helper = r'''  Map<String, String> _selectedMaterialsFromItem(Map<String, dynamic> item) {
    final Map<String, String> result = <String, String>{};

    void add(String kategori, dynamic value) {
      final String materialName = (value ?? '').toString().trim();

      if (materialName.isNotEmpty) {
        result[kategori] = materialName;
      }
    }

    add('Material Dinding', item['material_dinding'] ?? item['material']);
    add('Semen', item['material_semen']);
    add('Pasir', item['material_pasir']);
    add('Keramik Lantai', item['material_keramik_lantai']);
    add('Cat Dinding', item['material_cat_dinding']);
    add('Genteng / Atap', item['material_genteng_atap']);
    add('Plafon', item['material_plafon']);
    add('Pipa', item['material_pipa']);

    return result;
  }

'''
    if "Map<String, String> _selectedMaterialsFromItem(" in text:
        text = re.sub(
            r"  Map<String, String> _selectedMaterialsFromItem\(Map<String, dynamic> item\) \{.*?\n  \}\n\n",
            helper,
            text,
            flags=re.S
        )
    elif "  Future<void> openEdit" in text:
        text = text.replace("  Future<void> openEdit", helper + "  Future<void> openEdit")

    # Pastikan arguments selectedMaterials untuk openRab
    if "'selectedMaterials': _selectedMaterialsFromItem(item)," not in text:
        text = text.replace(
            "'material': (item['material_dinding'] ?? item['material'] ?? '').toString(),\n",
            "'material': (item['material_dinding'] ?? item['material'] ?? '').toString(),\n        'selectedMaterials': _selectedMaterialsFromItem(item),\n"
        )

    riwayat_controller_path.write_text(text, encoding="utf-8")

# ============================================================
# 3) PATCH RiwayatPage
# ============================================================

if riwayat_page_path.exists():
    text = riwayat_page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

    helper = r'''  Map<String, String> _selectedMaterialsFromHistory(Map<String, dynamic> item) {
    final Map<String, String> result = <String, String>{};

    void add(String kategori, dynamic value) {
      final String materialName = (value ?? '').toString().trim();

      if (materialName.isNotEmpty) {
        result[kategori] = materialName;
      }
    }

    add('Material Dinding', item['material_dinding'] ?? item['material']);
    add('Semen', item['material_semen']);
    add('Pasir', item['material_pasir']);
    add('Keramik Lantai', item['material_keramik_lantai']);
    add('Cat Dinding', item['material_cat_dinding']);
    add('Genteng / Atap', item['material_genteng_atap']);
    add('Plafon', item['material_plafon']);
    add('Pipa', item['material_pipa']);

    if (!result.containsKey('Material Dinding')) {
      result['Material Dinding'] = 'batu bata merah';
    }

    return result;
  }

'''
    if "Map<String, String> _selectedMaterialsFromHistory(" in text:
        text = re.sub(
            r"  Map<String, String> _selectedMaterialsFromHistory\(Map<String, dynamic> item\) \{.*?\n  \}\n\n",
            helper,
            text,
            flags=re.S
        )
    elif "  double _readRabArea" in text:
        text = text.replace("  double _readRabArea", helper + "  double _readRabArea")

    text = text.replace(
        "final String material = selectedMaterials['Material Dinding'] ??\n        (item['material'] ?? 'batu bata merah').toString();",
        "final String material = selectedMaterials['Material Dinding'] ??\n        (item['material_dinding'] ?? item['material'] ?? 'batu bata merah').toString();"
    )

    riwayat_page_path.write_text(text, encoding="utf-8")

# ============================================================
# 4) PATCH PDF Exporter
# ============================================================

if pdf_path.exists():
    text = pdf_path.read_text(encoding="utf-8").replace("\r\n", "\n")

    text = text.replace(
        "final String material = _readText(item['material'], fallback: '-');",
        "final String material = _readText(item['material_dinding'] ?? item['material'], fallback: '-');"
    )

    helper = r'''  static Map<String, String> _selectedMaterials(Map<String, dynamic> item) {
    final Map<String, String> result = <String, String>{};

    void add(String kategori, dynamic value) {
      final String materialName = (value ?? '').toString().trim();

      if (materialName.isNotEmpty) {
        result[kategori] = materialName;
      }
    }

    add('Material Dinding', item['material_dinding'] ?? item['material']);
    add('Semen', item['material_semen']);
    add('Pasir', item['material_pasir']);
    add('Keramik Lantai', item['material_keramik_lantai']);
    add('Cat Dinding', item['material_cat_dinding']);
    add('Genteng / Atap', item['material_genteng_atap']);
    add('Plafon', item['material_plafon']);
    add('Pipa', item['material_pipa']);

    if (!result.containsKey('Material Dinding')) {
      result['Material Dinding'] = 'batu bata merah';
    }

    return result;
  }

'''
    if "static Map<String, String> _selectedMaterials(" in text:
        text = re.sub(
            r"  static Map<String, String> _selectedMaterials\(Map<String, dynamic> item\) \{.*?\n  \}\n\n",
            helper,
            text,
            flags=re.S
        )

    pdf_path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: Aplikasi sekarang pakai kolom material per kategori.")
