import 'dart:math';

double calculateZScore(double newValue, List<double> historicalData) {
  if (historicalData.length < 2) return 0.0;
  final sum = historicalData.reduce((a, b) => a + b);
  final mean = sum / historicalData.length;
  double varianceSum = 0;
  for (final value in historicalData) {
    varianceSum += pow(value - mean, 2);
  }
  final variance = varianceSum / (historicalData.length - 1);
  final stdDev = sqrt(variance);
  if (stdDev == 0) return 0.0;
  return (newValue - mean) / stdDev;
}

void main() {
  final random = Random(42);
  final history = <double>[];
  for (int i = 0; i < 30; i++) {
    final value = 90.0 + random.nextDouble() * 20.0;
    history.add(value);
  }
  
  final z = calculateZScore(350.0, history);
  print('Z-Score: \$z');
  print('Is Anomaly: \${z.abs() > 2.5}');
}
