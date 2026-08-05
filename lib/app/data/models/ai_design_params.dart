class AIDesignParams {
  final String style;
  final int familySize;
  final int bedroom;
  final int bathroom;
  final String priority;
  final List<String> extraRooms;
  final int garage;
  final String garden;
  final double? budget;
  final String? orientation;
  final String? roofType;

  AIDesignParams({
    required this.style,
    required this.familySize,
    required this.bedroom,
    required this.bathroom,
    required this.priority,
    required this.extraRooms,
    required this.garage,
    required this.garden,
    this.budget,
    this.orientation,
    this.roofType,
  });

  factory AIDesignParams.fromJson(Map<String, dynamic> json) {
    return AIDesignParams(
      style: json['style'] ?? 'Modern',
      familySize: json['family_size'] ?? 4,
      bedroom: json['bedroom'] ?? 3,
      bathroom: json['bathroom'] ?? 2,
      priority: json['priority'] ?? 'Fungsi',
      extraRooms: List<String>.from(json['extra_rooms'] ?? []),
      garage: json['garage'] ?? 1,
      garden: json['garden'] ?? 'Tidak Ada',
      budget: json['budget']?.toDouble(),
      orientation: json['orientation'],
      roofType: json['roof_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'style': style,
      'family_size': familySize,
      'bedroom': bedroom,
      'bathroom': bathroom,
      'priority': priority,
      'extra_rooms': extraRooms,
      'garage': garage,
      'garden': garden,
      'budget': budget,
      'orientation': orientation,
      'roof_type': roofType,
    };
  }

  // ⭐ TAMBAHKAN METHOD copyWith
  AIDesignParams copyWith({
    String? style,
    int? familySize,
    int? bedroom,
    int? bathroom,
    String? priority,
    List<String>? extraRooms,
    int? garage,
    String? garden,
    double? budget,
    String? orientation,
    String? roofType,
  }) {
    return AIDesignParams(
      style: style ?? this.style,
      familySize: familySize ?? this.familySize,
      bedroom: bedroom ?? this.bedroom,
      bathroom: bathroom ?? this.bathroom,
      priority: priority ?? this.priority,
      extraRooms: extraRooms ?? this.extraRooms,
      garage: garage ?? this.garage,
      garden: garden ?? this.garden,
      budget: budget ?? this.budget,
      orientation: orientation ?? this.orientation,
      roofType: roofType ?? this.roofType,
    );
  }
}