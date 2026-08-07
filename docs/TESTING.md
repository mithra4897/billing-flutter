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
