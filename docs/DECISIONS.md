# Architecture decisions

## ADR-0040: Make Sales customer-advance allocation explicit and transactional

- Date: 2026-09-03
- Status: Accepted
- Context: Sales receipts silently allocated when no rows were supplied, while
  the editor could conflate Received Amount with the allocation total. Purchase
  already has an explicit, audited advance-allocation workflow.
- Decision: Keep Received Amount as the receipt control total; treat its
  invoice-unallocated remainder as customer advance; require the user to invoke
  Auto Allocate or add rows; and ask before applying posted FIFO advances to the
  invoice currently being posted. Perform allocation, settlement, voucher, and
  audit updates under database locks in one transaction.
- Reason: Explicit intent prevents unexpected settlement, preserves genuine
  customer credits, and keeps receivable balances and accounting allocations
  consistent under concurrent use.
- Alternatives considered: Continue silent receipt allocation; automatically
  apply advances to every old invoice; calculate Received Amount from rows; or
  maintain a Sales-only frontend calculation without server enforcement.
- Consequences: Sales gains company-scoped preview/advance/allocation APIs and
  allocation audit columns. Direct customers are excluded from cross-document
  matching, historical rows remain untouched, and deployment requires the
  accompanying migration or SQL patch.
- Related files: Sales receipt/invoice services, voucher allocation service,
  Sales controllers/routes/models, Flutter Sales receipt/invoice editors,
  `billing-api/doc/sales-customer-advance-allocation.md`, migration, patch, and
  `install.sql`.

## ADR-0033: Email printable documents through one validated template flow

- Date: 2026-09-02
- Status: Accepted
- Context: Print-capable ERP documents used separate or absent email actions;
  existing quotation and payslip actions could send without template choice.
- Decision: Extend the shared print preview with one template-selected Email
  PDF action and send through a bounded backend document registry that reuses
  `EmailCommunicationService` for recipient resolution, rendering, delivery,
  and history.
- Reason: This makes template selection mandatory everywhere without copying
  PDF, dialog, recipient, SMTP, or placeholder logic into each module.
- Alternatives considered: Add separate send dialogs and endpoints to every
  page; trust client-composed recipients and template content; create a second
  email framework.
- Consequences: Printable controllers pass persisted document ids into the
  common preview; the backend owns the supported-type and permission mapping.
  No Sales Payment entity or new permission code is introduced.
- Related files: Shared print designer/support, communication models/services,
  printable document controllers, backend document-email service and route.


## ADR-0032: Keep Sales lifecycle labels presentation-only

- Date: 2026-09-01
- Status: Accepted
- Context: Generic status rendering mapped every posted/submitted Sales
  document to `Finished`, hiding the next required lifecycle action.
- Decision: Preserve canonical stored statuses and derive document-specific
  labels/colors through shared Flutter helpers. Add bounded relationship
  existence flags to quotation and delivery read payloads so list and detail
  screens make identical decisions without additional client requests.
- Reason: This avoids duplicating or mutating backend lifecycle state for UI
  wording, keeps filters/request payloads compatible, and prevents per-row
  relationship queries.
- Alternatives considered: Rewrite persisted statuses to display phrases;
  infer conversion only from client-side pipeline collections; duplicate label
  switches in every page.
- Consequences: Read payloads gain boolean fields; database schema and write
  contracts are unchanged. Every Sales status surface must use the
  document-specific shared helper where one exists.
- Related files: Sales status helpers/register/detail/pipeline views; API Sales
  quotation and delivery models, list-query services, and repositories.

## ADR-0031: Complete CRM leads at delivery or invoice

- Date: 2026-08-26
- Status: Accepted
- Context: The CRM marked a lead completed as soon as an opportunity or sales
  order existed, although the requested business completion point is delivery
  or invoicing.
- Decision: Keep the canonical completion decision in the backend sales-chain
  service. Flutter continues to render the API's `lead_status` and reuses the
  existing CRM refresh mechanism.
