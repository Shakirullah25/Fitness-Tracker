import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitness_tracker.db');
    print("Database path: $path");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fitness_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        steps INTEGER,
        caloriesBurned REAL,
        heartRate INTEGER,
        timestamp TEXT
      )
    ''');
  }

  Future<void> insertFitnessData(
      int steps, double caloriesBurned, int heartRate) async {
    final db = await database;
    await db.insert(
      'fitness_data',
      {
        'steps': steps,
        'caloriesBurned': caloriesBurned,
        'heartRate': heartRate,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print(
      "Data saved to database: steps = $steps, caloriesBurned = $caloriesBurned, heartRate = $heartRate",
    );
  }

  Future<List<Map<String, dynamic>>> getFitnessData() async {
    final db = await database;
    final data = await db.query('fitness_data');
    print("Data fetched from database: $data");
    return data;
  }
}


