# Specifications

## Activity Watch privacy-safe enrollment and ingestion MVP

- Date: 2026-08-06
- Status: Approved for implementation

### Objective

Complete the consent-gated Activity Watch path from an ERP user enrolling a
desktop device through the local Go service retaining an offline queue and the
ERP receiving idempotent device batches.

### Data and access rules

- Collect only active/idle/locked durations, timestamped lifecycle state, and
  application executable name/category. Browser collection, when enabled by a
  later native adapter, is domain/category only.
- Never collect keystrokes, clipboard contents, screenshots, pointer
  coordinates, window or tab titles, full URLs, page/form content, or process
  command-line arguments.
- Enrollment requires an authenticated ERP user, explicit consent, a device
  label/platform, and a consent policy version.
- Device credentials are random, device-scoped, stored server-side only as a
  hash, returned once at enrollment, and invalid after revocation.
- The service uses the credential only for `POST /api/v1/activity-watch/batches`.
  It never retains the employee's ERP JWT after logout.
- HR managers (the existing `hr.approve` scope) and super administrators may
  view organization records; regular employees may view only their own device
  status. Server data is retained for 90 days, then deleted.

### API and persistence requirements

- `POST /api/v1/activity-watch/enroll` creates/replaces an active device
  credential for the authenticated user after explicit consent.
- `POST /api/v1/activity-watch/batches` authenticates a device credential and
  accepts at most 500 ordered outbox records. Device/idempotency keys make a
  retried batch safe.
- Server ingestion stores opaque encrypted payload fields and metadata only;
  it does not attempt to decrypt a device-local SQLCipher/AES payload.
- Revocation disables future batches immediately. Retention cleanup removes
  records and batch receipts older than 90 days.

### Acceptance criteria

- Missing consent, invalid device credential, mismatched device header, an
  oversized batch, or malformed item is rejected without partial writes.
- Retried batch/idempotency keys do not create duplicate stored events.
- Credentials, encrypted payload contents, and database keys never appear in
  API responses or logs.
- Flutter exposes an explicit consent/status path before configuring a native
  service.

## Activity Watch Go desktop service

- Date: 2026-08-06
- Status: Service foundation and server ingestion implemented; native collectors
  pending

### Problem and objective

Activity Watch must start with a desktop computer, store authorized monitoring
events locally while offline, and continue uploading queued records after the
ERP user logs out until the operating system shuts the service down.

Implement the boot-time machine-service role now and reserve the same Go
executable for a later interactive session-helper role:

- a machine service that starts at boot, owns encrypted persistence, and keeps
  synchronization running; and
- a future per-user session helper that will start only after enrollment and
  consent and supply user-session activity to the machine service.

The two roles are necessary because Windows Session 0, macOS launch daemons,
and Linux graphical sessions do not allow a machine daemon to reliably inspect
the active user's foreground UI directly.

### In scope

- Windows, macOS, and Linux desktop service lifecycle.
- Non-destructive `provision` command that creates a new encrypted local
  database/key pair and its control directory from a valid configuration.
- Install, uninstall, start, stop, restart, status, and foreground-run commands.
- Boot-time machine service execution until OS shutdown.
- SQLCipher database opening and approved schema verification.
- Machine lifecycle and bounded health events in `system_events`.
- Bounded `sync_outbox` batch selection with idempotent HTTP upload.
- Exponential retry with a maximum delay and server `Retry-After` support.
- Logout-triggered sync flush while the machine service remains alive.
- Graceful shutdown with a bounded final flush.
- Interfaces for later native session collectors and secure secret providers.
- Unit tests with in-memory fakes and HTTP test servers.

### Out of scope

- Mobile background execution on Android or iOS.
- Browser extension/native messaging.
- Full Windows, macOS, X11, and Wayland foreground/idle adapters in this phase.
- Installing the service without administrator approval.
- ERP-side reporting and retention jobs beyond raw idempotent ingestion.
- Storing user passwords or reusing a logged-in user's ERP access token.

### Required behavior

1. Installation must not begin collection. Enrollment, device authorization,
   active consent, and machine credentials are prerequisites.
2. The machine service starts at operating-system boot and runs independently
   of the Flutter process and interactive login session.
