# Architecture decisions

## ADR-0009: Collect in the enrolled user's service context with safe OS adapters

- Date: 2026-08-07
- Status: Accepted
- Context: Windows Session 0 and system-level launch daemons cannot reliably
  access the active user's idle and foreground application state, while the
  feature must behave consistently on Windows, macOS, and Linux.
- Decision: Install Activity Watch as a current-user service and use one
  best-effort OS adapter selected at runtime. The adapter returns only idle
  duration, lock state, foreground executable/application name, and bounded
  process/service inventory. Missing tools or permissions return unknown data.
- Reason: User-service execution supplies the correct interactive security
  context without privileged UI inspection or a second IPC process.
- Alternatives considered: A system daemon plus authenticated session helper;
  Flutter-only timers; keyboard/mouse hooks; platform-specific binaries.
- Consequences: Monitoring begins at enrolled user login rather than before any
  user session exists. Linux foreground accuracy depends on the desktop session
  exposing standard X11/systemd tools; Wayland denial is reported as unknown.
- Related files: `activity-watch-agent/internal/collector/`,
  `activity-watch-agent/cmd/activity-watch-agent/main.go`.

## ADR-0010: Publish bounded summary metadata beside encrypted payloads

- Date: 2026-08-07
- Status: Accepted
- Context: The ERP cannot build useful reports from device-encrypted opaque
  payloads, but sending detailed desktop content would violate the privacy
  policy.
- Decision: Keep the authoritative local payload AES-GCM encrypted and send a
  separately validated metadata projection only for approved entity types.
  Daily-summary metadata contains durations and application executable/category
  totals; lifecycle metadata contains event type/time. The server stores this
  projection as JSON and never receives prohibited content.
- Reason: This supports operational reporting while retaining encrypted local
  detail and a narrow server data contract.
- Alternatives considered: Uploading plaintext detailed segments; sharing the
  device database key with the server; storing only opaque records with no
  report UI.
- Consequences: The server schema gains `metadata_json` and event-date indexes;
  older installations use the additive patch, not a framework migration.
- Related files: `activity-watch-agent/internal/store/`,
  `billing-api/app/Http/Controllers/ActivityWatchController.php`,
  `billing-api/install.sql`.

## ADR-0008: Transactionally queue every persisted machine lifecycle event

- Date: 2026-08-06
- Status: Accepted
- Context: Recording a `system_events` row separately from its `sync_outbox`
  row can permanently desynchronize local audit history from server ingestion
  after a process or power failure.
- Decision: `RecordSystemEvent` encrypts the policy-safe JSON payload with
  AES-GCM using the protected local service key, then creates the local
  lifecycle row, checksum, and pending outbox row in one SQLCipher transaction.
- Reason: A single local transaction provides all-or-nothing durability without
  a second worker or a repair scan. Dispatch stays indexed and bounded by the
  existing `sync_outbox` query.
- Alternatives considered: A periodic repair job; inserting the outbox row
  first; sending lifecycle events directly over HTTP.
- Consequences: A lifecycle write now has constant extra storage work, one
  extra insert, and one AES-GCM operation. The encrypted plaintext is limited
  to event type and UTC timestamp, never desktop-content data.
- Related files: `activity-watch-agent/internal/store/store.go`,
  `activity-watch-agent/internal/store/store_test.go`.

## ADR-0007: Provision new service storage through a no-overwrite command

- Date: 2026-08-06
- Status: Accepted
- Context: The Go service previously required a pre-created encrypted database
  and protected key, leaving a fresh authorized installation without a usable
  operator command.
- Decision: Add `activity-watch-agent provision --config <absolute-path>`.
  It creates a new version-1 SQLCipher database, a cryptographically random
  raw 256-bit key encoded in a mode-`0600` file, and the logout-control parent.
  It rejects any pre-existing database or key and publishes temporary files
  with no-replace hard links.
- Reason: A paired database/key must be created together without exposing or
  logging key material. Refusing replacement avoids irreversible loss of an
  existing encrypted database.
- Alternatives considered: Manual SQLCipher CLI setup; generating a new key
  beside an existing database; storing the key in JSON configuration.
- Consequences: Provisioning is intended only for a fresh authorized service
  installation. It is not a migration mechanism for an existing Flutter
  secure-storage database; cross-runtime key sharing remains a separate
  enrollment feature.
- Related files: `activity-watch-agent/internal/provision/`,
  `activity-watch-agent/internal/store/`, `docs/activity-watch-go-service.md`.

## ADR-0004: One Go binary with machine-service and session-helper roles

- Date: 2026-08-06
- Status: Accepted
- Context: Synchronization must survive user logout, but desktop operating
  systems isolate machine daemons from interactive foreground and idle APIs.
- Decision: Build one Go executable with a boot-time machine service for
  persistence/sync and a consent-gated per-user helper role for later native
  activity adapters.
