import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../data/models/material_item_model.dart';

class MaterialItemService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Ambil semua material
  Future<List<MaterialItem>> getMaterialItems() async {
    try {
      final response = await _supabase
          .from('rab_material_options')
          .select('*')
          .eq('is_active', true) // ✅ Hanya yang aktif
          .order('kategori', ascending: true)
          .order('harga_rata_rata', ascending: true);

      print('✅ Found ${response.length} materials');
      return response.map((data) => MaterialItem.fromJson(data)).toList();
    } catch (e) {
      print('❌ Error getMaterialItems: $e');
      return [];
    }
  }

  // Ambil berdasarkan kategori
  Future<List<MaterialItem>> getMaterialsByCategory(String kategori) async {
    try {
      final response = await _supabase
          .from('rab_material_options')
          .select('*')
          .eq('kategori', kategori)
          .eq('is_active', true)
          .order('harga_rata_rata', ascending: true);

      return response.map((data) => MaterialItem.fromJson(data)).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  // Ambil kategori unik
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('rab_material_options')
          .select('kategori')
          .eq('is_active', true);

      final categories = response.map((e) => e['kategori'] as String).toSet().toList();
      categories.sort();
      return categories;
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  // Cari material
  Future<List<MaterialItem>> searchMaterials(String query) async {
    try {
      final response = await _supabase
          .from('rab_material_options')
          .select('*')
          .eq('is_active', true)
          .ilike('nama_material', '%$query%')
          .order('harga_rata_rata', ascending: true);

      return response.map((data) => MaterialItem.fromJson(data)).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  // Ambil material termurah
  Future<List<MaterialItem>> getCheapestMaterials({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('rab_material_options')
          .select('*')
          .eq('is_active', true)
          .order('harga_rata_rata', ascending: true)
          .limit(limit);

      return response.map((data) => MaterialItem.fromJson(data)).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  // Ambil material termahal
  Future<List<MaterialItem>> getMostExpensiveMaterials({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('rab_material_options')
          .select('*')
          .eq('is_active', true)
          .order('harga_rata_rata', ascending: false)
          .limit(limit);

      return response.map((data) => MaterialItem.fromJson(data)).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }
}