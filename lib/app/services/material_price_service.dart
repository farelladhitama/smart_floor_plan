import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialPriceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRabMaterialItems() async {
    final response = await _supabase
        .from('rab_material_items')
        .select()
        .order('nama_material', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}
