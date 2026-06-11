import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialPriceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRabMaterialOptions() async {
    final response = await _supabase
        .from('rab_material_options')
        .select()
        .eq('is_active', true)
        .order('kategori', ascending: true)
        .order('nama_material', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Fungsi lama tetap disediakan supaya kode lain tidak rusak.
  Future<List<Map<String, dynamic>>> getRabMaterialItems() async {
    return getRabMaterialOptions();
  }
}
