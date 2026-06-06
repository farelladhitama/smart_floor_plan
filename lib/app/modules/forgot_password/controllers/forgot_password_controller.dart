import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final isLoading = false.obs;

  SupabaseClient get supabase => Supabase.instance.client;

  Future<void> sendResetPasswordEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'Email tidak valid',
        'Masukkan email yang benar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'http://localhost:3000',
      );

      Get.snackbar(
        'Berhasil',
        'Link reset password sudah dikirim ke email. Silakan cek inbox atau spam.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on AuthException catch (e) {
      Get.snackbar(
        'Gagal',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}

