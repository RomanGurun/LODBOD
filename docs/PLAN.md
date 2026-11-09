# LODBOD — 3-Day Build Plan & Commit Strategy

> Working plan. `README.md` and `TECHNICAL_NOTES.md` are aspirational — the app is
> **not** built yet. This file is the source of truth for execution.
> Status: planning only. No feature code written yet.

---

## 1. State management: Riverpod 2 (`flutter_riverpod`)

One-liner for stakeholders:

> Riverpod gives compile-time-safe, testable state with built-in async handling
> (`AsyncValue`), so every screen explicitly renders loading/error/empty/data and
> the whole app shares one source of truth.

Why not others:

| Option | Verdict |
|--------|---------|
| **Riverpod** | Chosen — no `context` crashes, `AsyncValue` built in, easy mock overrides in tests, low boilerplate |
| Bloc | Too much ceremony (events/states) for a 3-day slice |
| Provider | Less safe, async states manual |
| setState only | Fails the "state consistency across screens" criterion |

Decisions:
- **No codegen** (`riverpod_generator`/`build_runner`). Hand-write `Provider`/`AsyncNotifier`.
- **No Freezed.** Hand-written immutable models with `copyWith` + `==`/`hashCode`.
- **LOD-1002 has 2 bids** (matches required 2-bid comparison).

### Provider map

```
IShipmentRepository (abstract)
   └── MockShipmentRepository (seed data + fake delay + failure flag)
          ▲
   shipmentRepoProvider (DI seam → swap to Rest later)
          ▲
   ShipmentNotifier (AsyncNotifier<List<Shipment>>)   ← SINGLE SOURCE OF TRUTH
          ├── active/awaiting/completed count providers (derived)
          ├── shipmentListProvider (search + status filter)
          ├── shipmentDetailProvider(id)
          ├── bidsProvider(shipmentId)
          └── createShipmentNotifier (keepAlive → preserves form on limit)
   authRepoProvider → AuthNotifier (splash / login / otp)
```

Rule: screens `watch` providers; never hold shipment copies. Create/accept mutates
the notifier once → dashboard, list, detail, bids update automatically.

### Notifier contracts (approved adjustments)

`ShipmentNotifier` is the single source of truth and the only writer of
`List<Shipment>`.

- `createShipment(draft)`:
  - Guard duplicate submissions with an `_isCreating` flag.
  - **Enforce the 3-active-shipment limit inside the notifier** (not only in the
    form notifier), using `ShipmentLimitRule.isAtLimit(currentList)`; throw
    `LimitException` without mutating state.
  - `await repo.createShipment(...)`; **only after success** append the returned
    shipment to state. On failure rethrow; state untouched.
- `acceptBid(shipmentId, bidId)`:
  - Guard duplicate taps with `_acceptInProgress`.
  - `await repo.acceptBid(...)`; **update state from the updated `Shipment`
    returned by the repository**. Never optimistic — state changes only after
    success. On failure rethrow; state untouched.
- Derived providers (`dashboardStats`, `filteredShipments`, `shipmentById`) must
  handle `AsyncLoading` / `AsyncData` / `AsyncError` safely by reading the
  `AsyncValue` from the notifier (pass through loading/error, transform only data).
- Riverpod 2 `NotifierProvider` is kept alive by default; **do not add
  `keepAlive`**. Only use `autoDispose` intentionally.

Create form state remains separate from the dataset and survives validation
errors and limit hits. It delegates the limit check and persistence to
`ShipmentNotifier` (defense in depth: form pre-checks for UX, notifier enforces).

### Auth & fake-data decisions (final)

- **Auth = Firebase Authentication, email/password only.** Behind
  `IAuthRepository`. `FirebaseAuthRepository` is the real impl;
  `MockAuthRepository` is the fallback so the app always runs before Firebase is
  configured. Provider selects Firebase only when configured.
  - Phone OTP is out of scope for the 3-day build (needs SHA fingerprints/billing).
  - `google-services.json` / `firebase_options.dart` are gitignored and provided
    locally; documented in README.
- **Shipments = in-code fake API, shaped like real REST.** No hosted fake API.
  `FakeShipmentApi` returns JSON via `Future.delayed` with a failure flag.
  Endpoints mirrored: `GET /shipments`, `GET /shipments/{id}`, `POST /shipments`,
  `PATCH /shipments/{id}/bids/{bidId}/accept`, `GET /shipments/{id}/bids`.
- **Two model layers per entity:** `data/models/*_model.dart` (JSON DTO with
  `fromJson`/`toJson`/`toEntity`) and `domain/entities/*.dart` (pure entity).
  Repository maps DTO → entity; UI/notifiers never see JSON.
- **Fields (real-backend feel):** uuid ids, human `reference` (LOD-xxxx),
  nested shipper/carrier summaries, `cargo {description, category, weight,
  weightUnit}`, `pickupAt` ISO-8601, `expectedFare {amount, currency: NPR}`,
  `status`, `bidCount`, `acceptedBidId`, `assignedCarrier`, `bids[]`,
  `timeline[]`, `createdAt`/`updatedAt`. Response envelope includes
  `data`/`meta{page,pageSize,total,hasMore}`; errors use a typed envelope.
