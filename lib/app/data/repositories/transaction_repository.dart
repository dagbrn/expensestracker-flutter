import '../db/db_instance.dart';
import '../models/transaction.dart';

class TransactionRepository {
  Future<int> insert(TransactionModel tx) async {
    final db = await DatabaseInstance.instance.database;
    return db.insert('transactions', tx.toMap());
  }

  Future<int> update(TransactionModel tx) async {
    final db = await DatabaseInstance.instance.database;
    return db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseInstance.instance.database;
    return db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseInstance.instance.database;
    return db.query('transactions', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getByType(String type) async {
    final db = await DatabaseInstance.instance.database;
    return db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getByCategory(int categoryId) async {
    final db = await DatabaseInstance.instance.database;
    return db.query(
      'transactions',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseInstance.instance.database;
    return db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await DatabaseInstance.instance.database;
    final results = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
