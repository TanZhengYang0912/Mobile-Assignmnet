import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'modules/leakage/data/leakage_repository.dart';
import 'modules/leakage/screens/home_screen.dart';
import 'modules/leakage/services/baseline_service.dart';
import 'modules/leakage/services/nrw_service.dart';
import 'modules/leakage/services/simulation_service.dart';
import 'modules/leakage/state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MySumberApp());
}

class MySumberApp extends StatelessWidget {
  const MySumberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) {
        final baseline = BaselineService();
        final nrw = NrwService();
        final repository = LeakageRepository();
        final simulation = SimulationService(
          baseline: baseline,
          repository: repository,
        );
        final state = AppState(
          baseline: baseline,
          nrw: nrw,
          repository: repository,
          simulation: simulation,
        );
        state.init();
        return state;
      },
      child: MaterialApp(
        title: 'mySumber',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
