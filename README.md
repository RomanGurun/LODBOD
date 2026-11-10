# LODBOD — Shipper Mobile App

Flutter prototype for the LODBOD shipper-side load board. It covers the
end-to-end shipper flow: sign in, view shipment KPIs, browse and search
shipments, compare carrier bids, accept a bid, and post a new load with the
mobile 3-request limit.

## Demo credentials

| Field | Value |
|-------|-------|
| Email | `demo@lodbod.com` |
| Password | `Demo@1234` |

The login screen also has a **Use demo account** button that fills these
values. Authentication uses Firebase Auth when the platform is configured and
the Email/Password provider is enabled. If Firebase is unavailable or the
provider is not enabled, it falls back to the in-memory `MockAuthRepository`;
only the demo credentials are accepted there.

## Run

Tested with Flutter 3.50 (Dart 3.12) on macOS.

```bash
flutter pub get
flutter run -d <android-device>
```

Build artifacts:

```bash
flutter build apk --debug
# build/app/outputs/flutter-apk/app-debug.apk
```

The Android build is configured with Firebase. iOS/web are not configured or
verified for this submission.

## Golden path

1. Launch and sign in with the demo account.
2. Dashboard shows seed KPIs and recent shipments.
3. Open **Shipments**, use the search field and status chips.
4. Open **LOD-1002** (Awaiting Bids).
5. Compare the two bids, tap **Accept Bid**, and confirm. The shipment becomes
   Confirmed and every screen updates from the same state.
6. Open **Post Load**, complete the five steps, and submit. The seed has two
   active shipments, so the first request succeeds as **LOD-1005**.
7. Submit a second request. The 3-request limit dialog appears with the exact
   prescribed message, and the typed form values are preserved.

## Implemented

- Splash with auth-state redirect.
- Login with validation, password visibility, loading state, error message,
  and demo-account shortcut.
- Five-tab shell: Dashboard, Shipments, Post Load, Analytics, Account.
- Dashboard KPI cards and recent shipments driven by the same shipment list.
- Shipment list with text search (reference/route/cities), status chips,
  pull-to-refresh, empty state, and shimmer loading skeleton.
- Shipment detail with route, cargo, schedule, notes, status timeline, bids,
  and pull-to-refresh.
- Bid cards showing carrier, rating, fare, ETA, and verification. Accepting a
  bid requires confirmation and updates the shipment status.
- Five-step Post Load form: Route, Cargo, Schedule, Vehicle, Review. Each step
  validates before advancing; the review step shows the full summary.
- 3-active-shipment limit enforced in the domain rule and the notifier.
- Confirmation dialog on successful creation.
- Analytics summary counts with a status-breakdown bar chart.
- Account screen with account info and sign out confirmation.
- Riverpod `AsyncValue` loading/error/data handling on data-backed screens.

The default seed starts with two active shipments, so the first Post Load
succeeds and the next one hits the limit. This keeps both flows demonstrable.

## 3-request limit

Active statuses: `open`, `awaitingBids`, `scheduled`, `confirmed`, `inTransit`.
Completed/cancelled/expired shipments do not count.

Exact message shown:

> You have reached the mobile request limit of 3. Please use the LODBOD web
> platform to create additional requests.

The limit is checked in `ShipmentLimitRule` and again in `ShipmentNotifier`
before persistence. On a limit hit, `LimitException` is thrown without mutating
state, and the form keeps all typed values.

## Seed data

| Reference | Route | Status | Bids |
|-----------|-------|--------|------|
| LOD-1001 | Kathmandu → Pokhara | In Transit | - |
| LOD-1002 | Birgunj → Kathmandu | Awaiting Bids | 2 |
| LOD-1003 | Butwal → Narayanghat | Delivered | - |
| LOD-1004 | Kathmandu → Biratnagar | Cancelled | - |

Bids for LOD-1002:

| Carrier | Fare | Rating | ETA |
|---------|------|--------|-----|
| Himalayan Cargo | NPR 32,000 | 4.6 | 2 days |
| Swift Transport | NPR 29,500 | 4.1 | 3 days |

