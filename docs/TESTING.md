# Testing

## Global status toast — 2026-08-25

- Focused `flutter analyze lib/main.dart lib/components/app_toast.dart` passed
  with no issues.
- Manual verification remains required for the visual placement and colors in
  an authenticated browser session.

## CRM Enquiries expected-value presentation — 2026-08-25

- The register and legacy read-only table configure the shared Expected Value
  display as centered, including its `-` zero/blank placeholder.
- `dart format` completed for the CRM Expected Value formatter, register page,
  and focused unit test.
- Focused `flutter analyze` completed with no issues.
- `flutter test test/controller/crm/crm_opportunities_controller_test.dart
  --no-pub` passed 3/3 tests for blank/zero placeholders, non-zero/legacy
  value preservation, and the blank editable-field variant.
- Authenticated visual QA remains recommended to confirm the wider Expected
  Value column remains distinct from Lead By at desktop and narrow widths.

## CRM inline filter bars — 2026-08-25

- Verify the Filter action on CRM Enquiries, Leads, and Opportunities toggles
  an inline filter bar instead of opening a dialog.
- Verify CRM Follow-ups hides its old date card until Filter is clicked, then
  shows From Date, To Date, and Clear controls. Verify either boundary can be
  empty and the selected range is inclusive.
- Verify search, date, lookup, and status changes update the visible rows, and
  Clear restores each page's existing default status scope.
- Verification performed: `dart format` completed and focused
  `flutter analyze` passed with no issues. The full `flutter test --no-pub`
  run is blocked by the repository's pre-existing missing
  `lib/app/theme/app_module_theme.dart` referenced by
  `test/app/theme/app_module_theme_test.dart`; authenticated visual QA remains
  recommended.

## CRM lead probability status

- Verify the Leads register shows a circular percentage indicator beside each
  lead's status.
- Verify explicit probabilities below 0 or above 100 render as 0% or 100% and
  do not affect the API payload.
- Verify leads without a probability use Draft 10%, In Progress 50%, Own 100%,
  or Lost 0%.
- Verify the indicator's semantic label includes the displayed percentage.

## Sales outstanding balance drill-down parity — 2026-08-24

- `dart format` completed for the shared sales dashboard helper, export, focused
  dashboard/register edits, and unit test.
- Focused Dart analysis of the dashboard helper, dashboard loader, invoice
  register, and test passed with no issues.
- `flutter test test/view/dashboard/sales_dashboard_support_test.dart
  --no-pub`: passed all 4 tests.
- Coverage verifies the overdue status preset, positive-balance/open-status
  boundary, null-balance handling without invoice-total fallback, exact parity
  between dashboard and drill-down sums, and the open/balance-desc route.
- Manual authenticated verification remains recommended against the reported
  company/FY dataset after refreshing both the Sales Dashboard and invoice
  register.

## CRM follow-up timeline presentation — 2026-08-24

- Browser inspection of the StaffU Activity Log reference confirmed the date
  filter card, grouped bordered sections, vertical rail and nodes, compact time
  labels, nested detail cards, status pills, and responsive content structure.
- `dart format` completed for the follow-ups page and focused widget test.
- Focused Dart analysis reports only the page's pre-existing unused
  `_buildGapList` warning; no new warning or information diagnostic is present.
- `flutter test test/view/crm/crm_followups_page_test.dart --no-pub`: passed 3
  tests covering populated timeline structure, rail continuity, record actions,
  exact-date filtering/clearing, and a 420px-wide layout without overflow.
- Authenticated manual visual QA against live CRM data remains recommended in
  both operating-system brightness modes.

## Bulk Attendance submit-only action — 2026-08-22

- Focused Flutter analysis passed for the Bulk Attendance page. Existing
  selection/model tests passed for the submitted employee/date payload.

## Monthly Attendance month boundary — 2026-08-21

- Focused Flutter analysis passed for the monthly attendance sheet model.
- The HR attendance model test verifies a June response with an incorrect
  `days_in_month: 31` still produces exactly 30 June days (5 tests passed).

## Leave Request approval controls — 2026-08-21

- Focused Flutter analysis covers the Leave Request controller and page.
- The complete Flutter suite is recorded after wiring the existing approval
  and rejection endpoints into the screen.

## Calculate leave balance at approval — 2026-08-21

- Backend HR PHPUnit coverage verifies that pending leave does not consume a
  company's available entitlement: 18 tests and 72 assertions passed.
- Focused Flutter analysis and the complete Flutter test suite are recorded
  after the request-status UI update.

## Leave Requests use the logged-in employee — 2026-08-21

- Focused Flutter analysis covers the Leave Request page and controller.
- Full Flutter suite is recorded after the implementation change.

## Company Settings tab rendering — 2026-08-21

- `flutter analyze` for the Company and Financial Year pages/controllers:
  passed with no issues.
- `flutter test`: passed (18 tests).
- `git diff --check`: passed.

## Monthly Attendance includes all active employees — 2026-08-21

- The Monthly Attendance route now requests the existing all-employee sheet
  mode and uses the same mode when saving records.
- Verification: focused Flutter analysis and the existing HR attendance model
  coverage; live authenticated employee-count verification remains manual.

## Bulk Attendance selected-employee submission — 2026-08-21

- Single-row selection and header select-all/clear behavior are covered by the
  monthly attendance selection helper tests.
- `flutter analyze` for the changed page, grid, helper, and test: passed.
- `flutter test test/view/hr/monthly_attendance_selection_test.dart
  test/model/hr_attendance_payroll_model_test.dart`: passed (6 tests).

## Activity Watch connection setup status — 2026-08-21

- Added model coverage for the pending, connected, and post-30-minute pairing
  statuses.
- Focused verification: `dart format`, `flutter analyze` for the changed model
  and setup page, and the Activity Watch enrollment model test.
- Live authenticated visual verification remains manual.

