from pathlib import Path

service_path = Path(r"lib\app\services\floor_plan_pdf_exporter.dart")
riwayat_page_path = Path(r"lib\app\modules\riwayat\views\riwayat_page.dart")

if not riwayat_page_path.exists():
    raise SystemExit(f"ERROR: File tidak ditemukan: {riwayat_page_path}")

service_path.parent.mkdir(parents=True, exist_ok=True)

if riwayat_page_path.exists():
    backup = riwayat_page_path.with_suffix(riwayat_page_path.suffix + ".before-export-pdf.bak")
    backup.write_text(riwayat_page_path.read_text(encoding="utf-8"), encoding="utf-8")

# ============================================================
# 1) BUAT SERVICE EXPORT PDF
# ============================================================

service_code = r'''import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FloorPlanPdfExporter {
  static Future<void> exportHistory(Map<String, dynamic> item) async {
    final pw.Document document = pw.Document();

    final List<Map<String, dynamic>> rooms = _parseRooms(item);
    final String title = _readText(item['title'], fallback: 'Denah Rumah');
    final double lebar = _toDouble(item['lebar_lahan']);
    final double panjang = _toDouble(item['panjang_lahan']);
    final double luas = _readArea(item);
    final String material = _readText(item['material'], fallback: '-');
    final String tanggal = _readText(
      item['updated_at'] ?? item['created_at'],
      fallback: '-',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            _header(title),
            pw.SizedBox(height: 14),
            _infoTable(
              lebar: lebar,
              panjang: panjang,
              luas: luas,
              material: material,
              tanggal: tanggal,
              jumlahRuang: rooms.length,
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Hasil Denah',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#0D1B2A'),
              ),
            ),
            pw.SizedBox(height: 10),
            _floorPlanBox(rooms),
            pw.SizedBox(height: 18),
            pw.Text(
              'Daftar Ruangan',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#0D1B2A'),
              ),
            ),
            pw.SizedBox(height: 8),
            _roomTable(rooms),
            pw.SizedBox(height: 18),
            _materialBox(item),
            pw.SizedBox(height: 16),
            pw.Text(
              'Catatan: PDF ini dibuat dari data riwayat SmartFloorPlan. Ukuran dan kebutuhan biaya bersifat estimasi awal.',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await document.save();
    final String safeTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    await Printing.layoutPdf(
      name: '${safeTitle.isEmpty ? 'denah' : safeTitle}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  static pw.Widget _header(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0D1B2A'),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 42,
            height: 42,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E47B3E'),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Center(
              child: pw.Text(
                'SFP',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SmartFloorPlan',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoTable({
    required double lebar,
    required double panjang,
    required double luas,
    required String material,
    required String tanggal,
    required int jumlahRuang,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F7FA'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColor.fromHex('#D9DEE8'),
          width: 1,
        ),
      ),
      child: pw.Column(
        children: [
          _infoRow('Ukuran Lahan', '${_formatNumber(lebar)} m x ${_formatNumber(panjang)} m'),
          _infoRow('Total Luas', '${_formatNumber(luas)} m2'),
          _infoRow('Jumlah Ruang', '$jumlahRuang ruang'),
          _infoRow('Material Dinding', material),
          _infoRow('Tanggal', tanggal),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 105,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#0D1B2A'),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _floorPlanBox(List<Map<String, dynamic>> rooms) {
    if (rooms.isEmpty) {
      return pw.Container(
        height: 330,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F8F3E8'),
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(
            color: PdfColor.fromHex('#0D1B2A'),
            width: 2,
          ),
        ),
        child: pw.Text(
          'Data denah belum tersedia',
          style: pw.TextStyle(
            color: PdfColor.fromHex('#0D1B2A'),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    double maxX = 1;
    double maxY = 1;

    for (final room in rooms) {
      final double right = _toDouble(room['x']) + _toDouble(room['width']);
      final double bottom = _toDouble(room['y']) + _toDouble(room['height']);

      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    const double boxWidth = 360;
    const double boxHeight = 330;
    const double padding = 8;

    return pw.Center(
      child: pw.Container(
        width: boxWidth,
        height: boxHeight,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F8F3E8'),
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(
            color: PdfColor.fromHex('#0D1B2A'),
            width: 2,
          ),
        ),
        child: pw.Stack(
          children: [
            pw.Positioned(
              left: padding,
              top: padding,
              right: padding,
              bottom: padding,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColor.fromHex('#8B95A6'),
                    width: 0.7,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
              ),
            ),
            ...rooms.map((room) {
              final String nama = _readText(
                room['nama'] ?? room['name'] ?? room['title'],
                fallback: 'Ruang',
              );

              final double x = _toDouble(room['x']);
              final double y = _toDouble(room['y']);
              final double width = _toDouble(room['width']);
              final double height = _toDouble(room['height']);

              double left = padding + ((x / maxX) * (boxWidth - padding * 2));
              double top = padding + ((y / maxY) * (boxHeight - padding * 2));
              double roomWidth = ((width / maxX) * (boxWidth - padding * 2));
              double roomHeight = ((height / maxY) * (boxHeight - padding * 2));

              if (roomWidth < 24) roomWidth = 24;
              if (roomHeight < 20) roomHeight = 20;

              if (left + roomWidth > boxWidth - padding) {
                roomWidth = boxWidth - padding - left;
              }

              if (top + roomHeight > boxHeight - padding) {
                roomHeight = boxHeight - padding - top;
              }

              return pw.Positioned(
                left: left,
                top: top,
                child: pw.Container(
                  width: roomWidth,
                  height: roomHeight,
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(2),
                  decoration: pw.BoxDecoration(
                    color: _roomColor(nama),
                    borderRadius: pw.BorderRadius.circular(5),
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#0D1B2A'),
                      width: 1,
                    ),
                  ),
                  child: pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    child: pw.Text(
                      nama,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#0D1B2A'),
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static pw.Widget _roomTable(List<Map<String, dynamic>> rooms) {
    if (rooms.isEmpty) {
      return pw.Text(
        'Tidak ada data ruangan.',
        style: const pw.TextStyle(fontSize: 10),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromHex('#D9DEE8'),
        width: 0.7,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.5),
        1: pw.FlexColumnWidth(2.1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#0D1B2A'),
          ),
          children: [
            _tableCell('No', header: true),
            _tableCell('Nama Ruang', header: true),
            _tableCell('Lebar', header: true),
            _tableCell('Panjang', header: true),
          ],
        ),
        ...rooms.asMap().entries.map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> room = entry.value;

          return pw.TableRow(
            children: [
              _tableCell('${index + 1}'),
              _tableCell(_readText(room['nama'] ?? room['name'], fallback: 'Ruang')),
              _tableCell(_formatNumber(_toDouble(room['width']))),
              _tableCell(_formatNumber(_toDouble(room['height']))),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: header ? PdfColors.white : PdfColor.fromHex('#0D1B2A'),
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _materialBox(Map<String, dynamic> item) {
    final Map<String, String> selected = _selectedMaterials(item);

    if (selected.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF3EA'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E47B3E'),
          width: 0.8,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Material Terpilih',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0D1B2A'),
            ),
          ),
          pw.SizedBox(height: 8),
          ...selected.entries.map((entry) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '${entry.key}: ${entry.value}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            );
          }),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _parseRooms(Map<String, dynamic> item) {
    final dynamic rawRooms = item['rooms_json'] ?? item['rooms'];

    List<dynamic> rooms = <dynamic>[];

    if (rawRooms is List) {
      rooms = rawRooms;
    } else if (rawRooms is String && rawRooms.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(rawRooms);

        if (decoded is List) {
          rooms = decoded;
        }
      } catch (_) {}
    }

    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];

    for (final dynamic raw in rooms) {
      if (raw is Map) {
        final Map<String, dynamic> room = Map<String, dynamic>.from(raw);

        if (_toDouble(room['width']) > 0 && _toDouble(room['height']) > 0) {
          result.add(room);
        }
      }
    }

    return result;
  }

  static Map<String, String> _selectedMaterials(Map<String, dynamic> item) {
    final dynamic raw = item['selected_materials'] ?? item['selectedMaterials'];

    if (raw is Map) {
      final Map<String, String> result = <String, String>{};

      raw.forEach((key, value) {
        final String k = key.toString().trim();
        final String v = value.toString().trim();

        if (k.isNotEmpty && v.isNotEmpty) {
          result[k] = v;
        }
      });

      return result;
    }

    return <String, String>{};
  }

  static double _readArea(Map<String, dynamic> item) {
    final double total = _toDouble(
      item['total_luas'] ??
          item['totalLuas'] ??
          item['luasBangunan'] ??
          item['inputLuas'],
    );

    if (total > 0) {
      return total;
    }

    final double lebar = _toDouble(item['lebar_lahan']);
    final double panjang = _toDouble(item['panjang_lahan']);

    if (lebar > 0 && panjang > 0) {
      return lebar * panjang;
    }

    return 0;
  }

  static PdfColor _roomColor(String nama) {
    final String lower = nama.toLowerCase();

    if (lower.contains('taman') ||
        lower.contains('teras') ||
        lower.contains('court')) {
      return PdfColor.fromHex('#B8D9A8');
    }

    if (lower.contains('km') ||
        lower.contains('wc') ||
        lower.contains('mandi')) {
      return PdfColor.fromHex('#A9E4EE');
    }

    if (lower.contains('tidur') || lower.contains('kt')) {
      return PdfColor.fromHex('#E5B173');
    }

    if (lower.contains('dapur') || lower.contains('makan')) {
      return PdfColor.fromHex('#EAD8A8');
    }

    if (lower.contains('carport') || lower.contains('cuci')) {
      return PdfColor.fromHex('#E6E6E6');
    }

    return PdfColor.fromHex('#F2E7C9');
  }

  static String _readText(dynamic value, {required String fallback}) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString().trim();
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}
'''

service_path.write_text(service_code, encoding="utf-8")

# ============================================================
# 2) PATCH RIWAYAT PAGE
# ============================================================

text = riwayat_page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

if "floor_plan_pdf_exporter.dart" not in text:
    text = text.replace(
        "import 'package:get/get.dart';",
        "import 'package:get/get.dart';\nimport 'package:smart_floor_plan/app/services/floor_plan_pdf_exporter.dart';"
    )

export_button = r'''                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (Get.isBottomSheetOpen == true) {
                        Get.back();
                      }

                      await Future.delayed(const Duration(milliseconds: 250));
                      await FloorPlanPdfExporter.exportHistory(item);
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text(
                      'EXPORT PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
'''

close_button_marker = r'''                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: background,
                      foregroundColor: navy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),'''

if "'EXPORT PDF'" not in text:
    if close_button_marker not in text:
        raise SystemExit("ERROR: Marker tombol Tutup di detail riwayat tidak ditemukan.")
    text = text.replace(close_button_marker, export_button + close_button_marker, 1)

riwayat_page_path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: Export PDF riwayat sudah ditambahkan.")
