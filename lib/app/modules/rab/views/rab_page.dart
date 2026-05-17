import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';

class RABPage extends GetView<RABController> {
  final List<RoomModel> rooms;

  const RABPage({
    super.key,
    required this.rooms,
  });

  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF1B263B);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    controller.setRooms(rooms);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Detail RAB',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
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
                    110,
                  ),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCard(),
                            const SizedBox(height: 20),
                            _buildDetailSection(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 320,
                              child: _buildSummaryCard(),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: _buildDetailSection(),
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

  Widget _buildSummaryCard() {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              navy,
              navyLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.18),
              blurRadius: 26,
              offset: const Offset(0, 13),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderIcon(),
            const SizedBox(height: 18),
            const Text(
              'Rencana Anggaran Biaya',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimasi biaya pembangunan berdasarkan total luas denah dan pembagian komponen pekerjaan.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _buildSummaryTile(
              title: 'Total Luas',
              value: '${controller.totalLuas.toStringAsFixed(1)} m²',
              icon: Icons.square_foot_rounded,
            ),
            const SizedBox(height: 12),
            _buildSummaryTile(
              title: 'Jumlah Ruang',
              value: '${controller.rooms.length} ruang',
              icon: Icons.meeting_room_rounded,
            ),
            const SizedBox(height: 12),
            _buildSummaryTile(
              title: 'Harga / m²',
              value: controller.formatRupiah(RABController.hargaPerMeter),
              icon: Icons.price_change_rounded,
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: orange.withOpacity(0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Estimasi',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.formatRupiah(controller.hargaDasar),
                    style: const TextStyle(
                      color: orange,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.receipt_long_rounded,
        color: orange,
        size: 38,
      ),
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
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
            size: 23,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Biaya',
            style: TextStyle(
              color: navy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pembagian estimasi biaya berdasarkan komponen pekerjaan utama.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _buildBiayaCard(
            title: 'Struktur & Pondasi',
            harga: controller.formatRupiah(
              controller.biayaStrukturPondasi,
            ),
            percent: '25%',
            icon: Icons.foundation_rounded,
            description: 'Pekerjaan pondasi, struktur dasar, dan rangka utama.',
          ),
          _buildBiayaCard(
            title: 'Dinding & Material',
            harga: controller.formatRupiah(
              controller.biayaDindingMaterial,
            ),
            percent: '20%',
            icon: Icons.layers_rounded,
            description: 'Material dinding, pasangan bata, dan pekerjaan dinding.',
          ),
          _buildBiayaCard(
            title: 'Atap & Plafon',
            harga: controller.formatRupiah(
              controller.biayaAtapPlafon,
            ),
            percent: '15%',
            icon: Icons.roofing_rounded,
            description: 'Rangka atap, penutup atap, dan plafon ruangan.',
          ),
          _buildBiayaCard(
            title: 'Lantai & Keramik',
            harga: controller.formatRupiah(
              controller.biayaLantaiKeramik,
            ),
            percent: '15%',
            icon: Icons.grid_view_rounded,
            description: 'Pekerjaan lantai, keramik, dan pelapis dasar.',
          ),
          _buildBiayaCard(
            title: 'Pekerjaan Finishing',
            harga: controller.formatRupiah(
              controller.biayaFinishing,
            ),
            percent: '25%',
            icon: Icons.format_paint_rounded,
            description: 'Cat, finishing akhir, detail interior, dan perapian.',
          ),
          const SizedBox(height: 10),
          _buildNoteCard(),
        ],
      ),
    );
  }

  Widget _buildBiayaCard({
    required String title,
    required String harga,
    required String percent,
    required IconData icon,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              icon,
              color: orange,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: navy,
                          fontSize: 15.5,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: navy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        percent,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  harga,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: orange,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: navy.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: navy.withOpacity(0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: navy,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Catatan: RAB ini merupakan estimasi awal. Biaya aktual dapat berubah tergantung lokasi, kualitas material, upah tenaga kerja, dan kondisi lapangan.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
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
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: controller.simpanHasilFinal,
            icon: const Icon(
              Icons.save_rounded,
              color: Colors.white,
              size: 22,
            ),
            label: const Text(
              'SIMPAN HASIL FINAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
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