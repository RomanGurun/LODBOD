# 🚛 LODBOD — Shipper Mobile Application

> **Flutter Technical Assignment** | Load Board Pvt. Ltd. | Candidate Submission

A production-oriented Flutter prototype for the **LODBOD Shipper App** — a load-board and shipment-coordination platform connecting shippers with carriers and drivers. This submission demonstrates a complete, polished vertical slice of the shipper workflow using clean architecture, Riverpod state management, and a fully replaceable mock-API repository layer.

---

## 📋 Table of Contents

1. [Prerequisites](#-prerequisites)
2. [Setup & Run](#-setup--run)
3. [Demo Login Credentials](#-demo-login-credentials)
4. [Implemented Features](#-implemented-features)
5. [Architecture & State Management](#-architecture--state-management)
6. [Data Flow & Repository Design](#-data-flow--repository-design)
7. [Replacing Mock with Real Backend](#-replacing-mock-with-real-backend)
8. [Project Structure](#-project-structure)
9. [Key Technical Decisions](#-key-technical-decisions)
10. [Testing](#-testing)
11. [Known Limitations](#-known-limitations)
12. [Screenshots](#-screenshots)

---

## ⚙️ Prerequisites

| Tool | Version |
|------|---------|
| Flutter | `3.27.x` or later |
| Dart | `3.6.x` or later |
| Android SDK | API 21+ (Android 5.0 Lollipop) |
| Xcode (iOS) | 15+ *(macOS only)* |
| Git | Any recent version |

```bash
# Verify your Flutter environment
flutter doctor -v
```

---

## 🚀 Setup & Run

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd lodbod

# 2. Install dependencies
flutter pub get

# 3. Run on Android (or iOS simulator / Chrome for web)
flutter run

# 4. Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> **Note:** No `.env` or API keys needed — the app uses an in-memory mock repository by default.

---

## 🔐 Demo Login Credentials

| Field | Value |
|-------|-------|
| Email | `demo@lodbod.com` |
| Phone | `9800000000` |
| Password | `Demo@1234` |
| Role | Shipper |

The app accepts **either** email or phone login. OTP verification is simulated (any 6-digit code is accepted).

---

## ✅ Implemented Features

### P0 — Required Scope

| Feature | Status | Notes |
|---------|--------|-------|
| **Splash Screen** | ✅ | Animated logo, initialization check |
| **Login** | ✅ | Email/phone + password, validation, show/hide, loading state |
| **OTP Verification** | ✅ | Simulated 6-digit OTP flow |
| **Home Dashboard** | ✅ | Active, awaiting-bids, completed counts; recent shipments; quick-post action |
| **Shipment List** | ✅ | Search by ref/route, status filter chips, empty state, pull-to-refresh |
| **Shipment Details** | ✅ | Route, cargo, schedule, vehicle, timeline, action buttons |
| **Create Shipment (multi-step)** | ✅ | Route → Cargo → Schedule → Vehicle → Review → Submit |
| **Review & Submit** | ✅ | Full summary, field validation, unique reference generation |
| **3-Request Mobile Limit** | ✅ | Enforced; prescribed message shown; form values preserved |
| **Bids Screen** | ✅ | ≥2 bids with fare, carrier, rating, ETA; accept with confirmation |
| **State Consistency** | ✅ | Single source of truth; dashboard/list/details auto-update |
| **Bottom Navigation** | ✅ | Home · Shipments · Post Load · Analytics · Account |

### P1 — Enhanced / Bonus

| Feature | Status |
|---------|--------|
| Analytics screen (chart of shipment statuses) | ✅ |
| Account screen with profile + logout | ✅ |
| Dark / Light theme toggle | ✅ |
| Offline / stale-data empty state | ✅ |
| Shimmer loading skeletons | ✅ |
| Form auto-save on 3-limit hit | ✅ |
| Haptic feedback on key interactions | ✅ |
| Localized NPR currency + Nepali date hints | ✅ |

---

## 🏗 Architecture & State Management

### Why Riverpod?

Riverpod was chosen over Provider/Bloc because:
- **Compile-time safety** — no `context`-dependent lookups that crash at runtime.
- **Async states built-in** — `AsyncValue<T>` handles loading/error/data uniformly.
- **Testability** — providers can be overridden per-test without a widget tree.
- **No boilerplate** — no events/states classes needed for straightforward flows.

### Layer Diagram

```
┌──────────────────────────────────────────────────────┐
│                   Presentation Layer                  │
│  (Screens, Widgets — Flutter UI only, no logic)       │
├──────────────────────────────────────────────────────┤
│                  ViewModel Layer                       │
│  (Riverpod Notifiers — exposes AsyncValue<T> state)   │
├──────────────────────────────────────────────────────┤
│                   Domain Layer                         │
│  (Use cases / business rules — pure Dart, no Flutter) │
├──────────────────────────────────────────────────────┤
│                  Repository Layer                      │
│  (Abstract interfaces — IShipmentRepository, etc.)    │
├──────────────────────────────────────────────────────┤
│               Data / Mock Layer                        │
│  (MockShipmentRepository — in-memory, replaceable)    │
└──────────────────────────────────────────────────────┘
```

### State Management Flow

```
User Action
    │
    ▼
Screen Widget  ──ref.read(notifier)──▶  Notifier (AsyncNotifier)
                                            │
                                            ▼
                                     Repository (abstract)
                                            │
                                            ▼
                                   MockDataSource (or real API)
                                            │
                                   AsyncValue<T> emitted back
                                            │
                                            ▼
                               Widget rebuilds via ref.watch()
```

---

## 🔄 Data Flow & Repository Design

### Single Source of Truth

All shipment data lives in `ShipmentNotifier` (a `StateNotifier<List<Shipment>>`). Every screen — dashboard, list, detail, bids — watches the **same** provider. When a shipment is created or a bid is accepted, the notifier updates its list once and all watchers rebuild automatically.

### Repository Abstraction

```dart
// Abstract contract — UI never imports the concrete class
abstract class IShipmentRepository {
  Future<List<Shipment>> getShipments();
  Future<Shipment> createShipment(CreateShipmentRequest req);
  Future<void> acceptBid(String shipmentId, String bidId);
  // ...
}

// Swappable implementations
class MockShipmentRepository implements IShipmentRepository { ... }
class RestShipmentRepository   implements IShipmentRepository { ... }  // future
```

The active implementation is injected via a Riverpod provider override — no widget code changes when switching.

### 3-Request Limit Logic

```dart
// Pure Dart business rule — testable in isolation
class ShipmentLimitRule {
  static const int mobileLimit = 3;

  static final _openStatuses = {
    ShipmentStatus.open,
    ShipmentStatus.awaitingBids,
    ShipmentStatus.scheduled,
    ShipmentStatus.confirmed,
    ShipmentStatus.inTransit,
  };

  static bool isAtLimit(List<Shipment> shipments) =>
      shipments.where((s) => _openStatuses.contains(s.status)).length >= mobileLimit;
}
```

The form state is kept alive in the notifier even when the limit is hit, so values are restored if the user navigates back.

---

## 🔀 Replacing Mock with Real Backend

This requires **zero widget changes**. The only change is the provider registration:

```dart
// Before (mock)
final shipmentRepoProvider = Provider<IShipmentRepository>(
  (_) => MockShipmentRepository(),
);

// After (real REST API)
final shipmentRepoProvider = Provider<IShipmentRepository>(
  (ref) => RestShipmentRepository(
    httpClient: ref.watch(httpClientProvider),
    baseUrl: 'https://api.lodbod.com/v1',
  ),
);
```

### Real API Mapping

| Mock method | REST equivalent |
|-------------|----------------|
| `getShipments()` | `GET /shipments?shipper_id=...` |
| `createShipment(req)` | `POST /shipments` |
| `acceptBid(id, bidId)` | `PATCH /shipments/{id}/bids/{bidId}/accept` |
| `getShipmentDetail(id)` | `GET /shipments/{id}` |

**Error handling:** `RestShipmentRepository` maps HTTP status codes → typed `AppException` subclasses. The UI already renders `AsyncValue.error` states, so it works automatically.

**Auth tokens:** A `DioInterceptor` injects Bearer tokens from `SecureStorage` and refreshes via `POST /auth/refresh` on 401. Token lifecycle is entirely in the data layer, invisible to screens.

**Pagination:** `getShipments()` returns a `PaginatedResult<Shipment>`; the notifier accumulates pages and exposes a `hasMore` flag for the list screen's `ScrollController` listener.

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/        # app colors, strings, sizes
│   ├── errors/           # AppException hierarchy
│   ├── extensions/       # DateTime, String, num helpers
│   ├── router/           # GoRouter configuration
│   ├── theme/            # ThemeData (light + dark)
│   └── utils/            # validators, formatters
│
├── data/
│   ├── mock/             # MockShipmentRepository, seed data
│   ├── remote/           # RestShipmentRepository (future)
│   └── models/           # Freeze'd data classes (JSON-serializable)
│
├── domain/
│   ├── entities/         # Pure Dart business entities
│   ├── repositories/     # Abstract interfaces
│   └── usecases/         # ShipmentLimitRule, BidAcceptRule, etc.
│
├── features/
│   ├── auth/
│   │   ├── screens/      # LoginScreen, OtpScreen
│   │   ├── widgets/      # PhoneEmailField, PasswordField
│   │   └── providers/    # authNotifierProvider
│   ├── dashboard/
│   ├── shipments/
│   │   ├── list/
│   │   ├── detail/
│   │   └── create/       # multi-step form
│   ├── bids/
│   ├── analytics/
│   └── account/
│
└── shared/
    ├── widgets/           # AppButton, AppCard, StatusBadge, ShimmerBox
    └── providers/         # shipmentProvider (global source of truth)
```

---

## 🔑 Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | **Riverpod 2** | Type-safe, testable, async-first |
| Navigation | **GoRouter** | Deep-link ready, declarative, nested routes |
| Data classes | **Freezed + json_serializable** | Immutable, copyWith, sealed unions |
| HTTP (future) | **Dio** | Interceptors, multipart, cancellation |
| Local storage | **shared_preferences / flutter_secure_storage** | Tokens secure, prefs lightweight |
| Forms | **flutter_form_builder** | Validation, field types, focus chain |
| UI components | Custom design system | Consistent orange/white LODBOD brand |
| Testing | **flutter_test + mockito** | Unit tests for domain + widget smoke tests |

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Coverage

| Test file | What it covers |
|-----------|----------------|
| `shipment_limit_rule_test.dart` | 3-request limit logic (all status combos) |
| `create_shipment_validation_test.dart` | Required fields, identical pickup/dest, past date |
| `shipment_filter_test.dart` | Search + status filter correctness |
| `bid_acceptance_test.dart` | Accept updates status; duplicate accept rejected |
| `dashboard_counts_test.dart` | Counts match filtered list |
| `shipment_notifier_test.dart` | State consistency after create/accept |
| `login_screen_test.dart` | Widget smoke test, validation messages |

---

## ⚠️ Known Limitations

- **No persistent storage** — mock data resets on app restart. Planned: Hive or Isar for local cache.
- **No push notifications** — out of scope per assignment spec.
- **Analytics screen** — shows static/mock chart data; no real query engine.
- **OTP** — any 6 digits accepted; production would call a real SMS gateway.
- **Bid acceptance conflict** — the race-condition guard is simulated with a mutex in the notifier; production needs server-side idempotency keys.
- **Image upload** — form has a placeholder; `image_picker` + presigned S3 URL needed for production.
- **iOS** — untested on physical device (simulator verified).

---

## 📸 Screenshots

Refer to `/dos/` directory for the reference UI screens included with the assignment.

---

## 📝 Technical Note — Engineering Decisions & Trade-offs

### Why a repository pattern for a mock app?

The mock repository is not a shortcut — it is the same interface a production `RestShipmentRepository` will implement. This means the entire UI + ViewModel layer is **already written for production**; swapping the data source is a one-line provider change. This was a deliberate choice to show that the architecture is not "mock-only."

### Form state preservation on limit hit

When the user hits the 3-request limit mid-form, `GoRouter` pops to the dashboard but the `CreateShipmentFormNotifier` retains its state via `keepAlive: true`. When the user re-navigates to Post Load, the form resumes from where they left off. This avoids the frustrating UX of losing typed data.

### Async state machine

Every screen consumes `AsyncValue<T>` from its notifier and renders three branches:

```dart
ref.watch(shipmentListProvider).when(
  loading: () => ShimmerListView(),
  error:   (e, _) => ErrorRetryWidget(onRetry: () => ref.refresh(shipmentListProvider)),
  data:    (shipments) => ShipmentListView(shipments),
);
```

This ensures **no screen can accidentally show stale data or miss an error state**.

### Bid acceptance safety

Accepting a bid goes through a local mutex and an optimistic UI update:
1. UI immediately shows "Accepting…" and disables the button.
2. Repository call is awaited.
3. On success → notifier updates shipment status to `Confirmed`.
4. On failure → notifier reverts state and shows an error dialog.
5. A `bool _acceptInProgress` flag prevents duplicate taps from sending two requests.

---

## 🤝 Attribution

- UI inspiration: LODBOD Shipper reference screens (supplied by evaluator).
- Sample data: fictional (Nepali routes, carriers, fares) as specified.
- Packages: see `pubspec.yaml`. All listed packages are open-source (MIT / BSD).
- Code assistant: used for boilerplate generation and documentation; all architecture decisions, business logic, and widget composition are original work.

---

*Built with ❤️ and Flutter | LODBOD Technical Assessment 2026*
