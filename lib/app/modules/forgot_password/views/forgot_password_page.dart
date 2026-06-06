import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/modules/forgot_password/controllers/forgot_password_controller.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ForgotPasswordController>()
        ? Get.find<ForgotPasswordController>()
        : Get.put(ForgotPasswordController());

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
                'Lupa Password',
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
                        Icons.lock_reset_rounded,
                        color: orange,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan email akun kamu. Kami akan mengirim link untuk membuat password baru.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'contoh@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 17,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE1E7EF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: orange, width: 1.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.sendResetPasswordEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text(
                                  'KIRIM LINK RESET',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Catatan: cek folder spam jika email belum masuk.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
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