- Reason: This prevents quotation/order screens from duplicating business rules
  and keeps completion consistent across delivery and invoice entry paths.
- Alternatives considered: Mark completion from the quotation screen; add a
  separate frontend-only status; complete at sales order creation.
- Consequences: Leads may remain read-only while In Progress because their
  linked opportunity is already established, but they are not shown as
  completed until delivery/invoice exists. No schema migration is required.
- Related files: `billing-api/app/Services/Crm/CrmSalesChainService.php`,
  CRM lead/opportunity services, and CRM lead register refresh flow.

## ADR-0030: Keep leave-type creation out of leave requests and company policy

- Date: 2026-08-21
- Status: Accepted
- Context: The Leave Request form included an inline leave-type creation
  dialog, while a dedicated Leave Types master already owns the shared catalog.
  Company Settings now configures company-specific policies for catalog types.
- Decision: Remove inline creation from Leave Requests. Retain Leave Types as
  the sole catalog-management screen and keep Company Settings limited to
  company policy configuration.
- Reason: A single catalog workflow prevents duplicate or incomplete leave
  types and keeps company entitlement changes separate from shared definitions.
- Alternatives considered: Create leave types in the request form; create
  leave types inside Company Settings; duplicate types per company.
- Consequences: Users create a type in Leave Types before configuring it for a
  company or selecting it in a request. Existing policy rows remain the
  company-specific source of entitlement and LOP behavior.
- Related files: Leave Request page/controller, Leave Types page/controller,
  Company Settings Leave Policy tab.

## ADR-0029: Company-scoped generic leave policies

- Date: 2026-08-21
- Status: Accepted
- Context: Leave types are global, CL entitlement is hard-coded to 12 with
  CL-only overflow handling, and companies require different entitlements and
  LOP deduction factors.
- Decision: Keep the shared leave-type catalog and add one policy row per
  company/leave type. Resolve entitlement and overflow through a generic leave
  allocation service. Store the LOP multiplier on the company and snapshot it
  into payroll calculations.
- Reason: Company policy rows avoid duplicating leave-type names while allowing
  every company to configure CL and all other leave types independently.
- Alternatives considered: hard-coded CL/SL/EL columns on companies; duplicating
  the leave-type catalog for each company; continuing CL-only calculations.
- Consequences: Existing requests remain compatible, company policy lookups are
  indexed, and leave allocation becomes policy-driven for every leave type.
- Related files: company settings/model/service, company leave policy schema,
  leave request allocation, payroll processing, and focused tests.

## ADR-0028: Restore every valid browser session on refresh

- Date: 2026-08-20
- Status: Accepted
- Context: The bootstrap route required the optional remember-me preference,
  so users with a valid token were sent back to login after every refresh.
- Decision: Restore any unexpired stored session. Remove the checkbox because
  it no longer has a meaningful security or behavior distinction.
- Reason: The requested session lifetime is manual logout, token expiry, or
  server rejection—not browser refresh.
- Alternatives considered: Require users to tick remember me; persist a second
  long-lived token; browser-session-only storage.
- Consequences: A user of a shared browser must use the explicit Logout action
  when leaving the ERP.
- Related files: `AppBootstrapController`, login controller/page, and existing
  `SessionStorage`.

## ADR-0024: Month-end manual attendance uses the shared attendance ledger

- Date: 2026-08-17
- Status: Accepted
- Context: Departments without computers cannot practically create attendance
  one employee at a time, while Activity Watch rows must not be overwritten.
- Decision: Add a separate monthly calendar for employees without active ERP
  users and one bounded API accepting employee/date/status entries. Validate
  the full month before inserting only rows that do not already exist.
- Reason: One request avoids partial frontend loops and reuses payroll's single
  attendance source of truth and unique key.
- Alternatives considered: One API request per employee; overwrite existing
  rows; create a separate manual-attendance table; assign one status without
  per-employee adjustment.
