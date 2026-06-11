from pathlib import Path
import re

# ============================================================
# 1) PATCH ScanDenahController - tambah material pilihan scan
# ============================================================

controller_path = Path(r"lib\app\modules\scan_denah\controllers\scan_denah_controller.dart")

if not controller_path.exists():
    raise SystemExit("ERROR: scan_denah_controller.dart tidak ditemukan.")

backup = controller_path.with_suffix(controller_path.suffix + ".before-scan-material.bak")
backup.write_text(controller_path.read_text(encoding="utf-8"), encoding="utf-8")

text = controller_path.read_text(encoding="utf-8").replace("\r\n", "\n")

# Tambah import supabase
if "package:supabase_flutter/supabase_flutter.dart" not in text:
    text = text.replace(
        "import 'package:image_picker/image_picker.dart';",
        "import 'package:image_picker/image_picker.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';"
    )

# Tambah field material setelah baseUrl
if "final List<String> materialCategories" not in text:
    text = text.replace(
"""  final String baseUrl = 'http://127.0.0.1:5000';
""",
"""  final String baseUrl = 'http://127.0.0.1:5000';

  final List<String> materialCategories = const [
    'Material Dinding',
    'Semen',
    'Pasir',
    'Keramik Lantai',
    'Cat Dinding',
    'Genteng / Atap',
    'Plafon',
    'Pipa',
  ];

  final materialOptionsByCategory = <String, List<String>>{}.obs;
  final selectedMaterials = <String, String>{}.obs;
  final isLoadingMaterials = false.obs;

  SupabaseClient get _supabase => Supabase.instance.client;
"""
    )

# Tambah onInit dan fungsi material sebelum pickImage
if "Future<void> loadMaterialOptions()" not in text:
    marker = "  Future<void> pickImage() async {"

    helper = r'''
  @override
  void onInit() {
    super.onInit();
    loadMaterialOptions();
  }

  Future<void> loadMaterialOptions() async {
    try {
      isLoadingMaterials.value = true;

      final response = await _supabase
          .from('rab_material_options')
          .select('kategori, nama_material, is_active')
          .eq('is_active', true)
          .order('kategori', ascending: true)
          .order('nama_material', ascending: true);

      final List<Map<String, dynamic>> rows = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final Map<String, List<String>> grouped = <String, List<String>>{};

      for (final Map<String, dynamic> row in rows) {
        final String kategori = (row['kategori'] ?? '').toString();
        final String namaMaterial = (row['nama_material'] ?? '').toString();

        if (kategori.isEmpty || namaMaterial.isEmpty) continue;
        if (!materialCategories.contains(kategori)) continue;

        grouped.putIfAbsent(kategori, () => <String>[]);

        if (!grouped[kategori]!.contains(namaMaterial)) {
          grouped[kategori]!.add(namaMaterial);
        }
      }

      if (grouped.isEmpty) {
        _setFallbackMaterialOptions();
      } else {
        final Map<String, List<String>> sorted = <String, List<String>>{};

        for (final String category in materialCategories) {
          final List<String>? options = grouped[category];

          if (options != null && options.isNotEmpty) {
            sorted[category] = options;
          }
        }

        materialOptionsByCategory.assignAll(sorted);
        _ensureDefaultSelectedMaterials();
      }
    } catch (_) {
      _setFallbackMaterialOptions();
    } finally {
      isLoadingMaterials.value = false;
    }
  }

  void _setFallbackMaterialOptions() {
    materialOptionsByCategory.assignAll({
      'Material Dinding': [
        'batu bata merah',
        'batako',
        'bata ringan / hebel',
      ],
      'Semen': [
        'semen tiga roda',
        'semen gresik',
        'semen padang',
        'semen mortar',
        'semen instan',
      ],
      'Pasir': [
        'pasir pasang',
        'pasir urug',
      ],
      'Keramik Lantai': [
        'keramik lantai standar',
        'keramik lantai premium',
        'granit lantai',
      ],
      'Cat Dinding': [
        'cat tembok standar',
        'cat tembok avian',
        'cat tembok dulux',
        'cat tembok nippon paint',
      ],
      'Genteng / Atap': [
        'genteng tanah liat',
        'genteng beton',
        'atap spandek',
      ],
      'Plafon': [
        'plafon gypsum',
        'plafon pvc',
        'plafon grc',
      ],
      'Pipa': [
        'pipa pvc',
        'pipa air',
        'pipa conduit',
      ],
    });

    _ensureDefaultSelectedMaterials();
  }

  void _ensureDefaultSelectedMaterials() {
    for (final String kategori in materialCategories) {
      final List<String> options =
          materialOptionsByCategory[kategori] ?? <String>[];

      if (options.isEmpty) continue;

      if (!selectedMaterials.containsKey(kategori) ||
          !options.contains(selectedMaterials[kategori])) {
        selectedMaterials[kategori] = options.first;
      }
    }
  }

  void changeMaterialForCategory(String kategori, String value) {
    selectedMaterials[kategori] = value;
  }

  Map<String, String> _effectiveSelectedMaterials() {
    if (selectedMaterials.isEmpty) {
      _setFallbackMaterialOptions();
    }

    return Map<String, String>.from(selectedMaterials);
  }

'''
    if marker in text:
        text = text.replace(marker, helper + marker)
    else:
        raise SystemExit("ERROR: marker pickImage tidak ditemukan.")

