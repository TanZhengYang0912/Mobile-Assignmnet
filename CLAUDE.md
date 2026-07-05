# MySumber Project Documentation

## Overview

**MySumber** is a Flutter mobile app for water & electricity anomaly detection using Malaysian government open data (data.gov.my). The app supports SDG 9 (Industry, Innovation, and Infrastructure).

- **Team:** BMIT2073 Mobile Application Development assignment
- **Platform:** Android & iOS (Flutter)
- **Cloud:** Supabase (PostgreSQL)
- **Status:** 4 modules, mostly complete (Modules 1, 3, 4 active; Module 2 placeholder)

---

## Architecture Overview

### Frontend
- **Framework:** Flutter 3.12+ (Dart)
- **State Management:** Provider (ChangeNotifier)
- **UI:** Material Design 3
- **Charts:** fl_chart 1.2.0

### Backend (Cloud)
- **Provider:** Supabase (managed Postgres)
- **URL:** `https://tnmznkdvrrpigevxdfet.supabase.co`
- **Auth:** Anonymous (public key embedded in code)
- **Tables:** `alerts`, `readings`, `reports` (Module 3 only)

### Data Sources
- **Local:** 4 bundled CSV files (government datasets, read-only)
  - `water_consumption.csv`
  - `water_production.csv`
  - `electricity_consumption.csv`
  - `electricity_supply.csv`
- **Cloud:** Supabase real-time sync (Module 3)

---

## Project Structure

```
lib/
├── main.dart                          SHARED (entry point, app shell, providers)
└── modules/
    ├── auth/                          Module 0: Role Selection (Admin/Consumer)
    │   ├── screens/
    │   │   └── role_selection_screen.dart
    │   └── state/
    │       └── auth_state.dart
    │
    ├── dataset/                       Module 1: Equipment Management
    │   ├── data/                      CSV parsing & dataset repository
    │   ├── models/                    Dataset, Node, Equipment classes
    │   ├── screens/                   Dashboard & detail screens
    │   ├── services/                  Anomaly detection
    │   └── state/                     DatasetState (Provider)
    │
    ├── usage/                         Module 2: Personal Usage Comparison
    │   └── screens/
    │       └── work_in_progress_screen.dart
    │
    ├── leakage/                       Module 3: Water Leakage Detection
    │   ├── data/                      LeakageRepository (Supabase CRUD)
    │   ├── models/                    Alert, Reading, Report
    │   ├── screens/                   Home, reports, alert queue
    │   ├── services/                  Detection, baseline, explainer
    │   └── state/                     AppState (Provider)
    │
    └── electricity/                   Module 4: Electricity Anomalies
        ├── models/                    Electricity data classes
        ├── screens/                   Dashboard
        ├── services/                  ElectricityDataService
        └── state/                     ElectricityState (Provider)

assets/
├── water_consumption.csv              Government reference data
├── water_production.csv
├── electricity_consumption.csv
└── electricity_supply.csv
```

---

## Module Breakdown

| Module | Owner | Purpose | Storage | Status |
|--------|-------|---------|---------|--------|
| 0. Auth | Assigned | Role selection (Admin/Consumer) | In-memory | ✅ Complete |
| 1. Equipment | Chun Jie Tan | Dataset management & state variance | Local CSV | ✅ Active |
| 2. Comparison | Unassigned | Household vs. state usage | Local CSV | 🔧 Placeholder |
| 3. Leakage | Worker X | Water anomaly detection | Supabase + CSV | ✅ Active |
| 4. Electricity | Chun Jie Tan | Meter tampering detection | Local CSV | ✅ Active |

---

## Tech Stack

### Dependencies
```yaml
flutter: sdk (3.12.2+)
provider: ^6.1.5          # State management
csv: ^6.0.0               # CSV parsing
fl_chart: ^1.2.0          # Charts
supabase_flutter: ^2.9.0  # Cloud backend
intl: ^0.20.2             # Date/number formatting
uuid: ^4.5.3              # Unique IDs
```

