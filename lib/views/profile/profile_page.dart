import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);

  String username = '-';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      username = prefs.getString('username') ?? 'User SmartFloorPlan';
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', false);

    Get.offAllNamed('/login');
  }

  void showComingSoon(String title) {
    Get.snackbar(
      'Info',
      '$title belum tersedia. Fitur ini bisa dikembangkan nanti.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }

  void confirmLogout() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 28),

                      _buildProfileCard(),

                      const SizedBox(height: 28),

                      const Text(
                        'Pengaturan Akun',
                        style: TextStyle(
                          color: navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profil',
                        subtitle: 'Ubah nama pengguna dan informasi akun',
                        onTap: () => showComingSoon('Edit Profil'),
                      ),

                      _buildMenuItem(
                        icon: Icons.lock_outline_rounded,
                        title: 'Ganti Password',
                        subtitle: 'Perbarui password akun lokal Anda',
                        onTap: () => showComingSoon('Ganti Password'),
                      ),

                      _buildMenuItem(
                        icon: Icons.palette_outlined,
                        title: 'Tema Aplikasi',
                        subtitle: 'Atur tampilan dan warna aplikasi',
                        onTap: () => showComingSoon('Tema Aplikasi'),
                      ),

                      _buildMenuItem(
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang Aplikasi',
                        subtitle: 'SmartFloorPlan versi demo project',
                        onTap: () => showComingSoon('Tentang Aplikasi'),
                      ),

                      const SizedBox(height: 18),

                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Profil',
            style: TextStyle(
              color: navy,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Pengguna SmartFloorPlan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  value: 'AI',
                  label: 'Generator',
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withOpacity(0.15),
              ),
              Expanded(
                child: _buildStatItem(
                  value: '2D',
                  label: 'Denah',
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withOpacity(0.15),
              ),
              Expanded(
                child: _buildStatItem(
                  value: 'RAB',
                  label: 'Estimasi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: orange,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.70),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: orange,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.grey,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: confirmLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}