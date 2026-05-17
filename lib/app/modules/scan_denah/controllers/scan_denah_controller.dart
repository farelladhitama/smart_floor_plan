import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/app/modules/hasil_denah/controllers/hasil_denah_controller.dart';
import 'package:smart_floor_plan/app/modules/hasil_denah/views/hasil_denah_page.dart';

class ScanDenahController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  final selectedImageBytes = Rxn<Uint8List>();
  final selectedImageName = ''.obs;

  final detectedRooms = <RoomModel>[].obs;
  final isProcessing = false.obs;
  final message = ''.obs;

  /*
    Untuk HP Android yang dicolok USB:
    Jalankan dulu:
    adb reverse tcp:5000 tcp:5000

    Setelah itu, baseUrl ini bisa langsung dipakai di HP:
  */
  final String baseUrl = 'http://127.0.0.1:5000';

  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      selectedImageBytes.value = bytes;
      selectedImageName.value = pickedFile.name;

      detectedRooms.clear();
      message.value = 'Gambar dipilih. Memproses dengan OpenCV...';

      await scanImageWithOpenCV(bytes, pickedFile.name);
    } catch (e) {
      isProcessing.value = false;
      message.value = 'Gagal memilih gambar: $e';
    }
  }

  Future<void> scanImageWithOpenCV(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      isProcessing.value = true;
      message.value = 'Mengirim gambar ke backend OpenCV...';

      final uri = Uri.parse('$baseUrl/api/cv/scan-denah');

      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename.isEmpty ? 'denah.png' : filename,
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      final jsonData = jsonDecode(responseBody);

      if (streamedResponse.statusCode != 200) {
        isProcessing.value = false;
        message.value = jsonData['message'] ?? 'Gagal memproses gambar.';
        return;
      }

      final data = jsonData['data'];
      final List roomsJson = data['rooms'] ?? [];

      final rooms = roomsJson.map((item) {
        return RoomModel(
          nama: item['name'] ?? 'Ruang',
          x: _toDouble(item['x']),
          y: _toDouble(item['y']),
          width: _toDouble(item['width']),
          height: _toDouble(item['height']),
        );
      }).toList();

      detectedRooms.assignAll(rooms);

      if (rooms.isEmpty) {
        message.value =
            'Belum ada ruangan terdeteksi. Gunakan sketsa dengan garis hitam tebal dan background putih.';
      } else {
        message.value =
            '${rooms.length} ruangan berhasil terdeteksi menggunakan OpenCV.';
      }

      isProcessing.value = false;
    } catch (e) {
      isProcessing.value = false;
      message.value =
          'Gagal terhubung ke backend OpenCV. Pastikan Flask berjalan dan ADB reverse sudah aktif. Error: $e';
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  void openResult() {
    if (detectedRooms.isEmpty) {
      Get.snackbar(
        'Belum ada hasil',
        'Silakan scan gambar denah terlebih dahulu.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final normalizedRooms = _normalizeRoomsForCanvas(
      detectedRooms.toList(),
      canvasWidth: 260,
      canvasHeight: 360,
      padding: 20,
    );

    if (Get.isRegistered<HasilDenahController>()) {
      Get.delete<HasilDenahController>();
    }

    Get.put(HasilDenahController());

    Get.to(
      () => HasilDenahPage(
        rooms: normalizedRooms,
        inputLebarRumah: 10,
        inputPanjangRumah: 12,
      ),
    );
  }

  List<RoomModel> _normalizeRoomsForCanvas(
    List<RoomModel> rooms, {
    required double canvasWidth,
    required double canvasHeight,
    required double padding,
  }) {
    if (rooms.isEmpty) return [];

    double minX = rooms.first.x;
    double minY = rooms.first.y;
    double maxX = rooms.first.x + rooms.first.width;
    double maxY = rooms.first.y + rooms.first.height;

    for (final room in rooms) {
      if (room.x < minX) minX = room.x;
      if (room.y < minY) minY = room.y;

      final right = room.x + room.width;
      final bottom = room.y + room.height;

      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    final detectedWidth = maxX - minX;
    final detectedHeight = maxY - minY;

    if (detectedWidth <= 0 || detectedHeight <= 0) {
      return rooms;
    }

    final availableWidth = canvasWidth - (padding * 2);
    final availableHeight = canvasHeight - (padding * 2);

    final scaleX = availableWidth / detectedWidth;
    final scaleY = availableHeight / detectedHeight;

    final scale = scaleX < scaleY ? scaleX : scaleY;

    return rooms.map((room) {
      return RoomModel(
        nama: room.nama,
        x: ((room.x - minX) * scale) + padding,
        y: ((room.y - minY) * scale) + padding,
        width: room.width * scale,
        height: room.height * scale,
      );
    }).toList();
  }

  void reset() {
    selectedImageBytes.value = null;
    selectedImageName.value = '';
    detectedRooms.clear();
    message.value = '';
  }
}