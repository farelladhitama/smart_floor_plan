import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/routes/app_routes.dart';
import 'package:smart_floor_plan/app/modules/riwayat/views/riwayat_page.dart';
import 'package:smart_floor_plan/app/modules/profile/controllers/profile_controller.dart';
import 'package:smart_floor_plan/app/modules/analysis/views/analysis_page.dart'; 

import '../controllers/dashboard_controller.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);
  static const Color softGrey = Color(0xFFEDEFF3);

  ProfileController get profileController {
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>();
    }

    return Get.put(ProfileController());
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Obx(() {
        final index = controller.selectedIndex.value;

        // ✅ TAMBAHKAN UNTUK ANALISIS
        if (index == 1) {
          return const AnalysisPage();
        }

        if (index == 2) {
          return const RiwayatPage();
        }

        if (index == 3) {
          return _buildProfilePage();
        }

        return _buildHomePage();
      }),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomePage() {
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
                    _buildHeader(isMobile: isMobile),
                    SizedBox(height: isMobile ? 22 : 28),
                    _buildHeroCard(isMobile: isMobile),
                    SizedBox(height: isMobile ? 26 : 34),
                    Text(
                      'Menu Utama',
                      style: TextStyle(
                        color: navy,
                        fontSize: isMobile ? 24 : 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMainMenu(isMobile: isMobile),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SmartFloorPlan',
                style: TextStyle(
                  color: navy,
                  fontSize: isMobile ? 26 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AI House Planning System',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => controller.changeTab(2),
          child: Obx(
            () {
              final profile = profileController;

              return Container(
                width: isMobile ? 50 : 54,
                height: isMobile ? 50 : 54,
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    profile.initialName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 22 : 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 28),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(isMobile ? 28 : 32),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 54 : 58,
            height: isMobile ? 54 : 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: isMobile ? 30 : 32,
            ),
          ),
          SizedBox(height: isMobile ? 22 : 26),
          Text(
            'Generate Denah Rumah\nDengan AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 25 : 28,
              fontWeight: FontWeight.bold,
              height: 1.18,
            ),
          ),
          SizedBox(height: isMobile ? 14 : 18),
          Text(
            'Buat desain rumah otomatis berdasarkan ukuran lahan, kebutuhan ruangan, dan sketsa denah.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 13.5 : 15,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 28),
          SizedBox(
            width: double.infinity,
            height: isMobile ? 52 : 54,
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.generateForm),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                'Mulai Generate',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14.5 : 15.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: navy,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu({required bool isMobile}) {
    return Row(
      children: [
        Expanded(
          child: _buildMenuCard(
            isMobile: isMobile,
            icon: Icons.architecture_rounded,
            title: 'Generate\nDenah',
            subtitle: 'Buat denah dari input kebutuhan rumah',
            onTap: () => Get.toNamed(AppRoutes.generateForm),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMenuCard(
            isMobile: isMobile,
            icon: Icons.document_scanner_rounded,
            title: 'Scan\nSketsa',
            subtitle: 'Ubah gambar sketsa menjadi denah digital',
            onTap: () => Get.toNamed(AppRoutes.scanDenah),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required bool isMobile,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isMobile ? 218 : 235,
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 26 : 30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 66 : 74,
              height: isMobile ? 66 : 74,
              decoration: BoxDecoration(
                color: softGrey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: navy,
                size: isMobile ? 34 : 38,
              ),
            ),
            SizedBox(height: isMobile ? 14 : 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: isMobile ? 18 : 20,
                height: 1.15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black45,
                fontSize: isMobile ? 11.5 : 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    final ProfileController profile = profileController;

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
                onRefresh: profile.loadProfile,
                color: orange,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    isMobile ? 18 : 24,
                    isMobile ? 16 : 24,
                    110,
                  ),
                  child: Obx(
                    () {
                      if (profile.isLoading.value) {
                        return SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.70,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: orange,
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profil',
                            style: TextStyle(
                              color: navy,
                              fontSize: isMobile ? 26 : 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Informasi pengguna aplikasi SmartFloorPlan.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: isMobile ? 13.5 : 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isMobile ? 20 : 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.035),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: isMobile ? 82 : 90,
                                  height: isMobile ? 82 : 90,
                                  decoration: BoxDecoration(
                                    color: navy,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Center(
                                    child: Text(
                                      profile.initialName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isMobile ? 34 : 38,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  profile.displayName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: isMobile ? 21 : 23,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  profile.displayEmail,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: isMobile ? 13.5 : 14.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: orange.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Text(
                                    'Akun Aktif',
                                    style: TextStyle(
                                      color: orange,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 26),
                                _buildProfileMenu(
                                  icon: Icons.info_rounded,
                                  title: 'Tentang Aplikasi',
                                  subtitle: 'SmartFloorPlan Capstone Project',
                                  onTap: () {
                                    Get.snackbar(
                                      'Tentang Aplikasi',
                                      'SmartFloorPlan membantu membuat denah rumah 2D, edit layout, RAB, dan scan sketsa.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: navy,
                                      colorText: Colors.white,
                                    );
                                  },
                                ),

                                _buildProfileMenu(
                                  icon: Icons.help_rounded,
                                  title: 'Bantuan Penggunaan',
                                  subtitle: 'Panduan singkat fitur aplikasi',
                                  onTap: () {
                                    Get.snackbar(
                                      'Bantuan',
                                      'Gunakan Generate Denah untuk membuat layout, atau Scan Sketsa untuk membaca gambar denah.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: navy,
                                      colorText: Colors.white,
                                    );
                                  },
                                ),
                                _buildProfileMenu(
  icon: Icons.history_rounded,
  title: 'Activity Log',
  subtitle: 'Lihat riwayat aktivitas pengguna',
  onTap: () {
    Get.toNamed(AppRoutes.ACTIVITY_LOG);
  },
),
                                Obx(
                                  () => _buildProfileMenu(
                                    icon: Icons.logout_rounded,
                                    title: profile.isLoggingOut.value
                                        ? 'Logout...'
                                        : 'Logout',
                                    subtitle: 'Keluar dari akun SmartFloorPlan',
                                    iconColor: Colors.red,
                                    textColor: Colors.red,
                                    onTap: profile.isLoggingOut.value
                                        ? () {}
                                        : profile.logout,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileMenu({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = navy,
    Color textColor = navy,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor.withOpacity(0.55),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Obx(() {
      final currentIndex = controller.selectedIndex.value;

      return Container(
        margin: const EdgeInsets.fromLTRB(6, 0, 6, 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: controller.changeTab,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: navy,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
      icon: Icon(Icons.analytics), // ✅ TAMBAHKAN INI
      label: 'Analisis',
    ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      );
    });
  }
}