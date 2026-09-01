# Changelog

## 2026-08-31 — Default sales lists to newest first

- Standardized sales quotation, proforma, order, delivery, invoice, receipt,
  return, and ledger source requests to send descending date/ID sorting.
- Changed the shared register controller default from oldest-first to
  `date_desc`, so the UI ordering matches the API ordering on first load.
- Clear Filters now restores the same newest-first default instead of resetting
  the list to oldest-first.
- Existing register sort controls and user-selected filters remain unchanged.

## 2026-08-31 — Carry CRM customer into new quotations

- Fixed the CRM enquiry/opportunity to quotation bootstrap so it reads the
  typed opportunity fields returned by the API.
- New quotations now retain the CRM opportunity link and preselect the linked
  customer and company; the customer remains editable.
- A linked customer missing from the initial Sales lookup is fetched and added
  to the quotation customer options before the editor refreshes.
- No database or API contract change.
- Focused formatting and analysis are pending verification.

## 2026-08-29 — Require warehouses on stock-tracked sales invoice lines

- Added a reusable warehouse validator to the line-item table and enabled it
  for Sales Invoice and Sales Delivery stock-tracked rows.
- Preserved warehouses inherited from delivery lines when refreshing current
  stock availability after delivery consumption.
- Service and non-stock rows remain exempt, and existing source-line
  prefill/warehouse selection behavior is unchanged.
- Focused Flutter analysis and all tests passed; backend enforcement is recorded
  in the sibling API changelog.

## 2026-08-29 — Fix Flutter hot-restart compilation

- Restored the deterministic local API host fallback in `AppConfig.baseHost`,
  while retaining `API_BASE_URL` dart-define overrides.
- Updated the shared register filter animation to the current Flutter
  `SizeTransition` API and preserved top-aligned expansion.
- Added a regression test covering the non-null `AppConfig.baseHost` contract.
- No database, API contract, security, or business-rule changes.
- `dart format`, focused/full Flutter analysis, all Flutter tests, and
  the web release build completed successfully; full analysis retains one
  unrelated unused-element warning in the CRM follow-ups page.

## 2026-08-27 — Fix salary-component reorder callback

- Replaced the unsupported `onReorderItem` argument with Flutter's
  `ReorderableListView.builder` `onReorder` callback.
- Preserved the existing reorder-index conversion, drag disabling while saving,
  and salary-order persistence behavior.
- No database, API, security, or payroll-calculation impact.
- Focused formatting and analysis passed.

## 2026-08-26 — Consistent payslip PDF salary-table borders

- Payslip PDF salary-table row, column, and outer borders now use one stroked
  vector grid, preventing uneven rasterized borders when the template stroke
  width is 1 or 0.80.
- The designer preview, configured table styling, payroll data, API, and
  persistence remain unchanged.
- Focused formatting and Flutter analysis passed; a fresh browser download
  remains the final manual visual check.

## 2026-08-26 — Refresh HR dashboard after payroll deletion

- Payroll-run deletion now emits the existing HR module refresh event, so the
  HR dashboard updates immediately without a browser refresh.

## 2026-08-26 — Pending LOP in draft payroll preview

- Draft payroll rows now show pending values instead of displaying false LOP
  days when attendance has not been submitted.
- The employee row explains that submitted attendance is required.

## 2026-08-26 — Full-width CRM filter bars

- CRM Enquiries, Leads, and Opportunities now expand their inline filter bars
  across the available page width while preserving responsive wrapping.
- Wide CRM filter bars now fit up to six controls per row.
- Moved CRM list search into the application bar and removed duplicate search
  controls from filter and list/table content.
- Added the same application-bar search to CRM Follow-ups, filtering follow-up
  cards and pending enquiry gaps by their visible identifying details.
- Widened the application-bar search to 360 px and centered it in the main
  header area; the title remains left-aligned and Filter/New stay on the right.
- Reused `SettingsFormWrap` with a CRM-specific width configuration; no shared
  component behavior changes for existing callers and no backend/API behavior
  changed.

## 2026-08-26 — Sales and Purchase app-bar search

- Sales and Purchase register/document pages now place their list search in the
  application bar, matching the CRM layout.
- Inline filter controls use the shared `SettingsFormWrap` with a maximum of
  six controls per row and remain responsive on smaller screens.
- Search behavior, filtering, APIs, and document data remain unchanged.

## 2026-08-26 — Print summary rupee typography

- The downloaded invoice summary now embeds a high-resolution Flutter-rendered
  currency-text image, so its rupee glyph exactly matches the UI preview.
- Increased the embedded render resolution to retain the preview glyph's
  visible stroke weight in downloaded PDFs.
- Applied the Flutter-rendered rupee rule to every print text field containing
  `₹`, rather than only the sales-invoice summary shape.

## 2026-08-26 — Toast overlay frame safety

- Deferred toast overlay mutations until after the active widget frame to
  prevent inherited-widget descendant assertions during rebuilds.
- Replaced the unsupported `ScaffoldMessenger` subclass with Flutter's standard
  root messenger so hot restart cannot retain invalid inherited dependents.

## 2026-08-25 — Global status toast

- Request: Replace snackbar feedback with a centered, color-coded global toast.
- Implementation: Added one overlay-based toast with green, amber, red, and
  blue states plus a compatibility host for controller notifications.
- Database/API impact: None.
- Security impact: None.
- Tests executed and results: Focused Flutter analysis passed with no issues.
- Known limitations: Context-owned snackbar calls must be migrated separately.

## 2026-08-25 — CRM Enquiries expected-value presentation

- Request: Separate Expected Value from Lead By and replace zero values with a
  clear placeholder.
- Specification: Added display rules and acceptance criteria for blank and
  zero Expected Value fields.
- Implementation: Reused one CRM Expected Value formatter in the register and
  read-only table view; zero/blank values show `-`, while editor input remains
  blank for a zero value. Expanded the register column from its default width
  to flex 2 and configured both views to center the Expected Value text and
  placeholder.
- Files changed: CRM opportunity controller/register page, focused formatter
  test, and durable frontend documentation.
- Database/API impact: None; the existing `expected_value` field is displayed
  without changing its payload or persistence.
- Security impact: None.
- Tests added or updated: Added focused zero, blank, non-zero, legacy-text,
  and editable-placeholder coverage.
- Tests executed and results: Focused analysis passed with no issues; focused
  Flutter test passed 3/3.
- Documentation updated: Specifications, architecture, testing, and changelog.
- Known limitations: Authenticated visual QA is still needed for production
  desktop and narrow-width register layouts.
- Follow-up work: None.

## 2026-09-01 — CRM Dashboard all-employees filter selection

- Fixed the searchable CRM Dashboard Employee filter so selecting All employees
  checks the All employees checkbox and every employee-name checkbox.
- Selecting a named employee clears the all-employees selection; selecting All
  employees again checks every employee and preserves the existing unfiltered
  API value.
- Unchecking All employees now clears every employee checkbox while retaining
  the unfiltered dashboard data view.
- Extended the shared ERP link field with an optional select-all multi-select
  value; no backend or database changes are required.
- Verification: `dart format`, focused `flutter analyze`, and `git diff
  --check` completed successfully.

## 2026-08-25 — CRM inline filter bars

- Reused the Sales register filter-bar interaction for CRM Enquiries, Leads,
  and Opportunities.
- Filter buttons now toggle inline controls with live search/date/status
  updates and a shared Clear action; existing CRM defaults and filter fields
  are preserved.
- Added a Sales-style Sort filter to CRM lists, defaulting to Newest first.
- Added a Super Admin-only Employee filter to CRM Leads, Enquiries, and
  Opportunities using each row's existing assigned employee.
- Added the same Employee filter to CRM Follow-ups with consistent top spacing
  and Clear behavior.
- Changed the CRM Dashboard Employee filter to a searchable ERP link field.
- CRM Follow-ups now uses the same toggleable inline From Date / To Date filter
  and no longer shows its previous always-visible date card.
- No backend or database changes are required.

## 2026-08-24 — CRM lead probability status

- Added a StaffU-inspired circular Probability column to the CRM Leads
  register, with semantic high/medium/low colors and accessible percentage text.
- Added model support for `probability_percent` and a status-based fallback for
  legacy lead responses; no backend or database changes are required.
- Added per-column register text styling so lead-name emphasis does not make all
  CRM fields bold.
- Enabled the same controlled row emphasis for Sales and Purchase registers and
  ledgers on desktop and mobile layouts.

## 2026-08-24 — Sales outstanding balance drill-down parity

- Request: Include overdue invoices in the Outstanding Balance pre-filter and
  make its drill-down amount match the dashboard, like Monthly Sales.
- Specification: Added the outstanding-invoice definition, route behavior, and
  parity acceptance criteria to `docs/SPECIFICATIONS.md`.
- Implementation: Added one reusable sales-invoice outstanding predicate,
  balance aggregator, status preset, and route builder. Both the Sales
  Dashboard and invoice register now use the same positive `balance_amount`
  rule; the Open preset includes posted, overdue, and partially paid invoices
  and sorts by descending balance.
- Files changed: Shared sales dashboard support, Sales Dashboard loader,
  invoice register, screen export, focused tests, and durable documentation.
- Database/API impact: None; existing invoice list/all endpoints and persisted
  balances are reused.
- Security impact: None.
- Tests added or updated: Added four focused parity and boundary tests.
- Tests executed and results: Focused analysis passed with no issues; focused
  Flutter tests passed 4/4.
- Documentation updated: Specifications, architecture, testing, and changelog.
- Known limitations: The reported production-shaped dataset was not available
  to the isolated unit test, so authenticated manual value comparison remains.
- Follow-up work: None required after dataset verification.

## 2026-08-24 — CRM follow-up timeline presentation

- Request: Reproduce the StaffU Activity Log design on the CRM follow-ups page.
- Specification: Added the CRM follow-up timeline requirements and acceptance
  criteria to `docs/SPECIFICATIONS.md`.
