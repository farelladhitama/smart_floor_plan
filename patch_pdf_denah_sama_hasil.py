from pathlib import Path
import re

exporter_path = Path(r"lib\app\services\floor_plan_pdf_exporter.dart")
riwayat_page_path = Path(r"lib\app\modules\riwayat\views\riwayat_page.dart")

for path in [exporter_path, riwayat_page_path]:
    if not path.exists():
        raise SystemExit(f"ERROR: File tidak ditemukan: {path}")
    backup = path.with_suffix(path.suffix + ".before-same-denah-pdf.bak")
    backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

# ============================================================
# 1) PATCH PDF EXPORTER: terima gambar denah dari Flutter widget
# ============================================================

text = exporter_path.read_text(encoding="utf-8").replace("\r\n", "\n")

# Pastikan dart:typed_data ada
if "import 'dart:typed_data';" not in text:
    text = text.replace(
        "import 'dart:convert';",
        "import 'dart:convert';\nimport 'dart:typed_data';"
    )

# Ubah signature exportHistory
text = text.replace(
    "  static Future<void> exportHistory(Map<String, dynamic> item) async {",
    "  static Future<void> exportHistory(\n    Map<String, dynamic> item, {\n    Uint8List? denahImageBytes,\n  }) async {"
)

# Ubah pemanggilan _floorPlanBox
text = text.replace(
    "            _floorPlanBox(rooms),",
    "            _floorPlanBox(\n              rooms,\n              denahImageBytes: denahImageBytes,\n            ),"
)

# Ubah signature _floorPlanBox
text = text.replace(
    "  static pw.Widget _floorPlanBox(List<Map<String, dynamic>> rooms) {",
    "  static pw.Widget _floorPlanBox(\n    List<Map<String, dynamic>> rooms, {\n    Uint8List? denahImageBytes,\n  }) {"
)

# Sisipkan prioritas pakai image bytes
marker = """  static pw.Widget _floorPlanBox(
    List<Map<String, dynamic>> rooms, {
    Uint8List? denahImageBytes,
  }) {"""

insert = """  static pw.Widget _floorPlanBox(
    List<Map<String, dynamic>> rooms, {
    Uint8List? denahImageBytes,
  }) {
    if (denahImageBytes != null && denahImageBytes.isNotEmpty) {
      return pw.Center(
        child: pw.Container(
          width: 360,
          height: 430,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F1F5F9'),
            borderRadius: pw.BorderRadius.circular(14),
            border: pw.Border.all(
              color: PdfColor.fromHex('#DDE6EF'),
              width: 1,
            ),
          ),
          child: pw.Image(
            pw.MemoryImage(denahImageBytes),
            fit: pw.BoxFit.contain,
          ),
        ),
      );
    }"""

if marker in text and "pw.MemoryImage(denahImageBytes)" not in text:
    text = text.replace(marker, insert)

exporter_path.write_text(text, encoding="utf-8")

# ============================================================
# 2) PATCH RIWAYAT PAGE: capture denah yang sama dengan Hasil Denah
# ============================================================

text = riwayat_page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

imports = {
    "import 'dart:typed_data';": "import 'dart:typed_data';",
    "import 'dart:ui' as ui;": "import 'dart:ui' as ui;",
    "import 'package:flutter/rendering.dart';": "import 'package:flutter/rendering.dart';",
}

for imp in imports:
    if imp not in text:
        if "import 'dart:convert';" in text:
            text = text.replace("import 'dart:convert';", "import 'dart:convert';\n" + imp)
        else:
            text = imp + "\n" + text

# Ganti tombol EXPORT PDF agar capture denah dulu
text = text.replace(
    "await FloorPlanPdfExporter.exportHistory(item);",
    "await _exportPdfWithSameDenahRender(item);"
)

# Tambahkan helper capture sebelum _buildDenahPreviewCanvas
helper = r'''  Future<void> _exportPdfWithSameDenahRender(Map<String, dynamic> item) async {
    final GlobalKey repaintKey = GlobalKey();

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    Uint8List? denahImageBytes;

    Get.dialog(
      Material(
        color: Colors.black.withOpacity(0.05),
        child: Center(
          child: Opacity(
            opacity: 0.01,
            child: RepaintBoundary(
              key: repaintKey,
              child: SizedBox(
                width: 430,
                height: 560,
                child: _buildDenahPreviewCanvas(item),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 450));
      await WidgetsBinding.instance.endOfFrame;

      final BuildContext? context = repaintKey.currentContext;
      final RenderObject? renderObject = context?.findRenderObject();

      if (renderObject is RenderRepaintBoundary) {
        final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );

        denahImageBytes = byteData?.buffer.asUint8List();
      }
    } catch (_) {
      denahImageBytes = null;
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }

    await FloorPlanPdfExporter.exportHistory(
      item,
      denahImageBytes: denahImageBytes,
    );
  }

'''

if "Future<void> _exportPdfWithSameDenahRender" not in text:
    marker = "  Widget _buildDenahPreviewCanvas(Map<String, dynamic> item) {"
    if marker not in text:
        raise SystemExit("ERROR: Marker _buildDenahPreviewCanvas tidak ditemukan di riwayat_page.dart")
    text = text.replace(marker, helper + marker)

riwayat_page_path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: Export PDF sekarang memakai gambar denah hasil capture render Hasil Denah.")
