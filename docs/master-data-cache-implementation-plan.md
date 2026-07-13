# Master Data Cache and API Call Reduction Plan

Last updated: 2026-07-13
Status: `In Progress`
Owner: `Codex + team`

## Why this exists

Many pages currently make 10 to 15 API calls during `loadPage()` even when most of the data is stable master data that was already fetched on previous pages.

This file is the living specification for fixing that problem across the Flutter app.

It also serves as long-term project memory so we do not create cognitive debt while using AI to accelerate implementation.

## AI-Driven Development Rules for This Work

### 1. Writing Specifications

Before changing code, every cache-related change must be described here:

- What problem is being solved
- Which files are affected
- What behavior changes
- What tests or validation prove the change is safe

No cache optimization should be merged as an undocumented "smart shortcut."

### 2. Agentic Architecture

We will treat this as a pipeline of responsibilities instead of scattered controller edits:

1. Bootstrap agent responsibility: load session and trigger master cache warmup
2. Cache agent responsibility: fetch, store, deduplicate, refresh, and invalidate master data
3. Context agent responsibility: resolve company, branch, location, and financial year from cached data
4. Page agent responsibility: fetch only page-specific transactional data and read master data from cache
5. Validation agent responsibility: analyze API-count reduction, run static checks, and verify flows

Human checkpoints:

- Approve cache scope before adding new datasets
- Review fallback behavior before broad rollout
- Verify high-traffic flows after each migration wave

### 3. Managing Cognitive Debt

Every time this system changes, update this file with:

- New datasets added to cache
- New controllers migrated
- Any fallback or invalidation rule added
- Any bug discovered and its root cause
- Any design tradeoff that future maintainers need to understand

If a future engineer cannot answer "why is this cached, when is it refreshed, and when is it invalidated?" by reading this file, then the documentation is incomplete.

## Problem Summary

Current pattern:

- Each page controller or view model fetches transaction data
- The same page also refetches master data like companies, branches, items, UOMs, accounts, parties, warehouses, and tax codes
- `WorkingContextService.loadSnapshot()` separately refetches companies, branches, locations, and financial years
- Navigation between pages repeats the same calls again and again

Observed hotspot areas in the current repo:

- `lib/controller/sales/*`
- `lib/controller/purchase/*`
- `lib/controller/settings/accounting/*`
- `lib/controller/project/*`
- `lib/view_model/inventory/*`
- `lib/view_model/service/*`
- `lib/view_model/manufacturing/*`
- `lib/view_model/maintenance/*`

Concrete examples already confirmed:

- `lib/service/app/working_context_service.dart`
- `lib/controller/sales/sales_quotation_management_controller.dart`
- `lib/controller/sales/sales_order_management_controller.dart`
- `lib/controller/purchase/purchase_order_management_controller.dart`
- `lib/controller/purchase/purchase_invoice_management_controller.dart`

## Target Outcome

Target per page load:

- 1 to 3 calls for transaction-specific data
- 0 repeated calls for already-loaded master data

Target app behavior:

- Master data loads once after session bootstrap
- Working context reads from cache
- Page controllers read from cache
- Settings pages refresh only the dataset they changed
- Logout or access-context changes invalidate cache safely

## Design Principles

### Principle A: Cache only stable shared master data

Good cache candidates:

- Companies
- Branches
- Business locations
- Financial years
- Document series
- Warehouses
- Parties
- Party types
- Items
- UOMs
- UOM conversions
- Tax codes
- Accounts
- GST registrations

Do not put transaction lists into this cache:

- Invoices
- Orders
- Quotations
- Receipts
- Payments
- Returns
- Requisitions
- Reports with filters

### Principle B: One shared in-flight load

The cache must deduplicate concurrent loads.

Bad pattern:

- `if (isLoading) return;`

Why it is risky:

- callers may continue before data is actually ready
- first page can still trigger fallback API calls
- startup behavior becomes timing-dependent