- **Reads are resilient, writes are honest:** DTO/mock read failures may fall
  back to seed data with a visible "sample data" marker; create/accept failures
  surface errors and never fake success.
- Seed data uses **future dates** and exactly 3 active shipments
  (LOD-1001/1002/1004) so the 3-limit demo triggers immediately.

---

## 2. Working method

Two rules:

1. Every commit compiles, `flutter analyze` is clean, and the app runs.
2. One commit = one demoable slice with a Definition of Done (DoD). The git log is
   the progress report.

Conventional Commits: `feat:`, `fix:`, `test:`, `chore:`, `docs:`.

---

## 3. Commit sequence

### Day 1 — Foundation + Auth

- [ ] `chore: remove counter, wire theme + router shell + ProviderScope`
  DoD: app launches into a splash placeholder; zero analyzer issues.
- [ ] `feat(domain): entities, status enums, repository interfaces, limit/validation rules`
  DoD: pure Dart, no Flutter imports; `flutter test` green for rules.
- [ ] `feat(data): DTO models + seed + FakeShipmentApi + MockAuthRepository`
  DoD: DTO↔entity mapping; JSON-shaped fake API with async delay + failure flag;
  repo returns seed data through the interface; error can be forced.
- [ ] `feat(auth): FirebaseAuthRepository + email/password provider switch`
  DoD: IAuthRepository seam; Firebase used only when configured, mock otherwise.
- [ ] `feat(providers): DI + shipment/auth notifiers (single source of truth)`
  DoD: counts + list derive from one notifier; unit-testable via override.
- [ ] `feat(auth): splash → login → OTP (validation, show/hide, loading)`
  DoD: demo credentials reach Home; invalid input shows messages.
- [ ] `feat(nav): bottom nav shell + GoRouter auth guard`
  DoD: all 5 tabs navigate; unauthenticated redirects to login.

### Day 2 — Golden path

- [ ] `feat(dashboard): summary cards + recent shipments + quick post`
  DoD: counts match list data; tapping a summary opens filtered list.
- [ ] `feat(shipments): list with search, status chips, shimmer/empty/error`
  DoD: search by ref/route works; filters work; empty state shown.
- [ ] `feat(shipments): detail screen with route/cargo/timeline`
  DoD: tapping a card opens the correct shipment; bid CTA for awaiting-bids.
- [ ] `feat(bids): bid list + accept with confirmation + optimistic rollback`
  DoD: accept → Confirmed; double-tap blocked; failure reverts + error dialog.

### Day 3 — Create, polish, ship

- [ ] `feat(create): multi-step form + review`
  DoD: all steps validate; review shows full summary.
- [ ] `feat(create): enforce 3-limit + preserve form + confirmation`
  DoD: exact limit message; typed values survive; new ref in list/counts.
- [ ] `feat: analytics + account (lightweight)`
  DoD: chart renders from the real dataset; logout returns to login.
- [ ] `test: rules, filtering/counts, bid acceptance, state consistency`
  DoD: meaningful tests green.
- [ ] `chore: fix overflow/responsive, analyze, build release APK`
  DoD: `flutter analyze` zero issues; APK installs and runs.
- [ ] `docs: honest README + architecture note + screenshots`
  DoD: README matches reality (remove false ✅ tables).

---

## 4. Acceptance criteria to keep visible

- 3-request limit counts: `open, awaitingBids, scheduled, confirmed, inTransit`.
  NOT: `delivered, cancelled, expired`.
- Exact limit text: "You have reached the mobile request limit of 3. Please use the
  LODBOD web platform to create additional requests."
- Form data preserved when limit hit.
- Lowest bid is NOT auto-labelled "best".
- Bid accept requires confirmation and updates only after simulated success.
- Create validation: pickup/destination not blank, not identical, weight > 0,
  pickup date not in past, review before submit.
- Search matches reference or route; status filters; empty state.
- Dashboard counts derive from the same dataset as the list.
- All bottom-nav tabs work; no dead buttons.
- Status communicated with text + color (not color only).
- Explicit loading / empty / error / success states; repeated submissions disabled.

---

## 5. Progress reporting format

After each commit:

```
DONE: shipment list + search/filter (commit 8)
VERIFIED: search by ref & route, status chips, empty state, no overflow
NEXT: detail screen → bids accept flow
```

Milestones:
- End of Day 2: live demo of golden path (login → bids → accept → counts update).
- End of Day 3: demo create + 3-limit, hand over APK + repo + README.

If time slips: cut Analytics polish first — never cut the golden path or the 3-limit.

---

## 6. Known risks

- Docs claim packages not in `pubspec.yaml` (Freezed, form_builder, fl_chart, lottie).
  Add only if truly needed; prefer hand-written models.
- Seed dates in docs are Oct 2026 (in the past relative to "today"). Use future/
  relative dates so date validation behaves.
- `README.md` currently overstates completion — must be rewritten honestly.
- Keep state out of widgets; reviewers test consistency after create/accept.
