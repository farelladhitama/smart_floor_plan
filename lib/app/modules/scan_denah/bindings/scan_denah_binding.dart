import 'package:get/get.dart';
import '../controllers/scan_denah_controller.dart';

class ScanDenahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScanDenahController>(() => ScanDenahController());
  }
}