## One Activity Watch card per owner and day — 2026-08-20

- `flutter test test/model/activity_watch_daily_grouping_test.dart
  test/model/activity_watch_enrollment_test.dart`: passed (4 tests).
- Coverage verifies that repeated newest-first snapshots for one device/date
  retain only the newest totals, distinct devices for one owner/date combine
  their durations and application totals, and different owners/dates remain
  separate cards.
- `flutter analyze lib/model/activity_watch_enrollment.dart
  lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_daily_grouping_test.dart`: passed with no issues.
- `flutter test`: passed the complete current suite (15 tests).
- `flutter analyze`: changed files remain clean; the full project reports two
  unrelated existing warnings in `lib/app/constants/app_config.dart` and
  `lib/view/crm/crm_followups_page.dart`.
- Live authenticated visual verification remains manual.

## Fail-closed logout upload and explicit acknowledgement — 2026-08-20

- `go test ./...`: passed for every Activity Watch agent package.
- `go vet ./...`: passed.
- Regression coverage verifies that HTTP 200 HTML and a mismatched accepted
  count remain retryable and never mark outbox rows synced; an unvalidated HTTP
  409 is a permanent failure rather than a false acknowledgement.
- Runner coverage verifies acknowledgement after an empty queue, one exact
  full batch, and multiple exact full batches. Control coverage verifies the
  authenticated POST acknowledgement URL and combined-control delegation.
- `php -l app/Http/Controllers/ActivityWatchController.php`: passed.
- `php -l routes/activity_watch.php`: passed.
- `php -l app/Http/Controllers/Auth/AuthController.php`: passed.
- Rebuilt the ARM64 macOS package. `pkgutil --payload-files` listed the launcher,
  agent, and `Info.plist`; both executables are mode `755`.
- macOS Installer's read-only `-showChoicesXML` parse passed for the stable
  package name. Packaging and API-public copies are 7,974,306 bytes and share
  SHA-256 `7701e3a9d6b0d3b22acfcdf4dbafa549af65cca62f25ba5c155c6335a7ac6b8f`.
- Windows packaging was not rebuilt on macOS; rebuild and validate the Windows
  installer on the approved Windows/SQLCipher toolchain before publishing it.
- Live end-to-end logout verification remains a post-deployment check because
  the backend acknowledgement route must be deployed before the updated agent.

## macOS Activity Watch package repair — 2026-08-20

- Reproduced the screenshot failure against the published artifact:
  `file` identified `BillingActivityWatch-macos.pkg` as an ARM64 Mach-O
  executable and `pkgutil --payload-files` could not open it.
- The mislabeled published file's SHA-256 matched the current raw Go agent,
  confirming that the agent binary had been copied over the package filename.
- `go test ./...`: passed for all Activity Watch agent packages.
- `go vet ./...`: passed.
- Rebuilt the current ARM64 Go agent and AppKit pairing launcher, then created a
  fresh component package with `pkgbuild`.
- `pkgutil --payload-files`: passed and listed the app, launcher, Go agent, and
  `Info.plist`; both executables have mode `755`.
- `installer -pkg <published-package> -target / -showChoicesXML`: passed and
  returned the `BillingActivityWatch-macos` install choice without installing.
- Packaging and API-public copies are 7,972,209 bytes and share SHA-256
  `c1766b6eb7da024224e5039549e396cec4f5679f51ca5ffe378f2bf3eb3d1f65`.
- The development package remains unsigned. Signing, notarization, and a manual
  employee install/pairing check remain required for general distribution.

## Activity Watch installer download path — 2026-08-20

- Reproduced the production failure: the unprefixed installer URL returned a
  `200 text/html` response of 1,502 bytes instead of the installer.
- Corrected the configured installer base to the deployed API public path.
- `curl -I` verification passed for the corrected Windows URL with executable
  content type and a 10,769,920-byte payload, and for the corrected macOS URL
  with a 13,105,986-byte payload.

## Windows Activity Watch installer update repair — 2026-08-20

- `go test ./internal/collector`: passed.
- `packaging/windows/build-exe.ps1`: passed and created the repaired installer.
- The published installer is 21,472,256 bytes; source and API-download hashes
  match: `5378FF4E8E7B4137C6AC79C24CE0BCDDCA4D4DD06CAB81677D29EC6E4DDBEED2`.
- Manual verification remains: run the new installer over an existing running
  Activity Watch Windows service, approve UAC, and confirm the service returns
  to `running` without a copy failure.

## Windows Activity Watch installer build — 2026-08-19

- `go test ./internal/collector`: passed.
- `go vet ./internal/collector`: passed.
- `packaging/windows/build-exe.ps1`: passed and created the installer.
- `go test ./...`: all packages passed except the existing Windows pairing-file
  permission assertion, which expects Unix owner-only mode bits but observes
  Windows mode `-rw-rw-rw-`.
- The installer copied to the API public download path is 21,471,232 bytes;
  source and published SHA-256 hashes match:
  `275C3E4F7E5BCFE495D73B866872D6CBC604C0B34AE243AC4FCAD98CBC5F222D`.
- Authenticode verification reports `NotSigned`; code signing is still required
  before production employee distribution.

## Attendance month and year filtering — 2026-08-17

- Focused analysis passed for the monthly Attendance report.
- Manual visual check: changing Month or Year reloads that full calendar month
  and resets the horizontal scroll to its first day.
- Saved-cell interaction now opens the existing attendance editor directly;
  focused analysis verifies the editor call and refresh callback.

## Monthly manual attendance and employee display — 2026-08-17

- Backend focused PHPUnit passed: 12 tests and 56 assertions. Monthly coverage
  verifies that a system-linked employee is excluded and a non-system employee
  receives Present, Half day, and LOP rows. A legacy-schema case verifies the
  employee-code fallback when `users.employee_id` is absent. Draft attendance
  can be edited then submitted, and payroll processing is blocked for drafts.
