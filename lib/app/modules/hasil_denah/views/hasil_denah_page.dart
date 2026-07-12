import 'package:smart_floor_plan/app/routes/app_routes.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/modules/edit_denah/views/edit_denah_page.dart';
import 'package:smart_floor_plan/app/modules/hasil_denah/controllers/hasil_denah_controller.dart';
import 'package:smart_floor_plan/app/widgets/floor_plan_asset_overlay.dart';
import 'package:smart_floor_plan/app/widgets/professional_floor_plan_painter.dart';
import 'package:smart_floor_plan/app/modules/riwayat/views/riwayat_page.dart';
import 'package:smart_floor_plan/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:smart_floor_plan/app/modules/dashboard/views/dashboard_page.dart';

class HasilDenahPage extends StatefulWidget {
  final List<RoomModel> rooms;
  final dynamic inputLebarRumah;
  final dynamic inputPanjangRumah;
  final dynamic floorPlanId;
  final dynamic material;
  final dynamic jumlahKamar;
  final dynamic ruangTambahan;
  final dynamic totalLuas;
final Map<String, String>? selectedMaterials;
final String? jenisTukang;
  

  const HasilDenahPage({
  super.key,
  this.rooms = const [],
  this.inputLebarRumah,
  this.inputPanjangRumah,
  this.floorPlanId,
  this.material,
  this.jumlahKamar,
  this.ruangTambahan,

  this.totalLuas,
  this.selectedMaterials,
  this.jenisTukang,
});

  @override
  State<HasilDenahPage> createState() => _HasilDenahPageState();
}

