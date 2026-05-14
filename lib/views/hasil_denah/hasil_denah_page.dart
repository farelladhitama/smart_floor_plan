import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/room_model.dart';
import '../edit_denah/edit_denah_page.dart';
import '../rab/rab_page.dart';

class HasilDenahPage extends StatefulWidget {
  final List<RoomModel> rooms;
  final double inputPanjangRumah;
  final double inputLebarRumah;

  const HasilDenahPage({
    super.key,
    required this.rooms,
    required this.inputPanjangRumah,
    required this.inputLebarRumah,
  });

  @override
  State<HasilDenahPage> createState() => _HasilDenahPageState();
}

class _HasilDenahPageState extends State<HasilDenahPage> {
  late List<RoomModel> currentRooms;
  final double skala = 20.0;
  
  // State untuk melacak apakah denah sudah disimpan
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    currentRooms = List.from(widget.rooms);
  }

  // Fungsi simulasi simpan denah
  void _simpanDenah() {
    // Di sini kamu bisa menambahkan logika database/API nantinya
    setState(() {
      _isSaved = true;
    });
    
    Get.snackbar(
      "Berhasil", 
      "Denah telah disimpan ke koleksi Anda",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0D1B2A),
      colorText: Colors.white,
      margin: const EdgeInsets.all(15),
    );
  }

  @override
  Widget build(BuildContext context) {
    double lebarVisual = widget.inputLebarRumah * skala;
    double panjangVisual = widget.inputPanjangRumah * skala;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Smart Floor Plan", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Stats
            Container(
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0D1B2A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoTile("Lebar Rumah", "${widget.inputLebarRumah}m", Icons.straighten),
                  _infoTile("Panjang Rumah", "${widget.inputPanjangRumah}m", Icons.square_foot),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Canvas Denah
            Center(
              child: Container(
                width: lebarVisual + 80,
                height: panjangVisual + 80,
                alignment: Alignment.center,
                child: CustomPaint(
                  size: Size(lebarVisual, panjangVisual),
                  painter: DenahProfessionalPainter(
                    rooms: currentRooms,
                    skala: skala,
                    lebarRumah: widget.inputLebarRumah,
                    panjangRumah: widget.inputPanjangRumah,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // TOMBOL AKSI DENGAN LOGIKA SEQUENCE (URUTAN)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Tombol Edit (Selalu muncul)
                  Expanded(
                    flex: 1,
                    child: _customButton(
                      label: "EDIT",
                      icon: Icons.edit_location_alt_rounded,
                      color: const Color(0xFFE47B3E),
                      onTap: () async {
                        final result = await Get.to(() => EditDenahPage(initialRooms: currentRooms));
                        if (result != null) {
                          setState(() {
                            currentRooms = List.from(result);
                            _isSaved = false; // Reset status simpan jika diedit lagi
                          });
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),

                  // Logika Tombol: SIMPAN dulu, baru LIHAT RAB
                  Expanded(
                    flex: 2,
                    child: !_isSaved 
                    ? _customButton(
                        label: "SIMPAN DENAH",
                        icon: Icons.save_rounded,
                        color: const Color(0xFF1D3557),
                        onTap: _simpanDenah,
                      )
                    : _customButton(
                        label: "LIHAT RAB",
                        icon: Icons.receipt_long_rounded,
                        color: Colors.green.shade800, // Warna hijau untuk menandakan progres lanjut
                        onTap: () => Get.to(() => RABPage(rooms: currentRooms)),
                      ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _customButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(15),
      elevation: 5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PAINTER (LOGIKA VISUAL DENAH)
class DenahProfessionalPainter extends CustomPainter {
  final List<RoomModel> rooms;
  final double skala;
  final double lebarRumah;
  final double panjangRumah;

  DenahProfessionalPainter({
    required this.rooms,
    required this.skala,
    required this.lebarRumah,
    required this.panjangRumah,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.15)
      ..strokeWidth = 0.5;

    for (double i = -40; i <= size.width + 40; i += 10) {
      canvas.drawLine(Offset(i, -40), Offset(i, size.height + 40), gridPaint);
    }
    for (double i = -40; i <= size.height + 40; i += 10) {
      canvas.drawLine(Offset(-40, i), Offset(size.width + 40, i), gridPaint);
    }

    final outerWallPaint = Paint()
      ..color = const Color(0xFF0D1B2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), outerWallPaint);

    _drawDimension(canvas, const Offset(0, -25), Offset(size.width, -25), "${lebarRumah}m", Colors.blueGrey.shade800);
    _drawDimension(canvas, const Offset(-25, 0), Offset(-25, size.height), "${panjangRumah}m", Colors.blueGrey.shade800, isVertical: true);

    for (var room in rooms) {
      final roomRect = Rect.fromLTWH(room.x, room.y, room.width, room.height);
      canvas.drawRect(roomRect, Paint()..color = Colors.white);
      
      final wallPaint = Paint()
        ..color = const Color(0xFF0D1B2A).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(roomRect, wallPaint);

      double luas = (room.width / skala) * (room.height / skala);
      _drawRoomInfo(canvas, roomRect, room.nama, luas);

      _drawDimension(canvas, Offset(room.x, room.y + 12), Offset(room.x + room.width, room.y + 12), 
          "${(room.width / skala).toStringAsFixed(1)}m", Colors.red.shade800, fontSize: 9);
      _drawDimension(canvas, Offset(room.x + 12, room.y), Offset(room.x + 12, room.y + room.height), 
          "${(room.height / skala).toStringAsFixed(1)}m", Colors.red.shade800, isVertical: true, fontSize: 9);
    }
  }

  void _drawDimension(Canvas canvas, Offset start, Offset end, String text, Color color, {bool isVertical = false, double fontSize = 11}) {
    final p = Paint()..color = color..strokeWidth = 1.0;
    canvas.drawLine(start, end, p);
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    Offset textPos = isVertical 
      ? Offset(start.dx - tp.width - 5, (start.dy + end.dy) / 2 - (tp.height / 2))
      : Offset((start.dx + end.dx) / 2 - (tp.width / 2), start.dy - tp.height - 2);
    tp.paint(canvas, textPos);
  }

  void _drawRoomInfo(Canvas canvas, Rect rect, String name, double area) {
    final tp = TextPainter(
      textAlign: TextAlign.center,
      text: TextSpan(children: [
        TextSpan(text: "$name\n", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
        TextSpan(text: "${area.toStringAsFixed(1)} m²", style: TextStyle(color: Colors.grey.shade700, fontSize: 9, fontStyle: FontStyle.italic)),
      ]),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(rect.center.dx - (tp.width / 2), rect.center.dy - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}