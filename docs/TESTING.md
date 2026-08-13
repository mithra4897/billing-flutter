# Testing

## Activity Watch background-application process grid — 2026-08-13

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter test test/model/activity_watch_enrollment_test.dart`: passed.
- `flutter analyze lib/view/settings/activity_watch/activity_watch_setup_page.dart
  test/model/activity_watch_enrollment_test.dart`: passed with no issues.
- `git diff --check`: passed.
- Manual authenticated verification remains required to assess the three-card
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
