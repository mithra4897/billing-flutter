# Testing

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
