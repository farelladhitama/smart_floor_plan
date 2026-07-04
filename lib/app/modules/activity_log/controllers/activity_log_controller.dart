import 'package:get/get.dart';
import 'package:smart_floor_plan/app/modules/activity_log/models/activity_log_model.dart';
import 'package:smart_floor_plan/app/services/activity_log_service.dart';

class ActivityLogController extends GetxController {
  final RxBool isLoading = false.obs;

  final RxList<ActivityLogModel> logs =
      <ActivityLogModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadLogs();
  }

  Future<void> loadLogs() async {
    try {
      isLoading.value = true;

      final result = await ActivityLogService.getLogs();

      logs.assignAll(result);
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshLogs() async {
    await loadLogs();
  }

  Future<void> deleteLog(String id) async {
    await ActivityLogService.deleteLog(id);

    logs.removeWhere((e) => e.id == id);
  }

  Future<void> clearLogs() async {
    await ActivityLogService.clearLogs();

    logs.clear();
  }
}