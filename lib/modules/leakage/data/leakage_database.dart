import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LeakageDatabase {
  LeakageDatabase._();
  static final LeakageDatabase instance = LeakageDatabase._();

  static const _fileName = 'leakage.db';
  static const _version = 2;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _fileName);
    return openDatabase(path,
        version: _version, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS reports');
    await db.execute('DROP TABLE IF EXISTS alerts');
    await db.execute('DROP TABLE IF EXISTS readings');
    await _onCreate(db, newVersion);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        household_id TEXT NOT NULL,
        state TEXT NOT NULL,
        household_size INTEGER NOT NULL,
        reading_date TEXT NOT NULL,
        day_flow_l REAL NOT NULL,
        night_flow_l REAL NOT NULL,
        scenario TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reading_id INTEGER,
        alert_type TEXT NOT NULL,
        household_id TEXT,
        state TEXT NOT NULL,
        detected_at TEXT NOT NULL,
        signature TEXT NOT NULL,
        severity TEXT NOT NULL,
        baseline_l REAL NOT NULL DEFAULT 0,
        actual_l REAL NOT NULL DEFAULT 0,
        explanation TEXT NOT NULL,
        status TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        produced_mld REAL,
        billed_mld REAL,
        loss_mld REAL,
        loss_pct REAL,
        data_year INTEGER,
        FOREIGN KEY (reading_id) REFERENCES readings (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alert_id INTEGER NOT NULL,
        worker_name TEXT NOT NULL,
        findings TEXT NOT NULL,
        action_taken TEXT NOT NULL,
        outcome TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (alert_id) REFERENCES alerts (id)
      )
    ''');
  }
}
