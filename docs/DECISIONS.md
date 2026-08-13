# Architecture decisions

## ADR-0018: Encode all Windows collector PowerShell commands

- Date: 2026-08-12
- Status: Superseded in part by ADR-0019
- Context: The scheduled Windows agent reported exit status 1 for foreground
  sampling and process inventory. Raw `-Command` arguments can be changed by
  Windows argument reconstruction before PowerShell parses embedded quotes.
- Decision: Reuse the USB collector's UTF-16LE `EncodedCommand` helper for all
  Windows activity, lock, foreground, pointer, process, and service commands.
- Reason: One existing, tested command transport removes inconsistent quoting
  behavior without widening collection scope.
- Alternatives considered: Shell quoting variations; a separate native helper.
- Consequences: Windows collectors remain bounded and fail safely, while their
  commands are reliable from the scheduled task.
- Related files: `activity-watch-agent/internal/collector/collector.go`,
  `activity-watch-agent/internal/collector/usb.go`.

## ADR-0019: Use native APIs for Windows activity and process inventory

- Date: 2026-08-12
- Status: Accepted
- Context: Even with safe encoded command transport, starting three PowerShell
  processes for every sample approached the bounded command timeout and caused
  intermittent `exit status 1` failures under the Scheduled Task. Later
  installed agents also reported `collect processes inventory failed: exit
  status 1` because the five-minute process inventory path still depended on
  PowerShell.
- Decision: Call User32 and Kernel32 directly for idle duration, foreground
  process/title, pointer position, and interactive-desktop availability. Use a
  native Toolhelp process snapshot for process inventory. Keep encoded
  PowerShell only for service and USB collection.
- Reason: Native calls avoid process startup and script compilation on the
  high-frequency sample path and recurring process-inventory path while
  retaining the existing privacy boundary.
- Consequences: Sampling is faster and no longer depends on PowerShell timing;
  protected foreground processes safely return an empty executable identity.
  Process inventory remains limited to executable names and no command lines.
- Related files: `activity-watch-agent/internal/collector/collector.go`,
  `activity-watch-agent/internal/collector/windows_api_windows.go`.

## ADR-0016: Use the Activity Watch company-view permission in the client

- Date: 2026-08-12
- Status: Superseded by ADR-0017
- Context: The API grants company Activity Watch scope to super administrators
  and `hr.view` users, but the Flutter page requested it only for super admins.
  Device rows without an employee link also collapsed into one filter entry.
- Decision: Superseded. The employee-label fallback remains valid, but company
  scope is no longer granted from `hr.view`.
- Related files: `lib/view/settings/activity_watch/activity_watch_setup_page.dart`,
  `lib/model/activity_watch_enrollment.dart`,
  `billing-api/app/Http/Controllers/ActivityWatchController.php`.

## ADR-0017: Restrict company-wide Activity Watch access to super admins

- Date: 2026-08-12
- Status: Accepted
- Context: The intended policy is company-wide Activity Watch access for super
  administrators only; a regular administrator must not receive peer devices.
- Decision: Both Flutter and API authorization require super-admin status for
  `scope=company`. `hr.view` alone does not broaden Activity Watch scope.
- Reason: Monitoring data is sensitive and needs the stricter ownership rule.
- Consequences: Every non-super-admin sees only their own devices and summaries.
- Related files: `lib/view/settings/activity_watch/activity_watch_setup_page.dart`,
  `billing-api/app/Http/Controllers/ActivityWatchController.php`.

## ADR-0015: Make Windows pairing failures visible

- Date: 2026-08-12
- Status: Accepted
- Context: The direct executable association had no visible output when local
  pairing failed, leaving the employee with only an unexplained pending row.
- Decision: Install a copy of the Windows launcher and register it as the
  pairing-file handler. It runs the installed agent and shows a safe result.
- Reason: Reuses the existing packaging artifact while making failure local and
  actionable.
- Alternatives considered: Require command-line diagnosis; build another UI.
- Consequences: Install the rebuilt installer once to update the handler.
- Related files: `activity-watch-agent/packaging/windows/install.ps1`,
  `activity-watch-agent/packaging/windows/build-exe.ps1`.

