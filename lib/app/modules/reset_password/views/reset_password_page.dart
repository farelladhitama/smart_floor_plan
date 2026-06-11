import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  bool isRecoveringSession = true;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  @override
  void initState() {
    super.initState();
    _recoverSessionFromResetLink();
  }

  Future<void> _recoverSessionFromResetLink() async {
    try {
      setState(() => isRecoveringSession = true);

      final uri = Uri.base;
      debugPrint('RESET URL: $uri');

      final errorCode = uri.queryParameters['error_code'];
      final errorDescription = uri.queryParameters['error_description'];

      if (errorCode != null) {
        debugPrint('RESET ERROR CODE: $errorCode');
        debugPrint('RESET ERROR DESC: $errorDescription');

        Get.snackbar(
          'Link reset tidak valid',
          errorDescription ??
              'Link reset sudah expired. Kirim ulang link reset password.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final code = uri.queryParameters['code'];
      debugPrint('RESET CODE: $code');

      if (code != null && code.isNotEmpty) {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
        debugPrint(
          'RESET SESSION AFTER CODE: ${Supabase.instance.client.auth.currentSession != null}',
        );
        return;
      }

      String fragment = uri.fragment;
      debugPrint('RESET FRAGMENT: $fragment');

      if (fragment.contains('?')) {
        fragment = fragment.substring(fragment.indexOf('?') + 1);
      }

      if (fragment.contains('#')) {
        fragment = fragment.substring(fragment.lastIndexOf('#') + 1);
      }

      final params = Uri.splitQueryString(fragment);
      final refreshToken = params['refresh_token'];

      debugPrint('RESET REFRESH TOKEN ADA: ${refreshToken != null}');

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await Supabase.instance.client.auth.setSession(refreshToken);
        debugPrint(
          'RESET SESSION AFTER REFRESH: ${Supabase.instance.client.auth.currentSession != null}',
        );
        return;
      }

      debugPrint(
        'RESET CURRENT SESSION: ${Supabase.instance.client.auth.currentSession != null}',
      );
    } catch (e) {
      debugPrint('Reset password session recovery failed: $e');

      Get.snackbar(
        'Gagal membaca sesi',
        'Kirim ulang link reset password, lalu klik link terbaru satu kali saja.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => isRecoveringSession = false);
      }
    }
  }

  Future<void> updatePassword() async {
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (isRecoveringSession) {
      Get.snackbar(
        'Tunggu',
        'Sedang menyiapkan sesi reset password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (password.length < 6) {
      Get.snackbar(
        'Gagal',
        'Password minimal 6 karakter.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (password != confirm) {
      Get.snackbar(
        'Gagal',
        'Konfirmasi password tidak sama.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        Get.snackbar(
          'Gagal',
          'Session reset password belum terbaca. Kirim ulang link reset dan klik link terbaru.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      Get.snackbar(
        'Berhasil',
        'Password berhasil diperbarui. Silakan login ulang.',
        snackPosition: SnackPosition.BOTTOM,
      );

      await Supabase.instance.client.auth.signOut();
      Get.offAllNamed('/login');
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
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool buttonLoading = isLoading || isRecoveringSession;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: navy,
              elevation: 0,
              title: const Text(
                'Password Baru',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEFE6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.password_rounded,
                        color: orange,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Buat Password Baru',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan password baru untuk akun SmartFloorPlan kamu.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isRecoveringSession) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEFE6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: orange,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Menyiapkan sesi reset password...',
                                style: TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => obscurePassword = !obscurePassword);
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 17,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => obscureConfirm = !obscureConfirm);
                          },
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 17,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: buttonLoading ? null : updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: buttonLoading
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text(
                                'SIMPAN PASSWORD BARU',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
