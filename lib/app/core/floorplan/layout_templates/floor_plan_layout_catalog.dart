import 'package:smart_floor_plan/app/core/floorplan/layout_templates/floor_plan_template.dart';

class FloorPlanLayoutCatalog {
  static LayoutSlot _slot(
    String nama,
    String category,
    String doorSide,
    double x,
    double y,
    double width,
    double height, {
    bool outdoor = false,
  }) {
    return LayoutSlot(
      nama: nama,
      category: category,
      doorSide: doorSide,
      x: x,
      y: y,
      width: width,
      height: height,
      isOutdoor: outdoor,
    );
  }

  static LandShape detectShape({
    required double landWidth,
    required double landLength,
  }) {
    final double ratio = landWidth / landLength;

    if (ratio < 0.80) {
      return LandShape.portrait;
    }

    if (ratio > 1.20) {
      return LandShape.landscape;
    }

    return LandShape.balanced;
  }

  static LandSizeClass detectSizeClass(double area) {
    if (area < 70) {
      return LandSizeClass.compact;
    }

    if (area < 120) {
      return LandSizeClass.medium;
    }

    if (area < 180) {
      return LandSizeClass.family;
    }

    return LandSizeClass.premium;
  }

  static FloorPlanTemplate select({
    required double landWidth,
    required double landLength,
  }) {
    final LandShape shape = detectShape(
      landWidth: landWidth,
      landLength: landLength,
    );

    final LandSizeClass sizeClass = detectSizeClass(
      landWidth * landLength,
    );

    if (sizeClass == LandSizeClass.compact) {
      if (shape == LandShape.portrait) return compactPortrait;
      if (shape == LandShape.landscape) return compactLandscape;
      return compactBalanced;
    }

    if (sizeClass == LandSizeClass.medium) {
      if (shape == LandShape.portrait) return mediumPortrait;
      if (shape == LandShape.landscape) return mediumLandscape;
      return mediumBalanced;
    }

    if (sizeClass == LandSizeClass.family) {
      if (shape == LandShape.portrait) return familyPortrait;
      if (shape == LandShape.landscape) return familyLandscape;
      return familyBalanced;
    }

    if (shape == LandShape.portrait) return premiumPortrait;
    if (shape == LandShape.landscape) return premiumLandscape;
    return premiumBalanced;
  }

  static List<FloorPlanTemplate> alternatives({
    required double landWidth,
    required double landLength,
  }) {
    final LandSizeClass sizeClass = detectSizeClass(
      landWidth * landLength,
    );

    switch (sizeClass) {
      case LandSizeClass.compact:
        return [
          compactPortrait,
          compactBalanced,
          compactLandscape,
        ];
      case LandSizeClass.medium:
        return [
          mediumPortrait,
          mediumBalanced,
          mediumLandscape,
        ];
      case LandSizeClass.family:
        return [
          familyPortrait,
          familyBalanced,
          familyLandscape,
        ];
      case LandSizeClass.premium:
        return [
          premiumPortrait,
          premiumBalanced,
          premiumLandscape,
        ];
    }
  }

  // ================================================================
  // COMPACT - luas di bawah 70 m²
  // ================================================================

