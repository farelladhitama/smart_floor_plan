import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF173451);
  static const Color orange = Color(0xFFE47B3E);
  static const Color orangeLight = Color(0xFFFF9950);
  static const Color background = Color(0xFFF5F7FB);
  static const Color secondaryText = Color(0xFF718096);
  static const Color border = Color(0xFFE3EAF2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadProfile,
          color: orange,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
            child: Obx(
              () {
                if (controller.isLoading.value) {
                  return SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.75,
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
                    const _HeaderCard(),
                    const SizedBox(height: 22),
                    _ProfileCard(controller: controller),
                    const SizedBox(height: 18),
                    _AccountInfoCard(controller: controller),
                    const SizedBox(height: 18),
                    _MenuCard(controller: controller),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            ProfilePage.navy,
            ProfilePage.navyLight,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: ProfilePage.navy.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          _LogoIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Akun',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Data pengguna SmartFloorPlan',
                  style: TextStyle(
                    color: Color(0xFF9CACBC),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.manage_accounts_rounded,
            color: Color(0xFF52677D),
            size: 31,
          ),
        ],
      ),
    );
  }
}

class _LogoIcon extends StatelessWidget {
  const _LogoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            ProfilePage.orange,
            ProfilePage.orangeLight,
          ],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 31,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ProfileController controller;

  const _ProfileCard({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE9EEF4),
        ),
        boxShadow: [
          BoxShadow(
            color: ProfilePage.navy.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  ProfilePage.orange,
                  ProfilePage.orangeLight,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ProfilePage.orange.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Center(
              child: Text(
                controller.initialName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            controller.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProfilePage.navy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            controller.displayEmail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProfilePage.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: ProfilePage.orange.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: ProfilePage.orange,
                  size: 18,
                ),
                SizedBox(width: 7),
                Text(
                  'Akun aktif',
                  style: TextStyle(
                    color: ProfilePage.orange,
                    fontSize: 13,
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
}

class _AccountInfoCard extends StatelessWidget {
  final ProfileController controller;

  const _AccountInfoCard({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ProfilePage.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Akun',
            style: TextStyle(
              color: ProfilePage.navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.badge_outlined,
            title: 'Nama Lengkap',
            value: controller.displayName,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.alternate_email_rounded,
            title: 'Email',
            value: controller.displayEmail,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: ProfilePage.orange.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: ProfilePage.orange,
            size: 22,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ProfilePage.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: ProfilePage.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final ProfileController controller;

  const _MenuCard({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ProfilePage.border,
        ),
      ),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.refresh_rounded,
            title: 'Muat ulang profil',
            subtitle: 'Ambil ulang data dari Supabase',
            onTap: controller.loadProfile,
          ),
          const Divider(height: 1),
          Obx(
            () => _MenuTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Keluar dari akun SmartFloorPlan',
              isDanger: true,
              isLoading: controller.isLoggingOut.value,
              onTap: controller.logout,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;
  final bool isLoading;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isDanger ? Colors.redAccent : ProfilePage.orange;
    final Color titleColor = isDanger ? Colors.redAccent : ProfilePage.navy;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.redAccent,
                        ),
                      )
                    : Icon(
                        icon,
                        color: iconColor,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: ProfilePage.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AA7B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}