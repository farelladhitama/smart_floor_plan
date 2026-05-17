import 'package:get/get.dart';

class DashboardController extends GetxController {
  final selectedIndex = 0.obs;

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void goToProfileTab() {
    selectedIndex.value = 2;
  }

  void goToHistoryTab() {
    selectedIndex.value = 1;
  }

  void goToHomeTab() {
    selectedIndex.value = 0;
  }
}