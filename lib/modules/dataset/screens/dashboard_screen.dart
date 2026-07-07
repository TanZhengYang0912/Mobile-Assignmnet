import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
import '../../auth/state/auth_state.dart';
import '../state/dataset_state.dart';
import '../models/models.dart';
import 'equipment_detail_screen.dart';
import 'node_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';
  String _selectedUtility = 'All';
  String _selectedPeriod = 'Monthly';
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
    final activeCount = nodes.where((n) => n.status == 'Active').length;
    final criticalCount = nodes.where((n) => n.status == 'Critical').length;

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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _systemOverviewCard(nodes.length, activeCount, criticalCount),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _usageComparisonCard(state),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _searchField(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _filterChips(nodes.length, waterCount, elecCount),
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
                    'Utility Equipment\nDashboard',
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
Main Valve B,Water,Kedah,FlowMaster,Maintenance
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

  Widget _systemOverviewCard(int total, int active, int critical) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('SYSTEM OVERVIEW'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCell(
                  icon: Icons.dns_outlined,
                  iconColor: AppColors.textPrimary,
                  value: total.toString(),
                  label: 'Total Nodes',
                  background: const Color(0xFFF3F4F6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCell(
                  icon: Icons.monitor_heart_outlined,
                  iconColor: AppColors.success,
                  value: active.toString(),
                  label: 'Active',
                  background: AppColors.successSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCell(
                  icon: LucideIcons.serverCrash,
                  iconColor: AppColors.critical,
                  value: critical.toString(),
                  label: 'Critical',
                  background: AppColors.criticalSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double get _periodMultiplier {
    switch (_selectedPeriod) {
      case 'Daily':
        return 1 / 365.0;
      case '7D Avg':
        return 7 / 365.0;
      case 'Yearly':
        return 1.0;
      default:
        return 30 / 365.0;
    }
  }

  String get _periodUnit {
    switch (_selectedPeriod) {
      case 'Daily':
        return '/day';
      case '7D Avg':
        return '/week';
      case 'Yearly':
        return '/year';
      default:
        return '/month';
    }
  }

  Widget _usageComparisonCard(DatasetState state) {
    final mult = _periodMultiplier;
    final unit = _periodUnit;

    final waterLoss = <String, double>{};
    final elecLoss = <String, double>{};
    for (final s in state.stateWaterSupply.keys) {
      final loss = ((state.stateWaterSupply[s] ?? 0) -
              (state.stateWaterConsumption[s] ?? 0)) *
          mult;
      if (loss > 0) waterLoss[s] = loss;
    }
    for (final s in state.stateElectricitySupply.keys) {
      final loss = ((state.stateElectricitySupply[s] ?? 0) -
              (state.stateElectricityConsumption[s] ?? 0)) *
          mult;
      if (loss > 0) elecLoss[s] = loss;
    }
    final topWater = waterLoss.entries.isEmpty
        ? null
        : (waterLoss.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
    final topElec = elecLoss.entries.isEmpty
        ? null
        : (elecLoss.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

    final unionStates = {...waterLoss.keys, ...elecLoss.keys}.toList()..sort();
    final topFour = unionStates.take(4).toList();

    const periods = ['Daily', '7D Avg', 'Monthly', 'Yearly'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Usage Comparison',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              PopupMenuButton<String>(
                onSelected: (v) => setState(() => _selectedPeriod = v),
                itemBuilder: (_) => periods
                    .map((p) => PopupMenuItem<String>(
                          value: p,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: p == _selectedPeriod
                                ? BoxDecoration(
                                    color: AppColors.canvas,
                                    borderRadius: BorderRadius.circular(6),
                                  )
                                : null,
                            child: Text(
                              p,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: p == _selectedPeriod
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: p == _selectedPeriod
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedPeriod,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _lossCallout(
                  icon: LucideIcons.droplets,
                  color: AppColors.waterAccent,
                  bg: AppColors.waterSurface,
                  label: 'Top Water Loss',
                  state: topWater?.key ?? 'N/A',
                  value: '${_shortNum(topWater?.value ?? 0)} L$unit',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _lossCallout(
                  icon: Icons.electric_bolt_outlined,
                  color: AppColors.electricityAccent,
                  bg: AppColors.electricitySurface,
                  label: 'Top Elec. Loss',
                  state: topElec?.key ?? 'N/A',
                  value: '${_shortNum(topElec?.value ?? 0)} Wh$unit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _horizontalLossChart(topFour, waterLoss, elecLoss),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.waterAccent, 'Water'),
              const SizedBox(width: 24),
              _legendDot(AppColors.electricityAccent, 'Electricity'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lossCallout({
    required IconData icon,
    required Color color,
    required Color bg,
    required String label,
    required String state,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(state,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _horizontalLossChart(
    List<String> states,
    Map<String, double> waterLoss,
    Map<String, double> elecLoss,
  ) {
    if (states.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No data available.',
              style: TextStyle(color: AppColors.textTertiary)),
        ),
      );
    }
    double maxV = 0;
    for (final s in states) {
      maxV = [
        maxV,
        waterLoss[s] ?? 0,
        elecLoss[s] ?? 0,
      ].reduce((a, b) => a > b ? a : b);
    }
    if (maxV == 0) maxV = 100;
    final scale = maxV * 1.05;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final state in states) ...[
          _stateBarRow(
            state: state,
            water: waterLoss[state] ?? 0,
            electricity: elecLoss[state] ?? 0,
            scale: scale,
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        _axisScale(scale),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'L / Wh (x1000)',
            style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _stateBarRow({
    required String state,
    required double water,
    required double electricity,
    required double scale,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            state,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _valueBar(water, scale, AppColors.waterAccent),
              const SizedBox(height: 4),
              _valueBar(electricity, scale, AppColors.electricityAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _valueBar(double value, double scale, Color color) {
    final ratio = scale <= 0 ? 0.0 : (value / scale).clamp(0.0, 1.0);
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * ratio;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: width,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Positioned(
                left: width + 4,
                child: Text(
                  _shortNum(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _axisScale(double scale) {
    final ticks = List.generate(5, (i) => scale * i / 4);
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Row(
        children: [
          for (int i = 0; i < ticks.length; i++) ...[
            if (i > 0) const Spacer(),
            Text(
              _shortNum(ticks[i]),
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
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
          _chip('Water ($water)', 'Water', icon: LucideIcons.droplets),
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
                  style: TextButton.styleFrom(foregroundColor: AppColors.critical),
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
                          isWater ? LucideIcons.droplets : Icons.electric_bolt,
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

  static String _shortNum(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}
