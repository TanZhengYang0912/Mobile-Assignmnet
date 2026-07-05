import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  String _sortBy = 'Name (A-Z)';
  String _chartTimeRange = 'Daily';
  String _chartUtility = 'Water';
  double _zoomFactor = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatasetState>().loadNodes();
    });
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
      if (_selectedUtility != 'All' && node.utilityType != _selectedUtility) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return node.nodeName.toLowerCase().contains(query) ||
               (node.zoneId ?? '').toLowerCase().contains(query) ||
               (node.manufacturer?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();

    displayNodes.sort((a, b) {
      if (_sortBy == 'Name (A-Z)') {
        return a.nodeName.compareTo(b.nodeName);
      } else if (_sortBy == 'Status') {
        int weight(String status) {
          switch(status) {
            case 'Critical': return 0;
            case 'Maintenance': return 1;
            case 'Offline': return 2;
            default: return 3;
          }
        }
        return weight(a.status).compareTo(weight(b.status));
      } else if (_sortBy == 'Recent') {
        return (b.installationDate ?? DateTime(2000)).compareTo(a.installationDate ?? DateTime(2000));
      }
      return 0;
    });

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Utility Equipment Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Import from CSV',
            icon: const Icon(Icons.upload_file, size: 28),
            onPressed: () {
              _importData(context);
            },
          ),
          IconButton(
            tooltip: 'Add Equipment',
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NodeFormScreen()),
              );
            },
          )
        ],
      ),
      body: Consumer<DatasetState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final nodes = state.nodes;
          final activeCount = nodes.where((n) => n.status == 'Active').length;
          final criticalCount = nodes.where((n) => n.status == 'Critical').length;
          final waterCount = nodes.where((n) => n.utilityType == 'Water').length;
          final elecCount = nodes.where((n) => n.utilityType == 'Electricity').length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeaderAnalytics(
                  total: nodes.length,
                  active: activeCount,
                  critical: criticalCount,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildZoneComparisonChart(state),
              ),
              SliverToBoxAdapter(
                child: _buildFilterAndSearchSection(waterCount, elecCount),
              ),
              if (displayNodes.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No equipment found matching your criteria.\nAdjust filters or click + to deploy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final node = displayNodes[index];
                      return _buildEquipmentCard(context, node, state);
                    },
                    childCount: displayNodes.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          );
        },
      ),
    );
  }

  void _importData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Equipment Data'),
        content: const Text('Would you like to bulk import equipment records from the predefined system CSV file?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
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
    final csvString = '''node_name,utility_type,zone_id,manufacturer,status
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
        content: Text('✅ Successfully imported $count equipment nodes.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildHeaderAnalytics({required int total, required int active, required int critical}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Total Nodes', total.toString(), Icons.router),
              _buildMetric('Active', active.toString(), Icons.check_circle, Colors.greenAccent),
              _buildMetric('Critical', critical.toString(), Icons.warning, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, [Color color = Colors.white]) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildEquipmentCard(BuildContext context, dynamic node, DatasetState state) {
    Color statusColor;
    if (node.status == 'Active') statusColor = Colors.green;
    else if (node.status == 'Critical') statusColor = Colors.red;
    else statusColor = Colors.orange;

    return Dismissible(
      key: Key(node.nodeId ?? node.nodeName),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        if (node.nodeId != null) {
          state.deleteNode(node.nodeId!);
        }
      },
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Deletion"),
              content: Text("Are you sure you want to delete '${node.nodeName}'? This action cannot be undone."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: node.utilityType == 'Water' ? Colors.blue.shade50 : Colors.amber.shade50,
                radius: 24,
                child: Icon(
                  node.utilityType == 'Water' ? Icons.water_drop : Icons.electric_bolt,
                  color: node.utilityType == 'Water' ? Colors.blue : Colors.amber,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              )
            ],
          ),
          title: Text(node.nodeName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Health: ${node.healthScore}% • ${node.zoneId}'),
              Text(node.manufacturer ?? 'Unknown Manufacturer', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueGrey),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NodeFormScreen(node: node),
                ),
              );
            },
          ),
          onTap: () {
            state.selectNode(node);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EquipmentDetailScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildZoneComparisonChart(DatasetState state) {
    double multiplier = 1.0;
    String timeLabel = '/ day';
    if (_chartTimeRange == '7D Avg') {
      multiplier = 0.95; 
      timeLabel = '/ day';
    } else if (_chartTimeRange == 'Monthly') {
      multiplier = 30.0;
      timeLabel = '/ month';
    } else if (_chartTimeRange == 'Yearly') {
      multiplier = 365.0;
      timeLabel = '/ year';
    }

    final supplyData = _chartUtility == 'Water' ? state.stateWaterSupply : state.stateElectricitySupply;
    final consumptionData = _chartUtility == 'Water' ? state.stateWaterConsumption : state.stateElectricityConsumption;
    
    final Map<String, double> chartSupply = {};
    final Map<String, double> chartConsumption = {};
    
    final Set<String> allStates = {...supplyData.keys, ...consumptionData.keys};
    final sortedStates = allStates.toList()..sort();
    
    double maxY = 0;
    
    for (var stateName in sortedStates) {
      final s = (supplyData[stateName] ?? 0.0) / 365.0 * multiplier;
      final c = (consumptionData[stateName] ?? 0.0) / 365.0 * multiplier;
      chartSupply[stateName] = s;
      chartConsumption[stateName] = c;
      if (s > maxY) maxY = s;
      if (c > maxY) maxY = c;
    }
    
    if (maxY == 0) maxY = 100;
    else maxY = maxY * 1.35; // Add 35% headroom to ensure tooltips don't get clipped
    
    // Find highest losses
    String highestWaterLossState = 'N/A';
    double highestWaterLoss = 0;
    for (var stateName in state.stateWaterSupply.keys) {
      final s = (state.stateWaterSupply[stateName] ?? 0.0) / 365.0 * multiplier;
      final c = (state.stateWaterConsumption[stateName] ?? 0.0) / 365.0 * multiplier;
      final loss = s - c;
      if (loss > highestWaterLoss && loss > 0) {
        highestWaterLoss = loss;
        highestWaterLossState = stateName;
      }
    }
    
    String highestElecTheftState = 'N/A';
    double highestElecTheft = 0;
    for (var stateName in state.stateElectricitySupply.keys) {
      final s = (state.stateElectricitySupply[stateName] ?? 0.0) / 365.0 * multiplier;
      final c = (state.stateElectricityConsumption[stateName] ?? 0.0) / 365.0 * multiplier;
      final loss = s - c;
      if (loss > highestElecTheft && loss > 0) {
        highestElecTheft = loss;
        highestElecTheftState = stateName;
      }
    }

    // Dynamic width for scrollability: 80px per state
    final double baseWidth = sortedStates.length * 80.0;
    final chartWidth = (baseWidth > 300 ? baseWidth : 300) * _zoomFactor;
    
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Usage Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  ToggleButtons(
                    isSelected: [_chartUtility == 'Water', _chartUtility == 'Electricity'],
                    onPressed: (idx) => setState(() => _chartUtility = idx == 0 ? 'Water' : 'Electricity'),
                    constraints: const BoxConstraints(minHeight: 28, minWidth: 36),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.blueGrey,
                    selectedColor: _chartUtility == 'Water' ? Colors.blue : Colors.amber,
                    fillColor: (_chartUtility == 'Water' ? Colors.blue : Colors.amber).withValues(alpha: 0.1),
                    children: const [
                      Icon(Icons.water_drop, size: 16),
                      Icon(Icons.bolt, size: 16),
                    ],
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _chartTimeRange,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                    items: ['Daily', '7D Avg', 'Monthly', 'Yearly'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _chartTimeRange = val!),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (sortedStates.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            const Text('Top Water Leakage', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(highestWaterLossState, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 14)),
                        Text('${highestWaterLoss >= 1000 ? '${(highestWaterLoss / 1000).toStringAsFixed(1)}k' : highestWaterLoss.toInt()} L Loss $timeLabel', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.red.shade200),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            const Text('Top Elec. Theft/Loss', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(highestElecTheftState, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 14)),
                        Text('${highestElecTheft >= 1000 ? '${(highestElecTheft / 1000).toStringAsFixed(1)}k' : highestElecTheft.toInt()} kW Loss $timeLabel', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (sortedStates.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('No data available. Add equipment to see usage.', style: TextStyle(color: Colors.grey))),
            )
          else
            Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: 220,
                    width: chartWidth,
                    child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final stateName = sortedStates[groupIndex];
                          final val = rod.toY.toInt();
                          final unit = _chartUtility == 'Water' ? 'L' : 'kW';
                          final type = rodIndex == 0 ? 'Supply' : 'Billed';
                          return BarTooltipItem(
                            '$stateName\n$type: $val $unit',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= sortedStates.length) return const SizedBox.shrink();
                            final stateName = sortedStates[value.toInt()];
                            
                            // Shorten long state names for display
                            String displayName = stateName;
                            if (stateName == 'W.P. Kuala Lumpur') displayName = 'KL';
                            if (stateName == 'W.P. Putrajaya') displayName = 'Putrajaya';
                            if (stateName == 'W.P. Labuan') displayName = 'Labuan';
                            if (stateName == 'Negeri Sembilan') displayName = 'N. Sembilan';
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(displayName, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == meta.max) return const SizedBox.shrink();
                            String text = value.toInt().toString();
                            if (value >= 1000) {
                              text = '${(value / 1000).toStringAsFixed(1)}k';
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                text, 
                                style: const TextStyle(color: Colors.blueGrey, fontSize: 9, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(sortedStates.length, (index) {
                      final stateName = sortedStates[index];
                      final s = chartSupply[stateName] ?? 0.0;
                      final c = chartConsumption[stateName] ?? 0.0;
                      
                      return BarChartGroupData(
                        x: index,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: s, 
                            color: _chartUtility == 'Water' ? Colors.blue.shade200 : Colors.amber.shade200, 
                            width: 12 * _zoomFactor, 
                            borderRadius: BorderRadius.circular(2)
                          ),
                          BarChartRodData(
                            toY: c, 
                            color: _chartUtility == 'Water' ? Colors.blue.shade600 : Colors.amber.shade600, 
                            width: 12 * _zoomFactor, 
                            borderRadius: BorderRadius.circular(2)
                          ),
                        ],
                      );
                    }),
                  ), // BarChartData
                ), // BarChart
              ), // SizedBox
            ), // SingleChildScrollView
            Positioned(
              bottom: -10,
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.blueGrey.shade400,
                    iconSize: 20,
                    onPressed: () {
                      setState(() {
                        if (_zoomFactor > 0.5) _zoomFactor -= 0.25;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.blueGrey.shade400,
                    iconSize: 20,
                    onPressed: () {
                      setState(() {
                        if (_zoomFactor < 3.0) _zoomFactor += 0.25;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ), // Stack
      ],
    ), // Column
  ); // Container
  }

  BarChartGroupData _makeGroupData(int x, double water, double electricity) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: water,
          color: Colors.blue.shade400,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: electricity,
          color: Colors.amber.shade600,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildFilterAndSearchSection(int waterCount, int elecCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Combined Search Bar and Sort Menu
          TextField(
            decoration: InputDecoration(
              hintText: 'Search equipment...',
              prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: Colors.blueGrey),
                tooltip: 'Sort by',
                position: PopupMenuPosition.under,
                onSelected: (val) => setState(() => _sortBy = val),
                itemBuilder: (context) => ['Name (A-Z)', 'Status', 'Recent'].map((s) {
                  return PopupMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(
                          s == _sortBy ? Icons.check : null, 
                          size: 18, 
                          color: Colors.teal
                        ),
                        const SizedBox(width: 8),
                        Text(s, style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: s == _sortBy ? FontWeight.bold : FontWeight.normal
                        )),
                      ],
                    ),
                  );
                }).toList(),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), // Modern pill shape
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 12),
          // Lightweight Choice Chips for filtering
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip('All', waterCount + elecCount),
                const SizedBox(width: 8),
                _buildChip('Water', waterCount, icon: Icons.water_drop),
                const SizedBox(width: 8),
                _buildChip('Electricity', elecCount, icon: Icons.bolt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String title, int count, {IconData? icon}) {
    final isSelected = _selectedUtility == title;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.blueGrey),
            const SizedBox(width: 4),
          ],
          Text('$title ($count)'),
        ],
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) setState(() => _selectedUtility = title);
      },
      selectedColor: Colors.teal.shade600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.blueGrey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
      showCheckmark: false,
    );
  }
}