# Patch openResult supaya tidak pakai material default terus
text = text.replace(
"""    final double landArea = landWidth * landLength;
""",
"""    final double landArea = landWidth * landLength;
    final Map<String, String> selectedScanMaterials =
        _effectiveSelectedMaterials();
    final String materialDinding =
        selectedScanMaterials['Material Dinding'] ?? 'batu bata merah';
"""
)

text = text.replace(
"""        material: 'batu bata merah',
""",
"""        material: materialDinding,
"""
)

text = text.replace(
"""        'material': 'batu bata merah',
        'selectedMaterials': _defaultSelectedMaterials(),
""",
"""        'material': materialDinding,
        'selectedMaterials': selectedScanMaterials,
"""
)

controller_path.write_text(text, encoding="utf-8")


# ============================================================
# 2) PATCH ScanDenahPage - tambah UI pilihan material
# ============================================================

page_path = Path(r"lib\app\modules\scan_denah\views\scan_denah_page.dart")

if not page_path.exists():
    raise SystemExit("ERROR: scan_denah_page.dart tidak ditemukan.")

backup = page_path.with_suffix(page_path.suffix + ".before-scan-material.bak")
backup.write_text(page_path.read_text(encoding="utf-8"), encoding="utf-8")

text = page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

# Tambah section material setelah result card
if "_buildMaterialSection(isMobile)" not in text:
    text = text.replace(
"""                    _buildResultCard(isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildButtons(isMobile),
""",
"""                    _buildResultCard(isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildMaterialSection(isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildButtons(isMobile),
"""
    )

# Tambah widget material section sebelum _buildButtons
if "Widget _buildMaterialSection" not in text:
    marker = "  Widget _buildButtons(bool isMobile) {"

    widget = r'''
  Widget _buildMaterialSection(bool isMobile) {
    return Obx(() {
      if (controller.isLoadingMaterials.value &&
          controller.materialOptionsByCategory.isEmpty) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: orange,
                  strokeWidth: 2.4,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Memuat pilihan material...',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isMobile ? 38 : 42,
                  height: isMobile ? 38 : 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E8),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.layers_rounded,
                    color: orange,
                    size: isMobile ? 21 : 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pilihan Material Scan',
                    style: TextStyle(
                      color: navy,
                      fontSize: isMobile ? 18 : 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih material untuk hasil scan agar RAB mengikuti pilihan bahan bangunan.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: isMobile ? 12.5 : 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            ...controller.materialCategories.map((category) {
              final List<String> options =
                  controller.materialOptionsByCategory[category] ?? <String>[];

              if (options.isEmpty) {
                return const SizedBox.shrink();
              }

              final String? selected = controller.selectedMaterials[category];

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selected != null && options.contains(selected)
                        ? selected
                        : options.first,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: navy,
                    ),
                    items: options.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.layers_rounded,
                                color: navy,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: navy,
                                      fontSize: isMobile ? 13 : 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      controller.changeMaterialForCategory(category, value);
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

'''
    if marker in text:
        text = text.replace(marker, widget + marker)
    else:
        raise SystemExit("ERROR: marker _buildButtons tidak ditemukan.")

page_path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: halaman Scan Denah sekarang punya pilihan material.")
