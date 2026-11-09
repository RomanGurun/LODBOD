# 🧠 LODBOD — Technical Notes, Architecture & Build Strategy

> This document is the internal engineering reference for the LODBOD Shipper Flutter app.  
> It covers architecture decisions, data flow, interview prep, build order, and design tokens.  
> The public-facing `README.md` at the project root is the submission README for evaluators.

---

## 📋 Table of Contents

1. [Assignment Understanding](#-assignment-understanding)
2. [The Shipment Lifecycle](#-the-shipment-lifecycle)
3. [Architecture Blueprint](#-architecture-blueprint)
4. [Package Choices & Rationale](#-package-choices--rationale)
5. [Data Flow & Repository Design](#-data-flow--repository-design)
6. [3-Request Limit Logic](#-3-request-limit-logic)
7. [Replacing Mock with Real Backend](#-replacing-mock-with-real-backend)
8. [Project Folder Structure](#-project-folder-structure)
9. [5-Day Smart Build Order](#-5-day-smart-build-order)
10. [Design System Tokens](#-design-system-tokens)
11. [Seed Data Reference](#-seed-data-reference)
12. [Interview Talking Points](#-interview-talking-points)
13. [Pre-Submission Checklist](#-pre-submission-checklist)

---

## 📖 Assignment Understanding

**Company:** Load Board Pvt. Ltd. (LODBOD) — Nepal-based freight marketplace  
**App:** Shipper-side mobile app — the person who *posts loads* and *hires carriers*  
**Scope:** Polished Flutter prototype demonstrating the full shipment lifecycle  
**Timebox:** 5 days | ~10–12 focused hours  
**Primary Platform:** Android (APK deliverable)  
**Backend:** MockAPI / in-memory fake data (replaceable by real API)

### Core Demo Journey (Must Work Flawlessly)

```
Launch app → Splash → Login
       │
       ▼
   Dashboard  (shows counts: Active 2, Awaiting Bids 1, Completed 1)
       │
       ▼
   Shipment List  (search + filter chips work)
       │
       ▼
   LOD-1002 Detail  (Awaiting Bids)
       │
       ▼
   Bids Screen  (Himalayan Cargo Rs.32,000 | Swift Transport Rs.29,500)
       │
       ▼
   Accept Bid → Confirmation dialog → Success → Status = Confirmed
       │
       ▼
   Post Load → Multi-step form → Review → 3-Limit hit → Message shown
       │
       ▼
   Dashboard  (counts updated, new shipment appears in list)
```

---

## 🔄 The Shipment Lifecycle

```
[Open / Awaiting Bids]
       │  Carriers submit bids
       ▼
[Scheduled / Confirmed]   ← Shipper accepts a bid
       │
       ▼
[In Transit]              ← Carrier picks up cargo
       │
       ▼
[Delivered]               ← Terminal positive state

[Cancelled / Expired]     ← Terminal negative states
```

### Which Statuses Count Toward the 3-Request Mobile Limit?

| Status | Counts? |
|--------|---------|
| Open | ✅ Yes |
| Awaiting Bids | ✅ Yes |
| Scheduled | ✅ Yes |
| Confirmed | ✅ Yes |
| In Transit | ✅ Yes |
| Delivered | ❌ No |
| Cancelled | ❌ No |
| Expired | ❌ No |

> **Seed data starts with exactly 3 open requests (LOD-1001, LOD-1002, LOD-1004).**  
> This means the limit is hit immediately — perfect for demonstrating the feature in a live demo.

---

## 🏗 Architecture Blueprint

### Layer Diagram

```
┌──────────────────────────────────────────────────────┐
│                   Presentation Layer                  │
│  (Screens, Widgets — Flutter UI only, zero logic)     │
├──────────────────────────────────────────────────────┤
│                  ViewModel Layer                       │
│  (Riverpod Notifiers — exposes AsyncValue<T> state)   │
├──────────────────────────────────────────────────────┤
│                   Domain Layer                         │
│  (Business rules — pure Dart, no Flutter imports)     │
├──────────────────────────────────────────────────────┤
│                  Repository Layer                      │
│  (Abstract interfaces — IShipmentRepository, etc.)    │
├──────────────────────────────────────────────────────┤
│               Data / Mock Layer                        │
│  (MockShipmentRepository — in-memory, replaceable)    │
└──────────────────────────────────────────────────────┘
```

### State Flow Per Screen

```
User Action (tap, submit, search)
        │
        ▼
  Screen Widget
  ref.read(notifier.notifier).doSomething()
        │
        ▼
  AsyncNotifier  ──calls──▶  IShipmentRepository (abstract)
                                      │
                                      ▼
                             MockShipmentRepository
                             (or RestShipmentRepository)
                                      │
                             AsyncValue<T> emitted
                                      │
                                      ▼
                  Widget rebuilds via ref.watch(provider)
```

### AsyncValue Usage — Every Screen

```dart
ref.watch(shipmentListProvider).when(
  loading: () => ShimmerListView(),
  error:   (e, _) => ErrorRetryWidget(onRetry: () => ref.refresh(shipmentListProvider)),
  data:    (shipments) => ShipmentListView(shipments: shipments),
);
```

No screen can show stale data or silently swallow an error.

---

## 📦 Package Choices & Rationale

```yaml
dependencies:
  flutter_riverpod: ^2.5.1       # State: compile-safe, async-first, testable
  riverpod_annotation: ^2.3.5    # Code-gen for providers
  go_router: ^14.2.7             # Navigation: declarative, deep-link ready
  freezed_annotation: ^2.4.1    # Immutable data classes, copyWith, sealed unions
  json_annotation: ^4.9.0        # JSON serialization for models
  dio: ^5.4.3+1                  # HTTP: interceptors, auth tokens, cancellation
  flutter_form_builder: ^9.3.0   # Multi-step forms with validation
  form_builder_validators: ^10.0.1
  flutter_secure_storage: ^9.0.0 # Secure token storage
  shared_preferences: ^2.2.3     # Light user prefs
  shimmer: ^3.0.0                # Skeleton loaders
  lottie: ^3.1.2                 # Smooth animations
  fl_chart: ^0.68.0              # Analytics chart
  intl: ^0.19.0                  # NPR currency + date formatting
  gap: ^3.0.1                    # Cleaner spacing widget

dev_dependencies:
  build_runner: ^2.4.9
  freezed: ^2.5.2
  riverpod_generator: ^2.4.0
  json_serializable: ^6.8.0
  mockito: ^5.4.4
  flutter_lints: ^5.0.0
```

### Why Riverpod over Bloc or Provider?

| Concern | Riverpod | Bloc | Provider |
|---------|----------|------|----------|
| Compile-time safety | ✅ Full | ✅ | ⚠️ Partial |
| AsyncValue built-in | ✅ | ❌ manual | ❌ manual |
| Testable without widget | ✅ | ✅ | ⚠️ |
| Boilerplate | 🟢 Low | 🔴 High | 🟡 Medium |
| Learning curve | 🟡 Medium | 🔴 High | 🟢 Low |

---

## 🔄 Data Flow & Repository Design

### Single Source of Truth

All shipment data lives in a single global `shipmentProvider` (`StateNotifier<List<Shipment>>`).  
Every screen — dashboard, list, detail, bids — watches **the same provider**.  
When a shipment is created or a bid is accepted, one notifier update propagates everywhere.

### Repository Interface (Abstract Contract)

```dart
// lib/domain/repositories/i_shipment_repository.dart
abstract class IShipmentRepository {
  Future<List<Shipment>> getShipments();
  Future<Shipment> getShipmentById(String id);
  Future<Shipment> createShipment(CreateShipmentRequest request);
  Future<Shipment> acceptBid(String shipmentId, String bidId);
  Future<List<Bid>> getBidsForShipment(String shipmentId);
}
```

The UI **never** imports `MockShipmentRepository` directly.  
It only depends on `IShipmentRepository` — injected via Riverpod.

### Dependency Injection via Riverpod

```dart
// lib/shared/providers/repository_providers.dart

// Switch this ONE line to go from mock → production
final shipmentRepoProvider = Provider<IShipmentRepository>(
  (_) => MockShipmentRepository(),           // ← mock
  // (ref) => RestShipmentRepository(dio: ref.watch(dioProvider)), // ← real
);
```

---

## 🚦 3-Request Limit Logic

Implemented as a **pure Dart class** in the domain layer — no Flutter, fully testable.

```dart
// lib/domain/usecases/shipment_limit_rule.dart

class ShipmentLimitRule {
  static const int mobileLimit = 3;

  static const _openStatuses = {
    ShipmentStatus.open,
    ShipmentStatus.awaitingBids,
    ShipmentStatus.scheduled,
    ShipmentStatus.confirmed,
    ShipmentStatus.inTransit,
  };

  /// Returns true if the user has reached the mobile request limit.
  static bool isAtLimit(List<Shipment> shipments) =>
      shipments.where((s) => _openStatuses.contains(s.status)).length >= mobileLimit;

  /// Returns count of open/active shipments.
  static int countActive(List<Shipment> shipments) =>
      shipments.where((s) => _openStatuses.contains(s.status)).length;
}
```

### Form Preservation on Limit Hit

The `CreateShipmentFormNotifier` uses `keepAlive: true` on its Riverpod provider.  
When the limit dialog is shown and the user dismisses/navigates away, the form state is **not destroyed**.  
Navigating back to Post Load restores exactly what was typed.

---

## 🔀 Replacing Mock with Real Backend

### Zero widget changes required. Only swap the provider:

```dart
// Before (mock)
final shipmentRepoProvider = Provider<IShipmentRepository>(
  (_) => MockShipmentRepository(),
);

// After (real Dio REST client)
final shipmentRepoProvider = Provider<IShipmentRepository>(
  (ref) => RestShipmentRepository(
    dio: ref.watch(dioProvider),
    baseUrl: 'https://api.lodbod.com/v1',
  ),
);
```

### Mock → Real API Mapping

| Repository Method | REST Endpoint |
|------------------|---------------|
| `getShipments()` | `GET /shipments?shipper_id={id}&page={n}` |
| `getShipmentById(id)` | `GET /shipments/{id}` |
| `createShipment(req)` | `POST /shipments` |
| `acceptBid(id, bidId)` | `PATCH /shipments/{id}/bids/{bidId}/accept` |
| `getBidsForShipment(id)` | `GET /shipments/{id}/bids` |

### Authentication Token Lifecycle

```
Login response  →  Store access_token + refresh_token in SecureStorage
                        │
Every request  →  DioInterceptor injects "Authorization: Bearer <token>"
                        │
On 401         →  POST /auth/refresh  →  Store new tokens  →  Retry request
                        │
On refresh fail →  Clear tokens  →  Navigate to Login
```

This is entirely in the data layer — screens never handle tokens.

### Pagination

```dart
class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final bool hasMore;
}
```

The list screen's `ScrollController` triggers `notifier.loadNextPage()` near the bottom.  
The notifier appends new pages to its list and flips `hasMore` when exhausted.

### Error Mapping

```dart
// lib/core/errors/app_exception.dart
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException { ... }
class AuthException extends AppException { ... }
class LimitException extends AppException { ... }  // 3-request limit from server
class ValidationException extends AppException { ... }
class ServerException extends AppException { ... }
```

The UI renders `AsyncValue.error` → `ErrorRetryWidget` automatically for all types.

---

## 📁 Project Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       # Brand orange: #DF3A0C
│   │   ├── app_strings.dart      # All user-visible copy
│   │   └── app_sizes.dart        # Spacing, radius, icon sizes
│   ├── errors/
│   │   └── app_exception.dart    # Sealed exception hierarchy
│   ├── extensions/
│   │   ├── date_ext.dart         # formatNepalDate(), isPast()
│   │   ├── string_ext.dart       # isValidEmail(), isValidPhone()
│   │   └── num_ext.dart          # toNPR() → "Rs. 18,000"
│   ├── router/
│   │   └── app_router.dart       # GoRouter, auth guard, all routes
│   └── theme/
│       ├── app_theme.dart        # Light ThemeData
│       └── app_theme_dark.dart   # Dark ThemeData
│
├── data/
│   ├── mock/
│   │   ├── mock_shipment_repository.dart
│   │   ├── mock_auth_repository.dart
│   │   └── seed_data.dart        # LOD-1001..1004 + bids
│   ├── remote/                   # Placeholder for RestShipmentRepository
│   └── models/
│       ├── shipment_model.dart   # @freezed, fromJson/toJson
│       ├── bid_model.dart
│       └── user_model.dart
│
├── domain/
│   ├── entities/
│   │   ├── shipment.dart         # Pure Dart entity + status enum
│   │   ├── bid.dart
│   │   └── user.dart
│   ├── repositories/
│   │   ├── i_shipment_repository.dart
│   │   └── i_auth_repository.dart
│   └── usecases/
│       ├── shipment_limit_rule.dart   # isAtLimit(), countActive()
│       ├── shipment_validator.dart    # validateCreateForm()
│       └── bid_acceptance_rule.dart   # canAccept(), isAlreadyAccepted()
│
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── otp_screen.dart
│   │   ├── widgets/
│   │   │   └── phone_email_field.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   │
│   ├── dashboard/
│   │   ├── screens/dashboard_screen.dart
│   │   ├── widgets/
│   │   │   ├── summary_card.dart
│   │   │   └── recent_shipment_tile.dart
│   │   └── providers/dashboard_provider.dart
│   │
│   ├── shipments/
│   │   ├── list/
│   │   │   ├── screens/shipment_list_screen.dart
│   │   │   ├── widgets/shipment_card.dart
│   │   │   └── providers/shipment_list_provider.dart
│   │   ├── detail/
│   │   │   ├── screens/shipment_detail_screen.dart
│   │   │   └── widgets/status_timeline.dart
│   │   └── create/
│   │       ├── screens/
│   │       │   ├── create_shipment_screen.dart  # stepper shell
│   │       │   ├── step1_route_screen.dart
│   │       │   ├── step2_cargo_screen.dart
│   │       │   ├── step3_schedule_screen.dart
│   │       │   ├── step4_vehicle_screen.dart
│   │       │   └── step5_review_screen.dart
│   │       └── providers/create_shipment_provider.dart
│   │
│   ├── bids/
│   │   ├── screens/bids_screen.dart
│   │   ├── widgets/bid_card.dart
│   │   └── providers/bid_provider.dart
│   │
│   ├── analytics/
│   │   └── screens/analytics_screen.dart
│   │
│   └── account/
│       └── screens/account_screen.dart
│
└── shared/
    ├── providers/
    │   ├── shipment_provider.dart      # Single source of truth
    │   └── repository_providers.dart  # DI injection point
    └── widgets/
        ├── app_button.dart
        ├── app_card.dart
        ├── status_badge.dart
        ├── shimmer_box.dart
        ├── empty_state_widget.dart
        └── error_retry_widget.dart
```

---

## 🗓 5-Day Smart Build Order

### Day 1 — Foundation
- [ ] Clean project, add all packages to `pubspec.yaml`, run `flutter pub get`
- [ ] Create full folder structure
- [ ] `AppColors`, `AppTheme` (orange `#DF3A0C` / white brand)
- [ ] `AppRouter` with GoRouter (all route name constants)
- [ ] All domain entities with Freezed (`Shipment`, `Bid`, `User`, enums)
- [ ] Repository interfaces (`IShipmentRepository`, `IAuthRepository`)
- [ ] `seed_data.dart` (LOD-1001 → LOD-1004 + 2 bids for LOD-1002)

### Day 2 — Auth + Dashboard
- [ ] `SplashScreen` — logo + `AnimatedOpacity`, navigate after 2s
- [ ] `LoginScreen` — email/phone toggle, password show/hide, validation, loading
- [ ] `OtpScreen` — 6 boxes, auto-advance, resend countdown
- [ ] `MockAuthRepository` — demo credential check + simulated 1.5s delay
- [ ] `DashboardScreen` — `SummaryCard ×3`, recent shipments list, quick FAB
- [ ] `DashboardProvider` — derives counts from `shipmentProvider`

### Day 3 — Shipments Core
- [ ] `ShipmentListScreen` — search bar, status filter chips, `ShipmentCard` list
- [ ] `ShipmentCard` — reference, route, cargo, date, status badge, bid count
- [ ] `ShipmentDetailScreen` — route summary, cargo section, status timeline
- [ ] `StatusBadge` — colored chip per status, text label (not color-only)
- [ ] `ShimmerBox` for all loading states (list + detail)
- [ ] `EmptyStateWidget` for search/filter zero results

### Day 4 — Create Flow + Bids
- [ ] `CreateShipmentScreen` — multi-step with `PageView` or `Stepper`
  - Step 1: Pickup + Destination (not identical, not blank)
  - Step 2: Cargo (description, category, weight + unit)
  - Step 3: Schedule (date picker, cannot be past)
  - Step 4: Vehicle type selection (chips/cards)
  - Step 5: Review summary → Submit
- [ ] `ShipmentLimitRule` check at submit; show prescribed message; preserve form
- [ ] `BidsScreen` — 2 bid cards with fare, carrier, rating stars, ETA
- [ ] Accept bid → `AlertDialog` confirmation → update state → success snackbar

### Day 5 — Polish + Tests + Delivery
- [ ] Analytics screen — `fl_chart` pie/bar of status distribution
- [ ] Account screen — profile card + logout
- [ ] Write all 7 test files (see Testing section in README.md)
- [ ] `flutter analyze` — zero issues
- [ ] `flutter build apk --release`
- [ ] Record 2-min demo video
- [ ] Final `git` commit + push

---

## 🎨 Design System Tokens

### Colors

| Token | Hex | Usage |
|-------|-----|-------|
| Primary (orange) | `#DF3A0C` | Buttons, active nav, badges |
| Primary Light | `#FF6B3D` | Hover states |
| Background | `#FFFFFF` | Screen background |
| Surface | `#F5F5F5` | Cards, fields |
| Text Primary | `#1A1A1A` | Headings, body |
| Text Secondary | `#6B6B6B` | Subtitles, hints |
| Divider | `#E0E0E0` | Separators |
| Error | `#B00020` | Validation errors |
| Success | `#2E7D32` | Confirmed, delivered |

### Status Badge Colors

| Status | Background | Text color | Label |
|--------|-----------|-----------|-------|
| Open | `#E3F2FD` | `#1565C0` | "Open" |
| Awaiting Bids | `#FFF3E0` | `#E65100` | "Awaiting Bids" |
| Scheduled | `#F3E5F5` | `#6A1B9A` | "Scheduled" |
| Confirmed | `#E8F5E9` | `#1B5E20` | "Confirmed" |
| In Transit | `#DF3A0C` | `#FFFFFF` | "In Transit" |
| Delivered | `#2E7D32` | `#FFFFFF` | "Delivered" |
| Cancelled | `#B71C1C` | `#FFFFFF` | "Cancelled" |

### Spacing & Sizing

| Token | Value |
|-------|-------|
| Border radius — card | `12px` |
| Border radius — field | `8px` |
| Border radius — chip | `24px` |
| Screen horizontal padding | `16px` |
| Card vertical padding | `16px` |
| Icon size — nav | `24px` |
| Touch target minimum | `48×48px` |

---

## 📊 Seed Data Reference

```dart
// Active count on launch = 3 → limit immediately demonstrable

Shipment(
  ref: 'LOD-1001', from: 'Kathmandu', to: 'Pokhara',
  status: ShipmentStatus.inTransit,       // ← COUNTS toward limit
  fare: 18000, cargo: 'Steel pipes', weight: 10, unit: 'tonnes',
  pickupDate: DateTime(2026, 10, 14),
),

Shipment(
  ref: 'LOD-1002', from: 'Birgunj', to: 'Kathmandu',
  status: ShipmentStatus.awaitingBids,    // ← COUNTS toward limit
  cargo: 'Cement', weight: 12, unit: 'tonnes',
  pickupDate: DateTime(2026, 10, 15),
  bids: [
    Bid(carrier: 'Himalayan Cargo', fare: 32000, rating: 4.6, etaDays: 2),
    Bid(carrier: 'Swift Transport',  fare: 29500, rating: 4.1, etaDays: 3),
  ],
),

Shipment(
  ref: 'LOD-1003', from: 'Butwal', to: 'Narayanghat',
  status: ShipmentStatus.delivered,       // ← does NOT count
  fare: 12500, cargo: 'Rice sacks', weight: 8,
  pickupDate: DateTime(2026, 10, 9),
),

Shipment(
  ref: 'LOD-1004', from: 'Kathmandu', to: 'Biratnagar',
  status: ShipmentStatus.scheduled,       // ← COUNTS toward limit
  fare: 24000, cargo: 'Furniture', weight: 4,
  pickupDate: DateTime(2026, 10, 16),
),
```

---

## 💬 Interview Talking Points

### "Walk me through your architecture"
> "I used Clean Architecture with four layers: Presentation, ViewModel (Riverpod notifiers), Domain (pure Dart business rules), and Data (repository interfaces + mock/real implementations). The UI only talks to notifiers via `ref.watch`. Notifiers call `IShipmentRepository` — an abstract interface. `MockShipmentRepository` holds in-memory data today. When LODBOD integrates a real API, we register `RestShipmentRepository` in one provider line — zero widget changes."

### "Where is the 3-request limit enforced?"
> "In a pure-Dart `ShipmentLimitRule` class in the domain layer — no Flutter imports, fully unit-testable. The `CreateShipmentNotifier` calls `ShipmentLimitRule.isAtLimit(shipments)` before submitting. This keeps the business rule isolated and easy to verify. In production, the server enforces the same rule server-side, and we map the error to a `LimitException` which the UI handles gracefully."

### "What if the user confirms bid acceptance but the server fails?"
> "The notifier does an optimistic update — immediately marks 'Accepting…' and disables the button. If the repository throws, the notifier catches it, reverts state to `awaitingBids`, and shows an error dialog with retry. The user never sees a half-updated state. A `bool _acceptInProgress` flag also prevents duplicate taps."

### "How do you replace the mock with a real API?"
> "One line in the Riverpod provider registration. The UI and ViewModels are already written against `IShipmentRepository`. I'd create `RestShipmentRepository` implementing the same interface, backed by Dio with a `DioInterceptor` for auth headers and token refresh. No screen imports the concrete class — only the interface."

### "How do you prevent duplicate shipment submissions?"
> "Client-side: an `_isSubmitting` flag in the notifier disables the submit button during inflight requests. Server-side: each `POST /shipments` carries a UUID idempotency key generated on the client. If the user submits twice (network retry, double-tap), the server returns the existing shipment for that key rather than creating a duplicate."

### "How would you handle offline / stale data?"
> "Stale-while-revalidate pattern with a local Hive cache. On load, the notifier immediately emits cached data (fast UI render), then fetches fresh data from the API in the background and updates the state. If the API fails, the user sees the cached data with a 'Last updated X minutes ago' banner."

### "What would you improve with one more day?"
> "Local persistence with Hive — data resets on restart right now, which is fine for a prototype but jarring in production. Second priority: proper pagination on the shipment list. Third: a push notification handler for bid updates using FCM."

---

## ✅ Pre-Submission Checklist

### Code Quality
- [ ] `flutter analyze` — zero warnings, zero errors
- [ ] `flutter test` — all tests green
- [ ] No `print()` statements (use proper logging)
- [ ] No unused imports or dead variables
- [ ] All `TODO` comments addressed or documented

### Functionality
- [ ] Demo credentials work (email + phone both paths)
- [ ] All 5 bottom nav tabs navigate (no dead tabs)
- [ ] Dashboard counts match shipment list counts
- [ ] Shipment search works (by reference + route)
- [ ] Status filter chips work + empty state shows
- [ ] Create shipment all 5 steps work + validation
- [ ] Review screen shows complete summary
- [ ] 3-limit message shows exact prescribed text
- [ ] Form values preserved after limit hit
- [ ] LOD-1002 shows 2 bids with correct data
- [ ] Bid acceptance updates status to Confirmed
- [ ] Lowest bid NOT auto-labelled "best"

### Build & Delivery
- [ ] `flutter build apk --release` succeeds
- [ ] APK installs and runs on Android device/emulator
- [ ] `README.md` complete (see template)
- [ ] Git history has meaningful, granular commits
- [ ] Repository is clean (no `.dart_tool/`, build/, etc. committed)
- [ ] Demo video recorded (login → dashboard → bids → accept → create → limit)

