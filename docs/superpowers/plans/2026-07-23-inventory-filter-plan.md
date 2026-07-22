# Inventory Location and Status Filters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add clear, cascading State → Shopping Mall filters and a single-select equipment status filter to the Admin Inventory page.

**Architecture:** Keep filter state local to `InventoryScreen`, extract the list filtering/counting rules into a small pure helper, and continue using `DatasetState.nodes` as the source of truth. Reuse the existing `DashboardScreen.onStateTap` and `InventoryScreen.initialState` bridge so Dashboard navigation can seed the State dropdown.

**Tech Stack:** Flutter/Dart, Provider, Material 3 widgets, `flutter_test`.

## Global Constraints

- No new persistence or database schema; use existing `EquipmentNode` fields: `zoneId`, `facilityName`, `utilityType`, and `status`.
- Do not modify Oversight, Module 2, Module 3, or Module 4.
- Status filtering is single-select; do not add multi-select behavior.
- Preserve existing search, CRUD, import, delete, and equipment-detail behavior.
- Use TDD: write each behavior test, run it failing, implement the minimum behavior, then rerun it passing.

---

### Task 1: Add pure Inventory filter rules

**Files:**
- Create: `lib/modules/dataset/services/inventory_filter.dart`
- Modify: `test/dataset_facility_test.dart`

**Interfaces:**
- Produces `InventoryFilterResult filterEquipmentNodes({required Iterable<EquipmentNode> nodes, String state = 'All', String facility = 'All', String utility = 'All', String status = 'All', String query = ''})`.
- Produces `List<String> facilitiesForState(Iterable<EquipmentNode> nodes, String state)`.
- `InventoryFilterResult.nodes` is the filtered `List<EquipmentNode>`.
- `InventoryFilterResult.utilityCounts` and `statusCounts` are `Map<String, int>` counts for the filtered location/search scope, before applying the corresponding utility/status chip.

- [ ] **Step 1: Write failing tests for the filter contract**

Add tests covering the exact seeded data behavior:

```dart
test('filters Selangor to its nine equipment nodes', () async {
  final nodes = await DatasetRepository().fetchNodes();
  final result = filterEquipmentNodes(nodes: nodes, state: 'Selangor');

  expect(result.nodes, hasLength(9));
});

test('filters a Selangor mall to its three core equipment nodes', () async {
  final nodes = await DatasetRepository().fetchNodes();
  final result = filterEquipmentNodes(
    nodes: nodes,
    state: 'Selangor',
    facility: '1 Utama Shopping Centre',
  );

  expect(result.nodes, hasLength(3));
});

test('lists only facilities belonging to the selected state', () async {
  final nodes = await DatasetRepository().fetchNodes();

  expect(
    facilitiesForState(nodes, 'Selangor'),
    <String>[
      '1 Utama Shopping Centre',
      'Setia City Mall',
      'Sunway Pyramid',
    ],
  );
});
```

- [ ] **Step 2: Run the focused tests and verify the expected failure**

Run:

```bash
/Users/tanzhengyang/development/flutter/bin/flutter test test/dataset_facility_test.dart
```

Expected: compilation failure because `inventory_filter.dart` and its functions do not exist yet.

- [ ] **Step 3: Implement the minimal pure filter helper**

Create the helper with these rules:

```dart
class InventoryFilterResult {
  final List<EquipmentNode> nodes;
  final Map<String, int> utilityCounts;
  final Map<String, int> statusCounts;

  const InventoryFilterResult({
    required this.nodes,
    required this.utilityCounts,
    required this.statusCounts,
  });
}
```

Apply State, Facility, and case-insensitive search first. Build utility/status counts from that location/search result, then apply the selected utility and status to produce `nodes`. `facilitiesForState` must return sorted unique facility names, or all sorted facilities when state is `All`.

- [ ] **Step 4: Run the focused tests and verify they pass**

Run the same command. Expected: all existing facility tests and the new filter tests pass.

- [ ] **Step 5: Commit the filter helper**

```bash
git add lib/modules/dataset/services/inventory_filter.dart test/dataset_facility_test.dart
git commit -m "Add inventory filter rules"
```

### Task 2: Add cascading State and Shopping Mall controls

**Files:**
- Modify: `lib/modules/dataset/screens/inventory_screen.dart`
- Modify: `test/dataset_facility_test.dart`

**Interfaces:**
- Keep `InventoryScreen({super.key, this.initialState})` and initialize `_selectedState` from `initialState`.
- Add local `_selectedFacility`, `_selectedUtility`, and `_selectedStatus` values, each defaulting to `All`.
- The State dropdown consumes `facilitiesForState(state.nodes, _selectedState)` through the helper from Task 1.

- [ ] **Step 1: Add a widget test for the cascade**

Pump `InventoryScreen(initialState: 'Selangor')` with a `DatasetState` provider whose `stateWaterSupply` is pre-populated so the test does not wait for CSV aggregation. Set the test view large enough to render the controls, then assert:

```dart
expect(find.text('State: Selangor'), findsOneWidget);
expect(find.text('All Shopping Malls'), findsOneWidget);
```

Tap the State dropdown, select `Johor`, and assert that the mall selection returns to `All Shopping Malls`.

- [ ] **Step 2: Run the widget test and verify it fails**

Run:

```bash
/Users/tanzhengyang/development/flutter/bin/flutter test test/dataset_facility_test.dart --plain-name "inventory can open with a selected state filter"
```

