class ElectricityRecord {
  final DateTime date;
  final double supply;
  final double consumption;
  final double losses;
  final bool isAnomaly;

  const ElectricityRecord({
    required this.date,
    required this.supply,
    required this.consumption,
    required this.losses,
    this.isAnomaly = false,
  });
}
