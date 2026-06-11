from pathlib import Path
import re

# ============================================================
# 1) PATCH GenerateFormController
# ============================================================

controller_path = Path(r"lib\app\modules\generate_form\controllers\generate_form_controller.dart")

if not controller_path.exists():
    raise SystemExit("ERROR: generate_form_controller.dart tidak ditemukan.")

backup = controller_path.with_suffix(controller_path.suffix + ".before-extra-rooms.bak")
backup.write_text(controller_path.read_text(encoding="utf-8"), encoding="utf-8")

text = controller_path.read_text(encoding="utf-8").replace("\r\n", "\n")

# Tambah controller input tambahan ruangan
if "tambahanRuanganController" not in text:
    text = text.replace(
"""  final TextEditingController lebarController = TextEditingController();
  final TextEditingController panjangController = TextEditingController();
""",
"""  final TextEditingController lebarController = TextEditingController();
  final TextEditingController panjangController = TextEditingController();
  final TextEditingController tambahanRuanganController = TextEditingController();
"""
    )

# Tambah listener
if "tambahanRuanganController.addListener" not in text:
    text = text.replace(
"""    lebarController.addListener(_clearRecommendationOnInputChange);
    panjangController.addListener(_clearRecommendationOnInputChange);
""",
"""    lebarController.addListener(_clearRecommendationOnInputChange);
    panjangController.addListener(_clearRecommendationOnInputChange);
    tambahanRuanganController.addListener(_clearRecommendationOnInputChange);
"""
    )

# Patch analisisRekomendasiRuang agar tambahan ruangan ikut muncul di rekomendasi
old_rekom = """      final List<RoomRecommendation> result =
          SmartFloorPlanEngine.getRecommendations(
        landWidth: lebarRumah,
        landLength: panjangRumah,
        bedroomCount: bedroomCount,
      );

      rekomendasiRuang.assignAll(result);
"""

new_rekom = """      final List<RoomRecommendation> extraRooms = _buildExtraRoomRecommendations(
        landWidth: lebarRumah,
        landLength: panjangRumah,
      );

      final List<RoomRecommendation> result =
          SmartFloorPlanEngine.getRecommendations(
        landWidth: lebarRumah,
        landLength: panjangRumah,
        bedroomCount: bedroomCount,
      );

      for (final RoomRecommendation extra in extraRooms) {
        final bool alreadyExists = result.any(
          (room) => room.name.toLowerCase() == extra.name.toLowerCase(),
        );

        if (!alreadyExists) {
          result.add(extra);
        }
      }

      rekomendasiRuang.assignAll(result);
"""

if old_rekom in text:
    text = text.replace(old_rekom, new_rekom)
elif "_buildExtraRoomRecommendations" not in text:
    print("WARNING: blok analisis rekomendasi tidak ketemu, mungkin struktur kode berubah.")

# Patch prosesGenerate agar extraRooms tidak kosong lagi
old_generate = """    final SmartFloorPlanResult result = SmartFloorPlanEngine.generate(
      landWidth: lebarRumah,
      landLength: panjangRumah,
      bedroomCount: bedroomCount,
      extraRooms: const <RoomRecommendation>[],
    );
"""

new_generate = """    final List<RoomRecommendation> extraRooms = _buildExtraRoomRecommendations(
      landWidth: lebarRumah,
      landLength: panjangRumah,
    );

    final List<String> extraRoomNames = _extraRoomNames(extraRooms);

    final SmartFloorPlanResult result = SmartFloorPlanEngine.generate(
      landWidth: lebarRumah,
      landLength: panjangRumah,
      bedroomCount: bedroomCount,
      extraRooms: extraRooms,
    );
"""

if old_generate in text:
    text = text.replace(old_generate, new_generate)
else:
    text = text.replace(
"      extraRooms: const <RoomRecommendation>[],",
"      extraRooms: extraRooms,"
    )

