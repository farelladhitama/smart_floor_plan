import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';

class RabPage extends GetView<RabController> {
  final dynamic rooms;

  const RabPage({
    super.key,
    this.rooms,
  });

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);

  @override
  Widget build(BuildContext context) {
    controller.applyArgumentsFromPage(Get.arguments);

    if (rooms != null) {
      controller.setRooms(rooms);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        title: const Text(
          'Estimasi RAB',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: orange),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerCard(),
                  const SizedBox(height: 18),
                  inputCard(),
                  const SizedBox(height: 18),
                  totalCard(),
                  const SizedBox(height: 18),
                  materialListCard(),
                  const SizedBox(height: 18),
                  noteCard(),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: orange,
            radius: 26,
            child: Icon(Icons.receipt_long_rounded, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Estimasi awal bahan bangunan rumah berdasarkan luas lahan/denah dan data harga dari Supabase.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget inputCard() {
    return card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Perhitungan',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.luasController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: controller.setLuas,
            decoration: InputDecoration(
              labelText: 'Luas bangunan',
              suffixText: 'm2',
              prefixIcon: const Icon(Icons.square_foot_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: orange,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Estimasi Kebutuhan Material',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.rupiah(controller.totalRab),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Berdasarkan luas ${controller.luasBangunan.value.toStringAsFixed(1)} m2',
            style: const TextStyle(
              color: Color(0xFFFFEFE6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget materialListCard() {
    return card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kebutuhan Bahan Bangunan',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Jumlah bahan dihitung otomatis dari luas bangunan menggunakan koefisien estimasi awal.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...controller.rabItems.map(materialItem),
        ],
      ),
    );
  }

  Widget materialItem(RabMaterialResult item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.namaMaterial,
            style: const TextStyle(
              color: navy,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.kategori,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: miniInfo(
                  'Kebutuhan',
                  '${controller.formatVolume(item.volume)} ${item.satuan}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: miniInfo(
                  'Harga per 1 ${item.satuan}',
                  '${controller.rupiah(item.hargaSatuan)} / ${item.satuan}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          miniInfo(
            'Subtotal',
            controller.rupiah(item.totalHarga),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget miniInfo(String label, String value, {bool highlight = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFEFE6) : Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: highlight ? orange : navy,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget noteCard() {
    return card(
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Catatan: hasil RAB ini berupa estimasi awal. Jumlah bahan dan harga dapat berubah sesuai desain akhir, lokasi pembangunan, kualitas material, dan harga pasar terbaru.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: child,
    );
  }
}




