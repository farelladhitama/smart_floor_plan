import 'dart:math' as math;

import 'package:smart_floor_plan/app/core/floorplan/room_recommendation.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  RESULT
// ═══════════════════════════════════════════════════════════════════════════════

class SmartFloorPlanResult {
  final double landWidth;
  final double landLength;
  final List<RoomModel> rooms;

  const SmartFloorPlanResult({
    required this.landWidth,
    required this.landLength,
    required this.rooms,
  });

  double get landArea => landWidth * landLength;

  double get usedArea =>
      rooms.fold<double>(0, (sum, r) => sum + r.width * r.height);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ENGINE
// ═══════════════════════════════════════════════════════════════════════════════

class SmartFloorPlanEngine {
  // ── Constants ──────────────────────────────────────────────────────────────
  static const double _minRoom   = 1.2;   // minimum room dimension (m)
  static const double _wallGap   = 0.0;   // gap between rooms (set 0 = wall-to-wall)

  // ── Tier boundaries ────────────────────────────────────────────────────────
  static const double _tinyMax   = 45;
  static const double _smallMax  = 72;
  static const double _mediumMax = 140;

  // ═══════════════════════════════════════════════════════════════════════════
  //  PUBLIC: getRecommendations
  // ═══════════════════════════════════════════════════════════════════════════

