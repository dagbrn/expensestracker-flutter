import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseInstance {
  static final DatabaseInstance instance = DatabaseInstance._init();
  static Database? _db;

  DatabaseInstance._init();

  final String dbName = 'expense_tracker.db';
  final int dbVersion = 1;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(path, version: dbVersion, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
      icon TEXT,
      color TEXT,
      created_at TEXT,
      updated_at TEXT
      )
      ''');
          
    await db.execute('''
      CREATE TABLE wallets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      initial_balance REAL NOT NULL DEFAULT 0,
      current_balance REAL NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      category_id INTEGER,
      wallet_id INTEGER,
      description TEXT,
      created_at TEXT,
      updated_at TEXT,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
      FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE CASCADE
      )
      ''');

    // Insert seed data
    await _insertSeedData(db);
  }

  Future<void> _insertSeedData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Seed expense categories
    final expenseCategories = [
      {'name': 'Makanan & Minuman', 'type': 'expense', 'icon': '🍔', 'color': 'FF5722', 'created_at': now},
      {'name': 'Transportasi', 'type': 'expense', 'icon': '🚗', 'color': '2196F3', 'created_at': now},
      {'name': 'Belanja', 'type': 'expense', 'icon': '🛒', 'color': '4CAF50', 'created_at': now},
      {'name': 'Tagihan & Utilitas', 'type': 'expense', 'icon': '💳', 'color': 'FFC107', 'created_at': now},
      {'name': 'Hiburan', 'type': 'expense', 'icon': '🎬', 'color': '9C27B0', 'created_at': now},
      {'name': 'Kesehatan', 'type': 'expense', 'icon': '🏥', 'color': 'E91E63', 'created_at': now},
      {'name': 'Pendidikan', 'type': 'expense', 'icon': '📚', 'color': '00BCD4', 'created_at': now},
      {'name': 'Olahraga', 'type': 'expense', 'icon': '⚽', 'color': '8BC34A', 'created_at': now},
      {'name': 'Lainnya', 'type': 'expense', 'icon': '📦', 'color': '607D8B', 'created_at': now},
    ];

    // Seed income categories
    final incomeCategories = [
      {'name': 'Gaji', 'type': 'income', 'icon': '💰', 'color': '4CAF50', 'created_at': now},
      {'name': 'Bonus', 'type': 'income', 'icon': '🎁', 'color': '8BC34A', 'created_at': now},
      {'name': 'Investasi', 'type': 'income', 'icon': '📈', 'color': '009688', 'created_at': now},
      {'name': 'Freelance', 'type': 'income', 'icon': '💼', 'color': '00BCD4', 'created_at': now},
      {'name': 'Lainnya', 'type': 'income', 'icon': '💵', 'color': '4DD0E1', 'created_at': now},
    ];

    for (var category in expenseCategories) {
      await db.insert('categories', category);
    }
    for (var category in incomeCategories) {
      await db.insert('categories', category);
    }

    // Seed default wallet
    await db.insert('wallets', {
      'name': 'Dompet Utama',
      'initial_balance': 0.0,
      'current_balance': 0.0,
      'created_at': now,
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
