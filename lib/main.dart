import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modules/admin/screens/abnormal_production_screen.dart';
import 'modules/admin/screens/oversight_screen.dart';

import 'modules/auth/screens/login_screen.dart';
import 'modules/auth/state/auth_state.dart' show RoleState;

import 'modules/leakage/data/leakage_repository.dart';
import 'modules/leakage/models/alert.dart' show Utility;
import 'modules/leakage/screens/home_screen.dart';
import 'modules/leakage/services/baseline_service.dart';
import 'modules/leakage/services/nrw_service.dart';
import 'modules/leakage/services/simulation_service.dart';
import 'modules/leakage/state/app_state.dart';

import 'modules/dataset/data/dataset_repository.dart';
import 'modules/dataset/screens/dashboard_screen.dart';
import 'modules/dataset/state/dataset_state.dart';

import 'modules/usage/screens/compare_usage_screen.dart';
import 'modules/usage/screens/report_problem_screen.dart';

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
          create: (_) => DatasetState(repository: DatasetRepository()),
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
              return const LoginScreen();
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
    switch (widget.userRole) {
      case 'admin':
        _screens = [
          const DashboardScreen(), // Module 1: equipment
          const AbnormalProductionScreen(), // generate abnormal-production alerts
          const OversightScreen(), // oversight + alert gate + report hide
        ];
        _tabColors = [
          Colors.teal.shade700,
          Colors.red.shade700,
          Colors.blue.shade700,
        ];
        _navItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Equipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility_outlined),
            label: 'Oversight',
          ),
        ];
        break;
      case 'worker':
        _screens = [
          const HomeScreen(utility: Utility.water),
          const HomeScreen(utility: Utility.electricity),
        ];
        _tabColors = [Colors.blue.shade700, Colors.amber.shade700];
        _navItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Water',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.electric_meter),
            label: 'Electricity',
          ),
        ];
        break;
      default:
        // Normal user
        _screens = [
          const CompareUsageScreen(),
          const ReportProblemScreen(),
        ];
        _tabColors = [Colors.blue.shade700, Colors.red.shade700];
        _navItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Compare',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            label: 'Report',
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
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: _tabColors[_currentIndex],
              items: _navItems,
            )
          : null,
    );
  }
}