- Implementation: Reworked the existing Today, Overdue, Upcoming, and
  dashboard-filtered lists into semantic StaffU-style timelines; added an
  optional shared-calendar date filter; retained refresh, loading, error,
  empty, route-filter, visibility, and Open-record behavior. Added optional
  service injection solely for deterministic widget tests.
- Files changed: `lib/view/crm/crm_followups_page.dart`, focused widget tests,
  and durable frontend documentation.
- Database/API impact: None; the existing follow-up board and create/detail
  contracts are unchanged, and date filtering is local.
- Security impact: None; no new data is collected, stored, or transmitted.
- Tests added or updated: Added desktop, date-filter, and 420px responsive
  widget coverage.
- Tests executed and results: Focused widget tests passed 3/3; focused analysis
  has only the pre-existing unused `_buildGapList` warning.
- Documentation updated: Specifications, architecture, testing, and changelog.
- Known limitations: Authenticated visual QA with production-shaped CRM data is
  not available in the local widget-test environment.
- Follow-up work: None required for the presentation change.

## 2026-08-22 — Make Bulk Attendance submit-only

- Removed the Bulk Attendance **Save draft** action. The remaining **Submit
  attendance** action always creates payroll-ready submitted records after
  confirmation.
- API/database impact: none; the existing submit endpoint and payload are
  reused.

## 2026-08-21 — Prevent monthly attendance from crossing its month boundary

- The monthly attendance model now derives the number of calendar days from
  the selected year and month instead of accepting a stale or missing response
  count. June submissions therefore stop at June 30.
- API/database impact: none on the Flutter client.
- Tests: focused analysis and attendance model tests passed.

## 2026-08-21 — Correct Bulk Attendance employee selection

- Bulk Attendance no longer preselects every employee when a month loads.
  Selecting one employee now submits only that employee's attendance cells.
- The shared monthly calendar grid now wires its existing header checkbox to
  select or clear all employees in the loaded bulk sheet.
- The select-all `Set<int>` operation lives in the shared HR helper layer for
  reuse by other HR bulk workflows.
- API/database impact: none.
- Tests: focused analysis and the monthly attendance selection/model tests
  passed.

## 2026-08-21 — Add Leave Request approval controls

- Pending Leave Requests now show Approve and Reject actions to Super Admins
  and users with `hr.approve`.
- The controls reuse the existing secured HR endpoints, which calculate the
  paid-leave/LOP split when approval succeeds.

## 2026-08-21 — Calculate leave balance at approval

- Pending leave requests now display a read-only Pending status and do not
  create paid-leave or LOP values.
- The server calculates the company-policy paid-leave/LOP split when HR
  approves the request, using only already-approved leave.

## 2026-08-21 — Use the logged-in employee for Leave Requests

- Removed the all-employee chooser from the Leave Request form.
- New requests use the active user's linked employee; existing requests retain
  their recorded employee when opened.
- HR list filtering and server-side access rules are unchanged.

## 2026-08-21 — Stabilize Company Settings tab rendering

- Removed form-key reuse between Company Settings and its embedded Financial
  Years editors.
- Company Settings now initializes its tab controller before layout, keeps each
  tab body keyed, and mounts only the selected tab; persistent controllers are
  reused rather than registered again when returning to the page.
- This prevents Flutter from reparenting focused form elements while layout is
  in progress.
- Clearing the embedded Financial Years action during disposal no longer
  notifies the Company GetBuilder while Flutter's widget tree is locked.

## 2026-08-21 — Clarify leave availability and centralize leave-type creation

- Renamed the Company Settings field from “Accrual method” to “Leave
  availability schedule” with compact **Yearly** and **Monthly** choices.
- Removed the inline Leave Type creation dialog from Leave Requests. The
  existing Leave Types master is now the only catalog create/update/delete
  workflow; Company Settings continues to configure company-specific policy.
- API/database impact: none.

## 2026-08-21 — Company-configurable leave entitlement and LOP

- Added a Leave Policy tab to Company Settings with a configurable annual
  entitlement, annual/monthly accrual, excess handling, and active state for
  every leave type. Casual Leave is no longer fixed at 12 days.
- Added a company LOP multiplier restricted to 1, 1.5, or 2 days.
- Leave requests now display the generic paid-leave/LOP split returned by the
  server. Excess entitlement can convert to LOP or reject the request according
  to company policy.
- Payroll applies the configured multiplier to leave-request LOP, caps total
  LOP at working days, and stores the multiplier in its calculation snapshot.
- Database deployment requires the accompanying API migration or SQL patch.

## 2026-08-21 — Show all active employees in Monthly Attendance

- Request: include all active employees in the Monthly Attendance sheet,
  matching the Employees screen.
- Implementation: kept the bulk-attendance UI but enabled the existing backend
  system-employee path for the Monthly Attendance route and save request.
- API/database impact: the monthly sheet endpoints now accept the optional
  `active_employees_only` flag; no database change.
- Verification: focused Flutter analysis and existing HR attendance tests.

## 2026-08-21 — Simplify Activity Watch connection status

- Request: remove revoke wording, hide disconnected devices, and make pending
  pairing status clear for the full 30-minute download window.
- Implementation: filtered revoked devices from the setup list, renamed the
  visible action to Disconnect, changed pending status to Waiting for
  connection, and reduced the connection card to its title, device label, and
  connect button. The existing consent payload and 30-minute backend expiry
  remain unchanged.
- API/database impact: none.
- Tests: focused model and widget analysis/tests are recorded in `TESTING.md`.

## 2026-08-20 — Group Activity Watch cards by owner and day

- Request: Show one Activity Watch card per user/date when the user logs out
  several times in the same day.
- Specification: Retain the newest cumulative snapshot per device/date, then
  combine distinct devices under the linked employee/user and local work date.
- Implementation: Reused the typed Activity Watch summary model and dashboard;
  added a map-based daily aggregator and changed expansion/trend keys from
  device/date to owner/date.
- Files changed: Activity Watch model, setup/report page, focused model tests,
  feature specification, architecture, testing notes, and changelog.
- API/database/security impact: None. Existing viewer scope and privacy-safe
  response fields are unchanged.
- Tests: Focused grouping/parsing tests passed (4 tests), the complete Flutter
  suite passed (15 tests), and focused Flutter analysis passed with no issues.
  Full-project analysis retains two unrelated existing warnings.
- Complexity: Expected `O(n + d)` time and `O(n + d)` space for loaded
  summaries and bounded detail items.
- Remaining verification: Confirm the grouped card visually in an
  authenticated production UI after multiple same-day logout uploads.

## 2026-08-20 — Make web-logout uploads fail closed

- Request: Verify and correct Activity Watch data not reaching the server after
  ERP web logout.
- Specification: A batch requires a valid JSON accepted-count acknowledgement;
  logout completion uses a separate device-authenticated control acknowledgement.
- Implementation: Added bounded batch-response validation, retry handling for
  invalid HTTP 2xx responses, explicit post-drain acknowledgement, backend
  route/controller support, and preserved the legacy header for older agents.
- Files changed: Agent syncer/control/runner and tests, backend Activity Watch
  controller/routes, macOS package/public artifact, specifications,
  architecture, ADR, operations, testing, and changelogs.
- Database/API impact: Adds authenticated
  `POST /activity-watch/control/acknowledge`; no new table or column. The
  existing `flush_requested` patch is still required.
- Security impact: Reuses device authentication and prevents misrouted HTML
  responses from falsely acknowledging encrypted activity data.
- Tests added or updated: HTML 200, accepted-count mismatch, empty/full queue
  acknowledgement, combined-control delegation, and server acknowledgement.
- Tests executed and results: Full Go tests and vet passed; changed PHP files
  passed syntax checks; rebuilt macOS package passed payload, mode, hash, and
  Installer parse validation.
- Documentation updated: Specification, architecture, replacement ADR,
  release/deployment operations, testing, frontend/backend/root changelogs.
- Known limitations: Rebuild Windows on its approved toolchain. Deploy backend
  before updated agents and complete one live logout test after deployment.

## 2026-08-20 — Repair invalid macOS Activity Watch package

- Request: Fix the macOS Installer page-controller error shown when opening the
  downloaded Activity Watch package.
- Specification: The stable `.pkg` must contain a parseable XAR installer with
  the app launcher, agent, and `Info.plist`, and the published hash must match
  the validated build.
- Implementation: Rebuilt the current ARM64 agent and AppKit launcher into a
  valid component package, replaced the mislabeled raw executable in the API
  download folder, and added pre-publication package validation steps.
- Files changed: macOS packaging artifact, API-public macOS artifact, release
  specification, operations guide, testing record, and changelogs.
- Database/API impact: No database, endpoint, or payload-shape change; the
  stable installer filename is retained.
- Security impact: The internal development package is still unsigned and must
  be signed and notarized before general distribution.
- Tests executed and results: Agent tests and vet passed; `pkgutil` payload
  validation, executable-mode checks, hash comparison, and macOS Installer's
  read-only choices parse passed.
- Known limitations: The corrected API-public file must be deployed to the live
  server, then manually installed and paired on a test Mac.

## 2026-08-20 — Fix Activity Watch agent download path

- Request: Fix the Activity Watch agent download.
- Specification: The installer URL must include the deployment's API public-path
  prefix and return an installer-sized payload rather than HTML.
- Implementation: Pointed the production installer base URL at the API's
  deployed public directory; no Flutter widget or API contract changed.
- Database/API impact: No database or response-shape change.
- Security impact: None; installer and pairing security behavior is unchanged.
- Tests executed and results: Production `curl -I` checks returned the Windows
  executable (10,769,920 bytes) and macOS package (13,105,986 bytes).
- Documentation updated: Specification, release operations, testing, frontend
  changelog, and backend changelog.
- Known limitations: The corrected environment value must be present on the
  deployed backend if this workspace is not the live server filesystem.

## 2026-08-20 — Repair Windows Activity Watch installer updates

- Request: Fix the installer failure when `activity-watch-agent.exe` is in use.
- Implementation: Windows updates now request elevation, stop and wait for the
  existing service/process, replace the executable, and restart the existing
  service without launching a duplicate foreground process.
