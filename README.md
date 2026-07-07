# mySumber

BMIT2073 Mobile Application Development assignment — Flutter app supporting
SDG 9 (Industry, Innovation, and Infrastructure) using Malaysian government
open data (data.gov.my).

Each team member owns one module. This README documents where everything
lives and the exact GitHub Desktop steps the team follows so branches merge
without stepping on each other.

---

## Modules and owners

| Module | Description | Storage | Status |
|---|---|---|---|
| 1. Equipment Management | Import/version government datasets, dual-bar variance chart, anomaly detection | Local CSV | ✅ Complete |
| 2. Customer Experience | Personal usage comparison, repair report flow, service review & AI insights | Local + Cloud (Supabase) | ✅ Complete |
| 3. Water Leakage Detection | Detect leakage from real NRW data + simulated household readings, worker alert queue | Cloud (Supabase) + Local CSV | ✅ Complete |
| 4. Electricity Anomaly Detection | Detect meter tampering patterns, electricity loss hotspot analysis | Local CSV + Cloud (Supabase) | ✅ Complete |

---

## User Roles

| Role | Login | Access |
|---|---|---|
| **Admin** | Password: `admin` | Equipment dashboard, alerts oversight, reports, service reviews & AI insights |
| **Worker** | Password: `worker` | Water alert queue, electricity alert queue, field report submission |
| **Customer** | Email + password (Supabase Auth) | Home dashboard, usage comparison, repair history, AI service summary |

---

## Project structure

```
mysumber/
├── android/, ios/, ...           Flutter platform folders
│
├── assets/                       Read-only government reference datasets
│   ├── water_consumption.csv     data.gov.my — domestic/nondomestic consumption by state
│   ├── water_production.csv      data.gov.my — water production by state
│   ├── electricity_consumption.csv
│   └── electricity_supply.csv
│
├── supabase/
│   └── functions/
│       └── generate-ai-summary/  (unused — AI now called directly from Flutter)
│           └── index.ts
│
├── lib/
│   ├── main.dart                 App entry point, role-based navigation shell
│   ├── config.dart               Groq API key (DO NOT COMMIT to public repos)
│   │
│   ├── theme/
│   │   └── tokens.dart           Design tokens: colours, shared widgets (AppCard, SectionLabel)
│   │
│   └── modules/
│       ├── auth/                 Role selection + Supabase consumer auth
│       │   ├── screens/
│       │   │   └── landing_screen.dart
│       │   └── state/
│       │       └── auth_state.dart       (RoleState provider)
│       │
│       ├── dataset/              Module 1 — Equipment Management
│       │   ├── data/             CSV parsing & dataset repository
│       │   ├── models/           Dataset, Node, Equipment
│       │   ├── screens/          dashboard_screen.dart, node_form_screen.dart, equipment_detail_screen.dart
│       │   ├── services/         Anomaly detection engine
│       │   └── state/            DatasetState provider
│       │
│       ├── usage/                Module 2 — Customer Experience
│       │   └── screens/
│       │       ├── customer_home_screen.dart    Home: usage overview, AI summary card, pending review banner
│       │       ├── compare_usage_screen.dart    Water/electricity monthly history + daily bar chart
│       │       ├── report_problem_screen.dart   Profile + Report a Problem flow
│       │       └── my_reports_screen.dart       Resolved repairs list + star/tag/comment rating sheet
│       │
│       ├── leakage/              Module 3 — Water Leakage Detection
│       │   ├── data/
│       │   │   └── leakage_repository.dart      Supabase CRUD: alerts, reports, readings, reviews, summaries
│       │   ├── models/
│       │   │   ├── alert.dart
│       │   │   ├── report.dart
│       │   │   ├── reading.dart
│       │   │   ├── service_review.dart          Customer repair rating (stars + tags + comment)
│       │   │   └── ai_summary.dart              AI-generated service quality summary
│       │   ├── screens/          home_screen.dart, alert_queue_screen.dart, alert_detail_screen.dart,
│       │   │                     report_history_screen.dart, network_error.dart
│       │   ├── services/         baseline_service, nrw_service, simulation_service, explainer,
│       │   │                     electricity_loss_service
│       │   └── state/
│       │       └── app_state.dart               Central Provider: alerts, reports, reviews, AI summary
│       │
│       ├── electricity/          Module 4 — Electricity Anomaly Detection
│       │   ├── models/           ElectricityRecord
│       │   ├── screens/          electricity dashboard
│       │   └── services/         ElectricityDataService
│       │
│       └── admin/                Admin-only screens
│           └── screens/
│               ├── oversight_screen.dart         Alerts + reports oversight (tabs)
│               ├── admin_alert_detail_screen.dart
│               ├── abnormal_production_screen.dart
│               └── review_management_screen.dart  All reviews + ✨ Generate AI Insights button
│
├── pubspec.yaml                  Shared dependencies
└── README.md                     This file
```

