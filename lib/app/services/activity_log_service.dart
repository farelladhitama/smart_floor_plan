import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_floor_plan/app/modules/activity_log/models/activity_log_model.dart';

class ActivityLogService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Tambah log baru
  static Future<void> addLog({
    required String title,
    required String description,
    required String icon,
  }) async {
    try {
      final user = _client.auth.currentUser;

      if (user == null) return;

      await _client.from('activity_logs').insert({
        'user_id': user.id,
        'title': title,
        'description': description,
        'icon': icon,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Activity Log Error : $e');
    }
  }

  /// Ambil seluruh activity user
  static Future<List<ActivityLogModel>> getLogs() async {
    try {
      final user = _client.auth.currentUser;

      if (user == null) return [];

      final response = await _client
          .from('activity_logs')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => ActivityLogModel.fromJson(e))
          .toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  /// Hapus semua activity
  static Future<void> clearLogs() async {
    try {
      final user = _client.auth.currentUser;

      if (user == null) return;

      await _client
          .from('activity_logs')
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      print(e);
    }
  }

  /// Hapus satu activity
  static Future<void> deleteLog(String id) async {
    try {
      await _client
          .from('activity_logs')
          .delete()
          .eq('id', id);
    } catch (e) {
      print(e);
    }
  }
}