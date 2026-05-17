import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_floor_plan/app/routes/app_routes.dart';

class ProfileController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);

  final username = 'User SmartFloorPlan'.obs;
  final email = ''.obs;
  final photoUrl = ''.obs;
  final isGoogleLogin = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    username.value = prefs.getString('username') ?? 'User SmartFloorPlan';
    email.value = prefs.getString('email') ?? '';
    photoUrl.value = prefs.getString('photoUrl') ?? '';
    isGoogleLogin.value = prefs.getBool('isGoogleLogin') ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', false);

    if (isGoogleLogin.value) {
      await FirebaseAuth.instance.signOut();
    }

    Get.offAllNamed(AppRoutes.login);
  }

  void showInfo(String title) {
    Get.snackbar(
      'Info',
      '$title belum tersedia. Fitur ini bisa dikembangkan nanti.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }
}