Required pattern:

- maintain a shared `_loadFuture`
- all callers await the same future
- only clear `_loadFuture` when work completes

### Principle C: Preserve current behavior first, optimize second

The cache must not silently change:

- active-item filtering rules
- sorting expectations
- current financial year selection
- warehouse access filtering
- page editor dropdown contents

### Principle D: No silent truncation

Several current fetches use different `per_page` values depending on page.

The cache must not assume fixed limits like `500` if actual data may exceed that.

Before rollout, each cached dataset must have a pagination strategy:

- use a server endpoint that returns all records if available
- or fetch all pages until complete
- or document a validated upper bound and monitor it

## Proposed Architecture

## 1. New service: `lib/helper/master_data_cache.dart`

Responsibilities:

- hold cached master datasets
- deduplicate loads
- expose readiness state
- refresh individual datasets
- invalidate all data
- optionally expose lightweight diagnostics like `lastLoadedAt`

Suggested shape:

```dart
class MasterDataCache extends GetxController {
  MasterDataCache._();

  static MasterDataCache get to => Get.find<MasterDataCache>();

  Future<void>? _loadFuture;
  bool isLoaded = false;
  Object? lastError;
  DateTime? lastLoadedAt;

  List<CompanyModel> companies = const [];
  List<BranchModel> branches = const [];
  List<BusinessLocationModel> locations = const [];
  List<FinancialYearModel> financialYears = const [];
  List<DocumentSeriesModel> documentSeries = const [];
  List<WarehouseModel> warehouses = const [];
  List<PartyModel> parties = const [];
  List<PartyTypeModel> partyTypes = const [];
  List<ItemModel> items = const [];
  List<UomModel> uoms = const [];
  List<UomConversionModel> uomConversions = const [];
  List<TaxCodeModel> taxCodes = const [];
  List<AccountModel> accounts = const [];
  List<GstRegistrationModel> gstRegistrations = const [];

  Future<void> ensureLoaded() => _loadFuture ??= _loadImpl();
}
```

Implementation rules:

- load in parallel
- normalize responses into typed lists
- keep existing sort behavior where important
- set `isLoaded` only after all required datasets are populated
- record failure in `lastError`
- allow explicit retry after failure

## 2. Bootstrap integration

Files:

- `lib/main.dart`
- `lib/controller/core/app_shell_controller.dart`

Changes:

- register `MasterDataCache` during app startup
- after successful session bootstrap, trigger `MasterDataCache.to.ensureLoaded()`
- decide whether first screen should await cache or render while cache warms in background

Recommended rule:

- `WorkingContextService` should await the shared cache future
- page controllers should prefer awaiting cache in critical flows instead of falling back immediately

This gives better API reduction than fire-and-forget warmup.

## 3. Working context integration

File:

- `lib/service/app/working_context_service.dart`

Changes:

- stop refetching companies, branches, locations, and financial years when cache is available
- preserve current active-only filtering behavior
- keep `resolveSelection()` logic unchanged unless a bug is intentionally fixed

Required behavior:

- await cache shared future
- read cached data
- filter active records exactly as current implementation does
- only use direct API fallback if cache initialization fails

## 4. Page loader contract

All page loaders should follow this contract:

1. Await cache readiness if the page depends on cached master data
2. Fetch only page-specific transaction data
3. Read shared master data from cache
4. Apply page-specific filtering locally
5. Keep editor save, delete, and reload behavior intact

Standard pattern:

```dart
Future<void> loadPage({int? selectId}) async {
  await MasterDataCache.to.ensureLoaded();

  final transactionResponse = await _service.fetchPageData(...);
  final cache = MasterDataCache.to;

  companies = cache.companies.where((e) => e.isActive).toList(growable: false);
  branches = cache.branches.where((e) => e.isActive).toList(growable: false);
  locations = cache.locations.where((e) => e.isActive).toList(growable: false);
  financialYears = cache.financialYears
      .where((e) => e.isActive)
      .toList(growable: false);
}
```