# Kirim ruang tambahan ke HasilDenahPage
text = text.replace(
"        ruangTambahan: const [],",
"        ruangTambahan: extraRoomNames,"
)

# Kirim juga lewat arguments
if "'ruangTambahan': extraRoomNames," not in text:
    text = text.replace(
"        'selectedMaterials': Map<String, String>.from(selectedMaterials),",
"        'selectedMaterials': Map<String, String>.from(selectedMaterials),\n        'ruangTambahan': extraRoomNames,"
    )

# Tambah helper tambahan ruangan
helper = r'''
  List<RoomRecommendation> _buildExtraRoomRecommendations({
    required double landWidth,
    required double landLength,
  }) {
    final List<String> names = _parseTambahanRuanganInput();

    if (names.isEmpty) {
      return <RoomRecommendation>[];
    }

    final double area = landWidth * landLength;
    final List<RoomRecommendation> extras = <RoomRecommendation>[];

    for (final String name in names.take(6)) {
      final String lowerName = name.toLowerCase();

      String category = 'room';
      double width = area <= 60 ? 1.8 : area <= 140 ? 2.2 : 2.8;
      double height = area <= 60 ? 1.6 : area <= 140 ? 2.0 : 2.4;

      if (lowerName.contains('mushola') ||
          lowerName.contains('musola') ||
          lowerName.contains('sholat') ||
          lowerName.contains('ibadah')) {
        category = 'room';
        width = area <= 60 ? 1.8 : 2.4;
        height = area <= 60 ? 1.8 : 2.4;
      } else if (lowerName.contains('gudang') ||
          lowerName.contains('storage')) {
        category = 'service';
        width = area <= 60 ? 1.5 : 1.8;
        height = area <= 60 ? 1.5 : 1.8;
      } else if (lowerName.contains('kerja') ||
          lowerName.contains('office') ||
          lowerName.contains('belajar')) {
        category = 'room';
        width = area <= 60 ? 1.8 : area <= 140 ? 2.4 : 3.0;
        height = area <= 60 ? 1.7 : area <= 140 ? 2.2 : 2.6;
      } else if (lowerName.contains('tamu')) {
        category = 'living';
        width = area <= 60 ? 2.2 : area <= 140 ? 3.0 : 3.6;
        height = area <= 60 ? 2.0 : area <= 140 ? 2.6 : 3.0;
      } else if (lowerName.contains('keluarga')) {
        category = 'family';
        width = area <= 60 ? 2.4 : area <= 140 ? 3.2 : 4.0;
        height = area <= 60 ? 2.0 : area <= 140 ? 2.8 : 3.2;
      } else if (lowerName.contains('cuci') ||
          lowerName.contains('laundry')) {
        category = 'service';
        width = area <= 60 ? 1.5 : 1.8;
        height = area <= 60 ? 1.5 : 1.9;
      } else if (lowerName.contains('garasi') ||
          lowerName.contains('carport')) {
        category = 'outdoor';
        width = area <= 60 ? 2.4 : 3.0;
        height = area <= 60 ? 3.0 : 4.0;
      } else if (lowerName.contains('wc') ||
          lowerName.contains('mandi') ||
          lowerName.contains('toilet')) {
        category = 'bath';
        width = 1.6;
        height = 1.8;
      } else if (lowerName.contains('dapur')) {
        category = 'kitchen';
        width = area <= 60 ? 2.0 : 2.6;
        height = area <= 60 ? 1.8 : 2.4;
      }

      extras.add(
        RoomRecommendation(
          name: _formatRoomName(name),
          category: category,
          width: width,
          height: height,
          selected: true,
        ),
      );
    }

    return extras;
  }

  List<String> _parseTambahanRuanganInput() {
    final String rawInput = tambahanRuanganController.text.trim();

    if (rawInput.isEmpty) {
      return <String>[];
    }

    final List<String> result = <String>[];
    final Set<String> usedNames = <String>{};

    final List<String> parts = rawInput
        .split(RegExp(r'[,;\n]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    for (final String part in parts) {
      final String key = part.toLowerCase();

      if (usedNames.contains(key)) {
        continue;
      }

      usedNames.add(key);
      result.add(part);
    }

    return result;
  }

  String _formatRoomName(String value) {
    final String cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleaned.isEmpty) {
      return cleaned;
    }

    return cleaned
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  List<String> _extraRoomNames(List<RoomRecommendation> extraRooms) {
    return extraRooms.map((room) => room.name).toList();
  }

'''

