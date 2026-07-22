import 'package:flutter_test/flutter_test.dart';

import 'package:mysumber/modules/dataset/data/dataset_repository.dart';
import 'package:mysumber/modules/dataset/models/models.dart';

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
}