- Full-sheet coverage verifies that an Activity Watch Present row can be
  submitted as a manual LOP override while retaining its original check-in.
- PHP syntax checks passed for the attendance controller, service, and HR route
  file; `git diff --check` passed in the backend repository.
- `dart format` passed for the changed model, service, screen, navigation,
  register, dialog, and focused test.
- Focused Flutter model tests passed. Coverage includes monthly sheet parsing,
  LOP status, and nested employee name/code retention.
- Focused Flutter analysis passed with no issues.
- Focused Flutter model tests passed after adding the system-access marker used
  by the all-employee Attendance sheet.
- Saved-record report refinement: focused analysis of the monthly sheet,
  Attendance wrapper, and shell route passed with no issues; focused HR model
  tests passed (4 tests). Missing dates are now presentation-only blanks, while
  saved cells retain their typed record for the single-record detail flow.
- Period-filter refinement: focused analysis passed after replacing the inline
  report toolbar with the shared HR filter dialog; focused HR model tests still
  passed (4 tests).
- Restored-filter/post-submit verification: focused Flutter analysis passed for
  Search, Employee, Status, Source, Month, and Year filters; focused HR model
  tests passed (4 tests). Backend coverage now verifies that a submitted bulk
  manual row is returned by the all-employee monthly report with its submitted
  state and manual source.
- Monthly-report visual verification: focused Flutter analysis passed with no
  issues after adding metadata columns, bordered grid, and client-side
  pagination; focused HR model tests passed (4 tests). The separate report bar
  and status legend were intentionally removed, with controls retained in page
  actions. Backend coverage verifies Department and Employee Status metadata
  in the monthly response.
- Report metadata coverage also verifies that an inactive employee whose
  employment overlaps the month remains available to the saved-record report.
- Agent-browser verification: the current local Flutter build served
  `/hr/attendance` successfully, then correctly redirected its isolated,
  unauthenticated browser session to login. Calendar rendering in an
  authenticated HR session remains manual.
- Attendance inline-filter verification: focused Flutter analysis passed after
  replacing the popup with the shared toggleable HR filter bar; focused
  attendance/payroll model tests passed (4 tests).
- HR inline-filter migration: focused analysis passed for Attendance, Leave
  Requests, Expense Claims, Payslips, the HR register, and shared filter
  helper; no live HR filter page uses the popup helper.
- Full-width HR filter layout: focused analysis passed after placing
  `SettingsWorkspace` filters above both the list and editor panels; focused
  attendance/payroll model tests passed (4 tests).
- Sales-style HR filter actions: focused analysis passed after removing Apply
  and reusing the shared Clear action; focused attendance/payroll model tests
  passed (4 tests).
- Payroll Run date filters: focused analysis passed after adding From date and
  To date to the shared Payroll Runs filter bar; focused attendance/payroll
  model tests passed (4 tests).
- Navigation coverage verifies Monthly Attendance is absent from the drawer
  while `/hr/monthly-attendance` remains accessible with `hr.create`.
- Authenticated browser verification remains manual because the isolated test
  browser did not have the user's ERP session.

## Activity Watch and manual attendance — 2026-08-17

- Backend focused PHPUnit passed: 6 tests and 22 assertions, including
  company-timezone deduplication, earliest check-in/latest check-out, manual
  precedence, payroll proration, and salary component reconciliation.
- PHP syntax checks passed for the changed Activity Watch controller,
  authentication service, and attendance service. PHP 8.5 emitted existing
  Lumen vendor nullable-parameter deprecation notices.
- `go test ./...` passed for the Activity Watch agent. New coverage simulates a
  failed request, service restart, retry with the original event time, and
  removal of the protected pending file after acceptance.
- Focused Flutter model tests passed (3 tests); focused attendance-register
  analysis passed with no issues.
- Manual integration check remains: pair an employee device, start the agent,
  verify one company-local `Activity Watch` attendance row, then create/edit a
  manual attendance row for an employee without a device.

## Processed payroll-run deletion control — 2026-08-14

- `dart format lib/view/hr/hr_workflow_dialogs.dart`: passed.
- `flutter analyze lib/view/hr/hr_workflow_dialogs.dart`: passed with no
  issues.
- Manual check required: open an unposted processed run, confirm the warning,
  then verify successful deletion refreshes the register. Voucher-linked and
  posted runs must remain rejected or unavailable.

## Login attendance and attendance-based payroll — 2026-08-14

- Backend focused PHPUnit: passed, 5 tests and 18 assertions. PHP 8.5 emitted
  existing Lumen vendor nullable-parameter deprecation notices.
- PHP syntax checks passed for changed services, controller, and models.
- `dart format` passed for changed Flutter files.
- `flutter test test/model/hr_attendance_payroll_model_test.dart`: passed,
  3 tests.
- Focused Flutter analysis: passed with no issues.
- Full `flutter test`: passed, 7 tests.
- Full `flutter analyze`: completed with two pre-existing unrelated warnings in
  `lib/app/constants/app_config.dart` and
  `lib/view/crm/crm_followups_page.dart`; changed HR files have no issues.
- Full backend PHPUnit ran 27 tests: 19 passed and 8 existing Auth feature tests
  errored because their SQLite fixtures omit `user_roles` and the test
  environment has no JWT secret. The focused payroll suite remains green and
  none of the full-suite errors reference changed attendance/payroll code.
- Production SQL-patch execution and authenticated login/process/post
  verification remain deployment-time checks against a database backup.

## Payroll process validation feedback — 2026-08-14

- `dart format lib/view/hr/hr_workflow_dialogs.dart`: passed.
- `flutter analyze lib/view/hr/hr_workflow_dialogs.dart`: passed with no
  issues.
- Manual check required: submit a draft payroll run with a known salary
  reconciliation mismatch, confirm the dialog stays open, and verify the API
  message is shown.

