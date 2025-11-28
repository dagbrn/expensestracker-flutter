class CategoryModel {
  final int? id;
  final String name;
  final String type; // income / expense
  final String? icon;
  final String? color;
  final String? createdAt;
  final String? updatedAt;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'icon': icon,
    'color': color,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

