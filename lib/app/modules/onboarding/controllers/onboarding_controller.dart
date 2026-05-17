import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_floor_plan/app/routes/app_routes.dart';

class OnboardingController extends GetxController {
  Future<void> finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('hasSeenOnboarding', true);

    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> skipOnboarding() async {
    await finishOnboarding();
  }
}