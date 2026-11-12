# LODBOD — Shipper Mobile Application

Technical assignment submission for the **Junior Flutter Developer** position at **LODBOD** (Hiring Team – IT Department).

> 📋 **Are you reviewing or evaluating this project?**  
> Check out the dedicated [**Interviewer & Evaluator Guide**](docs/INTERVIEWER_GUIDE.md) for a 5-minute grading walkthrough, architectural trade-offs, edge-case breakdown, and interview discussion topics.

---

## 📦 Submission Deliverables & Quick Links

| Deliverable | Location / Status | Description |
| :--- | :--- | :--- |
| **Release APK** | `build/app/outputs/flutter-apk/app-release.apk` | Built with `flutter build apk --release` (56 MB, production-optimized) |
| **Source Code** | Full project repository | Clean Architecture + Riverpod 2 + GoRouter |
| **Test Suite** | **191 passing tests (100%)** | `flutter test` across unit, domain, repository, and widget tests |
| **Code Analyzer** | **0 issues found** | `flutter analyze` passes cleanly |
| **Screen Recording** | Video Demo Walkthrough | [See Suggested Demo Checklist](#-video-demo-recording-checklist) |

---

## 🔑 Demo & Test Credentials

The app supports both **Instant Demo Mode** (zero setup required) and **Live Firebase Authentication**:

| Mode | Identifier | Password / Code | Behavior |
| :--- | :--- | :--- | :--- |
| **One-Tap Demo** | `demo@lodbod.com` | `Demo@1234` | Login screen has a **"Use demo account"** button. Pre-loaded with seed shipments (`LOD-1001`–`LOD-1004`) and pending bids. |
| **Live Gmail Signup** | Any valid `@gmail.com` | Min 6 characters | Registers real Firebase account, dispatches verification email, and enforces verification before dashboard access. |
| **Phone OTP Login** | Registered Nepal mobile (`+977 98...`) | Account password | Looks up linked profile in MockAPI, verifies password, and completes phone authentication. |

---

## 🏗️ Architecture & Engineering Highlights

The project is built on **Clean Architecture**, **Atomic UI Design**, and **Dependency Inversion**:

```
lib/
├── core/                  # App-wide infrastructure (DI root, Theme/Tokens, GoRouter, Dio interceptors, Errors)
├── shared/                # Cross-feature design system (AppCard, AppTextField, Skeletons, StateViews, Extensions)
└── features/
    ├── auth/              # Domain (AuthUser, UserProfile), Data (Firebase, MockAPI), Presentation (Login, Register, Verify)
    ├── shipments/         # Domain (Shipment, Rules, Flow), Data (Resilient Repository), Presentation (List, Detail, Tracking)
    ├── bids/              # Feature widgets (BidCard, BidDetailsSheet with acceptance)
    ├── create_shipment/   # Multi-step validated load posting wizard
    ├── dashboard/         # Real-time computed KPIs (active, bidding, completed loads, next pickup)
    ├── analytics/         # Monthly shipment volume charts and status distribution
    └── account/           # Profile management, password reset, session preferences
```

### 1. Separation of Concerns & Dependency Inversion
* **Domain Layer (Pure Dart)**: Zero dependencies on Flutter UI, Dio, or Firebase. Business rules like active load limits ([`ShipmentLimitRule`](lib/features/shipments/domain/rules/shipment_limit_rule.dart)), bid acceptance criteria ([`BidAcceptanceRule`](lib/features/shipments/domain/rules/bid_acceptance_rule.dart)), and status state machines ([`ShipmentStatusFlow`](lib/features/shipments/domain/rules/shipment_status_flow.dart)) are 100% framework-independent and unit tested.
* **Data Layer (Resilience & Adapters)**: Implements domain repository interfaces ([`IShipmentRepository`](lib/features/shipments/domain/repositories/i_shipment_repository.dart)). Swapping from MockAPI to a production backend requires touching only [`repository_providers.dart`](lib/core/di/repository_providers.dart); **zero UI screens need modification**.
* **Presentation Layer (Riverpod 2)**: UI widgets observe state via Riverpod `AsyncNotifier` and `AsyncValue`. No business logic lives inside `build()` methods.

### 2. Why Riverpod instead of BLoC?
1. **Outside-Widget Navigation Guards**: GoRouter redirect guards in [`app_router.dart`](lib/core/routing/app_router.dart) can read auth and verification state directly via `ref.read()` without requiring a `BuildContext` or third-party service locator like `GetIt`.
2. **Declarative Computed State**: The dashboard automatically derives statistics (`activeCount`, `biddingCount`, `completedCount`) from the shipment list using `ref.watch(shipmentsProvider)`, eliminating complex bloc-to-bloc communication.
3. **AsyncValue Ergonomics**: Native handling of loading, data, and error states with skeleton loaders and retry callbacks with minimal boilerplate.

### 3. Atomic Design System
* **Tokens**: [`tokens.dart`](lib/core/theme/tokens.dart) (`AppColors`, `AppTypography`, `AppSizes`, `AppDurations`).
* **Atoms**: `AppLogo`, `DashedDivider`, `StatusBadge`, `AppTextField`.
* **Molecules**: `AppCard`, `DashboardStatCard`, `EmptyStateView`, `StatusTimeline`, `AdvanceStatusButton`.
* **Organisms**: `ShipmentCard`, `BidCard`, `DashboardHeroCard`, `BidDetailsSheet`.
* **Templates**: `MainShell` (scaffold with responsive bottom nav and offline banner), `AuthPage` (scroll-safe container constrained to `maxWidth: 420` to prevent tablet and landscape stretching).

---

## 🌐 Backend & API Integration

The app connects to two dedicated MockAPI projects (one for shipments/bids, one for user profiles):

1. **Shipments & Bids API**: `https://6af2103d42c6561ced38f683.mockapi.io`
   - `GET /shipments`, `GET /shipments/:id`, `POST /shipments`, `PATCH /shipments/:id`
   - `GET /bids`, `POST /bids`, `PATCH /bids/:id`, `DELETE /bids/:id`
2. **User Profiles API**: `https://6af4414b55a1de7dcf03c6dc.mockapi.io`
   - `GET /users?firebaseUid=...`, `GET /users?phoneNumber=...`, `POST /users`, `PATCH /users/:id`

### Resilience & Rollback Protection:
* **Offline / Outage Fallback**: [`ResilientShipmentRepository`](lib/features/shipments/data/repositories/resilient_shipment_repository.dart) falls back to local cache/seed data during network or 5xx server errors, surfacing a non-intrusive offline banner in the shell. 4xx client errors are surfaced honestly.
* **Atomic Rollback on Partial Failures**: When simulating a carrier bid on an `open` shipment, the app posts the bid (`POST /bids`) and updates the shipment to `awaiting_bids` (`PATCH /shipments/:id`). If the status patch fails, the repository issues `DELETE /bids/:id` to remove the orphan bid and prevent database corruption.

---

## 📋 Assignment Requirements Checklist

| Requirement | Implementation Status | How to Verify |
| :--- | :---: | :--- |
| **Authentication** | ✅ Complete | Email + Password, Phone OTP login, and instant Demo button. |
| **Email Verification** | ✅ Complete | Gmail verification screen enforces clicking the email link; cancelling deletes unverified accounts (`user.delete()`). |
| **Dashboard** | ✅ Complete | Dynamic KPI stat cards, next pickup card, action-required card, recent shipments. |
| **Shipment List** | ✅ Complete | Search by reference/route/city, status filter chips, pull-to-refresh, skeleton loading. |
| **Shipment Details** | ✅ Complete | Route timeline, cargo specs, carrier quotes, status progress timeline. |
| **Bid Acceptance** | ✅ Complete | Tap bid to open details sheet, confirm acceptance, patches selected bid to `accepted` and competitors to `rejected`. |
| **3-Active-Request Limit** | ✅ Complete | Max 3 active loads enforced in domain rule; shows exact required dialog and prevents duplicate submission. |
| **Carrier Simulation** | ✅ Complete | Clearly-labelled demo controls to simulate incoming carrier bids and advance load status (`confirmed` ➔ `in_transit` ➔ `delivered`). |
| **Analytics Screen** | ✅ Complete | Bar chart of loads created per month from real `createdAt` timestamps, plus status breakdown. |
| **Account Screen** | ✅ Complete | Profile card with skeleton, personal info sheet, password reset, session preferences. |

---

## 🚀 Running the Project

### Prerequisites
* Flutter 3.22+ (tested with Flutter 3.50.0 / Dart 3.12.0)
* Android Studio / Xcode / VS Code / Antigravity IDE

### Run in Development
```bash
# 1. Install dependencies
flutter pub get

# 2. Run on connected device or emulator
flutter run
```

### Run Tests & Analyzer
```bash
# Run code analysis (0 warnings)
flutter analyze

# Run all 191 automated tests
flutter test
```

### Install Release APK directly to device
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎥 Video Demo Recording Checklist

When recording your 3–5 minute walk-through demo video for the hiring team, follow this recommended sequence:

1. **Authentication (1 min)**:
   - Tap **"Use demo account"** to demonstrate instant access.
   - Alternatively, show Gmail registration: enter name, phone, Gmail, password, show the verification screen, and demonstrate the "Go back" button.
2. **Dashboard & KPIs (30 sec)**:
   - Show summary cards (Active Loads, Awaiting Bids, Completed, Total Spend).
   - Tap an active stat card to show automatic filtered navigation to the Shipments screen.
3. **Shipment List & Search (30 sec)**:
   - Filter by status chips (*All, Open, Awaiting Bids, In Transit*).
   - Type in the search box (e.g. "Pokhara" or "LOD-1002").
   - Pull down to trigger `RefreshIndicator`.
4. **Post Load & 3-Request Limit (1 min)**:
   - Tap the **"+" (Post Load)** tab.
   - Complete the form (Cargo description, weight, route, schedule, expected fare).
   - If 3 loads are already active, demonstrate the **3-request limit dialog** preventing excess creation.
5. **Bid Acceptance & Carrier Simulation (1 min)**:
   - Open an `open` or `awaiting_bids` shipment.
   - Tap **"Simulate Carrier Bid"** (demonstrates live `POST /bids` and status flip).
   - Tap the bid card to open the **Bid Details Sheet**, review carrier info, and tap **"Accept Bid"**.
   - Show status changing to `confirmed` with assigned carrier.
   - Tap **"Advance Status"** to advance through `in_transit` and `delivered`.
6. **Analytics & Account (30 sec)**:
   - Open **Analytics** tab to show the monthly loads bar chart.
   - Open **Account** tab to show the authenticated profile and sign-out confirmation.