- Reason: A single machine daemon cannot reliably collect interactive activity
  across Windows Session 0, macOS launchd, X11, and Wayland. One executable
  limits packaging complexity while retaining the two required security
  contexts.
- Alternatives considered: Flutter-only background execution; a user service
  that exits at logout; one privileged process that attempts UI inspection.
- Consequences: Packaging must register the machine role at boot and the helper
  at authorized login. Local authenticated IPC is required before interactive
  collectors are enabled.
- Related files: `activity-watch-agent/`, `docs/ARCHITECTURE.md`.

## ADR-0005: Keep synchronization independent from ERP user login

- Date: 2026-08-06
- Status: Accepted
- Context: A normal ERP access token is cleared at logout, while pending
  activity must continue uploading until shutdown.
- Decision: Use a revocable, device-scoped machine credential and idempotent
  outbox batches. Never copy or retain the employee's ERP login token.
- Reason: This preserves logout semantics and limits the background service to
  the Activity Watch ingestion contract.
- Alternatives considered: Retaining the user's bearer token; stopping sync at
  logout; anonymous uploads.
- Consequences: The backend must add device enrollment, revocation, and batch
  ingestion before production upload can be enabled. Until then the outbox is
  retained locally.
- Related files: `activity-watch-agent/internal/syncer/`,
  `docs/SPECIFICATIONS.md`.

## ADR-0006: Apply the raw key once through the SQLCipher v4 driver

- Date: 2026-08-06
- Status: Accepted
- Context: The pinned Go module is a SQLCipher v4 driver. Integration testing
  showed that applying its raw key through the DSN works with encrypted WAL,
  while issuing `cipher_compatibility` again after keying invalidates later
  writes in this binding.
- Decision: Apply the raw 256-bit key once in the connection DSN, verify a
  non-empty `cipher_version`, verify schema version/tables, and then configure
  WAL. Do not re-key or reapply compatibility pragmas on that connection.
- Reason: This ordering passes encrypted write/reopen, wrong-key, WAL, and
  outbox transaction tests without placing key material in SQL logs.
- Alternatives considered: Reapplying compatibility after keying; plaintext
  SQLite; an unverified dynamically linked driver.
- Consequences: SQLCipher dependency upgrades require interoperability tests
  against a Flutter-created database before release. Interactive helpers still
  submit through the service so one process owns business writes.
- Related files: `activity-watch-agent/internal/store/store.go`,
  `docs/ARCHITECTURE.md`.

## ADR-0001: Use a compact cross-platform SQLCipher schema

- Date: 2026-08-06
- Status: Accepted
- Context: Activity Watch needs offline, privacy-sensitive, transactional local
  storage across native Flutter platforms. An earlier 24-table design was too
  complex for the first release.
- Decision: Use the approved 10-table schema in
  `ACTIVITY_WATCH_LOCAL_DATABASE_STRUCTURE.md` with SQLCipher full-database
  encryption and authenticated encryption for sensitive payload columns.
- Reason: It preserves durable sessions, summaries, recovery, and outbox
  semantics while minimizing migration and repository complexity.
- Alternatives considered: Flutter Hive; plaintext SQLite with only column
  encryption; the 24-table normalized schema.
- Consequences: Some local details are encrypted JSON payloads and cannot be
  efficiently filtered with SQL. The ERP server remains the reporting store.
- Related files: `docs/ACTIVITY_WATCH_LOCAL_DATABASE_STRUCTURE.md`,
  `lib/core/activity_watch/database/`.

## ADR-0002: Bundle SQLCipher through sqlite3 build hooks

- Date: 2026-08-06
- Status: Accepted
- Context: The same native persistence layer must work on Android, iOS, macOS,
  Linux, and Windows. Mobile-only SQLCipher plugins do not satisfy that scope.
- Decision: Use `package:sqlite3` with its `source: sqlcipher` build-hook
  configuration, and verify `PRAGMA cipher_version` at runtime.
- Reason: The package provides one SQLite API and maintained native SQLCipher
  binaries for all required native Flutter targets.
- Alternatives considered: `sqflite_sqlcipher` (no Linux/Windows support), an
  unencrypted SQLite package, or separate database plugins per platform.
- Consequences: Native builds depend on the package's SQLCipher artifacts and
  their license. Web is intentionally unsupported by this subsystem.
- Related files: `pubspec.yaml`, `lib/core/activity_watch/database/`.

## ADR-0003: Keep Activity Watch initialization opt-in

- Date: 2026-08-06
- Status: Accepted
- Context: Opening or creating a monitoring database during ordinary ERP app
  startup would occur before enrollment and consent.
- Decision: Do not call Activity Watch persistence from `main.dart`. A future
  authorized enrollment/runtime component must initialize it explicitly.
- Reason: This enforces consent and prevents accidental collection behavior.
- Alternatives considered: Eager initialization at application startup.
- Consequences: Schema code is implemented and tested but remains dormant until
  the approved Activity Watch runtime is added.
- Related files: `lib/main.dart`, `lib/core/activity_watch/`.
