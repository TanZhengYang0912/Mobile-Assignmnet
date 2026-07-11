import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/utility_entry.dart';

/// CRUD against `customer_utility_entries` — RLS scopes every row to the
/// signed-in user, so no explicit user_id filtering is needed client-side.
class UsageRepository {
  final SupabaseClient _client;

  UsageRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<UtilityEntry>> entriesFor(UtilityType utility) async {
    final rows = await _client
        .from('customer_utility_entries')
        .select()
        .eq('utility', utility.key)
        .order('period_month', ascending: true);
    return rows.map((row) => UtilityEntry.fromMap(row)).toList();
  }

  /// Inserts or overwrites the entry for [utility] in the month of [month].
  Future<UtilityEntry> upsertEntry({
    required UtilityType utility,
    required DateTime month,
    required double value,
  }) async {
    final periodMonth = DateTime(month.year, month.month, 1);
    final row = await _client
        .from('customer_utility_entries')
        .upsert(
          {
            'utility': utility.key,
            'period_month': periodMonth.toIso8601String().split('T').first,
            'value': value,
          },
          onConflict: 'user_id,utility,period_month',
        )
        .select()
        .single();
    return UtilityEntry.fromMap(row);
  }
}
