import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_floor_plan/app/routes/app_routes.dart';

class OtpVerificationController extends GetxController {
  static const String otpVerifiedKey = 'login_otp_verified';
  static const int otpLength = 6;

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  final TextEditingController otpController = TextEditingController();

  final RxBool isVerifying = false.obs;
  final RxBool isResending = false.obs;
  final RxInt secondsRemaining = 60.obs;

  String email = '';
  String name = '';
  String flow = 'login_otp';

  Timer? _timer;

  SupabaseClient get _supabase => Supabase.instance.client;

  String get titleText {
    return 'Verifikasi Email';
  }

  String get descriptionText {
    return 'Masukkan kode OTP yang telah dikirim ke Gmail Anda untuk melanjutkan login.';
  }

  String get greetingText {
    if (name.isEmpty) {
      return 'Verifikasi login Anda';
    }

    return 'Halo, $name';
  }

  String get maskedEmail {
    if (email.isEmpty || !email.contains('@')) {
      return email;
    }

    final List<String> parts = email.split('@');
    final String username = parts.first;
    final String domain = parts.last;

    if (username.length <= 2) {
      return '${username.substring(0, 1)}***@$domain';
    }

    return '${username.substring(0, 2)}***@$domain';
  }

  @override
  void onInit() {
    super.onInit();

    final Map<String, dynamic> arguments =
        (Get.arguments as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    email = (arguments['email'] ?? '').toString().trim().toLowerCase();
    name = (arguments['name'] ?? '').toString().trim();
    flow = (arguments['flow'] ?? 'login_otp').toString();

    if (email.isEmpty) {
      Future.microtask(() {
        Get.back();
      });
      return;
    }

    startResendTimer();
  }

  void startResendTimer([int seconds = 60]) {
    _timer?.cancel();
    secondsRemaining.value = seconds;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (secondsRemaining.value <= 1) {
          secondsRemaining.value = 0;
          timer.cancel();
          return;
        }

        secondsRemaining.value--;
      },
    );
  }

  Future<void> verifyLoginOtp() async {
    if (isVerifying.value) {
      return;
    }

    final String otp = otpController.text.trim();

    if (otp.isEmpty) {
      showMessage(
        'Kode OTP Kosong',
        'Masukkan kode OTP yang dikirim ke Gmail Anda.',
      );
      return;
    }

    if (otp.length != otpLength) {  // 6
  showMessage('Kode OTP Tidak Valid', 'Kode OTP harus terdiri dari $otpLength angka.');
  return;
}

    try {
      isVerifying.value = true;

      /*
       * OTP ini berasal dari signInWithOtp(),
       * maka verifikasinya memakai OtpType.email.
       */
      final AuthResponse response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.user == null || response.session == null) {
        showMessage(
          'Verifikasi Gagal',
          'Kode OTP salah atau sudah kedaluwarsa.',
        );
        return;
      }

      /*
       * Setelah OTP pertama berhasil, simpan tanda di metadata.
       * Login berikutnya cukup email dan password.
       */
      final UserResponse updateResponse = await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            otpVerifiedKey: true,
            'login_otp_verified_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      if (updateResponse.user == null) {
        showMessage(
          'Verifikasi Gagal',
          'OTP benar, tetapi status verifikasi gagal disimpan.',
        );
        return;
      }

      _timer?.cancel();

      Get.offAllNamed(AppRoutes.dashboard);

      showMessage(
        'Login Berhasil',
        'OTP berhasil diverifikasi. Login berikutnya cukup menggunakan password.',
      );
    } on AuthException catch (error) {
      showMessage(
        'Verifikasi Gagal',
        _readableAuthMessage(error.message),
      );
    } catch (error) {
      showMessage(
        'Verifikasi Gagal',
        'Terjadi kesalahan: $error',
      );
    } finally {
      isVerifying.value = false;
    }
  }

  Future<void> resendLoginOtp() async {
    if (isResending.value || secondsRemaining.value > 0) {
      return;
    }

    try {
      isResending.value = true;

      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      otpController.clear();
      startResendTimer();

      showMessage(
        'OTP Dikirim Ulang',
        'Kode OTP login baru telah dikirim ke Gmail Anda.',
      );
    } on AuthException catch (error) {
      showMessage(
        'Gagal Mengirim OTP',
        _readableAuthMessage(error.message),
      );
    } catch (error) {
      showMessage(
        'Gagal Mengirim OTP',
        'Terjadi kesalahan: $error',
      );
    } finally {
      isResending.value = false;
    }
  }

  Future<void> backToLogin() async {
    _timer?.cancel();
    otpController.clear();

    Get.back();
  }

  /*
   * Alias agar aman jika otp_verification_page.dart lama masih memanggil
   * nama method lama.
   */
  Future<void> verifySignupOtp() async {
    await verifyLoginOtp();
  }

  Future<void> resendSignupOtp() async {
    await resendLoginOtp();
  }

  Future<void> backToRegister() async {
    await backToLogin();
  }

  String _readableAuthMessage(String? message) {
    final String safeMessage = message ?? 'Terjadi kesalahan autentikasi.';
    final String lowerMessage = safeMessage.toLowerCase();

    if (lowerMessage.contains('expired')) {
      return 'Kode OTP sudah kedaluwarsa. Silakan kirim ulang kode.';
    }

    if (lowerMessage.contains('invalid') ||
        lowerMessage.contains('token')) {
      return 'Kode OTP salah atau sudah tidak berlaku.';
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

  @override
  void onClose() {
    _timer?.cancel();

    /*
     * Jangan dispose otpController manual agar aman di Flutter Web.
     */
    super.onClose();
  }
}