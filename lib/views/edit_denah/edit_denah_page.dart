import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/room_model.dart';

class EditDenahPage extends StatefulWidget {
  final List<RoomModel> initialRooms;
  const EditDenahPage({super.key, required this.initialRooms});

  @override
  State<EditDenahPage> createState() => _EditDenahPageState();
}

class _EditDenahPageState extends State<EditDenahPage> {
  late List<RoomModel> listRuangan;
  final double skala = 20.0; // 1 meter = 20 pixel

  @override
  void initState() {
    super.initState();
    // Mengambil data awal dari halaman sebelumnya
    listRuangan = List.from(widget.initialRooms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        title: const Text("Editor Denah Modern", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1D3557),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: () => Get.back(result: listRuangan), // Mengirim data kembali setelah diedit
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text("SIMPAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          children: [
            // Background Grid agar terlihat profesional
            CustomPaint(size: Size.infinite, painter: GridPainter()),

            // Render setiap ruangan
            ...listRuangan.asMap().entries.map((entry) {
              int idx = entry.key;
              RoomModel room = entry.value;

              return Positioned(
                left: room.x,
                top: room.y,
                child: Stack(
                  clipBehavior: Clip.none, // Penting agar handle merah bisa sedikit keluar garis
                  children: [
                    // FITUR DRAG (PINDAH POSISI RUANGAN)
                    GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          listRuangan[idx] = room.copyWith(
                            x: (room.x + details.delta.dx).clamp(0, constraints.maxWidth - room.width),
                            y: (room.y + details.delta.dy).clamp(0, constraints.maxHeight - room.height),
                          );
                        });
                      },
                      child: Container(
                        width: room.width,
                        height: room.height,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          border: Border.all(color: const Color(0xFF1D3557), width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Nama Ruangan & Dimensi di Tengah
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(room.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  Text(
                                    "${(room.width / skala).toStringAsFixed(1)}m x ${(room.height / skala).toStringAsFixed(1)}m",
                                    style: const TextStyle(fontSize: 9, color: Colors.blueGrey),
                                  ),
                                ],
                              ),
                            ),
                            // Angka Lebar di Atas
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                "${(room.width / skala).toStringAsFixed(1)}m",
                                style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Angka Tinggi di Samping
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  "${(room.height / skala).toStringAsFixed(1)}m",
                                  style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // FITUR RESIZE (POJOK KANAN BAWAH) - RADIUS MERAH
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            listRuangan[idx] = room.copyWith(
                              width: (room.width + details.delta.dx).clamp(40.0, 500.0),
                              height: (room.height + details.delta.dy).clamp(40.0, 500.0),
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red, // Radius sirkular merah
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.open_in_full_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      }),
    );
  }
}

// Painter untuk menggambar grid di background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (double i = 0; i <= size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}