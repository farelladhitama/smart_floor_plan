import 'package:flutter/material.dart';
import '../../models/room_model.dart';

class RABPage extends StatelessWidget {
  final List<RoomModel> rooms;

  const RABPage({Key? key, required this.rooms}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double skala = 20.0;
    double totalLuas = rooms.fold(0, (sum, item) => sum + ((item.width / skala) * (item.height / skala)));
    double hargaDasar = totalLuas * 3500000;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Detail RAB", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Rincian Anggaran", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
            Text("Total Luas: ${totalLuas.toStringAsFixed(1)} m²", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            _buildBiayaCard("Struktur & Pondasi", _formatRupiah(hargaDasar * 0.25)),
            _buildBiayaCard("Dinding & Material", _formatRupiah(hargaDasar * 0.20)),
            _buildBiayaCard("Atap & Plafon", _formatRupiah(hargaDasar * 0.15)),
            _buildBiayaCard("Lantai & Keramik", _formatRupiah(hargaDasar * 0.15)),
            _buildBiayaCard("Pekerjaan Finishing", _formatRupiah(hargaDasar * 0.25)),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF0D1B2A), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Estimasi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_formatRupiah(hargaDasar), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildAction(context),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(double amount) {
    return "Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  Widget _buildBiayaCard(String title, String harga) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(harga, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil disimpan"))),
        icon: const Icon(Icons.save),
        label: const Text("Simpan Hasil Final"),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}