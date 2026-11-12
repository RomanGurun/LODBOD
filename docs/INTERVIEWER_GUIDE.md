# LODBOD — Technical Interviewer & Evaluator Guide

> **Prepared for:** LODBOD Hiring Team – IT Department  
> **Candidate:** Junior Flutter Developer Applicant  
> **Project:** LODBOD Shipper Mobile Application  
> **Release Artifact:** `build/app/outputs/flutter-apk/app-release.apk`  
> **Test Suite:** 191 passing tests (100%) | `flutter analyze` 0 issues  

---

## 🧭 Executive Summary for the Evaluator

This guide is designed to help the technical reviewer quickly evaluate the submission against the assignment brief without spending hours configuring environments.

The project demonstrates **production-grade engineering**, not just prototype screens:
1. **Clean Architecture**: Complete decoupling of Domain (pure Dart), Data (resilient repositories, DTOs, data sources), and Presentation (Riverpod 2, GoRouter).
2. **Atomic Design System**: Strict UI hierarchy from design tokens (`tokens.dart`) to atoms, molecules, organisms, templates, and screens.
3. **Resilient Data Layer**: Handles real-world backend realities—MockAPI quirks (404 on empty reads), server outage fallback to local cache, and compensating rollbacks for multi-document operations.
4. **Security & Auth Lifecycle**: Full Firebase Authentication with Gmail verification enforcement, phone OTP linkage, and draft account deletion on cancellation.

---

## ⚡ 5-Minute Fast-Track Review (How to Test)

### Step 1: Launch & Demo Login
1. Install the APK: `adb install -r build/app/outputs/flutter-apk/app-release.apk` (or run `flutter run`).
2. On the Login Screen, open the **Email** tab and enter `demo@lodbod.com` / `Demo@1234`.
3. You land on the Dashboard with pre-seeded shipments (`LOD-1001` through `LOD-1004`).

### Step 2: Test the 3-Active-Request Limit
1. Tap the **"+" (Post Load)** tab in the bottom navigation.
2. The demo account currently has 3 active shipments (`open`, `awaiting_bids`, `in_transit`).
3. Fill in the form or tap Submit — the app triggers the exact required dialog:
   > *"You have reached the mobile request limit of 3. Please use the LODBOD web platform to create additional requests."*
4. All typed input remains intact (zero data loss).

### Step 3: Test Bid Review & Acceptance
1. Open the **Shipments** tab and tap on **`LOD-1002`** (status: *Awaiting Bids*).
2. Scroll to the bids section. Tap on any carrier quote card (e.g. *Everest Express*).
3. The **Bid Details Sheet** slides up showing the carrier profile, fare, and message.
4. Tap **"Accept Bid"** and confirm in the dialog.
5. **Observe**: The shipment instantly transitions to `confirmed`, the accepted bid is marked `Accepted`, and competing bids are automatically updated to `Rejected`.

### Step 4: Test Carrier Movement (Demo Controls)
Because this assignment only covers the shipper side, we built two clearly-labelled carrier controls hitting the live MockAPI:
* On an `open` shipment: Tap **"Simulate Carrier Bid"** to generate a synthetic quote via `CarrierBidFactory` (`POST /bids`).
* On a `confirmed` shipment: Tap **"Advance Status"** to step through `in_transit` ➔ `delivered`.

---

## 🏛️ Architecture & Decision Rationale

### 1. Why Riverpod 2 (No Code-Gen) over BLoC?
| Architectural Need | Riverpod (Implemented) | BLoC Alternative |
| :--- | :--- | :--- |
| **GoRouter Navigation Guards** | `ref.read(authNotifierProvider)` works seamlessly inside GoRouter redirects outside the widget tree. | Requires `BuildContext` or extra global singletons via `GetIt`. |
| **Computed Dashboard KPIs** | `dashboardStatsProvider` simply watches `shipmentsProvider` and derives counts reactively. | Requires manual Stream subscriptions or `BlocListener` chaining between two Blocs. |
| **Boilerplate Reduction** | `AsyncNotifier` provides loading, error, and data states natively via `AsyncValue`. | Requires creating 4–5 files per screen (`event`, `state`, `bloc`). |
| **Dependency Injection** | Built-in compile-time DI container in `lib/core/di/repository_providers.dart`. | Requires an external dependency like `get_it` or `injectable`. |

