import '../db/db_instance.dart';
import '../models/wallet.dart';


class WalletRepository {
Future<int> insert(WalletModel wallet) async {
final db = await DatabaseInstance.instance.database;
return db.insert('wallets', wallet.toMap());
}


Future<List<Map<String, dynamic>>> getAll() async {
final db = await DatabaseInstance.instance.database;
return db.query('wallets');
}


Future<int> updateBalance(int walletId, double amount, bool isIncome) async {
final db = await DatabaseInstance.instance.database;
final wallet = await db.query('wallets', where: 'id = ?', whereArgs: [walletId]);
if (wallet.isEmpty) return 0;


final current = wallet.first['current_balance'] as double;
final newBalance = isIncome ? current + amount : current - amount;


return db.update(
'wallets',
{'current_balance': newBalance, 'updated_at': DateTime.now().toIso8601String()},
where: 'id = ?',
whereArgs: [walletId],
);
}
}