# Specifications

## Activity Watch self-service employee onboarding

- Date: 2026-08-07
- Status: Approved for implementation

### Objective

Replace developer-only device-ID, credential-file, JSON, and Terminal setup
with a one-time employee workflow suitable for Flutter Web and all supported
desktop operating systems.

### User workflow

1. An employee installs the organization-provided signed Activity Watch agent
   once on a Windows, macOS, or Linux computer.
2. In ERP Settings → Activity Watch, the employee enters a device label,
   accepts consent, and selects **Connect this computer**.
3. ERP creates a ten-minute, single-use pairing token and downloads a small
   `.billingawpair` file. The file contains only the API URL, platform, token,
   and format version; it never contains the permanent device credential.
4. Opening the pairing file invokes the installed agent. The agent exchanges
   the token once, provisions encrypted local storage when absent, writes the
   credential/configuration atomically with user-only permissions, and starts
   the user service.
5. The ERP page shows pending, connected, last-seen, revoked, or expired state.
   Normal ERP logins and computer restarts require no reconfiguration.

### API, storage, and security requirements

- Use the existing `activity_watch_devices` table; do not introduce a migration
  framework table or an additional Activity Watch pairing table.
- Store only a SHA-256 pairing-token hash, expiry, and paired timestamp. The raw
  token is returned once and expires after ten minutes.
- Pairing exchange is transactional and single-use. Concurrent or repeated
  exchanges fail without returning another credential.
- The device credential is generated locally by the agent during exchange,
  stored server-side only as a hash, and never included in the pairing file,
  Flutter state, server response, logs, or documentation. Retrying the same
  token with the same credential is idempotent until token expiry.
- The generated credential is a 64-character hexadecimal value, matching the
  server's alphanumeric validation. A leftover URL-safe Base64 candidate from
  an older development build is replaced before exchange.
- Production pairing URLs require HTTPS. Loopback HTTP remains allowed only for
  local development.
- During the approved internal development phase, the agent may also accept
  `http://bill.local/...` and `http://192.168.31.83:8000/...` for pairing and
  synchronization. No other remote HTTP hostname is permitted. This temporary
  exception must be removed or superseded by trusted internal HTTPS before
  wider deployment.
- Pairing bundles are bounded, versioned, strict-decoded, and removed by the
  handler after a successful setup.
- Existing direct enrollment remains available for native/developer
  compatibility but Flutter Web uses token pairing by default.

### Failure and recovery

- Missing agent/file association: keep the pending device visible and provide
  installer/open-file guidance; no activity collection begins.
- Expired or already-used token: ERP creates a new pairing session; old pending
  devices may be revoked by the owner.
- Provision/configuration failure: do not partially publish a credential file
  or configuration; rerunning the same bundle is allowed only until the server
  has consumed the token.
- Service installation/start failure: preserve the paired configuration and
  show an actionable local error so install/start can be retried without
  exposing the credential.

### Acceptance criteria

- A web employee never copies a device ID or permanent credential and never
  edits JSON.
- Backend tests cover expiry, one-time exchange, ownership/company scope, and
  token hashing; PHP syntax checks pass.
- Go tests cover strict bundle parsing, URL policy, exchange response handling,
  atomic protected writes, provisioning reuse, and failure preservation.
- Flutter model/service tests cover pairing responses and the web page downloads
  the versioned bundle using the existing shared file-download utility.
- Existing Activity Watch collection, reports, direct enrollment, and logout
  synchronization remain compatible.

## Activity Watch cross-platform completion

- Date: 2026-08-07
- Status: Approved for implementation

### Objective

Complete the consent-gated Windows, macOS, and Linux Activity Watch workflow so
an enrolled desktop can sample privacy-safe user presence and foreground
application identity, retain consolidated encrypted local records, publish
daily summaries through the durable outbox, and expose device/report status in
the ERP.

### Functional requirements

1. Collection starts only when synchronization has an enrolled device
   credential and `collection.disabled` is not set.
2. The collector samples at a configurable interval (default 15 seconds), uses
   only OS idle duration and foreground executable/application identity, and
   classifies active, idle, locked, or unknown state. Unsupported or denied OS
   APIs produce `unknown`; they must not crash the service.
