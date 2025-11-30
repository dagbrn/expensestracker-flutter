import '../db/db_instance.dart';
import '../models/category.dart';


class CategoryRepository {
Future<int> insert(CategoryModel category) async {
final db = await DatabaseInstance.instance.database;
return db.insert('categories', category.toMap());
}


Future<List<Map<String, dynamic>>> getAll() async {
final db = await DatabaseInstance.instance.database;
return db.query('categories');
}


Future<List<Map<String, dynamic>>> getByType(String type) async {
final db = await DatabaseInstance.instance.database;
return db.query('categories', where: 'type = ?', whereArgs: [type]);
}
}