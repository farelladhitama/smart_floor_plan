import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/hasil_denah/controllers/hasil_denah_controller.dart';
import 'package:smart_floor_plan/app/modules/hasil_denah/views/hasil_denah_page.dart';
import 'package:smart_floor_plan/app/routes/app_routes.dart';

class RiwayatController extends GetxController {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> histories = <Map<String, dynamic>>[].obs;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    loadHistories();
  }

  Future<void> loadHistories() async {
    final User? user = _supabase.auth.currentUser;

    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    try {
      isLoading.value = true;

      final response = await _supabase
          .from('floor_plans')
          .select(
            'id, title, panjang_lahan, lebar_lahan, jumlah_kamar, material, ruang_tambahan, total_luas, estimasi_rab, rooms_json, created_at, updated_at',
          )
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);

      final List<Map<String, dynamic>> rows = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      histories.assignAll(rows);
    } on PostgrestException catch (error) {
      showMessage(
        'Gagal Memuat Riwayat',
        error.message,
      );
    } catch (error) {
      showMessage(
        'Gagal Memuat Riwayat',
        'Terjadi kesalahan: $error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  String getTitle(Map<String, dynamic> item) {
    final String title = (item['title'] ?? '').toString().trim();

    if (title.isNotEmpty) {
      return title;
    }

    return 'Denah Rumah';
  }

  String getSubtitle(Map<String, dynamic> item) {
    final String lebar = _formatNumber(item['lebar_lahan']);
    final String panjang = _formatNumber(item['panjang_lahan']);
    final String kamar = (item['jumlah_kamar'] ?? 0).toString();
    final String material = (item['material'] ?? '-').toString();

    return '$lebar m x $panjang m • $kamar kamar • $material';
  }

  String getDate(Map<String, dynamic> item) {
    final String rawDate =
        (item['updated_at'] ?? item['created_at'] ?? '').toString();

    if (rawDate.isEmpty) {
      return '-';
    }

    final DateTime? parsed = DateTime.tryParse(rawDate);

    if (parsed == null) {
      return rawDate;
    }

    final DateTime local = parsed.toLocal();

    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String getAreaText(Map<String, dynamic> item) {
    return '${_formatNumber(item['total_luas'])} m²';
  }

  String getRabText(Map<String, dynamic> item) {
    final num value = _toNum(item['estimasi_rab']);

    return 'Rp ${_formatRupiah(value)}';
  }

  int getRoomCount(Map<String, dynamic> item) {
    final dynamic roomsJson = item['rooms_json'];

    if (roomsJson is List) {
      return roomsJson.length;
    }

    return 0;
  }

  void openDetail(Map<String, dynamic> item) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Denah',
                style: TextStyle(
                  color: navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _detailRow('Judul', getTitle(item)),
              _detailRow('Ukuran', getSubtitle(item)),
              _detailRow('Ruangan', '${getRoomCount(item)} ruang'),
              _detailRow('Total Luas', getAreaText(item)),
              _detailRow('Estimasi RAB', getRabText(item)),
              _detailRow('Tanggal', getDate(item)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> openEdit(Map<String, dynamic> item) async {
    final List<RoomModel> rooms = _roomsFromJson(item);

    if (rooms.isEmpty) {
      showMessage(
        'Tidak Bisa Edit',
        'Data rooms_json kosong atau format ruangan tidak valid.',
      );
      return;
    }

    final double landWidth = _toDouble(item['lebar_lahan']);
    final double landLength = _toDouble(item['panjang_lahan']);

    if (landWidth <= 0 || landLength <= 0) {
      showMessage(
        'Tidak Bisa Edit',
        'Ukuran lahan pada riwayat tidak valid.',
      );
      return;
    }

    if (Get.isRegistered<HasilDenahController>()) {
      Get.delete<HasilDenahController>();
    }

    Get.put(HasilDenahController());

    await Get.to(
      () => HasilDenahPage(
        rooms: rooms,
        inputLebarRumah: landWidth,
        inputPanjangRumah: landLength,
        floorPlanId: (item['id'] ?? '').toString(),
        material: (item['material'] ?? 'Batu Bata').toString(),
        jumlahKamar: _toNum(item['jumlah_kamar']).toInt(),
        ruangTambahan: _stringListFromDynamic(item['ruang_tambahan']),
      ),
    );

    await loadHistories();
  }

  Future<void> deleteHistory(Map<String, dynamic> item) async {
    final String id = (item['id'] ?? '').toString();

    if (id.isEmpty) {
      showMessage(
        'Gagal Hapus',
        'ID riwayat tidak ditemukan.',
      );
      return;
    }

    try {
      await _supabase.from('floor_plans').delete().eq('id', id);

      histories.removeWhere((history) => history['id'] == id);

      showMessage(
        'Berhasil',
        'Riwayat denah berhasil dihapus.',
      );
    } on PostgrestException catch (error) {
      showMessage(
        'Gagal Hapus',
        error.message,
      );
    } catch (error) {
      showMessage(
        'Gagal Hapus',
        'Terjadi kesalahan: $error',
      );
    }
  }

  List<RoomModel> _roomsFromJson(Map<String, dynamic> item) {
    final dynamic rawRooms = item['rooms_json'];

    if (rawRooms is! List) {
      return <RoomModel>[];
    }

    return rawRooms.map((rawRoom) {
      final Map<String, dynamic> room =
          Map<String, dynamic>.from(rawRoom as Map);

      return RoomModel(
        nama: (room['nama'] ?? room['name'] ?? 'Ruang').toString(),
        category: (room['category'] ?? 'room').toString(),
        x: _toDouble(room['x']),
        y: _toDouble(room['y']),
        width: _toDouble(room['width']),
        height: _toDouble(room['height']),
      );
    }).toList();
  }

  List<String> _stringListFromDynamic(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return <String>[];
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic value) {
    final num number = _toNum(value);

    if (number == number.roundToDouble()) {
      return number.toStringAsFixed(0);
    }

    return number.toStringAsFixed(1);
  }

  num _toNum(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value;
    }

    return num.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatRupiah(num value) {
    final String raw = value.round().toString();
    final StringBuffer buffer = StringBuffer();

    int counter = 0;

    for (int i = raw.length - 1; i >= 0; i--) {
      buffer.write(raw[i]);
      counter++;

      if (counter == 3 && i != 0) {
        buffer.write('.');
        counter = 0;
      }
    }

    return buffer.toString().split('').reversed.join();
  }

  void showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      icon: const Icon(
        Icons.info_outline_rounded,
        color: orange,
      ),
    );
  }
}