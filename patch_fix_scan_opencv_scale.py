from pathlib import Path
import re

path = Path(r"lib\app\modules\scan_denah\controllers\scan_denah_controller.dart")

if not path.exists():
    raise SystemExit("ERROR: scan_denah_controller.dart tidak ditemukan.")

backup = path.with_suffix(path.suffix + ".before-fix-opencv-scale.bak")
backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

# ============================================================
# 1. Tambahkan ukuran lahan default untuk hasil scan
# ============================================================

if "static const double scanLandWidth" not in text:
    text = text.replace(
"""  final String baseUrl = 'http://127.0.0.1:5000';
""",
"""  final String baseUrl = 'http://127.0.0.1:5000';

  static const double scanLandWidth = 10.0;
  static const double scanLandLength = 12.0;
  static const double scanPadding = 0.35;
"""
    )

# ============================================================
# 2. Ubah hasil OpenCV dari pixel menjadi meter + nama ruangan
# ============================================================

old_block = """      final rooms = roomsJson.map((item) {
        return RoomModel(
          nama: item['name'] ?? 'Ruang',
          x: _toDouble(item['x']),
          y: _toDouble(item['y']),
          width: _toDouble(item['width']),
          height: _toDouble(item['height']),
        );
      }).toList();

      detectedRooms.assignAll(rooms);
"""

new_block = """      final rawRooms = roomsJson.map((item) {
        return RoomModel(
          nama: item['name'] ?? 'Ruang',
          x: _toDouble(item['x']),
          y: _toDouble(item['y']),
          width: _toDouble(item['width']),
          height: _toDouble(item['height']),
        );
      }).toList();

      final rooms = _normalizeRoomsToLand(
        rawRooms,
        landWidth: scanLandWidth,
        landLength: scanLandLength,
        padding: scanPadding,
      );

      detectedRooms.assignAll(rooms);
"""

if old_block in text:
    text = text.replace(old_block, new_block)
else:
    print("WARNING: blok roomsJson map tidak ketemu, mungkin kode sudah berubah.")

text = text.replace(
"""        message.value =
            '${rooms.length} ruangan berhasil terdeteksi menggunakan OpenCV.';
""",
"""        message.value =
            '${rooms.length} ruangan berhasil terdeteksi dan dinormalisasi ke ukuran ${scanLandWidth.toStringAsFixed(0)} x ${scanLandLength.toStringAsFixed(0)} m.';
"""
)

# ============================================================
# 3. Fix openResult: jangan normalize ke canvas pixel lagi
#    dan kirim arguments supaya RAB tidak default 100
# ============================================================

old_open = """    final normalizedRooms = _normalizeRoomsForCanvas(
      detectedRooms.toList(),
      canvasWidth: 260,
      canvasHeight: 360,
      padding: 20,
    );
"""

new_open = """    final normalizedRooms = _cloneRooms(detectedRooms.toList());
"""

if old_open in text:
    text = text.replace(old_open, new_open)

old_get_to = """    Get.to(
      () => HasilDenahPage(
        rooms: normalizedRooms,
        inputLebarRumah: 10,
        inputPanjangRumah: 12,
      ),
    );
"""

new_get_to = """    Get.to(
      () => HasilDenahPage(
        rooms: normalizedRooms,
        inputLebarRumah: scanLandWidth,
        inputPanjangRumah: scanLandLength,
        material: 'batu bata merah',
        jumlahKamar: _countBedrooms(normalizedRooms),
        ruangTambahan: const [],
      ),
      arguments: {
        'scanMode': true,
        'material': 'batu bata merah',
        'selectedMaterials': _defaultSelectedMaterials(),
        'luasBangunan': scanLandWidth * scanLandLength,
        'totalLuas': scanLandWidth * scanLandLength,
        'total_luas': scanLandWidth * scanLandLength,
        'inputLuas': scanLandWidth * scanLandLength,
        'inputLebarRumah': scanLandWidth,
        'inputPanjangRumah': scanLandLength,
        'lebar_lahan': scanLandWidth,
        'panjang_lahan': scanLandLength,
      },
    );
"""

if old_get_to in text:
    text = text.replace(old_get_to, new_get_to)
else:
    print("WARNING: blok Get.to HasilDenahPage tidak ketemu.")

# ============================================================
# 4. Tambahkan helper normalisasi pixel -> meter + nama ruangan
# ============================================================

helper = r'''
  List<RoomModel> _normalizeRoomsToLand(
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
      return _applySmartRoomNames(rawRooms, landWidth, landLength);
    }

    final double availableWidth = landWidth - (padding * 2);
    final double availableHeight = landLength - (padding * 2);

    final double scaleX = availableWidth / detectedWidth;
    final double scaleY = availableHeight / detectedHeight;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double usedWidth = detectedWidth * scale;
    final double usedHeight = detectedHeight * scale;

    final double offsetX = (landWidth - usedWidth) / 2;
    final double offsetY = (landLength - usedHeight) / 2;

    final List<RoomModel> scaledRooms = rawRooms.map((room) {
      final double x = ((room.x - minX) * scale) + offsetX;
      final double y = ((room.y - minY) * scale) + offsetY;
      final double width = room.width * scale;
      final double height = room.height * scale;

      return RoomModel(
        nama: room.nama,
        category: 'room',
        x: _clampDouble(x, 0, landWidth),
        y: _clampDouble(y, 0, landLength),
        width: _clampDouble(width, 1.0, landWidth),
        height: _clampDouble(height, 1.0, landLength),
      );
    }).toList();

    return _applySmartRoomNames(scaledRooms, landWidth, landLength);
  }

  List<RoomModel> _applySmartRoomNames(
    List<RoomModel> rooms,
    double landWidth,
    double landLength,
  ) {
    if (rooms.isEmpty) return <RoomModel>[];

    final List<int> indexes = List<int>.generate(rooms.length, (index) => index);

    indexes.sort((a, b) {
      final double areaA = rooms[a].width * rooms[a].height;
      final double areaB = rooms[b].width * rooms[b].height;

      return areaB.compareTo(areaA);
    });

    final int largestIndex = indexes.first;
    final int smallestIndex = indexes.last;
    final int secondSmallestIndex = indexes.length >= 4 ? indexes[indexes.length - 2] : -1;

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
        .where((room) => room.category == 'bedroom' || room.nama.toLowerCase().contains('tidur'))
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

  double _clampDouble(double value, double min, double max) {
    if (max < min) return min;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

'''

if "List<RoomModel> _normalizeRoomsToLand" not in text:
    marker = "  List<RoomModel> _normalizeRoomsForCanvas"
    if marker in text:
        text = text.replace(marker, helper + marker)
    else:
        raise SystemExit("ERROR: marker _normalizeRoomsForCanvas tidak ditemukan.")

path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: hasil OpenCV sekarang dinormalisasi dari pixel ke meter.")
