import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/otp_verification_controller.dart';

class OtpVerificationPage extends GetView<OtpVerificationController> {
  const OtpVerificationPage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color pageBackground = Color(0xFFF4F7FA);
  static const Color textSecondary = Color(0xFF66758A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 880;

          return Stack(
            children: [
              const _OtpBackground(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 36 : 20,
                      vertical: isDesktop ? 28 : 18,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Expanded(
                                  flex: 9,
                                  child: _OtpBrandPanel(),
                                ),
                                const SizedBox(width: 34),
                                Expanded(
                                  flex: 8,
                                  child: _OtpCard(
                                    controller: controller,
                                    isDesktop: true,
                                  ),
                                ),
                              ],
                            )
                          : _OtpCard(
                              controller: controller,
                              isDesktop: false,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OtpBackground extends StatelessWidget {
  const _OtpBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -95,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              color: OtpVerificationPage.orange.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -120,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              color: OtpVerificationPage.navy.withValues(alpha: 0.035),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpBrandPanel extends StatelessWidget {
  const _OtpBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 532,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: OtpVerificationPage.navy,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: OtpVerificationPage.navy.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.architecture_rounded,
              color: OtpVerificationPage.orange,
              size: 29,
            ),
          ),
          const Spacer(),
          const Text(
            'Verifikasi\nkeamanan.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Masukkan kode OTP dari email untuk memastikan hanya pemilik akun yang dapat masuk ke dashboard.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: OtpVerificationPage.orange,
                  size: 21,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Dashboard hanya dibuka setelah OTP berhasil diverifikasi.',
                    style: TextStyle(
                      color: Color(0xFFC5CED8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpCard extends StatelessWidget {
  final OtpVerificationController controller;
  final bool isDesktop;

  const _OtpCard({
    required this.controller,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 24,
        isDesktop ? 34 : 30,
        isDesktop ? 32 : 24,
        isDesktop ? 30 : 26,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 30 : 28),
        border: Border.all(
          color: const Color(0xFFE9EEF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isDesktop ? 68 : 64,
              height: isDesktop ? 68 : 64,
              decoration: BoxDecoration(
                color: OtpVerificationPage.orange.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(21),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: OtpVerificationPage.orange,
                size: 34,
              ),
            ),
            const SizedBox(height: 23),
            Text(
              controller.titleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: OtpVerificationPage.navy,
                fontSize: isDesktop ? 28 : 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              controller.descriptionText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OtpVerificationPage.textSecondary,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              controller.maskedEmail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OtpVerificationPage.navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 30),
            _OtpInput(controller: controller),
            const SizedBox(height: 22),
            _VerifyButton(controller: controller),
            const SizedBox(height: 20),
            if (controller.secondsRemaining.value > 0)
              Text(
                'Kirim ulang kode dalam 00:${controller.secondsRemaining.value.toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF798798),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              TextButton(
                onPressed: controller.isResending.value
                    ? null
                    : controller.resendSignupOtp,
                child: controller.isResending.value
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          color: OtpVerificationPage.orange,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kirim Ulang Kode',
                        style: TextStyle(
                          color: OtpVerificationPage.orange,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: controller.backToRegister,
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
              ),
              label: const Text(
                'Kembali ke halaman login',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: OtpVerificationPage.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpInput extends StatelessWidget {
  final OtpVerificationController controller;

  const _OtpInput({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isSmallPhone = screenWidth < 390;

    return TextField(
      controller: controller.otpController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(
          OtpVerificationController.otpLength,
        ),
      ],
      onSubmitted: (_) => controller.verifySignupOtp(),
      style: TextStyle(
        color: OtpVerificationPage.navy,
        fontSize: isSmallPhone ? 21 : 23,
        fontWeight: FontWeight.w900,
        letterSpacing: isSmallPhone ? 4.5 : 6.5,
      ),
      decoration: InputDecoration(
        hintText: '00000000',
        hintStyle: TextStyle(
          color: const Color(0xFFC8D0D9),
          fontSize: isSmallPhone ? 21 : 23,
          fontWeight: FontWeight.w800,
          letterSpacing: isSmallPhone ? 4.5 : 6.5,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 19,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE4E9F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: OtpVerificationPage.orange,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final OtpVerificationController controller;

  const _VerifyButton({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            controller.isVerifying.value ? null : controller.verifySignupOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: OtpVerificationPage.orange,
          disabledBackgroundColor:
              OtpVerificationPage.orange.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: controller.isVerifying.value
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : const Text(
                'Verifikasi & Lanjutkan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}