Pickup dates are generated relative to `DateTime.now()` so the data stays
fresh across runs.

## Architecture

```
lib/
├── core/           constants, theme, router, errors, extensions, validators
├── domain/         entities, enums, repository interfaces, business rules
├── data/           DTO models, seed data, mock and HTTP repositories
├── features/       auth, dashboard, shipments, bids, create, analytics, account
└── shared/         provider wiring, reusable widgets (badges, states, skeletons)
```

- **State:** Riverpod 2 without code generation. `ShipmentNotifier`
  (`AsyncNotifier<List<Shipment>>`) is the single source of truth. Derived
  providers expose dashboard stats, recent shipments, filtered shipments,
  shipment-by-id, and shipment bids.
- **Navigation:** `go_router` with an auth redirect and a stateful shell.
  Detail routes are nested under `/shipments/:id`.
- **Data:** `IShipmentRepository` / `IAuthRepository` interfaces are injected
  through `lib/shared/providers/repository_providers.dart`. Shipments use the
  in-memory mock by default and switch to the API when `API_BASE_URL` is
  provided. API calls go through Dio interceptors for retries, safe logging,
  and data-source tracking, and are wrapped in `ResilientShipmentRepository`:
  network/server failures switch reads and writes to a local snapshot (or seed)
  and show an offline banner in the shell. Auth uses Firebase Auth with a mock
  fallback.
- **Writing:** only the notifier writes shipment state. `createShipment` and
  `acceptBid` return the repository result and update central state from it;
  there are no optimistic updates.

## Hosted mock API (mockapi.io)

`ApiShipmentRepository` in `lib/data/remote/` already implements the REST
contract with Dio. The local mock stays the default so the app runs offline.

Seed or reset the hosted project:

```bash
API_BASE_URL=https://6af2103d42c6561ced38f683.mockapi.io \
  ./scripts/seed_mockapi.sh
```

The script deletes existing rows, inserts the four shipments, reads the
generated LOD-1002 id, and inserts its two bids. LOD-1001 and LOD-1002 are
active, so the first mobile create succeeds and the next hits the limit. Run it
again before each demo to reset accepted bids and the active count.

Run against the hosted API:

```bash
flutter run -d <android-device> \
  --dart-define=API_BASE_URL=https://6af2103d42c6561ced38f683.mockapi.io
```

Without the define, the app uses `MockShipmentRepository`. Tests also override
the provider with the mock. For a different mockapi project, change
`API_BASE_URL`; resource names must be `shipments` and `bids`.

## Replacing the data source

Implement `IShipmentRepository` (and optionally `IAuthRepository`), then change
the provider in `lib/shared/providers/repository_providers.dart`. Screens and
notifiers do not import the concrete repository classes.

## Verify

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Current state: analyze clean, 43 tests passing.

Tests cover domain rules, DTO mapping, remote repository atomicity and error
mapping, fallback repository behavior, auth and shipment notifiers, derived
providers, the shipment list search/filter UI, and the Post Load step
validation plus both the success and limit dialogs.

## Limitations

- Firebase Auth is wired but real sign-in requires Email/Password to be
  enabled in the Firebase console; otherwise the demo mock fallback is used.
  OTP and sign-up screens are not implemented.
- Local/mock data is in-memory and resets when the process restarts; hosted
  mockapi data persists until the seed script is run again.
- Analytics is computed locally from the current list; no historical trends,
  date ranges, or reporting engine.
- No dark theme toggle (colors are defined as light-mode tokens).
- No pagination or image upload.
- Only the Android build has been verified on an emulator. The hosted mockapi
  contract was live-tested for reads, create, and bid acceptance; no physical
  device or iOS build was verified.

## Reference material

- `docs/PLAN.md` — execution plan and original API contract.
- `docs/TECHNICAL_NOTES.md` — architecture notes and design tokens.
- `images/` — supplied LODBOD reference screens.
