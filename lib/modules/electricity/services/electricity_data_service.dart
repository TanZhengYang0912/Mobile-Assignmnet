import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../../dataset/services/anomaly_detector.dart';
import '../models/electricity_models.dart';

class ElectricityDataService {
  Future<List<ElectricityRecord>> loadRecords() async {
    final supplyCsv = await rootBundle.loadString('assets/electricity_supply.csv');
    final consumptionCsv = await rootBundle.loadString('assets/electricity_consumption.csv');

    const converter = CsvToListConverter(eol: '\n');
    final supplyRows = converter.convert(supplyCsv);
    final consumptionRows = converter.convert(consumptionCsv);

    final supplyMap = <String, double>{};
    for (int i = 1; i < supplyRows.length; i++) {
      if (supplyRows[i].length >= 4 && supplyRows[i][2].toString().toLowerCase() == 'total') {
        final dateStr = supplyRows[i][1].toString();
        final value = double.tryParse(supplyRows[i][3].toString()) ?? 0.0;
        supplyMap[dateStr] = (supplyMap[dateStr] ?? 0.0) + value;
      }
    }

    final consumptionTotalMap = <String, double>{};
    final lossesMap = <String, double>{};
    
    for (int i = 1; i < consumptionRows.length; i++) {
      if (consumptionRows[i].length >= 4) {
        final dateStr = consumptionRows[i][1].toString();
        final sector = consumptionRows[i][2].toString().toLowerCase();
        final value = double.tryParse(consumptionRows[i][3].toString()) ?? 0.0;
        
        if (sector == 'total') {
          consumptionTotalMap[dateStr] = (consumptionTotalMap[dateStr] ?? 0.0) + value;
        }
        if (sector == 'losses') {
          lossesMap[dateStr] = (lossesMap[dateStr] ?? 0.0) + value;
        }
      }
    }

    // Combine and Sort
    final dates = consumptionTotalMap.keys.toList()..sort();
    
    final records = <ElectricityRecord>[];
    final historicalLosses = <double>[];

    for (final dateStr in dates) {
      final supply = supplyMap[dateStr] ?? 0.0;
      final consumption = consumptionTotalMap[dateStr] ?? 0.0;
      final losses = lossesMap[dateStr] ?? 0.0;

      final zScore = AnomalyDetector.calculateZScore(losses, historicalLosses);
      final isAnomaly = AnomalyDetector.isAnomaly(zScore, threshold: 2.5);

      records.add(
        ElectricityRecord(
          date: DateTime.parse(dateStr),
          supply: supply,
          consumption: consumption,
          losses: losses,
          isAnomaly: isAnomaly,
        ),
      );

      // Add to history for next iteration's Z-score calculation
      historicalLosses.add(losses);
    }

    return records;
  }
}