3. The service records only policy-approved system lifecycle/health events when
   there is no authorized interactive helper. Each accepted lifecycle event and
   its AES-GCM-encrypted opaque outbox record must commit in one SQLCipher
   transaction, so a crash cannot leave an event recorded without a
   corresponding upload item (or the reverse).
4. Native Flutter logout requests an immediate outbox flush. When the future
   session helper is implemented, logout must also stop its user activity
   collection.
5. Logout must not stop the machine service. Pending sync continues until
   success, shutdown, permanent rejection, or policy/device revocation.
6. Shutdown cancels collection, closes open work, attempts a bounded final
   upload, and closes SQLCipher.
7. Upload batches are ordered by next-attempt time and creation time and are
   limited by configured batch size. Selection uses the approved dispatch
   index, making each batch `O(B)` after indexed lookup where `B` is batch size.
8. HTTP 2xx acknowledges the batch. Authentication/authorization rejection is
   permanent until re-enrollment. Timeouts, network errors, 408, 429, and 5xx
   use bounded exponential retry.
9. Logs must never contain database keys, device credentials, decrypted
   payloads, window titles, URLs, or personal activity content.
10. A plaintext SQLite runtime, missing key, wrong key, unsupported schema,
    absent consent, or invalid configuration fails closed.
11. `provision` must create the exact approved schema version, a cryptographically
    random raw 256-bit key encoded in a mode-`0600` file, and the configured
    control-directory parent. It must refuse to overwrite either an existing
    database or an existing key file.
12. If provisioning cannot finish, it must remove only temporary artifacts and
    artifacts it created during that same invocation; it must never modify an
    existing configured path.

### Configuration and API contract

Non-secret configuration defines database path, sync URL, device identifier,
intervals, batch size, and shutdown timeout. Database and device credentials
come from a machine secret provider, not the JSON configuration file.

For an authorized fresh installation, run `activity-watch-agent provision`
before `run` or native service installation. It creates a new independent
machine database/key pair. It must not be used to replace an existing
Flutter-managed database because that would create a different key.

The implemented endpoint is `POST /api/v1/activity-watch/batches` with:

- a device-scoped bearer credential;
- `X-Device-Id` and `Idempotency-Key` headers; and
- a JSON body containing an ordered batch of opaque encrypted outbox payloads.

When sync is disabled or the endpoint is unavailable, the service retains
pending records without data loss for a later retry.

### Security and privacy

- The machine service owns the database/key lifecycle required after logout.
- SQLCipher compatibility 4 and a raw 256-bit key are required.
- Secrets are injected through a provider interface. Production packaging must
  use a machine-scoped credential/ACL implementation for each OS.
- The service never captures keystrokes, clipboard data, screenshots, pointer
  coordinates, full URLs, form/page content, or command-line arguments.
- All collectors remain consent- and capability-gated.

### Acceptance criteria and tests

- Service commands are wired through the native service manager abstraction.
- Native Flutter logout notifies a configured service, while web and
  non-enrolled installations remain safe no-ops.
- The worker starts collector/sync loops and stops them with bounded cleanup.
- Logout stops session collection but triggers synchronization without stopping
  the machine worker.
- Outbox upload handles success, retryable failure, permanent rejection, batch
  limits, and cancellation.
- Retry delay is capped and deterministic under injected randomness.
- Configuration rejects unsafe or missing required values.
- Provisioning creates an encrypted database that passes the store's schema
  verification and rejects existing database/key paths without modifying them.
- SQLCipher runtime and approved schema are verified before writes.
- `go test ./...`, `go vet ./...`, and `go build ./cmd/activity-watch-agent`
  pass where a Go/CGO toolchain is available.

## Engineering optimization and reuse policy

- Date: 2026-08-06
- Status: Active

Every implementation, fix, review, and refactor must search for reusable
project components before adding an equivalent widget, helper, service, model,
or utility. Existing abstractions should be reused or compatibly extended only
when their responsibility and contract match; otherwise the reason for a new
abstraction must be recorded.

Non-trivial logic must choose algorithms and data structures from real access
patterns and expected input sizes. Implementations must avoid accidental
quadratic work, repeated scans, unnecessary sorting or copying, and unbounded
data loading. Performance claims require measurement. Optimization must not
reduce correctness, accessibility, maintainability, security, or readability.

Acceptance criteria:

- Repository reuse search is completed before new shared UI or utility code.
- New abstractions have a distinct responsibility or documented justification.
- Non-trivial performance-sensitive logic records meaningful time/space
  complexity and relevant validation.
- No benchmark or optimization claim is reported without execution evidence.

## Activity Watch encrypted local persistence

- Date: 2026-08-06
- Status: Implemented

### Problem

The cross-platform Activity Watch agent needs durable offline storage for
sessions, consolidated activity, application/browser observations, inventory,
system events, summaries, and synchronization. The data is privacy-sensitive
and must remain encrypted at rest.

### Objective

Implement the approved 10-table SQLCipher schema as an opt-in Flutter
persistence foundation with secure key management, authenticated payload
encryption, schema versioning, foreign keys, transactions, and automated tests.

### In scope

- Native Android, iOS, macOS, Linux, and Windows database support.
- SQLCipher full-database encryption with a verified cipher runtime.
- Platform secure storage for database, payload, and HMAC keys.
- AES-256-GCM helpers for sensitive payload columns.
- The 10 approved tables and 11 indexes.
- Schema version 1 creation and future migration boundary.
- Transaction API and fail-closed database opening.
- Tests for schema, constraints, encryption, reopen, and rollback.

### Out of scope

- Activity collection and OS platform adapters.
- Browser extensions or native messaging.
- Enrollment UI, consent UI, and automatic startup.
- ERP server tables or synchronization endpoints.
- Web persistence; Activity Watch is a native-agent facility.
- Production key recovery or device migration.

### Requirements

1. Do not initialize the database from normal Flutter startup before consent.
2. Generate three independent 256-bit keys: SQLCipher, payload AES-GCM, and
   identifier HMAC.
3. Store keys only through the platform secure credential provider.
4. Verify `PRAGMA cipher_version` before creating any schema.
5. Apply the encryption key before all other database reads.
6. Enable foreign keys, secure deletion, full synchronous writes, WAL where
   supported, and a bounded busy timeout.
7. Create exactly the approved 10 application tables and 11 indexes.
8. Reject databases newer than the supported schema version.
9. Run schema creation and migrations transactionally.
10. Roll back caller transactions when an operation throws.
11. Never log keys or decrypted sensitive payloads.

### Inputs and outputs

- Input: native database path and key material, normally obtained through the
  database manager.
- Output: an open `ActivityWatchDatabaseContext` containing an encrypted
  database connection and in-memory key material for authorized runtime use.
- Failure: typed initialization exception without secret values.

### Validation and edge cases

- Keys must be exactly 32 bytes after decoding.
- Missing or unavailable secure storage prevents initialization.
- A plaintext SQLite runtime is rejected even if it accepts `PRAGMA key`.
- A wrong database key must fail before migrations run.
- Foreign-key and CHECK constraint violations must surface to the caller.
- Empty/invalid secure-storage values are treated as corruption, not silently
  reused.
- Web initialization throws `UnsupportedError`.

### Security and privacy

- SQLCipher encrypts the complete database.
- Sensitive BLOB payloads use independent AES-256-GCM encryption.
- Identifier hashing uses independent HMAC-SHA-256 key material.
- In-memory key buffers are cleared when the context is disposed, subject to
  Dart runtime limitations.
- Tests must not contain production keys or personal activity data.

### Acceptance criteria

- Schema exposes exactly 10 application tables and the documented indexes.
- SQLCipher runtime verification succeeds in the native test environment.
- A database can be closed and reopened with the correct key.
- Opening with the wrong key fails.
- Foreign keys and CHECK constraints reject invalid rows.
- A failed transaction leaves no partial records.
- Payload encryption round-trips and detects tampering.
- Formatting, analysis, and focused tests pass.
- Documentation and changelog match the implementation.

### Required tests

- Schema table/index inventory.
- SQLCipher availability and encrypted file reopen.
- Wrong-key failure.
- Foreign-key enforcement.
- Platform and state CHECK constraints.
- Transaction commit and rollback.
- Key generation and secure-storage persistence through a fake provider.
- AES-GCM round trip and tamper rejection.
- HMAC stability and key separation.

## Party code synchronization when party type changes

The approved requirements, edge cases, compatibility constraints, acceptance
criteria, and verification plan are maintained in
[`party-code-type-sync.md`](party-code-type-sync.md).
