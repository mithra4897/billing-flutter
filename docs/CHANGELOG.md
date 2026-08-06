# Changelog

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
