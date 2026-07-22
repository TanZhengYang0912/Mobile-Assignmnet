# Inventory Location and Status Filters

## Goal

Improve the Admin Inventory filtering experience so equipment can be located in the hierarchy:

```text
State / Federal Territory → Shopping Mall → Equipment → Status
```

The design follows the existing Oversight filtering pattern while keeping the Inventory page usable with 26 malls and 78 seeded equipment nodes.

## Scope

In scope:

- Inventory filtering by utility type, state/federal territory, shopping mall, and equipment status.
- Cascading State and Shopping Mall dropdowns.
- Single-select equipment status chips.
- Dynamic counts and a clear-filters action.
- Passing a selected state from Dashboard into Inventory.

Out of scope:

- Supabase changes.
- Changes to Oversight, Module 2, Module 3, or Module 4.
- Changes to anomaly detection or loss calculations.
- Multi-select status filters.

## User Interface

Inventory keeps the existing search field and utility chips, then adds location and status controls:

```text
Search equipment...

Utility
[All] [Water] [Electricity]

Location
[All States ▼] [All Shopping Malls ▼]

Status
[All] [Active] [Warning] [Critical] [Maintenance]

Clear filters
```

Rules:

1. The default state is `All States`, and the default mall is `All Shopping Malls`.
2. Selecting a state limits the mall dropdown to malls in that state.
3. Changing the state resets the mall to `All Shopping Malls`.
4. Selecting a mall limits the list to that mall's equipment.
5. Utility and status remain single-select filters and can be combined with location filters.
6. Filter counts update from the current result set.
7. `Clear filters` restores all filters and the complete equipment list.
8. If no equipment matches, the existing empty state remains visible.

## Data and Components

No new persistence or database schema is required. Existing `EquipmentNode` fields provide all filter dimensions:

| Filter | Field |
|---|---|
| State / Federal Territory | `zoneId` |
| Shopping Mall | `facilityName` |
| City | `facilityCity` |
| Utility | `utilityType` |
| Status | `status` |

Inventory maintains local UI state for the selected state, mall, utility, and status. The filtered list is derived from `DatasetState.nodes`.

Dashboard already knows the selected loss state. When a user taps a state or top-loss callout, AppShell opens Inventory with that state as the initial location filter.

## Validation

Tests should verify:

- All 78 equipment nodes are visible by default.
- Selecting Selangor limits the result to its 9 nodes.
- Selecting a Selangor mall limits the result to its 3 nodes.
- Changing state clears the previous mall selection.
- Utility, location, and status filters combine correctly.
- Clear filters restores the complete list.
- A Dashboard state tap opens Inventory with the matching state selected.
- Empty filter results show the existing empty state.

## Success Criteria

An Admin can start from a state in Dashboard, arrive at Inventory, choose a specific mall from that state, and then narrow the list to a single equipment status without leaving the page. The UI makes the nationwide-to-facility-to-equipment hierarchy visible while leaving all other modules unchanged.
