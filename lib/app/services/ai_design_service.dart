import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_floor_plan/app/data/models/ai_design_params.dart';

class AIDesignService {
  static String _apiKey = '';
  
  static void setApiKey(String key) {
    _apiKey = key;
  }

  // ============= SIMULASI SEPERTI API =============
  Future<AIDesignParams> analyzePrompt(String prompt) async {
    print('⏳ [AI] Menganalisis prompt...');
    final stopwatch = Stopwatch()..start();
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final params = _parsePromptManually(prompt);
    final enrichedParams = _enrichWithVariation(params, prompt);
    
    print('✅ [AI] Selesai dalam ${stopwatch.elapsedMilliseconds}ms');
    print('📊 [AI] Hasil: ${enrichedParams.style}, ${enrichedParams.bedroom} kamar');
    
    return enrichedParams;
  }

  // ============= ANALISIS PROMPT SEPERTI AI =============
  AIDesignParams _parsePromptManually(String prompt) {
    final lower = prompt.toLowerCase();
    
    print('🔍 [AI] Menganalisis: "$prompt"');
    
    // === STYLE ===
    String style = 'Modern';
    if (lower.contains('minimalis')) style = 'Minimalis Modern';
    else if (lower.contains('klasik') || lower.contains('classic')) style = 'Klasik';
    else if (lower.contains('tropis')) style = 'Tropis';
    else if (lower.contains('skandinavia') || lower.contains('scandinavian')) style = 'Skandinavia';
    else if (lower.contains('industrial')) style = 'Industrial';
    else if (lower.contains('kontemporer') || lower.contains('contemporary')) style = 'Kontemporer';
    else if (lower.contains('jepang') || lower.contains('japanese')) style = 'Jepang';
    else if (lower.contains('mediterania')) style = 'Mediterania';
    else if (lower.contains('modern')) style = 'Modern';
    
    // === FAMILY SIZE ===
    int familySize = 4;
    final familyMatch = RegExp(r'(\d+)\s*orang').firstMatch(lower);
    if (familyMatch != null) {
      familySize = int.tryParse(familyMatch.group(1) ?? '4') ?? 4;
    }
    if (lower.contains('keluarga') && familySize == 4) {
      familySize = 5;
    }
    if (lower.contains('anak')) {
      final childMatch = RegExp(r'(\d+)\s*anak').firstMatch(lower);
      if (childMatch != null) {
        final children = int.tryParse(childMatch.group(1) ?? '2') ?? 2;
        familySize = familySize + children;
      } else {
        familySize = familySize + 2;
      }
    }
    
    // === BEDROOM ===
    int bedroom = 3;
    final bedMatch = RegExp(r'(\d+)\s*kamar').firstMatch(lower);
    if (bedMatch != null) {
      bedroom = int.tryParse(bedMatch.group(1) ?? '3') ?? 3;
    }
    if (familySize >= 6 && bedroom < 4) bedroom = 4;
    if (familySize >= 8 && bedroom < 5) bedroom = 5;
    if (familySize >= 10 && bedroom < 6) bedroom = 6;
    if (lower.contains('keluarga besar') && bedroom < 4) bedroom = 4;
    
    // === BATHROOM ===
    int bathroom = 2;
    final bathMatch = RegExp(r'(\d+)\s*kamar\s*mandi').firstMatch(lower);
    if (bathMatch != null) {
      bathroom = int.tryParse(bathMatch.group(1) ?? '2') ?? 2;
    } else if (bedroom >= 4) {
      bathroom = 3;
    } else if (bedroom >= 2) {
      bathroom = 2;
    } else {
      bathroom = 1;
    }
    if (lower.contains('km/wc') && bathroom < 2) bathroom = 2;
    
    // === PRIORITY ===
    String priority = 'Fungsi';
    if (lower.contains('pencahayaan') || lower.contains('cahaya') || 
        lower.contains('terang') || lower.contains('natural') ||
        lower.contains('lighting')) {
      priority = 'Natural Lighting';
    } else if (lower.contains('privasi') || lower.contains('tertutup') ||
               lower.contains('privacy')) {
      priority = 'Privasi';
    } else if (lower.contains('terbuka') || lower.contains('lapang') ||
               lower.contains('open')) {
      priority = 'Ruang Terbuka';
    } else if (lower.contains('estetika') || lower.contains('indah') || 
               lower.contains('cantik') || lower.contains('aesthetic')) {
      priority = 'Estetika';
    } else if (lower.contains('efisiensi') || lower.contains('hemat') || 
               lower.contains('compact') || lower.contains('efficient')) {
      priority = 'Efisiensi';
    } else if (lower.contains('sirkulasi') || lower.contains('udara')) {
      priority = 'Sirkulasi Udara';
    }
    
    // === EXTRA ROOMS ===
    List<String> extraRooms = [];
    final Map<String, String> roomKeywords = {
      'ruang kerja': 'Ruang Kerja',
      'kantor': 'Ruang Kerja',
      'study': 'Ruang Kerja',
      'office': 'Ruang Kerja',
      'mushola': 'Mushola',
      'musola': 'Mushola',
      'gudang': 'Gudang',
      'storage': 'Gudang',
      'ruang keluarga': 'Ruang Keluarga',
      'family': 'Ruang Keluarga',
      'ruang makan': 'Ruang Makan',
      'dining': 'Ruang Makan',
      'laundry': 'Laundry',
      'cuci': 'Laundry',
      'taman': 'Taman',
      'garden': 'Taman',
      'garasi': 'Garasi',
      'carport': 'Garasi',
      'kolam renang': 'Kolam Renang',
      'pool': 'Kolam Renang',
      'perpustakaan': 'Perpustakaan',
      'library': 'Perpustakaan',
      'gym': 'Ruang Gym',
      'ruang olahraga': 'Ruang Gym',
      'home theater': 'Home Theater',
      'ruang hiburan': 'Home Theater',
      'teras': 'Teras',
      'balkon': 'Balkon',
      'ruang jemur': 'Ruang Jemur',
    };
    
    for (final entry in roomKeywords.entries) {
      if (lower.contains(entry.key)) {
        if (!extraRooms.contains(entry.value)) {
          extraRooms.add(entry.value);
        }
      }
    }
    
    // === GARAGE ===
    int garage = 0;
    final garageMatch = RegExp(r'(\d+)\s*mobil').firstMatch(lower);
    if (garageMatch != null) {
      garage = int.tryParse(garageMatch.group(1) ?? '0') ?? 0;
    } else if (lower.contains('garasi') || lower.contains('carport')) {
      garage = 1;
    }
    if (lower.contains('2 mobil') || lower.contains('dua mobil')) garage = 2;
    if (lower.contains('3 mobil') || lower.contains('tiga mobil')) garage = 3;
    if (lower.contains('4 mobil') || lower.contains('empat mobil')) garage = 4;
    
    // === GARDEN ===
    String garden = 'Tidak Ada';
    if (lower.contains('taman belakang')) garden = 'Back';
    else if (lower.contains('taman depan')) garden = 'Front';
    else if (lower.contains('taman samping')) garden = 'Side';
    else if (lower.contains('taman keliling')) garden = 'Around';
    else if (lower.contains('taman dalam')) garden = 'Inner Court';
    else if (lower.contains('taman')) garden = 'Back';
    
    // === BUDGET ===
    double? budget;
    final budgetMatch = RegExp(r'(\d+)\s*(juta|jt|miliar|m)').firstMatch(lower);
    if (budgetMatch != null) {
      final num = double.tryParse(budgetMatch.group(1) ?? '0') ?? 0;
      final unit = budgetMatch.group(2) ?? '';
      if (unit.contains('miliar') || unit == 'm') {
        budget = num * 1000000000;
      } else if (unit.contains('juta') || unit == 'jt') {
        budget = num * 1000000;
      }
    }
    
    print('✅ [AI] Analisis selesai:');
    print('   Style: $style');
    print('   Penghuni: $familySize orang');
    print('   Kamar: $bedroom');
    print('   KM/WC: $bathroom');
    print('   Prioritas: $priority');
    print('   Ruang tambahan: ${extraRooms.join(", ")}');
    print('   Garasi: $garage mobil');
    print('   Taman: $garden');
    
    return AIDesignParams(
      style: style,
      familySize: familySize,
      bedroom: bedroom,
      bathroom: bathroom,
      priority: priority,
      extraRooms: extraRooms,
      garage: garage,
      garden: garden,
      budget: budget,
    );
  }

