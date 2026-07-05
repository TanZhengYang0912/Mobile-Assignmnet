import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/electricity_state.dart';

class ElectricityDashboardScreen extends StatefulWidget {
  const ElectricityDashboardScreen({super.key});

  @override
  State<ElectricityDashboardScreen> createState() => _ElectricityDashboardScreenState();
}

class _ElectricityDashboardScreenState extends State<ElectricityDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ElectricityState>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electricity Anomaly Detection'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ElectricityState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(child: Text(state.errorMessage!, style: const TextStyle(color: Colors.red)));
          }

          if (state.records.isEmpty) {
            return const Center(child: Text('No data found in datasets.'));
          }

          return Column(
            children: [
              // Legend
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Colors.blue, 'Supply'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.green, 'Consumption'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.red, 'Losses'),
                  ],
                ),
              ),

              // Chart Area
              Container(
                height: 300,
                padding: const EdgeInsets.only(right: 16, left: 8, top: 16, bottom: 8),
                child: _buildChart(state),
              ),
              
              const Divider(thickness: 2),
              
              // Anomalies List
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Detected Anomalies (${state.anomalies.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: state.anomalies.isEmpty
                    ? const Center(child: Text('No anomalies detected. Everything looks normal.'))
                    : ListView.builder(
                        itemCount: state.anomalies.length,
                        itemBuilder: (context, index) {
                          final anomaly = state.anomalies[index];
                          final dateStr = DateFormat.yMMM().format(anomaly.date);
                          final lossPctStr = anomaly.supply > 0 
                              ? ((anomaly.losses / anomaly.supply) * 100).toStringAsFixed(1)
                              : '0.0';
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.red,
                                child: Icon(Icons.electric_meter, color: Colors.white),
                              ),
                              title: Text('Potential Tampering: $dateStr'),
                              subtitle: Text(
                                'Loss: ${anomaly.losses.toStringAsFixed(0)} kWh ($lossPctStr% of supply)',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChart(ElectricityState state) {
    final records = state.records;
    
    final supplySpots = <FlSpot>[];
    final consumptionSpots = <FlSpot>[];
    final lossesSpots = <FlSpot>[];
    final anomalyIndices = <int>[];

    for (int i = 0; i < records.length; i++) {
      supplySpots.add(FlSpot(i.toDouble(), records[i].supply));
      consumptionSpots.add(FlSpot(i.toDouble(), records[i].consumption));
      lossesSpots.add(FlSpot(i.toDouble(), records[i].losses));
      if (records[i].isAnomaly) {
        anomalyIndices.add(i);
      }
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          // Supply Line
          LineChartBarData(
            spots: supplySpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          // Consumption Line
          LineChartBarData(
            spots: consumptionSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          // Losses Line
          LineChartBarData(
            spots: lossesSpots,
            isCurved: true,
            color: Colors.red.withOpacity(0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (anomalyIndices.contains(index)) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.red,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                );
              },
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide X axis for simplicity
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}
