import 'package:get/get.dart';

import '../controllers/edit_denah_controller.dart';

class EditDenahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditDenahController>(
      () => EditDenahController(),
    );
  }
}