  // ============= TAMBAH VARIASI AGAR TIDAK MONOTON =============
  AIDesignParams _enrichWithVariation(AIDesignParams params, String prompt) {
    final lower = prompt.toLowerCase();
    
    var newExtraRooms = List<String>.from(params.extraRooms);
    var newGarage = params.garage;
    var newGarden = params.garden;
    
    if (lower.contains('mewah') || lower.contains('luxury')) {
      if (!newExtraRooms.contains('Home Theater')) {
        newExtraRooms.add('Home Theater');
      }
      if (!newExtraRooms.contains('Ruang Gym')) {
        newExtraRooms.add('Ruang Gym');
      }
      if (newGarage < 2) newGarage = 2;
    }
    
    if (lower.contains('2 lantai') || lower.contains('dua lantai')) {
      if (!newExtraRooms.contains('Balkon')) {
        newExtraRooms.add('Balkon');
      }
    }
    
    if (lower.contains('tanpa garasi') || lower.contains('no garage')) {
      newGarage = 0;
    }
    
    if (lower.contains('tanpa taman') || lower.contains('no garden')) {
      newGarden = 'Tidak Ada';
    }
    
    return params.copyWith(
      extraRooms: newExtraRooms,
      garage: newGarage,
      garden: newGarden,
    );
  }
}