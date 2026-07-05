import 'package:flutter/foundation.dart';

import '../models/electricity_models.dart';
import '../services/electricity_data_service.dart';

class ElectricityState extends ChangeNotifier {
  final ElectricityDataService _dataService = ElectricityDataService();

  List<ElectricityRecord> records = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      records = await _dataService.loadRecords();
    } catch (e) {
      debugPrint('Error loading electricity data: $e');
      errorMessage = 'Failed to load datasets. Ensure assets are bundled correctly.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<ElectricityRecord> get anomalies => 
      records.where((r) => r.isAnomaly).toList();
}
