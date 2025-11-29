class WalletModel {
  final int? id;
  final String name;
  final double initialBalance;
  final double currentBalance;
  final String? createdAt;
  final String? updatedAt;

  WalletModel({
    this.id,
    required this.name,
    required this.initialBalance,
    required this.currentBalance,
    this.createdAt,
    this.updatedAt,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      initialBalance: (map['initial_balance'] as num).toDouble(),
      currentBalance: (map['current_balance'] as num).toDouble(),
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  WalletModel copyWith({
    int? id,
    String? name,
    double? initialBalance,
    double? currentBalance,
    String? createdAt,
    String? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
