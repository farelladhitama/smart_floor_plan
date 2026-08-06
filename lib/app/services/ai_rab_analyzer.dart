import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIRabAnalyzer {
  static const String apiKey = "AQ.Ab8RN6JWaSkq8sUh7reqz2R-G3ged-QeiZkyF1YYvPt-TBjniw";

  static Future<String> analyze({
    required double totalBiaya,
    required Map<String, dynamic> rincian,
    required String kategori,
    required String materialDinding,
    required String jenisTukang,
    required int jumlahKamar,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final prompt = """
Anda adalah seorang estimator bangunan profesional Indonesia.

Analisis hasil estimasi RAB berikut.

DATA:

Total Biaya :
Rp ${totalBiaya.toStringAsFixed(0)}

Kategori :
$kategori

Material Dinding :
$materialDinding

Jenis Tukang :
$jenisTukang

Jumlah Kamar :
$jumlahKamar

Rincian:
${jsonEncode(rincian)}

Jangan menghitung ulang RAB.

Berikan:

1. Ringkasan
2. Analisis material
3. Saran penghematan
4. Prioritas pekerjaan
5. Kesimpulan

Gunakan bahasa Indonesia.

Maksimal 300 kata.
""";

      final response =
          await model.generateContent([Content.text(prompt)]);

      return response.text ??
          "AI tidak dapat memberikan analisis saat ini.";
    } catch (e) {
      debugPrint(e.toString());

      return _fallback(
        totalBiaya,
        kategori,
        materialDinding,
        jenisTukang,
      );
    }
  }

  static String _fallback(
    double total,
    String kategori,
    String material,
    String tukang,
  ) {
    return """
📊 Ringkasan

Estimasi biaya pembangunan sebesar Rp ${total.toStringAsFixed(0)} termasuk kategori $kategori.

🧱 Analisis Material

Material utama menggunakan $material dengan tenaga kerja $tukang.

💰 Saran Penghematan

Apabila ingin mengurangi biaya, pertimbangkan menggunakan material alternatif dengan kualitas setara serta lakukan pembelian material secara bertahap.

🏗 Prioritas Pekerjaan

1. Pondasi
2. Struktur
3. Dinding
4. Atap
5. Finishing

✅ Kesimpulan

Estimasi RAB sudah sesuai dengan spesifikasi yang dipilih dan dapat dijadikan acuan awal pembangunan.
""";
  }
}