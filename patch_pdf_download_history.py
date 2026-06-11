from pathlib import Path
import re

# ============================================================
# 1) Buat service untuk insert riwayat download PDF
# ============================================================

service_path = Path(r"lib\app\services\pdf_download_history_service.dart")
service_path.parent.mkdir(parents=True, exist_ok=True)

service_code = r'''import 'package:supabase_flutter/supabase_flutter.dart';

class PdfDownloadHistoryService {
  static Future<void> record({
    required Map<String, dynamic> item,
    required String fileName,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final String userName = _getUserName(user, item);
    final String? floorPlanId = _readTextOrNull(item['id']);
    final String title = _readText(item['title'], fallback: 'Denah SmartFloorPlan');

    await supabase.from('pdf_download_histories').insert({
      'user_id': user.id,
      'user_name': userName,
      'floor_plan_id': floorPlanId,
      'title': title,
      'file_name': fileName,
      'total_luas': _readNumber(item['total_luas'] ?? item['totalLuas']),
      'estimasi_rab': _readNumber(item['estimasi_rab'] ?? item['estimasiRab']),
    });
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
# 2) Patch FloorPlanPdfExporter agar setelah download PDF,
#    langsung insert ke pdf_download_histories
# ============================================================

exporter_path = Path(r"lib\app\services\floor_plan_pdf_exporter.dart")

if not exporter_path.exists():
    raise SystemExit("ERROR: file floor_plan_pdf_exporter.dart tidak ditemukan.")

backup = exporter_path.with_suffix(exporter_path.suffix + ".before-pdf-download-history.bak")
backup.write_text(exporter_path.read_text(encoding="utf-8"), encoding="utf-8")

text = exporter_path.read_text(encoding="utf-8").replace("\r\n", "\n")

# Tambahkan import service
if "pdf_download_history_service.dart" not in text:
    last_import_match = list(re.finditer(r"^import .*?;\n", text, flags=re.M))
    if last_import_match:
        last = last_import_match[-1]
        text = text[:last.end()] + "import 'package:smart_floor_plan/app/services/pdf_download_history_service.dart';\n" + text[last.end():]
    else:
        text = "import 'package:smart_floor_plan/app/services/pdf_download_history_service.dart';\n" + text

# Tambahkan record setelah PdfDownloadHelper.saveOrShare
target = "await PdfDownloadHelper.saveOrShare(bytes: bytes, fileName: fileName);"
insert = """await PdfDownloadHelper.saveOrShare(bytes: bytes, fileName: fileName);

    await PdfDownloadHistoryService.record(
      item: item,
      fileName: fileName,
    );"""

if target in text and "PdfDownloadHistoryService.record" not in text:
    text = text.replace(target, insert, 1)
elif "PdfDownloadHistoryService.record" not in text:
    print("WARNING: Tidak menemukan PdfDownloadHelper.saveOrShare.")
    print("Nanti kalau analyze error atau data belum masuk, kirim isi floor_plan_pdf_exporter.dart bagian exportHistory.")

exporter_path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: Export PDF sekarang akan dicatat ke pdf_download_histories.")