## Activity Watch super-admin disconnect access — 2026-08-14

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart
  lib/service/activity_watch/activity_watch_service.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `php -l app/Http/Controllers/ActivityWatchController.php`: passed in the
  backend repository.
- Manual authenticated verification remains required for regular-user 403
  responses and super-admin disconnect confirmation.

## Activity Watch macOS direct-pairing recovery — 2026-08-14

- Manual macOS verification: the installed agent successfully paired with a
  fresh downloaded bundle using the documented direct `pair` command.
- The command consumed the one-time bundle and returned a connected result.

## Activity Watch macOS packaged executable permissions — 2026-08-14

- Inspection of the installed development package found its launcher and bundled
  agent owned by `root` with mode `700`, preventing the enrolled macOS user
  from launching the application after installation.
- The documented app-bundle command now uses mode `755` for both executable
  files. Rebuilding and launch verification remain required.

## Activity Watch macOS pairing-launcher compile — 2026-08-14

- `swiftc -parse-as-library -framework AppKit
  packaging/macos/PairingLauncher.swift -o <temporary-output>`: passed on
  macOS; the temporary output was removed after verification.
- `git diff --check`: passed.

## Activity Watch release-operations documentation — 2026-08-14

- Static review confirms the guide uses the filenames resolved by the backend
  controller: `BillingActivityWatch-windows.exe` and
  `BillingActivityWatch-macos.pkg`.
- `git diff --check`: passed.
- Commands requiring Windows tooling, real Developer ID signing/notarization,
  or a production API deployment remain operator-run procedures and were not
  executed from this macOS development workspace.

## Activity Watch logout-only upload and macOS USB monitoring — 2026-08-14

- `gofmt -w internal/agent/runner.go internal/agent/runner_test.go
  internal/collector/usb.go internal/collector/collector_test.go
  internal/collector/windows_api_nonwindows.go
  cmd/activity-watch-agent/main.go`: passed.
- `go test ./...`: passed.
- `go vet ./...`: passed.
- `go build ./cmd/activity-watch-agent`: passed on macOS.
- Unit coverage confirms startup does not flush; ERP logout is the flush
  boundary. macOS USB parsing coverage verifies bounded `system_profiler`
  device metadata discovery. Real macOS USB hardware verification remains
  manual.

## Activity Watch browser-title tiles — 2026-08-14

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/components/erp_module_dashboard.dart
  lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required for desktop two-column
  layout, narrow stacking, and title truncation with real browser-title data.

## Activity Watch foldable detail sections — 2026-08-14

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/components/erp_module_dashboard.dart
  lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required to confirm that non-graph
  sections toggle independently while duration graphs remain visible.

## Activity Watch expanded-row indicator — 2026-08-14

- `dart format lib/components/erp_module_dashboard.dart
  lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/components/erp_module_dashboard.dart
  lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required to confirm the chevron
  direction and expanded-details association with real activity records.

## Activity Watch single-day graph line — 2026-08-14

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required for the single-day line
  placement and tooltip against real report data.

## Activity Watch details background restoration — 2026-08-14

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required to confirm the restored
  background separation around the details.

## Activity Watch USB detail layout — 2026-08-13

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required for USB-device card
  wrapping, long file-change labels, and the file-path hover tooltip.

## Activity Watch background-application process grid — 2026-08-13

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required to assess the four-card
  process grid, state-label truncation, and narrow-layout stacking.

## Activity Watch browser-title activity list — 2026-08-13

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required to assess title truncation
  and duration-badge alignment with real browser-title data.

## Activity Watch application report — 2026-08-13

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required to assess the three-card
  desktop grid and narrow-layout stacking with real application totals,
  including an `Unclassified` category label.

## Activity Watch locked and untracked graphs — 2026-08-13

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required to inspect the added graphs
  and hover tooltips with live report data at desktop and narrow widths.

## Activity Watch graph date-axis verification — 2026-08-13

- `dart format --output=none lib/view/settings/activity_watch/activity_watch_setup_page.dart`:
  passed.
- `dart analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart`:
  passed with no issues.
- `git diff --check`: passed.
- Manual browser verification remains required for label spacing with real
  report data.

## Activity Watch graph hover visibility verification — 2026-08-13

- `dart format --output=none lib/view/settings/activity_watch/activity_watch_setup_page.dart`:
  passed.
- `dart analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart`:
  passed with no issues.
- `git diff --check`: passed.
- Manual browser verification remains required for pointer hover placement at
  desktop and narrow widths.

## Activity Watch graph timelines and hover values â€” 2026-08-13

- `C:\flutter\bin\cache\dart-sdk\bin\dart.exe format
  lib\view\settings\activity_watch\activity_watch_setup_page.dart`: passed.
- `C:\flutter\bin\cache\dart-sdk\bin\dart.exe analyze
  lib\view\settings\activity_watch\activity_watch_setup_page.dart
  lib\components\erp_module_dashboard.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated browser verification remains required for pointer hover
  tooltips and duration timelines with real report data.

## Activity Watch mountain graph cards â€” 2026-08-13

- `C:\flutter\bin\cache\dart-sdk\bin\dart.exe format
  lib\view\settings\activity_watch\activity_watch_setup_page.dart`: passed.
