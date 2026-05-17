import 'package:get/get.dart';

import '../controllers/ai_loading_controller.dart';

class AiLoadingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiLoadingController>(
      () => AiLoadingController(),
    );
  }
}