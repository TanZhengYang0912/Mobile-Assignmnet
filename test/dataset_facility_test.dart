import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mysumber/modules/dataset/data/dataset_repository.dart';
import 'package:mysumber/modules/dataset/models/models.dart';
import 'package:mysumber/modules/dataset/screens/inventory_screen.dart';
import 'package:mysumber/modules/dataset/services/inventory_filter.dart';
import 'package:mysumber/modules/dataset/state/dataset_state.dart';

void main() {
  test('seeds every configured mall with the three core equipment types',
      () async {
    final nodes = await DatasetRepository().fetchNodes();
    final facilities = nodes.map((node) => node.facilityName).toSet();
    final facilitiesByState = <String, int>{};
    for (final node in nodes) {
      facilitiesByState[node.zoneId!] =
          (facilitiesByState[node.zoneId!] ?? 0) + 1;
    }

    expect(facilities.length, 26);
    expect(nodes.length, 26 * 3);
    expect(facilitiesByState['W.P. Kuala Lumpur'], 5 * 3);
    expect(facilitiesByState['Selangor'], 3 * 3);
    expect(facilitiesByState['Johor'], 2 * 3);
    expect(facilitiesByState['Pulau Pinang'], 2 * 3);
    expect(facilitiesByState['Sabah'], 2 * 3);
    expect(facilitiesByState['Sarawak'], 2 * 3);
    expect(facilitiesByState.length, 16);

    for (final facility in facilities) {
      final facilityNodes =
          nodes.where((node) => node.facilityName == facility).toList();
      expect(
        facilityNodes.map((node) => node.nodeName).toSet(),
        containsAll(<String>[
          'Main Water Pump A1',
          'Cooling Tower Valve',
          'Sub-Transformer B2',
        ]),
      );
    }
  });

  test('equipment mapping preserves its mall and city', () {
    const node = EquipmentNode(
      nodeName: 'Main Water Pump A1',
      utilityType: 'Water',
      zoneId: 'Selangor',
      facilityName: '1 Utama Shopping Centre',
      facilityCity: 'Petaling Jaya',
      status: 'Active',
    );

    final restored = EquipmentNode.fromMap(node.toMap());

    expect(restored.facilityName, '1 Utama Shopping Centre');
    expect(restored.facilityCity, 'Petaling Jaya');
  });

  testWidgets('inventory can open with a selected state filter',
      (tester) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final datasetState = DatasetState(repository: DatasetRepository());
    datasetState.stateWaterSupply['Selangor'] = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DatasetState>.value(
          value: datasetState,
          child: const InventoryScreen(initialState: 'Selangor'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('State: Selangor'), findsOneWidget);
    expect(find.text('Aman Central'), findsNothing);
  });

  test('filters Selangor to its nine equipment nodes', () async {
    final nodes = await DatasetRepository().fetchNodes();
    final result = filterEquipmentNodes(nodes: nodes, state: 'Selangor');

    expect(result.nodes, hasLength(9));
  });

  test('filters a Selangor mall to its three core equipment nodes', () async {
    final nodes = await DatasetRepository().fetchNodes();
    final result = filterEquipmentNodes(
      nodes: nodes,
      state: 'Selangor',
      facility: '1 Utama Shopping Centre',
    );

    expect(result.nodes, hasLength(3));
  });

  test('lists only facilities belonging to the selected state', () async {
    final nodes = await DatasetRepository().fetchNodes();

    expect(
      facilitiesForState(nodes, 'Selangor'),
      <String>[
        '1 Utama Shopping Centre',
        'Setia City Mall',
        'Sunway Pyramid',
      ],
    );
  });

  test('combines state, mall, utility, and status filters', () async {
    final nodes = await DatasetRepository().fetchNodes();
    final result = filterEquipmentNodes(
      nodes: nodes,
      state: 'Selangor',
      facility: '1 Utama Shopping Centre',
      utility: 'Electricity',
      status: 'Maintenance',
    );

    expect(result.nodes, hasLength(1));
    expect(result.nodes.single.nodeName, 'Sub-Transformer B2');
  });
}