- `C:\flutter\bin\cache\dart-sdk\bin\dart.exe analyze
  lib\view\settings\activity_watch\activity_watch_setup_page.dart
  lib\components\erp_module_dashboard.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated browser verification remains required to confirm the
  intended green/red curves and card wrapping with real report data.

## Activity Watch duration graphs and overview layout â€” 2026-08-13

- Static source verification confirms the Activity Watch details graph set
  includes total, keyboard, mouse, and browser durations, and the overview no
  longer creates an empty analytics column.
- `C:\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none
  lib\components\erp_module_dashboard.dart
  lib\view\settings\activity_watch\activity_watch_setup_page.dart`: passed.
- `C:\flutter\bin\cache\dart-sdk\bin\dart.exe analyze
  lib\components\erp_module_dashboard.dart
  lib\view\settings\activity_watch\activity_watch_setup_page.dart`: passed
  with no issues.
- Full `flutter analyze` exceeded the two-minute execution limit without
  returning diagnostics.
- Authenticated visual verification remains required for all graphs and narrow
  layout wrapping.

## Activity Watch detail keyboard graph â€” 2026-08-13

- Static source verification confirms the expanded Activity Watch card no
  longer renders the metric-tile grid and scopes graph aggregation to the
  selected device.
- `dart format`, focused Flutter tests, and `flutter analyze` could not run
  because neither `dart` nor `flutter` is available on the execution PATH.
- Authenticated visual verification remains required for the chart at desktop
  and narrow widths.

## Activity Watch active trend removal â€” 2026-08-13

- Static source verification confirmed Activity Watch no longer supplied a
  dashboard `trend`, and the page-only daily active-time metrics helper was
  removed.
- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart`,
  focused Activity Watch tests, and `flutter analyze` could not run because
  neither `dart` nor `flutter` is available on the execution PATH.
- Manual authenticated verification remains required to confirm the Activity
  Watch dashboard shows recent daily activity without an active trend graph.

## Payslip gross and net salary summary — 2026-08-13

- `dart format lib/model/printing/print_template_model.dart
  test/model/printing/payslip_template_compatibility_test.dart`: passed.
- `flutter test test/model/printing/payslip_template_compatibility_test.dart`:
  passed (5 tests), including missing-summary fallback and existing-summary
  no-duplication coverage.
- `flutter analyze`: completed with one pre-existing unrelated unused
  `_buildGapList` warning in `lib/view/crm/crm_followups_page.dart`; no issue
  was reported for the payslip template change.
- `php -l ../billing-api/app/Http/Controllers/Hr/PayslipController.php`:
  passed with no syntax errors after removing the calculated deduction row.
- Manual verification remains required for highly custom saved template
  placement in the authenticated print preview.

## Processed payroll-run deletion — 2026-08-13

- `dart format lib/view/hr/hr_workflow_dialogs.dart`: passed; no formatting
  changes were needed.
- `flutter analyze`: completed with one pre-existing unrelated unused
  `_buildGapList` warning in `lib/view/crm/crm_followups_page.dart`; no issue
  was reported for the payroll dialog.
- The change reuses the existing typed `HrService.deletePayrollRun` request and
  its existing dialog confirmation/delete-success flow; no API or model contract
  changed. Processed runs present the confirmed delete action and no Post
  action, so no additional unit test fixture was required.
- Manual authenticated verification remains required to confirm server-side
  voucher-linked and posted-run rejection messages, and the processed deletion
  confirmation, with production-like data.

## Apply salary-component order to all employees — 2026-08-11

- `flutter test test/controller/hr/employee_salary_component_order_test.dart`:
  passed (4 tests), including reorder preservation and invalid-index safety.
- `vendor/bin/phpunit tests/Unit/Hr/EmployeeSalaryComponentOrderServiceTest.php`:
  passed (1 test, 5 assertions). It covers case-insensitive matching,
  target-only rows, company isolation, and preservation of a generated
  payslip record.
- `flutter analyze`: completed with one pre-existing unrelated warning in
  `lib/view/crm/crm_followups_page.dart`; no issue was reported for this
  feature.

## Employee salary component grouped amounts — 2026-08-11

- `flutter test test/controller/hr/employee_salary_component_order_test.dart`:
  passed (3 tests), including grouped component and structure amount
  serialization.
- `flutter analyze`: completed with three existing unrelated warnings in
  `lib/app/constants/app_config.dart` and
  `lib/view/crm/crm_followups_page.dart`; no issue was reported for the
  salary-component change.

## Go Activity Watch service

Run from `billing-flutter/activity-watch-agent`:

```bash
go test ./...
go vet ./...
go build ./cmd/activity-watch-agent
```

Tests cover configuration validation, service worker lifecycle, logout flush,
batch limits/order, retry classification/backoff, HTTP success/retry/permanent
failure, cancellation, and transactional lifecycle-event queueing (including
the minimum privacy-safe payload and idempotency metadata). SQLCipher
integration requires CGO and is tested separately from store-independent unit
tests.

Completion coverage additionally verifies application classification,
inventory canonicalization/deduplication, activity-segment consolidation,
daily duration/application aggregation (including offline overlap and local
midnight clipping), encrypted metadata projection, authentication-failure
recovery, and retention that preserves unsynchronized outbox records.

Privacy-safe input/browser coverage verifies that an unchanged last-input
timestamp is not counted, a newer timestamp is counted without capturing its
source or value, input-state segments aggregate once, browser duration derives
from foreground executable classification, and older API/model payloads default
the additive counters to zero.

On 2026-08-07, the complete Go test suite, vet, and build passed; PHP Activity
Watch controller lint passed; all 52 Flutter tests passed. Flutter analysis
reported only the two pre-existing unrelated warnings in `app_config.dart` and
`crm_followups_page.dart`.

Self-service onboarding coverage verifies strict and bounded pairing bundles,
platform/HTTPS policy, locally generated credentials, protected atomic
configuration, fresh encrypted provisioning, consumed-bundle removal, pairing
model parsing, credential-free bundle serialization, and pending/connected
device states. Native installer signing and file-association behavior remain
target-OS release checks.

The macOS launcher was type-checked with Swift/AppKit and the package builder
produced an unsigned 7.5 MB test package. Signing, notarization, and installation
on a clean macOS account remain release checks.

Provisioning tests additionally verify fresh encrypted schema creation,
protected key permissions, generated-key reopen, control-directory creation,
and rejection of an existing database without modifying it.

