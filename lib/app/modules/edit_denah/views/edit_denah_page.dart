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

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 14 : 22,
                    16,
                    isMobile ? 14 : 22,
                    12,
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildInfoPanel(isMobile: true),
                            const SizedBox(height: 14),
                            Expanded(child: _buildEditorCard()),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 286,
                              child: _buildInfoPanel(isMobile: false),
                            ),
                            const SizedBox(width: 18),
                            Expanded(child: _buildEditorCard()),
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

  Widget _buildInfoPanel({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 17 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: isMobile
          ? Row(
              children: [
                _buildPanelIcon(),
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
                        'Geser, resize, atau rotasi ruang sesuai kebutuhan.',
                        style: TextStyle(
                          color: Color(0xFFC2CBD5),
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
                _buildPanelIcon(),
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
                  'Sesuaikan tata ruang sambil tetap menjaga denah tidak bertabrakan.',
                  style: TextStyle(
                    color: Color(0xFFC2CBD5),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 19),
                _buildMiniGuide(
                  icon: Icons.open_with_rounded,
                  title: 'Drag',
                  text: 'Geser posisi ruang',
                ),
                const SizedBox(height: 9),
                _buildMiniGuide(
                  icon: Icons.open_in_full_rounded,
                  title: 'Resize',
                  text: 'Ubah ukuran ruang',
                ),
                const SizedBox(height: 9),
                _buildMiniGuide(
                  icon: Icons.rotate_90_degrees_ccw_rounded,
                  title: 'Rotasi',
                  text: 'Putar ruang 90°',
                ),
                const SizedBox(height: 9),
                _buildMiniGuide(
                  icon: Icons.shield_outlined,
                  title: 'Validasi',
                  text: 'Cegah tabrakan ruang',
                ),
                const SizedBox(height: 18),
                Obx(
                  () => _buildRoomCountInfo(
                    '${controller.listRuangan.length} ruang aktif',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPanelIcon() {
    return Container(
      width: 56,
      height: 56,
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

  Widget _buildMiniGuide({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: orange, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(
                      color: Color(0xFFC2CBD5),
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
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

  Widget _buildRoomCountInfo(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.meeting_room_rounded,
            color: orange,
            size: 19,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.045),
            blurRadius: 18,
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
                      'Drag ruang atau gunakan kontrol edit',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewport = _PlanViewport.calculate(
                      size: Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                      landWidth: landWidth,
                      landLength: landLength,
                    );

                    return Obx(
                      () => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                            painter: _EditorBlueprintPainter(
                              viewport: viewport,
                              landWidth: landWidth,
                              landLength: landLength,
                            ),
                          ),
                          ...controller.listRuangan.asMap().entries.map(
                            (entry) {
                              return _buildEditableRoom(
                                room: entry.value,
                                index: entry.key,
                                viewport: viewport,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRoom({
    required RoomModel room,
    required int index,
    required _PlanViewport viewport,
  }) {
    final width = room.width * viewport.scale;
    final height = room.height * viewport.scale;

    return Positioned(
      left: viewport.origin.dx + room.x * viewport.scale,
      top: viewport.origin.dy + room.y * viewport.scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              controller.updatePosition(
                index: index,
                deltaXMeter: details.delta.dx / viewport.scale,
                deltaYMeter: details.delta.dy / viewport.scale,
              );
            },
            child: CustomPaint(
              size: Size(width, height),
              painter: _EditableRoomPainter(room: room),
            ),
          ),
          Positioned(
            top: -11,
            right: -11,
            child: Tooltip(
              message: 'Putar ruangan 90°',
              child: InkWell(
                onTap: () => controller.rotateRoom(index),
                borderRadius: BorderRadius.circular(16),
                child: _buildControlButton(
                  icon: Icons.rotate_90_degrees_ccw_rounded,
                  backgroundColor: navy,
                ),
              ),
            ),
          ),
          Positioned(
            right: -11,
            bottom: -11,
            child: GestureDetector(
              onPanUpdate: (details) {
                controller.updateSize(
                  index: index,
                  deltaWidthMeter: details.delta.dx / viewport.scale,
                  deltaHeightMeter: details.delta.dy / viewport.scale,
                );
              },
              child: Tooltip(
                message: 'Ubah ukuran ruang',
                child: _buildControlButton(
                  icon: Icons.open_in_full_rounded,
                  backgroundColor: orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.28),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 13),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
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
        child: SizedBox(
          height: 55,
          child: ElevatedButton.icon(
            onPressed: controller.saveResult,
            icon: const Icon(Icons.save_rounded, size: 20),
            label: const Text(
              'SIMPAN HASIL EDIT',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
      ),
    );
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
    const double margin = 47;

    final availableWidth = math.max(1.0, size.width - margin * 2);
    final availableHeight = math.max(1.0, size.height - margin * 2);

    final scale = math.min(
      availableWidth / landWidth,
      availableHeight / landLength,
    );

    final planWidth = landWidth * scale;
    final planHeight = landLength * scale;

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

class _EditorBlueprintPainter extends CustomPainter {
  final _PlanViewport viewport;
  final double landWidth;
  final double landLength;

  const _EditorBlueprintPainter({
    required this.viewport,
    required this.landWidth,
    required this.landLength,
  });

  static const Color navy = Color(0xFF0D1B2A);

  @override
  void paint(Canvas canvas, Size size) {
    final minorGrid = Paint()
      ..color = const Color(0xFFE3EAF1)
      ..strokeWidth = 0.55;

    final majorGrid = Paint()
      ..color = const Color(0xFFD2DDE7)
      ..strokeWidth = 0.9;

    const grid = 14.0;

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

    final planRect = Rect.fromLTWH(
      viewport.origin.dx,
      viewport.origin.dy,
      viewport.planWidth,
      viewport.planHeight,
    );

    canvas.drawRect(
      planRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    canvas.drawRect(
      planRect,
      Paint()
        ..color = navy
        ..strokeWidth = 4.8
        ..style = PaintingStyle.stroke,
    );

    _drawDimension(
      canvas: canvas,
      start: Offset(planRect.left, planRect.top - 22),
      end: Offset(planRect.right, planRect.top - 22),
      text: '${landWidth.toStringAsFixed(1)} m',
      vertical: false,
    );

    _drawDimension(
      canvas: canvas,
      start: Offset(planRect.left - 22, planRect.top),
      end: Offset(planRect.left - 22, planRect.bottom),
      text: '${landLength.toStringAsFixed(1)} m',
      vertical: true,
    );

    _drawText(
      canvas,
      'BELAKANG',
      Offset(planRect.center.dx, planRect.top + 10),
    );

    _drawText(
      canvas,
      'DEPAN',
      Offset(planRect.center.dx, planRect.bottom - 12),
    );
  }

  void _drawDimension({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required String text,
    required bool vertical,
  }) {
    final paint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1;

    canvas.drawLine(start, end, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (vertical) {
      canvas.save();
      canvas.translate(start.dx - 10, (start.dy + end.dy) / 2);
      canvas.rotate(-math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    } else {
      textPainter.paint(
        canvas,
        Offset(
          (start.dx + end.dx - textPainter.width) / 2,
          start.dy - textPainter.height - 4,
        ),
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 7,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        position.dx - painter.width / 2,
        position.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _EditorBlueprintPainter oldDelegate) {
    return oldDelegate.viewport.scale != viewport.scale ||
        oldDelegate.landWidth != landWidth ||
        oldDelegate.landLength != landLength;
  }
}

class _EditableRoomPainter extends CustomPainter {
  final RoomModel room;

  const _EditableRoomPainter({required this.room});

  static const Color navy = Color(0xFF0D1B2A);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..color = _fillColor(room)
        ..style = PaintingStyle.fill,
    );

    if (room.nama.toLowerCase().contains('taman')) {
      _drawGrass(canvas, rect);
    }

    canvas.drawRect(
      rect,
      Paint()
        ..color = navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = room.isOutdoor ? 2.2 : 3.4,
    );

    _drawDoor(canvas, rect);
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
    final paint = Paint()
      ..color = const Color(0xFF86C28B).withValues(alpha: 0.34)
      ..strokeWidth = 1;

    for (double x = 8; x < rect.width - 5; x += 11) {
      for (double y = 10; y < rect.height - 5; y += 13) {
        canvas.drawLine(Offset(x, y + 4), Offset(x + 3, y), paint);
        canvas.drawLine(Offset(x + 3, y), Offset(x + 6, y + 4), paint);
      }
    }
  }

  void _drawDoor(Canvas canvas, Rect rect) {
    final double doorSize = math.min(
      25,
      math.min(rect.width, rect.height) * 0.34,
    );

    if (doorSize < 9) return;

    final erasePaint = Paint()
      ..color = _fillColor(room)
      ..strokeWidth = 5.5
      ..style = PaintingStyle.stroke;

    final doorPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    switch (room.doorSide) {
      case 'left':
        final y = rect.center.dy;
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
        final y = rect.center.dy;
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
        final x = rect.center.dx;
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
        final x = rect.center.dx;
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
    }
  }

  void _drawWindow(Canvas canvas, Rect rect) {
    if (room.isOutdoor || rect.width < 34) return;

    final windowWidth = math.min(27, rect.width * 0.27);

    canvas.drawLine(
      Offset(rect.center.dx - windowWidth / 2, rect.top + 1.5),
      Offset(rect.center.dx + windowWidth / 2, rect.top + 1.5),
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 2,
    );
  }

  void _drawLabel(Canvas canvas, Rect rect) {
    if (rect.width < 30 || rect.height < 25) return;

    final painter = TextPainter(
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
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _EditableRoomPainter oldDelegate) {
    return oldDelegate.room != room;
  }
}