- Database/API impact: None.
- Security impact: The original user's local install root is passed explicitly
  through elevation; credentials and pairing data remain unread and unlogged.

## 2026-08-19 — Build and publish the Windows Activity Watch installer

- Request: Build the Windows Activity Watch agent and move it to the API
  download path.
- Implementation: Restored the missing Windows-only collector API adapter,
  rebuilt the SQLCipher-enabled installer, and replaced the public API download
  artifact.
- Database/API impact: The existing public installer filename is updated; no
  endpoint or payload contract changed.
- Security impact: The adapter reports only aggregate presence, foreground app,
  inventory, and lock information. It does not capture keystrokes, clicks,
  persisted coordinates, URLs, or process command lines.

## 2026-08-17 — Use Month and Year filters for Attendance

- Request: Use the previous Month and Year filter behavior because the
  Attendance From/To combination was unreliable for a monthly calendar.
- Implementation: Replaced From and To inputs with Month and Year selectors
  that reload the selected attendance month directly.
- Database/API impact: None.
- Tests: Focused analysis and existing HR model tests passed.
- Saved-cell interaction: Removed the intermediate raw JSON detail popup from
  the Attendance calendar; selecting a persisted cell now opens Edit attendance
  directly and reloads the report after a successful save.

## 2026-08-17 — Monthly manual attendance and employee display

- Request: Let HR complete a full month for employees without system access.
- Implementation: Added a separate Monthly Attendance calendar with employee
  selection, default Present days, exception marking, locked weekly-off/future/
  existing cells, and one transactional save. The typed attendance model also
  retains employee names/codes, fixing the blank register column.
- API/database impact: Adds GET/POST `/hr/attendance-monthly-sheet` and the
  `lop` enum value. Existing installations apply
  `doc/sql/patch_monthly_manual_attendance_lop.sql`; new installs use
  `install.sql`.
- Security impact: Requires `hr.create` plus permission to manage all HR
  records; employees must be active and belong to the selected company.
- Tests: Focused Flutter and backend checks are recorded in `TESTING.md`.
- Compatibility fix: Monthly employee selection now uses `users.employee_code`
  when an existing production database does not have `users.employee_id`.
- Navigation refinement: Removed the duplicate Monthly Attendance drawer item;
  authorized HR users now open it from Bulk Attendance on the Attendance page.
- Draft/submit workflow: Draft saves remain editable and do not become payroll
  input. Submit locks them; payroll processing reports a clear error until all
  manual drafts for its period are submitted. Existing databases apply
  `doc/sql/patch_monthly_attendance_draft_submit.sql`.
- Attendance-sheet refinement: The Attendance route now reuses the monthly
  calendar for all employees. HR can change an Activity Watch day to a manual
  LOP, half-day, leave, absence, or present decision; the Bulk Attendance
  action retains its non-system-only scope.
- Compatibility fix: Send the all-employee flag as `1`/`0`, because the
  production Lumen query validator rejects the string form of `true`.
- Report-only refinement: Attendance now uses the monthly calendar only for
  persisted records. It removes bulk selection and draft/submit controls,
  leaves missing dates blank, labels saved cells by source, and reuses the
  single-record detail/editor when a saved cell is selected.
- Filter refinement: Removed the Attendance report's inline Month/Year/Load
  toolbar and reused the standard HR Filter dialog for period selection. Bulk
  Attendance retains its month controls for its separate preparation workflow.
- Filter completion: Restored report search, employee, status, and source
  options alongside month/year. After a successful Bulk Attendance submit, the
  app opens Attendance on that submitted period so persisted manual rows are
  shown immediately.
- Visual refinement: Removed the separate Monthly Attendance Report bar and
  status legend. The bordered employee/day grid, metadata, status pills, and
  pagination remain; Filter, Reload, and Bulk Attendance use the page actions.
- Table refinement: Replaced single-letter weekday headers with Mon–Sun labels
  and removed the Employee Status column.
- Grid refinement: Removed vertical daily-column lines while keeping horizontal
  row separation.
- Reuse refinement: Extracted the shared employee/day DataTable into
  `MonthlyAttendanceCalendarGrid`, used by both saved Attendance and Bulk
  Attendance while retaining their separate state and actions.
- Bulk visual alignment: Bulk Attendance now uses the same calendar layout as
  the saved report, including serial number, employee avatar, department, day
  headers, and horizontal row separators; its selection checkbox and editable
  attendance cells remain specific to bulk preparation.
- Attendance filter refinement: Replaced the popup filter with the shared,
  full-width, toggleable HR filter bar used as the Sales-style filter surface.
- HR filter completion: Migrated Leave Requests, Expense Claims, and Payslips
  to the same reusable inline filter bar and removed the unused popup helper.
- HR filter layout: Added a reusable full-width workspace-header slot so Leave
  Requests and Expense Claims display the filter bar across the full HR page,
  matching Attendance.
- HR filter actions: Removed Apply from the shared bar and reused the Sales
  Clear action layout; Attendance refreshes on period selection.
- Payroll Run filters: Added From date and To date to the existing toggleable
  Payroll Runs filter bar; both constrain displayed runs by their run date.
- Payroll Run filter layout: Removed the inner filter card so the shared bar
  uses the page's existing outer card, matching Payslips.
- HR filter action sizing: Reused the Sales filter Clear action dimensions and
  styling (160px wide, 48px high, left aligned) across all shared HR bars.

## 2026-08-17 — Activity Watch and manual attendance

- Request: Replace ERP-login attendance with Activity Watch agent attendance
  while retaining manual attendance for departments without computer access.
- Implementation: Removed the authentication attendance hook; added a
  device-authenticated attendance endpoint, company-local employee/day upsert,
  manual-row protection, earliest check-in/latest check-out handling, and a
  restart-safe agent retry file. The register labels the new source.
- Database/API impact: Adds `POST /api/v1/activity-watch/attendance`; reuses
  existing attendance columns and uniqueness, so no SQL patch is required.
- Security impact: The API resolves employee identity from the paired device
  and never accepts a client-supplied employee ID.
- Tests: Backend, Go agent, and focused Flutter checks are recorded in
  `TESTING.md`.

## 2026-08-14 — Restore processed payroll-run deletion control

- Request: Make the Delete option available in the processed payroll-run
  detail dialog.
- Implementation: Reused the existing DELETE API action for both draft and
  processed runs, added a permanent-lines-and-payslips warning for processed
  runs, and display API failures without closing the dialog. Posted runs remain
  protected.
- Database/API impact: None; the backend remains the lifecycle and
  voucher-link authority.
- Tests: Focused formatter and static analysis are recorded in `TESTING.md`.

## 2026-08-14 — Keep payroll process validation failures recoverable

- Request: Display the payroll validation message instead of leaving the app
  stuck when processing is rejected.
- Implementation: The payroll detail dialog catches typed API failures from
  Process, keeps the draft dialog open, and shows the backend message. A
  successful process retains the existing close-and-refresh flow.
- Database/API impact: None. Existing HTTP 422 payloads are now handled in the
  UI.
- Tests: Focused formatting and static analysis are recorded in `TESTING.md`.

## 2026-08-14 — Login attendance and attendance-based payroll

- Request: Generate attendance from successful login without duplicates,
  calculate payroll from attendance, and verify salary structure/components.
- Implementation: Extended existing HR models and UI for source, decimal
  attendance, readiness, paid days, earned gross, and LOP. Backend calculations
  are stored as immutable snapshots.
- Database/API impact: New optional response fields are Flutter-compatible;
  existing databases must apply the backend SQL patch before enabling login
  attendance. New databases receive the schema from `install.sql`; no framework
  migration is used.
- Security impact: No credential or token is stored in attendance; HR scoping
  remains unchanged.
- Tests: Focused Flutter test/analysis and backend suite passed; see `TESTING.md`.
- Known limitations: Sunday is the fixed first-release weekly off. Company
  holiday/shift editors and individual statutory liability accounts are future
  work; deductions post to combined `SALPAY001`.

## 2026-08-14 — Restrict Activity Watch disconnect to super admins

- Request: Show Disconnect only to super admins and keep ordinary users limited
  to their own employee activity.
- Specification: The page hides Disconnect for non-super-admins; the backend
  rejects their direct revoke requests with HTTP 403. Existing user-scoped
  device and summary queries remain unchanged.
- Implementation: Added the UI eligibility guard and replaced owner/HR revoke
  authorization with an explicit super-admin requirement at the API boundary.
- Database/API impact: The revoke endpoint's authorization is intentionally
  stricter; its response shape is unchanged.
- Security impact: Prevents a regular user from disconnecting any device,
  including their own, through either the UI or direct API call.
- Tests executed and results: Focused Flutter test/analyzer and backend PHP
  syntax check passed; details are in `TESTING.md`.
- Documentation updated: Specifications, testing notes, frontend changelog,
  and backend Activity Watch documentation/changelog.
- Known limitations: Authenticated role-based API verification remains manual.
- Follow-up work: None.

## 2026-08-14 — Document macOS direct-pairing recovery

- Request: Document the successful recovery for macOS pairing-file association
  failures.
- Implementation: Added a direct installed-agent pairing command and status
  check that use the downloaded one-time file without exposing its contents.
- Security impact: The documented recovery keeps pairing tokens and credentials
  out of terminal output and support messages.
- Tests executed and results: Manual macOS pairing succeeded with the direct
  command; the one-time bundle was consumed as expected.
- Documentation updated: Release operations guide and changelog.
- Follow-up work: None.

## 2026-08-14 — Fix macOS packaged-agent executable permissions

- Request: Diagnose the installed macOS app's `incorrect executable format`
  launch error.
- Implementation: Corrected the release command to package both executable
  files as mode `755`, rather than root-only `700` files after `pkgbuild`
  installs the app in `/Applications`.
- Tests executed and results: Inspection of the failed installed package found
  both executable files owned by `root` with mode `700`; the corrected package
  command is documented for the next build.