The Go command tests also start and stop a provisioned foreground worker to
ensure cancellation completes within its configured shutdown deadline.

Windows release packaging is a manual target-OS check. The package script uses
the installed .NET Framework C# compiler to embed the Go agent and reviewed
installation script into one launcher EXE. A clean-user installation and file
association test remain required before production signing and distribution.
The installation script treats every `reg.exe` file-association write as a
checked operation and fails the launcher if Windows returns a nonzero code.

The pairing-result launcher must be checked on a clean Windows account: a valid
pairing file shows a connection dialog, and a missing agent or rejected pairing
shows a safe failure dialog without secrets.

Windows pairing verification must also deny Scheduled Task creation for a
standard user and confirm the ERP shows **Connected** while the launcher shows
the separate background-start warning.

For the 2026-08-12 pairing-result change, the Windows installer rebuilt with
UCRT64 GCC enabled. `go test ./...` passed in every package except the existing
Windows-only POSIX credential-mode assertion in `internal/pairing`; `go vet
./...` completed without output. Clean-user pairing verification remains
required.

Manual verification remains required for Windows service/login packaging,
macOS launchd, Linux user services, native OS permission prompts, actual OS
sleep/logout/shutdown, and production HTTPS deployment.

## `bill.local` HTTP development exception — 2026-08-10

- Focused `internal/config` and `internal/pairing` tests passed, including
  acceptance of `http://bill.local/...`, `http://192.168.31.83:8000/...`, and
  rejection of another remote HTTP hostname.
- `go test ./...` and `go vet ./...` passed on macOS.
- Cross-compiling the Windows agent on macOS could not proceed because the
  Windows CGO headers/toolchain are unavailable. Build and manually install the
  Windows release artifact on a Windows build machine before testing pairing.
- Pairing tests verify generated credentials are 64-character alphanumeric
  hexadecimal values accepted by the server's exchange validator.

## Section-card ink surface and constrained Devices card (2026-08-12)

- `git diff --check` validates the focused source and documentation changes.
- Flutter/Dart formatting, analysis, and widget tests require a Flutter SDK on
  the execution PATH; final responsive verification must confirm that the
  Devices card scrolls at constrained heights and ListTile ink remains visible.

## Activity Watch numeric-string response parsing (2026-08-12)

- Focused coverage: `flutter test test/model/activity_watch_enrollment_test.dart`.
- It verifies numeric-string employee IDs, duration fields, application totals,
  and pagination values parse without runtime type errors.

## Standard commands

Run from `billing-flutter`:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Party code synchronization

Focused command:

```bash
flutter test test/helper/party_code_helper_test.dart
```

Coverage includes global prefix lookup across party types, cross-type occupied
codes, Supplier and Customer prefix derivation, next-number selection,
mismatched saved-prefix detection, restoration of a selected party's saved
code when an edit returns to its original type, and rejection of stale async
refresh results. On 2026-08-06 the focused 9-test suite and the complete
48-test Flutter suite passed. `flutter analyze` completed with only the
pre-existing unrelated unused `_buildGapList` warning in
`lib/view/crm/crm_followups_page.dart`.

## Activity Watch persistence

Focused command:

```bash
flutter test test/core/activity_watch
```

Coverage includes:

- SQLCipher runtime verification;
- exact schema table and index inventory;
- correct-key reopen and wrong-key rejection;
- foreign-key and CHECK constraints;
- transaction commit and rollback;
- key generation and persistence with a fake secure store;
- AES-256-GCM authenticated payload encryption; and
- keyed HMAC stability and key separation.

## Manual/native verification still required

- Build and open the database on Windows, Linux, Android, and iOS hardware or
  supported virtual environments.
- Confirm platform secure-storage behavior and uninstall/reinstall semantics.
- Confirm release signing and SQLCipher artifact licensing.
- Test corrupted database and lost-key operational workflows.
- Verify database directory permissions on every supported OS.

Do not interpret a macOS unit-test pass as proof that every native platform has
been packaged successfully.

## Activity Watch completion verification — 2026-08-07

- `go test -count=1 ./...`: passed.
- `go vet ./...`: passed.
- `go build -o /private/tmp/activity-watch-agent-complete
  ./cmd/activity-watch-agent`: passed on macOS arm64.
- PHP lint for the Activity Watch controller, device middleware, and routes:
  passed.
- `flutter test`: all 50 tests passed.
- `flutter analyze`: completed with two unrelated existing warnings in
  `lib/app/constants/app_config.dart` and
  `lib/view/crm/crm_followups_page.dart`; no Activity Watch issue was reported.
- `git diff --check` passed in both Flutter and backend repositories.
- The additive MySQL patch was deliberately not applied automatically; live
  ingestion/report verification requires the operator's local test database.

## Activity Watch summary table verification — 2026-08-07

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart`:
  passed.
- `flutter test test/model/activity_watch_model_test.dart`: passed (4 tests).
- The compact application-table action is presentation-only; it reuses the
  tested parsed application totals and does not issue an additional request.
- `flutter analyze`: completed with the two existing unrelated warnings in
  `lib/app/constants/app_config.dart` and
  `lib/view/crm/crm_followups_page.dart`; no Activity Watch issue was reported.
- Desktop and narrow-width browser visual verification remains manual work.

## Activity Watch professional full-width report verification — 2026-08-10

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart`:
  completed with no further changes.
- `flutter test test/model/activity_watch_model_test.dart`: passed (4 tests).
- `flutter test`: passed all 52 tests.
- `flutter build web`: passed. The compiler also completed its WebAssembly dry
  run; it emitted the existing Cupertino-icons asset notice.
- `git diff --check` for the changed Activity Watch source and documentation:
  passed.
- `flutter analyze`: reports only the two pre-existing unrelated warnings in
  `lib/app/constants/app_config.dart` and
  `lib/view/crm/crm_followups_page.dart`; no Activity Watch issue was reported.