- Consequences: Up to 15,000 cells can be processed in O(n) application work
  plus indexed operations. Sundays and existing rows remain locked. The route
  is opened from Attendance rather than duplicated in the HR drawer.
- Related files: HR attendance controller/service/routes, Flutter HR service,
  monthly attendance page/navigation, SQL patch, and focused payroll tests.

## ADR-0025: Draft monthly attendance stays in the attendance ledger

- Date: 2026-08-17
- Status: Accepted
- Context: HR needs to prepare a full manual month before it becomes payroll
  input, without a second attendance data source.
- Decision: Store `draft` or `submitted` state on manual attendance records.
  Draft cells remain editable in the monthly calendar; submitted cells and
  Activity Watch rows are locked. Payroll blocks when any manual draft exists
  in the selected period.
- Reason: Preserves the employee/date unique key and avoids synchronizing a
  staging table with the actual payroll ledger.
- Alternatives considered: A separate monthly batch table; treating draft rows
  as payroll input; allowing payroll to silently ignore drafts.
- Consequences: Existing rows default to submitted after the SQL patch. Users
  must submit drafts before processing payroll.

## ADR-0026: Use the shared monthly sheet for agent exception overrides

- Date: 2026-08-17
- Status: Accepted
- Context: A row-by-row attendance register makes it impractical for HR to
  review agent attendance and enter LOP, half-day, leave, or absence exceptions.
- Decision: The main Attendance route uses the monthly calendar for every
  active employee. Bulk Attendance reuses that calendar but stays restricted to
  non-system employees. In the main sheet, a changed Activity Watch record is
  converted to a manual record in the same ledger row.
- Reason: Retains one employee/date payroll input, preserves the agent's
  check-in/out audit timestamps, and avoids separate override tables.
- Alternatives considered: Keep the row register as the editor; add a second
  exception table; let the agent calculate HR absence decisions.
- Consequences: HR explicitly changes only exception cells. The API exposes
  `include_system_employees` only to privileged HR monthly-sheet calls.

## ADR-0027: Attendance is a persisted-record monthly report

- Date: 2026-08-17
- Status: Accepted; refines ADR-0026 UI behavior
- Context: Reusing the editable bulk sheet on Attendance made unsaved default
  Present cells and bulk controls look like actual attendance records.
- Decision: Attendance reuses the calendar layout only as a saved-record
  report. It filters out employees without records, renders missing days as
  blank, removes selection and batch-save controls, and opens only an existing
  record through the established single-record editor. Bulk Attendance remains
  a separate route and workflow.
- Reason: The report must never imply that an unsaved default is payroll input.
- Alternatives considered: Keep default Present cells; retain batch editing in
  both routes; restore the old row-per-record table.
- Consequences: Report indexing uses employee/date maps and sets in O(E + A)
  preparation time. Creating a full manual month remains exclusive to Bulk
  Attendance.

## ADR-0023: Use Activity Watch prompt events alongside manual attendance

- Date: 2026-08-17
- Status: Accepted
- Context: ERP login is not the approved attendance signal, and employees in
  non-computer departments still require HR-entered attendance.
- Decision: Send a minimal device-authenticated check-in promptly from the Go
  agent, persist unsent check-ins across restarts, and keep detailed Activity
  Watch batches logout-only. Preserve manual attendance as authoritative.
- Reason: This separates work-device presence from ERP authentication without
  creating a second attendance ledger or excluding non-system employees.
- Alternatives considered: ERP login attendance; logout-only attendance;
  mandatory device enrollment for all departments.
- Consequences: ADR-0022 is superseded only for its login capture signal. The
  existing attendance/payroll calculations and uniqueness rules remain.
- Related files: Activity Watch agent attendance client/runner, backend
  Activity Watch attendance endpoint, HR attendance register.

## ADR-0022: Use login-idempotent attendance and immutable payroll snapshots

