import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_floor_plan/app/data/models/ai_design_params.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AI DESIGN SERVICE — Gemini API + Rule-Based Fallback
// ═══════════════════════════════════════════════════════════════════════════════

class AIDesignService {
  static const String _modelName = 'gemini-1.5-flash';

  static AIDesignService? _instance;
  GenerativeModel? _model;

  factory AIDesignService() {
    _instance ??= AIDesignService._internal();
    return _instance!;
  }

  AIDesignService._internal() {
    _initModel();
  }

  void _initModel() {
    try {
      final apiKey = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
      if (apiKey.isNotEmpty && apiKey != 'MASUKKAN_API_KEY_ANDA_DISINI') {
        _model = GenerativeModel(
          model: _modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.2,
            maxOutputTokens: 600,
            responseMimeType: 'application/json',
          ),
        );
        debugPrint('✅ [AI] Gemini model berhasil diinisialisasi');
      } else {
        debugPrint('⚠️ [AI] API key belum diisi, gunakan mode rule-based');
      }
    } catch (e) {
      debugPrint('❌ [AI] Gagal inisialisasi Gemini: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PUBLIK: analyzePrompt
  // ═══════════════════════════════════════════════════════════════════════════

  Future<AIDesignParams> analyzePrompt(String prompt) async {
    debugPrint('⏳ [AI] Menganalisis: "$prompt"');
    final stopwatch = Stopwatch()..start();

    AIDesignParams params;

    if (_model != null) {
      try {
        params = await _analyzeWithGemini(prompt);
        debugPrint('✅ [AI] Gemini selesai dalam ${stopwatch.elapsedMilliseconds}ms');
      } catch (e) {
        debugPrint('⚠️ [AI] Gemini gagal ($e), fallback ke rule-based');
        params = _analyzeRuleBased(prompt);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      params = _analyzeRuleBased(prompt);
      debugPrint('✅ [AI] Rule-based selesai dalam ${stopwatch.elapsedMilliseconds}ms');
    }

    _printResult(params);
    return params;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  GEMINI API CALL
  // ═══════════════════════════════════════════════════════════════════════════

  Future<AIDesignParams> _analyzeWithGemini(String userPrompt) async {
    final systemPrompt = '''
Anda adalah AI analis desain rumah profesional. Analisis deskripsi rumah dari user dan hasilkan parameter dalam format JSON.

ATURAN UKURAN LAHAN (tanpa budget):
- Studio/pasangan/1-2 kamar: lebar_lahan 6-9, panjang_lahan 5-8
- Keluarga kecil/3 kamar: lebar_lahan 12-14, panjang_lahan 10-12
- Keluarga/4 kamar: lebar_lahan 14-16, panjang_lahan 12-14
- Keluarga besar/5 kamar: lebar_lahan 18-20, panjang_lahan 14-16
- Keluarga sangat besar/6+ kamar: lebar_lahan 20-24, panjang_lahan 16-20
- Setiap kolam renang: +3m lebar, +4m panjang
- Setiap gym/home theater: +2m lebar, +1.5m panjang
- Garasi 2 mobil: +2m lebar, +1m panjang
- Garasi 3+ mobil: +3m lebar, +1.5m panjang
- Taman keliling/besar: +2m lebar, +2m panjang
- Style mewah/klasik: +2m lebar, +1.5m panjang
- Style minimalis: -1m lebar, -0.5m panjang

ATURAN STYLE:
- "minimalis" → "Minimalis Modern"
- "klasik" saja → "Klasik"
- "mewah klasik" / "klasik mewah" → "Mewah Klasik"
- "tropis" → "Tropis"
- "skandinavia" → "Skandinavia"
- "industrial" → "Industrial"
- "jepang"/"japanese"/"zen" → "Jepang"
- "kontemporer" → "Kontemporer"
- "mewah"/"luxury" → "Mewah Modern"
- default → "Modern"

ATURAN PRIORITY:
- "cahaya"/"terang"/"pencahayaan"/"jendela besar" → "Natural Lighting"
- "privasi"/"tertutup"/"terisolasi" → "Privasi"
- "terbuka"/"lapang"/"open" → "Ruang Terbuka"
- "estetika"/"indah"/"cantik" → "Estetika"
- "hemat"/"efisiensi"/"compact"/"efficient" → "Efisiensi"
- "sirkulasi"/"angin"/"ventilasi"/"udara" → "Sirkulasi Udara"
- style Minimalis → default "Efisiensi"
- style Tropis → default "Sirkulasi Udara"
- style Skandinavia → default "Natural Lighting"
- style Jepang → default "Privasi"
- style Mewah/Klasik → default "Estetika"

ATURAN EXTRA ROOMS (jangan masukkan garasi dan taman ke extra_rooms):
- Deteksi: mushola, ruang kerja, gudang, laundry, kolam renang, perpustakaan, gym, home theater, balkon, dapur bersih, ruang makan, ruang keluarga, ruang jemur
- Style Mewah Modern/Mewah Klasik: otomatis tambah "Home Theater" dan "Ruang Gym" jika belum ada

GARDEN: "Back", "Front", "Side", "Around", "Inner Court", "Tidak Ada"
- "taman belakang" → "Back"
- "taman depan" → "Front"
- "taman samping" → "Side"
- "taman keliling"/"taman sekeliling" → "Around"
- "taman dalam"/"taman tengah"/"courtyard" → "Inner Court"
- "taman" saja → "Back" (atau "Inner Court" untuk Tropis/Jepang)
- Style Tropis/Jepang tanpa taman → otomatis "Inner Court"
- Style Skandinavia tanpa taman → otomatis "Back"

FORMAT WAJIB (JSON saja, tanpa teks lain):
{
  "style": "...",
  "family_size": <angka>,
  "bedroom": <angka>,
  "bathroom": <angka>,
  "priority": "...",
  "extra_rooms": ["...", "..."],
  "garage": <jumlah mobil, 0 jika tidak ada>,
  "garden": "...",
  "budget": <angka rupiah atau null>,
  "lebar_lahan": <angka float>,
  "panjang_lahan": <angka float>
}

Deskripsi user: $userPrompt
''';

    final response = await _model!.generateContent([
      Content.text(systemPrompt),
    ]);

    final text = response.text ?? '';
    debugPrint('📥 [Gemini] Raw: $text');

    String cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceAll(RegExp(r'^```[a-z]*\n?', multiLine: false), '')
          .replaceAll(RegExp(r'\n?```$', multiLine: false), '')
          .trim();
    }

    final Map<String, dynamic> json = jsonDecode(cleaned);
    return AIDesignParams.fromJson(json);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RULE-BASED FALLBACK — Akurat & Sesuai Prompt User
  // ═══════════════════════════════════════════════════════════════════════════

  AIDesignParams _analyzeRuleBased(String prompt) {
    final lower = prompt.toLowerCase();

    // ─── STYLE ────────────────────────────────────────────────────────────────
    // Cek kombinasi "mewah + klasik" dulu sebelum cek individual
    String style = 'Modern';
    if ((lower.contains('mewah') || lower.contains('luxury')) &&
        (lower.contains('klasik') || lower.contains('classic'))) {
      style = 'Mewah Klasik';
    } else if (lower.contains('minimalis')) {
      style = 'Minimalis Modern';
    } else if (lower.contains('tropis')) {
      style = 'Tropis';
    } else if (lower.contains('skandinavia') || lower.contains('scandinavian')) {
      style = 'Skandinavia';
    } else if (lower.contains('industrial')) {
      style = 'Industrial';
    } else if (lower.contains('jepang') || lower.contains('japanese') ||
               lower.contains('zen') || lower.contains('minimalis jepang')) {
      style = 'Jepang';
    } else if (lower.contains('kontemporer') || lower.contains('contemporary')) {
      style = 'Kontemporer';
    } else if (lower.contains('mewah') || lower.contains('luxury')) {
      style = 'Mewah Modern';
    } else if (lower.contains('klasik') || lower.contains('classic')) {
      style = 'Klasik';
    } else if (lower.contains('modern')) {
      style = 'Modern';
    }

    // ─── FAMILY SIZE ──────────────────────────────────────────────────────────
    // ⭐ FIX: Prioritaskan angka eksplisit, jangan override dengan "keluarga"
    int familySize = 0;

    final familyMatch = RegExp(r'(\d+)\s*orang').firstMatch(lower);
    if (familyMatch != null) {
      familySize = int.tryParse(familyMatch.group(1) ?? '0') ?? 0;
    }

    // Hanya pakai kata kunci jika TIDAK ada angka eksplisit
    if (familySize == 0) {
      if (lower.contains('pasangan') || lower.contains('berdua') ||
          lower.contains('couple') || lower.contains('2 orang')) {
        familySize = 2;
      } else if (lower.contains('single') || lower.contains('sendiri') ||
                 lower.contains('lajang') || lower.contains('1 orang')) {
        familySize = 1;
      } else if (lower.contains('keluarga besar')) {
        familySize = 8;
      } else if (lower.contains('keluarga')) {
        familySize = 5;
      } else {
        familySize = 4; // default
      }
    }

    // Tambah anak jika disebutkan
    if (lower.contains('anak')) {
      final childMatch = RegExp(r'(\d+)\s*anak').firstMatch(lower);
      final children = childMatch != null
          ? (int.tryParse(childMatch.group(1) ?? '2') ?? 2)
          : 2;
      familySize += children;
    }

    // ─── BEDROOM ──────────────────────────────────────────────────────────────
    // ⭐ FIX: Cek "kamar tidur" dulu (spesifik), baru "kamar" (umum)
    // Hindari matching "kamar mandi" sebagai bedroom
    int bedroom = 0;

    final bedTidurMatch = RegExp(r'(\d+)\s*kamar\s*tidur').firstMatch(lower);
    if (bedTidurMatch != null) {
      bedroom = int.tryParse(bedTidurMatch.group(1) ?? '0') ?? 0;
    }

    // Jika belum ketemu, coba "X kamar" tapi pastikan bukan "kamar mandi"
    if (bedroom == 0) {
      for (final m in RegExp(r'(\d+)\s*kamar(?!\s*mandi)').allMatches(lower)) {
        final n = int.tryParse(m.group(1) ?? '0') ?? 0;
        if (n > 0 && n <= 12) {
          bedroom = n;
          break;
        }
      }
    }

    // Default bedroom dari konteks jika tidak disebutkan
    if (bedroom == 0) {
      if (lower.contains('studio') || familySize <= 2) {
        bedroom = 1;
      } else if (familySize <= 3) {
        bedroom = 2;
      } else if (familySize <= 5) {
        bedroom = 3;
      } else if (familySize <= 7) {
        bedroom = 4;
      } else if (familySize <= 9) {
        bedroom = 5;
      } else {
        bedroom = 6;
      }
    }

    // Paksa minimum berdasarkan family size
    if (familySize >= 10 && bedroom < 6) bedroom = 6;
    else if (familySize >= 8 && bedroom < 5) bedroom = 5;
    else if (familySize >= 6 && bedroom < 4) bedroom = 4;

    // ─── BATHROOM ─────────────────────────────────────────────────────────────
    // ⭐ FIX: Deteksi lebih akurat, include "toilet" & "wc"
    int bathroom = 0;

    final bathMatch = RegExp(r'(\d+)\s*kamar\s*mandi').firstMatch(lower)
        ?? RegExp(r'(\d+)\s*toilet').firstMatch(lower)
        ?? RegExp(r'(\d+)\s*wc').firstMatch(lower);
    if (bathMatch != null) {
      bathroom = int.tryParse(bathMatch.group(1) ?? '0') ?? 0;
    }

    // Auto-hitung dari bedroom jika tidak disebutkan
    if (bathroom == 0) {
      if (bedroom >= 6) bathroom = 4;
      else if (bedroom >= 5) bathroom = 4;
      else if (bedroom >= 4) bathroom = 3;
      else if (bedroom >= 3) bathroom = 2;
      else if (bedroom >= 2) bathroom = 2;
      else bathroom = 1;
    }

    // ─── PRIORITY ─────────────────────────────────────────────────────────────
    String priority = '';

    if (lower.contains('pencahayaan alami') || lower.contains('cahaya alami') ||
        lower.contains('pencahayaan') || lower.contains('cahaya') ||
        lower.contains('terang') || lower.contains('jendela besar') ||
        lower.contains('natural lighting') || lower.contains('sinar matahari')) {
      priority = 'Natural Lighting';
    } else if (lower.contains('privasi') || lower.contains('tertutup') ||
               lower.contains('terisolasi') || lower.contains('privacy') ||
               lower.contains('tidak tembus pandang')) {
      priority = 'Privasi';
    } else if (lower.contains('ruang terbuka') || lower.contains('open plan') ||
               lower.contains('lapang') || lower.contains('lega') ||
               lower.contains('open space')) {
      priority = 'Ruang Terbuka';
    } else if (lower.contains('estetika') || lower.contains('indah') ||
               lower.contains('cantik') || lower.contains('aesthetic') ||
               lower.contains('elegan') || lower.contains('mewah')) {
      priority = 'Estetika';
    } else if (lower.contains('efisiensi') || lower.contains('hemat ruang') ||
               lower.contains('compact') || lower.contains('efficient') ||
               lower.contains('fungsional')) {
      priority = 'Efisiensi';
    } else if (lower.contains('sirkulasi udara') || lower.contains('ventilasi') ||
               lower.contains('angin') || lower.contains('udara segar') ||
               lower.contains('sejuk')) {
      priority = 'Sirkulasi Udara';
    }

    // Default priority dari style jika tidak disebutkan
    if (priority.isEmpty) {
      switch (style) {
        case 'Minimalis Modern': priority = 'Efisiensi'; break;
        case 'Tropis':           priority = 'Sirkulasi Udara'; break;
        case 'Skandinavia':      priority = 'Natural Lighting'; break;
        case 'Jepang':           priority = 'Privasi'; break;
        case 'Mewah Modern':
        case 'Mewah Klasik':
        case 'Klasik':           priority = 'Estetika'; break;
        default:                 priority = 'Fungsi';
      }
    }

    // ─── EXTRA ROOMS ──────────────────────────────────────────────────────────
    // ⭐ FIX: Garasi & taman TIDAK masuk extraRooms (ditangani di field terpisah)
    final List<String> extraRooms = [];

    final Map<String, String> roomKeywords = {
      // Ruang kerja
      'ruang kerja':    'Ruang Kerja',
      'home office':    'Ruang Kerja',
      'kantor':         'Ruang Kerja',
      'study room':     'Ruang Kerja',
      // Ibadah
      'mushola':        'Mushola',
      'musola':         'Mushola',
      'masjid':         'Mushola',
      'sholat':         'Mushola',
      'ibadah':         'Mushola',
      // Penyimpanan
      'gudang':         'Gudang',
      'storage':        'Gudang',
      // Laundry
      'laundry':        'Laundry',
      'area cuci':      'Laundry',
      'ruang cuci':     'Laundry',
      // Kolam
      'kolam renang':   'Kolam Renang',
      'swimming pool':  'Kolam Renang',
      'kolam':          'Kolam Renang',
      'pool':           'Kolam Renang',
      // Perpustakaan
      'perpustakaan':   'Perpustakaan',
      'library':        'Perpustakaan',
      'ruang buku':     'Perpustakaan',
      // Olahraga
      'ruang gym':      'Ruang Gym',
      'ruang olahraga': 'Ruang Gym',
      'ruang fitness':  'Ruang Gym',
      'fitness':        'Ruang Gym',
      'gym':            'Ruang Gym',
      // Hiburan
      'home theater':   'Home Theater',
      'bioskop':        'Home Theater',
      'ruang hiburan':  'Home Theater',
      'home cinema':    'Home Theater',
      // Balkon/Teras
      'balkon':         'Balkon',
      'balcony':        'Balkon',
      'teras':          'Teras',
      // Dapur
      'dapur bersih':   'Dapur Bersih',
      'pantry':         'Dapur Bersih',
      // Ruang lain
      'ruang jemur':    'Ruang Jemur',
      'jemuran':        'Ruang Jemur',
      'ruang makan':    'Ruang Makan',
      'dining room':    'Ruang Makan',
      'ruang keluarga': 'Ruang Keluarga',
      'family room':    'Ruang Keluarga',
      'ruang meditasi': 'Ruang Meditasi',
      'ruang musik':    'Ruang Musik',
    };

    for (final entry in roomKeywords.entries) {
      if (lower.contains(entry.key)) {
        if (!extraRooms.contains(entry.value)) {
          extraRooms.add(entry.value);
        }
      }
    }

    // Auto-tambah dari style mewah
    if (style == 'Mewah Modern' || style == 'Mewah Klasik') {
      if (!extraRooms.contains('Home Theater')) extraRooms.add('Home Theater');
      if (!extraRooms.contains('Ruang Gym')) extraRooms.add('Ruang Gym');
    }
    // Auto-tambah dari 2 lantai
    if ((lower.contains('2 lantai') || lower.contains('dua lantai')) &&
        !extraRooms.contains('Balkon')) {
      extraRooms.add('Balkon');
    }

    // ─── GARAGE ───────────────────────────────────────────────────────────────
    // ⭐ FIX: Deteksi jumlah mobil dengan berbagai format
    int garage = 0;

    // Cek "X mobil" (angka)
    final garageNumMatch = RegExp(r'(\d+)\s*mobil').firstMatch(lower);
    if (garageNumMatch != null) {
      garage = int.tryParse(garageNumMatch.group(1) ?? '0') ?? 0;
    }

    // Cek angka tertulis
    if (garage == 0 || lower.contains('satu mobil'))  { if (lower.contains('satu mobil')) garage = 1; }
    if (lower.contains('dua mobil') || lower.contains('2 mobil'))     garage = 2;
    if (lower.contains('tiga mobil') || lower.contains('3 mobil'))    garage = 3;
    if (lower.contains('empat mobil') || lower.contains('4 mobil'))   garage = 4;

    // Cek keberadaan garasi tanpa jumlah
    if (garage == 0 && (lower.contains('garasi') || lower.contains('carport'))) {
      garage = 1;
    }

    // Style mewah minimal 2 garasi
    if ((style == 'Mewah Modern' || style == 'Mewah Klasik') && garage < 2) {
      garage = 2;
    }

    // Tidak ada garasi jika eksplisit
    if (lower.contains('tanpa garasi') || lower.contains('no garage') ||
        lower.contains('tidak ada garasi')) {
      garage = 0;
    }

    // ─── GARDEN ───────────────────────────────────────────────────────────────
    String garden = '';

    if (lower.contains('tanpa taman') || lower.contains('no garden') ||
        lower.contains('tidak ada taman')) {
      garden = 'Tidak Ada';
    } else if (lower.contains('taman keliling') || lower.contains('taman mengelilingi') ||
               lower.contains('taman sekeliling')) {
      garden = 'Around';
    } else if (lower.contains('taman dalam') || lower.contains('taman tengah') ||
               lower.contains('inner court') || lower.contains('courtyard') ||
               lower.contains('taman zen')) {
      garden = 'Inner Court';
    } else if (lower.contains('taman belakang')) {
      garden = 'Back';
    } else if (lower.contains('taman depan')) {
      garden = 'Front';
    } else if (lower.contains('taman samping')) {
      garden = 'Side';
    } else if (lower.contains('taman luas')) {
      garden = 'Around';
    } else if (lower.contains('taman')) {
      // Style-aware default taman
      if (style == 'Tropis' || style == 'Jepang') {
        garden = 'Inner Court';
      } else {
        garden = 'Back';
      }
    }

    // Default dari style jika tidak ada taman disebutkan
    if (garden.isEmpty) {
      if (style == 'Tropis' || style == 'Jepang') {
        garden = 'Inner Court';
      } else if (style == 'Skandinavia') {
        garden = 'Back';
      } else if (style == 'Mewah Modern' || style == 'Mewah Klasik' || style == 'Klasik') {
        garden = 'Back';
      } else {
        garden = 'Tidak Ada';
      }
    }

    // ─── BUDGET ───────────────────────────────────────────────────────────────
    double? budget;

    final budgetMiliar = RegExp(r'(\d+(?:[.,]\d+)?)\s*(miliar|milyar)\b').firstMatch(lower);
    final budgetJuta   = RegExp(r'(\d+(?:[.,]\d+)?)\s*(juta|jt)\b').firstMatch(lower);

    if (budgetMiliar != null) {
      final raw = budgetMiliar.group(1)!.replaceAll(',', '.');
      budget = (double.tryParse(raw) ?? 0) * 1000000000;
    } else if (budgetJuta != null) {
      final raw = budgetJuta.group(1)!.replaceAll(',', '.');
      budget = (double.tryParse(raw) ?? 0) * 1000000;
    }

    // ─── UKURAN LAHAN ─────────────────────────────────────────────────────────
    final landSize = _calculateLandSize(
      bedroom:    bedroom,
      familySize: familySize,
      budget:     budget,
      extraRooms: extraRooms,
      garage:     garage,
      style:      style,
      garden:     garden,
    );

    return AIDesignParams(
      style:       style,
      familySize:  familySize,
      bedroom:     bedroom,
      bathroom:    bathroom,
      priority:    priority,
      extraRooms:  extraRooms,
      garage:      garage,
      garden:      garden,
      budget:      budget,
      lebarLahan:  landSize['lebar']!,
      panjangLahan: landSize['panjang']!,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  KALKULASI UKURAN LAHAN — Berdasarkan semua parameter
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, double> _calculateLandSize({
    required int bedroom,
    required int familySize,
    required double? budget,
    required List<String> extraRooms,
    required int garage,
    required String style,
    String garden = 'Tidak Ada',
  }) {
    double lebar;
    double panjang;

    // ── Base size: kombinasi bedroom + family size (ambil yang lebih besar) ──
    final effBed = bedroom;
    final effFam = familySize;

    if (effBed >= 7 || effFam >= 12) {
      lebar = 22.0; panjang = 18.0;
    } else if (effBed >= 6 || effFam >= 10) {
      lebar = 20.0; panjang = 16.0;
    } else if (effBed >= 5 || effFam >= 8) {
      lebar = 18.0; panjang = 14.0;
    } else if (effBed == 4 || effFam >= 6) {
      lebar = 14.0; panjang = 12.0;
    } else if (effBed == 3 || effFam >= 4) {
      lebar = 12.0; panjang = 10.0;
    } else if (effBed == 2) {
      lebar = 9.0;  panjang = 7.0;
    } else {
      lebar = 7.0;  panjang = 6.0;
    }

    // ── Penyesuaian budget ──────────────────────────────────────────────────
    if (budget != null) {
      if (budget >= 3000000000) {      lebar += 4.0; panjang += 3.0;
      } else if (budget >= 2000000000) { lebar += 3.0; panjang += 2.5;
      } else if (budget >= 1500000000) { lebar += 2.0; panjang += 2.0;
      } else if (budget >= 1000000000) { lebar += 1.5; panjang += 1.5;
      } else if (budget >= 700000000) {   lebar += 1.0; panjang += 1.0;
      } else if (budget < 250000000) {    lebar -= 2.5; panjang -= 2.0;
      } else if (budget < 400000000) {    lebar -= 1.5; panjang -= 1.5;
      } else if (budget < 500000000) {    lebar -= 1.0; panjang -= 1.0;
      }
    }

    // ── Penyesuaian ruang tambahan (per-tipe) ──────────────────────────────
    for (final room in extraRooms) {
      final r = room.toLowerCase();
      if (r.contains('kolam renang') || r.contains('pool')) {
        lebar += 3.0; panjang += 4.0;
      } else if (r.contains('gym') || r.contains('olahraga') || r.contains('fitness')) {
        lebar += 2.0; panjang += 1.5;
      } else if (r.contains('home theater') || r.contains('bioskop') || r.contains('cinema')) {
        lebar += 1.5; panjang += 1.5;
      } else if (r.contains('perpustakaan') || r.contains('library')) {
        lebar += 1.0; panjang += 1.0;
      } else if (r.contains('ruang kerja') || r.contains('office')) {
        lebar += 1.0; panjang += 0.5;
      } else if (r.contains('mushola') || r.contains('ibadah')) {
        lebar += 1.0; panjang += 1.0;
      } else {
        lebar += 0.5; panjang += 0.5;
      }
    }

    // ── Penyesuaian garasi ─────────────────────────────────────────────────
    if (garage >= 4)      { lebar += 4.5; panjang += 2.0; }
    else if (garage >= 3) { lebar += 3.0; panjang += 1.5; }
    else if (garage >= 2) { lebar += 2.0; panjang += 1.0; }
    else if (garage >= 1) { lebar += 1.0; panjang += 0.5; }

    // ── Penyesuaian taman ──────────────────────────────────────────────────
    if (garden == 'Around')      { lebar += 3.0; panjang += 3.0; }
    else if (garden == 'Inner Court') { lebar += 2.0; panjang += 2.0; }
    else if (garden == 'Back')   { lebar += 1.0; panjang += 1.0; }
    else if (garden == 'Front')  { lebar += 1.0; panjang += 1.0; }
    else if (garden == 'Side')   { lebar += 1.5; panjang += 0.5; }

    // ── Penyesuaian style ──────────────────────────────────────────────────
    switch (style) {
      case 'Mewah Klasik':
        lebar += 3.0; panjang += 2.0;
        break;
      case 'Mewah Modern':
      case 'Klasik':
        lebar += 2.0; panjang += 1.5;
        break;
      case 'Tropis':
        lebar += 1.0; panjang += 1.5;
        break;
      case 'Skandinavia':
        lebar += 0.5; panjang += 1.0;
        break;
      case 'Minimalis Modern':
        lebar -= 1.0; panjang -= 0.5;
        break;
    }

    // ── Clamp ke range wajar ────────────────────────────────────────────────
    lebar  = lebar.clamp(6.0, 30.0);
    panjang = panjang.clamp(5.0, 25.0);

    // ── Bulatkan ke 0.5m terdekat ──────────────────────────────────────────
    lebar  = (lebar  * 2).round() / 2.0;
    panjang = (panjang * 2).round() / 2.0;

    debugPrint('📐 [AI] Ukuran lahan: ${lebar}m × ${panjang}m');
    return {'lebar': lebar, 'panjang': panjang};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LOG HELPER
  // ═══════════════════════════════════════════════════════════════════════════

  void _printResult(AIDesignParams p) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📊 [AI] HASIL ANALISIS PROMPT:');
    debugPrint('   Style     : ${p.style}');
    debugPrint('   Penghuni  : ${p.familySize} orang');
    debugPrint('   Kamar     : ${p.bedroom} KT | ${p.bathroom} KM');
    debugPrint('   Prioritas : ${p.priority}');
    debugPrint('   Extra     : ${p.extraRooms.isEmpty ? "—" : p.extraRooms.join(", ")}');
    debugPrint('   Garasi    : ${p.garage} mobil');
    debugPrint('   Taman     : ${p.garden}');
    debugPrint('   Budget    : ${p.budget != null ? "Rp ${_formatBudget(p.budget!)}" : "tidak disebutkan"}');
    debugPrint('   Lahan     : ${p.lebarLahan}m × ${p.panjangLahan}m');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  String _formatBudget(double b) {
    if (b >= 1000000000) return '${(b / 1000000000).toStringAsFixed(1)} Miliar';
    if (b >= 1000000)     return '${(b / 1000000).toStringAsFixed(0)} Juta';
    return b.toStringAsFixed(0);
  }
}