import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modules/auth/screens/role_selection_screen.dart';
import 'modules/auth/state/auth_state.dart' show RoleState;

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

import 'modules/usage/screens/work_in_progress_screen.dart';

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
        ChangeNotifierProvider<RoleState>(
          create: (_) {
            final roleState = RoleState();
            roleState.checkExistingSession();
            return roleState;
          },
        ),
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
        home: Consumer<RoleState>(
          builder: (BuildContext context, RoleState authState, Widget? _) {
            if (authState.isLoggedIn) {
              return AppShell(userRole: authState.userRole!);
            } else {
              return const RoleSelectionScreen();
            }
          },
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final String userRole;

  const AppShell({super.key, required this.userRole});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;
  late final List<Color> _tabColors;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _setupScreensByRole();
  }

  void _setupScreensByRole() {
    if (widget.userRole == 'admin') {
      _screens = [
        const DashboardScreen(), // Module 1
        const HomeScreen(), // Module 3
        const ElectricityDashboardScreen(), // Module 4
      ];
      _tabColors = [
        Colors.teal.shade700,
        Colors.blue.shade700,
        Colors.amber.shade700,
      ];
      _navItems = const [
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
      ];
    } else {
      // Consumer role
      _screens = [
        const WorkInProgressScreen(), // Module 2
      ];
      _tabColors = [

        Colors.blue.shade700,
      ];
      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'My Usage',
        ),
      ];
    }
  }

  void _logout() {
    context.read<RoleState>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('mySumber - ${widget.userRole.toUpperCase()}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: _navItems.length > 1
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: _tabColors[_currentIndex],
              items: _navItems,
            )
          : null,
    );
  }
}