  static final FloorPlanTemplate compactPortrait = FloorPlanTemplate(
    id: 'compact_portrait',
    name: 'Compact Linear',
    description: 'Rumah kecil memanjang dengan fungsi inti tersusun vertikal.',
    shape: LandShape.portrait,
    sizeClass: LandSizeClass.compact,
    slots: [
      _slot('Dapur', 'kitchen', 'bottom', 0.00, 0.00, 0.62, 0.21),
      _slot('KM/WC', 'bath', 'bottom', 0.62, 0.00, 0.38, 0.21),
      _slot('K. Tidur', 'bedroom', 'bottom', 0.00, 0.21, 1.00, 0.31),
      _slot('Ruang Tamu', 'living', 'bottom', 0.00, 0.52, 1.00, 0.35),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.20,
        0.87,
        0.60,
        0.13,
        outdoor: true,
      ),
    ],
  );

  static final FloorPlanTemplate compactBalanced = FloorPlanTemplate(
    id: 'compact_balanced',
    name: 'Compact Couple House',
    description: 'Rumah compact seimbang untuk satu kamar tidur.',
    shape: LandShape.balanced,
    sizeClass: LandSizeClass.compact,
    slots: [
      _slot('Dapur', 'kitchen', 'right', 0.00, 0.00, 0.43, 0.28),
      _slot('KM/WC', 'bath', 'bottom', 0.43, 0.00, 0.23, 0.28),
      _slot('K. Tidur', 'bedroom', 'left', 0.66, 0.00, 0.34, 0.55),
      _slot('Ruang Tamu', 'living', 'bottom', 0.00, 0.28, 0.66, 0.56),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.16,
        0.84,
        0.50,
        0.16,
        outdoor: true,
      ),
    ],
  );

  static final FloorPlanTemplate compactLandscape = FloorPlanTemplate(
    id: 'compact_landscape',
    name: 'Compact Horizontal',
    description: 'Rumah kecil melebar dengan kamar berada di sisi rumah.',
    shape: LandShape.landscape,
    sizeClass: LandSizeClass.compact,
    slots: [
      _slot('Dapur', 'kitchen', 'bottom', 0.00, 0.00, 0.30, 0.42),
      _slot('KM/WC', 'bath', 'bottom', 0.30, 0.00, 0.18, 0.42),
      _slot('K. Tidur', 'bedroom', 'left', 0.48, 0.00, 0.52, 0.62),
      _slot('Ruang Tamu', 'living', 'bottom', 0.00, 0.42, 0.48, 0.42),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.08,
        0.84,
        0.40,
        0.16,
        outdoor: true,
      ),
    ],
  );

  // ================================================================
  // MEDIUM - luas 70 sampai 119 m²
  // ================================================================

  static final FloorPlanTemplate mediumPortrait = FloorPlanTemplate(
    id: 'medium_portrait',
    name: 'Family Corridor',
    description: 'Rumah dua kamar memanjang dengan ruang keluarga pusat.',
    shape: LandShape.portrait,
    sizeClass: LandSizeClass.medium,
    slots: [
      _slot('Dapur', 'kitchen', 'right', 0.00, 0.00, 0.56, 0.18),
      _slot('KM/WC', 'bath', 'bottom', 0.56, 0.00, 0.44, 0.18),
      _slot('K. Tidur Utama', 'bedroom', 'right', 0.00, 0.18, 0.48, 0.25),
      _slot('K. Tidur 1', 'bedroom', 'left', 0.52, 0.18, 0.48, 0.25),
      _slot('R. Keluarga', 'family', 'bottom', 0.00, 0.43, 1.00, 0.21),
      _slot('Ruang Tamu', 'living', 'bottom', 0.00, 0.64, 1.00, 0.24),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.20,
        0.88,
        0.60,
        0.12,
        outdoor: true,
      ),
    ],
  );

  static final FloorPlanTemplate mediumBalanced = FloorPlanTemplate(
    id: 'medium_balanced',
    name: 'Minimalis Central Living',
    description: 'Rumah seimbang dengan ruang keluarga sebagai penghubung.',
    shape: LandShape.balanced,
    sizeClass: LandSizeClass.medium,
    slots: [
      _slot('Dapur', 'kitchen', 'right', 0.00, 0.00, 0.34, 0.26),
      _slot('R. Makan', 'dining', 'bottom', 0.34, 0.00, 0.32, 0.26),
      _slot('KM/WC', 'bath', 'bottom', 0.66, 0.00, 0.34, 0.19),
      _slot('K. Tidur Utama', 'bedroom', 'left', 0.66, 0.19, 0.34, 0.35),
      _slot('R. Keluarga', 'family', 'bottom', 0.00, 0.26, 0.66, 0.31),
      _slot('Ruang Tamu', 'living', 'bottom', 0.00, 0.57, 0.58, 0.30),
      _slot('K. Tidur 1', 'bedroom', 'left', 0.58, 0.54, 0.42, 0.33),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.15,
        0.87,
        0.48,
        0.13,
        outdoor: true,
      ),
    ],
  );

  static final FloorPlanTemplate mediumLandscape = FloorPlanTemplate(
    id: 'medium_landscape',
    name: 'Wide Minimalis',
    description: 'Rumah melebar dua kamar dengan taman dan ruang utama lebar.',
    shape: LandShape.landscape,
    sizeClass: LandSizeClass.medium,
    slots: [
      _slot('Dapur', 'kitchen', 'bottom', 0.00, 0.00, 0.25, 0.33),
      _slot('R. Makan', 'dining', 'bottom', 0.25, 0.00, 0.25, 0.33),
      _slot('K. Tidur Utama', 'bedroom', 'bottom', 0.50, 0.00, 0.31, 0.39),
      _slot('KM/WC', 'bath', 'left', 0.81, 0.00, 0.19, 0.39),
      _slot(
        'Taman',
        'outdoor',
        'right',
        0.00,
        0.33,
        0.25,
        0.31,
        outdoor: true,
      ),
      _slot('R. Keluarga', 'family', 'bottom', 0.25, 0.33, 0.36, 0.35),
      _slot('K. Tidur 1', 'bedroom', 'left', 0.61, 0.39, 0.39, 0.45),
      _slot('Ruang Tamu', 'living', 'bottom', 0.25, 0.68, 0.36, 0.16),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.25,
        0.84,
        0.36,
        0.16,
        outdoor: true,
      ),
    ],
  );

  // ================================================================
  // FAMILY - luas 120 sampai 179 m²
  // ================================================================

  static final FloorPlanTemplate familyPortrait = FloorPlanTemplate(
    id: 'family_portrait',
    name: 'Long Family House',
    description: 'Rumah tiga kamar untuk lahan memanjang.',
    shape: LandShape.portrait,
    sizeClass: LandSizeClass.family,
    slots: [
      _slot('Dapur', 'kitchen', 'right', 0.00, 0.00, 0.46, 0.16),
      _slot('R. Makan', 'dining', 'bottom', 0.46, 0.00, 0.54, 0.16),
      _slot('K. Tidur Utama', 'bedroom', 'right', 0.00, 0.16, 0.48, 0.20),
      _slot('KM Utama', 'bath', 'left', 0.48, 0.16, 0.23, 0.20),
      _slot('KM/WC', 'bath', 'left', 0.71, 0.16, 0.29, 0.20),
      _slot('K. Tidur 1', 'bedroom', 'right', 0.00, 0.36, 0.48, 0.20),
      _slot('K. Tidur 2', 'bedroom', 'left', 0.52, 0.36, 0.48, 0.20),
      _slot('R. Keluarga', 'family', 'bottom', 0.00, 0.56, 1.00, 0.16),
      _slot(
        'Carport',
        'outdoor',
        'right',
        0.00,
        0.72,
        0.30,
        0.28,
        outdoor: true,
      ),
      _slot('Ruang Tamu', 'living', 'bottom', 0.30, 0.72, 0.70, 0.17),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.40,
        0.89,
        0.42,
        0.11,
        outdoor: true,
      ),
    ],
  );

  static final FloorPlanTemplate familyBalanced = FloorPlanTemplate(
    id: 'family_balanced',
    name: 'Ideal Family House',
    description: 'Rumah keluarga tiga kamar dengan pusat aktivitas di tengah.',
    shape: LandShape.balanced,
    sizeClass: LandSizeClass.family,
    slots: [
      _slot('Dapur', 'kitchen', 'right', 0.00, 0.00, 0.26, 0.22),
      _slot('R. Makan', 'dining', 'bottom', 0.26, 0.00, 0.25, 0.22),
      _slot('K. Tidur Utama', 'bedroom', 'bottom', 0.51, 0.00, 0.32, 0.22),
      _slot('KM Utama', 'bath', 'left', 0.83, 0.00, 0.17, 0.11),
      _slot('KM/WC', 'bath', 'left', 0.83, 0.11, 0.17, 0.11),
      _slot(
        'Taman',
        'outdoor',
        'right',
        0.00,
        0.22,
        0.26,
        0.24,
        outdoor: true,
      ),
      _slot('R. Keluarga', 'family', 'bottom', 0.26, 0.22, 0.41, 0.27),
      _slot('K. Tidur 2', 'bedroom', 'left', 0.67, 0.22, 0.33, 0.27),
      _slot(
        'Carport',
        'outdoor',
        'right',
        0.00,
        0.46,
        0.26,
        0.54,
        outdoor: true,
      ),
      _slot('Ruang Tamu', 'living', 'bottom', 0.26, 0.49, 0.41, 0.36),
      _slot('K. Tidur 1', 'bedroom', 'left', 0.67, 0.49, 0.33, 0.36),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.26,
        0.85,
        0.41,
        0.15,
        outdoor: true,
      ),
    ],
  );

  static final FloorPlanTemplate familyLandscape = FloorPlanTemplate(
    id: 'family_landscape',
    name: 'Wide Family Spread',
    description: 'Rumah keluarga melebar dengan kamar menyebar ke samping.',
    shape: LandShape.landscape,
    sizeClass: LandSizeClass.family,
    slots: [
      _slot('Dapur', 'kitchen', 'right', 0.00, 0.00, 0.22, 0.28),
      _slot('R. Makan', 'dining', 'bottom', 0.22, 0.00, 0.20, 0.28),
      _slot('R. Keluarga', 'family', 'bottom', 0.42, 0.00, 0.29, 0.38),
      _slot('K. Tidur Utama', 'bedroom', 'bottom', 0.71, 0.00, 0.29, 0.30),
      _slot('KM Utama', 'bath', 'left', 0.86, 0.30, 0.14, 0.17),
      _slot(
        'Taman',
        'outdoor',
        'right',
        0.00,
        0.28,
        0.22,
        0.24,
        outdoor: true,
      ),
      _slot('Ruang Tamu', 'living', 'bottom', 0.22, 0.28, 0.49, 0.35),
      _slot('K. Tidur 2', 'bedroom', 'left', 0.71, 0.47, 0.29, 0.26),
      _slot(
        'Carport',
        'outdoor',
        'right',
        0.00,
        0.52,
        0.22,
        0.48,
        outdoor: true,
      ),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.22,
        0.63,
        0.30,
        0.20,
        outdoor: true,
      ),
      _slot('K. Tidur 1', 'bedroom', 'left', 0.52, 0.63, 0.48, 0.37),
    ],
  );

  // ================================================================
  // PREMIUM - luas mulai 180 m²
  // ================================================================

  static final FloorPlanTemplate premiumPortrait = FloorPlanTemplate(
    id: 'premium_portrait',
    name: 'Premium Long Residence',
    description: 'Rumah besar memanjang dengan zona servis di belakang.',
    shape: LandShape.portrait,
    sizeClass: LandSizeClass.premium,
    slots: [
      _slot('Area Cuci', 'service', 'bottom', 0.00, 0.00, 0.30, 0.12),
      _slot('Dapur', 'kitchen', 'bottom', 0.30, 0.00, 0.34, 0.12),
      _slot('R. Makan', 'dining', 'bottom', 0.64, 0.00, 0.36, 0.12),
      _slot('K. Tidur Utama', 'bedroom', 'right', 0.00, 0.12, 0.64, 0.18),
      _slot('KM Utama', 'bath', 'left', 0.64, 0.12, 0.36, 0.09),
      _slot('KM/WC', 'bath', 'left', 0.64, 0.21, 0.36, 0.09),
      _slot('K. Tidur 1', 'bedroom', 'right', 0.00, 0.30, 0.48, 0.18),
      _slot('K. Tidur 2', 'bedroom', 'left', 0.52, 0.30, 0.48, 0.18),
      _slot('R. Keluarga', 'family', 'bottom', 0.00, 0.48, 1.00, 0.18),
      _slot(
        'Taman',
        'outdoor',
        'right',
        0.00,
        0.66,
        0.28,
        0.18,
        outdoor: true,
      ),
      _slot('Ruang Tamu', 'living', 'bottom', 0.28, 0.66, 0.72, 0.18),
      _slot(
        'Carport',
        'outdoor',
        'right',
        0.00,
        0.84,
        0.42,
        0.16,
        outdoor: true,
      ),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.42,
        0.84,
        0.58,
        0.16,
        outdoor: true,
      ),
    ],
  );

  static final FloorPlanTemplate premiumBalanced = FloorPlanTemplate(
    id: 'premium_balanced',
    name: 'Semi Luxury Courtyard',
    description: 'Rumah luas dengan taman belakang dan ruang tengah lega.',
    shape: LandShape.balanced,
    sizeClass: LandSizeClass.premium,
    slots: [
      _slot(
        'Taman Belakang',
        'outdoor',
        'right',
        0.00,
        0.00,
        0.24,
        0.18,
        outdoor: true,
      ),
      _slot('Dapur', 'kitchen', 'right', 0.00, 0.18, 0.24, 0.22),
      _slot('R. Makan', 'dining', 'bottom', 0.24, 0.00, 0.25, 0.25),
      _slot('K. Tidur Utama', 'bedroom', 'bottom', 0.49, 0.00, 0.34, 0.25),
      _slot('KM Utama', 'bath', 'left', 0.83, 0.00, 0.17, 0.13),
      _slot('KM/WC', 'bath', 'left', 0.83, 0.13, 0.17, 0.12),
      _slot(
        'Taman Depan',
        'outdoor',
        'right',
        0.00,
        0.40,
        0.24,
        0.20,
        outdoor: true,
      ),
      _slot('R. Keluarga', 'family', 'bottom', 0.24, 0.25, 0.43, 0.34),
      _slot('K. Tidur 2', 'bedroom', 'left', 0.67, 0.25, 0.33, 0.34),
      _slot(
        'Carport',
        'outdoor',
        'right',
        0.00,
        0.60,
        0.24,
        0.40,
        outdoor: true,
      ),
      _slot('Ruang Tamu', 'living', 'bottom', 0.24, 0.59, 0.43, 0.27),
      _slot('K. Tidur 1', 'bedroom', 'left', 0.67, 0.59, 0.33, 0.27),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.24,
        0.86,
        0.43,
        0.14,
        outdoor: true,
      ),
    ],
  );

  static final FloorPlanTemplate premiumLandscape = FloorPlanTemplate(
    id: 'premium_landscape',
    name: 'Wide Modern Residence',
    description: 'Rumah modern melebar dengan tata ruang horizontal.',
    shape: LandShape.landscape,
    sizeClass: LandSizeClass.premium,
    slots: [
      _slot(
        'Taman Belakang',
        'outdoor',
        'right',
        0.00,
        0.00,
        0.22,
        0.18,
        outdoor: true,
      ),
      _slot('Dapur', 'kitchen', 'right', 0.00, 0.18, 0.22, 0.22),
      _slot('R. Makan', 'dining', 'bottom', 0.22, 0.00, 0.22, 0.25),
      _slot('R. Keluarga', 'family', 'bottom', 0.44, 0.00, 0.28, 0.38),
      _slot('K. Tidur Utama', 'bedroom', 'bottom', 0.72, 0.00, 0.28, 0.28),
      _slot('KM/WC', 'bath', 'left', 0.72, 0.28, 0.14, 0.15),
      _slot('KM Utama', 'bath', 'left', 0.86, 0.28, 0.14, 0.15),
      _slot(
        'Carport',
        'outdoor',
        'right',
        0.00,
        0.40,
        0.22,
        0.60,
        outdoor: true,
      ),
      _slot('Ruang Tamu', 'living', 'bottom', 0.22, 0.38, 0.40, 0.38),
      _slot('K. Tidur 2', 'bedroom', 'left', 0.62, 0.43, 0.38, 0.27),
      _slot(
        'Teras',
        'outdoor',
        'top',
        0.22,
        0.76,
        0.40,
        0.24,
        outdoor: true,
      ),
      _slot('K. Tidur 1', 'bedroom', 'left', 0.62, 0.70, 0.38, 0.30),
    ],
  );
}