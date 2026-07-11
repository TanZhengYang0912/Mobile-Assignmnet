enum UtilityType {
  water('water', 'Water', 'm³'),
  electricity('electricity', 'Electricity', 'kWh');

  final String key;
  final String label;
  final String unit;
  const UtilityType(this.key, this.label, this.unit);

  static UtilityType fromKey(String key) =>
      values.firstWhere((u) => u.key == key, orElse: () => water);
}

class UtilityEntry {
  final int id;
  final UtilityType utility;
  final DateTime periodMonth;
  final double value;

  const UtilityEntry({
    required this.id,
    required this.utility,
    required this.periodMonth,
    required this.value,
  });

  factory UtilityEntry.fromMap(Map<String, dynamic> map) {
    return UtilityEntry(
      id: map['id'] as int,
      utility: UtilityType.fromKey(map['utility'] as String),
      periodMonth: DateTime.parse(map['period_month'] as String),
      value: (map['value'] as num).toDouble(),
    );
  }
}
