import 'package:supabase_flutter/supabase_flutter.dart';

class PdfDownloadHistoryService {
  static Future<void> record({
    required Map<String, dynamic> item,
    String? fileName,
  }) async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final User? user = supabase.auth.currentUser;

      if (user == null) {
        print('PDF HISTORY: gagal, user belum login.');
        return;
      }

      final String finalFileName = fileName ?? buildFileName(item);

      final Map<String, dynamic> payload = {
        'user_id': user.id,
        'user_name': _getUserName(user, item),
        'floor_plan_id': _readTextOrNull(item['id']),
        'title': _readText(item['title'], fallback: 'Denah SmartFloorPlan'),
        'file_name': finalFileName,
        'total_luas': _readNumber(item['total_luas'] ?? item['totalLuas']),
        'estimasi_rab': _readNumber(item['estimasi_rab'] ?? item['estimasiRab']),
      };

      print('PDF HISTORY INSERT PAYLOAD: $payload');

      await supabase.from('pdf_download_histories').insert(payload);

      print('PDF HISTORY: berhasil masuk Supabase.');
    } catch (e) {
      print('PDF HISTORY ERROR: $e');
    }
  }

  static String buildFileName(Map<String, dynamic> item) {
    final String title = _readText(
      item['title'],
      fallback: 'denah_smartfloorplan',
    );

    final String safeTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    return '${safeTitle}_$timestamp.pdf';
  }

  static String _getUserName(User user, Map<String, dynamic> item) {
    final String fromItem = _readText(item['user_name'], fallback: '');

    if (fromItem.trim().isNotEmpty) {
      return fromItem.trim();
    }

    final Map<String, dynamic>? metadata = user.userMetadata;

    final dynamic name = metadata?['name'] ??
        metadata?['full_name'] ??
        metadata?['username'] ??
        metadata?['display_name'];

    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }

    if (user.email != null && user.email!.trim().isNotEmpty) {
      return user.email!.trim();
    }

    return 'User';
  }

  static String _readText(dynamic value, {required String fallback}) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  static String? _readTextOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static double? _readNumber(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
