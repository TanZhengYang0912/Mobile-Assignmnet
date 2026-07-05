# Module 3 — Supabase Cloud Migration: Design Spec

Date: 2026-07-05
Module owner: Worker X
Supersedes the local-only storage decisions in
`2026-07-05-water-balance-detection-design.md` for operational data only.

## Purpose

Move Module 3's operational data (readings, alerts, reports) from local
sqflite to a shared Supabase (Postgres) project, matching the assignment's
own architecture guidance: data that must be seen by more than one
user/device belongs in the cloud. Detection logic and reference datasets
are unaffected.

## Scope — what moves, what doesn't

| Data | Before | After |
|---|---|---|
| `readings`, `alerts`, `reports` | Local sqflite | Supabase (Postgres) |
| Government CSVs (`water_consumption`, `water_production`) | Bundled asset | Unchanged — bundled asset |
| Detection engine, NRW analysis, baseline service | Pure Dart, local | Unchanged |

Rationale: only the data that needs shared worker visibility across
devices moves. Reference data has no sharing requirement and moving it
would add a needless network dependency to core detection logic (and
duplicate Module 1's territory).

## Auth — deliberately unchanged (simulated)

The app keeps its existing simulated persona model: no real login. Per
this migration, **the role switcher (Worker/Admin) is removed** — the app
now assumes a single persona, "Worker X", for all actions. This was a
scope reduction agreed during brainstorming, independent of the Supabase
move, but bundled into this change since it simplifies the security model
(no per-role RLS needed).

Consequence: `dismissAlert` (the admin false-positive workflow) has no
caller and is removed from `AppState`/repository. The `dismissed` status
value remains valid in the database CHECK constraint for when this
capability returns — it is parked, not deleted from the data model.

## Schema (Postgres, applied via Supabase migration)

Three tables, translated from the sqflite schema:

- `bigint generated always as identity` primary keys — keeps existing Dart
  models' `int? id` fields unchanged, no model rewrite needed.
- `timestamptz` for all date/time columns.
- `CHECK` constraints on enum-like text columns (`alerts.alert_type`,
  `alerts.severity`, `alerts.status`, `reports.outcome`) so invalid values
  can't reach the database even if application code has a bug — a
  meaningful upgrade over sqflite's untyped text columns for the "data
  management" rubric criterion.
- Foreign keys: `alerts.reading_id -> readings.id`, `reports.alert_id ->
  alerts.id`.

Column set is otherwise a direct carry-over from the existing `Alert`,
`Report`, `Reading` Dart models (see
`lib/modules/leakage/models/{alert,report,reading}.dart`) — no field
renames.

## Security (Row Level Security)

RLS is **enabled** on all three tables (non-negotiable — Supabase
guidance is to never disable it). Each table gets one permissive policy
allowing full read/write for the `anon` role, since there is no real user
identity yet to restrict by given the simulated single-persona model.
This is a documented, deliberate simplification — revisit with real
per-user policies if authentication is ever added.

The Flutter app uses only the **anon/publishable key** (safe to embed in
client code by design — RLS is the actual protection boundary). The
Supabase `service_role` key is never used in the app and never committed
to the repo.

## Client integration

- Add `supabase_flutter` to `pubspec.yaml`; remove `sqflite`, `path`,
  `path_provider` (no longer used by anything once `leakage_database.dart`
  is deleted).
- Initialize the Supabase client once in `main.dart` with the project URL
  and anon key.
- `LeakageRepository`'s public method signatures are unchanged
  (`insertReading`, `alerts()`, `updateAlertStatus`, `saveReport`, etc.) —
  only their internals swap from `sqflite` `Database` calls to
  `supabase_flutter` Postgrest calls (`.from(table).select()/.insert()/
  .update()`). This is the payoff of having isolated storage behind a
  repository: `AppState` and every screen are unaffected by this swap.
- `dismissAlert` and its repository method are removed (see Auth section).

## Offline behavior

No offline fallback. The app requires internet connectivity to read or
write alerts/reports/readings, matching how a real cloud-backed app
behaves. This was a deliberate choice over building sync/conflict-handling
logic, which would be disproportionate for a student prototype.

## Error handling

Each mutating action (simulate reading, run leakage analysis, save
report, update alert status) is wrapped in a try/catch at the screen
level. On failure, show a plain SnackBar: "Couldn't reach the server.
Check your connection and try again." No silent failures.

## Testing / verification

No new automated tests required — `test/detection_engine_test.dart` is
pure Dart and unaffected by the storage swap. Verification is manual:
run the app, trigger the simulate and NRW-scan flows, and independently
confirm the resulting rows via Supabase `execute_sql`, proving the app
and database genuinely agree.

## Team access model

- **Running the app**: no setup — the anon key ships in the code, so any
  teammate who clones the repo and runs the app is on the same shared
  database automatically.
- **Managing the Supabase project via Claude Code (MCP)**: requires the
  project owner to invite the teammate as a Supabase project member, then
  the teammate authenticates their own Supabase account via `claude /mcp`
  in a plain terminal. A Claude Code session already running before
  authenticating will not see the newly connected server — it must be
  restarted.

## Open items (parked, unchanged from prior spec)

- Dismiss / false-positive workflow — return before final submission to
  keep the alert CRUD story complete (Delete operation).
- Real authentication and per-role RLS — only if the module's scope grows
  beyond the assignment's fake-data allowance.
