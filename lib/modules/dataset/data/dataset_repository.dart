import 'package:uuid/uuid.dart';

import '../models/models.dart';

class DatasetRepository {
  final Uuid _uuid = const Uuid();

  // In-memory demo storage for Module 1. Every configured Malaysian state or
  // federal territory has at least one facility, while high-density areas
  // have more facilities to make the nationwide hierarchy visible.
  static final List<EquipmentNode> _nodes = _buildSeedNodes();
  static final List<UtilityLog> _logs = [];

  static const List<_FacilitySeed> _facilitySeeds = [
    _FacilitySeed('W.P. Kuala Lumpur', 'Kuala Lumpur', 'Suria KLCC'),
    _FacilitySeed('W.P. Kuala Lumpur', 'Kuala Lumpur', 'Pavilion Kuala Lumpur'),
    _FacilitySeed('W.P. Kuala Lumpur', 'Kuala Lumpur', 'Mid Valley Megamall'),
    _FacilitySeed('W.P. Kuala Lumpur', 'Kuala Lumpur', 'The Exchange TRX'),
    _FacilitySeed('W.P. Kuala Lumpur', 'Kuala Lumpur', 'Berjaya Times Square'),
    _FacilitySeed('Selangor', 'Petaling Jaya', '1 Utama Shopping Centre'),
    _FacilitySeed('Selangor', 'Subang Jaya', 'Sunway Pyramid'),
    _FacilitySeed('Selangor', 'Shah Alam', 'Setia City Mall'),
    _FacilitySeed('Johor', 'Johor Bahru', 'Mid Valley Southkey'),
    _FacilitySeed('Johor', 'Johor Bahru', 'Paradigm Mall Johor Bahru'),
    _FacilitySeed('Pulau Pinang', 'George Town', 'Gurney Plaza'),
    _FacilitySeed('Pulau Pinang', 'Bayan Lepas', 'Queensbay Mall'),
    _FacilitySeed('Sabah', 'Kota Kinabalu', 'Imago Shopping Mall'),
    _FacilitySeed('Sabah', 'Kota Kinabalu', 'Suria Sabah'),
    _FacilitySeed('Sarawak', 'Kuching', 'The Spring Shopping Mall'),
    _FacilitySeed('Sarawak', 'Kuching', 'Vivacity Megamall'),
    _FacilitySeed('Kedah', 'Alor Setar', 'Aman Central'),
    _FacilitySeed('Kelantan', 'Kota Bharu', 'AEON Mall Kota Bharu'),
    _FacilitySeed(
        'Melaka', 'Bandar Melaka', 'Dataran Pahlawan Melaka Megamall'),
    _FacilitySeed('Negeri Sembilan', 'Seremban', 'Palm Mall Seremban'),
    _FacilitySeed('Pahang', 'Kuantan', 'East Coast Mall'),
    _FacilitySeed('Perak', 'Ipoh', 'Ipoh Parade'),
    _FacilitySeed('Perlis', 'Kangar', 'Kangar Central Mall'),
    _FacilitySeed('Terengganu', 'Kuala Terengganu', 'Paya Bunga Square'),
    _FacilitySeed('W.P. Labuan', 'Labuan', 'Financial Park Labuan'),
    _FacilitySeed('W.P. Putrajaya', 'Putrajaya', 'Alamanda Shopping Centre'),
  ];

  static List<EquipmentNode> _buildSeedNodes() {
    final now = DateTime.now();
    final nodes = <EquipmentNode>[];

    for (var i = 0; i < _facilitySeeds.length; i++) {
      final facility = _facilitySeeds[i];
      final subnet = i + 1;
      final valveIsCritical = i % 4 == 0;
      final transformerNeedsMaintenance = i % 5 == 0;

      nodes.add(EquipmentNode(
        nodeId: const Uuid().v4(),
        nodeName: 'Main Water Pump A1',
        utilityType: 'Water',
        zoneId: facility.state,
        facilityName: facility.name,
        facilityCity: facility.city,
        status: 'Active',
        createdAt: now.subtract(Duration(days: 120 + i)),
        manufacturer: 'Grundfos',
        installationDate: now.subtract(Duration(days: 365 + i)),
        lastMaintenanceDate: now.subtract(Duration(days: 15 + i % 12)),
        healthScore: 96 - i % 8,
        firmwareVersion: 'v2.4.1',
        ipAddress: '10.0.$subnet.10',
      ));

      nodes.add(EquipmentNode(
        nodeId: const Uuid().v4(),
        nodeName: 'Cooling Tower Valve',
        utilityType: 'Water',
        zoneId: facility.state,
        facilityName: facility.name,
        facilityCity: facility.city,
        status: valveIsCritical ? 'Critical' : 'Active',
        createdAt: now.subtract(Duration(days: 90 + i)),
        manufacturer: 'Schneider Electric',
        installationDate: now.subtract(Duration(days: 240 + i)),
        lastMaintenanceDate: now.subtract(Duration(days: 30 + i % 15)),
        healthScore: valveIsCritical ? 58 : 90 - i % 7,
        firmwareVersion: 'v3.0.5',
        ipAddress: '10.0.$subnet.11',
      ));

      nodes.add(EquipmentNode(
        nodeId: const Uuid().v4(),
        nodeName: 'Sub-Transformer B2',
        utilityType: 'Electricity',
        zoneId: facility.state,
        facilityName: facility.name,
        facilityCity: facility.city,
        status: transformerNeedsMaintenance ? 'Maintenance' : 'Active',
        createdAt: now.subtract(Duration(days: 150 + i)),
        manufacturer: 'Siemens',
        installationDate: now.subtract(Duration(days: 300 + i)),
        lastMaintenanceDate: now.subtract(Duration(days: 2 + i % 20)),
        healthScore: transformerNeedsMaintenance ? 72 : 94 - i % 9,
        firmwareVersion: 'v1.1.0',
        ipAddress: '10.0.$subnet.12',
      ));
    }

    return nodes;
  }

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
}

class _FacilitySeed {
  final String state;
  final String city;
  final String name;

  const _FacilitySeed(this.state, this.city, this.name);
}
