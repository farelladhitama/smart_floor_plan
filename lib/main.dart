import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// VIEWS
import 'views/splash/splash_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/login/login_screen.dart';
import 'views/dashboard/dashboard_page.dart';
import 'views/generate_form/generate_form_page.dart';

// CORE
import 'core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartFloorPlanApp());
}

class SmartFloorPlanApp extends StatelessWidget {
  const SmartFloorPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartFloorPlan',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'SanFrancisco',
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => CinematicSplashScreen()),
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/dashboard', page: () => const DashboardPage()),
        GetPage(name: '/generate-form', page: () => const GenerateFormPage()),
      ],
    );
  }
}