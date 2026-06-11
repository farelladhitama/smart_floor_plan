from pathlib import Path

target = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart")
backup = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart.before-fix-scan-rab-sama-aplikasi.bak")

if not target.exists():
    raise SystemExit("ERROR: file hasil_denah_controller.dart tidak ditemukan.")

if not backup.exists():
    raise SystemExit("ERROR: file backup tidak ditemukan. Kirim isi baris 380-470 kalau ini muncul.")

# Balikin dulu ke file sebelum patch rusak
text = backup.read_text(encoding="utf-8").replace("\r\n", "\n")

start_marker = "  Future<double> _calculateScanEstimasiRab({"
end_marker = "  Future<void> _simpanScanDenah() async {"

start = text.find(start_marker)
end = text.find(end_marker)

if start == -1:
    raise SystemExit("ERROR: method _calculateScanEstimasiRab tidak ditemukan di backup.")

if end == -1:
    raise SystemExit("ERROR: method _simpanScanDenah tidak ditemukan di backup.")

new_block = r'''  Future<double> _calculateScanEstimasiRab({
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

'''

fixed = text[:start] + new_block + text[end:]
target.write_text(fixed, encoding="utf-8")

print("FIX BERHASIL: file dikembalikan dari backup lalu RAB scan dipatch ulang dengan aman.")
