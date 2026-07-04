import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/activity_log_controller.dart';

class ActivityLogPage extends GetView<ActivityLogController> {
  const ActivityLogPage({super.key});

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'login':
        return Icons.login;

      case 'logout':
        return Icons.logout;

      case 'home':
        return Icons.home;

      case 'save':
        return Icons.save;

      case 'delete':
        return Icons.delete;

      case 'edit':
        return Icons.edit;

      case 'history':
        return Icons.history;

      case 'scan':
        return Icons.document_scanner;

      default:
        return Icons.history;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity Log"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text("Hapus Semua?"),
                  content: const Text(
                    "Seluruh riwayat aktivitas akan dihapus.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text("Hapus"),
                    ),
                  ],
                ),
              );

              if (result == true) {
                controller.clearLogs();
              }
            },
            icon: const Icon(Icons.delete_forever),
          )
        ],
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 70,
                  color: Colors.grey,
                ),
                SizedBox(height: 15),
                Text(
                  "Belum ada aktivitas",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Semua aktivitas akan muncul di sini.",
                )
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshLogs,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.logs.length,
            itemBuilder: (context, index) {
              final log = controller.logs[index];

              return Dismissible(
                key: ValueKey(log.id),

                direction: DismissDirection.endToStart,

                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),

                onDismissed: (_) {
                  if (log.id != null) {
                    controller.deleteLog(log.id!);
                  }
                },

                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),

                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        _getIcon(log.icon),
                      ),
                    ),

                    title: Text(
                      log.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        Text(log.description),

                        const SizedBox(height: 6),

                        Text(
                          _formatDate(log.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}