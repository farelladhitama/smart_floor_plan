import 'package:get/get.dart';
import 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';

class RabBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RabController>(() => RabController());
  }
}
