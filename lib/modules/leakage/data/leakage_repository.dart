import '../models/alert.dart';
import '../models/reading.dart';
import '../models/report.dart';
import 'leakage_database.dart';

class LeakageRepository {
  final LeakageDatabase _database;

  LeakageRepository([LeakageDatabase? database])
      : _database = database ?? LeakageDatabase.instance;

  Future<int> insertReading(Reading reading) async {
    final db = await _database.database;
    return db.insert('readings', reading.toMap()..remove('id'));
  }

  Future<int> insertAlert(Alert alert) async {
    final db = await _database.database;
    return db.insert('alerts', alert.toMap()..remove('id'));
  }

  Future<List<Alert>> alerts({bool includeDismissed = true}) async {
    final db = await _database.database;
    final where = includeDismissed
        ? 'is_deleted = 0'
        : 'is_deleted = 0 AND status != ?';
    final args = includeDismissed ? null : [AlertStatus.dismissed];
    final rows = await db.query('alerts',
        where: where, whereArgs: args, orderBy: 'detected_at DESC');
    return rows.map(Alert.fromMap).toList();
  }

  Future<Alert?> alertById(int id) async {
    final db = await _database.database;
    final rows = await db.query('alerts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Alert.fromMap(rows.first);
  }

  Future<void> updateAlertStatus(int id, String status) async {
    final db = await _database.database;
    await db.update('alerts', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> dismissAlert(int id) async {
    final db = await _database.database;
    await db.update('alerts', {'status': AlertStatus.dismissed, 'is_deleted': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertReport(Report report) async {
    final db = await _database.database;
    return db.insert('reports', report.toMap()..remove('id'));
  }

  Future<void> updateReport(Report report) async {
    final db = await _database.database;
    await db.update('reports', report.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [report.id]);
  }

  Future<void> deleteReport(int id) async {
    final db = await _database.database;
    await db.update('reports', {'is_deleted': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<Set<String>> nrwAlertStates() async {
    final db = await _database.database;
    final rows = await db.query('alerts',
        columns: ['state'],
        where: 'alert_type = ? AND is_deleted = 0',
        whereArgs: [AlertType.nrwHotspot]);
    return rows.map((r) => r['state'] as String).toSet();
  }

  Future<List<Report>> reports() async {
    final db = await _database.database;
    final rows = await db.query('reports',
        where: 'is_deleted = 0', orderBy: 'updated_at DESC');
    return rows.map(Report.fromMap).toList();
  }

  Future<Report?> reportForAlert(int alertId) async {
    final db = await _database.database;
    final rows = await db.query('reports',
        where: 'alert_id = ? AND is_deleted = 0',
        whereArgs: [alertId],
        orderBy: 'updated_at DESC',
        limit: 1);
    if (rows.isEmpty) return null;
    return Report.fromMap(rows.first);
  }
}
