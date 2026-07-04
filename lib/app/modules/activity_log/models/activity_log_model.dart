class ActivityLogModel {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final String icon;
  final DateTime createdAt;

  ActivityLogModel({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.icon,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'],
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'history',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ActivityLogModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? icon,
    DateTime? createdAt,
  }) {
    return ActivityLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}