- Documentation updated: Release operations guide and changelog.
- Follow-up work: Rebuild the package after applying the corrected mode.

## 2026-08-14 — Fix macOS Activity Watch launcher build command

- Request: Resolve the Swift `@main` compilation error in the documented macOS
  release command.
- Implementation: Added `-parse-as-library` to both macOS pairing-launcher
  `swiftc` commands, which is required when compiling the `@main` launcher.
- Tests executed and results: The corrected launcher compilation command passed
  on macOS.
- Documentation updated: Release operations guide, packaging README, and
  changelog.
- Follow-up work: None.

## 2026-08-14 — Document Activity Watch release and agent operations

- Request: Provide proper Windows/macOS build, API download publication,
  unsigned macOS development installation, existing-agent removal, and command
  reference documentation.
- Implementation: Added a single operations guide with exact stable artifacts,
  backend download-folder copy commands, scoped Gatekeeper quarantine removal,
  and destructive-removal warnings.
- Database/API impact: None; documents the existing installer URL contract.
- Security impact: Explicitly limits unsigned macOS bypass to a verified,
  internally approved package and never disables Gatekeeper globally.
- Documentation updated: Documentation index, frontend changelog, and backend
  changelog.
- Known limitations: Production macOS packaging still requires organization
  Developer ID signing and notarization.
- Follow-up work: None.

## 2026-08-14 — Restrict Activity Watch uploads and add macOS USB metadata

- Request: Upload Activity Watch data only at ERP logout to reduce server
  requests, and add macOS USB monitoring.
- Specification: Records remain encrypted locally until native ERP logout
  drains the outbox; no upload occurs at agent start, on a timer, after summary
  generation, or at shutdown. macOS reports consented USB device topology only;
  Windows retains removable-drive and bounded file-change metadata.
- Implementation: Removed startup, interval, summary, and shutdown flushes;
  added `system_profiler SPUSBDataType -json` parsing for bounded macOS USB
  device observations; added non-Windows fallbacks so macOS builds do not link
  Windows-only collector APIs.
- Files changed: Activity Watch agent runner, collector, command wiring,
  tests, specifications, architecture, decisions, service guide, testing notes,
  and changelog.
- Database/API impact: No schema or endpoint change. Pending outbox items can
  remain across shutdown until ERP logout.
- Security impact: Local SQLCipher/AES-GCM protection remains in force. macOS
  collection does not enumerate mounted files or read file contents.
- Tests added or updated: Logout-only runner coverage and macOS USB parser
  coverage.
- Tests executed and results: `go test ./...`, `go vet ./...`, and
  `go build ./cmd/activity-watch-agent` passed.
- Documentation updated: Specifications, architecture, ADRs, service guide,
  testing notes, and changelog.
- Known limitations: Real macOS USB-device connection/disconnection and
  permission behavior require hardware verification. macOS does not report USB
  port totals or removable-drive file changes.
- Follow-up work: None.

## 2026-08-14 — Refine Activity Watch browser-title tiles

- Request: Improve the Browser tab titles section UI.
- Specification: Present existing privacy-safe foreground titles as compact,
  responsive title tiles with a browser icon and duration badge.
- Implementation: Replaced divider rows with bordered two-column title tiles
  that stack at narrow widths; title aggregation and privacy boundaries remain
  unchanged.
- Files changed: Activity Watch setup page, specifications, summary-table
  requirements, testing notes, and changelog.
- Database/API impact: None.
- Security impact: None; URLs and page content remain absent.
- Tests added or updated: Existing Activity Watch parsing coverage remains
  applicable.
- Tests executed and results: Focused Flutter test and analyzer passed; details
  are recorded in `TESTING.md`.
- Documentation updated: Activity Watch specifications, summary-table
  requirements, testing notes, and changelog.
- Known limitations: Authenticated visual verification remains manual.
- Follow-up work: None.

## 2026-08-14 — Fold Activity Watch detail sections

- Request: Keep graphs visible and make each non-graph detail section foldable.
- Specification: Application activity, Browser tab titles, Background
  applications, and USB activity are initially folded and independently toggle
  from their headers; duration graphs remain visible in an open daily record.
- Implementation: Added one reusable icon-led foldable-section header with
  state-specific chevrons and used it for the four existing detail sections.
- Files changed: Activity Watch setup page, specifications, summary-table
  requirements, testing notes, and changelog.
- Database/API impact: None.
- Security impact: None; folded content remains limited to existing
  privacy-safe response fields.
- Tests added or updated: Existing Activity Watch parsing coverage remains
  applicable.
- Tests executed and results: Focused Flutter test and analyzer passed; details
  are recorded in `TESTING.md`.
- Documentation updated: Activity Watch specifications, summary-table
  requirements, testing notes, and changelog.
- Known limitations: Authenticated visual verification remains manual.
- Follow-up work: None.

## 2026-08-14 — Clarify the expanded Activity Watch record

- Request: Make it clear which Recent daily activity card is open or folded.
- Specification: A closed record has a down chevron; the record with inline
  details open has an up chevron.
- Implementation: Added an optional trailing widget to the shared ERP dashboard
  list item and supplied a labelled direction-changing chevron for Activity
  Watch records.
- Files changed: Shared ERP dashboard component, Activity Watch setup page,
  specifications, testing notes, and changelog.
- Database/API impact: None.
- Security impact: None; the control exposes no additional activity data.
- Tests added or updated: Existing Activity Watch parsing coverage remains
  applicable.
- Tests executed and results: Focused Flutter test and analyzer passed; details
  are recorded in `TESTING.md`.
- Documentation updated: Activity Watch specifications, summary-table
  requirements, testing notes, and changelog.
- Known limitations: Authenticated visual verification remains manual.
- Follow-up work: None.

## 2026-08-13 — Add Activity Watch graph date axis

- Request: Show the month and day at the bottom of each graph.
- Implementation: Added up to four evenly spaced `MMM d` labels below each
  graph so dates remain readable at narrow widths.
- Database/API impact: None.
- Security impact: Aggregate durations only.

## 2026-08-13 — Fix Activity Watch graph hover visibility

- Request: Make graph hover values visible and remove graph points.
- Implementation: The hover tooltip now follows the selected graph position,
  stays within the graph bounds, and uses a high-contrast elevated surface.
  Removed all plotted point markers.
- Database/API impact: None.
- Security impact: Aggregate durations only.

## 2026-08-13 — Remove Activity Watch graph card borders

- Request: Remove the graph card borders.
- Implementation: Kept each graph's rounded card surface and removed its
  outline, leaving the mountain curves, timeline, and hover values unchanged.
- Database/API impact: None.
- Security impact: Aggregate durations only.

## 2026-08-13 â€” Remove the Activity Watch graph-set container

- Request: Remove the Activity duration label, supporting label, and outer
  outlined container.
- Implementation: The expanded details view now renders only the individual
  duration graph cards.
- Database/API impact: None.
- Security impact: None.

## 2026-08-13 â€” Simplify Activity Watch graph labels and add hover values

- Request: Remove unwanted graph labels, add a left timeline, and support
  hover values.
- Implementation: Removed graph legends/date labels, added duration scale
  labels on the left, and added pointer hover tooltips.
- Database/API impact: None.
- Security impact: Aggregate durations only.


## 2026-08-13 â€” Style Activity Watch duration graphs as mountain cards

- Request: Match the supplied curved green/red mountain-graph visual and wrap
  every Activity Watch graph in its own card.
- Implementation: Updated the local Activity Watch custom painter to draw
  smooth filled curves and added individually bordered graph cards.
- Database/API impact: None.
- Security impact: Aggregate durations only.
- Tests executed and results: Recorded in `TESTING.md`.


## 2026-08-13 â€” Expand Activity Watch duration graphs

- Request: Show all Activity Watch duration types as graphs and remove the
  unused analytics configuration space.
- Implementation: Added total, keyboard, mouse, and browser duration graphs to
  selected activity details. The shared dashboard now omits its analytics
  column when no insight card is available.
- Database/API impact: None.
- Security impact: Aggregate durations only.
- Tests executed and results: Recorded in `TESTING.md`.


## 2026-08-14 — Render single-day Activity Watch graph lines

- Request: Fix invisible graph lines in the Activity Watch report.
- Specification: Render a full-width horizontal duration line when the selected
  date range yields only one daily point.
- Implementation: Expanded one-point painter offsets to the left and right
  chart boundaries, allowing the existing filled path and stroke to render.
- Files changed: Activity Watch setup page, specifications, testing notes, and
  changelog.
- Database/API impact: None.
- Security impact: Aggregate durations only.
- Tests added or updated: Existing model parsing coverage remains applicable.
- Tests executed and results: Focused Flutter test and analyzer passed; details
  are recorded in `TESTING.md`.
- Documentation updated: Activity Watch specifications, testing notes, and
  changelog.
- Known limitations: Authenticated visual verification with real report data
  remains manual.
- Follow-up work: None.

## 2026-08-14 — Restore Full activity details background

- Request: Undo the removal of the Full activity details background color.
- Specification: Retain the details background fill, rounded shape, spacing,
  and content.
- Implementation: Restored the filled rounded container around the details.
- Files changed: Activity Watch setup page, specification, testing notes, and
  changelog.
- Database/API impact: None.
- Security impact: None.
- Tests added or updated: Existing model parsing coverage remains applicable.
- Tests executed and results: Focused Flutter test and analyzer passed; details
  are recorded in `TESTING.md`.
- Documentation updated: Activity Watch specification, testing notes, and
  changelog.
- Known limitations: Authenticated visual verification remains manual.
- Follow-up work: None.

## 2026-08-13 — Activity Watch USB detail layout

- Request: Update the USB activity section UI.
- Specification: Render existing USB data as a port-status line, responsive
  device cards, and compact file-change rows instead of tables or an outer card.
- Implementation: Replaced USB device and file-event tables with the new
  responsive detail layouts, retaining the existing file-path tooltip and
  safety-limit message. Removed obsolete table/outer-card helpers that were no
  longer used by any expanded detail section.
