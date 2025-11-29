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

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      categoryId: map['category_id'] as int?,
      walletId: map['wallet_id'] as int?,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'amount': amount,
      'date': date,
      'category_id': categoryId,
      'wallet_id': walletId,
      'description': description,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  TransactionModel copyWith({
    int? id,
    double? amount,
    String? date,
    int? categoryId,
    int? walletId,
    String? description,
    String? createdAt,
    String? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