- The supplied desktop screenshot confirmed the former checkbox column and
  oversized selected row. Manual verification of the finished responsive
  layout should confirm compact 56px daily rows, no selection checkbox column,
  full-width report alignment, and horizontal scrolling at narrow widths.

## Activity Watch ERP dashboard reuse verification — 2026-08-10

- Added `activity_watch_dashboard_metrics_test.dart` with two tests covering
  multi-device totals, same-day aggregation, chronological trend ordering,
  case-insensitive unique application names, unique devices, and the empty
  report boundary.
- Focused dashboard/model test run: passed all 6 tests.
- `flutter test`: passed all 54 tests.
- `flutter build web`: passed, with the existing Cupertino-icons asset notice.
- `flutter analyze`: reports only the two pre-existing unrelated warnings in
  `lib/app/constants/app_config.dart` and
  `lib/view/crm/crm_followups_page.dart`; no Activity Watch issue was reported.
- Dashboard aggregation is `O(n + a + d log d)` time and `O(u + d)` space,
  where `n` is summaries, `a` is application totals, `d` is distinct dates,
  and `u` is unique devices/applications. It performs no additional API call.
- Final visual confirmation of dashboard wrapping, chart labels, and the
  detailed table remains manual in the authenticated browser session.
- Manual detail verification should also confirm the overview has no
  distribution or recent-activity list card, the Full details action scrolls to
  the report, and a selected row shows aggregate keyboard/mouse input alongside
  active, idle, state, and application totals.

## Activity Watch graph border verification — 2026-08-13

- `dart format --output=none lib/view/settings/activity_watch/activity_watch_setup_page.dart`:
  passed.
- `dart analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart`:
  passed with no issues.
- `git diff --check`: passed.
- Manual browser verification should confirm the graph cards have no outline at
  desktop and narrow widths.

## Activity Watch office monitoring detail — 2026-08-10

- Go coverage verifies schema-v3 migration/provisioning, encrypted browser-title
  aggregation, sampled keyboard/mouse totals, bounded process projection, and
  existing pairing/synchronization behavior.
- Focused Flutter coverage verifies schema version 3, typed browser/background
  summary data, legacy defaults, and dashboard parsing.
- Manual installed-agent verification remains required for macOS System Events
  permission and Windows interactive-session foreground/pointer APIs.

## Activity Watch setup cards and device pagination verification — 2026-08-10

- The setup layout uses a `LayoutBuilder` breakpoint: Connect a computer and
  Devices share an equal row below the dashboard on wide cards and stack on
  narrow cards.
- The Devices card renders five newest records per page through the shared
  `LocalPageNavigation`; successful refresh/enrollment/revoke loads reset to
  page one.
- `flutter test`: passed all 54 tests.
- `flutter build web`: passed, with the existing Cupertino-icons asset notice.
- `flutter analyze`: reports only the two pre-existing unrelated warnings in
  `lib/app/constants/app_config.dart` and
  `lib/view/crm/crm_followups_page.dart`.
- Manual browser verification remains for confirming the exact breakpoint and
  pagination interaction in the authenticated desktop and narrow layouts.
## Activity Watch USB audit checks

- `go test ./...` covers baseline behavior, added-file detection, hashed device
  identity, exact UTF-16LE PowerShell command round-tripping, encoded-command
  invocation, encrypted system-event persistence, daily aggregation,
  consent-v3 pairing enablement, and old-summary defaults.
- Verify on Windows with a newly paired consent-v3 device: connect a removable
  drive, wait one scan interval, add and delete a test file, then expand that
  day's Activity Watch row. Confirm port/device/storage/duration metadata and
  observed `added`/`deleted` rows appear, while no file content is present.
- Confirm a consent-v2 configuration keeps `usb_enabled` false.
- Large-drive verification must confirm the 5,000-file scan and 200-event daily
  caps set the truncation notice rather than growing the payload without bound.

## Activity Watch company-scope checks

- Sign in as two different super administrators with the same company context;
  both Activity Watch pages must list the same company devices and summaries.
- Switch a super administrator to another company and verify devices and
  summaries from the previous company are absent.
- Sign in as a non-super-admin user and verify the requests omit company scope
  and only that user's devices and summaries are returned.

## Windows USB collector command verification — 2026-08-12

- `go test -count=1 ./internal/collector ./internal/agent ./internal/config
  ./internal/store ./internal/syncer ./cmd/activity-watch-agent`: passed.
- `go test -count=1 ./...`: all packages passed except the existing Windows
  `internal/pairing` POSIX file-mode assertion (`-rw-rw-rw-` versus the Unix
  owner-only expectation); this is unrelated to USB command transport.
- The exact `windowsUSBScript` extracted from the Go source was transported via
  UTF-16LE `EncodedCommand` and executed by Windows PowerShell 5.1: exit code 0
  with valid JSON (`total_ports`, `used_ports`, `devices`, `drives`, `files`,
  and `files_truncated`). No removable drive was attached for this check.
- `packaging/windows/build-exe.ps1` rebuilt the API download artifact at
  `billing-api/public/downloads/activity-watch/BillingActivityWatch-windows.exe`.
- Installer SHA-256:
  `3FCF8A38E63EE85E6B7C42E20FF4BA087DE2D3664096F46DB0B7642922F2A8DE`.
- Manual verification with an attached removable drive is still required to
  confirm real device/file metadata reaches the ERP daily detail.

## Global StaffU-inspired theme foundation — 2026-08-22

- `dart format lib/app/theme/app_theme.dart
  lib/app/theme/app_theme_extension.dart lib/main.dart
  test/app/theme/app_theme_test.dart`: passed.
- Focused `flutter analyze` for the two theme files, app root, and new theme
  test: passed with no issues.