## 5. Refresh and invalidation model

Refresh one dataset after save:

- company create or update -> refresh companies
- branch create or update -> refresh branches
- location create or update -> refresh locations
- financial year create or update -> refresh financial years
- document series create or update -> refresh document series
- warehouse create or update -> refresh warehouses
- item create or update -> refresh items
- UOM create or update -> refresh UOMs
- UOM conversion create or update -> refresh UOM conversions
- tax code create or update -> refresh tax codes
- account create or update -> refresh accounts
- party create or update -> refresh parties
- party type create or update -> refresh party types
- GST registration create or update -> refresh GST registrations

Invalidate entire cache on:

- logout
- login as different user
- company access scope change
- permission refresh that changes accessible master data
- explicit "hard refresh" action if added later

## 6. Pagination strategy

This is mandatory before broad rollout.

For each cached dataset, decide one of these:

- `All endpoint exists`: use it
- `Paginated only`: fetch all pages until `next` is empty or all rows collected
- `Safe upper bound confirmed`: use documented bound and revisit when data grows

Datasets most likely to outgrow current limits:

- parties
- items
- accounts
- document series
- UOM conversions

## Implementation Plan

## Phase 0: Specification and baseline

Deliverables:

- this document created
- cache scope approved
- hotspot inventory recorded

Tasks:

- [ ] Confirm exact master datasets to cache
- [ ] Confirm pagination strategy per dataset
- [ ] Confirm fallback policy on startup failure
- [ ] Record baseline API count for 5 high-traffic pages

Suggested baseline pages:

- sales quotation
- sales order
- purchase order
- purchase invoice
- voucher management

## Phase 1: Core cache service

Files:

- [ ] `lib/helper/master_data_cache.dart` create
- [x] `lib/helper/master_data_cache.dart` create
- [x] `lib/main.dart` register service

Tasks:

- [x] Add typed fields for all approved datasets
- [x] Implement shared in-flight load future
- [x] Implement `ensureLoaded()`
- [x] Implement dataset-specific refresh methods
- [x] Implement `invalidate()`
- [x] Add basic diagnostics: `lastLoadedAt`, `lastError`

## Phase 2: Session and context wiring

Files:

- [ ] `lib/controller/core/app_shell_controller.dart`
- [ ] `lib/service/app/working_context_service.dart`

Tasks:

- [x] Trigger cache warmup after successful session bootstrap
- [x] Update working context to read from cache
- [ ] Preserve active-only filters and current selection behavior
- [ ] Add direct fallback only when cache load truly fails

## Phase 3: High-impact controller migration

Migrate first because they currently load the most shared data and are used often:

- [x] `lib/controller/sales/sales_quotation_management_controller.dart`
- [x] `lib/controller/sales/sales_order_management_controller.dart`
- [x] `lib/controller/sales/sales_invoice_management_controller.dart`
- [x] `lib/controller/sales/sales_delivery_management_controller.dart`
- [x] `lib/controller/sales/sales_return_management_controller.dart`
- [x] `lib/controller/purchase/purchase_order_management_controller.dart`
- [x] `lib/controller/purchase/purchase_invoice_management_controller.dart`
- [x] `lib/controller/purchase/purchase_payment_management_controller.dart`
- [x] `lib/controller/purchase/purchase_receipt_management_controller.dart`
- [x] `lib/controller/purchase/purchase_return_management_controller.dart`
- [ ] `lib/controller/purchase/purchase_requisition_management_controller.dart`

Migration rule for each file:

- remove repeated master-data fetches from `Future.wait`
- keep transaction fetches only
- load master data from cache
- preserve page behavior and editor interactions
- verify post-save reload still works

## Phase 4: Settings and refresh hooks

Files likely involved:

