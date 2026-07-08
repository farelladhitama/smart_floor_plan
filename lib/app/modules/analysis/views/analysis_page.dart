import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/analysis_controller.dart';
import '../../../data/models/material_item_model.dart';

class AnalysisPage extends GetView<AnalysisController> {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Analisis Material'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search
                TextField(
                  onChanged: controller.search,
                  decoration: InputDecoration(
                    hintText: '🔍 Cari material...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 8),
                // Filter row
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => DropdownButtonFormField<String>(
                        value: controller.selectedCategory.value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          isDense: true,
                        ),
                        items: controller.categories.map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) controller.setCategory(v);
                        },
                      )),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Obx(() => DropdownButtonFormField<String>(
                        value: controller.selectedSort.value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          isDense: true,
                        ),
                        items: controller.sortOptions.map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) controller.setSort(v);
                        },
                      )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = controller.filteredMaterials;

        return Column(
          children: [
            // Statistik cards
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[50],
              child: Row(
                children: [
                  _statCard('Total', controller.totalItems.toString(), Icons.inventory, Colors.blue),
                  _statCard('Termurah', 'Rp${_format(controller.cheapestPrice)}', Icons.trending_down, Colors.green),
                  _statCard('Termahal', 'Rp${_format(controller.mostExpensivePrice)}', Icons.trending_up, Colors.red),
                  _statCard('Rata-rata', 'Rp${_format(controller.averagePrice)}', Icons.equalizer, Colors.orange),
                ],
              ),
            ),
            // List
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Tidak ada data material', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _materialCard(item);
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _materialCard(MaterialItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.03),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon kategori
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _catColor(item.kategori).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _catIcon(item.kategori),
              color: _catColor(item.kategori),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Info material
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaMaterial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.kategori,
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.satuan,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '📊 ${item.jumlahData} data',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Harga
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp${_format(item.hargaUtama)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blue,
                ),
              ),
              Text(
                'Min: Rp${_format(item.hargaMinimum)}',
                style: TextStyle(fontSize: 9, color: Colors.grey[400]),
              ),
              _priceTag(item.hargaUtama),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceTag(double price) {
    Color color;
    String label;
    if (price < 50000) {
      color = Colors.green;
      label = '💚 Murah';
    } else if (price < 150000) {
      color = Colors.orange;
      label = '💛 Sedang';
    } else {
      color = Colors.red;
      label = '❤️ Mahal';
    }
    return Text(
      label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
    );
  }

  Color _catColor(String kategori) {
    if (kategori.contains('Cat')) return Colors.purple;
    if (kategori.contains('Besi')) return Colors.blue;
    if (kategori.contains('Bata')) return Colors.orange;
    if (kategori.contains('Keramik')) return Colors.teal;
    if (kategori.contains('Semen')) return Colors.grey;
    if (kategori.contains('Kayu')) return Colors.brown;
    if (kategori.contains('Pipa')) return Colors.cyan;
    if (kategori.contains('Pasir')) return Colors.amber;
    return Colors.grey;
  }

  IconData _catIcon(String kategori) {
    if (kategori.contains('Cat')) return Icons.brush;
    if (kategori.contains('Besi')) return Icons.build;
    if (kategori.contains('Bata')) return Icons.home;
    if (kategori.contains('Keramik')) return Icons.grid_on;
    if (kategori.contains('Semen')) return Icons.construction;
    if (kategori.contains('Kayu')) return Icons.nature;
    if (kategori.contains('Pipa')) return Icons.water_damage;
    if (kategori.contains('Pasir')) return Icons.landscape;
    return Icons.category;
  }

  String _format(double number) {
    String result = '';
    String numStr = number.round().toString();
    int count = 0;
    for (int i = numStr.length - 1; i >= 0; i--) {
      result = numStr[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.' + result;
      }
    }
    return result;
  }
}