- Files changed: Activity Watch setup page, specifications, testing notes, and
  changelog.
- Database/API impact: None.
- Security impact: Existing privacy limits remain unchanged; file content and
  URLs are not shown.
- Tests added or updated: Existing model parsing coverage remains applicable.
- Tests executed and results: Focused Flutter test and analyzer passed; details
  are recorded in `TESTING.md`.
- Documentation updated: Activity Watch specifications, testing notes, and
  changelog.
- Known limitations: Authenticated visual verification with real USB metadata
  remains manual.
- Follow-up work: None.

## 2026-08-13 — Activity Watch background-application process grid

- Request: Update the Background applications section UI.
- Specification: Show existing bounded process names and states in a responsive
  four-column grid without chips or an enclosing outer card.
- Implementation: Replaced the chip list and outer section card with compact
  process cards, and sort de-duplicated process entries alphabetically for a
  stable display.
- Files changed: Activity Watch setup page, specifications, testing notes, and
  changelog.
- Database/API impact: None.
- Security impact: No new process data is exposed; only the existing bounded
  name/state fields are displayed.
- Tests added or updated: Existing model parsing coverage remains applicable.
- Tests executed and results: Focused Flutter test and analyzer passed; details
  are recorded in `TESTING.md`.
- Documentation updated: Activity Watch specifications, testing notes, and
  changelog.
- Known limitations: Authenticated visual verification with live process data
  remains manual.
- Follow-up work: None.

## 2026-08-13 — Activity Watch browser-title activity list

- Request: Update the Browser tab titles section UI.
- Specification: Show existing browser titles as a compact, duration-ranked
  activity list without supporting label text below the heading.
- Implementation: Replaced the browser-title table and card grid with compact
  icon-led rows, duration badges, and subtle dividers, sorting titles by
  duration; removed the supporting label beneath the Browser tab titles heading.
- Files changed: Activity Watch setup page, specifications, testing notes, and
  changelog.
- Database/API impact: None.
- Security impact: The UI continues to display only existing foreground tab
  titles; URLs and page content remain absent.
- Tests added or updated: Existing model parsing coverage remains applicable.
- Tests executed and results: Focused Flutter test and analyzer passed; details
  are recorded in `TESTING.md`.
- Documentation updated: Activity Watch specifications, testing notes, and
  changelog.
- Known limitations: Authenticated visual verification with live browser-title
  data remains manual.
- Follow-up work: None.

## 2026-08-13 — Professional Activity Watch application report

- Request: Update the Activity Watch application section with a professional
  presentation.
- Specification: Present existing application totals as a responsive three-card
  ranked grid with readable categories and durations, not a table or percentage
  comparison.
- Implementation: Sorted the existing de-duplicated totals by duration and
  replaced the application table with a responsive three-card grid without an
  enclosing outer card. Removed the duplicate date/device subtitle and fixed
  category tokenization so `Unclassified` is not split into two words.
- Files changed: Activity Watch setup page, dashboard specification, main
  specification, testing notes, and changelog.
- Database/API impact: None; the UI reuses existing application name,
  classification, and duration fields.
- Security impact: None; no additional process or input information is shown.
- Tests added or updated: Existing summary parsing coverage remains applicable;
  no API contract changed.
- Tests executed and results: Focused Flutter test and analyzer passed; details
  are recorded in `TESTING.md`.
- Documentation updated: Activity Watch specifications, testing notes, and
  changelog.
- Known limitations: Authenticated visual verification with real application
  totals remains manual.
- Follow-up work: None.

## 2026-08-13 — Add missing Activity Watch duration graphs

- Request: Show locked and untracked time in the Activity Watch graph section.
- Specification: Extend the expanded device details with two duration graphs.
  Untracked time maps directly to the existing `unknown_seconds` API field and
  does not estimate time absent from a device report.
- Implementation: Extended the selected-device, date-keyed aggregation and
  rendered Locked time and Untracked time graph cards from the already-loaded
  summaries.
- Files changed: Activity Watch setup page, model parsing test, specification,
  dashboard record, testing notes, and changelog.
- Database/API impact: None; existing summary fields are reused.
- Security impact: None; the change renders only existing aggregate durations.
- Tests added or updated: Added numeric-string parsing coverage for the two
  graph duration fields.
- Tests executed and results: Focused Flutter test and analyzer passed; details
  are recorded in `TESTING.md`.
- Documentation updated: Activity Watch specification, dashboard record,
  testing notes, and changelog.
- Known limitations: Authenticated visual verification with live report data
  remains manual.
- Follow-up work: None.

## 2026-08-13 â€” Move the Activity Watch keyboard graph into details

- Request: Replace the expanded Activity Watch metric containers with the
  previously requested keyboard active/idle graph, not a dashboard-level graph.
- Implementation: Replaced the selected activity metric-tile grid with a
  two-line, per-device daily keyboard activity graph using already-loaded
  summaries.
- Database/API impact: None.
- Security impact: Aggregate durations only; no input content is displayed.
- Tests executed and results: Recorded in `TESTING.md`.
- Documentation updated: Activity Watch specification, dashboard record,
  testing notes, and changelog.


## 2026-08-13 â€” Remove Activity Watch active trend graph

- Request: Remove the active trend graph from Activity Watch.
- Specification: Keep recent daily activity, filters, loading/error/empty
  states, and the detailed activity view; omit only the chart.
- Implementation: Removed the Activity Watch dashboard trend configuration and
  its page-only daily active-time aggregation helper.
- Files changed: Activity Watch setup page and frontend documentation.
- Database/API impact: None.
- Security impact: None.
- Tests added or updated: No behavior-specific automated test was needed; the
  removed chart had no interactive or API contract.
- Tests executed and results: Recorded in `TESTING.md`.
- Documentation updated: Activity Watch specification, dashboard record,
  testing notes, and changelog.
- Known limitations: Authenticated visual confirmation remains manual.


## 2026-08-13 — Add gross and net summary to saved payslips

- Request: Mention Gross Amount and Net Amount on the payslip.
- Specification: Render a summary fallback for saved payslip templates that do
  not already reference the existing salary-summary values.
- Implementation: Extended the shared payslip-template normalization to append
  a Gross Salary, Total Deductions, and Net Salary display only when a saved
  layout has no existing salary-summary binding.
- Follow-up: Removed the duplicate Total Deductions table row and added CTC
  Monthly to the bottom salary summary.
- Database/API impact: None; uses existing `salary_summary` print data.
- Security impact: None.
- Tests added or updated: Added fallback and no-duplication cases to payslip
  template compatibility coverage.
- Tests executed and results: Focused payslip-template tests passed (5 tests).
  PHP syntax validation passed; Flutter analysis reported only the existing
  unrelated CRM unused-method warning.
- Documentation updated: Specification, architecture, testing notes, and
  changelog.
- Known limitations: The fallback position follows the standard payslip layout;
  highly custom designs can be adjusted through the existing print designer.

## 2026-08-13 — Allow processed payroll-run deletion

- Request: Make Delete available while viewing a processed payroll run.
- Specification: Processed and draft runs require confirmation before using the
  existing delete API; posted and voucher-linked protection remains server-side.
- Implementation: Extended the existing delete action to processed state with
  a cascade-deletion warning for generated payroll lines and payslips, and
  removed the processed-state Post action.
- Files changed: Payroll workflow dialog and frontend documentation.
- Database/API impact: None; reuses the existing DELETE endpoint and database
  foreign-key cascade.
- Security impact: Existing `hr.delete` authorization remains unchanged.
- Tests added or updated: UI behavior is covered by focused source-level
  verification; no API/model contract changed.
- Documentation updated: Specification, architecture, testing notes, and
  changelog.
- Known limitations: Authenticated UI confirmation remains a manual check.

## 2026-08-12 â€” Fix section-card ink surfaces and device-card overflow

- Request: Resolve a ListTile ink/background assertion and a constrained
  Activity Watch Devices card RenderFlex overflow.
- Specification: Section cards must provide the Material surface that paints
  their background; the Devices card must scroll its legitimate paged content
  when its parent limits height.
- Implementation: Moved the shared card background from `DecoratedBox` to its
  rounded `Material` child while retaining the outer shadow. Wrapped Devices
  card content in a vertical `SingleChildScrollView`.
- Files changed: Shared section card, Activity Watch setup page, and frontend
  documentation.
- Database/API impact: None.
- Security impact: None.
- Tests executed and results: `git diff --check` passed. Flutter/Dart commands
  could not run because neither executable is available on the execution PATH.
- Documentation updated: Activity Watch feature specification and changelog.
- Known limitations: Authenticated responsive visual verification remains
  manual.

## 2026-08-11 — Apply salary-component order to all employees

- Request: Apply a configured Salary Components order to all employees without
  changing generated payslips.
- Specification: Copy ordering by matching component name within the selected
  employee's company; retain unmatched target rows and all salary values.
- Implementation: Added a confirmed per-structure action, an authorized API,
  and explicit persisted component order. Only matching component rows in the
  selected company are reordered; generated payroll and payslip records are
  not queried or changed.
- Database/API impact: Adds explicit component ordering through a standalone
  additive SQL patch (no framework migration) and an authorized HR apply-order
  endpoint; generated payroll and payslip records are excluded.
- Security impact: Uses the existing authenticated `hr.update` permission.
- Tests: Focused Flutter and PHP tests passed; Flutter analysis reported one
  pre-existing CRM warning only.
- Documentation updated: Specification, architecture, ADR, testing notes, and
  backend contract record.

## 2026-08-11 — Employee salary component grouped amounts

- Request: Fix the false `Amount must be a valid number` error when saving a
  salary component whose amount is displayed with a thousands separator.
- Specification: `1,000.00` must validate and serialize as numeric `1000.0`;
  malformed and negative values remain invalid.
- Implementation: Reused `Validators.parseFlexibleNumber` for component form
  validation and salary draft serialization, including salary-structure numeric
  fields that use the same formatted controls.