3. State and application samples are consolidated into local segments. An
   unchanged state/application updates the current segment in constant time;
   a change closes the current segment and opens one new segment.
4. Process inventory is sampled every 5 minutes and service inventory every 15
   minutes by default. Canonically sorted names are hashed, and an unchanged
   snapshot is not stored again.
5. Daily summaries contain active/idle/locked/unknown totals, overlapping
   offline duration, and application duration grouped by executable
   name/category. Segments spanning local midnight are clipped to each local
   date. Summaries are regenerated on a separate bounded interval (default 15
   minutes) and immediately before logout and shutdown synchronization; network
   retry frequency cannot create extra summary revisions.
6. Local synchronized detail older than 90 days is deleted in bounded indexed
   operations. Pending/retry/permanently-failed records are retained for human
   resolution and are never silently discarded.
7. Server ingestion validates all base64 fields, checks SHA-256 ciphertext
   checksums, accepts only approved entity/operation values, stores a bounded
   privacy-safe metadata projection for reports, and is idempotent.
8. A new credential for an existing device identity may recover locally queued
   authentication failures; unrelated permanent validation failures remain
   failed.
9. Authenticated ERP users can list their own enrolled devices, summaries, and
   revoke a device. Users with `hr.view` may view devices/summaries within their
   authorized company context. Reporting is date-bounded and paginated.
10. The Flutter Activity Watch page reuses the existing API client, section
    cards, form controls, and shell. It shows enrollment, device state,
    revocation, filters, and daily totals without exposing credentials after
    the one-time enrollment response.

### Security and privacy

- Never collect keystrokes, clipboard contents, screenshots, pointer
  coordinates, command-line arguments, window/tab titles, URLs, or page/form
  content.
- Foreground collection is limited to process/executable name and a local
  category. Inventory is limited to process/service names and states.
- Detailed local payloads remain AES-GCM encrypted and the database remains
  SQLCipher encrypted. Only an explicit, bounded summary metadata projection is
  sent for server reporting over HTTPS (loopback HTTP is development-only).
- Collection errors log operation names only, never observed content or secret
  material.

### Acceptance criteria

- Go unit/integration tests cover sample consolidation, idle thresholds,
  inventory deduplication, local-midnight summary aggregation, retention,
  credential recovery, and existing synchronization behavior.
- Go formatting, tests, vet, and build pass on the available host; OS adapters
  fail safely when permissions/tools are unavailable.
- PHP syntax checks pass and Activity Watch routes are authenticated and
  company/user scoped.
- Flutter formatting, analysis, and focused tests pass where the SDK is
  available.
- `install.sql` remains the fresh-install source of truth; the existing
  additive Activity Watch patch is updated for already-created test/server
  tables. No framework migration table is introduced.

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
- Status: Implemented; collection/reporting details are governed by the
  cross-platform completion specification above

### Problem and objective

Activity Watch must start with a desktop computer, store authorized monitoring
events locally while offline, and continue uploading queued records after the
ERP user logs out until the operating system shuts the service down.

Run the Go executable in the enrolled user's service/login context. This keeps
encrypted persistence and synchronization independent from Flutter while also
giving privacy-safe OS adapters access to that user's idle and foreground
application state. System-service contexts such as Windows Session 0 are not
used for interactive collection.

### In scope

- Windows, macOS, and Linux desktop service lifecycle.
- Non-destructive `provision` command that creates a new encrypted local
  database/key pair and its control directory from a valid configuration.
- Install, uninstall, start, stop, restart, status, and foreground-run commands.
- Enrolled-user service execution from OS login until logout/shutdown.
- SQLCipher database opening and approved schema verification.
- Machine/session lifecycle, idle/application sampling, and bounded health
  events.
- Bounded `sync_outbox` batch selection with idempotent HTTP upload.
- Exponential retry with a maximum delay and server `Retry-After` support.
- Logout-triggered sync flush while the machine service remains alive.
- Graceful shutdown with a bounded final flush.
- Interfaces for later native session collectors and secure secret providers.
- Unit tests with in-memory fakes and HTTP test servers.

### Out of scope

- Mobile background execution on Android or iOS.
- Browser extension/native messaging.
- Raw browser tab capture, window-title capture, or Wayland permission bypasses.
- Installing the service without administrator approval.
- ERP-side reporting and retention jobs beyond raw idempotent ingestion.
- Storing user passwords or reusing a logged-in user's ERP access token.

