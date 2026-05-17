import 'package:get/get.dart';

class AiLoadingController extends GetxController {
  final progressText = 'Menganalisis kebutuhan ruang...'.obs;

  void updateProgress(String text) {
    progressText.value = text;
  }
}