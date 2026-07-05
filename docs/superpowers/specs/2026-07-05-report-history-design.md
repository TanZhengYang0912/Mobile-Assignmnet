# Module 3 — Report History: Design Spec

Date: 2026-07-05
Module owner: Worker X
Builds on: `2026-07-05-water-balance-detection-design.md`,
`2026-07-05-supabase-migration-design.md`

## Purpose

Currently an alert has at most one report, which is edited in place every
time a worker re-investigates after a "Not fixed" outcome — the previous
findings are overwritten. This changes that: every investigation attempt
produces its own permanent report. Past attempts become read-only history;
nothing is ever edited or deleted after it's saved.

## Why no schema change

The `reports` table already has no constraint limiting one row per
`alert_id` — the app only ever *queried* for the single latest row
(`order by updated_at desc limit 1`). This is purely an application-logic
change: stop treating "the report" as singular, treat it as a list ordered
newest-first. No migration needed.

## Behavior

- **Writing**: whenever an alert's status is `investigating`, a "Write
  report" button is available — regardless of whether past reports exist
  for this alert. It always opens a blank form. Saving always inserts a
  new row (never updates an existing one) and, as before, the chosen
  outcome sets the alert's status (`fixed` → `resolved`, `not_fixed` →
  `not_fixed`, staying in the queue for another investigation round).
- **Reading**: the alert detail screen lists every report for that alert,
  newest-first, below the assessment section. Each card shows outcome,
  a findings preview, and the date — the same visual pattern already used
  for a single report today.
- **Locking**: tapping any report card (including the most recent one)
  opens a new read-only view screen — same layout as the write form, but
  every field disabled/plain text, outcome shown as static badges, and no
  Save or Delete button. Nothing is ever editable or deletable once saved.

## Data layer changes

- `LeakageRepository.reportForAlert(alertId)` (singular, latest-only) is
  replaced by `reportsForAlert(alertId)` returning `List<Report>`,
  ordered `updated_at desc`.
- `LeakageRepository.deleteReport` and `AppState.deleteReport` are removed
  — no caller survives this change (same treatment given to `dismissAlert`
  earlier in the project). The `is_deleted` column stays in the schema,
  unused for now, in case a future admin feature needs it.

## Screens

- `alert_detail_screen.dart`: the report section becomes a list of cards
  instead of a single card. The "Write report" action's visibility
  condition changes from `status == investigating && report == null` to
  simply `status == investigating` (a report existing no longer blocks
  writing a new one). Tapping a card navigates to the new read-only view
  screen instead of the editable form.
- `report_form_screen.dart`: drop the `existing` parameter entirely — it
  only ever supported edit-in-place, which no longer exists. Every write
  is a fresh entry. Remove the delete icon from the app bar.
- New file `report_view_screen.dart`: read-only counterpart to the report
  form, showing findings, action taken, outcome, and timestamps as static
  text. Keeps the write form single-purpose rather than growing a
  dual editable/disabled mode.
- `report_history_screen.dart` (the global, cross-alert report list reached
  from the home screen): already lists every report row individually, not
  deduped to one-per-alert, so no structural change is needed here — it
  already is a full history view. Its tap target changes from
  `ReportFormScreen(alert: alert, existing: report)` to the new
  `ReportViewScreen`, matching the "every saved report is read-only"
  rule everywhere it's reachable.

## Testing / verification

No new automated tests planned — this is UI/query logic consistent with
the project's existing "verification is manual" approach for this module.
Manual verification: re-investigate an alert with an existing report,
confirm a second report is created (not an edit of the first), confirm
the first report is still visible and read-only, and independently
cross-check row count via `execute_sql` against the live Supabase project.

## Open items

None new. Existing parked items (dismiss/false-positive workflow, real
auth) are unaffected by this change.
