import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:smart_floor_plan/app/routes/app_routes.dart';

enum AuthMode {
  login,
  register,
}

class LoginController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final authMode = AuthMode.login.obs;

  final isPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;
  final isLoading = false.obs;

  bool get isLogin => authMode.value == AuthMode.login;

  void switchMode() {
    authMode.value = isLogin ? AuthMode.register : AuthMode.login;

    usernameController.clear();
    passwordController.clear();
    confirmPasswordController.clear();

    isPasswordHidden.value = true;
    isConfirmPasswordHidden.value = true;
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  Future<void> registerUser() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showMessage('Gagal', 'Semua field harus diisi.');
      return;
    }

    if (username.length < 4) {
      showMessage('Gagal', 'Username minimal 4 karakter.');
      return;
    }

    if (password.length < 6) {
      showMessage('Gagal', 'Password minimal 6 karakter.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Gagal', 'Konfirmasi password tidak sama.');
      return;
    }

    isLoading.value = true;

    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');

    await Future.delayed(const Duration(milliseconds: 500));

    if (savedUsername == username) {
      isLoading.value = false;
      showMessage('Gagal', 'Username sudah terdaftar.');
      return;
    }

    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setString('email', '');
    await prefs.setString('photoUrl', '');
    await prefs.setBool('isRegistered', true);
    await prefs.setBool('isGoogleLogin', false);

    isLoading.value = false;
    authMode.value = AuthMode.login;

    usernameController.clear();
    passwordController.clear();
    confirmPasswordController.clear();

    isPasswordHidden.value = true;
    isConfirmPasswordHidden.value = true;

    showMessage('Berhasil', 'Akun berhasil dibuat. Silakan login.');
  }

  Future<void> loginUser() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showMessage('Gagal', 'Username dan password harus diisi.');
      return;
    }

    isLoading.value = true;

    final prefs = await SharedPreferences.getInstance();

    final savedUsername = prefs.getString('username');
    final savedPassword = prefs.getString('password');

    await Future.delayed(const Duration(milliseconds: 500));

    isLoading.value = false;

    if (savedUsername == null || savedPassword == null) {
      showMessage('Belum Ada Akun', 'Silakan register terlebih dahulu.');
      return;
    }

    if (username == savedUsername && password == savedPassword) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isGoogleLogin', false);

      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      showMessage('Login Gagal', 'Username atau password salah.');
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;

      UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();

        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
      } else {
        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();

        final GoogleSignInAuthentication googleAuth =
            googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      final user = userCredential.user;

      if (user == null) {
        isLoading.value = false;
        showMessage('Gagal', 'Login Google dibatalkan.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'username',
        user.displayName ?? user.email ?? 'Google User',
      );
      await prefs.setString('email', user.email ?? '');
      await prefs.setString('photoUrl', user.photoURL ?? '');
      await prefs.setString('password', '');
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isRegistered', true);
      await prefs.setBool('isGoogleLogin', true);

      isLoading.value = false;

      Get.offAllNamed(AppRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;

      showMessage(
        'Login Google Gagal',
        e.message ?? 'Terjadi kesalahan Firebase Auth.',
      );
    } catch (e) {
      isLoading.value = false;

      showMessage(
        'Login Google Gagal',
        e.toString(),
      );
    }
  }

  Future<void> submitAuth() async {
    if (isLogin) {
      await loginUser();
    } else {
      await registerUser();
    }
  }

  void showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}