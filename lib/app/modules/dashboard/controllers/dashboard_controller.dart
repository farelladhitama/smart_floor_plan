import 'package:get/get.dart';

class DashboardController extends GetxController {
  final selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments != null && Get.arguments is int) {
      selectedIndex.value = Get.arguments as int;
    }
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void goToHistoryTab() {
    selectedIndex.value = 2;
  }

  void goToProfileTab() {
    selectedIndex.value = 3;
  }

  void goToHomeTab() {
    selectedIndex.value = 0;
  }
}