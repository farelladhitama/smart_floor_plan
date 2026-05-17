import 'package:get/get.dart';

import '../controllers/rab_controller.dart';

class RABBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RABController>(
      () => RABController(),
    );
  }
}