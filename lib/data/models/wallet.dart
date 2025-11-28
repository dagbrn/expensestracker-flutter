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

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'initial_balance': initialBalance,
    'current_balance': currentBalance,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