- Files changed: Employee salary page/controller, focused controller test, and
  frontend documentation.
- Database/API impact: None; the existing numeric API contract is preserved.
- Security impact: None.
- Tests added or updated: Added grouped component and salary-structure
  serialization coverage.
- Tests executed and results: Focused Flutter test passed (3 tests); Flutter
  analysis reported only three pre-existing unrelated warnings.
- Documentation updated: Specification, testing notes, and changelog.
- Known limitations: Final authenticated browser save remains a manual check.
- Follow-up work: None.

## 2026-08-10 — Consent-gated office monitoring detail

- Added sampled keyboard/mouse active and idle estimates, encrypted foreground
  browser-title totals, and bounded background process inventory.
- Added local schema version 3 with additive version-1/2 migration, API
  validation/defaults, typed Flutter models, updated consent wording, and
  expanded dashboard sections.
- Existing summaries remain compatible through zero/empty defaults.
- No typed keys, clicks, coordinates, URLs, screenshots, clipboard, page
  content, or process command lines are collected.
- Go agent suite, focused Flutter tests, PHP syntax, formatting, and Flutter
  analysis were run. Installed Windows/macOS permission checks remain manual.

## 2026-08-10 — Activity Watch employee filter

- Added a super-admin-only employee filter to Recent daily activity.
- Summary responses now include employee identity so each selected record opens
  the correct full-details dialog; API viewer scoping remains unchanged.

## 2026-08-10 — Activity Watch focused full details

- Request: Remove the Activity distribution and recent daily activity cards and
  expose the complete activity report from the dashboard.
- Implementation: The overview now keeps KPI, trend, and highlight content;
  its Full details action scrolls to the full-width daily report. Selecting a
  row shows active, idle, aggregate keyboard/mouse input, browser, lock,
  offline, unknown, tracked, and classified application totals.
- Database/API impact: None; no background-process or raw input data is added.
- Tests: Formatting and the focused Activity Watch dashboard tests passed.
- Documentation updated: Activity Watch feature record, specification, testing
  notes, and changelog.

## 2026-08-10 — Activity Watch setup layout and device pagination

- Request: Place Connect a computer and Devices in the same row and show only
  five device records at a time with pagination for the rest.
- Specification: Extended the Activity Watch feature record with responsive
  setup-card and newest-first local-pagination requirements.
- Implementation: Placed the dashboard first, followed by an equal two-column
  setup row above the optional pairing and credential cards, with narrow layouts
  stacking automatically. The Devices card now uses the shared
  `LocalPageNavigation` at five rows per page and resets to the newest page
  after status refreshes.
- Files changed: Activity Watch setup page and feature documentation.
- Database/API impact: None; the existing newest-first device response is reused.
- Security impact: None.
- Tests added or updated: Existing Activity Watch model/dashboard coverage was
  retained; the pagination is a bounded presentation-only slice over the
  loaded device list.
- Tests executed and results: Focused Activity Watch tests and the complete
  54-test Flutter suite passed. `flutter build web` passed. Analysis reports
  only two pre-existing unrelated warnings.
- Documentation updated: Specification, testing notes, and changelog.
- Known limitations: Final authenticated visual verification remains manual.
- Follow-up work: None required for this layout change.

## 2026-08-10 — Activity Watch reusable ERP dashboard

- Request: Present Activity Watch in a dashboard layout inspired by the
  supplied reference and reuse the existing ERP dashboard widget.
- Specification: Extended
  [the Activity Watch dashboard specification](activity-watch-summary-table.md)
  with reusable dashboard, aggregation, trend, distribution, highlights, and
  detailed-table requirements.
- Implementation: Reused `ErpModuleDashboard` for a responsive header, date
  actions, four KPI cards, recent daily activity, active-time trend, activity
  distribution, and highlights. The complete interactive daily/application
  table remains below it. A feature-local metrics helper derives all dashboard
  values from the already-loaded summary collection and limits chart labels to
  the latest 12 reporting days when necessary.
- Files changed: Activity Watch page, dashboard metrics helper and tests, plus
  specification, testing, and changelog documentation.
- Database/API impact: None; no additional request is made.
- Security impact: None; only existing privacy-safe aggregate fields are used.
- Tests added or updated: Added two aggregation tests covering totals,
  uniqueness, daily grouping/order, and empty input.
- Tests executed and results: Focused tests passed all 6 tests; the complete
  Flutter suite passed all 54 tests; `flutter build web` passed. Analysis
  reports only two pre-existing unrelated warnings.
- Documentation updated: Specification, feature record, testing notes, and
  changelog.
- Known limitations: Final authenticated desktop and narrow-width visual
  verification remains manual.
- Follow-up work: None required for the dashboard implementation.

## 2026-08-10 — Activity Watch professional full-width report

- Request: Redesign the full-width Activity table section as a clean,
  professional desktop report.
- Specification: Updated
  [the Activity Watch summary-table specification](activity-watch-summary-table.md)
  with responsive toolbar, compact-row, table-surface, and application-panel
  requirements.
- Implementation: Kept setup and device cards at their readable 900px maximum
  width while allowing the report to fill the shell content area. Replaced the
  loose title/filter stack with a responsive report toolbar, removed automatic
  selection checkboxes, fixed daily rows at 56px, applied shared hover/selected
  colors, framed both tables, and moved application totals into a distinct
  details panel with a close action.
- Files changed: Activity Watch setup page and its specification, testing, and
  changelog documentation.
- Database/API impact: None.
- Security impact: None; consent, collection, and privacy rules are unchanged.
- Tests added or updated: No new automation was required because the API/model
  contract is unchanged; existing Activity Watch model coverage was retained.
- Tests executed and results: Focused Activity Watch tests and the complete
  52-test Flutter suite passed. `flutter build web` passed. `flutter analyze`
  reports only two pre-existing unrelated warnings.
- Documentation updated: Specification, feature record, testing notes, and
  changelog.
- Known limitations: Final desktop and narrow-width visual checks remain
  manual.
- Follow-up work: None required for this presentation-only change.

## 2026-08-10 — macOS pairing-file launch race

- Fixed the macOS package launcher exiting during startup before Launch Services
  delivered a `.billingawpair` file. The updated package waits for the file
  event, implements AppKit's `openFile` callback, pairs the device, and reports
  the result instead of rejecting the document as unsupported.
- Refresh the copied per-user agent from the installed package before pairing,
  so package updates apply new agent behavior to an already provisioned Mac.
- Generate 64-character hexadecimal pairing credentials rather than URL-safe
  Base64 values, which may contain characters rejected by the server validator.
- Replace obsolete invalid pairing candidates before exchange so a failed
  development attempt can be retried without manually editing local files.

## 2026-08-10 — Activity Watch local-network HTTP development exception

- Permit only `http://bill.local/...` and `http://192.168.31.83:8000/...` for
  development pairing and sync so agents can be tested against the internal
  pre-TLS server. All other remote HTTP hosts remain blocked; trusted HTTPS is
  still required before broader deployment. See
  [the specification](activity-watch-bill-local-http-development.md).

## 2026-08-07 — Activity Watch summary table

- Replaced the stacked Activity Watch daily-summary cards with a compact,
  horizontally scrollable metrics table. Its application breakdown now opens
  below the selected daily row instead of widening every table row. No API,
  collection, or privacy behaviour changed. See
  [the specification](activity-watch-summary-table.md).

## 2026-08-07 — Activity Watch concise UI

- Simplified the setup, pairing, device, and activity-summary labels using the
  existing Activity Watch cards and expandable summary rows.
- Preserved explicit consent, pairing expiry, device state, disconnect action,
  date filters, and detailed metrics while moving secondary duration data into
  the expanded summary area.

## 2026-08-07 — macOS pairing launcher package permissions

- Fixed the packaged application executables being installed as root-owned
  mode `0700`, which prevented normal employees from opening the pairing app.
- Application-bundle executables now use mode `0755`; after first launch, the
  copied per-user agent remains protected with mode `0700` in the employee's
  application-support directory.

## 2026-08-07 — Privacy-safe input and browser duration

- Request: Add keyboard/mouse usage, idle time, and browser activity reporting.
- Implementation: Added sampled `input_seconds` and foreground-browser
  `browser_seconds` daily totals. Input sampling records only whether any input
  occurred between samples; browser reporting remains category-only.
- Database/API impact: Upgrades the encrypted local schema from version 1 to 2
  in place with one boolean segment flag and two aggregate columns. The server
  keeps the existing three tables and stores the additive fields in validated
  summary metadata; old summaries default them to zero.
- Security impact: Raw keys, clicks, coordinates, tab/window titles, domains,
  URLs, private/incognito data, page/form content, clipboard, and screenshots
  remain prohibited.
- Reuse/optimization: Reused existing idle timestamps, consolidated activity
  segments, application classification, bounded summary aggregation, model, and
  summary UI. Aggregation is linear in the bounded daily category result set.
- Validation: Complete Go tests, vet, and build passed; PHP controller lint
  passed; all 52 Flutter tests passed. Flutter analysis retained only two
  unrelated pre-existing warnings, and both repository diff checks passed.
- Limitation: `input_seconds` is a sampling approximation and intentionally
  combines keyboard and mouse activity; it cannot reconstruct user input.


## 2026-08-07 — Activity Watch self-service employee pairing

- Request: Replace manual device-ID, credential-file, JSON, and Terminal setup
  with a workflow usable by non-technical employees.
- Implementation: Added authenticated ten-minute pairing sessions, a public
  single-use/idempotent exchange, locally generated device credentials, strict
  `.billingawpair` bundles, automatic SQLCipher provisioning and protected
  configuration, service activation, Flutter Web download/connection states,
  and Windows/macOS/Linux installer/file-association assets.
- Database/API impact: Reuses the existing three Activity Watch tables. Adds
  pairing hash/expiry/paired fields to `activity_watch_devices` and two pairing
  endpoints through guarded additive SQL; no migration or fourth table.