class _HasilDenahPageState extends State<HasilDenahPage> {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color bg = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF102033);
  static const Color textSoft = Color(0xFF6B7A90);

  // ==================== LAND SIZE INFO ====================
  Widget _buildLandSizeInfo() {
    double lebar = 0;
    double panjang = 0;
    
    // Coba dari widget
    if (widget.inputLebarRumah != null && widget.inputPanjangRumah != null) {
      lebar = _toDouble(widget.inputLebarRumah, fallback: 0);
      panjang = _toDouble(widget.inputPanjangRumah, fallback: 0);
    } else {
      // Coba dari Get.arguments
      final args = Get.arguments;
      if (args is Map) {
        lebar = _toDouble(args['lebar_lahan'] ?? args['inputLebarRumah'] ?? 0, fallback: 0);
        panjang = _toDouble(args['panjang_lahan'] ?? args['inputPanjangRumah'] ?? 0, fallback: 0);
      }
    }
    
    // Jika tidak ada ukuran, jangan tampilkan
    if (lebar <= 0 || panjang <= 0) {
      return const SizedBox.shrink();
    }
    
    final luas = lebar * panjang;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB3D9F7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.straighten_rounded,
            color: Color(0xFF0D1B2A),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Ukuran Lahan: ${lebar.toStringAsFixed(1)} m × ${panjang.toStringAsFixed(1)} m  |  Luas: ${luas.toStringAsFixed(1)} m²',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF0D1B2A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HasilDenahController>(
      builder: (controller) {
        final List<RoomModel> rooms = _getRooms(controller);
        final double landWidth = _getLandWidth(controller);
        final double landLength = _getLandLength(controller);

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: navy,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
            title: const Text(
              'Hasil Denah',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 86),
            child: FloatingActionButton.extended(
              heroTag: 'rab_hasil_denah',
              backgroundColor: const Color(0xFFE47B3E),
              foregroundColor: Colors.white,
              elevation: 8,
              onPressed: () {
  Get.toNamed(
  AppRoutes.rab,
  arguments: {
    'luasBangunan': widget.totalLuas ??
        (widget.inputLebarRumah * widget.inputPanjangRumah),

    'estimasi_rab': controller.estimasiRab,

    'inputLebarRumah': widget.inputLebarRumah,
    'inputPanjangRumah': widget.inputPanjangRumah,

    'material': widget.material,
    'jumlahKamar': widget.jumlahKamar,
    'ruangTambahan': widget.ruangTambahan,

    'jenisTukang': widget.jenisTukang,
    'selectedMaterials': widget.selectedMaterials,

    'rooms': widget.rooms,
  },
);
},
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text(
                'LIHAT RAB',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreviewCard(
                          rooms: rooms,
                          landWidth: landWidth,
                          landLength: landLength,
                        ),
                        const SizedBox(height: 18),
                        _buildRoomSummary(
                          rooms: rooms,
                          landWidth: landWidth,
                          landLength: landLength,
                        ),
                        const SizedBox(height: 92),
                      ],
                    ),
                  ),
                ),
                _buildBottomAction(
                  controller: controller,
                  rooms: rooms,
                  landWidth: landWidth,
                  landLength: landLength,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewCard({
    required List<RoomModel> rooms,
    required double landWidth,
    required double landLength,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE3E9F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewHeader(),
          const SizedBox(height: 10),
          // ✅ TAMBAHKAN INI - TAMPILAN UKURAN LAHAN
          _buildLandSizeInfo(),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 560,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                border: Border.all(
                  color: const Color(0xFFDDE6EF),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: rooms.isEmpty
                  ? _buildEmptyPreview()
                  : InteractiveViewer(
                      minScale: 0.75,
                      maxScale: 3.2,
                      boundaryMargin: const EdgeInsets.all(80),
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
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Cubit atau scroll untuk zoom  |  geser untuk melihat detail',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: textSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preview Arsitektural',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Denah rendered dengan furniture, taman, pintu, dan material',
                style: TextStyle(
                  fontSize: 12.5,
                  color: textSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEFE6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'SMART PLAN',
            style: TextStyle(
              color: orange,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPreview() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 54,
              color: textSoft,
            ),
            SizedBox(height: 12),
            Text(
              'Data ruangan belum tersedia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Silakan generate denah terlebih dahulu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSoft,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSummary({
    required List<RoomModel> rooms,
    required double landWidth,
    required double landLength,
  }) {
    final double landArea = landWidth * landLength;

    final double buildingArea = rooms.fold<double>(
      0,
      (total, room) {
        if (_isOutdoorRoom(room)) return total;
        return total + (room.width * room.height);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Legenda Ruang',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoBox(
                icon: Icons.meeting_room_rounded,
                label: '${rooms.length} Ruang',
                subtitle: 'Total ruang',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoBox(
                icon: Icons.square_foot_rounded,
                label: '${landArea.toStringAsFixed(1)} m²',
                subtitle: 'Luas lahan',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoBox(
                icon: Icons.home_rounded,
                label: '${buildingArea.toStringAsFixed(1)} m²',
                subtitle: 'Luas ruang',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE3E9F0),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < rooms.length; i++)
                _roomRow(
                  room: rooms[i],
                  isLast: i == rooms.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE3E9F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: orange,
            size: 22,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textSoft,
              fontSize: 10.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomRow({
    required RoomModel room,
    required bool isLast,
  }) {
    final double area = room.width * room.height;

    return Container(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 10,
        top: isLast ? 0 : 0,
      ),
      margin: EdgeInsets.only(
        bottom: isLast ? 0 : 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : const Color(0xFFE8EDF3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _roomIcon(room),
              color: orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              room.nama,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
          ),
          Text(
            '${area.toStringAsFixed(1)} m2',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: textSoft,
            ),
          ),
        ],
      ),
    );
  }

  IconData _roomIcon(RoomModel room) {
    final String name = room.nama.toLowerCase();
    final String category = room.category.toLowerCase();

    if (name.contains('tidur') || category == 'bedroom') {
      return Icons.bed_rounded;
    }

    if (name.contains('mandi') || name.contains('wc') || name.contains('km')) {
      return Icons.bathtub_rounded;
    }

    if (name.contains('dapur')) return Icons.kitchen_rounded;
    if (name.contains('makan')) return Icons.dining_rounded;
    if (name.contains('carport')) return Icons.directions_car_rounded;
    if (name.contains('taman') || name.contains('inner court')) {
      return Icons.park_rounded;
    }

    return Icons.meeting_room_rounded;
  }

  Widget _buildBottomAction({
    required HasilDenahController controller,
    required List<RoomModel> rooms,
    required double landWidth,
    required double landLength,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: rooms.isEmpty
                    ? null
                    : () async {
                        final dynamic result = await Get.to(
                          () => EditDenahPage(
                            initialRooms: rooms,
                            inputLebarRumah: landWidth,
                            inputPanjangRumah: landLength,
                          ),
                        );

                        if (result is List<RoomModel> && result.isNotEmpty) {
                          _replaceControllerRooms(controller, result);

                          Get.snackbar(
                            'Berhasil',
                            'Hasil edit denah berhasil diterapkan.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: navy,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(16),
                            borderRadius: 16,
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text(
                  'EDIT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: rooms.isEmpty
                    ? null
                    : () async {
                        await _callSave(controller);
                      },
                icon: const Icon(Icons.save_rounded, size: 20),
                label: const Text(
                  'SIMPAN DENAH',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOutdoorRoom(RoomModel room) {
    final String name = room.nama.toLowerCase();
    final String category = room.category.toLowerCase();

    return category == 'outdoor' ||
        name.contains('taman') ||
        name.contains('carport') ||
        name.contains('teras') ||
        name.contains('inner court') ||
        name.contains('halaman');
  }

  List<RoomModel> _getRooms(dynamic controller) {
    final dynamic raw = _readRawRooms(controller);
    final dynamic value = _unwrap(raw);

    if (value is List<RoomModel>) {
      return value;
    }

    if (value is Iterable) {
      try {
        return value.cast<RoomModel>().toList();
      } catch (_) {
        return <RoomModel>[];
      }
    }

    return <RoomModel>[];
  }

  dynamic _readRawRooms(dynamic controller) {
    if (widget.rooms.isNotEmpty) {
      return widget.rooms;
    }

    return _tryRead(() => controller.rooms) ??
        _tryRead(() => controller.roomList) ??
        _tryRead(() => controller.generatedRooms) ??
        _tryRead(() => controller.hasilRooms) ??
        _tryRead(() => controller.denahRooms) ??
        _tryRead(() {
          final dynamic args = Get.arguments;
          if (args is Map) return args['rooms'];
          return null;
        });
  }

  double _getLandWidth(dynamic controller) {
    if (widget.inputLebarRumah != null) {
      return _toDouble(widget.inputLebarRumah, fallback: 8);
    }

    return _toDouble(
      _tryRead(() => controller.inputLebarRumah) ??
          _tryRead(() => controller.landWidth) ??
          _tryRead(() => controller.lebarRumah) ??
          _tryRead(() => controller.lebarLahan) ??
          _tryRead(() {
            final dynamic args = Get.arguments;
            if (args is Map) {
              return args['inputLebarRumah'] ??
                  args['landWidth'] ??
                  args['lebarRumah'] ??
                  args['lebarLahan'];
            }
            return null;
          }),
      fallback: 8,
    );
  }

  double _getLandLength(dynamic controller) {
    if (widget.inputPanjangRumah != null) {
      return _toDouble(widget.inputPanjangRumah, fallback: 10);
    }

    return _toDouble(
      _tryRead(() => controller.inputPanjangRumah) ??
          _tryRead(() => controller.landLength) ??
          _tryRead(() => controller.panjangRumah) ??
          _tryRead(() => controller.panjangLahan) ??
          _tryRead(() {
            final dynamic args = Get.arguments;
            if (args is Map) {
              return args['inputPanjangRumah'] ??
                  args['landLength'] ??
                  args['panjangRumah'] ??
                  args['panjangLahan'];
            }
            return null;
          }),
      fallback: 10,
    );
  }

  dynamic _unwrap(dynamic value) {
    try {
      return value.value;
    } catch (_) {
      return value;
    }
  }

  dynamic _tryRead(dynamic Function() reader) {
    try {
      return reader();
    } catch (_) {
      return null;
    }
  }

  double _toDouble(dynamic value, {required double fallback}) {
    final dynamic unwrapped = _unwrap(value);

    if (unwrapped is num) {
      return unwrapped.toDouble();
    }

    if (unwrapped is String) {
      return double.tryParse(unwrapped) ?? fallback;
    }

    return fallback;
  }

  bool _replaceControllerRooms(dynamic controller, List<RoomModel> editedRooms) {
    final dynamic raw = _readRawRooms(controller);

    try {
      raw.assignAll(editedRooms);
      _refreshController(controller);
      return true;
    } catch (_) {}

    try {
      raw.clear();
      raw.addAll(editedRooms);
      _refreshController(controller);
      return true;
    } catch (_) {}

    try {
      raw.value = editedRooms;
      _refreshController(controller);
      return true;
    } catch (_) {}

    try {
      controller.rooms = editedRooms;
      _refreshController(controller);
      return true;
    } catch (_) {}

    return false;
  }

  void _refreshController(dynamic controller) {
    try {
      controller.update();
    } catch (_) {}

    try {
      controller.rooms.refresh();
    } catch (_) {}
  }

  Future<void> _callSave(dynamic controller) async {
    final List<RoomModel> saveRooms = _getRooms(controller);
    final double saveLandWidth = _getLandWidth(controller);
    final double saveLandLength = _getLandLength(controller);

    if (saveRooms.isEmpty) {
      Get.snackbar(
        'Gagal Simpan',
        'Tidak ada data ruangan yang dapat disimpan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    int safeInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final String? saveFloorPlanId =
        widget.floorPlanId == null ? null : widget.floorPlanId.toString();

    final String saveMaterial =
        widget.material == null ? 'Batu Bata' : widget.material.toString();

    final int saveJumlahKamar = safeInt(widget.jumlahKamar, 1);

    final List<String> saveRuangTambahan = widget.ruangTambahan is List
        ? (widget.ruangTambahan as List).map((item) => item.toString()).toList()
        : <String>[];

    try {
      controller.resetRooms(saveRooms);
    } catch (_) {
      try {
        controller.currentRooms.assignAll(saveRooms);
      } catch (_) {}
    }

    try {
      controller.setMetadata(
        inputFloorPlanId: saveFloorPlanId,
        inputLebarRumah: saveLandWidth,
        inputPanjangRumah: saveLandLength,
        inputJumlahKamar: saveJumlahKamar,
        inputMaterial: saveMaterial,
        inputRuangTambahan: saveRuangTambahan,
      );
    } catch (_) {
      try {
        controller.floorPlanId = saveFloorPlanId;
      } catch (_) {}

      try {
        controller.landWidth = saveLandWidth;
      } catch (_) {}

      try {
        controller.landLength = saveLandLength;
      } catch (_) {}

      try {
        controller.jumlahKamar = saveJumlahKamar;
      } catch (_) {}

      try {
        controller.material = saveMaterial;
      } catch (_) {}

      try {
        controller.ruangTambahan = saveRuangTambahan;
      } catch (_) {}
    }

    try {
      controller.update();
    } catch (_) {}

    try {
await controller.simpanDenah();

Get.offAllNamed(
  AppRoutes.dashboard,
  arguments: 2,
);


} catch (error) {
      Get.snackbar(
        'Gagal Simpan',
        'Terjadi kesalahan: $error',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<bool> _tryCallAsync(dynamic Function() caller) async {
    try {
      final dynamic result = caller();

      if (result is Future) {
        await result;
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}