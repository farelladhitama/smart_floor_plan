import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/riwayat_controller.dart';

class RiwayatPage extends GetView<RiwayatController> {
  const RiwayatPage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);
  static const Color softGrey = Color(0xFFEDEFF3);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RiwayatController>()) {
      Get.put(RiwayatController());
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final bool isWide = constraints.maxWidth > 720;
          final double maxWidth = isWide ? 680 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 18 : 24,
                  isMobile ? 16 : 24,
                  110,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    const SizedBox(height: 22),
                    _buildSummary(isMobile),
                    const SizedBox(height: 20),
                    Obx(() {
                      return Column(
                        children: controller.histories.map((item) {
                          return _buildHistoryCard(
                            isMobile: isMobile,
                            title: item['title'] ?? '-',
                            subtitle: item['subtitle'] ?? '-',
                            date: item['date'] ?? '-',
                            type: item['type'] ?? 'manual',
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
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
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
                'Daftar rancangan denah yang pernah dibuat.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: isMobile ? 13.5 : 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Container(
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
            Icons.history_rounded,
            color: Colors.white,
            size: isMobile ? 25 : 28,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(bool isMobile) {
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
                    'Contoh data riwayat untuk tampilan demo aplikasi.',
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
    required String title,
    required String subtitle,
    required String date,
    required String type,
  }) {
    final IconData icon = type == 'scan'
        ? Icons.document_scanner_rounded
        : Icons.home_work_rounded;

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
                  icon,
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
                      title,
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
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: isMobile ? 12.5 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Detail',
                  icon: Icons.visibility_rounded,
                  isPrimary: true,
                  onTap: () => controller.openDetail(title),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  label: 'Edit',
                  icon: Icons.edit_rounded,
                  isPrimary: false,
                  onTap: () => controller.openEdit(title),
                ),
              ),
            ],
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
        icon: Icon(icon, size: 18),
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
              'Riwayat ini masih menggunakan data demo untuk tampilan mobile. Fitur penyimpanan ke backend dapat dikembangkan pada tahap berikutnya.',
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