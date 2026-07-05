import 'package:uuid/uuid.dart';

import '../../leakage/models/alert.dart';
import '../../leakage/data/leakage_repository.dart';
import '../models/models.dart';
import '../services/anomaly_detector.dart';

class DatasetRepository {
  final Uuid _uuid = const Uuid();
  final LeakageRepository? _leakageRepo;

  DatasetRepository({LeakageRepository? leakageRepo}) : _leakageRepo = leakageRepo;

  // In-memory storage for local testing
  static final List<EquipmentNode> _nodes = [
    EquipmentNode(
      nodeId: const Uuid().v4(),
      nodeName: 'Main Water Pump A1',
      utilityType: 'Water',
      zoneId: 'Selangor',
      status: 'Active',
      createdAt: DateTime.now().subtract(const Duration(days: 300)),
      manufacturer: 'Grundfos',
      installationDate: DateTime.now().subtract(const Duration(days: 365)),
      lastMaintenanceDate: DateTime.now().subtract(const Duration(days: 15)),
      healthScore: 98,
      firmwareVersion: 'v2.4.1',
      ipAddress: '192.168.1.10',
    ),
    EquipmentNode(
      nodeId: const Uuid().v4(),
      nodeName: 'Sub-Transformer B2',
      utilityType: 'Electricity',
      zoneId: 'Kedah',
      status: 'Maintenance',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      manufacturer: 'Siemens',
      installationDate: DateTime.now().subtract(const Duration(days: 200)),
      lastMaintenanceDate: DateTime.now().subtract(const Duration(days: 2)),
      healthScore: 72,
      firmwareVersion: 'v1.1.0',
      ipAddress: '192.168.1.44',
    ),
    EquipmentNode(
      nodeId: const Uuid().v4(),
      nodeName: 'Cooling Tower Valve',
      utilityType: 'Water',
      zoneId: 'Johor',
      status: 'Critical',
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
      manufacturer: 'Schneider Electric',
      installationDate: DateTime.now().subtract(const Duration(days: 60)),
      lastMaintenanceDate: DateTime.now().subtract(const Duration(days: 30)),
      healthScore: 34,
      firmwareVersion: 'v3.0.5',
      ipAddress: '192.168.1.105',
    ),
  ];
  static final List<UtilityLog> _logs = [];
  static final List<Alert> _alerts = [];

  // --- Equipment Nodes CRUD ---

  Future<void> upsertNode(EquipmentNode node) async {
    // Delay to simulate network
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (node.nodeId == null) {
      // Create
      final newNode = node.copyWith(
        nodeId: _uuid.v4(),
        createdAt: DateTime.now(),
      );
      _nodes.insert(0, newNode);
    } else {
      // Update
      final index = _nodes.indexWhere((n) => n.nodeId == node.nodeId);
      if (index != -1) {
        _nodes[index] = node;
      }
    }
  }

  Future<List<EquipmentNode>> fetchNodes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_nodes);
  }

  Future<void> deleteNode(String nodeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _nodes.removeWhere((n) => n.nodeId == nodeId);
    _logs.removeWhere((l) => l.nodeId == nodeId); // Cascade delete
  }

  // --- Utility Logs & Anomaly Detection ---

  Future<List<UtilityLog>> fetchLogsForNode(String nodeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final nodeLogs = _logs.where((l) => l.nodeId == nodeId).toList();
    nodeLogs.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
    return nodeLogs;
  }

  void insertHistoricalLog(String nodeId, double value, DateTime timestamp) {
    _logs.add(UtilityLog(
      logId: _uuid.v4(),
      nodeId: nodeId,
      usageValue: value,
      isAnomaly: false, // historical data is baseline
      timestamp: timestamp,
    ));
  }

  /// Inserts a log, calculates Z-score against historical data, and triggers Alert if needed.
  Future<UtilityLog> insertLogAndAnalyze(String nodeId, double value, EquipmentNode node) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 1. Fetch last 30 days of data
    final nodeLogs = _logs.where((l) => l.nodeId == nodeId).toList();
    nodeLogs.sort((a, b) => b.timestamp!.compareTo(a.timestamp!)); // descending
    
    final recentLogs = nodeLogs.take(30).toList();
    final historicalValues = recentLogs.map((l) => l.usageValue).toList();

    // 2. Analyze for anomaly
    final zScore = AnomalyDetector.calculateZScore(value, historicalValues);
    final isAnomaly = AnomalyDetector.isAnomaly(zScore);

    // 3. Insert Log
    final log = UtilityLog(
      logId: _uuid.v4(),
      nodeId: nodeId,
      usageValue: value,
      isAnomaly: isAnomaly,
      timestamp: DateTime.now().toUtc(),
    );
    
    _logs.add(log);

    // 4. Trigger Module 3 integration if anomaly detected
    if (isAnomaly) {
      await _triggerModule3Alert(log, zScore, node);
    }

    return log;
  }

  Future<void> _triggerModule3Alert(UtilityLog log, double zScore, EquipmentNode node) async {
    final alert = Alert(
      alertType: AlertType.nrwHotspot, 
      state: 'Local Test',
      householdId: node.nodeName, 
      detectedAt: log.timestamp ?? DateTime.now(),
      signature: 'Z-Score Anomaly: Spike (Z=${zScore.toStringAsFixed(2)})',
      severity: Severity.high,
      actualL: log.usageValue,
      baselineL: 100.0,
      explanation: 'CRITICAL: Automated Pipe Inspection Required for ${node.nodeName}. Z-Score indicates a massive deviation.',
      status: AlertStatus.pending,
    );

    _alerts.add(alert);
    print('LOCAL ALERT GENERATED: ${alert.title} - ${alert.explanation}');
    
    // Push to Module 3 (Leakage) if repository is available
    if (_leakageRepo != null) {
      try {
        await _leakageRepo!.insertAlert(alert);
        print('Alert successfully pushed to Module 3 Supabase!');
      } catch (e) {
        print('Failed to push alert to Module 3: $e');
      }
    }
  }
}
