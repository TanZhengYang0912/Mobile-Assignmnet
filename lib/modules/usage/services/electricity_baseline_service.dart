import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../../leakage/services/baseline_service.dart' show BaselineService;

/// Per-state average residential electricity usage, mirroring
/// [BaselineService]'s water baseline but sourced from the
/// `local_domestic` sector of the electricity consumption dataset.
class ElectricityBaselineService {
  static const _assetPath = 'assets/electricity_consumption.csv';
  static const _sector = 'local_domestic';

  final Map<String, double> _perCapitaKwhPerDay = {};
  int _latestYear = 0;

  int get latestYear => _latestYear;

  List<String> get states {
    final list = _perCapitaKwhPerDay.keys.toList()..sort();
    return list;
  }

  Future<void> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final rows = const CsvToListConverter(eol: '\n').convert(raw);

    final Map<String, DateTime> latestDateByState = {};
    final Map<String, double> latestValueByState = {};

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 4) continue;
      final state = row[0].toString().trim();
      final sector = row[2].toString().trim();
      if (sector != _sector) continue;
      if (!BaselineService.statePopulation.containsKey(state)) continue;

      final date = DateTime.parse(row[1].toString().trim());
      final value = (row[3] as num).toDouble();

      final currentLatest = latestDateByState[state];
      if (currentLatest == null || date.isAfter(currentLatest)) {
        latestDateByState[state] = date;
        latestValueByState[state] = value;
        if (date.year > _latestYear) _latestYear = date.year;
      }
    }

    latestValueByState.forEach((state, gwhPerMonth) {
      final population = BaselineService.statePopulation[state]!;
      final month = latestDateByState[state]!;
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      final kwhPerDay = (gwhPerMonth * 1000000) / daysInMonth;
      _perCapitaKwhPerDay[state] = kwhPerDay / population;
    });
  }

  double perCapitaKwhPerDay(String state) => _perCapitaKwhPerDay[state] ?? 2.5;

  double expectedHouseholdKwhPerDay(String state, int householdSize) =>
      perCapitaKwhPerDay(state) * householdSize;
}
