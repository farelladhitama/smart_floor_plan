import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_floor_plan/app/routes/app_routes.dart';

class RegisterController extends GetxController {
  static const String otpVerifiedKey = 'login_otp_verified';

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isPasswordHidden = true.obs;
  final RxBool isConfirmPasswordHidden = true.obs;

  SupabaseClient get _supabase => Supabase.instance.client;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  Future<void> registerWithEmail() async {
    if (isLoading.value) {
      return;
    }

    final String name = nameController.text.trim();
    final String email = emailController.text.trim().toLowerCase();
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage(
        'Data Belum Lengkap',
        'Semua data pendaftaran harus diisi.',
      );
      return;
    }

    if (name.length < 3) {
      showMessage(
        'Nama Tidak Valid',
        'Nama minimal terdiri dari 3 karakter.',
      );
      return;
    }

    if (!GetUtils.isEmail(email)) {
      showMessage(
        'Email Tidak Valid',
        'Masukkan alamat email yang benar.',
      );
      return;
    }

    if (password.length < 8) {
      showMessage(
        'Password Lemah',
        'Password minimal terdiri dari 8 karakter.',
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage(
        'Konfirmasi Salah',
        'Konfirmasi password tidak sama.',
      );
      return;
    }

    try {
      isLoading.value = true;

      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'display_name': name,
          otpVerifiedKey: false,
        },
      );

      final User? user = response.user;
      final Session? session = response.session;

      if (user == null) {
        showMessage(
          'Register Gagal',
          'Akun tidak berhasil dibuat.',
        );
        return;
      }

      if (session == null) {
        showMessage(
          'Pengaturan Supabase Belum Sesuai',
          'Matikan Confirm Email di Supabase, hapus akun tes ini, lalu daftar ulang.',
        );
        return;
      }

      /*
       * Simpan data user ke tabel public.profiles.
       * Jadi data user tidak hanya ada di Authentication,
       * tetapi juga ada di database aplikasi.
       */
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _supabase.auth.signOut();

      showMessage(
        'Pendaftaran Berhasil',
        'Akun berhasil dibuat. Silakan login untuk verifikasi OTP pertama kali.',
      );

      Get.offNamed(
        AppRoutes.login,
        arguments: {
          'email': email,
        },
      );
    } on AuthException catch (error) {
      showMessage(
        'Register Gagal',
        _readableAuthMessage(error.message),
      );
    } on PostgrestException catch (error) {
      showMessage(
        'Database Gagal',
        'Akun berhasil dibuat, tetapi profil gagal disimpan: ${error.message}',
      );
    } catch (error) {
      showMessage(
        'Register Gagal',
        'Terjadi kesalahan: $error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _readableAuthMessage(String? message) {
    final String safeMessage = message ?? 'Terjadi kesalahan autentikasi.';
    final String lowerMessage = safeMessage.toLowerCase();

    if (lowerMessage.contains('email signups are disabled') ||
        lowerMessage.contains('signup is disabled')) {
      return 'Pendaftaran email belum aktif. Nyalakan Email Provider dan Email Signups di Supabase.';
    }

    if (lowerMessage.contains('user already registered')) {
      return 'Email sudah terdaftar. Silakan login menggunakan akun tersebut.';
    }

    if (lowerMessage.contains('password')) {
      return 'Password tidak memenuhi aturan keamanan.';
    }

    if (lowerMessage.contains('rate limit') ||
        lowerMessage.contains('too many')) {
      return 'Permintaan terlalu sering. Tunggu beberapa saat lalu coba kembali.';
    }

    return safeMessage;
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