if "List<RoomRecommendation> _buildExtraRoomRecommendations" not in text:
    marker = "  void updateRekomendasiRuang() {"
    if marker in text:
        text = text.replace(marker, helper + marker)
    else:
        raise SystemExit("ERROR: marker updateRekomendasiRuang tidak ditemukan.")

# Remove listener dan dispose controller tambahan
if "tambahanRuanganController.removeListener" not in text:
    text = text.replace(
"""    lebarController.removeListener(_clearRecommendationOnInputChange);
    panjangController.removeListener(_clearRecommendationOnInputChange);
""",
"""    lebarController.removeListener(_clearRecommendationOnInputChange);
    panjangController.removeListener(_clearRecommendationOnInputChange);
    tambahanRuanganController.removeListener(_clearRecommendationOnInputChange);
"""
    )

if "tambahanRuanganController.dispose();" not in text:
    text = text.replace(
"""    lebarController.dispose();
    panjangController.dispose();
""",
"""    lebarController.dispose();
    panjangController.dispose();
    tambahanRuanganController.dispose();
"""
    )

controller_path.write_text(text, encoding="utf-8")


# ============================================================
# 2) PATCH GenerateFormPage
# ============================================================

page_path = Path(r"lib\app\modules\generate_form\views\generate_form_page.dart")

if not page_path.exists():
    raise SystemExit("ERROR: generate_form_page.dart tidak ditemukan.")

backup = page_path.with_suffix(page_path.suffix + ".before-extra-rooms.bak")
backup.write_text(page_path.read_text(encoding="utf-8"), encoding="utf-8")

text = page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

# Tambah section Tambahan Ruangan sebelum Rekomendasi Ruangan
if "title: 'Tambahan Ruangan'" not in text:
    old = """                        _buildMaterialDropdown(),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Rekomendasi Ruangan',
"""
    new = """                        _buildMaterialDropdown(),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Tambahan Ruangan',
                          subtitle:
                              'Tulis kebutuhan ruang tambahan, pisahkan dengan koma. Contoh: mushola, gudang, ruang kerja.',
                        ),
                        const SizedBox(height: 14),
                        _buildTambahanRuanganField(),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Rekomendasi Ruangan',
"""
    if old in text:
        text = text.replace(old, new)
    else:
        print("WARNING: posisi insert Tambahan Ruangan tidak ketemu.")

# Tambah widget input tambahan ruangan
field_widget = r'''
  Widget _buildTambahanRuanganField() {
    return TextFormField(
      controller: controller.tambahanRuanganController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      minLines: 1,
      maxLines: 3,
      style: const TextStyle(
        color: navy,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        hintText: 'Contoh: mushola, gudang, ruang kerja',
        helperText: 'Boleh kosong. Gunakan koma untuk lebih dari satu ruangan.',
        helperStyle: const TextStyle(
          color: mutedText,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.add_home_work_rounded,
          color: navy,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: orange,
            width: 1.7,
          ),
        ),
      ),
    );
  }

'''

if "Widget _buildTambahanRuanganField()" not in text:
    marker = "  Widget _buildRecommendationButton() {"
    if marker in text:
        text = text.replace(marker, field_widget + marker)
    else:
        raise SystemExit("ERROR: marker _buildRecommendationButton tidak ditemukan.")

page_path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: tambahan ruangan user sudah tersambung ke rekomendasi dan generate denah.")