### Development
```yaml
flutter_test: sdk
flutter_lints: ^6.0.0
```

---

## Setup & Running

### Prerequisites
- **Flutter SDK 3.12+** installed and in PATH
- **Android Studio** with Android emulator configured
- **Git** for version control

### First-Time Setup

1. **Clone the repo** (if not already done)
   ```bash
   git clone <repo-url>
   cd Mobile-Assignmnet
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Start the Android emulator**
   - Open Android Studio → Device Manager
   - Click **▶️** to start an emulator
   - Wait ~30 seconds for it to fully boot

4. **Verify emulator is ready**
   ```bash
   flutter devices
   ```
   Should show: `emulator-5554 • Android 14 • android-x86_64 • emulator`

### Running the App

```bash
flutter run
```

**First run:** 3-10 minutes (downloads SDKs, builds APK)  
**Subsequent runs:** 30-60 seconds (cached build)

The app will launch on the emulator automatically.

### Hot Reload (Development Loop)

While `flutter run` is active, press **`r`** in the terminal to hot-reload code changes. Much faster than full rebuild (~2 seconds).

---

## Data Flow

### Example: Module 3 (Water Leakage Detection)

```
User creates a reading on phone
    ↓
LeakageRepository.insertReading()
    ↓
Supabase stores in 'readings' table
    ↓
Detection engine analyzes vs. baseline
    ↓
If anomaly → Alert created & stored in 'alerts'
    ↓
Explainer generates human-readable explanation
    ↓
Provider notifies UI listeners
    ↓
