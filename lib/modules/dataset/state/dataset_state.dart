import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/dataset_repository.dart';
import '../models/models.dart';

class DatasetState extends ChangeNotifier {
  final DatasetRepository repository;

  DatasetState({required this.repository});

  List<EquipmentNode> nodes = [];
  List<UtilityLog> currentLogs = [];
  bool isLoading = false;
  EquipmentNode? selectedNode;

  Map<String, double> stateWaterSupply = {};
  Map<String, double> stateWaterConsumption = {};
  Map<String, double> stateElectricitySupply = {};
  Map<String, double> stateElectricityConsumption = {};

  Future<void> loadNodes() async {
    isLoading = true;
    notifyListeners();

    try {
      nodes = await repository.fetchNodes();
      if (stateWaterSupply.isEmpty) {
        await loadAggregatedStateData();
      }
    } catch (e) {
      debugPrint('Error loading nodes: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addOrUpdateNode(EquipmentNode node) async {
    await repository.upsertNode(node);
    await loadNodes();
  }

  Future<void> deleteNode(String nodeId) async {
    await repository.deleteNode(nodeId);
    await loadNodes();
  }

  Future<void> selectNode(EquipmentNode node) async {
    selectedNode = node;
    isLoading = true;
    notifyListeners();

    try {
      if (node.nodeId != null) {
        currentLogs = await repository.fetchLogsForNode(node.nodeId!);
        if (currentLogs.isEmpty) {
          await _loadHistoricalDataFromCSV(node);
          currentLogs = await repository.fetchLogsForNode(node.nodeId!);
        }
      }
    } catch (e) {
      debugPrint('Error loading logs: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadHistoricalDataFromCSV(EquipmentNode node) async {
    final isWater = node.utilityType == 'Water';
    final assetPath = isWater 
        ? 'assets/water_consumption.csv' 
        : 'assets/electricity_consumption.csv';
    
    try {
      final csvString = await rootBundle.loadString(assetPath);
      final lines = csvString.split('\n');
      
      int stateIdx = 0;
      int dateIdx = isWater ? 2 : 1;
      int valIdx = 3;

      final matchingLines = lines.skip(1).where((l) {
        final p = l.split(',');
        return p.length > valIdx && p[stateIdx] == node.zoneId;
      }).toList();
      
      // Grab up to 30 recent data points to form baseline
      final recentLines = matchingLines.length > 30 ? matchingLines.sublist(matchingLines.length - 30) : matchingLines;
      
      for (var line in recentLines) {
        final parts = line.split(',');
        final val = double.tryParse(parts[valIdx]) ?? 0.0;
        final timestamp = DateTime.tryParse(parts[dateIdx]) ?? DateTime.now();
        repository.insertHistoricalLog(node.nodeId!, val, timestamp);
      }
    } catch(e) {
      debugPrint('Failed to load CSV: $e');
    }
  }

  Future<void> loadAggregatedStateData() async {
    try {
      // 1. Load Water Supply (Production)
      final waterSupplyStr = await rootBundle.loadString('assets/water_production.csv');
      final waterSupplyLines = waterSupplyStr.split('\n');
      for (var line in waterSupplyLines.skip(1)) {
        final p = line.split(',');
        if (p.length >= 3 && p[0] != 'Malaysia' && p[0].trim().isNotEmpty) {
          final state = p[0].trim();
          final val = double.tryParse(p[2]) ?? 0.0;
          stateWaterSupply[state] = (stateWaterSupply[state] ?? 0.0) + val;
        }
      }

      // 2. Load Water Consumption
      final waterConStr = await rootBundle.loadString('assets/water_consumption.csv');
      final waterConLines = waterConStr.split('\n');
      for (var line in waterConLines.skip(1)) {
        final p = line.split(',');
        if (p.length >= 4 && p[0] != 'Malaysia' && p[0].trim().isNotEmpty) {
          final state = p[0].trim();
          final val = double.tryParse(p[3]) ?? 0.0;
          stateWaterConsumption[state] = (stateWaterConsumption[state] ?? 0.0) + val;
        }
      }

      // 3. Load Electricity Supply
      final elecSupplyStr = await rootBundle.loadString('assets/electricity_supply.csv');
      final elecSupplyLines = elecSupplyStr.split('\n');
      for (var line in elecSupplyLines.skip(1)) {
        final p = line.split(',');
        if (p.length >= 4 && p[0] != 'Malaysia' && p[0].trim().isNotEmpty) {
          final state = p[0].trim();
          final val = double.tryParse(p[3]) ?? 0.0;
          stateElectricitySupply[state] = (stateElectricitySupply[state] ?? 0.0) + val;
        }
      }

      // 4. Load Electricity Consumption
      final elecConStr = await rootBundle.loadString('assets/electricity_consumption.csv');
      final elecConLines = elecConStr.split('\n');
      for (var line in elecConLines.skip(1)) {
        final p = line.split(',');
        if (p.length >= 4 && p[0] != 'Malaysia' && p[0].trim().isNotEmpty) {
          final state = p[0].trim();
          final val = double.tryParse(p[3]) ?? 0.0;
          stateElectricityConsumption[state] = (stateElectricityConsumption[state] ?? 0.0) + val;
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading aggregated data: $e');
    }
  }

  /// Hidden function to generate fake data for demo
  Future<void> generateFakeDataForSelectedNode() async {
    if (selectedNode == null || selectedNode!.nodeId == null) return;
    
    isLoading = true;
    notifyListeners();
    
    final nodeId = selectedNode!.nodeId!;
    final random = Random();

    try {
      if (currentLogs.isEmpty) {
        // Fallback if CSV failed
        for (int i = 0; i < 30; i++) {
          final value = 90.0 + random.nextDouble() * 20.0;
          await repository.insertLogAndAnalyze(nodeId, value, selectedNode!);
        }
      }

      // Inject final data point with massive spike
      final baseVal = currentLogs.isNotEmpty ? currentLogs.last.usageValue : 100.0;
      await repository.insertLogAndAnalyze(nodeId, baseVal * 3.5, selectedNode!);

      // Refresh logs
      await selectNode(selectedNode!);
    } catch (e) {
      debugPrint('Error generating fake data: $e');
      isLoading = false;
      notifyListeners();
    }
  }
}
