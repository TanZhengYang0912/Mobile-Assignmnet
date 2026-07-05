import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

class BaselineService {
  static const _assetPath = 'assets/water_consumption.csv';

  static const Map<String, int> statePopulation = {
    'Johor': 4030000,
    'Kedah': 2190000,
    'Kelantan': 1920000,
    'Melaka': 1000000,
    'Negeri Sembilan': 1200000,
    'Pahang': 1680000,
    'Perak': 2510000,
    'Perlis': 300000,
    'Pulau Pinang': 1770000,
    'Sabah': 3420000,
    'Sarawak': 2450000,
    'Selangor': 9080000,
    'Terengganu': 1260000,
    'W.P. Labuan': 100000,
  };

  final Map<String, double> _perCapitaLPerDay = {};
  int _latestYear = 0;

  int get latestYear => _latestYear;
  List<String> get states {
    final list = _perCapitaLPerDay.keys.toList()..sort();
    return list;
  }

  Future<void> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final rows = const CsvToListConverter(eol: '\n').convert(raw);

    final Map<String, int> latestYearByState = {};
    final Map<String, double> latestMldByState = {};

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 4) continue;
      final state = row[0].toString().trim();
      final sector = row[1].toString().trim();
      if (sector != 'domestic') continue;
      if (!statePopulation.containsKey(state)) continue;

      final year = DateTime.parse(row[2].toString().trim()).year;
      final mld = (row[3] as num).toDouble();

      if (year > (latestYearByState[state] ?? 0)) {
        latestYearByState[state] = year;
        latestMldByState[state] = mld;
        if (year > _latestYear) _latestYear = year;
      }
    }

    latestMldByState.forEach((state, mld) {
      final population = statePopulation[state]!;
      _perCapitaLPerDay[state] = (mld * 1000000) / population;
    });
  }

  double perCapitaLPerDay(String state) => _perCapitaLPerDay[state] ?? 226;

  double expectedHouseholdLPerDay(String state, int householdSize) =>
      perCapitaLPerDay(state) * householdSize;
}