- Date: 2026-08-14
- Status: Superseded for attendance capture by ADR-0023; payroll snapshots remain accepted
- Context: Attendance allowed duplicate employee/day rows, payroll did not
  prorate salary, and payslips could resolve a later salary structure.
- Decision: Upsert successful login by employee/date, calculate scheduled units
  in a locked payroll transaction, reconcile structure/components, and persist
  run/line snapshots.
- Reason: Natural keys handle concurrency, bulk maps avoid N+1 queries, and
  snapshots preserve historical payroll evidence.
- Alternatives considered: Count login history; application-only duplicate
  checks; background attendance generation; render current salary settings.
- Consequences: Sunday is the paid weekly-off default until a company calendar
  editor is approved. Existing endpoints remain compatible with added fields.
- Related files: HR attendance/payroll/payslip models, services, registers, and
  workflow dialogs in Flutter and the backend.

## ADR-0020: Upload Activity Watch outbox only on ERP logout

- Date: 2026-08-14
- Status: Accepted
- Context: The existing worker uploaded on start, every sync interval, after
  each summary revision, on ERP logout, and during shutdown. The requested
  policy reduces server requests while retaining encrypted offline records.
- Decision: Drain the outbox only when the native ERP logout control is
  consumed. Keep collection, summary generation, retry metadata, and encrypted
  local persistence active. Shutdown finalizes local state without uploading.
- Reason: ERP logout is the requested explicit synchronization boundary and
  avoids background server traffic.
- Alternatives considered: Longer periodic interval; startup-only uploads;
  shutdown uploads.
- Consequences: Pending records can remain local across power cycles until the
  next ERP logout; they remain SQLCipher/AES-GCM protected.
- Related files: `activity-watch-agent/internal/agent/runner.go`,
  `activity-watch-agent/internal/agent/runner_test.go`.

## ADR-0021: Add metadata-only macOS USB topology monitoring

- Date: 2026-08-14
- Status: Accepted
- Context: USB monitoring previously returned no data outside Windows.
- Decision: On macOS, derive bounded USB device metadata from
  `system_profiler SPUSBDataType -json` and feed it into the existing encrypted
  USB observation pipeline. Keep Windows-only removable-drive file event
  monitoring unchanged.
- Reason: This adds practical macOS USB visibility without broad filesystem
  permissions or reading file contents.
- Alternatives considered: Full macOS mounted-volume scanning; a privileged
  native extension; no macOS USB support.
- Consequences: macOS reports connected/disconnected device metadata but not
  removable-drive file changes or port totals.
- Related files: `activity-watch-agent/internal/collector/usb.go`,
  `activity-watch-agent/internal/collector/collector_test.go`.

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
- Decision: Authenticated ERP users create a 30-minute pairing session in the
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

## ADR-0018: Extend the existing Material theme as the global design boundary

- Date: 2026-08-22
- Status: Accepted
- Context: The ERP already applies `AppTheme.light()` at `MaterialApp` and 128
  source files consume `AppThemeExtension`. The approved StaffU-inspired visual
  language requires shared light/dark semantics before modules are migrated.
- Decision: Keep `MaterialApp` as the sole global theme widget, add light and
  dark builders to `AppTheme`, preserve `AppThemeExtension` as the ERP-specific
  compatibility contract, and style standard Material components globally.
  Register both themes at the app root with `ThemeMode.system`.
- Reason: Extending the established theme avoids a parallel inherited widget,
  duplicate lookups, broad caller churn, and inconsistent module styling.
- Alternatives considered: Add a second custom theme scope; copy generated
  DesignLang Flutter tokens directly; redesign all modules in one change; keep
  a light-only theme.
- Consequences: Shared Material controls can adopt the new language
  immediately, while hardcoded and feature-specific styles remain explicit
  one-module-at-a-time migration work. Theme construction is fixed-size O(1)
  time and O(1) space. System dark mode can expose legacy hardcoded light
  colors until those modules are migrated, so focused visual QA is required at
  each module boundary.
