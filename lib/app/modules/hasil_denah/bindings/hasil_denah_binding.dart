import 'package:get/get.dart';

import '../controllers/hasil_denah_controller.dart';

class HasilDenahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HasilDenahController>(
      () => HasilDenahController(),
    );
  }
}