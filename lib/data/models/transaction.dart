class TransactionModel {
  final int? id;
  final double amount;
  final String date;
  final int? categoryId;
  final int? walletId;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  TransactionModel({
    this.id,
    required this.amount,
    required this.date,
    this.categoryId,
    this.walletId,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date,
    'category_id': categoryId,
    'wallet_id': walletId,
    'description': description,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
