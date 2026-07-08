class RoomModel {
  String nama;
  double x;
  double y;
  double width;
  double height;
  
String category;
String doorSide;
bool isOutdoor;
double rotation;

  RoomModel({
    required this.nama,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
   this.category = 'room',
    this.doorSide = 'bottom',
    this.isOutdoor = false,
    this.rotation = 0,
  });

  double get area => width * height;

  RoomModel copyWith({
  String? nama,
  double? x,
  double? y,
  double? width,
  double? height,
  String? category,
  String? doorSide,
  bool? isOutdoor,
  double? rotation,
}){
    return RoomModel(
  nama: nama ?? this.nama,
  x: x ?? this.x,
  y: y ?? this.y,
  width: width ?? this.width,
  height: height ?? this.height,
  category: category ?? this.category,
  doorSide: doorSide ?? this.doorSide,
  isOutdoor: isOutdoor ?? this.isOutdoor,
  rotation: rotation ?? this.rotation,
);
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      nama: json['nama'] ?? json['name'] ?? 'Ruang',
      x: _toDouble(json['x']),
      y: _toDouble(json['y']),
      width: _toDouble(json['width']),
      height: _toDouble(json['height']),
      category: json['category'] ?? 'room',
      doorSide: json['doorSide'] ?? json['door_side'] ?? 'bottom',
      isOutdoor: json['isOutdoor'] ?? json['is_outdoor'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nama,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'category': category,
      'door_side': doorSide,
      'is_outdoor': isOutdoor,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }
}