- [ ] `lib/controller/settings/master/company_management_controller.dart`
- [ ] `lib/controller/settings/master/branch_management_controller.dart`
- [ ] `lib/controller/settings/master/business_location_management_controller.dart`
- [ ] `lib/controller/settings/master/financial_year_management_controller.dart`
- [ ] `lib/controller/settings/master/document_series_management_controller.dart`
- [ ] `lib/controller/settings/master/warehouse_management_controller.dart`
- [ ] `lib/controller/settings/master/item_management_controller.dart`
- [ ] `lib/controller/settings/accounting/account_management_controller.dart`
- [ ] party management flows
- [ ] GST registration management flows

Tasks:

- [ ] read from cache where appropriate
- [ ] refresh only changed dataset after successful save
- [ ] avoid full-page re-fetch when a small refresh is enough

## Phase 5: Secondary migration wave

These still duplicate master data and should move onto the shared contract:

- [ ] inventory view models
- [ ] manufacturing view models
- [ ] service view models
- [ ] maintenance view models
- [ ] project controllers
- [ ] CRM controllers
- [ ] dashboard support helpers where shared master data is involved

## Phase 6: Validation and rollout hardening

Tasks:

- [x] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Measure API count before and after on target pages
- [ ] Smoke test create, edit, delete, and reload flows
- [ ] Smoke test logout/login and user-context change
- [ ] Smoke test first-load behavior on slow network

## Validation Matrix

For each migrated page, verify:

- [ ] page opens successfully
- [ ] API count reduced
- [ ] dropdowns still show correct values
- [ ] active/inactive filtering still correct
- [ ] current financial year still resolves correctly
- [ ] save flow still refreshes visible data
- [ ] no stale data after master-record update

## Risks and Mitigations

### Risk 1: Truncated datasets

Cause:

- fixed `per_page` limits smaller than real data volume

Mitigation:

- define pagination strategy before rollout
- add temporary logging for returned item counts if needed

### Risk 2: Stale cache after settings changes

Cause:

- create or update flows not refreshing affected datasets

Mitigation:

- dataset-level refresh methods
- mandatory refresh hook checklist in settings controllers

### Risk 3: Duplicate calls still happen during startup

Cause:

- background warmup not awaited by dependent pages

Mitigation:

- shared `ensureLoaded()` future
- only fallback on real failure, not on timing

### Risk 4: Behavior regressions from changed filtering

Cause:

- cache returns raw lists while old pages used active-only lists

Mitigation:

- preserve existing filtering rules during migration
- verify dropdown behavior page by page

### Risk 5: Access-scope leakage

Cause:

- cache survives user or permission changes

Mitigation:

- invalidate on logout and access refresh events
- scope cached data to current session identity

## Definition of Done

This initiative is done when all of the following are true:

- high-traffic pages no longer refetch common master data on navigation
- `WorkingContextService` no longer duplicates those calls
- startup uses one shared master-data load path
- settings flows refresh only affected cache entries
- API count drops from roughly 10 to 15 per page to roughly 1 to 3 per page on migrated pages
- this document reflects the actual implemented design

## Maintenance Protocol

Update this file every time we do any of the following:

- add a new dataset to cache
- migrate a new controller or view model
- change invalidation rules
- change fallback behavior
- discover a bug related to stale or missing cache data
- finish a validation step

Update format:

1. Change the relevant checklist item from `[ ]` to `[x]`
2. Update `Last updated`
3. Add a short note under `Implementation Notes`

## Implementation Notes

