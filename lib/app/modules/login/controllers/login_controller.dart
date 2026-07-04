import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_floor_plan/app/routes/app_routes.dart';
import 'package:smart_floor_plan/app/services/activity_log_service.dart';

enum AuthMode {
  login,
  register,
}

class LoginController extends GetxController {
  static const String otpVerifiedKey = 'login_otp_verified';

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final Rx<AuthMode> authMode = AuthMode.login.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordHidden = true.obs;
  final RxBool isConfirmPasswordHidden = true.obs;

  SupabaseClient get _supabase => Supabase.instance.client;

  bool get isLogin => authMode.value == AuthMode.login;
  bool get isRegister => authMode.value == AuthMode.register;

  String get titleText {
    return isLogin ? 'Selamat Datang' : 'Buat Akun Baru';
  }

  String get descriptionText {
    return isLogin
        ? 'Masuk menggunakan email dan password.'
        : 'Daftarkan akun baru untuk menyimpan hasil denah Anda.';
  }

  String get submitButtonText {
    return isLogin ? 'Masuk' : 'Daftar Akun';
  }

  void changeMode(AuthMode mode) {
    if (isLoading.value || authMode.value == mode) {
      return;
    }

    authMode.value = mode;

    passwordController.clear();
    confirmPasswordController.clear();

    isPasswordHidden.value = true;
    isConfirmPasswordHidden.value = true;

    if (mode == AuthMode.login) {
      nameController.clear();
    }
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  Future<void> submitAuth() async {
    if (isLoading.value) {
      return;
    }

    if (isLogin) {
      await loginWithPasswordThenCheckOtp();
    } else {
      await registerWithEmail();
    }
  }

  Future<void> registerWithEmail() async {
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

      /*
       * REGISTER:
       * Hanya membuat akun.
       * Supabase untuk alur ini:
       * - Confirm Email = OFF
       * - Email Provider = ON
       */
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'display_name': name,
          otpVerifiedKey: false,
        },
      );

      if (response.user == null) {
        showMessage(
          'Register Gagal',
          'Akun tidak berhasil dibuat.',
        );
        return;
      }

      /*
       * Kalau session null, biasanya Confirm Email masih ON.
       * Untuk alur OTP saat login, Confirm Email harus OFF.
       */
      if (response.session == null) {
        showMessage(
          'Pengaturan Supabase Belum Sesuai',
          'Matikan Confirm Email di Supabase, hapus akun tes ini, lalu daftar ulang.',
        );
        return;
      }

      await _supabase.auth.signOut();

      authMode.value = AuthMode.login;
      emailController.text = email;

      nameController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      isPasswordHidden.value = true;
      isConfirmPasswordHidden.value = true;

      showMessage(
        'Pendaftaran Berhasil',
        'Akun berhasil dibuat. Silakan login untuk verifikasi OTP pertama kali.',
      );
    } on AuthException catch (error) {
      showMessage(
        'Register Gagal',
        _readableAuthMessage(error.message),
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

  Future<void> loginWithPasswordThenCheckOtp() async {
    final String email = emailController.text.trim().toLowerCase();
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage(
        'Data Belum Lengkap',
        'Email dan password harus diisi.',
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

    try {
      isLoading.value = true;

      /*
       * Tahap 1:
       * Cek email dan password.
       */
      final AuthResponse passwordResponse =
          await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = passwordResponse.user;
      final Session? session = passwordResponse.session;

      if (user == null || session == null) {
        showMessage(
          'Login Gagal',
          'Email atau password salah.',
        );
        return;
      }

      final bool alreadyVerified = _isOtpVerified(user);

      /*
       * Jika user sudah pernah berhasil OTP,
       * login berikutnya langsung Dashboard.
       */
      if (alreadyVerified) {
        await ActivityLogService.addLog(
           title: "Login",
         description: "User berhasil login ke aplikasi",
        icon: "login",
        );
        Get.offAllNamed(AppRoutes.dashboard);

        showMessage(
          'Login Berhasil',
          'Selamat datang kembali di SmartFloorPlan.',
        );
        return;
      }

      /*
       * Jika user belum pernah OTP:
       * tutup session password sementara,
       * lalu kirim OTP login ke Gmail.
       */
      final String name =
          user.userMetadata?['full_name']?.toString().trim() ?? '';

      await _supabase.auth.signOut();

      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      showMessage(
        'OTP Telah Dikirim',
        'Periksa Gmail Anda untuk kode OTP login.',
      );

      await Get.toNamed(
        AppRoutes.otpVerification,
        arguments: {
          'email': email,
          'name': name,
          'flow': 'login_otp',
        },
      );
    } on AuthException catch (error) {
      showMessage(
        'Login Gagal',
        _readableAuthMessage(error.message),
      );
    } catch (error) {
      showMessage(
        'Login Gagal',
        'Terjadi kesalahan: $error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool _isOtpVerified(User user) {
    final dynamic status = user.userMetadata?[otpVerifiedKey];

    if (status == true) {
      return true;
    }

    if (status == null) {
      return false;
    }

    return status.toString().toLowerCase() == 'true';
  }

  void forgotPasswordComingSoon() {
    showMessage(
      'Segera Hadir',
      'Fitur lupa password akan disambungkan setelah autentikasi utama selesai.',
    );
  }

  void loginWithGoogleComingSoon() {
    showMessage(
      'Segera Hadir',
      'Login Google akan disambungkan setelah autentikasi email dan OTP stabil.',
    );
  }

  String _readableAuthMessage(String? message) {
    final String safeMessage = message ?? 'Terjadi kesalahan autentikasi.';
    final String lowerMessage = safeMessage.toLowerCase();

    if (lowerMessage.contains('email signups are disabled') ||
        lowerMessage.contains('signup is disabled')) {
      return 'Pendaftaran email belum aktif. Nyalakan Email Provider dan Email Signups di Supabase.';
    }

    if (lowerMessage.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }

    if (lowerMessage.contains('email not confirmed')) {
      return 'Confirm Email masih aktif. Matikan Confirm Email di Supabase untuk alur OTP saat login.';
    }

    if (lowerMessage.contains('user already registered')) {
      return 'Email sudah terdaftar. Silakan gunakan menu Login.';
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

  /*
   * Sengaja tidak dispose TextEditingController manual.
   * Pada Flutter Web + GetX route transition, controller bisa masih terbaca
   * ketika animasi perpindahan halaman berlangsung.
   */
}