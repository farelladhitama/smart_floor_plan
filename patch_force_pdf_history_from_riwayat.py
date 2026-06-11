from pathlib import Path
import re

# ============================================================
# 1. Buat / timpa service pencatat download PDF
# ============================================================

service_path = Path(r"lib\app\services\pdf_download_history_service.dart")
service_path.parent.mkdir(parents=True, exist_ok=True)

service_code = r'''import 'package:supabase_flutter/supabase_flutter.dart';

class PdfDownloadHistoryService {
  static Future<void> record({
    required Map<String, dynamic> item,
    String? fileName,
  }) async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final User? user = supabase.auth.currentUser;

      if (user == null) {
        print('PDF HISTORY: gagal, user belum login.');
        return;
      }

      final String finalFileName = fileName ?? buildFileName(item);

      final Map<String, dynamic> payload = {
        'user_id': user.id,
        'user_name': _getUserName(user, item),
        'floor_plan_id': _readTextOrNull(item['id']),
        'title': _readText(item['title'], fallback: 'Denah SmartFloorPlan'),
        'file_name': finalFileName,
        'total_luas': _readNumber(item['total_luas'] ?? item['totalLuas']),
        'estimasi_rab': _readNumber(item['estimasi_rab'] ?? item['estimasiRab']),
      };

      print('PDF HISTORY INSERT PAYLOAD: $payload');

      await supabase.from('pdf_download_histories').insert(payload);

      print('PDF HISTORY: berhasil masuk Supabase.');
    } catch (e) {
      print('PDF HISTORY ERROR: $e');
    }
  }

  static String buildFileName(Map<String, dynamic> item) {
    final String title = _readText(
      item['title'],
      fallback: 'denah_smartfloorplan',
    );

    final String safeTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    return '${safeTitle}_$timestamp.pdf';
  }

  static String _getUserName(User user, Map<String, dynamic> item) {
    final String fromItem = _readText(item['user_name'], fallback: '');

    if (fromItem.trim().isNotEmpty) {
      return fromItem.trim();
    }

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

  static String _readText(dynamic value, {required String fallback}) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  static String? _readTextOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static double? _readNumber(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
'''

service_path.write_text(service_code, encoding="utf-8")


# ============================================================
# 2. Patch RiwayatPage agar setelah EXPORT PDF langsung insert DB
# ============================================================

path = Path(r"lib\app\modules\riwayat\views\riwayat_page.dart")

if not path.exists():
    raise SystemExit("ERROR: riwayat_page.dart tidak ditemukan.")

backup = path.with_suffix(path.suffix + ".before-force-pdf-history.bak")
backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

# Tambah import service
if "pdf_download_history_service.dart" not in text:
    imports = list(re.finditer(r"^import .*?;\n", text, flags=re.M))
    if imports:
        last = imports[-1]
        text = (
            text[:last.end()]
            + "import 'package:smart_floor_plan/app/services/pdf_download_history_service.dart';\n"
            + text[last.end():]
        )
    else:
        text = "import 'package:smart_floor_plan/app/services/pdf_download_history_service.dart';\n" + text

# Tambahkan insert setelah export PDF yang pakai denah image
if "PdfDownloadHistoryService.record(" not in text:
    pattern = r"await FloorPlanPdfExporter\.exportHistory\(\s*item,\s*denahImageBytes:\s*denahImageBytes,\s*\);"

    replacement = """await FloorPlanPdfExporter.exportHistory(
      item,
      denahImageBytes: denahImageBytes,
    );

    await PdfDownloadHistoryService.record(
      item: item,
    );"""

    new_text, count = re.subn(pattern, replacement, text, count=1, flags=re.S)

    if count == 0:
        # fallback kalau bentuk export-nya beda
        pattern2 = r"await FloorPlanPdfExporter\.exportHistory\(\s*item\s*\);"
        replacement2 = """await FloorPlanPdfExporter.exportHistory(item);

    await PdfDownloadHistoryService.record(
      item: item,
    );"""

        new_text, count2 = re.subn(pattern2, replacement2, text, count=1, flags=re.S)

        if count2 == 0:
            raise SystemExit(
                "ERROR: Tidak menemukan baris FloorPlanPdfExporter.exportHistory di riwayat_page.dart. Kirim file riwayat_page.dart."
            )

    text = new_text

path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: Export PDF dari RiwayatPage sekarang insert ke pdf_download_histories.")
