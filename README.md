# LODBOD — Shipper Mobile App

Flutter app for the LODBOD shipper-side load board. It implements the full
shipper journey: register/sign in, view shipment KPIs, browse and search your
shipments, compare carrier bids and accept one (with confirmation), post a new
load through a five-step form under the 3-active-request limit, track a moving
load, and review analytics — all against a hosted MockAPI backend with a
resilient local fallback.

## Demo credentials

| Field | Value |
|-------|-------|
| Email | `demo@lodbod.com` |
| Password | `Demo@1234` |

The login screen has a **Use demo account** button that fills these values.
The demo account is deliberately authenticated through the local fallback
(signed-in uid `demo-1`), because it owns the seeded sample shipments — this
keeps the documented demo journey working even when Firebase is unreachable.
Any *other* email/password always goes to Firebase Auth first and only falls
back when the auth service itself cannot be reached; client-side failures
(wrong password, unknown user) never fall back.

## Requirements

- Flutter 3.50+ (Dart ≥ 3.3). Verified with `Flutter 3.50.0-0.4.pre` on macOS.
- A device or emulator for Android; macOS desktop also runs (without Firebase
  — see [Firebase setup](#firebase-setup)).

```bash
flutter pub get
flutter run -d <device>
```

Release artifact:

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

## Firebase setup

Firebase is configured for Android only (`android/app/google-services.json`,
project `lodbod-shipper`). To reproduce:

1. Create a Firebase project, add an Android app with package name
   `com.example.lodbod`, and download `google-services.json`.
2. Enable **Authentication → Sign-in method → Email/Password**.
3. (Optional) Register the app with the CLI and deploy the Firestore rules:
   `firebase deploy --only firestore:rules` — `firestore.rules` allows a
   signed-in user to read/update only their own `users/{uid}` profile, forces
   `role == 'shipper'` on create, forbids role changes, and denies client
   deletes.
4. Register real users from the app's Create Account screen.

Without Firebase (e.g. running on macOS), auth falls back to the in-memory
`MockAuthRepository`, which only accepts the demo credentials above, and the
Firestore profile falls back to an in-memory store.

### Shipper profile document

On sign-up the app writes `users/{uid}` with:

```json
{
  "uid": "<firebase uid>",
  "name": "Full Name",
  "email": "you@example.com",
  "phone": "98XXXXXXXX",
  "role": "shipper",
  "createdAt": "2026-11-11T…",
  "updatedAt": "2026-11-11T…"
}
```

The Account screen reads this document (with a skeleton loader) and shows a
profile synthesized from the auth identity if the document is missing.

## Backend — MockAPI

The app is remote-first against the provided endpoint:

- Base URL: `https://6af2103d42c6561ced38f683.mockapi.io`
- Resources: `GET/POST /shipments`, `GET/PATCH/DELETE /shipments/{id}`,
  `GET/POST /bids`, `GET/PATCH/DELETE /bids/{id}` (field names preserved
  exactly as in the assignment contract; `shipperId` is sent on create).

The base URL defaults to the hosted project and can be overridden with
`--dart-define=API_BASE_URL=https://…` without touching the repository code.

### Fallback semantics (honesty about every layer)

`ResilientShipmentRepository` wraps the API repository:

- Reads and writes go to MockAPI first.
- Only **network and server failures** (`NetworkException`, 5xx
  `ServerException`) switch to the local snapshot (or the seed on a cold
  start) and raise the offline banner in the shell.
- **4xx responses never fall back** — 404 maps to `NotFoundException`,
  409 to `ConflictException`, 400/422 to `ValidationException`, and the
  user sees the error.
- Writes that succeed remotely are mirrored into the snapshot so a later
  fallback still shows them.

`scripts/seed_mockapi.sh` resets the hosted data (four shipments, two bids on
LOD-1002):

```bash
./scripts/seed_mockapi.sh
```

## Shipment ownership

- Every shipment created through the app is stamped with
  `shipperId = <firebase uid>` and the shipper's display name.
- The shipment list, detail, bids, dashboard, and analytics are all derived
  from one auth-scoped notifier, so a shipper only ever sees and manages
  their own shipments; signing out clears the list.
- The legacy seed rows (LOD-1001…1004) predate the `shipperId` field, so
  they are mapped to the documented demo owner (`demo-1`) — visible only to
  the demo account, never to other shippers. Blank `shipperId` values parse
  as absent (null), never as an empty-string owner.

## 3-request limit

Qualifying (active) statuses: `open`, `awaiting_bids`, `scheduled`,
`confirmed`, `in_transit`. Delivered/cancelled/expired do not count. Only the
signed-in shipper's own shipments count.

Exact message shown on the limit dialog:

> You have reached the mobile request limit of 3. Please use the LODBOD web
> platform to create additional requests.

The limit is enforced in `ShipmentLimitRule` (domain) and re-checked in
`ShipmentNotifier.createShipment` before persistence. On a limit hit a
`LimitException` is thrown without mutating any state, and the Post Load form
keeps every typed value. Duplicate submissions are additionally guarded by an
in-flight flag that throws `ConflictException`.

## Bid acceptance

Accepting a bid performs these checks before any write:

1. the shipment is in the authenticated shipper's list (ownership),
2. the shipment is `awaiting_bids`,
3. the bid belongs to that shipment.

The UI asks for confirmation, then the repository:

1. `PATCH /shipments/{id}` → `status=confirmed`, `acceptedBidId`,
   `assignedCarrier`, `updatedAt`;
2. `PATCH /bids/{acceptedId}` → `status=accepted`;
3. `PATCH /bids/{competingId}` → `status=rejected` for every other pending
   bid.

If any of those PATCHes fail mid-sequence, every already-applied write is
rolled back to the values read before the acceptance; if the rollback itself
fails, the user gets an explicit "the server could not be restored" error
rather than silent inconsistency.

**Production atomicity:** MockAPI has no transactions, so multi-document
consistency is best-effort compensating writes. In production this would be a
single atomic operation — a Firestore batch/transaction (shipment + bids in
one commit), a cloud function, or a backend endpoint — so a partial failure
could never be observed at all.

## Carrier-side demo actions

The assignment brief only requires the flow up to accepting a bid with
confirmation. LODBOD is a two-sided marketplace, but this prototype ships
**only the shipper app** — there is no carrier side to place bids or to move
a confirmed booking forward. So that the full lifecycle (posted → bids →
confirmed → in transit → delivered) can be demonstrated on loads you create
yourself, the app exposes two clearly-labelled demo controls. Both hit the
**real API** — nothing is faked locally:

- **Simulate Carrier Bid** — in the bids section of an open or awaiting-bids
  shipment. `POST /bids` with a fictional carrier drawn from a fixed pool
  (fare anchored at 85%–120% of the shipper's expected fare, rounded to
  NPR 500; ETA 1–4 days; generated by `CarrierBidFactory`). Because bids can
  only be accepted on an `awaiting_bids` load, a shipment that is still
  `open` is first flipped with `PATCH /shipments/{id}`; if that patch fails,
  the just-created bid is deleted again so the server stays consistent.
- **Mark as In-transit / Mark as Delivered** — on the detail and tracking
  screens of scheduled/confirmed/in-transit shipments. `PATCH /shipments/{id}`
  to the next status defined by `ShipmentStatusFlow` (confirmed → in transit
  → delivered); terminal and pre-booking statuses are refused before any
  write.

The buttons are marked "Demo control — stands in for the carrier side", the
confirm dialogs say exactly what will happen, and every write goes through
the same repository chain (ownership check in the notifier, domain rules in
the repository, resilient fallback on network/server failure, honest errors
otherwise). Pull-to-refresh on another device shows the same data, because
it is all on MockAPI.

## Screens

Bottom navigation: **Home · Shipments · Post Load · Analytics · Account**.

- Splash (auth-state redirect).
- Login — validation, password visibility, error surface, demo shortcut.
- Registration — full name, phone, email, password, confirm password
  (per spec); creates the Firebase account, stores the shipper profile, and
  signs in.
- Dashboard — dynamic KPI cards (tap a stat to open the filtered list),
  next-pickup card, action-required card (most-bidded awaiting shipment),
  recent shipments.
- Shipments — search (reference/route/cities), status filter chips,
  active/inactive grouping, pull-to-refresh, skeleton, empty and error
  states with retry.
- Shipment detail — route, cargo, schedule, notes, shared status timeline,
  bids, a **Track Shipment** button once a carrier is engaged
  (scheduled/confirmed/in transit), and the carrier-side demo controls
  (simulate bid while bidding is open, advance status once confirmed).
- Bid details sheet — full carrier profile, fare, rating, ETA, message, and
  acceptance with confirmation (the single acceptance path; bid cards open
  it).
- Tracking — simulated live progress for moving loads, plus the
  carrier-side demo status control.
- Post Load — five validated steps (Route, Cargo, Schedule, Vehicle, Review)
  ending in the order-placed confirmation screen.
- Analytics — totals plus a "Loads created per month" bar chart from real
  `createdAt` data, and a status breakdown.
- Account — real profile, personal-info sheet, change password via a real
  Firebase reset email (demo accounts fail honestly), session-scoped
  preference toggles, and explicit "not part of this prototype" dialogs for
  help/feedback/legal/deletion. Sign-out has a confirmation.

Every visible control either works or states plainly that it is not part of
the prototype — nothing is decorative.

## Architecture

Feature-first, with presentation / domain / data separation inside each
feature. A feature's domain layer holds its entities, repository contracts
and business rules (pure Dart, no Flutter imports); its data layer holds
DTOs, the MockAPI/Firebase/mock implementations and resilient wrappers;
its presentation layer holds screens, feature widgets and Riverpod
providers. `core/` holds app-level concerns (theme, routing, DI
composition root, network interceptors, the app shell); `shared/` holds
only Flutter-level building blocks (design-system widgets, extensions).

```
lib/
├── main.dart
├── core/
│   ├── constants/    copy strings
│   ├── di/           repository providers (composition root)
│   ├── errors/       AppException hierarchy
│   ├── network/      data-source status + dio interceptors
│   ├── routing/      go_router config, routes, auth redirect
│   ├── theme/        tokens + Material theme
│   ├── utils/        validators
│   └── widgets/       app shell, bottom nav, offline banner
├── features/
│   ├── auth/               data + domain + presentation
│   ├── shipments/         the shipment aggregate (bids included):
│   │                      entities, rules, factories, DTOs,
│   │                      api/mock/resilient repositories, notifier,
│   │                      screens, widgets
│   ├── bids/              presentation (bid card, details sheet)
│   ├── create_shipment/    presentation (5-step form, confirmation)
│   ├── dashboard/          domain (stats) + presentation
│   ├── analytics/          presentation (chart + providers)
│   └── account/            presentation
└── shared/          extensions + design-system widgets
```

Dependency rules (enforced by convention, verified by the import graph):
domain depends only on `core`; data depends on its own domain + `core`;
presentation depends on its own domain plus other features' **public**
providers/widgets; `core/di` and `core/routing` are the only places
allowed to know every feature's internals (composition root and route
builders). Bids belong to the shipment aggregate — they cannot exist
without a shipment, the MockAPI nests them under shipments, and bid
acceptance is one atomic-ish multi-document write — so the `bids`
feature is presentation-focused by design, avoiding bidirectional
feature coupling.

- **State: Riverpod 2 (no codegen).** Chosen deliberately: the ODT allows any
  justified state management. This app's state is one shared async list with
  many derived projections (dashboard counts, filtered lists, per-id lookups,
  monthly buckets) — `AsyncNotifier` + `Provider` gives that with automatic
  invalidation, testable `ProviderContainer` overrides, and no boilerplate;
  Bloc's event-driven per-screen cubits would add ceremony without benefit
  here.
- **Navigation:** `go_router` with an auth redirect, stateful shell route, a
  `/shipments?filter=…` deep link used by dashboard stat cards, and a
  `/shipments/:id/tracking` route.
- **Data:** repository contracts are injected through
  `lib/core/di/repository_providers.dart`; screens never import concrete
  repositories. Dio interceptors add retry, safe logging, and data-source
  tracking (offline banner).
- **Writes:** only `ShipmentNotifier` writes shipment state; `createShipment`
  and `acceptBid` return the repository result and update state from it — no
  optimistic updates. Every screen (dashboard, list, detail, tracking,
  analytics) watches the same provider, so a created shipment or accepted bid
  propagates everywhere in one rebuild.

## Testing

```bash
flutter analyze   # 0 issues
flutter test      # 108 tests, all passing
```

Covered: shipment validation and the 3-limit rule, ownership rule (including
legacy/demo-owner mapping and blank-`shipperId` parsing), DTO ↔ JSON
round-trips, API repository error mapping and acceptance rollback, resilient
fallback behavior (network vs 4xx), auth notifier (sign-in/sign-up/profile
persistence/error surfacing, no echo-invalidation), the auth-scoped shipment
notifier (ownership filtering, owner stamping, limit enforcement, foreign
shipment refusal), derived providers (filters, stats, monthly buckets), and
widget tests for the shipments list, registration validation, and the Post
Load success + limit flows through a real router.

## Limitations (honest)

- Shipments live in MockAPI with no server-side filtering — the client
  fetches and scopes by ownership; a hostile client could read all rows from
  MockAPI directly (the backend is a mock, with no auth).
- There is no carrier app: carrier bids and the post-confirmation status
  updates (`in_transit`, `delivered`) come from seed data or the two
  labelled demo controls described above — never from a live marketplace.
- The tracking screen simulates movement; there is no real carrier GPS feed.
- Analytics is computed from the currently loaded list; no historical
  aggregation or date ranges.
- Account preferences (push/SMS/email toggles) are session-local and labelled
  as such; help centre, feedback, legal documents, and account deletion show
  explicit "not part of this prototype" dialogs.
- Password reset requires a real Firebase account (the demo account cannot
  reset — stated in the UI when attempted).
- No dark theme (light tokens only), no pagination, no image upload, no
  iOS/web builds. Firebase is configured for Android; macOS runs with the
  in-memory fallbacks.

## Reference material

- `docs/LODBOD_Flutter_Developer_Technical_Assignment 1.odt` — the
  assignment.
- `docs/PLAN.md`, `docs/TECHNICAL_NOTES.md` — planning and architecture
  notes.
- `images/` — supplied LODBOD reference screens.
- `screenshots/` — captured screens (see file names for the flow).
