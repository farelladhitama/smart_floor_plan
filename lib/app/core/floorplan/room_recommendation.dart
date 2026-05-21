class RoomRecommendation {
  final String name;
  final String category;
  final double width;
  final double height;
  final bool selected;

  const RoomRecommendation({
    required this.name,
    required this.category,
    required this.width,
    required this.height,
    this.selected = true,
  });

  double get area => width * height;

  RoomRecommendation copyWith({
    String? name,
    String? category,
    double? width,
    double? height,
    bool? selected,
  }) {
    return RoomRecommendation(
      name: name ?? this.name,
      category: category ?? this.category,
      width: width ?? this.width,
      height: height ?? this.height,
      selected: selected ?? this.selected,
    );
  }
}