Expected: failure because the new dropdown controls are not present.

- [ ] **Step 3: Implement the cascading controls**

Add a location section below the utility chips:

```dart
DropdownButtonFormField<String>(
  value: _selectedState,
  items: stateOptions.map(_stateMenuItem).toList(),
  onChanged: (value) {
    setState(() {
      _selectedState = value ?? 'All';
      _selectedFacility = 'All';
    });
  },
)
```

Use the selected state to build the mall items. Disable the mall dropdown only when there are no facilities, and always include `All Shopping Malls` as the first option. Keep the existing `initialState` path used by Dashboard.

- [ ] **Step 4: Run the widget test and verify it passes**

Run the focused command again. Expected: the State dropdown displays the incoming state, the mall dropdown lists only that state's malls, and changing State clears the mall.

- [ ] **Step 5: Commit the location controls**

```bash
git add lib/modules/dataset/screens/inventory_screen.dart test/dataset_facility_test.dart
git commit -m "Add cascading inventory location filters"
```

### Task 3: Add single-select Status chips and dynamic counts

**Files:**
- Modify: `lib/modules/dataset/screens/inventory_screen.dart`
- Modify: `test/dataset_facility_test.dart`

**Interfaces:**
- Status values are exactly `All`, `Active`, `Warning`, `Critical`, and `Maintenance`.
- Chips update `_selectedStatus` and use `InventoryFilterResult.statusCounts`.
- Utility chips continue using `InventoryFilterResult.utilityCounts` and existing labels.

- [ ] **Step 1: Add failing tests for status filtering and combined filters**

Add tests for the pure helper or widget behavior:

```dart
test('combines state, mall, utility, and status filters', () async {
  final nodes = await DatasetRepository().fetchNodes();
  final result = filterEquipmentNodes(
    nodes: nodes,
    state: 'Selangor',
    facility: '1 Utama Shopping Centre',
    utility: 'Water',
    status: 'Active',
  );

  expect(result.nodes, hasLength(1));
  expect(result.nodes.single.nodeName, 'Main Water Pump A1');
});
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run the focused test command. Expected: failure until status and combined filtering are implemented.

- [ ] **Step 3: Implement the status chips and counts**

Render a horizontally scrollable status chip row after the location controls. Keep status single-select, highlight only the selected chip, and show counts from the location/search scope. Keep utility chips above the location controls and update their counts from the same result object.

- [ ] **Step 4: Run the focused tests and verify they pass**

Run the focused test file. Expected: status-only and combined-filter tests pass.

- [ ] **Step 5: Commit the status controls**

```bash
git add lib/modules/dataset/screens/inventory_screen.dart test/dataset_facility_test.dart
git commit -m "Add inventory status filters"
```

### Task 4: Add clear-filters behavior and preserve Dashboard navigation

**Files:**
- Modify: `lib/modules/dataset/screens/inventory_screen.dart`
- Modify: `lib/main.dart`
- Modify: `lib/modules/dataset/screens/dashboard_screen.dart`
- Modify: `test/dataset_facility_test.dart`

**Interfaces:**
- Add `_clearFilters()` that resets State, Mall, Utility, Status, search text, and `_searchQuery` to their `All`/empty defaults.
- Preserve `DashboardScreen.onStateTap` and `AppShell._openInventoryForState` behavior from the previous commit.

- [ ] **Step 1: Add failing tests for clear filters and Dashboard entry**

Verify the widget test can start at `Selangor`, select `1 Utama Shopping Centre` and `Critical`, tap `Clear filters`, and observe the default selections. Keep the existing test that validates `InventoryScreen(initialState: 'Selangor')`.

- [ ] **Step 2: Run the focused tests and verify the failure**

Run:

```bash
/Users/tanzhengyang/development/flutter/bin/flutter test test/dataset_facility_test.dart
```

Expected: clear-filters assertion fails before the reset action exists.

- [ ] **Step 3: Implement clear filters and empty state behavior**

Add a visible `Clear filters` action near the filter controls. It must reset the controllers and call `setState`. Feed the resulting filtered list into the existing equipment card list; if it is empty, preserve the current no-results message.

- [ ] **Step 4: Run all verification commands**

```bash
/Users/tanzhengyang/development/flutter/bin/flutter test
/Users/tanzhengyang/development/flutter/bin/flutter analyze lib/main.dart lib/modules/dataset
git diff --check
```

Expected: all tests pass, the targeted analyzer reports no issues, and `git diff --check` is silent.

- [ ] **Step 5: Commit the complete Inventory filter flow**

```bash
git add lib/main.dart lib/modules/dataset/screens/dashboard_screen.dart lib/modules/dataset/screens/inventory_screen.dart test/dataset_facility_test.dart
git commit -m "Complete inventory location and status filters"
```

## Plan Self-Review

- Spec coverage: location cascade, dynamic utility/status counts, single-select status, clear filters, Dashboard state entry, empty state, test coverage, and module boundaries are all assigned to Tasks 1–4.
- Placeholder scan: all steps contain concrete commands, code, and expected outputs.
- Type consistency: `InventoryFilterResult`, `filterEquipmentNodes`, and `facilitiesForState` are introduced in Task 1 and consumed with the same signatures in Tasks 2–4.
- Scope check: all implementation files remain in Module 1 plus the existing shared Dashboard/AppShell bridge required for state navigation.