- Security impact: Pairing files contain no permanent credential. Tokens are
  hash-only server-side, expire after ten minutes, and accept only the same
  locally generated credential on an idempotent retry. Production URLs require
  HTTPS.
- Reuse/optimization: Reused the typed API client, shared file downloader,
  Activity Watch cards, provisioner, config model, service host, and device
  table. Indexed token lookup and row locking avoid polling and table scans.
- Tests: Go full tests/vet/build passed; PHP policy tests passed with 3 tests and
  7 assertions; PHP syntax/diff checks passed; all 52 Flutter tests passed.
  Flutter analysis reports only two unrelated existing warnings. The macOS
  launcher type-check, shell syntax checks, and an unsigned 7.5 MB `.pkg` test
  build also passed.
- Remaining release validation: Build, sign/notarize, publish, and open the
  native packages on each target OS; configure installer/API base URLs.

## 2026-08-07 — Activity Watch cross-platform completion

- Request: Complete the remaining Activity Watch implementation before manual
  testing.
- Specification: Added the consent-gated cross-platform collection, summary,
  retention, reporting, and credential-handoff contract.
- Implementation: Added bounded Windows/macOS/Linux idle and foreground-app
  adapters, lifecycle inference, consolidated local state/application segments,
  deduplicated process/service inventories, revisioned encrypted daily
  summaries with offline and local-midnight apportionment, 90-day cleanup,
  authentication-failure recovery, strict backend ingestion,
  device/revocation/report APIs, automatic native credential/config handoff,
  and Flutter device/summary views.
- Compatibility: Generic Go `Local` timezone values now use an explicit UTC
  offset (for example `+05:30`) so backend daily-summary timestamps validate
  consistently across operating systems.
- Database/API impact: Keeps the approved 10-table local schema. Adds
  `last_seen_at`, `metadata_json`, `event_at_utc`, indexed summary local date
  and `revision`, and report indexes to the existing three-table server design through
  `install.sql` and the additive patch; no framework migration table is
  introduced. Adds authenticated device, summary, and revoke endpoints.
- Security impact: Collection remains limited to idle duration, lock state,
  executable/application name/category, and bounded process/service names.
  Payloads remain SQLCipher/AES-GCM protected; server projections are validated
  and exclude prohibited desktop content.
- Tests added or updated: Go collector/store/config tests and Flutter Activity
  Watch model tests.
- Tests executed and results: Complete Go tests, vet, and macOS arm64 build
  passed; PHP Activity Watch lint passed; all 50 Flutter tests passed; Flutter
  analysis reported only two unrelated existing warnings; both repository diff
  checks passed.
- Documentation updated: Specification, architecture, ADR-0009/0010, testing,
  operations guide, and changelog.
- Known limitations: Browser tab content is intentionally excluded. Native
  packaging and permission behavior still require manual verification on each
  supported operating system.

## 2026-08-06 — Activity Watch lifecycle outbox delivery

- Request: Continue the Activity Watch implementation with a verifiable local
  queue-to-server delivery path.
- Implementation: The Go store now AES-GCM encrypts and writes each approved
  machine lifecycle event's minimal `system-event` outbox record in the same
  SQLCipher transaction as the local event. A normal service start therefore
  queues an `agent-start` record for the configured batch uploader without
  collecting desktop-content data.
- Privacy/security impact: The queued JSON is limited to event type and UTC
  occurrence time; it contains no credentials, window titles, URLs, keystrokes,
  clipboard, screenshots, or command-line data.
- Tests added or updated: Store integration test now verifies the encrypted
  outbox row, nonce/tag, decryptable minimal payload, checksum, and idempotency
  key created by `RecordSystemEvent`.
- Tests executed and results: `gofmt -d internal/store/store.go
  internal/store/store_test.go` produced no diff; `go test -count=1 ./...`,
  `go vet ./...`, and `go build -o /private/tmp/activity-watch-agent-lifecycle
  ./cmd/activity-watch-agent` passed on macOS arm64.
- Documentation updated: Specification, architecture, ADR-0008, testing, and
  changelog.
- Known limitations: Native foreground/idle collectors and production
  service-manager packaging remain pending; this delivery step covers only
  policy-safe machine lifecycle events.

## 2026-08-06 — Activity Watch consent setup screen

- Added Settings → Activity Watch for explicit privacy-safe consent, device
  label entry, authenticated enrollment, and one-time device credential display.
- The screen excludes prohibited collection categories and does not start the
  native agent itself; Go credential/configuration handoff remains pending.

## 2026-08-06 — Activity Watch foreground shutdown fix

- Request: Diagnose the `service shutdown exceeded its deadline` message after
  stopping a foreground Go agent with Ctrl+C.
- Implementation: Captured the per-run completion channel in the worker
  goroutine before shutdown clears the program field. The worker can now report
  completion after cancellation instead of blocking on a nil channel.
- Files changed: Go service lifecycle implementation/test and changelog.
- Database/API/security impact: None.
- Tests added or updated: Added an integration-style start/stop test using a
  provisioned encrypted database and disabled sync.
- Tests executed and results: `go test -count=1 ./...`, `go vet ./...`, and
  `go build -o /private/tmp/activity-watch-agent-fixed
  ./cmd/activity-watch-agent` passed on macOS arm64. `git diff --check` passed.
- Known limitations: Native service-manager lifecycle testing remains required
  on Windows, macOS, and Linux.

## 2026-08-06 — Activity Watch service provisioning command

- Request: Provide a complete command to create the local Activity Watch
  database needed to run the Go service.
- Specification: Updated Activity Watch service requirements in
  `docs/SPECIFICATIONS.md`.
- Implementation: Added `activity-watch-agent provision --config <absolute-path>`.
  It generates a raw 256-bit key, creates the encrypted version-1 schema and
  logout-control parent, and publishes the database/key only when both target
  paths are absent.
- Files changed: Go command, provisioner, SQLCipher schema initializer, store
  reuse helpers/tests, and service architecture/operations documentation.
- Database/API impact: Adds a fresh local version-1 SQLCipher provisioning
  path; does not alter the ERP API or server database.
- Security impact: Key contents are never logged; key files are mode `0600` on
  Unix; existing database/key targets are rejected rather than overwritten.
- Tests added or updated: Encrypted provisioning/reopen/schema-index test,
  key permission test, control-directory test, and existing-target preservation
  test.
- Tests executed and results: `go test -count=1 ./...`, `go vet ./...`, and
  `go build -o /private/tmp/activity-watch-agent-provision
  ./cmd/activity-watch-agent` passed on macOS arm64. `git diff --check` passed.
- Documentation updated: Specifications, architecture, ADR-0007, testing,
  operations guide, and changelog.
- Known limitations: Provisioning creates a new Go-managed database/key pair;
  it does not import an existing Flutter secure-storage key or enable user
  activity collectors, enrollment, ERP ingestion, or native installers.
- Follow-up work: Add consent/enrollment and machine-key storage integration
  before production rollout.

## 2026-08-06 — Synchronize party code with party type

- Request: Fix an existing Supplier changed to Customer retaining `SUP/0106`,
  which then causes a duplicate-code error when creating the next Supplier.
- Specification: `docs/party-code-type-sync.md`.
- Implementation: Party-type changes now regenerate the read-only party code
  for existing and new parties. Opening an existing party with a prefix that
  does not match its type also prepares a corrected code for save. Returning an
  unsaved edit to its original type restores its saved code, and a request
  token prevents stale async lookups from applying a code for a previously
  selected type. Save also waits for any required prefix correction. Existing
  prefix and next-number logic was extracted into a reusable, testable helper.
  Used-code lookup now searches the target prefix globally rather than
  filtering by party type, so a stale `SUP/...` code on a Customer is included.
- Files changed: Parties page, helper export, party-code helper and tests, and
  engineering documentation.
- Database/API impact: None. The existing required `party_code` request field,
  backend uniqueness validation, and global database unique key are unchanged.
- Security impact: None.
- Tests added or updated: Nine party-code helper regression tests, including
  the reported cross-type `SUP/0106` collision.
- Tests executed and results: Focused test passed all 9 tests; complete
  `flutter test` passed all 48 tests; `flutter analyze` reported only the
  pre-existing unrelated `_buildGapList` unused-element warning.
- Documentation updated: README index, specification, architecture, testing,
  and changelog.
- Known limitations: Final code allocation is still optimistic in the client;
  a simultaneous create by another user can still be rejected by backend
  uniqueness validation and retried.
- Follow-up work: Consider server-side atomic party-code allocation if
  concurrent party creation becomes frequent.

## 2026-08-06 — Activity Watch Go desktop background service

- Request: Start monitoring storage with the PC, keep a background service
  alive after user logout, upload pending local data, and stop at shutdown.
- Specification: Activity Watch Go desktop service in
  `docs/SPECIFICATIONS.md`.
- Implementation: Added one Go executable with Windows/macOS/Linux native
  service commands, SQLCipher schema verification, lifecycle/heartbeat events,
  indexed bounded outbox batches, idempotent HTTP upload, capped retry,
  logout-triggered flush, graceful shutdown, protected-file secret provider,
  and a native Flutter logout bridge.

## 2026-08-10 — Activity Watch logout persistence

- Logout and service shutdown now drain all pending durable outbox batches,
  rather than uploading only the first batch.
- ERP logout finalizes the current session, uploads saved summaries, and
  immediately starts a new local session so collection continues until the
  agent/device is shut down.
- Files changed: `activity-watch-agent/`, Activity Watch service control,
  application logout flow, architecture decisions, specifications, testing,
  operations guide, documentation index, and changelog.
- Database/API impact: Reuses local Activity Watch schema version 1 and its
  `idx_sync_outbox_dispatch` index. Documents the future
  `POST /api/v1/activity-watch/batches` contract; no backend endpoint or server
  table was added.
- Security impact: Uses SQLCipher v4, raw 256-bit database key validation,
  protected machine secret files, HTTPS enforcement, device-scoped credentials,
  bounded logs, and no employee ERP-token retention.
