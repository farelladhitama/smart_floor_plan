import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';

class RABController extends GetxController {
  static const double skala = 20.0;
  static const double hargaPerMeter = 3500000;

  final rooms = <RoomModel>[].obs;

  void setRooms(List<RoomModel> data) {
    rooms.assignAll(data);
  }

  double get totalLuas {
    return rooms.fold<double>(
      0,
      (sum, item) {
        final luasRuangan = (item.width / skala) * (item.height / skala);
        return sum + luasRuangan;
      },
    );
  }

  double get hargaDasar {
    return totalLuas * hargaPerMeter;
  }

  double get biayaStrukturPondasi {
    return hargaDasar * 0.25;
  }

  double get biayaDindingMaterial {
    return hargaDasar * 0.20;
  }

  double get biayaAtapPlafon {
    return hargaDasar * 0.15;
  }

  double get biayaLantaiKeramik {
    return hargaDasar * 0.15;
  }

  double get biayaFinishing {
    return hargaDasar * 0.25;
  }

  String formatRupiah(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        )}';
  }

  void simpanHasilFinal() {
    Get.snackbar(
      'Berhasil',
      'Hasil RAB final berhasil disimpan.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0D1B2A),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }
}