## ADR-0014: Package the Windows agent with a .NET launcher

- Date: 2026-08-12
- Status: Accepted
- Context: IExpress repeatedly failed while generating its internal MakeCAB
  directive on the supported Windows build, despite valid no-space staging and
  SED inputs. The release still requires one employee-facing installer EXE.
- Decision: Compile a small .NET Framework launcher that embeds the existing Go
  agent and reviewed `install.ps1`. At runtime it extracts both to a unique
  temporary directory, waits for the installation script, reports the result,
  and attempts to remove temporary files.
- Reason: The compiler is present on supported Windows installations, handles
  large embedded resources reliably, and preserves the existing installation
  and file-association behavior without adding another packaging dependency.
- Alternatives considered: Continue debugging deprecated IExpress behavior;
  distribute a ZIP with separate agent and script; require an additional MSI
  or third-party installer toolchain.
- Consequences: The unsigned launcher remains a release artifact that must be
  code-signed and verified on a clean employee account before distribution.
- Related files: `activity-watch-agent/packaging/windows/build-exe.ps1`,
  `activity-watch-agent/packaging/windows/install.ps1`.

## ADR-0013: Consent-gated office monitoring detail

- Date: 2026-08-10
- Status: Accepted; supersedes ADR-0012 only for explicitly consented office
  devices.
- Context: Administrators need separate sampled keyboard/mouse activity,
  foreground browser titles, and background process inventory for managed
  office laptops and desktops.
- Decision: Collect boolean keyboard/mouse activity signals per sample without
  event content; encrypt active browser titles locally; reuse encrypted bounded
  process snapshots; upload only daily duration/name projections. Never collect
  keys, text, clicks, coordinates, URLs, screenshots, clipboard, or page content.
- Reason: This supplies operational monitoring while retaining a strict
  content boundary and existing enrollment/consent gate.
- Alternatives: Raw hooks/event logs and browser extensions were rejected as
  unnecessarily invasive; fabricated splits from aggregate input were rejected
  as inaccurate.
- Consequences: Values are best-effort sampled estimates and platform
  permissions may produce zero/empty data. Existing payloads use defaults.
- Related files: `activity-watch-agent/internal/collector/`,
  `activity-watch-agent/internal/store/`, Activity Watch API controller and
  Flutter Activity Watch report.

## ADR-0012: Permit HTTP only for approved development servers

- Date: 2026-08-10
- Status: Accepted for development only
- Context: The approved internal development ERP server is on another LAN PC at
  `http://bill.local` / `http://192.168.31.83:8000`, while the agent normally
  permits HTTP only for loopback hosts. The team needs to validate installation
  and pairing before its internal TLS deployment is ready.
- Decision: Allow HTTP when the parsed hostname is exactly `bill.local` or
  `192.168.31.83` in the pairing and sync URL validators. Continue rejecting
  every other remote HTTP hostname.
- Reason: A hostname-specific exception is the smallest change that permits the
  required development workflow without turning off remote-HTTP protection
  generally.
- Alternatives: Trusted internal HTTPS (required for production); allowing all
  private-network hosts (rejected as too broad); manually copying credentials
  (rejected because it bypasses the pairing workflow).
- Consequences: Pairing tokens and device credentials can be observed on that
  LAN path. This build is unsuitable for wider deployment and must be replaced
  by a trusted-HTTPS build.
- Related files: `activity-watch-agent/internal/config/config.go`,
  `activity-watch-agent/internal/pairing/pairing.go`.

## ADR-0011: Pair web employees through a single-use file handled by the agent

- Date: 2026-08-07
- Status: Accepted
- Context: Browsers cannot securely write desktop service configuration or
  credential files. Asking every employee to copy secrets and edit JSON is not
  an acceptable production workflow.
- Decision: Authenticated ERP users create a ten-minute pairing session in the
  existing device table. Flutter Web downloads a versioned `.billingawpair`
  file containing a one-time token but no permanent credential. A signed agent
  installer associates that extension with the Go agent, which exchanges the
  token, provisions encrypted storage, and writes protected configuration.
- Reason: File association works across Windows, macOS, and Linux, avoids an
  HTTPS-page-to-loopback-HTTP dependency, and keeps the permanent credential
  out of browser storage and downloaded files.