### Required behavior

1. Installation must not begin collection. Enrollment, device authorization,
   active consent, and machine credentials are prerequisites.
2. The user service starts at operating-system login and runs independently of
   the Flutter process for the remainder of that interactive session.
3. The service records only policy-approved system lifecycle/health events when
   there is no authorized interactive helper. Each accepted lifecycle event and
   its AES-GCM-encrypted opaque outbox record must commit in one SQLCipher
   transaction, so a crash cannot leave an event recorded without a
   corresponding upload item (or the reverse).
4. Native Flutter logout finalizes user activity collection, regenerates the
   daily summary, and requests an immediate outbox flush.
5. Pending sync continues until success, service shutdown, permanent rejection,
   or policy/device revocation.
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

- The enrolled user service owns the database/key lifecycle for its session.
- SQLCipher compatibility 4 and a raw 256-bit key are required.
- Secrets are injected through a provider interface. Production packaging must
  use a machine-scoped credential/ACL implementation for each OS.
- The service never captures keystrokes, clipboard data, screenshots, pointer
  coordinates, full URLs, form/page content, or command-line arguments.
- All collectors are consent- and capability-gated and return unknown when a
  platform API or permission is unavailable.

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
# Privacy-safe input and browser-category duration

Status: Implementing (2026-08-07)

Objective: Report useful keyboard/mouse interaction and browser-use duration
without capturing employee content.

Requirements:

- The desktop agent records whether any keyboard or pointer input occurred
  between bounded activity samples. Keyboard keys, click targets, button values,
  and pointer coordinates are never stored.
- Daily summaries expose `input_seconds`, an approximation consisting of sample
  intervals in which input was detected, and `browser_seconds`, the duration for
  which a recognized browser was the foreground application.
- Browser reporting is category-only. Raw tab/window titles, domains, URLs,
  private/incognito activity, page content, and form content remain excluded.
- Existing version-1 encrypted local databases are upgraded in place by adding
  the non-content `input_detected` flag; no migration-history table is created.
- Older agents remain API-compatible; omitted new summary fields default to zero.

Acceptance criteria:

- Input state changes split local activity segments and aggregate without
  double counting.
- Browser time is calculated from existing foreground application segments.
- API validation accepts bounded new counters and old summaries.
- ERP daily summaries display input and browser durations.
- Tests confirm aggregation and backward-compatible parsing.

# Activity Watch concise screen

Status: Implementing (2026-08-07)

Objective: Make the Activity Watch setup and report page understandable at a
glance without removing consent, pairing, device state, or activity metrics.

Requirements:

- Use the existing Activity Watch cards, fields, and summary data.
- Replace explanatory paragraphs and low-value labels with concise titles and
  grouped primary metrics.
- Keep consent wording explicit and retain the actionable pairing expiry,
  device connection state, refresh, revoke, date filters, and application
  totals.
- Keep every reported duration and application total available in the daily
  summary table.

Acceptance criteria:

- The first view has one clear connect action and concise privacy wording.
- Device rows show label and connection state without duplicated platform and
  timestamp labels.
- Summary rows show active, idle, and browser duration first; expanded details
  retain keyboard/mouse, lock, offline, unknown, and application information.

## Activity Watch summary table

Status: Implemented (2026-08-10)

The Activity report reuses `ErpModuleDashboard` to present KPI cards, an active
time trend, recent daily activity, and summary highlights from the already-
loaded report rows. The separate distribution card and duplicate bottom table
are omitted. Selecting a recent activity record expands inline with all daily
metrics and classified application totals. Input is an aggregate
keyboard/mouse duration; raw input and background-process data are not part of
the API contract. No extra API request is introduced; date filtering,
loading/error/empty behaviour, the API contract, and privacy restrictions are
unchanged.

Super admins also receive an employee filter on Recent daily activity. The
filter uses employee identity returned with each summary, while the API remains
the source of truth for non-super-admin visibility.

The setup area places the Connect a computer and Devices cards side by side on
wide screens and stacks them on narrow screens below the Activity dashboard.
Devices are displayed newest first, five per local page, with older records
available through pagination; refresh, enrollment, and revoke actions reset the
device page to the newest records.
