from pathlib import Path

controller_path = Path(r"lib\app\modules\riwayat\controllers\riwayat_controller.dart")
page_path = Path(r"lib\app\modules\riwayat\views\riwayat_page.dart")
hasil_path = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart")

if not controller_path.exists():
    raise SystemExit("ERROR: riwayat_controller.dart tidak ditemukan.")

if not page_path.exists():
    raise SystemExit("ERROR: riwayat_page.dart tidak ditemukan.")

controller_text = controller_path.read_text(encoding="utf-8").replace("\r\n", "\n")
page_text = page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

controller_path.with_suffix(controller_path.suffix + ".before-riwayat-gabungan-final.bak").write_text(controller_text, encoding="utf-8")
page_path.with_suffix(page_path.suffix + ".before-riwayat-gabungan-final.bak").write_text(page_text, encoding="utf-8")

def replace_method(text, signature, new_method):
    start = text.find(signature)
    if start == -1:
        raise SystemExit(f"ERROR: method tidak ditemukan: {signature}")

    brace_start = text.find("{", start)
    if brace_start == -1:
        raise SystemExit(f"ERROR: body method tidak ditemukan: {signature}")

    depth = 0
    end = None

    for i in range(brace_start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break

    if end is None:
        raise SystemExit(f"ERROR: akhir method tidak ditemukan: {signature}")

    return text[:start] + new_method + text[end:]

# ============================================================
# 1. GANTI loadHistories: ambil floor_plans + scan_floor_plans
# ============================================================

load_start = controller_text.find("  Future<void> loadHistories() async {")
load_end = controller_text.find("  String getTitle(Map<String, dynamic> item) {", load_start)

if load_start == -1 or load_end == -1:
    raise SystemExit("ERROR: area loadHistories tidak ditemukan.")

new_load = r'''  Future<void> loadHistories() async {
    final User? user = _supabase.auth.currentUser;

    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    try {
      isLoading.value = true;

      final generateResponse = await _supabase
          .from('floor_plans')
          .select(
            'id, title, panjang_lahan, lebar_lahan, jumlah_kamar, material_dinding, material_semen, material_pasir, material_keramik_lantai, material_cat_dinding, material_genteng_atap, material_plafon, material_pipa, ruang_tambahan, total_luas, estimasi_rab, rooms_json, created_at, updated_at',
          )
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);

      final scanResponse = await _supabase
          .from('scan_floor_plans')
          .select(
            'id, title, panjang_lahan, lebar_lahan, jumlah_ruang, material_dinding, material_semen, material_pasir, material_keramik_lantai, material_cat_dinding, material_genteng_atap, material_plafon, material_pipa, total_luas, estimasi_rab, detected_rooms_json, scan_image_name, created_at, updated_at',
          )
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);

      final List<Map<String, dynamic>> generateRows = (generateResponse as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map(_normalizeGenerateHistory)
          .toList();

      final List<Map<String, dynamic>> scanRows = (scanResponse as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map(_normalizeScanHistory)
          .toList();

      final List<Map<String, dynamic>> combined = <Map<String, dynamic>>[
        ...generateRows,
        ...scanRows,
      ];

      combined.sort((a, b) {
        return _historySortDate(b).compareTo(_historySortDate(a));
      });

      histories.assignAll(combined);
    } on PostgrestException catch (error) {
      showMessage(
        'Gagal Memuat Riwayat',
        error.message,
      );
    } catch (error) {
      showMessage(
        'Gagal Memuat Riwayat',
        'Terjadi kesalahan: $error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _normalizeGenerateHistory(Map<String, dynamic> item) {
    return <String, dynamic>{
      ...item,
      '_source_table': 'floor_plans',
      '_history_type': 'generate',
      'jumlah_ruang': item['jumlah_kamar'],
    };
  }

  Map<String, dynamic> _normalizeScanHistory(Map<String, dynamic> item) {
    final dynamic detectedRooms = item['detected_rooms_json'];
    final List<dynamic> rooms = detectedRooms is List ? detectedRooms : <dynamic>[];

    return <String, dynamic>{
      ...item,
      '_source_table': 'scan_floor_plans',
      '_history_type': 'scan',
      'rooms_json': rooms,
      'jumlah_kamar': item['jumlah_ruang'] ?? rooms.length,
      'ruang_tambahan': <String>[],
    };
  }

  String _historySourceTable(Map<String, dynamic> item) {
    final String table = (item['_source_table'] ?? '').toString();

    if (table == 'scan_floor_plans') {
      return 'scan_floor_plans';
    }

    return 'floor_plans';
  }

  bool _isScanHistory(Map<String, dynamic> item) {
    return _historySourceTable(item) == 'scan_floor_plans';
  }

  DateTime _historySortDate(Map<String, dynamic> item) {
    final String rawDate =
        (item['updated_at'] ?? item['created_at'] ?? '').toString();

    return DateTime.tryParse(rawDate) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

'''

controller_text = controller_text[:load_start] + new_load + controller_text[load_end:]

# ============================================================
# 2. Subtitle: scan tampil ruang, generate tampil kamar
# ============================================================

new_get_subtitle = r'''  String getSubtitle(Map<String, dynamic> item) {
    final String lebar = _formatNumber(item['lebar_lahan']);
    final String panjang = _formatNumber(item['panjang_lahan']);
    final String material =
        (item['material_dinding'] ?? item['material'] ?? '-').toString();

    if (_isScanHistory(item)) {
      return '$lebar m x $panjang m  |  ${getRoomCount(item)} ruang  |  $material';
    }

    final String kamar = (item['jumlah_kamar'] ?? 0).toString();

    return '$lebar m x $panjang m  |  $kamar kamar  |  $material';
  }'''

controller_text = replace_method(
    controller_text,
    "  String getSubtitle(Map<String, dynamic> item) {",
    new_get_subtitle,
)

# ============================================================
# 3. Jumlah ruang: baca rooms_json / jumlah_ruang
# ============================================================

new_get_room_count = r'''  int getRoomCount(Map<String, dynamic> item) {
    final dynamic roomsJson = item['rooms_json'];

    if (roomsJson is List) {
      return roomsJson.length;
    }

    final num jumlahRuang = _toNum(item['jumlah_ruang']);

    if (jumlahRuang > 0) {
      return jumlahRuang.toInt();
    }

    final num jumlahKamar = _toNum(item['jumlah_kamar']);

    if (jumlahKamar > 0) {
      return jumlahKamar.toInt();
    }

    return 0;
  }'''

controller_text = replace_method(
    controller_text,
    "  int getRoomCount(Map<String, dynamic> item) {",
    new_get_room_count,
)

# ============================================================
# 4. Delete: hapus dari tabel asal
# ============================================================

new_delete = r'''  Future<void> deleteHistory(Map<String, dynamic> item) async {
    final String id = (item['id'] ?? '').toString();

    if (id.isEmpty) {
      showMessage(
        'Gagal Hapus',
        'ID riwayat tidak ditemukan.',
      );
      return;
    }

    final User? user = _supabase.auth.currentUser;

    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    final String tableName = _historySourceTable(item);

    try {
      await _supabase
          .from(tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);

      histories.removeWhere((history) {
        return history['id'] == id &&
            _historySourceTable(history) == tableName;
      });

      showMessage(
        'Berhasil',
        'Riwayat denah berhasil dihapus.',
      );
    } on PostgrestException catch (error) {
      showMessage(
        'Gagal Hapus',
        error.message,
      );
    } catch (error) {
      showMessage(
        'Gagal Hapus',
        'Terjadi kesalahan: $error',
      );
    }
  }'''

controller_text = replace_method(
    controller_text,
    "  Future<void> deleteHistory(Map<String, dynamic> item) async {",
    new_delete,
)

controller_path.write_text(controller_text, encoding="utf-8")

# ============================================================
# 5. Ganti tulisan UI riwayat
# ============================================================

page_text = page_text.replace(
    "Data riwayat diambil langsung dari tabel floor_plans.",
    "Data riwayat gabungan dari tabel floor_plans dan scan_floor_plans.",
)

page_text = page_text.replace(
    "Generate denah lalu tekan Simpan Denah agar muncul di sini.",
    "Generate atau scan denah lalu tekan Simpan Denah agar muncul di sini.",
)

page_text = page_text.replace(
    "Riwayat ini sudah mengambil data asli dari Supabase. Fitur Edit denah lama akan disambungkan pada tahap berikutnya.",
    "Riwayat ini mengambil data gabungan dari generate biasa dan scan denah. Database tetap dipisah, tetapi tampilannya jadi satu.",
)

page_path.write_text(page_text, encoding="utf-8")

# ============================================================
# 6. Ganti teks popup simpan scan biar tidak bikin bingung
# ============================================================

if hasil_path.exists():
    hasil_text = hasil_path.read_text(encoding="utf-8").replace("\r\n", "\n")
    hasil_path.with_suffix(hasil_path.suffix + ".before-popup-riwayat-desain.bak").write_text(hasil_text, encoding="utf-8")

    hasil_text = hasil_text.replace(
        "Hasil scan berhasil disimpan ke riwayat scan.",
        "Hasil scan berhasil disimpan ke Riwayat Desain.",
    )

    hasil_text = hasil_text.replace(
        "Hasil scan berhasil diperbarui.",
        "Hasil scan berhasil diperbarui di Riwayat Desain.",
    )

    hasil_path.write_text(hasil_text, encoding="utf-8")

print("PATCH BERHASIL: Riwayat sekarang gabung floor_plans + scan_floor_plans.")
