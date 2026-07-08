class RoomModel {
  final String nama;
  final String category;
  final double width;
  final double height;
  final double x;
  final double y;
  final double rotation;

  const RoomModel({
    required this.nama,
    required this.category,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    this.rotation = 0,
  });

  RoomModel copyWith({
    String? nama,
    String? category,
    double? width,
    double? height,
    double? x,
    double? y,
    double? rotation,
  }) {
    return RoomModel(
      nama: nama ?? this.nama,
      category: category ?? this.category,
      width: width ?? this.width,
      height: height ?? this.height,
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: rotation ?? this.rotation,
    );
  }
}