import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alert.dart';
import '../models/reading.dart';
import '../models/report.dart';

class LeakageRepository {
  final SupabaseClient _client;

  LeakageRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<int> insertReading(Reading reading) async {
    final row = await _client
        .from('readings')
        .insert(reading.toMap()..remove('id'))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<int> insertAlert(Alert alert) async {
    final row = await _client
        .from('alerts')
        .insert(alert.toMap()..remove('id'))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<List<Alert>> alerts({bool includeDismissed = true}) async {
    var query = _client.from('alerts').select().eq('is_deleted', false);
    if (!includeDismissed) {
      query = query.neq('status', AlertStatus.dismissed);
    }
    final rows = await query.order('detected_at', ascending: false);
    return rows.map((row) => Alert.fromMap(row)).toList();
  }

  Future<Alert?> alertById(int id) async {
    final row =
        await _client.from('alerts').select().eq('id', id).maybeSingle();
    return row == null ? null : Alert.fromMap(row);
  }

  Future<void> updateAlertStatus(int id, String status) async {
    await _client.from('alerts').update({'status': status}).eq('id', id);
  }

  Future<int> insertReport(Report report) async {
    final row = await _client
        .from('reports')
        .insert(report.toMap()..remove('id'))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<Set<String>> nrwAlertStates() async {
    final rows = await _client
        .from('alerts')
        .select('state')
        .eq('alert_type', AlertType.nrwHotspot)
        .eq('is_deleted', false);
    return rows.map((row) => row['state'] as String).toSet();
  }

  Future<List<Report>> reports() async {
    final rows = await _client
        .from('reports')
        .select()
        .eq('is_deleted', false)
        .order('updated_at', ascending: false);
    return rows.map((row) => Report.fromMap(row)).toList();
  }
}
