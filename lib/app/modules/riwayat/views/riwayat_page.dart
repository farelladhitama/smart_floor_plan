import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_floor_plan/app/widgets/professional_floor_plan_painter.dart';
import 'package:smart_floor_plan/app/widgets/floor_plan_asset_overlay.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/services/floor_plan_pdf_exporter.dart';
import 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';
import 'package:smart_floor_plan/app/modules/rab/views/rab_page.dart';

import '../controllers/riwayat_controller.dart';
import 'package:smart_floor_plan/app/services/pdf_download_history_service.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  static const Color navy = Color(0xFF1E3A5F);
static const Color orange = Color(0xFFF28C28);
static const Color background = Color(0xFFF8F9FB);
static const Color softGrey = Color(0xFFF1F3F6);

  RiwayatController get controller {
    if (Get.isRegistered<RiwayatController>()) {
      return Get.find<RiwayatController>();
    }

    return Get.put(RiwayatController());
  }

  @override
Widget build(BuildContext context) {
  final RiwayatController riwayatController = controller;

  return Scaffold(
    backgroundColor: background,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final bool isWide = constraints.maxWidth > 720;
          final double maxWidth =
              isWide ? 680 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: RefreshIndicator(
                onRefresh: riwayatController.loadHistories,
                color: orange,
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    isMobile ? 18 : 24,
                    isMobile ? 16 : 24,
                    110,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        isMobile: isMobile,
                        controller: riwayatController,
                      ),

                      const SizedBox(height: 22),

                      _buildSummary(
                        isMobile: isMobile,
                        controller: riwayatController,
                      ),

                      const SizedBox(height: 20),

                      Obx(() {
                        if (riwayatController
                            .isLoading.value) {
                          return const SizedBox(
                            height: 260,
                            child: Center(
                              child:
                                  CircularProgressIndicator(
                                color: orange,
                              ),
                            ),
                          );
                        }

                        if (riwayatController
                            .histories.isEmpty) {
                          return _buildEmptyBox(
                              isMobile);
                        }

                        return Column(
                          children:
                              riwayatController.histories
                                  .map((item) {
                            return _buildHistoryCard(
                              isMobile: isMobile,
                              item: item,
                              controller:
                                  riwayatController,
                            );
                          }).toList(),
                        );
                      }),

                      const SizedBox(height: 12),

                      _buildInfoBox(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildHeader({
  required bool isMobile,
  required RiwayatController controller,
}) {
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Desain',
              style: TextStyle(
                color: navy,
                fontSize:
                    isMobile ? 26 : 30,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Daftar rancangan denah yang tersimpan di Supabase.',
              style: TextStyle(
                color: Colors.black54,
                fontSize:
                    isMobile ? 13.5 : 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),

      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              controller.loadHistories(),
          borderRadius:
              BorderRadius.circular(18),
          child: Container(
            width: isMobile ? 48 : 54,
            height: isMobile ? 48 : 54,
            decoration: BoxDecoration(
              color: navy,
              borderRadius:
                  BorderRadius.circular(
                      18),
              boxShadow: [
                BoxShadow(
                  color: navy.withOpacity(
                      0.18),
                  blurRadius: 14,
                  offset:
                      const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size:
                  isMobile ? 25 : 28,
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildSummary({
    required bool isMobile,
    required RiwayatController controller,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 46 : 52,
            height: isMobile ? 46 : 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.folder_copy_rounded,
              color: Colors.white,
              size: isMobile ? 25 : 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.histories.length} Desain Tersimpan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Data riwayat gabungan dari tabel floor_plans dan scan_floor_plans.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMobile ? 12.5 : 14,
                      height: 1.4,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required bool isMobile,
    required Map<String, dynamic> item,
    required RiwayatController controller,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
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
                width: isMobile ? 52 : 58,
                height: isMobile ? 52 : 58,
                decoration: BoxDecoration(
                  color: softGrey,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  color: navy,
                  size: isMobile ? 28 : 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.getTitle(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: navy,
                        fontSize: isMobile ? 17 : 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      controller.getSubtitle(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: isMobile ? 12.5 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.getDate(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black38,
                        fontSize: isMobile ? 11.5 : 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _smallInfoChip(
                  icon: Icons.meeting_room_rounded,
                  text: '${controller.getRoomCount(item)} ruang',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _smallInfoChip(
                  icon: Icons.square_foot_rounded,
                  text: controller.getAreaText(item),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _smallInfoChip(
            icon: Icons.receipt_long_rounded,
            text: 'Buka LIHAT RAB untuk total material',
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Detail',
                  icon: Icons.visibility_rounded,
                  isPrimary: true,
                  onTap: () => _showDetailBottomSheet(
                    item: item,
                    controller: controller,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  label: 'Edit',
                  icon: Icons.edit_rounded,
                  isPrimary: false,
                  onTap: () => controller.openEdit(item),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                child: _buildIconButton(
                  icon: Icons.delete_rounded,
                  onTap: () => controller.deleteHistory(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDenahPreview({
    required bool isMobile,
    required Map<String, dynamic> item,
  }) {
    final List<Map<String, dynamic>> rooms = _parsePreviewRooms(item);
    final double previewHeight = isMobile ? 155 : 175;

    if (rooms.isEmpty) {
      return Container(
        width: double.infinity,
        height: previewHeight,
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withOpacity(0.16),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              color: navy.withOpacity(0.35),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              'Preview denah belum tersedia',
              style: TextStyle(
                color: navy.withOpacity(0.55),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }

    double maxX = 1;
    double maxY = 1;

    for (final room in rooms) {
      final double right = room['x'] + room['width'];
      final double bottom = room['y'] + room['height'];

      if (right > maxX) {
        maxX = right;
      }

      if (bottom > maxY) {
        maxY = bottom;
      }
    }

    return Container(
      width: double.infinity,
      height: previewHeight,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: orange.withOpacity(0.20),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double canvasWidth =
              constraints.maxWidth <= 0 ? 1 : constraints.maxWidth;
          final double canvasHeight =
              constraints.maxHeight <= 0 ? 1 : constraints.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: navy.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              ...rooms.map((room) {
                final double x = room['x'];
                final double y = room['y'];
                final double width = room['width'];
                final double height = room['height'];
                final String nama = room['nama'];

                final double maxLeft = canvasWidth > 24 ? canvasWidth - 24 : 0;
                final double maxTop = canvasHeight > 24 ? canvasHeight - 24 : 0;

                final double left =
                    ((x / maxX) * canvasWidth).clamp(0.0, maxLeft).toDouble();
                final double top =
                    ((y / maxY) * canvasHeight).clamp(0.0, maxTop).toDouble();

                double roomWidth =
                    ((width / maxX) * canvasWidth).clamp(28.0, canvasWidth).toDouble();
                double roomHeight =
                    ((height / maxY) * canvasHeight).clamp(24.0, canvasHeight).toDouble();

                final double availableWidth = canvasWidth - left;
                final double availableHeight = canvasHeight - top;

                if (roomWidth > availableWidth) {
                  roomWidth = availableWidth;
                }

                if (roomHeight > availableHeight) {
                  roomHeight = availableHeight;
                }

                return Positioned(
                  left: left,
                  top: top,
                  width: roomWidth,
                  height: roomHeight,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: orange.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: orange.withOpacity(0.70),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: navy,
                        fontSize: isMobile ? 9.5 : 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _parsePreviewRooms(Map<String, dynamic> item) {
    final List<dynamic> rawRooms = _readRoomsJson(item);
    final List<Map<String, dynamic>> parsedRooms = <Map<String, dynamic>>[];

    for (final dynamic rawRoom in rawRooms) {
      if (rawRoom is! Map) {
        continue;
      }

      final double x = _toDouble(rawRoom['x']);
      final double y = _toDouble(rawRoom['y']);
      final double width = _toDouble(rawRoom['width']);
      final double height = _toDouble(rawRoom['height']);

      if (width <= 0 || height <= 0) {
        continue;
      }

      parsedRooms.add({
        'nama': _readRoomName(rawRoom),
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      });
    }

    return parsedRooms;
  }

  List<dynamic> _readRoomsJson(Map<String, dynamic> item) {
    final dynamic rawRooms = item['rooms_json'];

    if (rawRooms is List) {
      return rawRooms;
    }

    if (rawRooms is String && rawRooms.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(rawRooms);

        if (decoded is List) {
          return decoded;
        }
      } catch (_) {}
    }

    return <dynamic>[];
  }

  String _readRoomName(Map<dynamic, dynamic> room) {
    final dynamic nama = room['nama'] ?? room['name'] ?? room['title'];

    if (nama == null || nama.toString().trim().isEmpty) {
      return 'Ruang';
    }

    return nama.toString();
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
  void _showDetailBottomSheet({
    required Map<String, dynamic> item,
    required RiwayatController controller,
  }) {
    Get.bottomSheet(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Detail Denah',
                  style: TextStyle(
                    color: navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                _detailRow('Judul', controller.getTitle(item)),
                _detailRow('Ukuran', controller.getSubtitle(item)),
                _detailRow('Ruangan', '${controller.getRoomCount(item)} ruang'),
                _detailRow('Total Luas', controller.getAreaText(item)),
                _detailRow('RAB Material', 'Tekan LIHAT RAB untuk total terbaru'),
                _detailRow('Tanggal', controller.getDate(item)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showFullDenahSheet(item);
                    },
                    icon: const Icon(Icons.map_rounded),
                    label: const Text(
                      'LIHAT DENAH',
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _openRabDirect(item),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text(
                      'LIHAT RAB',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (Get.isBottomSheetOpen == true) {
                        Get.back();
                      }

                      await Future.delayed(const Duration(milliseconds: 250));
                      await _exportPdfWithSameDenahRender(item);
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
                const SizedBox(height: 12),
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
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _openRabDirect(Map<String, dynamic> item) {
    final double luas = _readRabArea(item);
    final double lebar = _readNumberRab(item['lebar_lahan']);
    final double panjang = _readNumberRab(item['panjang_lahan']);
    final Map<String, String> selectedMaterials = _selectedMaterialsFromHistory(item);
    final String material = selectedMaterials['Material Dinding'] ??
        (item['material_dinding'] ?? item['material_dinding'] ?? 'batu bata merah').toString();

        

    final Map<String, dynamic> rabArgs = {
  'luasBangunan': luas,
  'totalLuas': luas,
  'total_luas': luas,
  'inputLuas': luas,
  'inputLebarRumah': lebar,
  'inputPanjangRumah': panjang,
  'lebar_lahan': lebar,
  'panjang_lahan': panjang,
  'material': material,
  'selectedMaterials': selectedMaterials,
  'rooms_json': item['rooms_json'],

  'jenisTukang': item['jenis_tukang'],
};

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    if (Get.isRegistered<RabController>()) {
      Get.delete<RabController>(force: true);
    }

    Get.to(
      () => const RabPage(),
      arguments: rabArgs,
      binding: BindingsBuilder(() {
        Get.put(RabController());
      }),
    );
  }

  Map<String, String> _selectedMaterialsFromHistory(Map<String, dynamic> item) {
    final Map<String, String> result = <String, String>{};

    void add(String kategori, dynamic value) {
      final String materialName = (value ?? '').toString().trim();

      if (materialName.isNotEmpty) {
        result[kategori] = materialName;
      }
    }

    add('Material Dinding', item['material_dinding']);
    add('Semen', item['material_semen']);
    add('Pasir', item['material_pasir']);
    add('Keramik Lantai', item['material_keramik_lantai']);
    add('Cat Dinding', item['material_cat_dinding']);
    add('Genteng / Atap', item['material_genteng_atap']);
    add('Plafon', item['material_plafon']);
    add('Pipa', item['material_pipa']);

    if (!result.containsKey('Material Dinding')) {
      result['Material Dinding'] = 'batu bata merah';
    }

    return result;
  }

  double _readRabArea(Map<String, dynamic> item) {
    final double totalLuas = _readNumberRab(
      item['total_luas'] ??
          item['totalLuas'] ??
          item['luasBangunan'] ??
          item['luas_bangunan'] ??
          item['inputLuas'],
    );

    if (totalLuas > 0) {
      return totalLuas;
    }

    final double lebar = _readNumberRab(item['lebar_lahan']);
    final double panjang = _readNumberRab(item['panjang_lahan']);

    if (lebar > 0 && panjang > 0) {
      return lebar * panjang;
    }

    return 100;
  }

  double _readNumberRab(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullDenahSheet(Map<String, dynamic> item) {
    Get.bottomSheet(
      Container(
        width: double.infinity,
        height: Get.height * 0.88,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Denah Tersimpan',
                style: TextStyle(
                  color: navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Preview denah dari data rooms_json Supabase',
                style: TextStyle(
                  color: navy.withOpacity(0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: orange.withOpacity(0.22),
                    ),
                  ),
                  child: InteractiveViewer(
                    minScale: 0.7,
                    maxScale: 4.0,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: _buildDenahPreviewCanvas(item),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
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
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _exportPdfWithSameDenahRender(Map<String, dynamic> item) async {
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

    await PdfDownloadHistoryService.record(
      item: item,
    );
  }

  Widget _buildDenahPreviewCanvas(Map<String, dynamic> item) {
    final List<RoomModel> rooms = _historyRoomsAsModel(item);
    final double landWidth = _readLandWidth(item);
    final double landLength = _readLandLength(item);

    if (rooms.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFDDE6EF),
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 54,
                  color: Color(0xFF6B7A90),
                ),
                SizedBox(height: 12),
                Text(
                  'Data ruangan belum tersedia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102033),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Data rooms_json pada riwayat kosong.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7A90),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          border: Border.all(
            color: const Color(0xFFDDE6EF),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: ProfessionalFloorPlanPainter(
                  rooms: rooms,
                  inputLebarRumah: landWidth,
                  inputPanjangRumah: landLength,
                  title: 'SMARTFLOORPLAN RENDER',
                ),
              ),
            ),
            Positioned.fill(
              child: FloorPlanAssetOverlay(
                rooms: rooms,
                landWidth: landWidth,
                landLength: landLength,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<RoomModel> _historyRoomsAsModel(Map<String, dynamic> item) {
    final List<Map<String, dynamic>> rawRooms = _parsePreviewRooms(item);

    return rawRooms.map((room) {
      return RoomModel(
        nama: (room['nama'] ?? room['name'] ?? 'Ruang').toString(),
        x: _toDouble(room['x']),
        y: _toDouble(room['y']),
        width: _toDouble(room['width']),
        height: _toDouble(room['height']),
        category: (room['category'] ?? 'room').toString(),
        doorSide: (room['doorSide'] ?? room['door_side'] ?? 'bottom').toString(),
        isOutdoor: room['isOutdoor'] == true || room['is_outdoor'] == true,
      );
    }).toList();
  }

  double _readLandWidth(Map<String, dynamic> item) {
    final double value = _readNumberRab(
      item['lebar_lahan'] ??
          item['inputLebarRumah'] ??
          item['landWidth'] ??
          item['lebarRumah'] ??
          item['lebarLahan'],
    );

    if (value > 0) {
      return value;
    }

    return 8;
  }

  double _readLandLength(Map<String, dynamic> item) {
    final double value = _readNumberRab(
      item['panjang_lahan'] ??
          item['inputPanjangRumah'] ??
          item['landLength'] ??
          item['panjangRumah'] ??
          item['panjangLahan'],
    );

    if (value > 0) {
      return value;
    }

    return 10;
  }

  Color _roomColor(String nama) {
    final String lower = nama.toLowerCase();

    if (lower.contains('taman') ||
        lower.contains('court') ||
        lower.contains('teras')) {
      return const Color(0xFFB8D9A8);
    }

    if (lower.contains('km') ||
        lower.contains('wc') ||
        lower.contains('mandi')) {
      return const Color(0xFFA9E4EE);
    }

    if (lower.contains('tidur') || lower.contains('kt')) {
      return const Color(0xFFE5B173);
    }

    if (lower.contains('dapur') || lower.contains('makan')) {
      return const Color(0xFFEAD8A8);
    }

    if (lower.contains('carport') || lower.contains('cuci')) {
      return const Color(0xFFE6E6E6);
    }

    return const Color(0xFFF2E7C9);
  }
  Widget _smallInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: orange,
            size: 17,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 18,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? navy : background,
          foregroundColor: isPrimary ? Colors.white : navy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.09),
          foregroundColor: Colors.red,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Icon(
          icon,
          size: 21,
        ),
      ),
    );
  }

  Widget _buildEmptyBox(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            color: navy.withOpacity(0.35),
            size: 58,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada riwayat',
            style: TextStyle(
              color: navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Generate atau scan denah lalu tekan Simpan Denah agar muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: orange.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: orange,
            size: isMobile ? 22 : 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Riwayat ini mengambil data gabungan dari generate biasa dan scan denah. Database tetap dipisah, tetapi tampilannya jadi satu.',
              style: TextStyle(
                color: navy.withOpacity(0.75),
                fontSize: isMobile ? 12.5 : 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}





