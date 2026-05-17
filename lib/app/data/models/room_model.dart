class RoomModel {
  final String nama;
  final double width;
  final double height;
  final double x;
  final double y;

  RoomModel({
    required this.nama,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
  });

  RoomModel copyWith({double? width, double? height, double? x, double? y}) {
    return RoomModel(
      nama: nama,
      width: width ?? this.width,
      height: height ?? this.height,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}