- Tests added or updated: Go configuration, secret permissions, logout marker,
  worker lifecycle/logout behavior, HTTP outcomes, retry/backoff, encrypted
  database/header, wrong-key rejection, schema verification, and outbox
  transaction tests.
- Tests executed and results: `go test -count=1 ./...`, `go vet ./...`, and
  `go build ./cmd/activity-watch-agent` passed on macOS arm64 with Go 1.26.5.
  Scoped Flutter analysis passed, and all 39 Flutter tests passed.
- Documentation updated: Specifications, architecture, ADR-0004 through
  ADR-0006, testing, operations guide, README index, and changelog.
- Known limitations: Full foreground/idle/browser collectors, authenticated
  local helper IPC, machine credential installers/ACLs, actual native service
  installation tests, Flutter-to-Go database interoperability on every desktop
  OS, and the ERP ingestion endpoint remain pending. The pinned self-contained
  Go SQLCipher v4.4.2 driver requires dependency/security review before release.
- Follow-up work: Implement enrollment/device credentials and server ingestion,
  then add signed Windows, macOS, and Linux installers and native collectors.

## 2026-08-06 — Global code optimization and reuse skill

- Request: Apply suitable data structures and algorithms to every code change
  and reuse existing widgets when available, across projects.
- Specification: Engineering optimization and reuse policy in
  `docs/SPECIFICATIONS.md`.
- Implementation: Added the personal global `optimize-and-reuse-code` skill,
  enabled implicit invocation across codebases, and made its reuse and
  complexity review mandatory in this repository's instructions. The policy
  is not limited to Activity Watch or Flutter.
- Files changed: Project skill, `AGENTS.md`, specification, and changelog.
- Database/API impact: None.
- Security impact: None.
- Tests added or updated: None; this is an engineering workflow change.
- Tests executed and results: Skill structure and metadata validation.
- Documentation updated: Repository instructions, specification, and changelog.
- Known limitations: Complexity depends on known input bounds; performance
  claims still require project-specific measurement.
- Follow-up work: Apply the skill during future implementation and review work.

## 2026-08-06 — Activity Watch encrypted local persistence

- Request: Implement the approved cross-platform 10-table Activity Watch
  schema and add the attached persistent engineering documentation rules.
- Specification: `docs/SPECIFICATIONS.md` and
  `docs/ACTIVITY_WATCH_LOCAL_DATABASE_STRUCTURE.md`.
- Implementation: Added the SQLCipher database wrapper and version-1 schema,
  secure key store, AES-GCM/HMAC helper, path manager, lifecycle context, and
  opt-in public persistence exports.
- Files changed: Activity Watch core persistence, dependencies, tests,
  repository instructions, local skill, and durable documentation.
- Database/API impact: Adds a new local schema version 1; no ERP server API or
  MySQL change.
- Security impact: Adds SQLCipher, platform secure key storage, AES-256-GCM
  payload encryption, and HMAC identifiers. Database initialization remains
  opt-in and consent-gated.
- Tests added or updated: Schema and index inventory, SQLCipher verification,
  encrypted reopen, wrong-key rejection, keys, constraints, transactions,
  AES-GCM tamper detection, and HMAC behavior.
- Tests executed and results: `flutter test test/core/activity_watch` passed
  9 tests on macOS, and the complete `flutter test` suite passed all 39 tests.
  `flutter analyze` found no Activity Watch issues and one pre-existing
  unrelated unused-element warning in `lib/view/crm/crm_followups_page.dart`.
- Documentation updated: README index, schema, specification, architecture,
  decisions, testing, and changelog.
- Known limitations: Activity collection, enrollment, synchronization, browser
  integration, and native packaging verification outside macOS remain outside
  this change.
- Follow-up work: Add authorized Activity Watch runtime and platform adapters.
## 2026-08-20 — Confirm ERP logout before clearing the session

- Request: Show a confirmation dialog when the user logs out manually.
- Specification: Browser logout must not imply it can trigger the local Windows
  Activity Watch agent.
- Implementation: Added a cancelable shell-level logout confirmation that
  explains the browser/native-agent boundary before the existing logout flow.
- Files changed: `lib/components/adaptive_shell.dart`, `docs/SPECIFICATIONS.md`,
  `docs/TESTING.md`, `docs/CHANGELOG.md`.
- Database/API impact: None.
- Security impact: Does not expose credentials or add browser-to-agent access.
- Tests added or updated: Manual dialog acceptance criteria documented.
- Tests executed and results: Pending focused Flutter analysis.
- Known limitations: Browser logout still cannot directly execute a local
  Windows agent command.
## 2026-08-20 — Keep valid browser sessions through refresh

- Request: Keep the ERP login active until manual logout instead of returning
  to login on every browser refresh.
- Implementation: Bootstrap restores every valid stored session and the login
  page removes the obsolete remember-me control.
- Database/API impact: None.
- Security impact: Explicit logout, expiry, and server rejection continue to
  clear the stored session.
- Tests: Focused Dart analysis passed. The focused Flutter session-storage test
  returned no result from this environment.

## 2026-08-22 — Global StaffU-inspired theme foundation

- Request: Implement only the approved global theme foundation before any
  module-by-module redesign.
- Specification: Global StaffU-inspired theme foundation in
  `docs/SPECIFICATIONS.md`.
- Implementation: Reused `MaterialApp`, `AppTheme`, `AppThemeExtension`, and
  `AppUiConstants`; added semantic light/dark palettes, system brightness,
  bundled Nunito typography, status roles, and global Material component
  defaults. No business-module page was edited.
- Files changed: Theme files, app root, font assets/license, `pubspec.yaml`,
  focused tests, and durable frontend documentation.
- Database/API impact: None.
- Security impact: None; fonts are bundled locally and no runtime font request
  is introduced.
- Tests added or updated: Five global-theme contract tests.
- Tests executed and results: Focused analysis passed; focused theme tests
  passed 5/5; all 24 runnable tests outside the incomplete untracked
  `app_module_theme_test.dart` passed.
- Documentation updated: Specification, architecture, ADR-0018, testing,
  changelog, and documentation index.
- Known limitations: Existing module-local hardcoded colors are not yet fully
  dark-mode compatible. Full project analysis is blocked by a preserved,
  pre-existing untracked test for an absent `AppModuleTheme` implementation.
- Follow-up work: After separate approval, migrate and visually verify one
  business module at a time against the global foundation.

## 2026-08-22 — Shared bordered cards and module-list tables

- Request: Add visible card borders and update all shared module-list/table UI
  using StaffU's data-table page as the reference.
- Specification: Shared bordered cards and module-list tables in
  `docs/SPECIFICATIONS.md`.
- Implementation: Added semantic one-pixel borders, 12px card/panel radii,
  subtle shared depth, StaffU-inspired global DataTable defaults, bordered
  settings tiles, compact grouped pagination, and a reusable legacy card
  decoration. Settings, purchase, CRM filter, purchase register, and login
  history surfaces now consume the shared styling. Sales/purchase register
  tables and editable document line-item tables now share the same semantic
  header, border, alternating-row, hover, and selected states in light and dark
  themes. The responsive register mobile-card path also has a valid local
  Material ink surface.
- Files changed: Global constants/theme, shared section card, local/report
  pagination, shared settings/purchase list components, affected register
  wrappers, focused tests, and durable documentation.
- Database/API impact: None.
- Security impact: None.
- Tests added or updated: Theme/component tests now cover card border, table
  sizing/states, pagination boundaries, pagination interaction, shared register
  rows, and editable line-item surfaces.
- Tests executed and results: Focused analysis passed; 10/10 focused tests and
  all 29 runnable tests passed.
- Performance: Page-count calculation is O(1) time/O(1) space; visible page
  extraction remains O(k) for bounded page size k. Register and editable-line
  rendering remain O(n), with no per-row searches or module table copies.
- Known limitations: Authenticated cross-platform visual QA remains manual.
- Follow-up work: Continue module-specific content refinements only after
  separate approval; shared card/table styling is now global.

## 2026-08-22 — White light-theme application sidebar

- Request: Use a white application side menu in the light theme while keeping
  the established primary active colors.
- Specification: Light-theme application sidebar in `docs/SPECIFICATIONS.md`.
- Implementation: Updated the existing light desktop-drawer semantic tokens to
  a white surface with dark foreground and muted text. The shared
  `AdaptiveShell` now uses primary foreground and a subtle primary tint for
  active light-mode entries while preserving the existing dark-mode sidebar.
- Reuse/performance: No new menu component or module copy was added; the shared
  shell performs one O(1) brightness decision per build.
- Database/API/security impact: None.
- Tests: Focused analysis passed and all 8 global-theme tests passed.
- Known limitation: Authenticated desktop visual QA remains manual.

## 2026-08-22 — Dark-theme visual hierarchy refinement

- Request: Correct the dark theme because its current presentation was not
  visually clear in the supplied purchase-invoice screenshot.
- Specification: Dark-theme visual hierarchy refinement in
  `docs/SPECIFICATIONS.md`.
- Implementation: Refined only the shared dark semantic palette with a
  near-neutral scaffold, lighter blue-slate card, quieter fills, clearer table
  header/stripe/hover/selection layers, stronger dividers, and readable muted
  text. The light palette and primary `#4666E1` remain unchanged.
- Reuse/performance: Existing `AppTheme.dark()` and `AppThemeExtension` remain
  the only dark-style boundary. Palette creation stays O(1) time/O(1) space.
- Database/API/security impact: None.
- Tests: Focused analysis passed; all 11 focused theme/table tests passed,
  including distinct-layer, luminance, and contrast assertions.
- Known limitation: Authenticated visual QA across all legacy module-local
  hardcoded colors remains manual.
# 2026-08-26 — CRM lead completion after delivery or invoice

- CRM documentation now records that quotation/order creation keeps a linked
  lead In Progress and delivery/invoice completion displays Own.
- The existing typed server-status and module-refresh flow remains reused; no
  frontend API or database contract changed.
- Manual authenticated verification remains recommended for the end-to-end
  quotation → delivery/invoice workflow.
