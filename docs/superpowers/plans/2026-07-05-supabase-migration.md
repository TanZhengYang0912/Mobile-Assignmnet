# Supabase Cloud Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move Module 3's operational data (readings, alerts, reports) from local sqflite to a shared Supabase (Postgres) project, while detection logic and government CSV reference data stay local.

**Architecture:** `LeakageRepository` keeps its existing public method signatures but swaps its internals from sqflite `Database` calls to `supabase_flutter` Postgrest calls. `AppState` and every screen are unaffected by the swap. The simulated role switcher (Worker/Admin) is removed in the same effort since it simplifies the security model to a single anon-key policy.

**Tech Stack:** Flutter, Dart, `supabase_flutter`, Supabase (Postgres + RLS), existing `provider` state management.

## Global Constraints

- Flutter/Dart SDK constraint stays `^3.12.2` (unchanged, from `pubspec.yaml`).
- No comments in any code — project convention, and the assignment requires all comments removed before final submission.
- RLS must be enabled on every table that holds operational data; never disabled.
- Only the Supabase anon/publishable key belongs in app code; the `service_role` key is never used client-side or committed.
- Single simulated persona ("Worker X"), no real login — this migration removes the Worker/Admin role switcher entirely.
- Only `readings`, `alerts`, `reports` move to Supabase. Government CSVs and all detection/NRW logic stay local and bundled, unchanged.
- `LeakageRepository`'s public method names and signatures do not change — only their internals.
- No offline fallback — the app requires connectivity for Module 3's cloud-backed features; failures show a clear message, never fail silently.
- Work happens on the `workerx-module3` branch, never committed directly to `main` (per the team's GitHub workflow in `README.md`).

---

### Task 1: Branch setup and Supabase schema migration

**Files:**
- None in the Flutter app (Supabase-side schema only)
- Commit: `README.md`, `.mcp.json`, `.agents/`, `skills-lock.json`, `docs/superpowers/specs/2026-07-05-supabase-migration-design.md` (already-written, currently uncommitted housekeeping from setting up Supabase tooling)

**Interfaces:**
- Produces: three Postgres tables (`public.readings`, `public.alerts`, `public.reports`) with RLS enabled and permissive anon policies, matching the exact column names used by `Alert.toMap()`/`Reading.toMap()`/`Report.toMap()` in `lib/modules/leakage/models/`. Task 5 (repository rewrite) depends on these table/column names existing exactly as created here.

- [ ] **Step 1: Create the working branch**

```bash
git checkout -b workerx-module3
```

Expected: `Switched to a new branch 'workerx-module3'`

- [ ] **Step 2: Apply the schema migration**

Call the `mcp__supabase__apply_migration` tool with:
- `name`: `create_leakage_tables`
- `query`:

```sql
create table if not exists public.readings (
  id bigint generated always as identity primary key,
  household_id text not null,
  state text not null,
  household_size integer not null,
  reading_date timestamptz not null,
  day_flow_l double precision not null,
  night_flow_l double precision not null,
  scenario text not null
);

create table if not exists public.alerts (
  id bigint generated always as identity primary key,
  reading_id bigint references public.readings (id),
  alert_type text not null check (alert_type in ('nrw_hotspot', 'household')),
  household_id text,
  state text not null,
  detected_at timestamptz not null,
  signature text not null,
  severity text not null check (severity in ('low', 'medium', 'high')),
  baseline_l double precision not null default 0,
  actual_l double precision not null default 0,
  explanation text not null,
  status text not null check (status in ('pending', 'investigating', 'resolved', 'not_fixed', 'dismissed')),
  is_deleted boolean not null default false,
  produced_mld double precision,
  billed_mld double precision,
  loss_mld double precision,
  loss_pct double precision,
  data_year integer
);

create table if not exists public.reports (
  id bigint generated always as identity primary key,
  alert_id bigint not null references public.alerts (id),
  worker_name text not null,
  findings text not null,
  action_taken text not null,
  outcome text not null check (outcome in ('fixed', 'not_fixed')),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  is_deleted boolean not null default false
);

alter table public.readings enable row level security;
alter table public.alerts enable row level security;
alter table public.reports enable row level security;

create policy "anon full access" on public.readings for all to anon using (true) with check (true);
create policy "anon full access" on public.alerts for all to anon using (true) with check (true);
create policy "anon full access" on public.reports for all to anon using (true) with check (true);
```

Expected: tool returns success, no error.

- [ ] **Step 3: Verify the tables and columns**

Call `mcp__supabase__list_tables` with `schemas: ["public"]`, `verbose: true`.

Expected: three entries — `readings`, `alerts`, `reports` — with columns matching the SQL above (18 columns on `alerts`, 8 on `readings`, 9 on `reports`).

- [ ] **Step 4: Verify RLS is enabled and policies exist**

Call `mcp__supabase__execute_sql` with:

```sql
select relname, relrowsecurity from pg_class where relname in ('readings', 'alerts', 'reports');
```

Expected: 3 rows, `relrowsecurity = true` for all.

Call `mcp__supabase__execute_sql` with:

```sql
select tablename, policyname, cmd from pg_policies where tablename in ('readings', 'alerts', 'reports');
```

Expected: 3 rows, one `"anon full access"` policy per table, `cmd = 'ALL'`.

- [ ] **Step 5: Commit the pending housekeeping files**

```bash
git add README.md .mcp.json .agents skills-lock.json docs/superpowers/specs/2026-07-05-supabase-migration-design.md
git commit -m "Add Supabase MCP tooling, cloud migration spec, and schema"
```

Expected: commit succeeds with the 5 paths listed.

---

### Task 2: Add supabase_flutter and initialize the client

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `Supabase.instance.client` (a `SupabaseClient`), available globally after `Supabase.initialize()` runs in `main()`. Task 5 (`LeakageRepository`) consumes this via `Supabase.instance.client`.

This task is purely additive — `sqflite` stays for now so the app keeps compiling and running exactly as before; it is removed in Task 5 once nothing references it.

- [ ] **Step 1: Add the dependency**

Edit `pubspec.yaml`, in the `dependencies:` block add:

```yaml
  supabase_flutter: ^2.9.0
```

- [ ] **Step 2: Run pub get**

```bash
flutter pub get
```

Expected: `Got dependencies!` with `supabase_flutter` and its transitive deps listed as added.

- [ ] **Step 3: Initialize the client in main.dart**

Replace the full contents of `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modules/leakage/data/leakage_repository.dart';
import 'modules/leakage/screens/home_screen.dart';
import 'modules/leakage/services/baseline_service.dart';
import 'modules/leakage/services/nrw_service.dart';
import 'modules/leakage/services/simulation_service.dart';
import 'modules/leakage/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tnmznkdvrrpigevxdfet.supabase.co',
    anonKey: 'sb_publishable_rPQeDFFfv1HQoYnqN2g9QQ_bLBVlaZE',
  );
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
```

- [ ] **Step 4: Verify it compiles and runs**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "Add supabase_flutter and initialize the client"
```

---

### Task 3: Remove the simulated role switcher and dead dismiss workflow

**Files:**
- Modify: `lib/modules/leakage/state/app_state.dart`
- Modify: `lib/modules/leakage/screens/home_screen.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `AppState` with no `UserRole`, `role`, `isAdmin`, `switchRole`, or `dismissAlert` members. Task 5 (repository rewrite) relies on nothing in the new repository needing a `dismissAlert` method, since no caller exists after this task.

Doing this before the repository rewrite (Task 5) means the new Supabase-backed repository never needs a `dismissAlert` method at all — there is no caller left by the time it's written.

- [ ] **Step 1: Remove role/admin/dismiss from AppState**

In `lib/modules/leakage/state/app_state.dart`, remove the `UserRole` enum (lines 11-17), the `_role` field, the `role` and `isAdmin` getters, the `switchRole` method, and the `dismissAlert` method. The file becomes:

```dart
import 'package:flutter/foundation.dart';

import '../data/leakage_repository.dart';
import '../models/alert.dart';
import '../models/report.dart';
import '../services/baseline_service.dart';
import '../services/explainer.dart';
import '../services/nrw_service.dart';
import '../services/simulation_service.dart';

class AppState extends ChangeNotifier {
  final BaselineService baseline;
  final NrwService nrw;
  final LeakageRepository repository;
  final SimulationService simulation;
  final Explainer explainer;

  List<Alert> _alerts = [];
  List<Report> _reports = [];
  bool _loading = true;

  AppState({
    required this.baseline,
    required this.nrw,
    required this.repository,
    required this.simulation,
    Explainer? explainer,
  }) : explainer = explainer ?? Explainer();

  String get workerName => 'Worker X';
  List<Alert> get alerts => _alerts;
  List<Report> get reports => _reports;
  bool get loading => _loading;

  List<Alert> get unresolvedAlerts =>
      _bySeverity(_alerts.where((a) => a.isUnresolved));
  List<Alert> get resolvedAlerts =>
      _bySeverity(_alerts.where((a) => a.status == AlertStatus.resolved));

  static const _severityRank = {
    Severity.high: 3,
    Severity.medium: 2,
    Severity.low: 1,
  };

  double _magnitude(Alert a) => a.isNrw ? (a.lossPct ?? 0) : a.ratio;

  List<Alert> _bySeverity(Iterable<Alert> source) {
    final list = source.toList();
    list.sort((a, b) {
      final rank = (_severityRank[b.severity] ?? 0)
          .compareTo(_severityRank[a.severity] ?? 0);
      if (rank != 0) return rank;
      return _magnitude(b).compareTo(_magnitude(a));
    });
    return list;
  }

  Future<void> init() async {
    await baseline.load();
    await nrw.load();
    await refresh();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _alerts = await repository.alerts(includeDismissed: false);
    _reports = await repository.reports();
    notifyListeners();
  }

  Future<int> runAnalysis() async {
    final existing = await repository.nrwAlertStates();
    final results = nrw.analyse();
    var added = 0;
    for (final r in results) {
      if (existing.contains(r.state)) continue;
      final alert = Alert(
        alertType: AlertType.nrwHotspot,
        state: r.state,
        detectedAt: DateTime.now(),
        signature: LeakSignature.nrwHotspot,
        severity: r.severity,
        explanation: explainer.describeNrw(r, nrw.nationalLossPct),
        producedMld: r.producedMld,
        billedMld: r.billedMld,
        lossMld: r.lossMld,
        lossPct: r.lossPct,
        dataYear: r.year,
      );
      await repository.insertAlert(alert);
      added++;
    }
    await refresh();
    return added;
  }

  Future<SimulationOutcome> simulate(LeakScenario scenario, String state) async {
    final outcome = await simulation.run(scenario, state);
    await refresh();
    return outcome;
  }

  Future<void> updateAlertStatus(int alertId, String status) async {
    await repository.updateAlertStatus(alertId, status);
    await refresh();
  }

  Future<void> saveReport(Report report) async {
    if (report.id == null) {
      await repository.insertReport(report);
    } else {
      await repository.updateReport(report);
    }
    await refresh();
  }

  Future<void> deleteReport(int reportId) async {
    await repository.deleteReport(reportId);
    await refresh();
  }
}
```

- [ ] **Step 2: Remove the role dropdown from home_screen.dart**

In `lib/modules/leakage/screens/home_screen.dart`, remove the `actions: [...]` block from the `AppBar` (the `DropdownButton<UserRole>` and its surrounding `Padding`), leaving:

```dart
      appBar: AppBar(
        title: const Text('Water leakage detection'),
      ),
```

- [ ] **Step 3: Verify no references remain**

```bash
grep -rn "UserRole\|isAdmin\|switchRole\|dismissAlert" lib/
```

Expected: no output.

- [ ] **Step 4: Verify it compiles**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/modules/leakage/state/app_state.dart lib/modules/leakage/screens/home_screen.dart
git commit -m "Remove simulated role switcher and dead dismiss workflow"
```

---

### Task 4: Fix Alert/Report boolean serialization for Postgres

**Files:**
- Modify: `lib/modules/leakage/models/alert.dart`
- Modify: `lib/modules/leakage/models/report.dart`
- Test: `test/model_serialization_test.dart` (new)

**Interfaces:**
- Consumes: nothing new.
- Produces: `Alert.toMap()`/`Alert.fromMap()` and `Report.toMap()`/`Report.fromMap()` using real Dart `bool` values for `is_deleted`, not `1`/`0` integers. Task 5 (repository) depends on this — Postgrest sends/receives JSON booleans, not SQLite-style integers.

sqflite stores booleans as `0`/`1` integers, which is why the current models convert `isDeleted` to `1`/`0`. Supabase's REST API (Postgrest) works with a real Postgres `boolean` column and expects/returns JSON `true`/`false`. Sending `1` would fail the column's type.

- [ ] **Step 1: Write the failing test**

Create `test/model_serialization_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mysumber/modules/leakage/models/alert.dart';
import 'package:mysumber/modules/leakage/models/report.dart';

void main() {
  test('Alert toMap/fromMap round-trips is_deleted as a real boolean', () {
    final alert = Alert(
      alertType: AlertType.nrwHotspot,
      state: 'Perlis',
      detectedAt: DateTime(2026, 7, 5),
      signature: LeakSignature.nrwHotspot,
      severity: Severity.high,
      explanation: 'test',
      isDeleted: true,
    );
    final map = alert.toMap();
    expect(map['is_deleted'], isA<bool>());
    expect(map['is_deleted'], isTrue);
    final restored = Alert.fromMap(map);
    expect(restored.isDeleted, isTrue);
  });

  test('Report toMap/fromMap round-trips is_deleted as a real boolean', () {
    final report = Report(
      alertId: 1,
      workerName: 'Worker X',
      findings: 'findings',
      actionTaken: 'action',
      outcome: ReportOutcome.fixed,
      createdAt: DateTime(2026, 7, 5),
      updatedAt: DateTime(2026, 7, 5),
      isDeleted: true,
    );
    final map = report.toMap();
    expect(map['is_deleted'], isA<bool>());
    expect(map['is_deleted'], isTrue);
    final restored = Report.fromMap(map);
    expect(restored.isDeleted, isTrue);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/model_serialization_test.dart
```

Expected: FAIL — `map['is_deleted']` is `1` (an `int`), not `true` (a `bool`), so `isA<bool>()` fails.

- [ ] **Step 3: Fix Alert's serialization**

In `lib/modules/leakage/models/alert.dart`, in `toMap()` change:

```dart
        'is_deleted': isDeleted ? 1 : 0,
```

to:

```dart
        'is_deleted': isDeleted,
```

In `fromMap()` change:

```dart
        isDeleted: (map['is_deleted'] as int) == 1,
```

to:

```dart
        isDeleted: map['is_deleted'] as bool,
```

- [ ] **Step 4: Fix Report's serialization**

In `lib/modules/leakage/models/report.dart`, in `toMap()` change:

```dart
        'is_deleted': isDeleted ? 1 : 0,
```

to:

```dart
        'is_deleted': isDeleted,
```

In `fromMap()` change:

```dart
        isDeleted: (map['is_deleted'] as int) == 1,
```

to:

```dart
        isDeleted: map['is_deleted'] as bool,
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
flutter test test/model_serialization_test.dart
```

Expected: `+2: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/modules/leakage/models/alert.dart lib/modules/leakage/models/report.dart test/model_serialization_test.dart
git commit -m "Serialize is_deleted as a real boolean for Postgres"
```

---

### Task 5: Rewrite LeakageRepository against Supabase and delete the local SQLite layer

**Files:**
- Modify: `lib/modules/leakage/data/leakage_repository.dart`
- Delete: `lib/modules/leakage/data/leakage_database.dart`
- Modify: `pubspec.yaml` (remove `sqflite`, `path`, `path_provider`)

**Interfaces:**
- Consumes: `Supabase.instance.client` (from Task 2), `Alert.toMap()`/`fromMap()` and `Report.toMap()`/`fromMap()` with real booleans (from Task 4).
- Produces: `LeakageRepository` with the exact same public method names/signatures as before (`insertReading`, `insertAlert`, `alerts({includeDismissed})`, `alertById`, `updateAlertStatus`, `insertReport`, `updateReport`, `deleteReport`, `nrwAlertStates`, `reports`, `reportForAlert`) so `AppState` (already updated in Task 3) needs no further changes.

- [ ] **Step 1: Rewrite the repository**

Replace the full contents of `lib/modules/leakage/data/leakage_repository.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alert.dart';
import '../models/reading.dart';
import '../models/report.dart';

class LeakageRepository {
  final SupabaseClient _client;

  LeakageRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<int> insertReading(Reading reading) async {
    final row = await _client
        .from('readings')
        .insert(reading.toMap()..remove('id'))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<int> insertAlert(Alert alert) async {
    final row = await _client
        .from('alerts')
        .insert(alert.toMap()..remove('id'))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<List<Alert>> alerts({bool includeDismissed = true}) async {
    var query = _client.from('alerts').select().eq('is_deleted', false);
    if (!includeDismissed) {
      query = query.neq('status', AlertStatus.dismissed);
    }
    final rows = await query.order('detected_at', ascending: false);
    return rows.map((row) => Alert.fromMap(row)).toList();
  }

  Future<Alert?> alertById(int id) async {
    final row =
        await _client.from('alerts').select().eq('id', id).maybeSingle();
    return row == null ? null : Alert.fromMap(row);
  }

  Future<void> updateAlertStatus(int id, String status) async {
    await _client.from('alerts').update({'status': status}).eq('id', id);
  }

  Future<int> insertReport(Report report) async {
    final row = await _client
        .from('reports')
        .insert(report.toMap()..remove('id'))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateReport(Report report) async {
    await _client
        .from('reports')
        .update(report.toMap()..remove('id'))
        .eq('id', report.id!);
  }

  Future<void> deleteReport(int id) async {
    await _client.from('reports').update({'is_deleted': true}).eq('id', id);
  }

  Future<Set<String>> nrwAlertStates() async {
    final rows = await _client
        .from('alerts')
        .select('state')
        .eq('alert_type', AlertType.nrwHotspot)
        .eq('is_deleted', false);
    return rows.map((row) => row['state'] as String).toSet();
  }

  Future<List<Report>> reports() async {
    final rows = await _client
        .from('reports')
        .select()
        .eq('is_deleted', false)
        .order('updated_at', ascending: false);
    return rows.map((row) => Report.fromMap(row)).toList();
  }

  Future<Report?> reportForAlert(int alertId) async {
    final rows = await _client
        .from('reports')
        .select()
        .eq('alert_id', alertId)
        .eq('is_deleted', false)
        .order('updated_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : Report.fromMap(rows.first);
  }
}
```

- [ ] **Step 2: Delete the local database file**

```bash
rm lib/modules/leakage/data/leakage_database.dart
```

- [ ] **Step 3: Remove the now-unused local storage dependencies**

Edit `pubspec.yaml`, remove these three lines from `dependencies:`:

```yaml
  sqflite: ^2.4.2
  path: ^1.9.1
  path_provider: ^2.1.5
```

- [ ] **Step 4: Update dependencies and verify it compiles**

```bash
flutter pub get
flutter analyze
```

Expected: `Got dependencies!` then `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/modules/leakage/data/leakage_repository.dart pubspec.yaml pubspec.lock
git rm lib/modules/leakage/data/leakage_database.dart
git commit -m "Rewrite LeakageRepository against Supabase, remove local SQLite layer"
```

---

### Task 6: Add network error handling to mutating screen actions

**Files:**
- Create: `lib/modules/leakage/screens/network_error.dart`
- Modify: `lib/modules/leakage/screens/home_screen.dart`
- Modify: `lib/modules/leakage/screens/alert_detail_screen.dart`
- Modify: `lib/modules/leakage/screens/report_form_screen.dart`

**Interfaces:**
- Consumes: existing `AppState` methods (`runAnalysis`, `simulate`, `updateAlertStatus`, `saveReport`, `deleteReport`) — unchanged signatures.
- Produces: `showNetworkErrorSnackBar(BuildContext context)`, a shared helper used by all three screens so the failure message and its wording exist in exactly one place.

Since the app now requires connectivity with no offline fallback, every mutating action needs to fail visibly rather than silently. Read-only failures (e.g. `refresh()` failing after `init()`) are out of scope for this task — only user-triggered actions.

- [ ] **Step 1: Create the shared error-snackbar helper**

Create `lib/modules/leakage/screens/network_error.dart`:

```dart
import 'package:flutter/material.dart';

void showNetworkErrorSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text("Couldn't reach the server. Check your connection and try again."),
  ));
}
```

- [ ] **Step 2: Wrap the two actions in home_screen.dart**

In `lib/modules/leakage/screens/home_screen.dart`, add `import 'network_error.dart';` to the imports, then change `_runAnalysis`:

```dart
  Future<void> _runAnalysis(AppState app) async {
    setState(() => _analysing = true);
    try {
      final added = await app.runAnalysis();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added == 0
            ? 'No new hotspots — all flagged states already in the queue.'
            : 'Flagged $added leaking state(s) from real data.'),
        backgroundColor: added == 0 ? Colors.blueGrey : Colors.red.shade600,
      ));
    } catch (_) {
      if (mounted) showNetworkErrorSnackBar(context);
    } finally {
      if (mounted) setState(() => _analysing = false);
    }
  }
```

And `_simulate`:

```dart
  Future<void> _simulate(AppState app, LeakScenario scenario) async {
    try {
      final outcome = await app.simulate(scenario, _selectedState);
      if (!mounted) return;
      final message = outcome.anomalyRaised
          ? 'Alert raised: ${outcome.result.signature} '
              '(${outcome.result.severity}, ${outcome.result.ratio.toStringAsFixed(1)}× average)'
          : 'No anomaly: usage within normal range '
              '(${outcome.result.ratio.toStringAsFixed(1)}× average)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: outcome.anomalyRaised
            ? Colors.red.shade600
            : Colors.green.shade600,
      ));
    } catch (_) {
      if (mounted) showNetworkErrorSnackBar(context);
    }
  }
