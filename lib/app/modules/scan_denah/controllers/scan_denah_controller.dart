import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_floor_plan/app/modules/hasil_denah/controllers/hasil_denah_controller.dart';
import 'package:smart_floor_plan/app/modules/hasil_denah/views/hasil_denah_page.dart';

class ScanDenahController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  final selectedImageBytes = Rxn<Uint8List>();
  final selectedImageName = ''.obs;

  final detectedRooms = <RoomModel>[].obs;
  final isProcessing = false.obs;
  final message = ''.obs;

  final scanLandWidth = 10.0.obs;
  final scanLandLength = 12.0.obs;

  final String baseUrl = "https://achmadmundakir.pythonanywhere.com";

  final List<String> materialCategories = const [
    'Material Dinding',
    'Semen',
    'Pasir',
    'Keramik Lantai',
    'Cat Dinding',
    'Genteng / Atap',
    'Plafon',
    'Pipa',
  ];

  final materialOptionsByCategory = <String, List<String>>{}.obs;
  final selectedMaterials = <String, String>{}.obs;
  final isLoadingMaterials = false.obs;

  SupabaseClient get _supabase => Supabase.instance.client;

  static const double scanPadding = 0.25;


  @override
  void onInit() {
    super.onInit();
    loadMaterialOptions();
  }

  Future<void> loadMaterialOptions() async {
    try {
      isLoadingMaterials.value = true;

      final response = await _supabase
          .from('rab_material_options')
          .select('kategori, nama_material, is_active')
          .eq('is_active', true)
          .order('kategori', ascending: true)
          .order('nama_material', ascending: true);

      final List<Map<String, dynamic>> rows = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final Map<String, List<String>> grouped = <String, List<String>>{};

      for (final Map<String, dynamic> row in rows) {
        final String kategori = (row['kategori'] ?? '').toString();
        final String namaMaterial = (row['nama_material'] ?? '').toString();

        if (kategori.isEmpty || namaMaterial.isEmpty) continue;
        if (!materialCategories.contains(kategori)) continue;

        grouped.putIfAbsent(kategori, () => <String>[]);

        if (!grouped[kategori]!.contains(namaMaterial)) {
          grouped[kategori]!.add(namaMaterial);
        }
      }

      if (grouped.isEmpty) {
        _setFallbackMaterialOptions();
      } else {
        final Map<String, List<String>> sorted = <String, List<String>>{};

        for (final String category in materialCategories) {
          final List<String>? options = grouped[category];

          if (options != null && options.isNotEmpty) {
            sorted[category] = options;
          }
        }

        materialOptionsByCategory.assignAll(sorted);
        _ensureDefaultSelectedMaterials();
      }
    } catch (_) {
      _setFallbackMaterialOptions();
    } finally {
      isLoadingMaterials.value = false;
    }
  }

  void _setFallbackMaterialOptions() {
    materialOptionsByCategory.assignAll({
      'Material Dinding': [
        'batu bata merah',
        'batako',
        'bata ringan / hebel',
      ],
      'Semen': [
        'semen tiga roda',
        'semen gresik',
        'semen padang',
        'semen mortar',
        'semen instan',
      ],
      'Pasir': [
        'pasir pasang',
        'pasir urug',
      ],
      'Keramik Lantai': [
        'keramik lantai standar',
        'keramik lantai premium',
        'granit lantai',
      ],
      'Cat Dinding': [
        'cat tembok standar',
        'cat tembok avian',
        'cat tembok dulux',
        'cat tembok nippon paint',
      ],
      'Genteng / Atap': [
        'genteng tanah liat',
        'genteng beton',
        'atap spandek',
      ],
      'Plafon': [
        'plafon gypsum',
        'plafon pvc',
        'plafon grc',
      ],
      'Pipa': [
        'pipa pvc',
        'pipa air',
        'pipa conduit',
      ],
    });

    _ensureDefaultSelectedMaterials();
  }

  void _ensureDefaultSelectedMaterials() {
    for (final String kategori in materialCategories) {
      final List<String> options =
          materialOptionsByCategory[kategori] ?? <String>[];

      if (options.isEmpty) continue;

      if (!selectedMaterials.containsKey(kategori) ||
          !options.contains(selectedMaterials[kategori])) {
        selectedMaterials[kategori] = options.first;
      }
    }
  }

  void changeMaterialForCategory(String kategori, String value) {
    selectedMaterials[kategori] = value;
  }

  Map<String, String> _effectiveSelectedMaterials() {
    if (selectedMaterials.isEmpty) {
      _setFallbackMaterialOptions();
    }

    return Map<String, String>.from(selectedMaterials);
  }

  Future<void> pickImage() async {
    await pickImageFromGallery();
  }

  Future<void> pickImageFromGallery() async {
    await _pickImageFromSource(ImageSource.gallery);
  }

  Future<void> pickImageFromCamera() async {
    await _pickImageFromSource(ImageSource.camera);
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2400,
        maxHeight: 2400,
      );

      if (image == null) {
        return;
      }

      final Uint8List bytes = await image.readAsBytes();

      selectedImageBytes.value = bytes;
      selectedImageName.value = image.name;
      detectedRooms.clear();

      if (source == ImageSource.camera) {
        message.value = 'Foto dari kamera berhasil diambil. Memproses scan...';
      } else {
        message.value = 'Gambar berhasil dipilih. Memproses scan...';
      }

      await scanImageWithOpenCV(bytes, image.name);
    } catch (e) {
      message.value = 'Gagal mengambil gambar: $e';
      Get.snackbar(
        'Gagal',
        'Gagal mengambil gambar. Pastikan izin kamera/file sudah diberikan.',
      );
    }
  }

  Future<void> scanPickedImageBytes({
    required Uint8List bytes,
    required String filename,
    bool fromCamera = false,
  }) async {
    selectedImageBytes.value = bytes;
    selectedImageName.value = filename;
    detectedRooms.clear();

    if (fromCamera) {
      message.value = 'Foto dari kamera berhasil diambil. Memproses scan...';
    } else {
      message.value = 'Gambar berhasil dipilih. Memproses scan...';
    }

    await scanImageWithOpenCV(bytes, filename);
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
      final double imageWidth = _toDouble(data['image_width']);
      final double imageHeight = _toDouble(data['image_height']);
      final List roomsJson = data['rooms'] ?? [];

     // _setLandSizeFromImageRatio(
//   imageWidth: imageWidth,
//   imageHeight: imageHeight,
// );

      final List<RoomModel> rawRooms = roomsJson.map<RoomModel>((item) {
        return RoomModel(
          nama: item['name'] ?? 'Ruang',
          category: 'room',
          x: _toDouble(item['x']),
          y: _toDouble(item['y']),
          width: _toDouble(item['width']),
          height: _toDouble(item['height']),
        );
      }).toList();

      final List<RoomModel> rooms = _fitRoomsToLandFrame(
        rawRooms,
        landWidth: scanLandWidth.value,
        landLength: scanLandLength.value,
        padding: scanPadding,
      );

      detectedRooms.assignAll(rooms);

      if (rooms.isEmpty) {
        message.value =
            'Belum ada ruangan terdeteksi. Gunakan sketsa dengan garis hitam tebal dan background putih.';
      } else {
        message.value =
            '${rooms.length} ruangan terdeteksi dan sudah disesuaikan ke frame denah ${scanLandWidth.value.toStringAsFixed(1)} x ${scanLandLength.value.toStringAsFixed(1)} m.';
      }

      isProcessing.value = false;
    } catch (e) {
      isProcessing.value = false;
      message.value =
          'Gagal terhubung ke backend OpenCV. Pastikan Flask berjalan dan ADB reverse sudah aktif. Error: $e';
    }
  }

  void _setLandSizeFromImageRatio({
    required double imageWidth,
    required double imageHeight,
  }) {
    if (imageWidth <= 0 || imageHeight <= 0) {
      scanLandWidth.value = 10.0;
      scanLandLength.value = 12.0;
      return;
    }

    final double aspectRatio = imageWidth / imageHeight;
    const double shortSideMeter = 10.0;

    if (aspectRatio >= 1) {
      scanLandWidth.value = _roundOneDecimal(shortSideMeter * aspectRatio);
      scanLandLength.value = shortSideMeter;
    } else {
      scanLandWidth.value = shortSideMeter;
      scanLandLength.value = _roundOneDecimal(shortSideMeter / aspectRatio);
    }
  }

  List<RoomModel> _fitRoomsToLandFrame(
    List<RoomModel> rawRooms, {
    required double landWidth,
    required double landLength,
    required double padding,
  }) {
    if (rawRooms.isEmpty) return <RoomModel>[];

    double minX = rawRooms.first.x;
    double minY = rawRooms.first.y;
    double maxX = rawRooms.first.x + rawRooms.first.width;
    double maxY = rawRooms.first.y + rawRooms.first.height;

    for (final RoomModel room in rawRooms) {
      if (room.x < minX) minX = room.x;
      if (room.y < minY) minY = room.y;

      final double right = room.x + room.width;
      final double bottom = room.y + room.height;

      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    final double detectedWidth = maxX - minX;
    final double detectedHeight = maxY - minY;

    if (detectedWidth <= 0 || detectedHeight <= 0) {
      return _applySmartRoomNames(rawRooms);
    }

    final double availableWidth = landWidth - (padding * 2);
    final double availableLength = landLength - (padding * 2);

    final double scaleX = availableWidth / detectedWidth;
    final double scaleY = availableLength / detectedHeight;

    final List<RoomModel> mappedRooms = rawRooms.map((room) {
      final double x = ((room.x - minX) * scaleX) + padding;
      final double y = ((room.y - minY) * scaleY) + padding;
      final double width = room.width * scaleX;
      final double height = room.height * scaleY;

      return RoomModel(
        nama: room.nama,
        category: 'room',
        x: _clampDouble(x, 0, landWidth),
        y: _clampDouble(y, 0, landLength),
        width: _clampDouble(width, 0.75, landWidth),
        height: _clampDouble(height, 0.75, landLength),
      );
    }).toList();

    return _applySmartRoomNames(mappedRooms);
  }

  List<RoomModel> _applySmartRoomNames(List<RoomModel> rooms) {
    if (rooms.isEmpty) return <RoomModel>[];

    final List<int> indexes = List<int>.generate(rooms.length, (index) => index);

    indexes.sort((a, b) {
      final double areaA = rooms[a].width * rooms[a].height;
      final double areaB = rooms[b].width * rooms[b].height;
      return areaB.compareTo(areaA);
    });

    final int largestIndex = indexes.first;
    final int smallestIndex = indexes.last;
    final int secondSmallestIndex =
        indexes.length >= 4 ? indexes[indexes.length - 2] : -1;

    int frontIndex = 0;
    double frontScore = -1;

    for (int i = 0; i < rooms.length; i++) {
      final double score = rooms[i].y + rooms[i].height;
      if (score > frontScore) {
        frontScore = score;
        frontIndex = i;
      }
    }

    int bedroomNumber = 0;

    return List<RoomModel>.generate(rooms.length, (index) {
      final RoomModel room = rooms[index];

      String name = 'Ruang ${index + 1}';
      String category = 'room';

      if (index == largestIndex) {
        name = 'R. Keluarga';
        category = 'family';
      } else if (index == frontIndex) {
        name = 'Ruang Tamu';
        category = 'living';
      } else if (index == smallestIndex) {
        name = 'KM/WC';
        category = 'bath';
      } else if (index == secondSmallestIndex) {
        name = 'Gudang';
        category = 'service';
      } else {
        bedroomNumber++;
        if (bedroomNumber == 1) {
          name = 'K. Tidur Utama';
        } else {
          name = 'K. Tidur ${bedroomNumber - 1}';
        }
        category = 'bedroom';
      }

      return RoomModel(
        nama: name,
        category: category,
        x: room.x,
        y: room.y,
        width: room.width,
        height: room.height,
      );
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
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

    final List<RoomModel> normalizedRooms = _cloneRooms(detectedRooms.toList());

    final double landWidth = scanLandWidth.value;
    final double landLength = scanLandLength.value;
    final double landArea = landWidth * landLength;
    final Map<String, String> selectedScanMaterials =
        _effectiveSelectedMaterials();
    final String materialDinding =
        selectedScanMaterials['Material Dinding'] ?? 'batu bata merah';

    if (Get.isRegistered<HasilDenahController>()) {
      Get.delete<HasilDenahController>();
    }

    Get.put(HasilDenahController());

    Get.to(
      () => HasilDenahPage(
        rooms: normalizedRooms,
        inputLebarRumah: landWidth,
        inputPanjangRumah: landLength,
        material: materialDinding,
        jumlahKamar: _countBedrooms(normalizedRooms),
        ruangTambahan: const [],
      ),
      arguments: {
        'scanMode': true,
        'scanImageName': selectedImageName.value,
        'material': materialDinding,
        'selectedMaterials': selectedScanMaterials,
        'luasBangunan': landArea,
        'totalLuas': landArea,
        'total_luas': landArea,
        'inputLuas': landArea,
        'inputLebarRumah': landWidth,
        'inputPanjangRumah': landLength,
        'lebar_lahan': landWidth,
        'panjang_lahan': landLength,
      },
    );
  }

  List<RoomModel> _cloneRooms(List<RoomModel> rooms) {
    return rooms.map((room) {
      return RoomModel(
        nama: room.nama,
        category: room.category,
        x: room.x,
        y: room.y,
        width: room.width,
        height: room.height,
      );
    }).toList();
  }

  int _countBedrooms(List<RoomModel> rooms) {
    final int count = rooms
        .where(
          (room) =>
              room.category == 'bedroom' ||
              room.nama.toLowerCase().contains('tidur'),
        )
        .length;

    if (count <= 0) return 1;
    return count;
  }

  Map<String, String> _defaultSelectedMaterials() {
    return {
      'Material Dinding': 'batu bata merah',
      'Semen': 'semen tiga roda',
      'Pasir': 'pasir pasang',
      'Keramik Lantai': 'keramik lantai standar',
      'Cat Dinding': 'cat tembok standar',
      'Genteng / Atap': 'genteng tanah liat',
      'Plafon': 'plafon gypsum',
      'Pipa': 'pipa pvc',
    };
  }

  double _roundOneDecimal(double value) {
    return (value * 10).round() / 10;
  }

  double _clampDouble(double value, double min, double max) {
    if (max < min) return min;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  void reset() {
    selectedImageBytes.value = null;
    selectedImageName.value = '';
    detectedRooms.clear();
    message.value = '';
    scanLandWidth.value = 10.0;
    scanLandLength.value = 12.0;
  }
}
