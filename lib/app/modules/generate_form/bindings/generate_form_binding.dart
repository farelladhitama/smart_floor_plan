import 'package:get/get.dart';

import '../controllers/generate_form_controller.dart';

class GenerateFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GenerateFormController>(
      () => GenerateFormController(),
    );
  }
}