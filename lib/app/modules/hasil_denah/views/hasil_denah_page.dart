import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/hasil_denah/controllers/hasil_denah_controller.dart';
import 'package:smart_floor_plan/app/widgets/professional_floor_plan_painter.dart';

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
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color mutedText = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    controller.setInitialRooms(rooms);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Hasil Denah',
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 14 : 22,
                    18,
                    isMobile ? 14 : 22,
                    110,
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 16),
                            _buildCanvasCard(isMobile: true),
                            const SizedBox(height: 16),
                            _buildLegendCard(),
                            const SizedBox(height: 16),
                            _buildRoomSummaryCard(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 300,
                              child: Column(
                                children: [
                                  _buildHeaderCard(),
                                  const SizedBox(height: 16),
                                  _buildLegendCard(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildCanvasCard(isMobile: false),
                                  const SizedBox(height: 16),
                                  _buildRoomSummaryCard(),
                                ],
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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            blurRadius: 22,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.architecture_rounded,
              color: orange,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Denah Rumah 2D',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Layout otomatis dengan pembagian ruang natural, dinding blueprint, dan akses pintu antarruang.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 12.5,
              height: 1.47,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  title: 'Lebar',
                  value: '${inputLebarRumah.toStringAsFixed(1)} m',
                  icon: Icons.straighten_rounded,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _buildInfoTile(
                  title: 'Panjang',
                  value: '${inputPanjangRumah.toStringAsFixed(1)} m',
                  icon: Icons.height_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    title: 'Ruangan',
                    value: '${controller.currentRooms.length}',
                    icon: Icons.meeting_room_rounded,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _buildInfoTile(
                    title: 'Area Ruang',
                    value: '${controller.totalRoomArea.toStringAsFixed(1)} m²',
                    icon: Icons.square_foot_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: orange.withValues(alpha: 0.18),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  color: orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zoom untuk melihat detail pintu, ukuran ruang, dan jalur akses. Gunakan Edit untuk mengatur posisi, ukuran, serta rotasi ruang.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.7,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: orange, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasCard({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 13 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.045),
            blurRadius: 19,
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
                      'Preview Arsitektural',
                      style: TextStyle(
                        color: navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Denah blueprint dengan pintu dan ukuran ruang',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11.8,
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
                  'SMART PLAN',
                  style: TextStyle(
                    color: orange,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: isMobile ? 500 : 620,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FA),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Obx(
                () => InteractiveViewer(
                  minScale: 0.75,
                  maxScale: 4.5,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: SizedBox.expand(
                    child: CustomPaint(
                      painter: ProfessionalFloorPlanPainter(
                        landWidth: inputLebarRumah,
                        landLength: inputPanjangRumah,
                        rooms: controller.currentRooms.toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pinch_rounded,
                color: mutedText,
                size: 16,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Cubit atau scroll untuk zoom • geser untuk melihat detail',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: borderColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda Ruang',
            style: TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _LegendItem(color: Color(0xFFFFF3DD), label: 'Kamar'),
              _LegendItem(color: Color(0xFFFFF9EC), label: 'R. Tamu'),
              _LegendItem(color: Color(0xFFF7F1E7), label: 'R. Keluarga'),
              _LegendItem(color: Color(0xFFEAF4FD), label: 'Dapur'),
              _LegendItem(color: Color(0xFFE0F2FE), label: 'KM/WC'),
              _LegendItem(color: Color(0xFFD8F3DC), label: 'Taman'),
              _LegendItem(color: Color(0xFFE5E7EB), label: 'Carport'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Ruangan',
            style: TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          Obx(
            () => Wrap(
              spacing: 9,
              runSpacing: 9,
              children: controller.currentRooms.map((room) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _roomDotColor(room),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        room.nama,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${room.area.toStringAsFixed(1)} m²',
                        style: const TextStyle(
                          color: mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _roomDotColor(RoomModel room) {
    switch (room.category) {
      case 'bedroom':
        return const Color(0xFFF59E0B);
      case 'living':
        return const Color(0xFFEA580C);
      case 'family':
        return const Color(0xFFD97706);
      case 'kitchen':
        return const Color(0xFF2563EB);
      case 'dining':
        return const Color(0xFFFB923C);
      case 'bath':
        return const Color(0xFF0EA5E9);
      case 'outdoor':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
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
        child: Row(
          children: [
            Expanded(
              child: _bottomButton(
                label: 'EDIT',
                icon: Icons.design_services_rounded,
                color: navy,
                onTap: () => controller.editDenah(
                  landWidth: inputLebarRumah,
                  landLength: inputPanjangRumah,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Obx(
                () => _bottomButton(
                  label: controller.isSaved.value
                      ? 'LIHAT RAB'
                      : 'SIMPAN DENAH',
                  icon: controller.isSaved.value
                      ? Icons.receipt_long_rounded
                      : Icons.save_rounded,
                  color: controller.isSaved.value
                      ? const Color(0xFF15803D)
                      : orange,
                  onTap: controller.isSaved.value
                      ? controller.lihatRAB
                      : controller.simpanDenah,
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
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: HasilDenahPage.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}