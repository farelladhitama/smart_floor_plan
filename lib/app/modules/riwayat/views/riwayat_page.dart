import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/riwayat_controller.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);
  static const Color softGrey = Color(0xFFEDEFF3);

  RiwayatController get controller {
    if (Get.isRegistered<RiwayatController>()) {
      return Get.find<RiwayatController>();
    }

    return Get.put(RiwayatController());
  }

  @override
  Widget build(BuildContext context) {
    final RiwayatController riwayatController = controller;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final bool isWide = constraints.maxWidth > 720;
          final double maxWidth = isWide ? 680 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: RefreshIndicator(
                onRefresh: riwayatController.loadHistories,
                color: orange,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    isMobile ? 18 : 24,
                    isMobile ? 16 : 24,
                    110,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (riwayatController.isLoading.value) {
                          return const SizedBox(
                            height: 260,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: orange,
                              ),
                            ),
                          );
                        }

                        if (riwayatController.histories.isEmpty) {
                          return _buildEmptyBox(isMobile);
                        }

                        return Column(
                          children: riwayatController.histories.map((item) {
                            return _buildHistoryCard(
                              isMobile: isMobile,
                              item: item,
                              controller: riwayatController,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat Desain',
                style: TextStyle(
                  color: navy,
                  fontSize: isMobile ? 26 : 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Daftar rancangan denah yang tersimpan di Supabase.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: isMobile ? 13.5 : 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => controller.loadHistories(),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: isMobile ? 48 : 54,
            height: isMobile ? 48 : 54,
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: navy.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: isMobile ? 25 : 28,
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
                    'Data riwayat diambil langsung dari tabel floor_plans.',
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
            text: controller.getRabText(item),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Detail',
                  icon: Icons.visibility_rounded,
                  isPrimary: true,
                  onTap: () => controller.openDetail(item),
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
            'Generate denah lalu tekan Simpan Denah agar muncul di sini.',
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
              'Riwayat ini sudah mengambil data asli dari Supabase. Fitur Edit denah lama akan disambungkan pada tahap berikutnya.',
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