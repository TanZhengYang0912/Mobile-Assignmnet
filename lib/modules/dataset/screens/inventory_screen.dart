import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
import '../../auth/state/auth_state.dart';
import '../state/dataset_state.dart';
import '../models/models.dart';
import 'equipment_detail_screen.dart';
import 'node_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  String _selectedUtility = 'All';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatasetState>().loadNodes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DatasetState>();
    final nodes = state.nodes;
    final waterCount = nodes.where((n) => n.utilityType == 'Water').length;
    final elecCount = nodes.where((n) => n.utilityType == 'Electricity').length;

    final displayNodes = nodes.where((node) {
      if (_selectedUtility != 'All' && node.utilityType != _selectedUtility) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return node.nodeName.toLowerCase().contains(query) ||
            (node.zoneId ?? '').toLowerCase().contains(query) ||
            (node.manufacturer?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                _header(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _searchField(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child:
                      _filterChips(nodes.length, waterCount, elecCount),
                ),
                const SizedBox(height: 12),
                if (displayNodes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Center(
                      child: Text(
                        'No equipment found matching your criteria.\nAdjust filters or tap + to deploy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...displayNodes.map((n) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _equipmentCard(n, state),
                      )),
                const SizedBox(height: 24),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NodeFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.adminPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'mySumber · ADMIN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => context.read<RoleState>().logout(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Logout',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text(
                    'Inventory',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                headerActionButton(
                  icon: Icons.upload_outlined,
                  label: 'Import',
                  onTap: () => _importData(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _importData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Equipment Data'),
        content: const Text(
            'Bulk-import 4 predefined equipment records from the sample CSV?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _processImport();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _processImport() {
    final state = context.read<DatasetState>();
    const csvString = '''node_name,utility_type,zone_id,manufacturer,status
Smart Water Meter X1,Water,Johor,AquaTech,Active
High-Voltage Transformer,Electricity,Selangor,Siemens,Critical
Main Valve B,Water,Kedah,FlowMaster,Warning
Backup Generator 2,Electricity,Kelantan,Honda,Active''';

    final lines = csvString.split('\n');
    int count = 0;
    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length >= 5) {
        state.addOrUpdateNode(EquipmentNode(
          nodeName: parts[0],
          utilityType: parts[1],
          zoneId: parts[2],
          manufacturer: parts[3],
          status: parts[4],
          installationDate: DateTime.now(),
        ));
        count++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully imported $count equipment nodes.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: const InputDecoration(
        hintText: 'Search equipment…',
        hintStyle: TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
        contentPadding: EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _filterChips(int total, int water, int elec) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All ($total)', 'All'),
          const SizedBox(width: 8),
          _chip('Water ($water)', 'Water', icon: Icons.water_drop_outlined),
          const SizedBox(width: 8),
          _chip('Electricity ($elec)', 'Electricity',
              icon: Icons.electric_bolt_outlined),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, {IconData? icon}) {
    final selected = _selectedUtility == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedUtility = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.adminPrimary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.adminPrimary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected ? Colors.white : AppColors.textPrimary),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _equipmentCard(EquipmentNode node, DatasetState state) {
    final isWater = node.utilityType == 'Water';
    final accent = isWater ? AppColors.waterAccent : AppColors.electricityAccent;
    final surface =
        isWater ? AppColors.waterSurface : AppColors.electricitySurface;

    Color statusColor;
    if (node.status == 'Active') {
      statusColor = AppColors.success;
    } else if (node.status == 'Critical') {
      statusColor = AppColors.critical;
    } else {
      statusColor = AppColors.warning;
    }

    return Dismissible(
      key: Key(node.nodeId ?? node.nodeName),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.critical,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete equipment'),
            content: Text('Delete "${node.nodeName}"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.critical),
                  child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (node.nodeId != null) state.deleteNode(node.nodeId!);
      },
      child: GestureDetector(
        onTap: () {
          state.selectNode(node);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EquipmentDetailScreen()),
          );
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isWater ? Icons.water_drop_outlined : Icons.electric_bolt,
                          color: accent,
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.surface, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.nodeName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${node.zoneId ?? '—'} · ${node.manufacturer ?? 'Unknown'}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              node.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${node.healthScore}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (node.healthScore / 100).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor:
                                statusColor.withValues(alpha: 0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NodeFormScreen(node: node),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
