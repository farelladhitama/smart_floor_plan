import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/edit_denah/controllers/edit_denah_controller.dart';

class EditDenahPage extends GetView<EditDenahController> {
  final List<RoomModel> initialRooms;

  const EditDenahPage({
    super.key,
    required this.initialRooms,
  });

  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF1B263B);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    controller.setInitialRooms(initialRooms);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Edit Denah',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: navy,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 700;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    18,
                    isMobile ? 16 : 24,
                    18,
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildInfoPanel(),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildEditorCanvas(),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            SizedBox(
                              width: 280,
                              child: _buildInfoPanel(),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _buildEditorCanvas(),
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

  Widget _buildInfoPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            navy,
            navyLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth > 500;

          if (compact) {
            return Row(
              children: [
                _buildPanelIcon(),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editor Layout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Geser ruangan untuk mengubah posisi. Tarik titik merah untuk resize ukuran ruangan.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanelIcon(),
              const SizedBox(height: 16),
              const Text(
                'Editor Layout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Geser ruangan untuk mengubah posisi. Tarik titik merah untuk resize ukuran ruangan.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              _buildMiniGuide(
                icon: Icons.open_with_rounded,
                title: 'Drag',
                text: 'Geser posisi ruangan',
              ),
              const SizedBox(height: 10),
              _buildMiniGuide(
                icon: Icons.open_in_full_rounded,
                title: 'Resize',
                text: 'Ubah ukuran ruangan',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPanelIcon() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.design_services_rounded,
        color: orange,
        size: 34,
      ),
    );
  }

  Widget _buildMiniGuide({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: orange,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorCanvas() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3F6),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: GridPainter(),
                ),
                Positioned.fill(
                  child: Obx(
                    () => Stack(
                      children: controller.listRuangan.asMap().entries.map(
                        (entry) {
                          final int index = entry.key;
                          final RoomModel room = entry.value;

                          return Positioned(
                            left: room.x,
                            top: room.y,
                            child: _buildEditableRoom(
                              room: room,
                              index: index,
                              maxWidth: constraints.maxWidth,
                              maxHeight: constraints.maxHeight,
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditableRoom({
    required RoomModel room,
    required int index,
    required double maxWidth,
    required double maxHeight,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            controller.updatePosition(
              index: index,
              deltaX: details.delta.dx,
              deltaY: details.delta.dy,
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            );
          },
          child: Container(
            width: room.width,
            height: room.height,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: navy,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: navy.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: orange.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(room.width / controller.skala).toStringAsFixed(1)}m',
                      style: const TextStyle(
                        color: orange,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: RotatedBox(
                    quarterTurns: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: navy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(room.height / controller.skala).toStringAsFixed(1)}m',
                        style: const TextStyle(
                          color: navy,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.meeting_room_rounded,
                            color: navy,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            room.nama,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${(room.width / controller.skala).toStringAsFixed(1)}m x ${(room.height / controller.skala).toStringAsFixed(1)}m',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -10,
          bottom: -10,
          child: GestureDetector(
            onPanUpdate: (details) {
              controller.updateSize(
                index: index,
                deltaX: details.delta.dx,
                deltaY: details.delta.dy,
              );
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: orange.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.open_in_full_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        decoration: BoxDecoration(
          color: background,
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: controller.saveResult,
            icon: const Icon(
              Icons.save_rounded,
              color: Colors.white,
              size: 22,
            ),
            label: const Text(
              'SIMPAN HASIL EDIT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              elevation: 5,
              shadowColor: orange.withOpacity(0.30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = const Color(0xFFEFF3F6)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    final smallGridPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.14)
      ..strokeWidth = 0.6;

    final largeGridPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.22)
      ..strokeWidth = 1.0;

    for (double i = 0; i <= size.width; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        i % 100 == 0 ? largeGridPaint : smallGridPaint,
      );
    }

    for (double i = 0; i <= size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        i % 100 == 0 ? largeGridPaint : smallGridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}