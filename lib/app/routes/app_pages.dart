import 'package:smart_floor_plan/app/modules/rab/views/rab_page.dart';
import 'package:smart_floor_plan/app/modules/rab/bindings/rab_binding.dart';
import 'package:smart_floor_plan/app/modules/forgot_password/bindings/forgot_password_binding.dart';
import 'package:smart_floor_plan/app/modules/reset_password/views/reset_password_page.dart';
import 'package:smart_floor_plan/app/modules/forgot_password/views/forgot_password_page.dart';
import 'package:get/get.dart';

import 'app_routes.dart';

import '../modules/splash/views/splash_screen.dart';
import '../modules/splash/bindings/splash_binding.dart';

import '../modules/onboarding/views/onboarding_screen.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';

import '../modules/login/views/login_screen.dart';
import '../modules/login/bindings/login_binding.dart';

import '../modules/register/views/register_screen.dart';
import '../modules/register/bindings/register_binding.dart';

import '../modules/otp_verification/views/otp_verification_page.dart';
import '../modules/otp_verification/bindings/otp_verification_binding.dart';

import '../modules/dashboard/views/dashboard_page.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';

import '../modules/profile/bindings/profile_binding.dart';

import '../modules/generate_form/views/generate_form_page.dart';
import '../modules/generate_form/bindings/generate_form_binding.dart';

import '../modules/scan_denah/views/scan_denah_page.dart';
import '../modules/scan_denah/bindings/scan_denah_binding.dart';

import 'package:smart_floor_plan/app/modules/activity_log/views/activity_log_page.dart';
import 'package:smart_floor_plan/app/modules/activity_log/bindings/activity_log_binding.dart';


class AppPages {
    static String get initial {
    final String url = Uri.base.toString();

    if (url.contains('type=recovery') ||
        url.contains('access_token') ||
        url.contains('refresh_token') ||
        url.contains('token_hash') ||
        url.contains('code=')) {
      return AppRoutes.resetPassword;
    }

    return AppRoutes.splash;
  }

  static final routes = [
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordPage(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordPage(),
    ),

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
    // Tambahkan di daftar routes

    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: RegisterBinding(),
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
    GetPage(
  name: AppRoutes.rab,
  page: () => const RabPage(),
  binding: RabBinding(),
),

GetPage(
  name: AppRoutes.ACTIVITY_LOG,
  page: () => const ActivityLogPage(),
  binding: ActivityLogBinding(),
),
    ];
}




