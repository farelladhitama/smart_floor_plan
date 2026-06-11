from pathlib import Path

path = Path(r"lib\app\services\floor_plan_pdf_exporter.dart")

if not path.exists():
    raise SystemExit(f"ERROR: File tidak ditemukan: {path}")

backup = path.with_suffix(path.suffix + ".before-rab-pdf.bak")
backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

code = r'''import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smart_floor_plan/app/services/material_price_service.dart';

class FloorPlanPdfExporter {
  static Future<void> exportHistory(Map<String, dynamic> item) async {
    final pw.Document document = pw.Document();

    final List<Map<String, dynamic>> rooms = _parseRooms(item);
    final List<_PdfRabItem> rabItems = await _buildRabItems(item);

    final String title = _readText(item['title'], fallback: 'Denah Rumah');
    final double lebar = _toDouble(item['lebar_lahan']);
    final double panjang = _toDouble(item['panjang_lahan']);
    final double luas = _readArea(item);
    final String material = _readText(item['material'], fallback: '-');
    final String tanggal = _readText(
      item['updated_at'] ?? item['created_at'],
      fallback: '-',
    );

    final double totalRab = rabItems.fold<double>(
      0,
      (total, item) => total + item.totalHarga,
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
            _rabTotalBox(
              luas: luas,
              totalRab: totalRab,
            ),
            pw.SizedBox(height: 12),
            _rabTable(rabItems),
            pw.SizedBox(height: 16),
            pw.Text(
              'Catatan: hasil RAB ini berupa estimasi awal. Jumlah bahan dan harga dapat berubah sesuai desain akhir, lokasi pembangunan, kualitas material, dan harga pasar terbaru.',
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

  static pw.Widget _rabTotalBox({
    required double luas,
    required double totalRab,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E47B3E'),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Total Estimasi Kebutuhan Material',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            _rupiah(totalRab),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Berdasarkan luas ${_formatNumber(luas)} m2',
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _rabTable(List<_PdfRabItem> items) {
    if (items.isEmpty) {
      return pw.Text(
        'Data RAB tidak tersedia.',
        style: const pw.TextStyle(fontSize: 10),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Rincian Estimasi RAB',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#0D1B2A'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColor.fromHex('#D9DEE8'),
            width: 0.7,
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.15),
            1: pw.FlexColumnWidth(1.55),
            2: pw.FlexColumnWidth(0.85),
            3: pw.FlexColumnWidth(1.05),
            4: pw.FlexColumnWidth(1.1),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0D1B2A'),
              ),
              children: [
                _tableCell('Kategori', header: true),
                _tableCell('Material', header: true),
                _tableCell('Kebutuhan', header: true),
                _tableCell('Harga', header: true),
                _tableCell('Subtotal', header: true),
              ],
            ),
            ...items.map((item) {
              return pw.TableRow(
                children: [
                  _tableCell(item.kategori),
                  _tableCell(item.namaMaterial),
                  _tableCell('${_formatVolume(item.volume)} ${item.satuan}'),
                  _tableCell('${_rupiah(item.hargaSatuan)} / ${item.satuan}'),
                  _tableCell(_rupiah(item.totalHarga)),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 8.5 : 8,
          color: header ? PdfColors.white : PdfColor.fromHex('#0D1B2A'),
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Future<List<_PdfRabItem>> _buildRabItems(
    Map<String, dynamic> item,
  ) async {
    List<Map<String, dynamic>> materialOptions = <Map<String, dynamic>>[];

    try {
      materialOptions = await MaterialPriceService().getRabMaterialOptions();
    } catch (_) {
      materialOptions = <Map<String, dynamic>>[];
    }

    if (materialOptions.isEmpty) {
      materialOptions = _fallbackMaterials();
    }

    final double luas = _readArea(item);
    final Map<String, String> selected = _selectedMaterials(item);

    _ensureDefaultSelectedMaterials(
      selected: selected,
      materialOptions: materialOptions,
    );

    final double dindingM2 = luas * 2.7;
    final double lantaiM2 = luas * 1.1;
    final double plafonM2 = luas;
    final double catM2 = dindingM2 * 1.5;
    final double atapM2 = luas * 1.15;

    final List<_PdfRabItem> results = <_PdfRabItem>[];

    for (final String kategori in _tampilKategori) {
      final String? namaMaterial = selected[kategori];

      if (namaMaterial == null || namaMaterial.trim().isEmpty) {
        continue;
      }

      double volume = 0;
      String fallbackSatuan = 'pcs';
      double fallbackHarga = 0;

      if (kategori == 'Material Dinding') {
        volume = _volumeDinding(namaMaterial, dindingM2);
        fallbackSatuan = 'pcs';
        fallbackHarga = 1200;
      } else if (kategori == 'Semen') {
        volume = (luas * 0.45).ceilToDouble();
        fallbackSatuan = 'sak';
        fallbackHarga = 65000;
      } else if (kategori == 'Pasir') {
        volume = _round1(luas * 0.10);
        fallbackSatuan = 'm3';
        fallbackHarga = 250000;
      } else if (kategori == 'Keramik Lantai') {
        volume = _round1(lantaiM2);
        fallbackSatuan = 'm2';
        fallbackHarga = 90000;
      } else if (kategori == 'Cat Dinding') {
        volume = (catM2 / 10).ceilToDouble();
        fallbackSatuan = 'liter';
        fallbackHarga = 55000;
      } else if (kategori == 'Genteng / Atap') {
        volume = _volumeAtap(namaMaterial, atapM2);
        fallbackSatuan = _satuanAtap(namaMaterial);
        fallbackHarga = 3500;
      } else if (kategori == 'Plafon') {
        volume = _round1(plafonM2);
        fallbackSatuan = 'm2';
        fallbackHarga = 75000;
      } else if (kategori == 'Pipa') {
        volume = (luas * 0.35).ceilToDouble();
        fallbackSatuan = 'meter';
        fallbackHarga = 18000;
      }

      results.add(
        _buildRabResult(
          materialOptions: materialOptions,
          kategori: kategori,
          namaMaterial: namaMaterial,
          volume: volume,
          fallbackSatuan: fallbackSatuan,
          fallbackHarga: _hargaFallback(
            materialOptions,
            namaMaterial,
            fallbackHarga,
          ),
        ),
      );
    }

    return results;
  }

  static _PdfRabItem _buildRabResult({
    required List<Map<String, dynamic>> materialOptions,
    required String kategori,
    required String namaMaterial,
    required double volume,
    required String fallbackSatuan,
    required double fallbackHarga,
  }) {
    final Map<String, dynamic>? item = _findMaterial(
      materialOptions,
      kategori,
      namaMaterial,
    );

    final String satuan = _normalizeSatuan(
      item?['satuan_rab']?.toString() ??
          item?['satuan']?.toString() ??
          fallbackSatuan,
    );

    final dynamic hargaValue = item?['harga_rab'] ?? item?['harga_rata_rata'];

    double harga = fallbackHarga;

    if (hargaValue is num) {
      harga = hargaValue.toDouble();
    } else if (hargaValue != null) {
      harga = double.tryParse(hargaValue.toString()) ?? fallbackHarga;
    }

    return _PdfRabItem(
      namaMaterial: _titleCase(namaMaterial),
      kategori: kategori,
      satuan: satuan,
      volume: volume,
      hargaSatuan: harga,
    );
  }

  static Map<String, String> _selectedMaterials(Map<String, dynamic> item) {
    final dynamic raw = item['selected_materials'] ?? item['selectedMaterials'];

    final Map<String, String> result = <String, String>{};

    if (raw is Map) {
      raw.forEach((key, value) {
        final String k = key.toString().trim();
        final String v = value.toString().trim();

        if (k.isNotEmpty && v.isNotEmpty) {
          result[k] = v;
        }
      });
    }

    if (!result.containsKey('Material Dinding')) {
      final String dinding = _readText(
        item['material'],
        fallback: 'batu bata merah',
      );

      result['Material Dinding'] = dinding;
    }

    return result;
  }

  static void _ensureDefaultSelectedMaterials({
    required Map<String, String> selected,
    required List<Map<String, dynamic>> materialOptions,
  }) {
    final Map<String, String> defaults = {
      'Material Dinding': 'batu bata merah',
      'Semen': 'semen tiga roda',
      'Pasir': 'pasir pasang',
      'Keramik Lantai': 'keramik lantai standar',
      'Cat Dinding': 'cat tembok standar',
      'Genteng / Atap': 'genteng tanah liat',
      'Plafon': 'plafon gypsum',
      'Pipa': 'pipa pvc',
    };

    defaults.forEach((kategori, namaDefault) {
      if (!selected.containsKey(kategori) ||
          selected[kategori]!.trim().isEmpty) {
        selected[kategori] = _findExistingMaterialName(
          materialOptions,
          kategori,
          namaDefault,
        );
      }
    });
  }

  static String _findExistingMaterialName(
    List<Map<String, dynamic>> materialOptions,
    String kategori,
    String fallbackName,
  ) {
    final String target = fallbackName.toLowerCase();

    for (final Map<String, dynamic> item in materialOptions) {
      final String itemKategori = (item['kategori'] ?? '').toString();
      final String itemName = (item['nama_material'] ?? '').toString();

      if (itemKategori == kategori && itemName.toLowerCase() == target) {
        return itemName;
      }
    }

    for (final Map<String, dynamic> item in materialOptions) {
      final String itemKategori = (item['kategori'] ?? '').toString();
      final String itemName = (item['nama_material'] ?? '').toString();

      if (itemKategori == kategori && itemName.isNotEmpty) {
        return itemName;
      }
    }

    return fallbackName;
  }

  static Map<String, dynamic>? _findMaterial(
    List<Map<String, dynamic>> materialOptions,
    String kategori,
    String namaMaterial,
  ) {
    final String targetName = namaMaterial.toLowerCase();

    for (final Map<String, dynamic> item in materialOptions) {
      final String itemKategori = (item['kategori'] ?? '').toString();
      final String itemName =
          (item['nama_material'] ?? '').toString().toLowerCase();

      if (itemKategori == kategori && itemName == targetName) {
        return item;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _findMaterialByName(
    List<Map<String, dynamic>> materialOptions,
    String namaMaterial,
  ) {
    final String target = namaMaterial.toLowerCase();

    for (final Map<String, dynamic> item in materialOptions) {
      final String name =
          (item['nama_material'] ?? '').toString().toLowerCase();

      if (name == target) {
        return item;
      }
    }

    return null;
  }

  static double _volumeDinding(String material, double dindingM2) {
    final String name = material.toLowerCase();

    if (name.contains('bata ringan') || name.contains('hebel')) {
      return (dindingM2 * 8.5).ceilToDouble();
    }

    if (name.contains('batako')) {
      return (dindingM2 * 12.5).ceilToDouble();
    }

    return (dindingM2 * 70).ceilToDouble();
  }

  static double _volumeAtap(String material, double atapM2) {
    final String name = material.toLowerCase();

    if (name.contains('spandek')) {
      return _round1(atapM2);
    }

    if (name.contains('beton')) {
      return (atapM2 * 10).ceilToDouble();
    }

    return (atapM2 * 25).ceilToDouble();
  }

  static String _satuanAtap(String material) {
    final String name = material.toLowerCase();

    if (name.contains('spandek')) {
      return 'm2';
    }

    return 'pcs';
  }

  static double _hargaFallback(
    List<Map<String, dynamic>> materialOptions,
    String material,
    double defaultValue,
  ) {
    final Map<String, dynamic>? item = _findMaterialByName(
      materialOptions,
      material,
    );

    final dynamic value = item?['harga_rab'] ?? item?['harga_rata_rata'];

    if (value is num) {
      return value.toDouble();
    }

    if (value != null) {
      return double.tryParse(value.toString()) ?? defaultValue;
    }

    return defaultValue;
  }

  static List<Map<String, dynamic>> _fallbackMaterials() {
    return [
      {'kategori': 'Material Dinding', 'nama_material': 'batu bata merah', 'satuan_rab': 'pcs', 'harga_rab': 1200},
      {'kategori': 'Material Dinding', 'nama_material': 'batako', 'satuan_rab': 'pcs', 'harga_rab': 3500},
      {'kategori': 'Material Dinding', 'nama_material': 'bata ringan / hebel', 'satuan_rab': 'pcs', 'harga_rab': 8500},
      {'kategori': 'Semen', 'nama_material': 'semen tiga roda', 'satuan_rab': 'sak', 'harga_rab': 65000},
      {'kategori': 'Semen', 'nama_material': 'semen gresik', 'satuan_rab': 'sak', 'harga_rab': 65000},
      {'kategori': 'Semen', 'nama_material': 'semen padang', 'satuan_rab': 'sak', 'harga_rab': 65000},
      {'kategori': 'Semen', 'nama_material': 'semen mortar', 'satuan_rab': 'sak', 'harga_rab': 75000},
      {'kategori': 'Semen', 'nama_material': 'semen instan', 'satuan_rab': 'sak', 'harga_rab': 75000},
      {'kategori': 'Pasir', 'nama_material': 'pasir pasang', 'satuan_rab': 'm3', 'harga_rab': 250000},
      {'kategori': 'Pasir', 'nama_material': 'pasir urug', 'satuan_rab': 'm3', 'harga_rab': 180000},
      {'kategori': 'Keramik Lantai', 'nama_material': 'keramik lantai standar', 'satuan_rab': 'm2', 'harga_rab': 90000},
      {'kategori': 'Keramik Lantai', 'nama_material': 'keramik lantai premium', 'satuan_rab': 'm2', 'harga_rab': 130000},
      {'kategori': 'Keramik Lantai', 'nama_material': 'granit lantai', 'satuan_rab': 'm2', 'harga_rab': 180000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok standar', 'satuan_rab': 'liter', 'harga_rab': 55000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok avian', 'satuan_rab': 'liter', 'harga_rab': 60000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok dulux', 'satuan_rab': 'liter', 'harga_rab': 75000},
      {'kategori': 'Cat Dinding', 'nama_material': 'cat tembok nippon paint', 'satuan_rab': 'liter', 'harga_rab': 75000},
      {'kategori': 'Genteng / Atap', 'nama_material': 'genteng tanah liat', 'satuan_rab': 'pcs', 'harga_rab': 3500},
      {'kategori': 'Genteng / Atap', 'nama_material': 'genteng beton', 'satuan_rab': 'pcs', 'harga_rab': 7000},
      {'kategori': 'Genteng / Atap', 'nama_material': 'atap spandek', 'satuan_rab': 'm2', 'harga_rab': 85000},
      {'kategori': 'Plafon', 'nama_material': 'plafon gypsum', 'satuan_rab': 'm2', 'harga_rab': 75000},
      {'kategori': 'Plafon', 'nama_material': 'plafon pvc', 'satuan_rab': 'm2', 'harga_rab': 75000},
      {'kategori': 'Plafon', 'nama_material': 'plafon grc', 'satuan_rab': 'm2', 'harga_rab': 90000},
      {'kategori': 'Pipa', 'nama_material': 'pipa pvc', 'satuan_rab': 'meter', 'harga_rab': 18000},
      {'kategori': 'Pipa', 'nama_material': 'pipa air', 'satuan_rab': 'meter', 'harga_rab': 20000},
      {'kategori': 'Pipa', 'nama_material': 'pipa conduit', 'satuan_rab': 'meter', 'harga_rab': 15000},
    ];
  }

  static const List<String> _tampilKategori = [
    'Material Dinding',
    'Semen',
    'Pasir',
    'Keramik Lantai',
    'Cat Dinding',
    'Genteng / Atap',
    'Plafon',
    'Pipa',
  ];

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

  static double _round1(double value) {
    return (value * 10).round() / 10;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  static String _formatVolume(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  static String _rupiah(num value) {
    final String raw = value.round().toString();
    final StringBuffer buffer = StringBuffer();

    int counter = 0;

    for (int i = raw.length - 1; i >= 0; i--) {
      buffer.write(raw[i]);
      counter++;

      if (counter == 3 && i != 0) {
        buffer.write('.');
        counter = 0;
      }
    }

    return 'Rp${buffer.toString().split('').reversed.join()}';
  }

  static String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
      final String lower = part.toLowerCase();

      if (lower == 'pvc' || lower == 'sni' || lower == 'grc') {
        return lower.toUpperCase();
      }

      if (lower.isEmpty) {
        return lower;
      }

      return lower[0].toUpperCase() + lower.substring(1);
    }).join(' ');
  }

  static String _normalizeSatuan(String value) {
    if (value == 'mÂ²' || value == 'mÃ‚Â²' || value == 'm2') {
      return 'm2';
    }

    if (value == 'mÂ³' || value == 'mÃ‚Â³' || value == 'm3') {
      return 'm3';
    }

    return value;
  }
}

class _PdfRabItem {
  final String namaMaterial;
  final String kategori;
  final String satuan;
  final double volume;
  final double hargaSatuan;

  const _PdfRabItem({
    required this.namaMaterial,
    required this.kategori,
    required this.satuan,
    required this.volume,
    required this.hargaSatuan,
  });

  double get totalHarga => volume * hargaSatuan;
}
'''

path.write_text(code, encoding="utf-8")

print("PATCH BERHASIL: Export PDF sekarang memuat estimasi RAB, harga satuan, subtotal, dan total.")
