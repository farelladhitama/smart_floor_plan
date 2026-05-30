import 'package:get/get.dart';

import 'app_routes.dart';

import '../modules/splash/views/splash_screen.dart';
import '../modules/onboarding/views/onboarding_screen.dart';
import '../modules/login/views/login_screen.dart';
import '../modules/otp_verification/views/otp_verification_page.dart';
import '../modules/dashboard/views/dashboard_page.dart';
import '../modules/generate_form/views/generate_form_page.dart';
import '../modules/scan_denah/views/scan_denah_page.dart';

import '../modules/splash/bindings/splash_binding.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/otp_verification/bindings/otp_verification_binding.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/generate_form/bindings/generate_form_binding.dart';
import '../modules/scan_denah/bindings/scan_denah_binding.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => CinematicSplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => const OtpVerificationPage(),
      binding: OtpVerificationBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      bindings: [
        DashboardBinding(),
        ProfileBinding(),
      ],
    ),
    GetPage(
      name: AppRoutes.generateForm,
      page: () => const GenerateFormPage(),
      binding: GenerateFormBinding(),
    ),
    GetPage(
      name: AppRoutes.scanDenah,
      page: () => const ScanDenahPage(),
      binding: ScanDenahBinding(),
    ),
  ];
}