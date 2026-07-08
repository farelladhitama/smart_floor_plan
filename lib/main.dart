import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/core/supabase/supabase_config.dart';
import 'app/core/theme/app_colors.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';
import 'app/services/material_item_service.dart'; // ✅ SUDAH BENAR
import 'app/modules/analysis/controllers/analysis_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.publishableKey,
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
        useMaterial3: true,
      ),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      initialBinding: AppBinding(),
    );
  }
}

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ PERBAIKAN: MaterialItemService, BUKAN MaterialService
    Get.put(MaterialItemService(), permanent: true);
    Get.put(AnalysisController(), permanent: true);
  }
}