```

- [ ] **Step 3: Wrap the status action in alert_detail_screen.dart**

In `lib/modules/leakage/screens/alert_detail_screen.dart`, add `import 'network_error.dart';` to the imports. The `_actions` method calls `app.updateAlertStatus(...)` directly as an `onPressed` callback via `_primary(...)`. Add a wrapper method and use it in place of the direct calls:

```dart
  Future<void> _updateStatus(
      BuildContext context, AppState app, int alertId, String status) async {
    try {
      await app.updateAlertStatus(alertId, status);
    } catch (_) {
      if (context.mounted) showNetworkErrorSnackBar(context);
    }
  }
```

Replace each `() => app.updateAlertStatus(alert.id!, AlertStatus.investigating)` (there are two — pending→investigating and notFixed→investigating) with `() => _updateStatus(context, app, alert.id!, AlertStatus.investigating)`.

- [ ] **Step 4: Wrap save/delete in report_form_screen.dart**

In `lib/modules/leakage/screens/report_form_screen.dart`, add `import 'network_error.dart';` to the imports, then wrap the body of `_save`:

```dart
  Future<void> _save(AppState app) async {
    if (_outcome == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select an outcome before saving.')));
      return;
    }
    final now = DateTime.now();
    final report = (widget.existing ??
            Report(
              alertId: widget.alert.id!,
              workerName: app.workerName,
              findings: '',
              actionTaken: '',
              outcome: _outcome!,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
      findings: _findings.text.trim(),
      actionTaken: _action.text.trim(),
      outcome: _outcome,
      updatedAt: now,
    );
    try {
      await app.saveReport(report);
      await app.updateAlertStatus(
          widget.alert.id!,
          _outcome == ReportOutcome.fixed
              ? AlertStatus.resolved
              : AlertStatus.notFixed);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showNetworkErrorSnackBar(context);
    }
  }
```

And `_delete`:

```dart
  Future<void> _delete(AppState app) async {
    try {
      await app.deleteReport(widget.existing!.id!);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showNetworkErrorSnackBar(context);
    }
  }
```

- [ ] **Step 5: Verify it compiles**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/modules/leakage/screens/network_error.dart lib/modules/leakage/screens/home_screen.dart lib/modules/leakage/screens/alert_detail_screen.dart lib/modules/leakage/screens/report_form_screen.dart
git commit -m "Show a clear message when a Supabase call fails"
```

---

### Task 7: End-to-end verification against the live app and database

**Files:** None — verification only.

**Interfaces:** None produced; this task consumes the fully migrated app from Tasks 1-6.

- [ ] **Step 1: Run the app**

```bash
flutter run
```

Expected: app launches to the home screen with no role dropdown, no crash on startup (confirms `Supabase.initialize` succeeded).

- [ ] **Step 2: Trigger a household simulation**

In the running app, tap **Continuous leak** under "Simulate a household reading". Expected: a SnackBar reporting an alert was raised.

- [ ] **Step 3: Trigger the NRW analysis**

Tap **Run leakage analysis**. Expected: a SnackBar reporting some number of flagged states (or "No new hotspots" if run twice).

- [ ] **Step 4: Confirm both alerts independently via Supabase**

Call `mcp__supabase__execute_sql` with:

```sql
select id, alert_type, state, severity, status from public.alerts order by id desc limit 5;
```

Expected: rows for both the household alert (`alert_type = 'household'`) and NRW alerts (`alert_type = 'nrw_hotspot'`) just created, `status = 'pending'`.

- [ ] **Step 5: Complete the investigate → report → resolved flow**

In the app, open the household alert, tap **Start investigation**, then **Write report**, fill in findings/action, choose **Fixed**, save. Expected: back on the queue, the alert now appears under the Resolved tab.

- [ ] **Step 6: Confirm the resolution independently via Supabase**

```sql
select a.id, a.status, r.outcome, r.findings from public.alerts a join public.reports r on r.alert_id = a.id order by a.id desc limit 1;
```

Expected: one row, `status = 'resolved'`, `outcome = 'fixed'`, `findings` matching what was typed in the app.

---

### Task 8: Push the branch and open a pull request

**Files:** None.

**Interfaces:** None.

- [ ] **Step 1: Push the branch**

```bash
git push -u origin workerx-module3
```

Expected: `workerx-module3` created on the remote.

- [ ] **Step 2: Open the pull request**

```bash
gh pr create --title "Module 3: migrate alerts/reports/readings to Supabase" --body "$(cat <<'EOF'
## Summary
- Moves readings/alerts/reports from local sqflite to a shared Supabase (Postgres) project with RLS
- Removes the simulated Worker/Admin role switcher (single persona for now)
- Government CSVs and detection/NRW logic remain local and unchanged

## Test plan
- [ ] flutter analyze — no issues
- [ ] flutter test — all tests pass
- [ ] Manual: simulate a reading and run leakage analysis, confirm alerts appear in-app and in Supabase
- [ ] Manual: investigate → write report → resolved, confirm status/outcome match in Supabase
EOF
)"
```

Expected: PR URL printed; this is the first real PR into `main` for the team to review, matching the workflow documented in `README.md`.

---

## Parked (not in this plan, unchanged from the design spec)

- Dismiss / false-positive workflow — return before final submission to keep the alert CRUD story complete.
- Real authentication and per-role RLS — only if the module's scope grows beyond the assignment's fake-data allowance.
