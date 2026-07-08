import 'package:get/get.dart';
import '../../../services/material_item_service.dart';
import '../../../data/models/material_item_model.dart';

class AnalysisController extends GetxController {
  final MaterialItemService _service = Get.find<MaterialItemService>();
  
  final isLoading = false.obs;
  final allMaterials = <MaterialItem>[].obs;
  final filteredMaterials = <MaterialItem>[].obs;
  final categories = <String>[].obs;
  
  // Filter
  final selectedCategory = 'Semua Kategori'.obs;
  final selectedSort = 'Termurah'.obs;
  final searchQuery = ''.obs;
  
  final sortOptions = ['Termurah', 'Termahal', 'A-Z', 'Z-A'];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() async {
    try {
      isLoading.value = true;
      
      final data = await _service.getMaterialItems();
      allMaterials.value = data;
      filteredMaterials.value = data;
      
      // Ambil kategori unik
      final cats = await _service.getCategories();
      categories.value = ['Semua Kategori', ...cats];
      
    } catch (e) {
      print('❌ Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    var data = allMaterials.toList();

    // Filter kategori
    if (selectedCategory.value != 'Semua Kategori') {
      data = data.where((e) => e.kategori == selectedCategory.value).toList();
    }

    // Search
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      data = data.where((e) =>
        e.namaMaterial.toLowerCase().contains(q) ||
        e.kategori.toLowerCase().contains(q)
      ).toList();
    }

    // Sorting
    switch (selectedSort.value) {
      case 'Termurah':
        data.sort((a, b) => a.hargaUtama.compareTo(b.hargaUtama));
        break;
      case 'Termahal':
        data.sort((a, b) => b.hargaUtama.compareTo(a.hargaUtama));
        break;
      case 'A-Z':
        data.sort((a, b) => a.namaMaterial.compareTo(b.namaMaterial));
        break;
      case 'Z-A':
        data.sort((a, b) => b.namaMaterial.compareTo(a.namaMaterial));
        break;
    }

    filteredMaterials.value = data;
  }

  void setCategory(String category) {
    selectedCategory.value = category;
    applyFilters();
  }

  void setSort(String sort) {
    selectedSort.value = sort;
    applyFilters();
  }

  void search(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  // Statistik
  int get totalItems => filteredMaterials.length;
  
  double get cheapestPrice {
    if (filteredMaterials.isEmpty) return 0;
    return filteredMaterials.map((e) => e.hargaUtama).reduce((a, b) => a < b ? a : b);
  }
  
  double get mostExpensivePrice {
    if (filteredMaterials.isEmpty) return 0;
    return filteredMaterials.map((e) => e.hargaUtama).reduce((a, b) => a > b ? a : b);
  }
  
  double get averagePrice {
    if (filteredMaterials.isEmpty) return 0;
    return filteredMaterials.map((e) => e.hargaUtama).reduce((a, b) => a + b) / filteredMaterials.length;
  }
}