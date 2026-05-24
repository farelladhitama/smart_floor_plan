import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/edit_denah/controllers/edit_denah_controller.dart';

class EditDenahPage extends GetView<EditDenahController> {
  final List<RoomModel> initialRooms;
  final double landWidth;
  final double landLength;

  const EditDenahPage({
    super.key,
    required this.initialRooms,
    required this.landWidth,
    required this.landLength,
  });

  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF1B263B);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color mutedText = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    controller.initialisePlan(
      rooms: initialRooms,
      inputLandWidth: landWidth,
      inputLandLength: landLength,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Edit Denah',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: navy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 760;

            if (isMobile) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
                child: Column(
                  children: [
                    _buildIntroPanel(compact: true),
                    const SizedBox(height: 14),
                    _buildEditorCard(
                      mobile: true,
                      canvasHeight: 530,
                    ),
                    const SizedBox(height: 14),
                    _buildSelectedRoomPanel(),
                  ],
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 306,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildIntroPanel(compact: false),
                              const SizedBox(height: 14),
                              _buildSelectedRoomPanel(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _buildEditorCard(
                          mobile: false,
                          canvasHeight: constraints.maxHeight - 34,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildIntroPanel({required bool compact}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: compact
          ? Row(
              children: [
                _buildIntroIcon(),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editor Blueprint',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pilih satu ruang untuk mulai mengedit.',
                        style: TextStyle(
                          color: Color(0xFFC4CDD7),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroIcon(),
                const SizedBox(height: 15),
                const Text(
                  'Editor Blueprint',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Pilih satu ruangan pada blueprint, lalu edit dari panel kontrol agar tampilan tidak tertutup tombol.',
                  style: TextStyle(
                    color: Color(0xFFC4CDD7),
                    fontSize: 12.5,
                    height: 1.48,
                  ),
                ),
                const SizedBox(height: 18),
                _buildGuideItem(
                  icon: Icons.touch_app_rounded,
                  label: 'Pilih',
                  detail: 'Tekan ruangan',
                ),
                const SizedBox(height: 8),
                _buildGuideItem(
                  icon: Icons.open_with_rounded,
                  label: 'Geser',
                  detail: 'Drag ruang terpilih',
                ),
                const SizedBox(height: 8),
                _buildGuideItem(
                  icon: Icons.tune_rounded,
                  label: 'Resize',
                  detail: 'Gunakan tombol panel',
                ),
                const SizedBox(height: 8),
                _buildGuideItem(
                  icon: Icons.rotate_90_degrees_ccw_rounded,
                  label: 'Rotasi',
                  detail: 'Putar 90 derajat',
                ),
              ],
            ),
    );
  }

  Widget _buildIntroIcon() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.design_services_rounded,
        color: orange,
        size: 31,
      ),
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String label,
    required String detail,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: orange, size: 18),
          const SizedBox(width: 9),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              detail,
              style: const TextStyle(
                color: Color(0xFFC4CDD7),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorCard({
    required bool mobile,
    required double canvasHeight,
  }) {
    return Container(
      width: double.infinity,
      height: canvasHeight,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.045),
            blurRadius: 17,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Layout Arsitektural',
                      style: TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Klik ruang untuk memilih • drag untuk menggeser',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  'EDIT MODE',
                  style: TextStyle(
                    color: orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FA),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final _PlanViewport viewport = _PlanViewport.calculate(
                      size: Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                      landWidth: landWidth,
                      landLength: landLength,
                    );

                    return Obx(() {
                      final List<RoomModel> rooms =
                          controller.listRuangan.toList();
                      final int selectedIndex =
                          controller.selectedRoomIndex.value;

                      return Stack(
                        children: [
                          CustomPaint(
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                            painter: _EditorCanvasPainter(
                              viewport: viewport,
                              landWidth: landWidth,
                              landLength: landLength,
                            ),
                          ),
                          ...rooms.asMap().entries.map((entry) {
                            return _buildRoomOnCanvas(
                              room: entry.value,
                              index: entry.key,
                              selected: selectedIndex == entry.key,
                              viewport: viewport,
                            );
                          }),
                        ],
                      );
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildRoomOnCanvas({
    required RoomModel room,
    required int index,
    required bool selected,
    required _PlanViewport viewport,
  }) {
    final double width = room.width * viewport.scale;
    final double height = room.height * viewport.scale;

    return Positioned(
      left: viewport.origin.dx + (room.x * viewport.scale),
      top: viewport.origin.dy + (room.y * viewport.scale),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => controller.selectRoom(index),
                onPanStart: (_) => controller.selectRoom(index),
                onPanUpdate: (details) {
                  controller.updatePosition(
                    index: index,
                    deltaXMeter: details.delta.dx / viewport.scale,
                    deltaYMeter: details.delta.dy / viewport.scale,
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: CustomPaint(
                    painter: _EditableRoomPainter(
                      room: room,
                      selected: selected,
                    ),
                  ),
                ),
              ),
            ),

            // Handle resize hanya tampil pada ruangan yang sedang dipilih.
            if (selected)
              Positioned(
                right: 6,
                bottom: 6,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    controller.resizeSelectedByDrag(
                      index: index,
                      deltaWidthMeter: details.delta.dx / viewport.scale,
                      deltaHeightMeter: details.delta.dy / viewport.scale,
                    );
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: _buildResizeHandle(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: orange,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Colors.white,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: orange.withValues(alpha: 0.32),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.open_in_full_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
  Widget _buildSelectedRoomPanel() {
    return Obx(() {
      final RoomModel? room = controller.selectedRoom;

      if (room == null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: orange,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pilih Ruangan',
                style: TextStyle(
                  color: navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tekan salah satu ruang pada denah untuk menampilkan kontrol edit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: orange.withValues(alpha: 0.36),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: orange.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _roomColor(room),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: borderColor),
                  ),
                  child: const Icon(
                    Icons.meeting_room_rounded,
                    color: navy,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ruang Dipilih',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        room.nama,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Batalkan pilihan',
                  onPressed: controller.clearSelection,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: mutedText,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _selectedInfoTile(
                    label: 'Ukuran',
                    value:
                        '${room.width.toStringAsFixed(1)} × ${room.height.toStringAsFixed(1)} m',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _selectedInfoTile(
                    label: 'Luas',
                    value: '${room.area.toStringAsFixed(1)} m²',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'Geser Presisi',
              style: TextStyle(
                color: navy,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Center(child: _buildMovementPad()),
            const SizedBox(height: 15),
            const Text(
              'Ubah Ukuran',
              style: TextStyle(
                color: navy,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            _buildSizeControl(
              title: 'Lebar',
              value: '${room.width.toStringAsFixed(2)} m',
              onMinus: () => controller.adjustSelectedWidth(-0.25),
              onPlus: () => controller.adjustSelectedWidth(0.25),
            ),
            const SizedBox(height: 8),
            _buildSizeControl(
              title: 'Panjang',
              value: '${room.height.toStringAsFixed(2)} m',
              onMinus: () => controller.adjustSelectedHeight(-0.25),
              onPlus: () => controller.adjustSelectedHeight(0.25),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: controller.rotateSelectedRoom,
                icon: const Icon(Icons.rotate_90_degrees_ccw_rounded),
                label: const Text(
                  'PUTAR RUANG 90°',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: navy,
                  side: const BorderSide(color: navy, width: 1.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Perubahan ditolak otomatis jika ruang bertabrakan atau keluar dari batas lahan.',
              style: TextStyle(
                color: mutedText,
                fontSize: 10.8,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _selectedInfoTile({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: navy,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementPad() {
    return Column(
      children: [
        _controlSquareButton(
          icon: Icons.keyboard_arrow_up_rounded,
          onTap: () => controller.moveSelectedRoom(
            deltaX: 0,
            deltaY: -0.25,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _controlSquareButton(
              icon: Icons.keyboard_arrow_left_rounded,
              onTap: () => controller.moveSelectedRoom(
                deltaX: -0.25,
                deltaY: 0,
              ),
            ),
            Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.open_with_rounded,
                color: orange,
                size: 19,
              ),
            ),
            _controlSquareButton(
              icon: Icons.keyboard_arrow_right_rounded,
              onTap: () => controller.moveSelectedRoom(
                deltaX: 0.25,
                deltaY: 0,
              ),
            ),
          ],
        ),
        _controlSquareButton(
          icon: Icons.keyboard_arrow_down_rounded,
          onTap: () => controller.moveSelectedRoom(
            deltaX: 0,
            deltaY: 0.25,
          ),
        ),
      ],
    );
  }

  Widget _controlSquareButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: navy,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: Colors.white,
            size: 23,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeControl({
    required String title,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text(
              title,
              style: const TextStyle(
                color: navy,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _miniActionButton(
            icon: Icons.remove_rounded,
            onTap: onMinus,
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: navy,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _miniActionButton(
            icon: Icons.add_rounded,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }

  Widget _miniActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: navy,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: borderColor),
          ),
          boxShadow: [
            BoxShadow(
              color: navy.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: controller.resetLayout,
                icon: const Icon(Icons.restart_alt_rounded, size: 19),
                label: const Text(
                  'RESET',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: navy,
                  side: const BorderSide(color: navy),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: controller.saveResult,
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: const Text(
                    'SIMPAN HASIL EDIT',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roomColor(RoomModel room) {
    switch (room.category) {
      case 'bedroom':
        return const Color(0xFFFFF3DD);
      case 'living':
        return const Color(0xFFFFF9EC);
      case 'family':
        return const Color(0xFFF7F1E7);
      case 'kitchen':
        return const Color(0xFFEAF4FD);
      case 'dining':
        return const Color(0xFFFFF4E6);
      case 'bath':
        return const Color(0xFFE0F2FE);
      case 'service':
        return const Color(0xFFF1F5F9);
      case 'outdoor':
        if (room.nama.toLowerCase().contains('taman')) {
          return const Color(0xFFD8F3DC);
        }
        return const Color(0xFFE5E7EB);
      default:
        return const Color(0xFFF8FAFC);
    }
  }
}

class _PlanViewport {
  final Offset origin;
  final double scale;
  final double planWidth;
  final double planHeight;

  const _PlanViewport({
    required this.origin,
    required this.scale,
    required this.planWidth,
    required this.planHeight,
  });

  factory _PlanViewport.calculate({
    required Size size,
    required double landWidth,
    required double landLength,
  }) {
    const double margin = 45;

    final double availableWidth = math.max(1.0, size.width - (margin * 2));
    final double availableHeight = math.max(1.0, size.height - (margin * 2));

    final double scale = math.min(
      availableWidth / landWidth,
      availableHeight / landLength,
    );

    final double planWidth = landWidth * scale;
    final double planHeight = landLength * scale;

    return _PlanViewport(
      origin: Offset(
        (size.width - planWidth) / 2,
        (size.height - planHeight) / 2,
      ),
      scale: scale,
      planWidth: planWidth,
      planHeight: planHeight,
    );
  }
}

class _EditorCanvasPainter extends CustomPainter {
  final _PlanViewport viewport;
  final double landWidth;
  final double landLength;

  const _EditorCanvasPainter({
    required this.viewport,
    required this.landWidth,
    required this.landLength,
  });

  static const Color navy = Color(0xFF0D1B2A);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint minorGrid = Paint()
      ..color = const Color(0xFFE3EAF1)
      ..strokeWidth = 0.55;

    final Paint majorGrid = Paint()
      ..color = const Color(0xFFD2DDE7)
      ..strokeWidth = 0.95;

    const double grid = 14;

    for (double x = 0; x <= size.width; x += grid) {
      final bool major = ((x / grid).round() % 5) == 0;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        major ? majorGrid : minorGrid,
      );
    }

    for (double y = 0; y <= size.height; y += grid) {
      final bool major = ((y / grid).round() % 5) == 0;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        major ? majorGrid : minorGrid,
      );
    }

    final Rect landRect = Rect.fromLTWH(
      viewport.origin.dx,
      viewport.origin.dy,
      viewport.planWidth,
      viewport.planHeight,
    );

    canvas.drawRect(
      landRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    canvas.drawRect(
      landRect,
      Paint()
        ..color = navy
        ..strokeWidth = 4.6
        ..style = PaintingStyle.stroke,
    );

    _drawHorizontalDimension(
      canvas,
      landRect,
      '${landWidth.toStringAsFixed(1)} m',
    );

    _drawVerticalDimension(
      canvas,
      landRect,
      '${landLength.toStringAsFixed(1)} m',
    );

    _drawLocationLabel(
      canvas,
      'BELAKANG',
      Offset(landRect.center.dx, landRect.top + 9),
    );

    _drawLocationLabel(
      canvas,
      'DEPAN',
      Offset(landRect.center.dx, landRect.bottom - 10),
    );
  }

  void _drawHorizontalDimension(
    Canvas canvas,
    Rect rect,
    String text,
  ) {
    final Paint paint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1;

    final double y = rect.top - 22;

    canvas.drawLine(
      Offset(rect.left, y),
      Offset(rect.right, y),
      paint,
    );

    canvas.drawLine(
      Offset(rect.left, y - 5),
      Offset(rect.left, y + 5),
      paint,
    );

    canvas.drawLine(
      Offset(rect.right, y - 5),
      Offset(rect.right, y + 5),
      paint,
    );

    _drawText(
      canvas,
      text,
      Offset(rect.center.dx, y - 10),
      rotate: false,
    );
  }

  void _drawVerticalDimension(
    Canvas canvas,
    Rect rect,
    String text,
  ) {
    final Paint paint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1;

    final double x = rect.left - 22;

    canvas.drawLine(
      Offset(x, rect.top),
      Offset(x, rect.bottom),
      paint,
    );

    canvas.drawLine(
      Offset(x - 5, rect.top),
      Offset(x + 5, rect.top),
      paint,
    );

    canvas.drawLine(
      Offset(x - 5, rect.bottom),
      Offset(x + 5, rect.bottom),
      paint,
    );

    _drawText(
      canvas,
      text,
      Offset(x - 10, rect.center.dy),
      rotate: true,
    );
  }

  void _drawLocationLabel(Canvas canvas, String text, Offset position) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        position.dx - (painter.width / 2),
        position.dy - (painter.height / 2),
      ),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    required bool rotate,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (rotate) {
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(-math.pi / 2);
      painter.paint(
        canvas,
        Offset(
          -(painter.width / 2),
          -(painter.height / 2),
        ),
      );
      canvas.restore();
      return;
    }

    painter.paint(
      canvas,
      Offset(
        position.dx - (painter.width / 2),
        position.dy - (painter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _EditorCanvasPainter oldDelegate) {
    return oldDelegate.viewport.scale != viewport.scale ||
        oldDelegate.landWidth != landWidth ||
        oldDelegate.landLength != landLength;
  }
}

class _EditableRoomPainter extends CustomPainter {
  final RoomModel room;
  final bool selected;

  const _EditableRoomPainter({
    required this.room,
    required this.selected,
  });

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Color fillColor = _fillColor(room);

    canvas.drawRect(
      rect,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    if (room.nama.toLowerCase().contains('taman')) {
      _drawGrass(canvas, rect);
    }

    canvas.drawRect(
      rect,
      Paint()
        ..color = selected ? orange : navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 4.1 : (room.isOutdoor ? 2.2 : 3.2),
    );

    if (selected) {
      canvas.drawRect(
        rect.deflate(3.5),
        Paint()
          ..color = orange.withValues(alpha: 0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    _drawDoor(canvas, rect, fillColor);
    _drawWindow(canvas, rect);
    _drawLabel(canvas, rect);
  }

  Color _fillColor(RoomModel room) {
    switch (room.category) {
      case 'bedroom':
        return const Color(0xFFFFF3DD);
      case 'living':
        return const Color(0xFFFFF9EC);
      case 'family':
        return const Color(0xFFF7F1E7);
      case 'kitchen':
        return const Color(0xFFEAF4FD);
      case 'dining':
        return const Color(0xFFFFF4E6);
      case 'bath':
        return const Color(0xFFE0F2FE);
      case 'service':
        return const Color(0xFFF1F5F9);
      case 'outdoor':
        if (room.nama.toLowerCase().contains('taman')) {
          return const Color(0xFFD8F3DC);
        }
        return const Color(0xFFE5E7EB);
      default:
        return const Color(0xFFF8FAFC);
    }
  }

  void _drawGrass(Canvas canvas, Rect rect) {
    final Paint paint = Paint()
      ..color = const Color(0xFF86C28B).withValues(alpha: 0.33)
      ..strokeWidth = 1;

    for (double x = 8; x < rect.width - 5; x += 11) {
      for (double y = 10; y < rect.height - 5; y += 13) {
        canvas.drawLine(Offset(x, y + 4), Offset(x + 3, y), paint);
        canvas.drawLine(Offset(x + 3, y), Offset(x + 6, y + 4), paint);
      }
    }
  }

  void _drawDoor(Canvas canvas, Rect rect, Color fillColor) {
    final double doorSize = math.min(
      25,
      math.min(rect.width, rect.height) * 0.34,
    );

    if (doorSize < 9) return;

    final Paint erasePaint = Paint()
      ..color = fillColor
      ..strokeWidth = selected ? 6.5 : 5
      ..style = PaintingStyle.stroke;

    final Paint doorPaint = Paint()
      ..color = selected ? orange : const Color(0xFF334155)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    switch (room.doorSide) {
      case 'left':
        final double y = rect.center.dy;

        canvas.drawLine(
          Offset(rect.left, y - doorSize / 2),
          Offset(rect.left, y + doorSize / 2),
          erasePaint,
        );

        canvas.drawArc(
          Rect.fromLTWH(rect.left, y - doorSize / 2, doorSize, doorSize),
          math.pi / 2,
          math.pi / 2,
          false,
          doorPaint,
        );
        break;

      case 'right':
        final double y = rect.center.dy;

        canvas.drawLine(
          Offset(rect.right, y - doorSize / 2),
          Offset(rect.right, y + doorSize / 2),
          erasePaint,
        );

        canvas.drawArc(
          Rect.fromLTWH(
            rect.right - doorSize,
            y - doorSize / 2,
            doorSize,
            doorSize,
          ),
          -math.pi / 2,
          math.pi / 2,
          false,
          doorPaint,
        );
        break;

      case 'top':
        final double x = rect.center.dx;

        canvas.drawLine(
          Offset(x - doorSize / 2, rect.top),
          Offset(x + doorSize / 2, rect.top),
          erasePaint,
        );

        canvas.drawArc(
          Rect.fromLTWH(x - doorSize / 2, rect.top, doorSize, doorSize),
          math.pi,
          -math.pi / 2,
          false,
          doorPaint,
        );
        break;

      case 'bottom':
      default:
        final double x = rect.center.dx;

        canvas.drawLine(
          Offset(x - doorSize / 2, rect.bottom),
          Offset(x + doorSize / 2, rect.bottom),
          erasePaint,
        );

        canvas.drawArc(
          Rect.fromLTWH(
            x - doorSize / 2,
            rect.bottom - doorSize,
            doorSize,
            doorSize,
          ),
          0,
          -math.pi / 2,
          false,
          doorPaint,
        );
        break;
    }
  }

  void _drawWindow(Canvas canvas, Rect rect) {
    if (room.isOutdoor || rect.width < 34) return;

    final double windowWidth = math.min(27, rect.width * 0.27);

    canvas.drawLine(
      Offset(rect.center.dx - windowWidth / 2, rect.top + 1.5),
      Offset(rect.center.dx + windowWidth / 2, rect.top + 1.5),
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 2,
    );
  }

  void _drawLabel(Canvas canvas, Rect rect) {
    if (rect.width < 29 || rect.height < 24) return;

    final TextPainter painter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${room.nama}\n',
            style: TextStyle(
              color: navy,
              fontSize: math.max(7, math.min(10.5, rect.width / 7)),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text:
                '${room.width.toStringAsFixed(1)} × ${room.height.toStringAsFixed(1)} m',
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: math.max(6, math.min(8.5, rect.width / 10)),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 7);

    painter.paint(
      canvas,
      Offset(
        rect.center.dx - (painter.width / 2),
        rect.center.dy - (painter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _EditableRoomPainter oldDelegate) {
    return oldDelegate.room != room ||
        oldDelegate.selected != selected;
  }
}