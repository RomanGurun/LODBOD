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
- **Shipments = mockapi.io hosted mock API + in-code fallback at the repository
  boundary.** `RestShipmentRepository` talks to mockapi.io over Dio;
  `MockShipmentRepository` (seed + fake delay + failure flag) is the fallback.
  `ResilientShipmentRepository` decorates them: connectivity/timeout/5xx
  failures switch reads and writes to a local snapshot with a visible offline
  banner. Full endpoint/field contract in §6.
- **Two model layers per entity:** `data/models/*_model.dart` (JSON DTO with
  `fromJson`/`toJson`/`toEntity`) and `domain/entities/*.dart` (pure entity).
  Repository maps DTO → entity; UI/notifiers never see JSON.
- **Fields (real-backend feel):** uuid ids, human `reference` (LOD-xxxx),
  nested shipper/carrier summaries, `cargo {description, category, weight,
  weightUnit}`, `pickupAt` ISO-8601, `expectedFare {amount, currency: NPR}`,
  `status`, `bidCount`, `acceptedBidId`, `assignedCarrier`, `bids[]`,
  `timeline[]`, `createdAt`/`updatedAt`. Response envelope includes
  `data`/`meta{page,pageSize,total,hasMore}`; errors use a typed envelope.
- **Reads and writes are resilient:** remote failures switch to a local
  snapshot (or seed) and surface a visible offline banner. Local writes still
  enforce the 3-request limit; a write is never presented as a remote success.
- Seed data uses **future dates** and exactly 2 active shipments
  (LOD-1001/1002); LOD-1004 is cancelled, so the first mobile create succeeds
  and the next hits the 3-request limit.

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

## 6. Mock API contract (mockapi.io)

Chosen host: **mockapi.io** free tier — **1 project, 2 resources**, which is
exactly what this app needs. The APP talks to it through `IShipmentRepository`,
so the host can be swapped without touching UI or notifiers.

### Project & resources

| Kind | Name | Result |
|------|------|--------|
| Project | `lodbod` | Base URL `https://<TOKEN>.mockapi.io` |
| Resource | `shipments` | `/shipments` |
| Resource | `bids` | `/bids` |
| Relation | `shipments` has many `bids` | `/shipments/{id}/bids` |

Base URL is injected, never hardcoded:
`--dart-define=API_BASE_URL=https://<TOKEN>.mockapi.io`.

### `shipments` fields (all String unless noted)

`reference`, `shipperName`, `pickupCity`, `pickupAddress`, `destinationCity`,
`destinationAddress`, `cargoDescription`, `cargoCategory`, `weight` (Number),
`weightUnit`, `vehicleType`, `pickupAt` (String ISO-8601), `expectedFare`
(Number), `currency`, `status`, `acceptedBidId`, `assignedCarrier`, `notes`,
`createdAt`, `updatedAt`.

### `bids` fields

`shipmentId` (String), `carrierName`, `carrierRating` (Number),
`carrierVerified` (Boolean), `fare` (Number), `currency`, `etaDays` (Number),
`estimatedDeliveryAt` (String ISO-8601), `message`, `status`, `createdAt`.

Rules: `id` is auto-generated by mockapi — do not declare it. `bidCount` is
**computed** by counting bids with matching `shipmentId`, never stored.
`expectedFare = 0` means "no expected fare" (UI shows "—"). Status strings are
lowercase snake_case matching the Dart enum wire names.

### Endpoints used by the repository

| Method | Path | Use |
|--------|------|-----|
| GET | `/shipments` | list (+ optional `search`, `status`, `page`, `limit`) |
| GET | `/shipments/{id}` | single shipment |
| POST | `/shipments` | create (server returns record incl. `id`) |
| PATCH | `/shipments/{id}` | update status/`acceptedBidId`/`assignedCarrier` |
| GET | `/bids?shipmentId={id}` | bids for a shipment (join in repo) |
| GET | `/shipments/{id}/bids` | nested alternative |
| PATCH | `/bids/{bidId}` | accept bid (`{"status":"accepted"}`) |

`acceptBid` = `PATCH /shipments/{id}` + `PATCH /bids/{bidId}`, then re-`GET` the
shipment and return the updated entity. Never optimistic.

### Seed records (deterministic — required for the 3-limit demo)

`shipments` (4): LOD-1001 `in_transit` (Kathmandu→Pokhara), LOD-1002
`awaiting_bids` (Birgunj→Kathmandu), LOD-1003 `delivered`
(Butwal→Narayanghat), LOD-1004 `scheduled` (Kathmandu→Biratnagar).
`bids` (2, both for LOD-1002's `id`): Himalayan Cargo NPR 32,000 / rating 4.6 /
2 days; Swift Transport NPR 29,500 / rating 4.1 / 3 days.

### Fallback & reset

- Reads: remote → on network/timeout/5xx use `MockShipmentRepository` seed +
  "sample data" banner. `200 []` is a valid empty result, not a failure.
- Writes: no silent fallback; surface typed errors, state unchanged.
- mockapi persists writes. Before each demo **reset the rows to the seed**
  (delete created rows, restore accepted bid to `pending`, status back to
  `awaiting_bids`), or the 3-active count and bid demo will be wrong.
- Free tier may throttle/sleep; local fallback covers availability.

---

## 7. Known risks

- Docs claim packages not in `pubspec.yaml` (Freezed, form_builder, fl_chart, lottie).
  Add only if truly needed; prefer hand-written models.
- Seed dates in docs are Oct 2026 (in the past relative to "today"). Use future/
  relative dates so date validation behaves.
- `README.md` currently overstates completion — must be rewritten honestly.
- Keep state out of widgets; reviewers test consistency after create/accept.