---

## Feature: AI-Powered Service Reviews

Customers rate completed repairs (1–5 stars + tags + comment). Admins click
"✨ Generate AI Insights" to send all reviews to the Groq API (Llama 3 8B),
which returns a structured summary (pros, cons, overall assessment) stored in
Supabase and displayed to both customers and admins.

### Review tags

| Positive | Negative |
|---|---|
| Fast Response | Still Leaking |
| Perfectly Fixed | Slow Response |
| Great Attitude | Overcharged |
| Professional | Unprofessional |
| Thorough Check | Poor Fix |

### Supabase tables required

Run this SQL once in Supabase → SQL Editor:

```sql
CREATE TABLE service_reviews (
  id             SERIAL PRIMARY KEY,
  alert_id       INTEGER,
  consumer_email TEXT NOT NULL,
  stars          INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
  tags           TEXT[] DEFAULT '{}',
  comment        TEXT DEFAULT '',
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ai_summaries (
  id             SERIAL PRIMARY KEY,
  summary_text   TEXT NOT NULL,
  pros           TEXT[] DEFAULT '{}',
  cons           TEXT[] DEFAULT '{}',
  review_count   INTEGER NOT NULL DEFAULT 0,
  generated_at   TIMESTAMPTZ DEFAULT NOW()
);
```

### Groq API key

1. Register free at [console.groq.com](https://console.groq.com).
2. Copy the key (`gsk_xxx...`).
3. Paste it into `lib/config.dart`:
   ```dart
   static const String apiKey = 'gsk_your_key_here';
   ```

---

## Cloud database (Supabase)

Module 3 operational data (`alerts`, `readings`, `reports`) and the review
system (`service_reviews`, `ai_summaries`) live in a shared Supabase
(Postgres) project.

### Tables

| Table | Module | Description |
|---|---|---|
| `alerts` | 3 | NRW and electricity anomaly alerts |
| `readings` | 3 | Household water readings |
| `reports` | 3 | Worker field reports |
| `service_reviews` | 2 | Customer repair ratings |
| `ai_summaries` | 2 | AI-generated review summaries |

### Running the app

Nothing to configure — the app connects automatically using the public anon
key already embedded in `main.dart`. Run `flutter pub get` then `flutter run`.

### Security note

Row Level Security (RLS) is enabled on all tables. The anon key is the only
key that belongs in app code. Never commit a Supabase `service_role` key.
`lib/config.dart` (Groq key) should be added to `.gitignore` before pushing
to any public repository.

---

## Dependencies

```yaml
provider: ^6.1.5        # State management
csv: ^6.0.0             # CSV parsing
fl_chart: ^1.2.0        # Line/bar charts
supabase_flutter: ^2.9.0 # Cloud backend + auth
intl: ^0.20.2           # Date/number formatting
uuid: ^4.5.3            # Unique IDs
lucide_icons: ^0.257.0  # Water droplet, server crash icons
http: ^1.2.0            # Groq API calls
```

---

## Setup

```bash
# 1. Clone and install
git clone <repo-url>
cd Mobile-Assignmnet
flutter pub get

# 2. Add Groq key to lib/config.dart

# 3. Ask Supabase project owner to run the two CREATE TABLE statements above

# 4. Run
flutter run
```

---

## Git workflow (GitHub Desktop)

### Every work session

1. **Sync main** — Branch dropdown → `main` → Fetch origin → Pull origin
2. **New branch** — `yourname-moduleX` (e.g. `alice-module1`)
3. **Work** in your own `lib/modules/<name>/` folder only
4. **Commit often** — small, specific messages (e.g. `Add NRW detection engine`)
5. **Push** — Push origin
6. **Pull Request** — Create PR on GitHub → teammate reviews → merge
7. **Everyone syncs** — Pull origin on `main`

### Conflict hotspots

Conflicts only happen when two people edit the **same lines** of a shared file.
The two files to watch:

- **`pubspec.yaml`** — add your dependency, commit fast, tell the team
- **`lib/main.dart`** — coordinate before editing (new module wiring)

### Quick reference

| Goal | Action |
|---|---|
| Start work | `main` → Fetch → Pull |
| New task | New Branch → `yourname-moduleX` |
| Save | Commit with message |
| Share | Push origin |
| Merge to main | Create PR → review → merge |
| Get others' work | `main` → Pull |

---

## Submission checklist

- [ ] All AI use disclosed (Appendix A)
- [ ] All comments removed from code
- [ ] All modules merged to `main` and running
- [ ] `flutter run` launches without errors on emulator
- [ ] Supabase tables created (`service_reviews`, `ai_summaries`)
- [ ] Groq API key set in `lib/config.dart`
- [ ] No `service_role` key committed anywhere
- [ ] `.gitignore` up to date
