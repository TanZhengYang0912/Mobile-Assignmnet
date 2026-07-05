import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../models/alert.dart';

class NrwPoint {
  final int year;
  final double lossPct;
  const NrwPoint(this.year, this.lossPct);
}

class NrwResult {
  final String state;
  final int year;
  final double producedMld;
  final double billedMld;
  final double lossMld;
  final double lossPct;
  final String severity;

  const NrwResult({
    required this.state,
    required this.year,
    required this.producedMld,
    required this.billedMld,
    required this.lossMld,
    required this.lossPct,
    required this.severity,
  });
}

class NrwService {
  static const _productionAsset = 'assets/water_production.csv';
  static const _consumptionAsset = 'assets/water_consumption.csv';

  static const double _highThreshold = 50;
  static const double _mediumThreshold = 40;

  final Map<String, Map<int, double>> _produced = {};
  final Map<String, Map<int, double>> _billed = {};
  double _nationalLossPct = 0;

  double get nationalLossPct => _nationalLossPct;

  Future<void> load() async {
    await _accumulate(_productionAsset, _produced, hasSector: false);
    await _accumulate(_consumptionAsset, _billed, hasSector: true);
    _nationalLossPct = _lossPctFor('Malaysia') ?? 0;
  }

  Future<void> _accumulate(
      String asset, Map<String, Map<int, double>> into,
      {required bool hasSector}) async {
    final raw = await rootBundle.loadString(asset);
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < (hasSector ? 4 : 3)) continue;
      final state = row[0].toString().trim();
      final dateIndex = hasSector ? 2 : 1;
      final valueIndex = hasSector ? 3 : 2;
      final year = DateTime.parse(row[dateIndex].toString().trim()).year;
      final value = (row[valueIndex] as num).toDouble();
      into.putIfAbsent(state, () => {});
      into[state]![year] = (into[state]![year] ?? 0) + value;
    }
  }

  double? _lossPctFor(String state, [int? year]) {
    final prod = _produced[state];
    final bill = _billed[state];
    if (prod == null || bill == null) return null;
    final y = year ?? _latestSharedYear(state);
    if (y == null) return null;
    final p = prod[y];
    final b = bill[y];
    if (p == null || b == null || p == 0) return null;
    return (p - b) / p * 100;
  }

  int? _latestSharedYear(String state) {
    final prod = _produced[state];
    final bill = _billed[state];
    if (prod == null || bill == null) return null;
    final shared = prod.keys.where(bill.containsKey);
    if (shared.isEmpty) return null;
    return shared.reduce((a, b) => a > b ? a : b);
  }

  String _severity(double lossPct) {
    if (lossPct > _highThreshold) return Severity.high;
    if (lossPct > _mediumThreshold) return Severity.medium;
    return Severity.low;
  }

  List<NrwResult> analyse() {
    final results = <NrwResult>[];
    for (final state in _produced.keys) {
      if (state == 'Malaysia') continue;
      final year = _latestSharedYear(state);
      if (year == null) continue;
      final produced = _produced[state]![year]!;
      final billed = _billed[state]?[year];
      if (billed == null) continue;
      final loss = produced - billed;
      final lossPct = loss / produced * 100;
      if (lossPct <= _nationalLossPct) continue;
      results.add(NrwResult(
        state: state,
        year: year,
        producedMld: produced,
        billedMld: billed,
        lossMld: loss,
        lossPct: lossPct,
        severity: _severity(lossPct),
      ));
    }
    results.sort((a, b) => b.lossPct.compareTo(a.lossPct));
    return results;
  }

  List<NrwPoint> trendFor(String state) {
    final prod = _produced[state];
    final bill = _billed[state];
    if (prod == null || bill == null) return [];
    final years = prod.keys.where(bill.containsKey).toList()..sort();
    return years.map((y) {
      final p = prod[y]!;
      final b = bill[y]!;
      return NrwPoint(y, p == 0 ? 0 : (p - b) / p * 100);
    }).toList();
  }
}