- Alternatives: Manual credential copying was rejected as error-prone. A local
  HTTP pairing server was rejected because browser mixed-content/private-network
  policies vary. A fourth pairing table was rejected to preserve the approved
  three-table server design.
- Consequences: Release engineering must build, sign, and publish per-platform
  installers that register the file association. Pairing tokens remain short
  lived and single-use; the local handler must be invoked to finish setup.

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
# ADR-0012: Aggregate input and category-only browser duration

- Date: 2026-08-07
- Status: Accepted
- Context: Activity Watch needs keyboard/mouse usage and browser duration, but
  raw input and browser titles can expose credentials, customer data, and other
  private content.
- Decision: Detect only whether any input occurred between samples, store a
  boolean on an encrypted local activity segment, and upload daily aggregate
  seconds. Derive browser seconds from foreground executable classification.
  Never collect keys, clicks, coordinates, titles, domains, URLs, or page data.
- Reason: This supplies auditable duration metrics while preserving the
  content-exclusion boundary and reusing the existing segment aggregation.
- Alternatives: Global keyboard hooks and browser extensions were rejected
  because they add invasive permissions and content-exposure risk.
- Consequences: `input_seconds` is a sampling approximation and does not split
  keyboard time from mouse time. Browser time is category-only.
- Related files: `activity-watch-agent/internal/collector/`,
  `activity-watch-agent/internal/store/`, Activity Watch API validation, and the
  Flutter Activity Watch summary model/page.
# ADR-0013: Persist salary-component display order separately from identity

- Date: 2026-08-11
- Status: Accepted
- Context: Component ordering had relied on database creation IDs. Applying an
  order to existing employees by deleting and recreating rows would risk
  unintended record replacement and makes a company-wide ordering action
  needlessly disruptive.
- Decision: Add `sort_order` to employee salary components through a standalone
  additive `ALTER TABLE` patch, preserve `id` as a legacy tie-breaker, and
  update only that field when an authorized user applies a source structure's
  order to the company.
- Reason: A narrow field update preserves all salary settings and guarantees
  that existing payroll lines and payslips are not changed.
- Alternatives considered: Deleting/recreating all salary structures;
  keeping creation-ID ordering; copying the entire source component set.
- Consequences: Existing installations must apply one additive SQL patch; no
  framework migration is introduced. Future payroll uses the explicit order,
  while existing zero-order rows remain deterministic by ID until they are
  updated.
- Related files: `billing-api/doc/sql/alter_employee_salary_component_sort_order.sql`,
  `billing-api/app/Services/Hr/EmployeeService.php`,
  `billing-flutter/lib/view/hr/employee_page.dart`.

# ADR-0015: Store bounded USB audit data as encrypted system events

- Date: 2026-08-12
- Status: Accepted
- Context: USB device and removable-drive auditing adds sensitive file-system
  metadata, but Activity Watch already has an approved ten-table encrypted
  schema and an authenticated system-event/outbox path.
- Decision: Gate USB collection behind consent policy version 3, poll Windows
  USB/removable-drive metadata at a bounded interval, store observations in the
  encrypted metadata columns of `system_events`, and derive bounded USB fields
  for the existing daily-summary payload. File contents and hashes are never
  read. Added files are not described as copied because their source is not
  knowable from snapshot differences.
- Reason: Reusing encrypted system events preserves the compact schema,
  offline durability, retry/idempotency behavior, and backward-compatible API
  summary contract while keeping privacy limits explicit.
- Alternatives considered: A new USB table family; reading the NTFS USN journal
  with elevated privileges; continuous recursive file-system watchers; treating
  every newly observed file as a proven copy.
- Consequences: Scans are O(D + F) time and O(D + F) memory for D devices and F
  removable-drive files, with F capped at 5,000. Firmware-derived port counts
  and polling-derived file events are best-effort, and rapid changes between
  observations can be missed. Existing version-2 pairings must be renewed to
  enable this expanded collection scope.
- Related files: `activity-watch-agent/internal/collector/`,
  `activity-watch-agent/internal/store/`, Activity Watch API validation, and the
  Flutter Activity Watch summary details.
