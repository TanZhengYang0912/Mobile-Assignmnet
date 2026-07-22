import '../models/models.dart';

const inventoryUtilityFilters = <String>['All', 'Water', 'Electricity'];
const inventoryStatusFilters = <String>[
  'All',
  'Active',
  'Warning',
  'Critical',
  'Maintenance',
];

class InventoryFilterResult {
  final List<EquipmentNode> nodes;
  final Map<String, int> utilityCounts;
  final Map<String, int> statusCounts;

  const InventoryFilterResult({
    required this.nodes,
    required this.utilityCounts,
    required this.statusCounts,
  });
}

InventoryFilterResult filterEquipmentNodes({
  required Iterable<EquipmentNode> nodes,
  String state = 'All',
  String facility = 'All',
  String utility = 'All',
  String status = 'All',
  String query = '',
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final locationNodes = nodes.where((node) {
    if (state != 'All' && node.zoneId != state) return false;
    if (facility != 'All' && node.facilityName != facility) return false;
    if (normalizedQuery.isEmpty) return true;

    return node.nodeName.toLowerCase().contains(normalizedQuery) ||
        (node.zoneId?.toLowerCase().contains(normalizedQuery) ?? false) ||
        (node.facilityName?.toLowerCase().contains(normalizedQuery) ?? false) ||
        (node.facilityCity?.toLowerCase().contains(normalizedQuery) ?? false) ||
        (node.manufacturer?.toLowerCase().contains(normalizedQuery) ?? false);
  }).toList();

  final utilityCounts = <String, int>{};
  final statusCounts = <String, int>{};
  for (final node in locationNodes) {
    utilityCounts[node.utilityType] =
        (utilityCounts[node.utilityType] ?? 0) + 1;
    statusCounts[node.status] = (statusCounts[node.status] ?? 0) + 1;
  }

  final filteredNodes = locationNodes.where((node) {
    if (utility != 'All' && node.utilityType != utility) return false;
    if (status != 'All' && node.status != status) return false;
    return true;
  }).toList();

  return InventoryFilterResult(
    nodes: filteredNodes,
    utilityCounts: utilityCounts,
    statusCounts: statusCounts,
  );
}

List<String> facilitiesForState(
  Iterable<EquipmentNode> nodes,
  String state,
) {
  final facilities = nodes
      .where((node) => state == 'All' || node.zoneId == state)
      .map((node) => node.facilityName)
      .whereType<String>()
      .toSet()
      .toList();
  facilities.sort();
  return facilities;
}
