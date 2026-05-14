import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/room_model.dart';
import '../hasil_denah/hasil_denah_page.dart';

class GenerateFormPage extends StatefulWidget {
  const GenerateFormPage({super.key});

  @override
  State<GenerateFormPage> createState() => _GenerateFormPageState();
}

class _GenerateFormPageState extends State<GenerateFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk Dimensi Lahan
  final TextEditingController _lebarController = TextEditingController();
  final TextEditingController _panjangController = TextEditingController();
  
  // Controller & State untuk Ruangan Tambahan
  final TextEditingController _ruangTambahanController = TextEditingController();
  List<String> _listRuangCustom = []; 
  
  // State untuk Jumlah Kamar
  int _jumlahKamar = 1;

  // Fitur Baru: State untuk Pilihan Material
  String _selectedMaterial = 'Batu Bata';
  final List<String> _materialOptions = ['Batu Bata', 'Hebel (Bata Ringan)', 'Batako'];

  @override
  void dispose() {
    _lebarController.dispose();
    _panjangController.dispose();
    _ruangTambahanController.dispose();
    super.dispose();
  }

  void _tambahRuang() {
    if (_ruangTambahanController.text.isNotEmpty) {
      setState(() {
        _listRuangCustom.add(_ruangTambahanController.text);
        _ruangTambahanController.clear();
      });
    }
  }

  void _prosesGenerate() {
    if (_formKey.currentState!.validate()) {
      double lebar = double.parse(_lebarController.text);
      double panjang = double.parse(_panjangController.text);

      // Simulasi generate ruangan berdasarkan input
      List<RoomModel> generatedRooms = [
        RoomModel(nama: "Ruang Tamu", width: 100, height: 100, x: 20, y: 20),
      ];
      
      for(int i = 1; i <= _jumlahKamar; i++) {
        generatedRooms.add(RoomModel(nama: "Kamar $i", width: 80, height: 80, x: 130, y: 20 + (i * 10)));
      }

      for (var ruang in _listRuangCustom) {
        generatedRooms.add(RoomModel(nama: ruang, width: 70, height: 70, x: 50, y: 150));
      }

      // Berpindah ke halaman hasil dengan membawa data input
      Get.to(() => HasilDenahPage(
            rooms: generatedRooms,
            inputLebarRumah: lebar,
            inputPanjangRumah: panjang,
            // Jika HasilDenahPage sudah kamu update untuk menerima material, 
            // kamu bisa menambahkannya di sini:
            // selectedMaterial: _selectedMaterial, 
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Kebutuhan Rumah", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Dimensi Lahan"),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildInputField(label: "Lebar (m)", controller: _lebarController, icon: Icons.straighten)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildInputField(label: "Panjang (m)", controller: _panjangController, icon: Icons.square_foot)),
                ],
              ),

              const SizedBox(height: 35),

              _sectionTitle("Jumlah Kamar Tidur"),
              const SizedBox(height: 10),
              _buildCounterSection(),

              const SizedBox(height: 35),

              // SEKSI BARU: PILIHAN MATERIAL
              _sectionTitle("Pilihan Material Dinding"),
              const SizedBox(height: 10),
              _buildMaterialDropdown(),

              const SizedBox(height: 35),

              _sectionTitle("Ruang Tambahan (Ketik Sendiri)"),
              const SizedBox(height: 10),
              _buildDynamicInputSection(),

              const SizedBox(height: 20),

              // Daftar Chip Ruangan
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _listRuangCustom.map((ruang) {
                  return Chip(
                    label: Text(ruang, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: const Color(0xFFE47B3E),
                    deleteIcon: const Icon(Icons.cancel, size: 16, color: Colors.white),
                    onDeleted: () => setState(() => _listRuangCustom.remove(ruang)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 50),

              _buildGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)));
  }

  Widget _buildInputField({required String label, required TextEditingController controller, required IconData icon}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0D1B2A)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      validator: (v) => v!.isEmpty ? "Isi angka" : null,
    );
  }

  Widget _buildCounterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Jumlah Kamar", style: TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              _counterBtn(Icons.remove, () => setState(() => _jumlahKamar > 1 ? _jumlahKamar-- : null)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text("$_jumlahKamar", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _counterBtn(Icons.add, () => setState(() => _jumlahKamar++)),
            ],
          )
        ],
      ),
    );
  }

  // Widget Baru untuk Dropdown Material
  Widget _buildMaterialDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMaterial,
          isExpanded: true,
          icon: const Icon(Icons.layers_outlined, color: Color(0xFF0D1B2A)),
          items: _materialOptions.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: const TextStyle(fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedMaterial = value!);
          },
        ),
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF0D1B2A), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildDynamicInputSection() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _ruangTambahanController,
            decoration: InputDecoration(
              hintText: "Contoh: Mushola, Gudang...",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _tambahRuang,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D1B2A),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _prosesGenerate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE47B3E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: const Text("GENERATE SEKARANG", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
      ),
    );
  }
}