import 'package:expences_tracker/model/expence_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const int _version = 1;
  static const String _dbName = 'expenses.db';

  static Future<Database> GetDatabase() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) => db.execute(
              'CREATE TABLE expenses(id INTEGER PRIMARY KEY, title TEXT, price REAL, date TEXT, category TEXT)',
            ),
        version: _version);
  }

  static Future<int> addExpense(ExpenceModel expenceModel) async {
    final db = await GetDatabase();
    return await db.insert("expenses", expenceModel.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> deleteExpense(ExpenceModel expenceModel) async {
    final db = await GetDatabase();
    return await db
        .delete("expenses", where: 'id = ?', whereArgs: [expenceModel.id]);
  }

  static Future<List<ExpenceModel>?> getAllExpences() async {
    final db = await GetDatabase();

    final List<Map<String, dynamic>> maps = await db.query("expenses");

    if (maps.isEmpty) {
      return null;
    } else {
      return List.generate(
        maps.length,
        (index) => ExpenceModel.fromJson(
          maps[index],
        ),
      );
    }
  }
}
