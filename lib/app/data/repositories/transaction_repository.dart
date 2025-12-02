import '../db/db_instance.dart';
import '../models/transaction.dart';

class TransactionRepository {
  Future<int> insert(TransactionModel tx) async {
    final db = await DatabaseInstance.instance.database;
    return db.insert('transactions', tx.toMap());
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseInstance.instance.database;
    return db.query('transactions', orderBy: 'date DESC');
  }

  Future<int> delete(int id) async {
    final db = await DatabaseInstance.instance.database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
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
}
