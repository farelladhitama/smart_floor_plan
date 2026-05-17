import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/modules/login/controllers/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color softBg = Color(0xFFEFF3F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 35,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Obx(
                      () => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogo(),

                          const SizedBox(height: 24),

                          Text(
                            controller.isLogin
                                ? 'SmartFloorPlan'
                                : 'Buat Akun Baru',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            controller.isLogin
                                ? 'Masuk untuk mulai membuat desain rumah AI'
                                : 'Daftar untuk menyimpan dan mengelola desain denah rumah Anda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 36),

                          _buildTextField(
                            controllerText: controller.usernameController,
                            hintText: 'Masukkan Username',
                            icon: Icons.person_rounded,
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            controllerText: controller.passwordController,
                            hintText: 'Masukkan Password',
                            icon: Icons.lock_rounded,
                            isPassword: true,
                            isHidden: controller.isPasswordHidden.value,
                            onToggleHidden:
                                controller.togglePasswordVisibility,
                          ),

                          if (!controller.isLogin) ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              controllerText:
                                  controller.confirmPasswordController,
                              hintText: 'Konfirmasi Password',
                              icon: Icons.verified_user_rounded,
                              isPassword: true,
                              isHidden:
                                  controller.isConfirmPasswordHidden.value,
                              onToggleHidden:
                                  controller.toggleConfirmPasswordVisibility,
                            ),
                          ],

                          const SizedBox(height: 18),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.switchMode,
                              child: Text(
                                controller.isLogin
                                    ? 'Belum punya akun? Register'
                                    : 'Sudah punya akun? Login',
                                style: const TextStyle(
                                  color: navy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          _buildMainButton(),

                          const SizedBox(height: 28),

                          _buildDivider(),

                          const SizedBox(height: 24),

                          _buildGoogleButton(),

                          const SizedBox(height: 28),

                          Text(
                            controller.isLogin
                                ? 'Dengan login Anda menyetujui syarat dan ketentuan aplikasi.'
                                : 'Data akun manual disimpan secara lokal untuk kebutuhan demo aplikasi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.architecture_rounded,
            color: Colors.white,
            size: 38,
          ),
          Positioned(
            right: 15,
            bottom: 15,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controllerText,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isHidden = false,
    VoidCallback? onToggleHidden,
  }) {
    return TextField(
      controller: controllerText,
      obscureText: isPassword ? isHidden : false,
      keyboardType: TextInputType.text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey.shade700,
        ),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onToggleHidden,
                icon: Icon(
                  isHidden
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
          borderSide: BorderSide(
            color: orange,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.submitAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          disabledBackgroundColor: navy.withOpacity(0.5),
          elevation: 6,
          shadowColor: navy.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: controller.isLoading.value
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.isLogin ? 'Log In' : 'Register',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    controller.isLogin
                        ? Icons.arrow_forward_rounded
                        : Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'atau lanjut dengan',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed:
            controller.isLoading.value ? null : controller.loginWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 18),
            Text(
              'Login dengan Google',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}