  static List<RoomRecommendation> getRecommendations({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
  }) {
    final int count = bedroomCount <= 0
        ? estimateBedroomCount(landWidth: landWidth, landLength: landLength)
        : bedroomCount.clamp(1, 5);

    final result = generate(
      landWidth: landWidth,
      landLength: landLength,
      bedroomCount: count,
    );

    return result.rooms
        .where((r) => !_isHidden(r.nama))
        .map((r) => RoomRecommendation(
              name: r.nama,
              category: r.category,
              width: r.width,
              height: r.height,
              selected: true,
            ))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PUBLIC: generate
  // ═══════════════════════════════════════════════════════════════════════════

  static SmartFloorPlanResult generate({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
    List<RoomRecommendation> extraRooms = const [],
    int? seed,
  }) {
    final double W = _safe(landWidth,  8);
    final double L = _safe(landLength, 10);
    final double area  = W * L;
    final double ratio = W / L;   // <1 narrow, >1 wide

    final int beds = bedroomCount <= 0
        ? estimateBedroomCount(landWidth: W, landLength: L)
        : bedroomCount.clamp(1, 5);

    final rng     = seed != null ? math.Random(seed) : math.Random();
    final variant = rng.nextInt(4);

    List<RoomModel> rooms;

    if (area <= _tinyMax) {
      // ── TINY  (≤ 45 m²) ──────────────────────────────────────────────────
      rooms = ratio >= 1.15
          ? _tinyWide(W, L, beds.clamp(1, 1), extraRooms, variant)
          : _tinyNarrow(W, L, beds.clamp(1, 1), extraRooms, variant);

    } else if (area <= _smallMax) {
      // ── SMALL (45–72 m²) ─────────────────────────────────────────────────
      rooms = ratio >= 1.2
          ? _smallWide(W, L, beds.clamp(1, 2), extraRooms, variant)
          : _smallNarrow(W, L, beds.clamp(1, 2), extraRooms, variant);

    } else if (area <= _mediumMax) {
      // ── MEDIUM (72–140 m²) ───────────────────────────────────────────────
      rooms = ratio >= 1.25
          ? _mediumWide(W, L, beds.clamp(2, 3), extraRooms, variant)
          : _mediumNarrow(W, L, beds.clamp(2, 3), extraRooms, variant);

    } else {
      // ── LARGE (> 140 m²) ─────────────────────────────────────────────────
      rooms = ratio >= 1.2
          ? _largeWide(W, L, beds.clamp(3, 5), extraRooms, variant)
          : _largeNarrow(W, L, beds.clamp(3, 5), extraRooms, variant);
    }

    return SmartFloorPlanResult(
      landWidth:  W,
      landLength: L,
      rooms: _normalize(rooms, W, L),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  estimateBedroomCount
  // ═══════════════════════════════════════════════════════════════════════════

  static int estimateBedroomCount({
    required double landWidth,
    required double landLength,
  }) {
    final double a = landWidth * landLength;
    if (a <= 50)  return 1;
    if (a <= 90)  return 2;
    if (a <= 150) return 3;
    return 4;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TIER 1 – TINY  (≤ 45 m²)
  //  Prinsip: ZERO margin, gunakan 100% lahan, max 5 ruangan
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tiny narrow  – layout linier vertikal, semua zona memenuhi lahan
  static List<RoomModel> _tinyNarrow(
    double W, double L, int beds,
    List<RoomRecommendation> extra, int v,
  ) {
    final rooms = <RoomModel>[];

    // Tidak ada margin / yard – gunakan 100% lahan
    // Bagi tinggi jadi 3 zona proporsional
    //   [DEPAN] teras + ruang tamu
    //   [TENGAH] kamar tidur + km/wc
    //   [BELAKANG] dapur + area cuci

    final double zFront  = L * _pick(v, [0.32, 0.30, 0.28, 0.34]);
    final double zMid    = L * _pick(v, [0.38, 0.40, 0.42, 0.36]);
    final double zBack   = L - zFront - zMid;

    final double yBack   = 0;
    final double yMid    = zBack;
    final double yFront  = zBack + zMid;

    // ── Zona Depan ────────────────────────────────────────────────────────
    final double terW = W * _pick(v, [0.40, 0.45, 0.35, 0.50]);
    _add(rooms, nama:'Teras',        cat:'outdoor', x:0,    y:yFront, w:terW,   h:zFront);
    _add(rooms, nama:'Ruang Tamu',   cat:'living',  x:terW, y:yFront, w:W-terW, h:zFront);

    // ── Zona Tengah ───────────────────────────────────────────────────────
    final double bathW = W * _pick(v, [0.35, 0.30, 0.38, 0.32]);
    _add(rooms, nama:'K. Tidur Utama', cat:'bedroom', x:0,     y:yMid, w:W-bathW, h:zMid);
    _add(rooms, nama:'KM/WC',          cat:'bath',    x:W-bathW, y:yMid, w:bathW,   h:zMid);

    // ── Zona Belakang ─────────────────────────────────────────────────────
    final double kitW = W * _pick(v, [0.55, 0.60, 0.50, 0.58]);
    _add(rooms, nama:'Dapur',      cat:'kitchen', x:0,    y:yBack, w:kitW,   h:zBack);
    _add(rooms, nama:'Area Cuci',  cat:'service', x:kitW, y:yBack, w:W-kitW, h:zBack);

    _placeExtra(rooms, extra, W, L, 0, yMid, W);
    return rooms;
  }

  /// Tiny wide – layout kolom kiri/kanan, semua zona memenuhi lahan
  static List<RoomModel> _tinyWide(
    double W, double L, int beds,
    List<RoomRecommendation> extra, int v,
  ) {
    final rooms = <RoomModel>[];

    // Kolom kiri = private (kamar + km)
    // Kolom kanan = publik+servis (tamu, dapur, cuci)
    final double cLeft = W * _pick(v, [0.48, 0.45, 0.52, 0.50]);
    final double cRight = W - cLeft;

    // Bagi tinggi kiri: kamar atas, km bawah
    final double bedH   = L * _pick(v, [0.60, 0.55, 0.65, 0.58]);
    final double bathH  = L - bedH;

    _add(rooms, nama:'K. Tidur Utama', cat:'bedroom', x:0,     y:L-bedH,  w:cLeft, h:bedH);
    _add(rooms, nama:'KM/WC',          cat:'bath',    x:0,     y:0,        w:cLeft, h:bathH);

    // Bagi tinggi kanan: tamu atas, dapur tengah, cuci bawah
    final double livH   = L * _pick(v, [0.42, 0.45, 0.38, 0.40]);
    final double kitH   = L * _pick(v, [0.34, 0.30, 0.36, 0.32]);
    final double svcH   = L - livH - kitH;

    _add(rooms, nama:'Ruang Tamu',  cat:'living',  x:cLeft, y:L-livH,      w:cRight, h:livH);
    _add(rooms, nama:'Dapur',       cat:'kitchen', x:cLeft, y:svcH,        w:cRight, h:kitH);
    _add(rooms, nama:'Area Cuci',   cat:'service', x:cLeft, y:0,           w:cRight, h:svcH);

    _placeExtra(rooms, extra, W, L, cLeft, L * 0.4, cRight);
    return rooms;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TIER 2 – SMALL  (45–72 m²)
  //  Prinsip: margin minimal (teras sebagai elemen denah, bukan yard)
  // ═══════════════════════════════════════════════════════════════════════════

  static List<RoomModel> _smallNarrow(
    double W, double L, int beds,
    List<RoomRecommendation> extra, int v,
  ) {
    final rooms = <RoomModel>[];

    // Hanya taman depan kecil
    final double taman = _clamp(L * 0.10, 0.6, 1.2);
    final double bH    = L - taman;   // tinggi bangunan
    final double bY    = 0;

    // 3 zona vertikal
    final double zF = bH * _pick(v, [0.28, 0.25, 0.30, 0.26]);
    final double zM = bH * _pick(v, [0.38, 0.42, 0.36, 0.40]);
    final double zB = bH - zF - zM;

    final double yB = bY;
    final double yM = bY + zB;
    final double yF = bY + zB + zM;

    // Depan
    final double terW = _clamp(W * 0.38, 1.6, 2.8);
    _add(rooms, nama:'Teras',       cat:'outdoor', x:0,    y:yF, w:terW,   h:zF);
    _add(rooms, nama:'Ruang Tamu',  cat:'living',  x:terW, y:yF, w:W-terW, h:zF);
    _add(rooms, nama:'Taman Depan', cat:'outdoor', x:0, y:yF+zF,  w:W, h:taman);

    // Tengah – keluarga
    if (v == 3) {
      // v3: ruang keluarga full lebar + ruang makan kecil di pojok
      final double famW = W * 0.65;
      _add(rooms, nama:'R. Keluarga', cat:'family',  x:0,    y:yM, w:famW,   h:zM);
      _add(rooms, nama:'R. Makan',    cat:'dining',  x:famW, y:yM, w:W-famW, h:zM);
    } else {
      _add(rooms, nama:'R. Keluarga', cat:'family',  x:0, y:yM, w:W, h:zM);
    }

    // Belakang – kamar + servis
    if (beds <= 1) {
      final double bathW = _clamp(W * 0.32, 1.4, 2.2);
      final double kitH  = zB * 0.42;
      _add(rooms, nama:'K. Tidur Utama', cat:'bedroom', x:0,       y:yB,       w:W-bathW, h:zB);
      _add(rooms, nama:'KM/WC',          cat:'bath',    x:W-bathW, y:yB+kitH,  w:bathW,   h:zB-kitH);
      _add(rooms, nama:'Dapur',          cat:'kitchen', x:W-bathW, y:yB,       w:bathW,   h:kitH);
    } else {
      final double halfW = W * _pick(v, [0.52, 0.55, 0.48, 0.50]);
      final double bathW = _clamp(W * 0.28, 1.3, 2.0);
      final double remW  = W - halfW - bathW;
      _add(rooms, nama:'K. Tidur Utama', cat:'bedroom', x:0,      y:yB, w:halfW,       h:zB);
      _add(rooms, nama:'K. Tidur 1',     cat:'bedroom', x:halfW,  y:yB, w:remW > _minRoom ? remW : bathW, h:zB * 0.55);
      _add(rooms, nama:'Dapur',          cat:'kitchen', x:halfW,  y:yB + zB*0.55, w:remW > _minRoom ? remW : bathW, h:zB*0.45);
      _add(rooms, nama:'KM/WC',          cat:'bath',    x:W-bathW,y:yB, w:bathW,       h:zB * 0.52);
      _add(rooms, nama:'Area Cuci',      cat:'service', x:W-bathW,y:yB+zB*0.52, w:bathW, h:zB*0.48);
    }

    _placeExtra(rooms, extra, W, L, 0, yM, W);
    return rooms;
  }

  static List<RoomModel> _smallWide(
    double W, double L, int beds,
    List<RoomRecommendation> extra, int v,
  ) {
    final rooms = <RoomModel>[];

    final double taman = _clamp(L * 0.10, 0.6, 1.0);
    final double bH    = L - taman;

    // Kolom kiri private, kanan publik+servis
    final double cL = W * _pick(v, [0.46, 0.42, 0.50, 0.44]);
    final double cR = W - cL;

    // Kiri: kamar(atas) + km(bawah)
    final double bedH = bH * _pick(v, [0.58, 0.55, 0.62, 0.60]);
    _add(rooms, nama:'K. Tidur Utama', cat:'bedroom', x:0, y:bH-bedH, w:cL, h:bedH);
    if (beds >= 2) {
      final double bed2H = bH - bedH;
      _add(rooms, nama:'K. Tidur 1', cat:'bedroom', x:0, y:0, w:cL * 0.60, h:bed2H);
      _add(rooms, nama:'KM/WC',      cat:'bath',    x:cL*0.60, y:0, w:cL*0.40, h:bed2H);
    } else {
      _add(rooms, nama:'KM/WC', cat:'bath', x:0, y:0, w:cL, h:bH-bedH);
    }

    // Kanan: teras+tamu(atas), keluarga(tengah), dapur+cuci(bawah)
    final double livH = bH * _pick(v, [0.30, 0.28, 0.32, 0.30]);
    final double famH = bH * _pick(v, [0.34, 0.36, 0.32, 0.35]);
    final double svcH = bH - livH - famH;

    final double terW = cR * 0.40;
    _add(rooms, nama:'Teras',       cat:'outdoor', x:cL,       y:bH-livH, w:terW,    h:livH);
    _add(rooms, nama:'Ruang Tamu',  cat:'living',  x:cL+terW,  y:bH-livH, w:cR-terW, h:livH);
    _add(rooms, nama:'R. Keluarga', cat:'family',  x:cL,       y:svcH,    w:cR,      h:famH);
    _add(rooms, nama:'Dapur',       cat:'kitchen', x:cL,       y:0,       w:cR*0.58, h:svcH);
    _add(rooms, nama:'Area Cuci',   cat:'service', x:cL+cR*0.58, y:0,     w:cR*0.42, h:svcH);

    _add(rooms, nama:'Taman Depan', cat:'outdoor', x:0, y:bH, w:W, h:taman);

    _placeExtra(rooms, extra, W, L, cL, svcH, cR);
    return rooms;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TIER 3 – MEDIUM  (72–140 m²)
  // ═══════════════════════════════════════════════════════════════════════════

  static List<RoomModel> _mediumNarrow(
    double W, double L, int beds,
    List<RoomRecommendation> extra, int v,
  ) {
    final rooms = <RoomModel>[];

    final double sideL  = _clamp(W * 0.06, 0.40, 0.80);
    final double sideR  = _clamp(W * 0.05, 0.30, 0.65);
    final double taman  = _clamp(L * 0.11, 1.0, 1.8);
    final double backYd = _clamp(L * 0.07, 0.6, 1.2);

    final double bX = sideL;
    final double bW = W - sideL - sideR;
    final double bH = L - taman - backYd;
    final double bY = backYd;

    // 4 zona – rasio disesuaikan per variant
    final double rF = _pick(v, [0.22, 0.20, 0.24, 0.22]);
    final double rP = _pick(v, [0.27, 0.30, 0.28, 0.25]);
    final double rV = _pick(v, [0.28, 0.26, 0.26, 0.32]);

    final double zF = bH * rF;   // front: teras+tamu
    final double zP = bH * rP;   // public: keluarga
    final double zV = bH * rV;   // private: kamar
    final double zS = bH - zF - zP - zV;  // service: dapur+km

    final double yS  = bY;
    final double yV  = bY + zS;
    final double yP  = bY + zS + zV;
    final double yF  = bY + zS + zV + zP;

    // Front
    final bool hasCarport = W >= 7.0;
    final double cpW  = hasCarport ? _clamp(W * 0.30, 2.4, 3.2) : 0;
    final double terW = _clamp(bW * 0.24, 1.6, 2.6);

    if (hasCarport) _add(rooms, nama:'Carport', cat:'outdoor', x:bX, y:yF, w:cpW, h:zF);
    _add(rooms, nama:'Teras',       cat:'outdoor', x:bX+cpW,       y:yF+zF*0.18, w:terW,        h:zF*0.82);
    _add(rooms, nama:'Ruang Tamu',  cat:'living',  x:bX+cpW+terW,  y:yF,         w:bW-cpW-terW, h:zF);
    _add(rooms, nama:'Taman Depan', cat:'outdoor', x:bX, y:yF+zF, w:bW, h:taman);

    // Public
    final double famW = bW * _pick(v, [0.62, 0.70, 0.58, 0.65]);
    _add(rooms, nama:'R. Keluarga',    cat:'family',  x:bX,       y:yP, w:famW,    h:zP);
    _add(rooms, nama:'Taman Samping',  cat:'outdoor', x:bX+famW,  y:yP, w:bW-famW, h:zP);

    // v3: ada ruang makan di zona public
    if (v == 3) {
      final double dinH = zP * 0.44;
      _add(rooms, nama:'R. Makan', cat:'dining',
          x:bX+famW*(beds<=2?0.65:0.60), y:yP, w:famW*(beds<=2?0.35:0.40), h:dinH);
    }

    // Private – kamar
    _buildBedroomZone(rooms, bX, yV, bW, zV, beds, v);

    // Service
    final double kitW = _clamp(bW * 0.32, 2.2, 3.8);
    final double dinW = v == 3 ? 0 : _clamp(bW * 0.28, 2.0, 3.4);
    final double bathW= _clamp(bW * 0.18, 1.5, 2.4);
    final double svcW = bW - kitW - dinW - bathW;

    _add(rooms, nama:'Dapur',     cat:'kitchen', x:bX,              y:yS, w:kitW, h:zS);
    if (dinW > _minRoom)
      _add(rooms, nama:'R. Makan', cat:'dining',  x:bX+kitW,         y:yS+zS*0.10, w:dinW, h:zS*0.90);
    _add(rooms, nama:'KM/WC',     cat:'bath',    x:bX+kitW+dinW,    y:yS, w:bathW, h:zS*0.76);
    if (svcW > _minRoom)
      _add(rooms, nama:'Area Cuci', cat:'service', x:bX+kitW+dinW+bathW, y:yS+zS*0.14, w:svcW, h:zS*0.86);

    _add(rooms, nama:'Taman Belakang', cat:'outdoor', x:bX, y:0, w:bW, h:backYd);

    _placeExtra(rooms, extra, W, L, bX + bW*0.55, yP, bW*0.40);
    return rooms;
  }

  static List<RoomModel> _mediumWide(
    double W, double L, int beds,
    List<RoomRecommendation> extra, int v,
  ) {
    final rooms = <RoomModel>[];

    final double side   = _clamp(W * 0.05, 0.45, 0.80);
    final double taman  = _clamp(L * 0.10, 0.9, 1.6);
    final double backYd = _clamp(L * 0.07, 0.6, 1.0);

    final double bX = side;
    final double bW = W - side * 2;
    final double bH = L - taman - backYd;
    final double bY = backYd;

    // 3 zona horizontal
    final double zF = bH * _pick(v, [0.26, 0.24, 0.28, 0.26]);
    final double zM = bH * _pick(v, [0.38, 0.42, 0.36, 0.40]);
    final double zB = bH - zF - zM;

    final double yB = bY;
    final double yM = bY + zB;
    final double yF = bY + zB + zM;

    // Front – carport (v0/v2 kiri, v1/v3 kanan)
    final double cpW  = _clamp(bW * 0.30, 2.6, 3.6);
    final bool   cpR  = (v == 1 || v == 3);
    final double cpX  = cpR ? bX + bW - cpW : bX;
    final double pubX = cpR ? bX : bX + cpW;
    final double pubW = bW - cpW;

    _add(rooms, nama:'Carport',     cat:'outdoor', x:cpX, y:yF, w:cpW, h:zF);
    _add(rooms, nama:'Teras',       cat:'outdoor', x:pubX, y:yF+zF*0.50, w:pubW*0.36, h:zF*0.50);
    _add(rooms, nama:'Ruang Tamu',  cat:'living',  x:pubX+pubW*0.36, y:yF, w:pubW*0.64, h:zF);
    _add(rooms, nama:'Taman Depan', cat:'outdoor', x:bX, y:yF+zF, w:bW, h:taman);

    // Middle – keluarga + taman samping
    final double famW = bW * _pick(v, [0.68, 0.72, 0.65, 0.70]);
    final double garW = bW - famW;
    final bool   garR = (v == 0 || v == 2);

    _add(rooms, nama:'R. Keluarga',   cat:'family',  x:garR?bX+garW:bX, y:yM, w:famW, h:zM);
    _add(rooms, nama:'Taman Samping', cat:'outdoor', x:garR?bX:bX+famW, y:yM+zM*0.12, w:garW, h:zM*0.88);

    // Back – kamar + dapur + km
    _buildBedroomZone(rooms, bX, yB, bW, zB, beds, v);

    _add(rooms, nama:'Taman Belakang', cat:'outdoor', x:bX, y:0, w:bW, h:backYd);

    _placeExtra(rooms, extra, W, L, bX + bW*0.55, yM, bW*0.40);
    return rooms;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TIER 4 – LARGE  (> 140 m²)
  // ═══════════════════════════════════════════════════════════════════════════

  static List<RoomModel> _largeNarrow(
    double W, double L, int beds,
    List<RoomRecommendation> extra, int v,
  ) {
    final rooms = <RoomModel>[];

    final double sideL  = _clamp(W * 0.06, 0.60, 1.00);
    final double sideR  = _clamp(W * 0.05, 0.50, 0.90);
    final double taman  = _clamp(L * 0.12, 1.6, 2.6);
    final double backYd = _clamp(L * 0.08, 0.9, 1.5);

    final double bX = sideL;
    final double bW = W - sideL - sideR;
    final double bH = L - taman - backYd;
    final double bY = backYd;

    final double rF = _pick(v, [0.20, 0.18, 0.22, 0.20]);
    final double rP = _pick(v, [0.28, 0.32, 0.26, 0.30]);
    final double rV = _pick(v, [0.30, 0.28, 0.32, 0.28]);

    final double zF = bH * rF;
    final double zP = bH * rP;
    final double zV = bH * rV;
    final double zS = bH - zF - zP - zV;

    final double yS = bY;
    final double yV = bY + zS;
    final double yP = bY + zS + zV;
    final double yF = bY + zS + zV + zP;

    // Front
    final double cpW  = _clamp(bW * 0.28, 3.0, 4.2);
    final double terW = _clamp(bW * 0.22, 2.0, 3.2);
    _add(rooms, nama:'Carport',     cat:'outdoor', x:bX,          y:yF, w:cpW,           h:zF);
    _add(rooms, nama:'Teras',       cat:'outdoor', x:bX+cpW,      y:yF+zF*0.22, w:terW,  h:zF*0.78);
    _add(rooms, nama:'Ruang Tamu',  cat:'living',  x:bX+cpW+terW, y:yF, w:bW-cpW-terW,  h:zF);
    _add(rooms, nama:'Taman Depan', cat:'outdoor', x:bX,          y:yF+zF, w:bW,         h:taman);

    // Public
    final double famW = v == 1 ? bW : _clamp(bW * 0.58, 4.6, bW-2.8);
    final double voidW = bW - famW;

    _add(rooms, nama:'R. Keluarga', cat:'family', x:bX, y:yP, w:famW, h:zP);
    if (voidW >= _minRoom && v != 1) {
      _add(rooms, nama:'Inner Court', cat:'outdoor', x:bX+famW, y:yP+zP*0.15, w:voidW, h:zP*0.85);
    }

    if (beds >= 4) {
      final double gW = _clamp(famW * 0.38, 2.6, 3.8);
      _add(rooms, nama:'K. Tidur 3', cat:'bedroom', x:bX+famW-gW, y:yP, w:gW, h:zP*0.55);
    }
    if (beds >= 5) {
      final double wW = _clamp(famW * 0.30, 2.4, 3.4);
      _add(rooms, nama:v==2?'K. Tidur 4':'Ruang Kerja',
           cat:v==2?'bedroom':'room', x:bX+famW-wW, y:yP+zP*0.55, w:wW, h:zP*0.45);
    }

    // Private – kamar dengan koridor
    final double mW  = _clamp(bW * 0.36, 3.4, 4.8);
    final double corW= _clamp(bW * 0.12, 1.0, 1.6);
    final double rW  = bW - mW - corW;
    final double spH = zV / 2;

    _add(rooms, nama:'K. Tidur Utama', cat:'bedroom', x:bX,         y:yV, w:mW, h:zV*0.58);
    _add(rooms, nama:'KM Utama',       cat:'bath',    x:bX,         y:yV+zV*0.58, w:mW, h:zV*0.42);
    _add(rooms, nama:'Koridor',        cat:'service', x:bX+mW,      y:yV+zV*0.08, w:corW, h:zV*0.84);
    _add(rooms, nama:'K. Tidur 1',     cat:'bedroom', x:bX+mW+corW, y:yV, w:rW, h:spH);
    _add(rooms, nama:'K. Tidur 2',     cat:'bedroom', x:bX+mW+corW, y:yV+spH, w:rW, h:spH);

    // Service
    final double kitW  = _clamp(bW * 0.30, 3.0, 4.4);
    final double dinW  = _clamp(bW * 0.26, 2.6, 4.0);
    final double bathW = _clamp(bW * 0.16, 1.6, 2.4);
    final double svcW  = bW - kitW - dinW - bathW;

    _add(rooms, nama:'Dapur',     cat:'kitchen', x:bX,                y:yS+zS*0.04, w:kitW,  h:zS*0.96);
    _add(rooms, nama:'R. Makan',  cat:'dining',  x:bX+kitW,           y:yS+zS*0.12, w:dinW,  h:zS*0.88);
    _add(rooms, nama:'KM/WC',     cat:'bath',    x:bX+kitW+dinW,      y:yS,         w:bathW, h:zS*0.76);
    if (svcW >= _minRoom)
      _add(rooms, nama:'Area Cuci', cat:'service', x:bX+kitW+dinW+bathW, y:yS+zS*0.14, w:svcW, h:zS*0.86);

    _add(rooms, nama:'Taman Belakang', cat:'outdoor', x:bX, y:0, w:bW, h:backYd);

    _placeExtra(rooms, extra, W, L, bX+bW*0.62, yP, bW*0.34);
    return rooms;
  }

  static List<RoomModel> _largeWide(
    double W, double L, int beds,
    List<RoomRecommendation> extra, int v,
  ) {
    final rooms = <RoomModel>[];

    final double side   = _clamp(W * 0.06, 0.70, 1.20);
    final double taman  = _clamp(L * 0.12, 1.6, 2.6);
    final double backYd = _clamp(L * 0.08, 0.9, 1.5);

    final double bX = side;
    final double bW = W - side * 2;
    final double bH = L - taman - backYd;
    final double bY = backYd;

    final double zF = bH * _pick(v, [0.22, 0.20, 0.24, 0.22]);
    final double zP = bH * _pick(v, [0.36, 0.40, 0.34, 0.38]);
    final double zV = bH - zF - zP;

    final double yV = bY;
    final double yP = bY + zV;
    final double yF = bY + zV + zP;

    // Lebar dibagi 3 wing
    final double lR = _pick(v, [0.34, 0.36, 0.30, 0.38]);
    final double cR = _pick(v, [0.32, 0.30, 0.36, 0.28]);
    final double lW = bW * lR;
    final double cW = bW * cR;
    final double rW = bW - lW - cW;

    _add(rooms, nama:'Carport',     cat:'outdoor', x:bX,       y:yF, w:lW, h:zF);
    _add(rooms, nama:'Teras',       cat:'outdoor', x:bX+lW,    y:yF+zF*0.50, w:cW, h:zF*0.50);
    _add(rooms, nama:'Ruang Tamu',  cat:'living',  x:bX+lW+cW, y:yF, w:rW, h:zF);
    _add(rooms, nama:'Taman Depan', cat:'outdoor', x:bX,        y:yF+zF, w:bW, h:taman);

    // Public
    final double famStartX = v == 1 ? bX : bX + lW;
    final double famW2     = v == 1 ? bW : cW + rW;
    _add(rooms, nama:'R. Keluarga', cat:'family', x:famStartX, y:yP, w:famW2, h:zP);
    if (v != 1) {
      _add(rooms, nama:'Inner Court', cat:'outdoor',
           x:bX, y:yP+zP*0.18, w:lW, h:zP*0.82);
    }

    // v3: R. Makan di wing kanan
    if (v == 3) {
      final double dinH = zP * 0.48;
      _add(rooms, nama:'R. Makan', cat:'dining', x:bX+lW+cW, y:yP, w:rW, h:dinH);
    }

    // Private
    final double spH = zV / 2;
    _add(rooms, nama:'K. Tidur Utama', cat:'bedroom', x:bX,      y:yV, w:lW, h:spH);
    _add(rooms, nama:'KM Utama',       cat:'bath',    x:bX,      y:yV+spH, w:lW, h:spH);
    _add(rooms, nama:'K. Tidur 1',     cat:'bedroom', x:bX+lW,   y:yV, w:cW, h:spH);
    _add(rooms, nama:'K. Tidur 2',     cat:'bedroom', x:bX+lW,   y:yV+spH, w:cW, h:spH);
    if (beds >= 4)
      _add(rooms, nama:'K. Tidur 3', cat:'bedroom', x:bX+lW+cW, y:yV, w:rW, h:spH);

    // Service di zone private kanan bawah jika beds < 4
    if (beds < 4) {
      _add(rooms, nama:'Dapur', cat:'kitchen', x:bX+lW+cW, y:yV, w:rW*0.55, h:spH);
      _add(rooms, nama:'KM/WC', cat:'bath',    x:bX+lW+cW+rW*0.55, y:yV, w:rW*0.45, h:spH);
    }
    if (beds < 4)
      _add(rooms, nama:'Area Cuci', cat:'service', x:bX+lW+cW, y:yV+spH, w:rW, h:spH);

    _add(rooms, nama:'Taman Belakang', cat:'outdoor', x:bX, y:0, w:bW, h:backYd);

    _placeExtra(rooms, extra, W, L, bX+lW, yP, cW+rW);
    return rooms;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED: bedroom zone builder
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tempatkan kamar tidur + km/wc + dapur dalam satu zona
  static void _buildBedroomZone(
    List<RoomModel> rooms,
    double bX, double yZone, double bW, double zH,
    int beds, int v,
  ) {
    if (beds <= 1) {
      final double bathW = _clamp(bW * 0.28, 1.3, 2.0);
      final double kitH  = zH * 0.40;
      _add(rooms, nama:'K. Tidur Utama', cat:'bedroom', x:bX,         y:yZone,       w:bW-bathW, h:zH);
      _add(rooms, nama:'KM/WC',          cat:'bath',    x:bX+bW-bathW,y:yZone+kitH,  w:bathW,    h:zH-kitH);
      _add(rooms, nama:'Dapur',          cat:'kitchen', x:bX+bW-bathW,y:yZone,        w:bathW,    h:kitH);
    } else if (beds == 2) {
      final double lW   = _clamp(bW * 0.50, 2.6, bW-2.4);
      final double bathW= _clamp(bW * 0.26, 1.3, 2.0);
      final double kitH = zH * 0.45;
      _add(rooms, nama:'K. Tidur Utama', cat:'bedroom', x:bX,           y:yZone, w:lW,          h:zH);
      _add(rooms, nama:'K. Tidur 1',     cat:'bedroom', x:bX+lW,        y:yZone, w:bW-lW-bathW, h:zH*0.55);
      _add(rooms, nama:'KM/WC',          cat:'bath',    x:bX+bW-bathW,  y:yZone+kitH, w:bathW,  h:zH-kitH);
      _add(rooms, nama:'Dapur',          cat:'kitchen', x:bX+bW-bathW,  y:yZone,      w:bathW,  h:kitH);
      _add(rooms, nama:'Area Cuci',      cat:'service', x:bX+lW,        y:yZone+zH*0.55, w:bW-lW-bathW, h:zH*0.45);
    } else {
      // 3+ kamar
      final double mW  = _clamp(bW * 0.38, 2.8, 4.2);
      final double corW= _clamp(bW * 0.10, 0.9, 1.4);
      final double rW  = bW - mW - corW;
      final double spH = zH / 2;

      _add(rooms, nama:'K. Tidur Utama', cat:'bedroom', x:bX,         y:yZone,       w:mW,  h:zH*0.58);
      _add(rooms, nama:'KM Utama',       cat:'bath',    x:bX,         y:yZone+zH*0.58, w:mW, h:zH*0.42);
      _add(rooms, nama:'Koridor',        cat:'service', x:bX+mW,      y:yZone+zH*0.10, w:corW, h:zH*0.80);
      _add(rooms, nama:'K. Tidur 1',     cat:'bedroom', x:bX+mW+corW, y:yZone,       w:rW,  h:spH);
      _add(rooms, nama:'K. Tidur 2',     cat:'bedroom', x:bX+mW+corW, y:yZone+spH,   w:rW,  h:spH);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static void _placeExtra(
    List<RoomModel> rooms,
    List<RoomRecommendation> extra,
    double W, double L,
    double baseX, double baseY, double maxW,
  ) {
    final selected = extra.where((r) => r.selected).toList();
    if (selected.isEmpty) return;
    double curY = baseY;
    for (final e in selected) {
      final rW = _clamp(e.width,  1.5, maxW);
      final rH = _clamp(e.height, 1.3, L * 0.18);
      if (baseX + rW > W || curY + rH > L) break;
      _add(rooms, nama:e.name, cat:e.category, x:baseX, y:curY, w:rW, h:rH);
      curY += rH + _wallGap;
    }
  }

  static void _add(
    List<RoomModel> rooms, {
    required String nama,
    required String cat,
    required double x,
    required double y,
    required double w,
    required double h,
  }) {
    if (w < _minRoom || h < _minRoom) return;
    rooms.add(RoomModel(nama:nama, category:cat, x:x, y:y, width:w, height:h));
  }

  static List<RoomModel> _normalize(List<RoomModel> rooms, double W, double L) {
    final result = <RoomModel>[];
    for (final r in rooms) {
      final x = _clamp(r.x, 0, W);
      final y = _clamp(r.y, 0, L);
      final w = _clamp(r.width,  _minRoom, math.max(_minRoom, W - x));
      final h = _clamp(r.height, _minRoom, math.max(_minRoom, L - y));
      if (x + w <= W + 0.001 && y + h <= L + 0.001) {
        result.add(RoomModel(nama:r.nama, category:r.category, x:x, y:y, width:w, height:h));
      }
    }
    return result;
  }

  static bool _isHidden(String name) {
    final n = name.toLowerCase();
    return n.contains('koridor') || n.contains('sirkulasi') || n.contains('inner court');
  }

  static double _safe(double v, double fallback) =>
      (v.isNaN || v.isInfinite || v <= 0) ? fallback : v;

  static double _clamp(double v, double mn, double mx) {
    if (mx < mn) return mn;
    return v.clamp(mn, mx).toDouble();
  }

  /// Pilih nilai dari list berdasarkan index variant
  static double _pick(int v, List<double> options) =>
      options[v.clamp(0, options.length - 1)];
}