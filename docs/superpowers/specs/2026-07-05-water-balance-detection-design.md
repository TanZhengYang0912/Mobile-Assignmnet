# Module 3 — Water Leakage Detection: Design Spec

Date: 2026-07-05
Module owner: Worker X (single member)
App: mysumber (Flutter, Android). Assignment: BMIT2073, SDG 9.

## Purpose

Detect water leakage from Malaysian government open data and let a worker/admin
triage alerts and record inspection outcomes. Storage is local first (sqflite),
cloud sync deferred.

## Detection — two methods, both kept

### 1. Water-balance (Non-Revenue Water) on REAL data — primary
- Source: data.gov.my `water_production` and `water_consumption` (bundled CSV assets).
- Per state, latest year: `loss = produced - billed`, `lossPct = loss / produced * 100`.
- `billed` = domestic + nondomestic consumption.
- A state is flagged when `lossPct` is above threshold relative to the national
  average (2022 national ≈ 37.4%).
- Severity: high `>50%`, medium `40–50%`, low `national avg–40%`.
- Produces one alert per flagged state (`alert_type = nrw_hotspot`).

### 2. Simulated household detection — kept for the live demo
- Existing simulate buttons generate a 7-day household reading series.
- `DetectionEngine` compares to the per-capita baseline (signatures: continuous
  leak, sudden burst, creeping leak, seasonal spike, normal).
- Produces alerts with `alert_type = household`.

Both alert types share one queue, one status lifecycle, one report flow.

## Status lifecycle

```
Pending -> Investigating -> Resolved   (outcome: fixed)
                         -> Not fixed  (outcome: not fixed, reopenable)
Dismissed  (parked for later — see Open items)
```
- `Pending`: detected, no action yet (renamed from `open`).
- `Investigating`: worker started / visited.
- `Resolved`: investigated and leak stopped.
- `Not fixed`: investigated, not stopped; stays in Unresolved; can reopen to
  `Investigating` for a follow-up visit.

## Report model — single report with outcome

- One report per alert. Fields: worker, findings, action taken, outcome
  (`fixed` / `not_fixed`), created/updated timestamps.
- Gated: writable only after status is `Investigating`.
- Visibility: shown only when a report exists. First-time (no report) shows no
  report section — no locked placeholder. On reopen (Not fixed), the previous
  report is shown pre-filled and editable.
- CRUD: create (after investigation), read (detail), update (edit / append),
  delete draft (soft delete).

## Screens

1. Home — role switcher (Worker/Admin), `Run leakage analysis` (scans real data),
   simulate buttons (household what-if).
2. Alert queue — search by state; filter chips (state, severity, status);
   tabs `Unresolved` / `Resolved`. Cards show state, severity (dominant colour),
   headline metric (`59.7%` or `2.2x`), status pill, and time as
   `date + data year` (NRW) or `date` (household). Sorted most-severe first.
3. Alert detail — evidence (water balance + 20-year loss trend, or household
   actual-vs-baseline + overnight flow), templated assessment, `Start
   investigation`, and the report (only when it exists).
4. Report form — findings, action taken, outcome toggle (Fixed / Not fixed);
   outcome sets the status. Full audit timestamp here.

## Data model changes (sqflite)

- `alerts`: rename status `open` -> `pending`; add `not_fixed` as a valid status;
  add `alert_type` (`nrw_hotspot` / `household`); add nullable NRW columns
  `produced_mld`, `billed_mld`, `loss_mld`, `loss_pct`, `data_year`.
- `reports`: add `outcome` (`fixed` / `not_fixed`, nullable until set).
- DB version bump with recreate (prototype data is disposable).

## Data ownership (Module 1 boundary)

- Government CSVs are read-only reference data. Investigations never mutate them.
- Dataset versioning / re-import belongs to Module 1. Module 3 reads the active
  version. For the prototype, Module 3 bundles its own read-only CSV copies.

## Open items (parked)

- Dismiss / false-positive (the alert Delete op) — decide placement later
  (admin-only action or swipe). Must return before final to keep CRUD complete.
- Cloud sync, real auth/roles, TFLite upgrade — post-prototype.

## Not a git repo

The project is not yet under git, so this spec is written but not committed.
Init git before the final GitHub submission (assignment requires a private repo).
