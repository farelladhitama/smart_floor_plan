import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/hasil_denah/controllers/hasil_denah_controller.dart';

class HasilDenahPage extends GetView<HasilDenahController> {
  final List<RoomModel> rooms;
  final double inputPanjangRumah;
  final double inputLebarRumah;

  const HasilDenahPage({
    super.key,
    required this.rooms,
    required this.inputPanjangRumah,
    required this.inputLebarRumah,
  });

  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF1B263B);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    controller.setInitialRooms(rooms);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Hasil Denah',
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    20,
                    isMobile ? 16 : 24,
                    120,
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 18),
                            _buildCanvasCard(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 300,
                              child: _buildHeaderCard(),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildCanvasCard(),
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

  Widget _buildHeaderCard() {
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderIcon(),
          const SizedBox(height: 18),
          const Text(
            'Denah Rumah 2D',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hasil generate denah berdasarkan ukuran lahan dan kebutuhan ruangan Anda.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  title: 'Lebar',
                  value: '${inputLebarRumah.toStringAsFixed(1)} m',
                  icon: Icons.straighten_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  title: 'Panjang',
                  value: '${inputPanjangRumah.toStringAsFixed(1)} m',
                  icon: Icons.square_foot_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => _buildInfoTile(
              title: 'Jumlah Ruang',
              value: '${controller.currentRooms.length} ruang',
              icon: Icons.meeting_room_rounded,
              fullWidth: true,
            ),
          ),
          const SizedBox(height: 18),
          _buildHintBox(),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.map_rounded,
        color: orange,
        size: 36,
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: orange.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: orange.withOpacity(0.20),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            color: orange,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tekan Edit untuk menggeser atau mengubah ukuran ruangan. Setelah selesai, simpan denah untuk melihat RAB.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasCard() {
    final double lebarVisual = inputLebarRumah * controller.skala;
    final double panjangVisual = inputPanjangRumah * controller.skala;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Preview Denah',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Blueprint',
                  style: TextStyle(
                    color: orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 360,
                maxHeight: 520,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3F6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 2.5,
                boundaryMargin: const EdgeInsets.all(80),
                child: Center(
                  child: Container(
                    width: lebarVisual + 90,
                    height: panjangVisual + 90,
                    alignment: Alignment.center,
                    child: Obx(
                      () => CustomPaint(
                        size: Size(lebarVisual, panjangVisual),
                        painter: DenahProfessionalPainter(
                          rooms: controller.currentRooms.toList(),
                          skala: controller.skala,
                          lebarRumah: inputLebarRumah,
                          panjangRumah: inputPanjangRumah,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _bottomButton(
                label: 'EDIT',
                icon: Icons.edit_location_alt_rounded,
                color: navy,
                onTap: controller.editDenah,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Obx(
                () => !controller.isSaved.value
                    ? _bottomButton(
                        label: 'SIMPAN DENAH',
                        icon: Icons.save_rounded,
                        color: orange,
                        onTap: controller.simpanDenah,
                      )
                    : _bottomButton(
                        label: 'LIHAT RAB',
                        icon: Icons.receipt_long_rounded,
                        color: Colors.green.shade700,
                        onTap: controller.lihatRAB,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 21,
        ),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: color.withOpacity(0.26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class DenahProfessionalPainter extends CustomPainter {
  final List<RoomModel> rooms;
  final double skala;
  final double lebarRumah;
  final double panjangRumah;

  DenahProfessionalPainter({
    required this.rooms,
    required this.skala,
    required this.lebarRumah,
    required this.panjangRumah,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = const Color(0xFFEFF3F6)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    final gridPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.16)
      ..strokeWidth = 0.6;

    final largeGridPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.25)
      ..strokeWidth = 1.0;

    for (double i = -40; i <= size.width + 40; i += 10) {
      canvas.drawLine(
        Offset(i, -40),
        Offset(i, size.height + 40),
        i % 50 == 0 ? largeGridPaint : gridPaint,
      );
    }

    for (double i = -40; i <= size.height + 40; i += 10) {
      canvas.drawLine(
        Offset(-40, i),
        Offset(size.width + 40, i),
        i % 50 == 0 ? largeGridPaint : gridPaint,
      );
    }

    final outerWallPaint = Paint()
      ..color = const Color(0xFF0D1B2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      outerWallPaint,
    );

    _drawDimension(
      canvas,
      const Offset(0, -25),
      Offset(size.width, -25),
      '${lebarRumah.toStringAsFixed(1)}m',
      Colors.blueGrey.shade800,
    );

    _drawDimension(
      canvas,
      const Offset(-25, 0),
      Offset(-25, size.height),
      '${panjangRumah.toStringAsFixed(1)}m',
      Colors.blueGrey.shade800,
      isVertical: true,
    );

    for (final room in rooms) {
      final roomRect = Rect.fromLTWH(
        room.x,
        room.y,
        room.width,
        room.height,
      );

      final roomPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(roomRect, const Radius.circular(4)),
        roomPaint,
      );

      final wallPaint = Paint()
        ..color = const Color(0xFF0D1B2A).withOpacity(0.86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(roomRect, const Radius.circular(4)),
        wallPaint,
      );

      final double luas = (room.width / skala) * (room.height / skala);

      _drawRoomInfo(
        canvas,
        roomRect,
        room.nama,
        luas,
      );

      _drawDimension(
        canvas,
        Offset(room.x, room.y + 13),
        Offset(room.x + room.width, room.y + 13),
        '${(room.width / skala).toStringAsFixed(1)}m',
        Colors.red.shade800,
        fontSize: 9,
      );

      _drawDimension(
        canvas,
        Offset(room.x + 13, room.y),
        Offset(room.x + 13, room.y + room.height),
        '${(room.height / skala).toStringAsFixed(1)}m',
        Colors.red.shade800,
        isVertical: true,
        fontSize: 9,
      );
    }
  }

  void _drawDimension(
    Canvas canvas,
    Offset start,
    Offset end,
    String text,
    Color color, {
    bool isVertical = false,
    double fontSize = 11,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    canvas.drawLine(start, end, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset textPos = isVertical
        ? Offset(
            start.dx - textPainter.width - 5,
            (start.dy + end.dy) / 2 - (textPainter.height / 2),
          )
        : Offset(
            (start.dx + end.dx) / 2 - (textPainter.width / 2),
            start.dy - textPainter.height - 2,
          );

    textPainter.paint(canvas, textPos);
  }

  void _drawRoomInfo(
    Canvas canvas,
    Rect rect,
    String name,
    double area,
  ) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$name\n',
            style: const TextStyle(
              color: Color(0xFF0D1B2A),
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          TextSpan(
            text: '${area.toStringAsFixed(1)} m²',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 8);

    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - (textPainter.width / 2),
        rect.center.dy - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}