- 2026-07-13: Initial specification created. Current repo scan confirms duplicate master-data fetching across controllers, view models, and working-context loading. No runtime code changed yet.
- 2026-07-13: Implemented `MasterDataCache` with shared in-flight loading, dataset refresh methods, full invalidation, and basic diagnostics. Wired it into app startup, session invalidation, shell warmup, and `WorkingContextService`.
- 2026-07-13: Migrated `sales_quotation_management_controller.dart`, `sales_order_management_controller.dart`, `purchase_order_management_controller.dart`, and `purchase_invoice_management_controller.dart` to fetch only transaction-specific data plus page-only dependencies while reading shared master data from cache.
- 2026-07-13: Migrated `sales_invoice_management_controller.dart`, `sales_return_management_controller.dart`, `purchase_payment_management_controller.dart`, `purchase_receipt_management_controller.dart`, and `purchase_return_management_controller.dart` to the shared master-data cache. `sales_invoice_management_controller.dart` also stopped refetching accounts/items/UOMs/warehouses/tax codes inside its background reference-data loader.
- 2026-07-13: Migrated `sales_delivery_management_controller.dart` and `sales_receipt_management_controller.dart` to the shared master-data cache. With this pass, the main sales document controllers no longer refetch common master datasets on each page load.
- 2026-07-13: Started the secondary wave by migrating `stock_issue_view_model.dart`, `stock_transfer_view_model.dart`, and `inventory_adjustment_view_model.dart` to read companies, branches, locations, financial years, document series, items, warehouses, UOMs, and UOM conversions from `MasterDataCache` while keeping stock batches, serials, balances, and departments page-specific.
- 2026-07-13: Continued the inventory wave by migrating `opening_stock_view_model.dart`, `internal_stock_receipt_view_model.dart`, `stock_damage_view_model.dart`, and `produce_tracking_view_model.dart` to the shared cache for common masters. These still fetch page-specific data such as batches, serials, employees, transporters, and transactional source documents directly.
- 2026-07-13: Migrated `service_contract_view_model.dart`, `service_ticket_view_model.dart`, `service_work_order_view_model.dart`, and `warranty_claim_view_model.dart` to the shared cache for companies, branches, locations, financial years, document series, parties, and items. These screens still fetch service transactions, users, service contracts, work orders, contract assets, and stock serials directly because those remain page-specific or detail-specific.
- 2026-07-13: Migrated `bom_view_model.dart`, `production_order_view_model.dart`, `production_material_issue_view_model.dart`, and `production_receipt_view_model.dart` to the shared cache for manufacturing master dependencies. These screens now read common companies, branches, locations, financial years, document series, items, UOMs, UOM conversions, and warehouses from `MasterDataCache`, while continuing to fetch manufacturing transactions, BOMs, production orders, stock batches, stock serials, and stock balances directly.
- 2026-07-13: Migrated `jobwork_order_view_model.dart`, `jobwork_charge_view_model.dart`, `jobwork_dispatch_view_model.dart`, and `jobwork_receipt_view_model.dart` to the shared cache for companies, branches, locations, financial years, document series, parties, party types, items, UOMs, UOM conversions, warehouses, and tax codes. These still fetch jobwork transactions, jobwork orders, stock batches, and stock serials directly because those are page-specific or transaction-specific.
- 2026-07-13: Migrated `stock_reservation_view_model.dart`, `item_planning_policy_view_model.dart`, `planning_calendar_view_model.dart`, `mrp_run_view_model.dart`, `qc_plan_view_model.dart`, `qc_inspection_view_model.dart`, and `qc_result_action_view_model.dart` to the shared cache for their common companies, branches, locations, financial years, items, UOMs, warehouses, document series, parties, and tax-code dependencies where applicable. These screens still fetch planning calendars, BOMs, QC plans, item categories, stock batches, stock serials, inspections, and result-action transaction lists directly because those remain page-specific.
- 2026-07-13: Added admin controls on the module-preferences settings page for super admins to enable or disable the shared master-data cache and clear all master/API cache entries on demand. The cache-enabled flag now persists in `SessionStorage`, and `MasterDataCache.ensureLoaded()` now short-circuits correctly after a successful load when caching is enabled.
- 2026-07-13: `flutter analyze` passes for this work with only pre-existing warnings outside the cache implementation.