- `flutter test test/app/theme/app_theme_test.dart`: passed all 5 tests covering
  light/dark semantic palettes, WCAG 4.5:1 foreground contrast, component
  states, extension copy/interpolation, and app-root registration.
- All 24 runnable tests outside the pre-existing incomplete
  `app_module_theme_test.dart` passed.
- Full `flutter analyze` remains blocked by the untracked
  `test/app/theme/app_module_theme_test.dart`, which imports the absent
  `lib/app/theme/app_module_theme.dart`. It also reports the two existing
  warnings in `app_config.dart` and `crm_followups_page.dart`. The incomplete
  test was preserved and is outside this foundation.
- Manual authenticated visual QA remains required for legacy module pages with
  hardcoded colors, especially when the operating system selects dark mode.

## Shared bordered cards and module-list tables — 2026-08-22

- Audited the StaffU `data_table` page in both light and dark modes. Browser
  inspection confirmed a one-pixel card border, 12px card radius, subtle light
  shadow, 46px-class header row, approximately 60px body rows, 12px cell
  padding, header bands, row separators, status pills, and grouped pagination.
- `dart format` completed for all changed Dart files.
- Focused `flutter analyze` across the theme, shared card/list/pagination
  components, affected register surfaces, and tests: passed with no issues.
- `flutter test test/app/theme/app_theme_test.dart`: passed all 8 tests,
  including semantic card border, DataTable defaults, exact integer pagination
  boundaries, and compact pagination interaction.
- All 27 runnable tests outside the preserved incomplete
  `app_module_theme_test.dart` passed.
- Expanded focused analysis passed for the shared register renderer,
  `ErpLineItemTable`, semantic theme extension, and both focused test files.
- Focused theme/table tests passed 10/10. They verify register header and
  alternating-row semantics, editable line-item border/header/row semantics,
  and theme extension copy/interpolation.
- All 29 runnable tests outside the preserved incomplete
  `app_module_theme_test.dart` passed after adding the table-surface coverage.
- The responsive register test exposed and verified a fix for the mobile-card
  `InkWell` Material ancestor.
- Full project analysis remains subject to the previously documented missing
  `AppModuleTheme` implementation referenced by that untracked test.
- Manual authenticated visual QA remains required for representative desktop
  and narrow module lists and editable document lines in both brightness modes.

## Light-theme application sidebar — 2026-08-22

- Focused formatting completed for the global theme, shared adaptive shell,
  and theme contract test.
- Focused Flutter analysis passed with no issues.
- `flutter test test/app/theme/app_theme_test.dart`: passed all 8 tests.
- Coverage verifies the white light-mode desktop-drawer token, dark readable
  foreground/muted tokens, unchanged dark drawer tokens, and primary selected
  navigation semantics.
- Manual authenticated visual QA remains recommended for expanded and collapsed
  permanent menus at desktop widths.

## Dark-theme visual hierarchy refinement — 2026-08-22

- The supplied screenshot was treated as visual evidence. It confirmed dark
  mode was active but showed insufficient separation among canvas, card,
  header, and row layers.
- Focused formatting completed for the global theme and theme contract test.
- Focused Flutter analysis passed with no issues.
- `flutter test test/app/theme/app_theme_test.dart
  test/components/staffu_table_surfaces_test.dart`: passed all 11 tests.
- Automated coverage verifies six distinct dark semantic layers, card
  luminance above the scaffold, and at least 4.5:1 foreground contrast on card
  and alternating-row surfaces.
- Manual authenticated visual QA remains recommended for representative cards,
  tables, dialogs, and forms in dark mode.
## ERP logout confirmation — 2026-08-20

- The shell logout action must first show `Log out?`; `Cancel` keeps the ERP
  session intact and `Log out` continues the existing session-clear flow.
- The dialog explicitly distinguishes browser logout from the local native
  Activity Watch agent signal so it does not imply an immediate upload.
## Persistent browser login session — 2026-08-20

- A valid token now reaches the existing active-session bootstrap path without
  a remember-me gate; logout, expiry, and 401/403 handling are unchanged.
- Focused Dart analysis of the three changed Flutter files passed. The focused
  Flutter session-storage test command was started but returned no result from
  this environment, so its outcome is not claimed.

## Company leave policy and LOP — 2026-08-21

- `vendor/bin/phpunit tests/Unit/Hr/LoginAttendancePayrollServiceTest.php`:
  passed 15 tests and 64 assertions, including configurable CL/all-type entitlement and
  the company LOP multiplier payroll snapshot.
- Backend PHP syntax checks cover the policy model/migration, company service
  and controller, entitlement service, leave request service, and payroll
  service.
- Flutter model coverage verifies policy and multiplier parsing/serialization.
- Full `flutter test`: passed 18 tests.
- Focused Flutter analysis passed; full analysis reports only the two existing
  unrelated warnings in `app_config.dart` and `crm_followups_page.dart`.
- Full backend PHPUnit currently has six unrelated existing fixture/code
  errors: five access-scope tests omit `user_roles`, and one forgot-password
  test resolves the missing `App\Services\Auth\Log` class. All 31 remaining
  tests pass, including the 15 focused HR/payroll tests for this change.
- Manual deployment verification: migrate the API database, configure two
  companies with different CL entitlements and LOP multipliers, submit leave
  beyond each balance, and confirm the paid/LOP split and payroll deduction
  follow the selected company only.

## Leave availability wording and leave-type workflow — 2026-08-21

- Verify Company Settings shows “Leave availability schedule” with the two
  compact Yearly and Monthly choices and persists the existing API values.
- Verify Leave Requests contains no inline create control and Leave Types
  remains the catalog create/update/delete screen.
- `flutter analyze` on the three changed page/controller files: passed with no
  issues. Full `flutter test`: passed 18 tests.
- After simplifying the schedule choices, focused analysis passed and the
  company leave-policy model test passed (2 tests).
