from pathlib import Path
import re

files = [
    Path(r"lib\app\modules\riwayat\controllers\riwayat_controller.dart"),
    Path(r"lib\app\modules\riwayat\views\riwayat_page.dart"),
    Path(r"lib\app\services\floor_plan_pdf_exporter.dart"),
    Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart"),
]

for path in files:
    if path.exists():
        backup = path.with_suffix(path.suffix + ".before-drop-old-material-columns.bak")
        backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

# ============================================================
# 1) HasilDenahController: jangan insert material / selected_materials
# ============================================================

path = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart")
if path.exists():
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

    text = text.replace("        'material': material,\n", "")
    text = text.replace("        'selected_materials': _effectiveSelectedMaterials(),\n", "")
    text = text.replace("        'selected_materials': selected,\n", "")

    path.write_text(text, encoding="utf-8")

# ============================================================
# 2) RiwayatController: select dan baca material_dinding saja
# ============================================================

path = Path(r"lib\app\modules\riwayat\controllers\riwayat_controller.dart")
if path.exists():
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

    # Paksa select tidak ambil material lama / selected_materials
    text = re.sub(
        r"\.select\(\s*'[^']*'\s*,?\s*\)",
        """.select(
            'id, title, panjang_lahan, lebar_lahan, jumlah_kamar, material_dinding, material_semen, material_pasir, material_keramik_lantai, material_cat_dinding, material_genteng_atap, material_plafon, material_pipa, ruang_tambahan, total_luas, estimasi_rab, rooms_json, created_at, updated_at',
          )""",
        text,
        flags=re.S,
    )

    text = text.replace(
        "(item['material'] ?? '-').toString()",
        "(item['material_dinding'] ?? '-').toString()"
    )

    text = text.replace(
        "(item['material'] ?? '').toString()",
        "(item['material_dinding'] ?? '').toString()"
    )

    text = text.replace(
        "(item['material'] ?? 'Batu Bata').toString()",
        "(item['material_dinding'] ?? 'Batu Bata').toString()"
    )

    # Ganti helper selectedMaterials agar pakai kolom per kategori
    helper = r'''  Map<String, String> _selectedMaterialsFromItem(Map<String, dynamic> item) {
    final Map<String, String> result = <String, String>{};

    void add(String kategori, dynamic value) {
      final String materialName = (value ?? '').toString().trim();

      if (materialName.isNotEmpty) {
        result[kategori] = materialName;
      }
    }

    add('Material Dinding', item['material_dinding']);
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
            flags=re.S,
        )
    elif "  Future<void> openEdit" in text:
        text = text.replace("  Future<void> openEdit", helper + "  Future<void> openEdit")

    path.write_text(text, encoding="utf-8")

# ============================================================
# 3) RiwayatPage: selectedMaterials dari kolom per kategori
# ============================================================

path = Path(r"lib\app\modules\riwayat\views\riwayat_page.dart")
if path.exists():
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

    text = text.replace(
        "(item['material'] ?? 'batu bata merah').toString()",
        "(item['material_dinding'] ?? 'batu bata merah').toString()"
    )

    text = text.replace(
        "item['material']",
        "item['material_dinding']"
    )

    helper = r'''  Map<String, String> _selectedMaterialsFromHistory(Map<String, dynamic> item) {
    final Map<String, String> result = <String, String>{};

    void add(String kategori, dynamic value) {
      final String materialName = (value ?? '').toString().trim();

      if (materialName.isNotEmpty) {
        result[kategori] = materialName;
      }
    }

    add('Material Dinding', item['material_dinding']);
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
            flags=re.S,
        )

    path.write_text(text, encoding="utf-8")

# ============================================================
# 4) PDF Exporter: material dari kolom per kategori
# ============================================================

path = Path(r"lib\app\services\floor_plan_pdf_exporter.dart")
if path.exists():
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

    text = text.replace(
        "_readText(item['material'], fallback: '-')",
        "_readText(item['material_dinding'], fallback: '-')"
    )

    text = text.replace(
        "_readText(item['material'],\n        fallback: 'batu bata merah',\n      )",
        "_readText(item['material_dinding'],\n        fallback: 'batu bata merah',\n      )"
    )

    helper = r'''  static Map<String, String> _selectedMaterials(Map<String, dynamic> item) {
    final Map<String, String> result = <String, String>{};

    void add(String kategori, dynamic value) {
      final String materialName = (value ?? '').toString().trim();

      if (materialName.isNotEmpty) {
        result[kategori] = materialName;
      }
    }

    add('Material Dinding', item['material_dinding']);
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
            flags=re.S,
        )

    path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: kode tidak bergantung lagi ke kolom material dan selected_materials.")
