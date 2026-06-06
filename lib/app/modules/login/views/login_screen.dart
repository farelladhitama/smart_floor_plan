import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/routes/app_routes.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF173451);
  static const Color orange = Color(0xFFE47B3E);
  static const Color orangeLight = Color(0xFFFF9950);
  static const Color background = Color(0xFFF5F7FB);
  static const Color fieldBackground = Color(0xFFF8FAFD);
  static const Color border = Color(0xFFE3EAF2);
  static const Color secondaryText = Color(0xFF718096);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          const _PageBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      const _HeaderCard(),
                      const SizedBox(height: 22),
                      _LoginCard(controller: controller),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageBackground extends StatelessWidget {
  const _PageBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -90,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: LoginScreen.orange.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -120,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              color: LoginScreen.navy.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            LoginScreen.navy,
            LoginScreen.navyLight,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: LoginScreen.navy.withValues(alpha: 0.15),
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
                  'SmartFloorPlan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Rancang rumah lebih cerdas',
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
            Icons.home_work_outlined,
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
            LoginScreen.orange,
            LoginScreen.orangeLight,
          ],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Icon(
        Icons.architecture_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final LoginController controller;

  const _LoginCard({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 380;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 24,
        30,
        compact ? 20 : 24,
        26,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFE9EEF4),
        ),
        boxShadow: [
          BoxShadow(
            color: LoginScreen.navy.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat datang',
              style: TextStyle(
                color: LoginScreen.navy,
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masuk untuk melanjutkan project denah Anda.',
              style: TextStyle(
                color: LoginScreen.secondaryText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            _AppField(
              controller: controller.emailController,
              label: 'Email',
              hintText: 'nama@email.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 17),
            _PasswordField(
              controller: controller,
              label: 'Password',
              hintText: 'Masukkan password',
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => controller.submitAuth(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        Get.toNamed(AppRoutes.forgotPassword);
                      },
                child: const Text(
                  'Lupa password?',
                  style: TextStyle(
                    color: LoginScreen.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SubmitButton(
              isLoading: controller.isLoading.value,
              label: 'Masuk',
              onPressed: controller.submitAuth,
            ),
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Belum punya akun? ',
                    style: TextStyle(
                      color: LoginScreen.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.register);
                    },
                    child: const Text(
                      'Register sekarang',
                    style: TextStyle(
                      color: LoginScreen.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                     ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: LoginScreen.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    color: LoginScreen.orange,
                    size: 19,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'OTP hanya diminta saat verifikasi awal akun.',
                      style: TextStyle(
                        color: LoginScreen.secondaryText,
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final LoginController controller;
  final String label;
  final String hintText;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final bool hidden = controller.isPasswordHidden.value;

        return _AppField(
          controller: controller.passwordController,
          label: label,
          hintText: hintText,
          icon: Icons.lock_outline_rounded,
          obscureText: hidden,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          suffixIcon: IconButton(
            onPressed: controller.togglePasswordVisibility,
            icon: Icon(
              hidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF7D8CA0),
            ),
          ),
        );
      },
    );
  }
}

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  const _AppField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: LoginScreen.navy,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          style: const TextStyle(
            color: LoginScreen.navy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFA0ACBD),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF7A879B),
              size: 22,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: LoginScreen.fieldBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: LoginScreen.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: LoginScreen.orange,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [
                    LoginScreen.orange.withValues(alpha: 0.55),
                    LoginScreen.orangeLight.withValues(alpha: 0.55),
                  ]
                : const [
                    LoginScreen.orange,
                    LoginScreen.orangeLight,
                  ],
          ),
          borderRadius: BorderRadius.circular(17),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: LoginScreen.orange.withValues(alpha: 0.28),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: isLoading
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
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}