### 2. Dependency Inversion in Action
The Presentation Layer **never imports Dio, Firebase, or MockAPI**.
```dart
// The UI only knows the domain contract:
final shipmentRepositoryProvider = Provider<IShipmentRepository>((ref) {
  // Swapping between MockAPI, real production backend, or mock test doubles
  // happens here in exactly ONE file:
  return ResilientShipmentRepository(remote: remote, status: status);
});
```

---

## 🛡️ Edge Cases & Engineering Highlights

| Challenge | Real-World Problem | LODBOD Solution |
| :--- | :--- | :--- |
| **MockAPI 404 on Empty Reads** | MockAPI returns HTTP `404 Not Found` when a collection or filtered query has 0 rows instead of `200 []`. | `ApiShipmentRepository._getBids()` intercepts 404 on collections and normalizes it to an empty list `[]`. |
| **Distributed Multi-Step Failure** | Simulating a bid creates a bid record (`POST /bids`), then patches shipment status (`PATCH /shipments`). If step 2 fails, an orphan bid remains. | **Compensating Rollback**: Code catches the failure and immediately calls `DELETE /bids/:id` to maintain database consistency. |
| **Orphan Unverified Auth Accounts** | If a user signs up with a typo email and cancels, the email stays locked in Firebase. | **Safe Cancellation**: If the user leaves `/verify-email`, `cancelRegistration()` invokes `user.delete()` on Firebase Auth. |
| **Offline Resilience** | Network dropout or MockAPI rate-limiting shouldn't crash the app. | `ResilientShipmentRepository` transparently serves cached snapshots and displays a non-blocking offline banner. |
| **Tablet / Foldable Responsiveness** | Forms stretching full width on iPads and tablets look broken. | All forms and auth views are wrapped in `ConstrainedBox(maxWidth: 420)` with vertical scroll safety. |

---

## 🧪 Test Suite Breakdown (191 Tests)

Run all tests with:
```bash
flutter test
```

* **Domain & Business Rules (42 tests)**:
  - `shipment_limit_rule_test.dart`: Validates 3-active limit boundary conditions.
  - `bid_acceptance_rule_test.dart`: Validates ownership, status prerequisites, and competitor rejections.
  - `shipment_status_flow_test.dart`: Validates the forward-only lifecycle state machine.
* **Data & Repositories (56 tests)**:
  - `api_shipment_repository_test.dart`: DTO serialization, MockAPI 404 normalization, and rollback error recovery.
  - `resilient_shipment_repository_test.dart`: Automatic failover between remote API and local cache snapshots.
* **State & Riverpod Notifiers (48 tests)**:
  - `shipment_notifier_test.dart`: Ownership scoping, duplicate submission guarding.
  - `auth_notifier_test.dart`: Session restoration, profile sync, and unverified cleanup.
* **Widget & Navigation Integration (45 tests)**:
  - `registration_screen_test.dart`: Nepal phone mask (+977), Gmail validation, error banners.
  - `verify_email_screen_test.dart`: Verification link checking, resend cooldown, back button account deletion.
  - `create_shipment_screen_test.dart`: Multi-step form state persistence and limit dialog popup.

---

## 🔮 Production Roadmap (What would be added in Phase 2)

If this project were being deployed to production next week, the immediate roadmap items would be:
1. **WebSockets / SSE**: Replace carrier bid polling with WebSocket events (`pusher` or `firebase_realtime_database`) for instant push updates when a carrier submits a quote.
2. **Server-Side Authorization**: Add an `AuthInterceptor` to Dio that attaches `Authorization: Bearer <Firebase_ID_Token>` to validate client requests via Firebase Admin SDK.
3. **CI/CD Pipeline**: GitHub Actions workflow running `flutter analyze`, `flutter test`, and automated release builds via Fastlane.

---

*Thank you for reviewing this submission. We look forward to the technical discussion!*

