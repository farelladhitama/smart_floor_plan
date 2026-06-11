from pathlib import Path

exporter_path = Path(r"lib\app\services\floor_plan_pdf_exporter.dart")
helper_main = Path(r"lib\app\services\pdf_download_helper.dart")
helper_web = Path(r"lib\app\services\pdf_download_helper_web.dart")
helper_stub = Path(r"lib\app\services\pdf_download_helper_stub.dart")

if not exporter_path.exists():
    raise SystemExit(f"ERROR: File tidak ditemukan: {exporter_path}")

backup = exporter_path.with_suffix(exporter_path.suffix + ".before-auto-download.bak")
backup.write_text(exporter_path.read_text(encoding="utf-8"), encoding="utf-8")

# ============================================================
# 1) BUAT HELPER CONDITIONAL DOWNLOAD
# ============================================================

helper_main.write_text(r'''export 'pdf_download_helper_stub.dart'
    if (dart.library.html) 'pdf_download_helper_web.dart';
''', encoding="utf-8")

helper_web.write_text(r'''import 'dart:html' as html;
import 'dart:typed_data';

class PdfDownloadHelper {
  static Future<void> saveOrShare({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final html.Blob blob = html.Blob(
      <Object>[bytes],
      'application/pdf',
    );

    final String url = html.Url.createObjectUrlFromBlob(blob);

    final html.AnchorElement anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(url);
  }
}
''', encoding="utf-8")

helper_stub.write_text(r'''import 'dart:typed_data';

import 'package:printing/printing.dart';

class PdfDownloadHelper {
  static Future<void> saveOrShare({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }
}
''', encoding="utf-8")

# ============================================================
# 2) PATCH EXPORTER AGAR PAKAI HELPER
# ============================================================

text = exporter_path.read_text(encoding="utf-8").replace("\r\n", "\n")

if "pdf_download_helper.dart" not in text:
    text = text.replace(
        "import 'package:smart_floor_plan/app/services/material_price_service.dart';",
        "import 'package:smart_floor_plan/app/services/material_price_service.dart';\nimport 'package:smart_floor_plan/app/services/pdf_download_helper.dart';"
    )

# Hapus import printing dari exporter kalau masih ada, karena sekarang dipakai di helper stub
text = text.replace("import 'package:printing/printing.dart';\n", "")

start_marker = "    final Uint8List bytes = await document.save();"
end_marker = "\n  }\n\n  static pw.Widget _header"

if start_marker not in text:
    raise SystemExit("ERROR: Marker document.save tidak ditemukan di floor_plan_pdf_exporter.dart")

start = text.index(start_marker)
end = text.index(end_marker, start)

new_end_block = r'''    final Uint8List bytes = await document.save();
    final String safeTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final String fileName = '${safeTitle.isEmpty ? 'denah' : safeTitle}.pdf';

    await PdfDownloadHelper.saveOrShare(
      bytes: bytes,
      fileName: fileName,
    );
'''

text = text[:start] + new_end_block + text[end:]

exporter_path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: Export PDF di Edge/Web sekarang otomatis download.")
