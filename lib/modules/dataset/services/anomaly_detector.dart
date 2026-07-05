import 'dart:math';

class AnomalyDetector {
  /// Calculates the Z-score for a new value against a list of historical values.
  /// 
  /// Formula: Z = (X - μ) / σ
  /// Returns the Z-score. If there are fewer than 2 historical data points,
  /// it returns 0 (insufficient data to calculate standard deviation).
  static double calculateZScore(double newValue, List<double> historicalData) {
    if (historicalData.length < 2) return 0.0;

    // Calculate Mean (μ)
    final sum = historicalData.reduce((a, b) => a + b);
    final mean = sum / historicalData.length;

    // Calculate Variance and Standard Deviation (σ)
    double varianceSum = 0;
    for (final value in historicalData) {
      varianceSum += pow(value - mean, 2);
    }
    final variance = varianceSum / (historicalData.length - 1); // Sample variance
    final stdDev = sqrt(variance);

    if (stdDev == 0) return 0.0; // Avoid division by zero

    // Calculate Z-score
    return (newValue - mean) / stdDev;
  }

  /// Checks if a Z-score exceeds the threshold for an anomaly.
  static bool isAnomaly(double zScore, {double threshold = 2.5}) {
    return zScore.abs() > threshold;
  }
}
