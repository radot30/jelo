import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  String generateRandomUniqueId() {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return 'USR-$number';
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gamified_city.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL DEFAULT 0';

    await db.execute('''
CREATE TABLE badges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  place_id $textType,
  name $textType,
  type $textType,
  lat $doubleType,
  lon $doubleType,
  claim_date $textType
)
''');

    await db.execute('''
CREATE TABLE user_profile (
  id TEXT PRIMARY KEY,
  unique_id $textType,
  name $textType,
  avatar $textType,
  bio TEXT,
  email TEXT,
  is_private $intType,
  lat $doubleType,
  lon $doubleType
)
''');

    await _seedDefaultProfile(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS user_profile (
  id TEXT PRIMARY KEY,
  unique_id TEXT NOT NULL,
  name TEXT NOT NULL,
  avatar TEXT NOT NULL,
  bio TEXT,
  is_private INTEGER NOT NULL DEFAULT 0,
  lat REAL NOT NULL,
  lon REAL NOT NULL
)
''');
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN email TEXT');
      } catch (_) {
        // Kolom sudah ada
      }
      await db.execute('DROP TABLE IF EXISTS friendships');
    }

    await _seedDefaultProfile(db);
  }

  Future<void> _seedDefaultProfile(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM user_profile'),
    );
    if (count == 0) {
      await db.insert('user_profile', {
        'id': 'my_user_id',
        'unique_id': generateRandomUniqueId(),
        'name': 'Petualang Kota',
        'avatar': 'avatar1',
        'bio': 'Suka menjelajah tempat nongkrong & wisata unik.',
        'email': null,
        'is_private': 0,
        'lat': AppConstants.defaultLat,
        'lon': AppConstants.defaultLon,
      });
    }
  }
}