- Amendment (2026-08-22): `tableRowAlternate` is part of the semantic extension
  contract. Shared register lists and `ErpLineItemTable` consume the table roles
  directly, so standard lists and editable document lines use one light/dark
  visual language without changing their business behavior.
- Related files: `lib/app/theme/app_theme.dart`,
  `lib/app/theme/app_theme_extension.dart`, `lib/main.dart`,
  `lib/view/purchase/purchase_register_page.dart`,
  `lib/widgets/erp_line_item_table.dart`, and focused table/theme tests.

## ADR-0037: Model Excel statutory formulas as salary-component bases

- Date: 2026-09-02
- Status: Accepted
- Context: The existing editor supports fixed, Basic, Gross, and CTC bases,
  while the approved wage register calculates PF from capped EPF wage and ESI
  from rounded Basic + DA with upward whole-rupee rounding.
- Decision: Extend the existing `calculation_basis` contract with
  `percent_epf_wage` and `percent_basic_da_ceil`. Keep the formula in the
  backend calculation service and expose the same enum values through the
  existing Flutter component editor.
- Reason: A shared backend formula is auditable and prevents employee-specific
  fixed statutory amounts while preserving the current component model.
- Alternatives considered: fixed PF/ESI amounts; special-casing payslip totals;
  storing formula text supplied by users.
- Consequences: Deployment backfills current PF and ESI components. Historical
  payroll snapshots remain unchanged. Paid-day discrepancies require a
  separate attendance-policy decision.
- Related files: backend statutory/payroll services and migration; Employee
  Salary Components editor and documentation.

## ADR-0038: Prorate saved net salary for calendar-month payroll

- Date: 2026-09-02
- Status: Superseded by ADR-0039
- Context: Month-based payroll subtracted scheduled-working-day LOP from every
  calendar day, implicitly paying all Sundays during a continuous LOP period.
  It also recomputed net solely from gross and explicit deductions even when
  the approved salary structure stored a different contractual monthly net.
- Decision: Treat the saved monthly net as authoritative for the `month`
  calculation basis. Derive payable calendar days from payable scheduled units
  plus weekly offs adjacent to payable work, use the same factor for earnings,
  floor the prorated net to a whole rupee, and add an auditable net-salary
  adjustment when explicit deductions do not reconcile to the prorated net
  target.
- Reason: This directly implements the approved formula while keeping gross,
  deductions, final net, paid days, and payslip totals internally consistent.
- Alternatives considered: Continue gross-only proration; nearest-rupee
  rounding; mark every Sunday payable; overwrite PF/ESI values; silently let
  payslip deductions disagree with final net.
- Consequences: Future or recalculated month-based runs can differ from prior
  snapshots. Working-days and percentage modes are unchanged. The bounded
  attendance algorithm remains O(A + D) per employee for A records and D days.
- Related files: backend payroll service/tests and Flutter company-setting
  labels, specifications, architecture, testing notes, and changelog.

## ADR-0039: Configure payroll proration per company

- Date: 2026-09-02
- Status: Accepted
- Context: The supplied workbook uses an actual-calendar-day divisor, while a
  sellable ERP must also support scheduled-working-day, fixed-divisor, and
  percentage policies. Statutory profiles already store effective-dated PF/ESI
  ceilings, but special salary-component formulas bypassed them.
- Decision: Extend the existing company record with divisor, net-target,
  rounding, and weekly-off policy fields. Reuse effective-dated statutory
  profiles for special component ceilings and snapshot all applied settings.
- Reason: Company-level policy is simple to operate, avoids code forks and a
  duplicate settings table, and keeps processed payroll auditable.
- Alternatives considered: hard-coded formulas; employee-specific policies;
  another payroll-policy table; continuing to hard-code statutory ceilings.
- Consequences: A reviewed SQL patch/API/UI change is required. Existing month
  companies retain contractual-net/floor behavior; historical snapshots remain immutable.
  Company payroll policy is current-state configuration, while statutory limits
  remain effective-dated through the existing profile model.
