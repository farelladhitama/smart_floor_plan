import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_floor_plan/app/routes/app_routes.dart';
import 'package:smart_floor_plan/app/services/activity_log_service.dart';

class ProfileController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  final RxBool isLoading = false.obs;
  final RxBool isLoggingOut = false.obs;
  final RxBool isUpdatingEmail = false.obs;

  final RxString fullName = ''.obs;
  final RxString email = ''.obs;
  final RxString userId = ''.obs;

  final TextEditingController emailController = TextEditingController();

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> loadProfile() async {
    final User? user = _supabase.auth.currentUser;

    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    try {
      isLoading.value = true;

      userId.value = user.id;
      email.value = user.email ?? '';

      final Map<String, dynamic>? profile = await _supabase
          .from('profiles')
          .select('full_name, email')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        fullName.value = (profile['full_name'] ?? '').toString();
        email.value = (profile['email'] ?? user.email ?? '').toString();
      } else {
        fullName.value =
            user.userMetadata?['full_name']?.toString().trim() ??
                user.userMetadata?['display_name']?.toString().trim() ??
                'Pengguna SmartFloorPlan';
      }
    } on PostgrestException catch (error) {
      showMessage(
        'Gagal Memuat Profil',
        error.message,
      );
    } catch (error) {
      showMessage(
        'Gagal Memuat Profil',
        'Terjadi kesalahan: $error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    if (isLoggingOut.value) {
      return;
    }

    try {
      isLoggingOut.value = true;

      await ActivityLogService.addLog(
        title: "Logout",
        description: "User keluar dari aplikasi",
        icon: "logout",
      );

      await _supabase.auth.signOut();

      Get.offAllNamed(AppRoutes.login);
      showMessage(
        'Logout Berhasil',
        'Anda telah keluar dari akun SmartFloorPlan.',
      );
    } catch (error) {
      showMessage(
        'Logout Gagal',
        'Terjadi kesalahan: $error',
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final String trimmed = newEmail.trim();

    if (trimmed.isEmpty) {
      showMessage('Gagal', 'Email tidak boleh kosong.');
      return;
    }

    if (trimmed == email.value) {
      showMessage('Gagal', 'Email baru sama dengan email aktif.');
      return;
    }

    if (!GetUtils.isEmail(trimmed)) {
      showMessage('Gagal', 'Format email tidak valid.');
      return;
    }

    try {
      isUpdatingEmail.value = true;

      // Update Supabase Auth — Supabase kirim link konfirmasi ke email baru
      await _supabase.auth.updateUser(
  UserAttributes(
    email: trimmed,
  ),
  emailRedirectTo:
      'https://achmadmundakir.pythonanywhere.com',
);
      // Update tabel profiles
      await _supabase
          .from('profiles')
          .update({'email': trimmed})
          .eq('id', userId.value);

      // Catat activity log
      await ActivityLogService.addLog(
        title: 'Permintaan Ganti Email',
        description: 'Permintaan ganti email ke $trimmed',
        icon: 'email',
      );

      Get.back();

      showMessage(
        'Cek Email Kamu',
        'Link konfirmasi dikirim ke $trimmed. Email akan berganti setelah dikonfirmasi.',
      );
    } on AuthException catch (e) {
      showMessage('Gagal Ganti Email', e.message);
    } on PostgrestException catch (e) {
      showMessage('Gagal Ganti Email', e.message);
    } catch (e) {
      showMessage('Gagal Ganti Email', 'Terjadi kesalahan: $e');
    } finally {
      isUpdatingEmail.value = false;
    }
  }

  String get displayName {
    if (fullName.value.trim().isEmpty) {
      return 'Pengguna SmartFloorPlan';
    }
    return fullName.value.trim();
  }

  String get displayEmail {
    if (email.value.trim().isEmpty) {
      return 'Email tidak tersedia';
    }
    return email.value.trim();
  }

  String get initialName {
    final String name = displayName.trim();
    if (name.isEmpty) {
      return 'S';
    }
    return name[0].toUpperCase();
  }

  void showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 4),
      icon: const Icon(
        Icons.info_outline_rounded,
        color: orange,
      ),
    );
  }
}