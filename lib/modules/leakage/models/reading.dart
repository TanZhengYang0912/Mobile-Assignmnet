class Reading {
  final int? id;
  final String householdId;
  final String state;
  final int householdSize;
  final DateTime readingDate;
  final double dayFlowL;
  final double nightFlowL;
  final String scenario;

  const Reading({
    this.id,
    required this.householdId,
    required this.state,
    required this.householdSize,
    required this.readingDate,
    required this.dayFlowL,
    required this.nightFlowL,
    required this.scenario,
  });

  double get totalDailyL => dayFlowL + nightFlowL;

  Map<String, Object?> toMap() => {
        'id': id,
        'household_id': householdId,
        'state': state,
        'household_size': householdSize,
        'reading_date': readingDate.toIso8601String(),
        'day_flow_l': dayFlowL,
        'night_flow_l': nightFlowL,
        'scenario': scenario,
      };

  factory Reading.fromMap(Map<String, Object?> map) => Reading(
        id: map['id'] as int?,
        householdId: map['household_id'] as String,
        state: map['state'] as String,
        householdSize: map['household_size'] as int,
        readingDate: DateTime.parse(map['reading_date'] as String),
        dayFlowL: (map['day_flow_l'] as num).toDouble(),
        nightFlowL: (map['night_flow_l'] as num).toDouble(),
        scenario: map['scenario'] as String,
      );

  Reading copyWith({int? id}) => Reading(
        id: id ?? this.id,
        householdId: householdId,
        state: state,
        householdSize: householdSize,
        readingDate: readingDate,
        dayFlowL: dayFlowL,
        nightFlowL: nightFlowL,
        scenario: scenario,
      );
}