- Related files: company schema/model/service/controller; payroll/statutory
  services; Company Settings and statutory UI; tests and deployment docs.

## ADR-0040: Use a feature-local Kanban presentation for standalone project tasks

- Date: 2026-09-03
- Status: Accepted
- Context: The StaffU task reference is a Kanban board, while the ERP task API
  already defines five statuses and the Project master embeds tasks inside a
  constrained child tab.
- Decision: Render the standalone task route through a feature-local responsive
  board grouped by the existing backend statuses. Keep the typed controller,
  editor, filters, and embedded expandable subtab unchanged as behavioral
  boundaries. Do not add a priority field or substitute a visual-only status.
- Reason: This applies the extracted design where it fits while preserving API
  truth, permissions, validation, and the denser parent-editor workflow.
- Alternatives considered: Copy the reference's three statuses; change every
  task surface to Kanban; introduce a second task state model; redesign the
  global theme again.
- Consequences: Grouping is O(n) time and O(n) output space for n visible tasks;
  desktop can scroll lanes horizontally and narrow layouts stack them. The
  ordinary route defaults to all statuses so Completed is discoverable. A
  cross-lane card drop uses the existing typed update API with optimistic UI,
  per-task duplicate suppression, cache invalidation before authoritative
  reload, and rollback on failure. Task create/edit/delete use the same refresh
  ordering. Only the five statuses accepted by the backend are valid targets.
- Related files: `lib/view/project/project_task_page.dart`,
  `lib/view/project/widgets/project_task_kanban_board.dart`, task controller,
  focused tests, and frontend documentation.

## ADR-0041: Extract reusable ProjectKanbanBoard and adopt StaffU Kanban for Project Milestones

- Date: 2026-09-03
- Status: Accepted
- Context: Project Milestones required the same StaffU-style Kanban board
  functionality introduced for Project Tasks. Duplicating board, lane, header,
  and drag targets would produce redundant presentation code.
- Decision: Implement a single unified `ProjectKanbanBoard<T extends Object>`
  widget with `ProjectKanbanBoard.task` and `ProjectKanbanBoard.milestone`
  factory constructors. Reuse this single widget across both `/projects/tasks`
  and `/projects/milestones`. Strictly use application theme tokens for all
  surfaces and status accents. Retain `ProjectSubtabExpandableSection` for
  embedded milestones.
- Reason: Strictly aligns with AGENTS.md rules against creating near-duplicate
  widgets, unifying all Kanban board logic, layout, drag targets, and styling
  into one canonical widget.
- Alternatives considered: Maintaining two wrapper widget files; forcing a 5-status
  task model onto milestones; creating custom color palettes instead of theme tokens.
- Consequences: Zero redundant board wrappers, O(n) grouping, optimistic updates
  with rollback, and unified theme-driven styling across tasks and milestones.
- Related files: `lib/view/project/widgets/project_kanban_board.dart`,
  `lib/view/project/project_task_page.dart`,
  `lib/view/project/project_milestone_page.dart`,
  `lib/controller/project/project_milestone_management_controller.dart`.

## ADR-0042: Keep Project editors inside the persistent application shell

- Date: 2026-09-04
- Status: Accepted
- Context: Five Project registers opened editors by pushing a new
  `AppStandaloneShell`, remounting the drawer and header instead of preserving
  the route-first shell behavior already used by Sales.
- Decision: Give those Project editors stable `new` and record-id paths, resolve
  them in `AppShellPage`, and render their existing forms as editor-only center
  content inside the mounted shell.
- Reason: This follows the frontend shell/navigation contract, keeps browser and
  application history synchronized, and reuses the Sales route architecture.
- Alternatives considered: hiding the second drawer; retaining unnamed nested
  routes; opening forms in dialogs. These do not preserve a single fixed shell
  with addressable content.
- Consequences: No API or database changes. Route parsing and lookup remain O(1),
  and direct editor URLs load the requested record through existing controllers.
