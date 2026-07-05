import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modules/leakage/data/leakage_repository.dart';
import 'modules/leakage/screens/home_screen.dart';
import 'modules/leakage/services/baseline_service.dart';
import 'modules/leakage/services/nrw_service.dart';
import 'modules/leakage/services/simulation_service.dart';
import 'modules/leakage/state/app_state.dart';

import 'modules/dataset/data/dataset_repository.dart';
import 'modules/dataset/screens/dashboard_screen.dart';
import 'modules/dataset/state/dataset_state.dart';

import 'modules/electricity/screens/electricity_dashboard.dart';
import 'modules/electricity/state/electricity_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tnmznkdvrrpigevxdfet.supabase.co',
    publishableKey: 'sb_publishable_rPQeDFFfv1HQoYnqN2g9QQ_bLBVlaZE',
  );
  runApp(const MySumberApp());
}

class MySumberApp extends StatelessWidget {
  const MySumberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
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
        ),
        ChangeNotifierProvider<DatasetState>(
          create: (context) {
            final leakageRepo = context.read<AppState>().repository;
            final repository = DatasetRepository(leakageRepo: leakageRepo);
            return DatasetState(repository: repository);
          },
        ),
        ChangeNotifierProvider<ElectricityState>(
          create: (_) => ElectricityState(),
        ),
      ],
      child: MaterialApp(
        title: 'mySumber',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey.shade50,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 1,
            centerTitle: false,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(), // Module 1
    const HomeScreen(), // Module 3
    const ElectricityDashboardScreen(), // Module 4
  ];

  static final List<Color> _tabColors = [
    Colors.teal.shade700, // Module 1
    Colors.blue.shade700, // Module 3
    Colors.amber.shade700, // Module 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: _tabColors[_currentIndex],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Equipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Leakage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.electric_meter),
            label: 'Electricity',
          ),
        ],
      ),
    );
  }
}
