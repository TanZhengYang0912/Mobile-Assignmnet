import '../models/alert.dart';
import '../models/reading.dart';

class DetectionResult {
  final bool isAnomaly;
  final String signature;
  final String severity;
  final double baselineL;
  final double actualL;
  final double ratio;
  final double zScore;
  final bool nightFlowElevated;

  const DetectionResult({
    required this.isAnomaly,
    required this.signature,
    required this.severity,
    required this.baselineL,
    required this.actualL,
    required this.ratio,
    required this.zScore,
    required this.nightFlowElevated,
  });
}

class DetectionEngine {
  static const double _burstRatio = 3.0;
  static const double _sustainedRatio = 1.8;
  static const double _elevatedRatio = 1.4;
  static const double _normalNightShare = 0.08;
  static const double _nightAlarmMultiple = 3.0;
  static const double _spreadFactor = 0.25;

  DetectionResult evaluate(List<Reading> series, double baselineDailyL) {
    final latest = series.last;
    final actual = latest.totalDailyL;
    final ratio = baselineDailyL == 0 ? 0.0 : actual / baselineDailyL;

    final sigma = baselineDailyL * _spreadFactor;
    final zScore = sigma == 0 ? 0.0 : (actual - baselineDailyL) / sigma;

    final expectedNight = baselineDailyL * _normalNightShare;
    final nightRatio =
        expectedNight == 0 ? 0.0 : latest.nightFlowL / expectedNight;
    final nightElevated = nightRatio > _nightAlarmMultiple;

    if (ratio > _burstRatio) {
      return _result(LeakSignature.suddenBurst, Severity.high, baselineDailyL,
          actual, ratio, zScore, nightElevated);
    }

    if (ratio > _sustainedRatio &&
        nightElevated &&
        _sustainedHigh(series, baselineDailyL)) {
      return _result(LeakSignature.continuousLeak, Severity.high,
          baselineDailyL, actual, ratio, zScore, nightElevated);
    }

    if (ratio > _elevatedRatio && _increasingTrend(series)) {
      return _result(LeakSignature.creepingLeak, Severity.medium,
          baselineDailyL, actual, ratio, zScore, nightElevated);
    }

    if (ratio > _elevatedRatio) {
      return _result(LeakSignature.seasonalSpike, Severity.low, baselineDailyL,
          actual, ratio, zScore, nightElevated);
    }

    return DetectionResult(
      isAnomaly: false,
      signature: '',
      severity: '',
      baselineL: baselineDailyL,
      actualL: actual,
      ratio: ratio,
      zScore: zScore,
      nightFlowElevated: nightElevated,
    );
  }

  bool _sustainedHigh(List<Reading> series, double baseline) {
    if (baseline == 0) return false;
    final window = series.length >= 3 ? series.sublist(series.length - 3) : series;
    return window.every((r) => r.totalDailyL / baseline > _sustainedRatio);
  }

  bool _increasingTrend(List<Reading> series) {
    if (series.length < 3) return false;
    for (var i = 1; i < series.length; i++) {
      if (series[i].totalDailyL <= series[i - 1].totalDailyL) return false;
    }
    return true;
  }

  DetectionResult _result(String signature, String severity, double baseline,
          double actual, double ratio, double z, bool nightElevated) =>
      DetectionResult(
        isAnomaly: true,
        signature: signature,
        severity: severity,
        baselineL: baseline,
        actualL: actual,
        ratio: ratio,
        zScore: z,
        nightFlowElevated: nightElevated,
      );
}