All connected phones see new alert in real-time (Supabase subscriptions)
```

### Modules 1, 2, 4 (Local Only)

No cloud dependency. All data processed locally; findings stored in Provider state.

---

## Module 0: Role Selection (Authentication)

### How It Works

The app starts with a **role selection screen** (no password required):

```
┌────────────────────────────────────┐
│          mySumber                   │
│  Select your role to continue       │
│                                     │
│      [Admin] [Consumer]             │
└────────────────────────────────────┘
```

**Admin role:**
- Access modules: 1 (Equipment), 3 (Leakage), 4 (Electricity)
- Tabs: Equipment | Leakage | Electricity

**Consumer role:**
- Access modules: 2 (Personal Usage) only
- Tabs: My Usage

### AppBar with Logout

Once logged in, the AppBar displays:
- Title: `mySumber - ADMIN` or `mySumber - CONSUMER`
- Logout button (top right)
- Click Logout → returns to role selection screen

### State Management

```dart
AuthState (Provider)
├── _userRole: "admin" | "consumer" | null
├── isLoggedIn: bool
├── setRole(role): void
└── logout(): void
```

The role selection is **in-memory only** (not persistent). When the app closes, the user must select a role again.

---

## Module 2: Personal Usage Comparison (Placeholder)

**Current status:** Placeholder screen with "Module 2 - Work in progress" text.

**To implement:** Follow the specifications in the Architecture Overview section above (Input form → Comparison chart → Recommendations).

**When ready to build:** Replace `work_in_progress_screen.dart` with actual screens while keeping the route and Provider setup unchanged.

---

## Important Rules & Constraints

### 🚫 Don't Do This

1. **Rewrite CSV files at runtime** — Assets are read-only reference data
2. **Edit another person's module folder** — Each person owns one module
3. **Commit a Supabase `service_role` key** — Only public anon key is safe
4. **Edit `main.dart` or `pubspec.yaml` without coordination** — Shared files

### ✅ Do This

1. **Work only in your module's folder** — `lib/modules/<your-module>/`
2. **Commit frequently** — Small, focused commits
3. **Sync `main` before starting new work** — Avoid painful merges
4. **Use branches** — Create feature branch like `yourname-module1`
5. **Create PRs** — Get reviewed before merging to `main`

---

## Supabase Connection

### For Running the App
**Nothing to do.** The app auto-connects using the embedded public key. All team members share the same cloud database.

### For Direct Database Management (Claude Code / MCP)
1. Ask project owner to invite you: Supabase dashboard → Project Settings → Team → Invite member
2. Accept the invite
3. In terminal: `claude` → `/mcp` → select **supabase** → **Authenticate** → log in via browser
4. Restart Claude Code session

---

## Development Workflow (Git)

### Daily Loop

1. **Sync main**
   ```bash
   git checkout main
   git pull origin
   ```

2. **Create feature branch**
   ```bash
   git checkout -b yourname-module1
   ```

3. **Make changes** in your module folder only

4. **Commit frequently**
   ```bash
   git add .
   git commit -m "Add NRW detection engine"
   ```

5. **Push to GitHub**
   ```bash
   git push origin yourname-module1
   ```

6. **Create Pull Request** on GitHub

7. **Wait for review** → Merge to `main`

8. **Everyone syncs**
   ```bash
   git checkout main
   git pull origin
   ```

### Handling Conflicts

If GitHub reports conflicts:
1. Open conflicting file
2. Find `<<<<<<<` / `=======` / `>>>>>>>`
3. Edit to keep both/correct version
4. Delete conflict markers
5. Mark resolved in GitHub Desktop → commit merge

---

## Troubleshooting

### `flutter: command not found`
- Restart PowerShell/terminal completely
- Or use full path: `C:\flutter\bin\flutter.bat run`

### Emulator won't start
- Check Android Studio → Device Manager
- Delete outdated emulator, create new one with API 34+

### Gradle build fails
- Run `flutter pub get` again
- Delete `build/` folder and rebuild
- Check internet connection (large downloads)

### Supabase connection fails
- App requires internet connection
- Check Supabase status: https://supabase.com/status
- Verify public key in `lib/main.dart` is correct

### Hot reload not working
- Stop and restart `flutter run`
- Make sure you're in debug mode (default)

---

## Useful Commands

```bash
flutter --version              # Check Flutter version
flutter doctor                 # Diagnose environment issues
flutter devices                # List available emulators/devices
flutter pub get                # Download/update dependencies
flutter pub outdated           # See outdated packages
flutter run                    # Launch app in debug mode
flutter run --release          # Build optimized release APK
flutter clean                  # Delete build artifacts
flutter pub upgrade            # Upgrade all dependencies
```

---

## File Permissions & Access

| File/Folder | Access | Notes |
|---|---|---|
| `lib/modules/<your-name>/` | ✅ Full | Your module — edit freely |
| `lib/modules/<other>/` | 🚫 Read-only | Don't edit others' work |
| `lib/main.dart` | ⚠️ Coordinate | Shared entry point |
| `pubspec.yaml` | ⚠️ Coordinate | Shared dependencies |
| `assets/` | 🚫 Read-only | Government data reference |

---

## Supabase RLS & Security

- **Row Level Security (RLS)** is enabled on `alerts`, `readings`, `reports`
- **Policies are permissive** (no per-user auth yet—future enhancement)
- **Public anon key** is intentionally embedded in `lib/main.dart`
- **Never commit service_role key** to GitHub

This is a deliberate simplification for the assignment—all team members share a single "Worker X" persona.

---

## Questions & Support

- **Flutter docs:** https://flutter.dev/docs
- **Supabase docs:** https://supabase.com/docs
- **Dart docs:** https://dart.dev/guides
- **Team chat:** Coordinate on shared files in team messaging

---

## Checklist Before Final Submission

- [ ] All AI use disclosed (Appendix A)
- [ ] All comments removed from code
- [ ] All team members' work merged to `main`
- [ ] App runs without errors in emulator
- [ ] All modules launch and display data
- [ ] Supabase connection works (Module 3)
- [ ] No secrets in code (keys, passwords)
- [ ] .gitignore is up-to-date
- [ ] README still reflects current project state
