from pathlib import Path
import re

path = Path(r"lib\app\modules\riwayat\views\riwayat_page.dart")

if not path.exists():
    raise SystemExit(f"ERROR: File tidak ditemukan: {path}")

backup = path.with_suffix(path.suffix + ".before-same-render-hasil-denah.bak")
backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

# Tambahkan import yang sama seperti HasilDenahPage
imports = [
    "import 'package:smart_floor_plan/app/data/models/room_model.dart';",
    "import 'package:smart_floor_plan/app/widgets/floor_plan_asset_overlay.dart';",
    "import 'package:smart_floor_plan/app/widgets/professional_floor_plan_painter.dart';",
]

for imp in imports:
    if imp not in text:
        text = text.replace("import 'package:get/get.dart';", "import 'package:get/get.dart';\n" + imp)

# Ganti fungsi _buildDenahPreviewCanvas lama
new_canvas = r'''  Widget _buildDenahPreviewCanvas(Map<String, dynamic> item) {
    final List<RoomModel> rooms = _historyRoomsAsModel(item);
    final double landWidth = _readLandWidth(item);
    final double landLength = _readLandLength(item);

    if (rooms.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFDDE6EF),
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 54,
                  color: Color(0xFF6B7A90),
                ),
                SizedBox(height: 12),
                Text(
                  'Data ruangan belum tersedia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102033),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Data rooms_json pada riwayat kosong.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7A90),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          border: Border.all(
            color: const Color(0xFFDDE6EF),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: ProfessionalFloorPlanPainter(
                  rooms: rooms,
                  inputLebarRumah: landWidth,
                  inputPanjangRumah: landLength,
                  title: 'SMARTFLOORPLAN RENDER',
                ),
              ),
            ),
            Positioned.fill(
              child: FloorPlanAssetOverlay(
                rooms: rooms,
                landWidth: landWidth,
                landLength: landLength,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<RoomModel> _historyRoomsAsModel(Map<String, dynamic> item) {
    final List<Map<String, dynamic>> rawRooms = _parsePreviewRooms(item);

    return rawRooms.map((room) {
      return RoomModel(
        nama: (room['nama'] ?? room['name'] ?? 'Ruang').toString(),
        x: _toDouble(room['x']),
        y: _toDouble(room['y']),
        width: _toDouble(room['width']),
        height: _toDouble(room['height']),
        category: (room['category'] ?? 'room').toString(),
        doorSide: (room['doorSide'] ?? room['door_side'] ?? 'bottom').toString(),
        isOutdoor: room['isOutdoor'] == true || room['is_outdoor'] == true,
      );
    }).toList();
  }

  double _readLandWidth(Map<String, dynamic> item) {
    final double value = _readNumberRab(
      item['lebar_lahan'] ??
          item['inputLebarRumah'] ??
          item['landWidth'] ??
          item['lebarRumah'] ??
          item['lebarLahan'],
    );

    if (value > 0) {
      return value;
    }

    return 8;
  }

  double _readLandLength(Map<String, dynamic> item) {
    final double value = _readNumberRab(
      item['panjang_lahan'] ??
          item['inputPanjangRumah'] ??
          item['landLength'] ??
          item['panjangRumah'] ??
          item['panjangLahan'],
    );

    if (value > 0) {
      return value;
    }

    return 10;
  }

  Color _roomColor'''

text, count = re.subn(
    r"  Widget _buildDenahPreviewCanvas\(Map<String, dynamic> item\) \{.*?\n  \}\n\n  Color _roomColor",
    new_canvas,
    text,
    flags=re.S,
)

if count == 0:
    raise SystemExit("ERROR: Gagal mengganti _buildDenahPreviewCanvas. Kirim riwayat_page.dart terbaru.")

path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: Riwayat LIHAT DENAH sekarang memakai render yang sama dengan Hasil Denah.")
