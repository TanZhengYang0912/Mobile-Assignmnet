import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../models/alert.dart';
import 'nrw_service.dart' show NrwResult;

/// Per-state electricity supply-vs-consumption analysis — the electricity
/// mirror of [NrwService]. Flags states where supply exceeds consumption
/// by a loss % above the national average (unaccounted-for / lost energy).
class ElectricityLossService {
  static const _supplyAsset = 'assets/electricity_supply.csv';
  static const _consumptionAsset = 'assets/electricity_consumption.csv';

  static const double _highThreshold = 40;
  static const double _mediumThreshold = 25;

  final Map<String, Map<int, double>> _supply = {};
  final Map<String, Map<int, double>> _consumption = {};
  double _nationalLossPct = 0;

  double get nationalLossPct => _nationalLossPct;

  Future<void> load() async {
    await _accumulate(_supplyAsset, _supply);
    await _accumulate(_consumptionAsset, _consumption);
    _nationalLossPct = _computeNationalLossPct();
  }

  Future<void> _accumulate(
      String asset, Map<String, Map<int, double>> into) async {
    final raw = await rootBundle.loadString(asset);
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 4) continue;
      final state = row[0].toString().trim();
      final sector = row[2].toString().trim();
      if (sector != 'total') continue;
      final year = DateTime.parse(row[1].toString().trim()).year;
      final value = (row[3] as num).toDouble();
      into.putIfAbsent(state, () => {});
      into[state]![year] = (into[state]![year] ?? 0) + value;
    }
  }

  int? _latestSharedYear(String state) {
    final sup = _supply[state];
    final con = _consumption[state];
    if (sup == null || con == null) return null;
    final shared = sup.keys.where(con.containsKey);
    if (shared.isEmpty) return null;
    return shared.reduce((a, b) => a > b ? a : b);
  }

  double _computeNationalLossPct() {
    // National figure: sum every state's supply and consumption for the
    // most recent year they share, then (supply - consumption) / supply.
    var totalSupply = 0.0;
    var totalConsumption = 0.0;
    for (final state in _supply.keys) {
      final year = _latestSharedYear(state);
      if (year == null) continue;
      totalSupply += _supply[state]![year]!;
      totalConsumption += _consumption[state]![year]!;
    }
    if (totalSupply == 0) return 0;
    return (totalSupply - totalConsumption) / totalSupply * 100;
  }

  String _severity(double lossPct) {
    if (lossPct > _highThreshold) return Severity.high;
    if (lossPct > _mediumThreshold) return Severity.medium;
    return Severity.low;
  }

  List<NrwResult> analyse() {
    final results = <NrwResult>[];
    for (final state in _supply.keys) {
      final year = _latestSharedYear(state);
      if (year == null) continue;
      final supply = _supply[state]![year]!;
      final consumption = _consumption[state]![year]!;
      if (supply <= 0) continue;
      final loss = supply - consumption;
      final lossPct = loss / supply * 100;
      if (lossPct <= _nationalLossPct) continue;
      results.add(NrwResult(
        state: state,
        year: year,
        producedMld: supply,
        billedMld: consumption,
        lossMld: loss,
        lossPct: lossPct,
        severity: _severity(lossPct),
      ));
    }
    results.sort((a, b) => b.lossPct.compareTo(a.lossPct));
    return results;
  }
}
