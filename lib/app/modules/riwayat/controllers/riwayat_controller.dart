import 'package:get/get.dart';

class RiwayatController extends GetxController {
  final histories = <Map<String, dynamic>>[
    {
      'title': 'Denah Rumah 8x12',
      'subtitle': '4 Ruangan • Batu Bata',
      'date': 'Terakhir dibuat: Hari ini',
      'type': 'manual',
    },
    {
      'title': 'Denah Rumah 10x15',
      'subtitle': '6 Ruangan • Hebel',
      'date': 'Terakhir dibuat: Kemarin',
      'type': 'manual',
    },
    {
      'title': 'Scan Sketsa Denah',
      'subtitle': '5 Ruangan • OpenCV',
      'date': 'Hasil scan terakhir',
      'type': 'scan',
    },
  ].obs;

  void openDetail(String title) {
    Get.snackbar(
      'Detail Denah',
      'Detail "$title" masih berupa tampilan demo.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openEdit(String title) {
    Get.snackbar(
      'Edit Denah',
      'Edit "$title" dari riwayat belum aktif pada versi demo.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}