# Specifications

## Persistent authenticated browser session

- Date: 2026-08-20
- Status: Implemented
- A valid stored authentication token restores the ERP session after a browser
  refresh regardless of the legacy remember-me preference.
- Manual logout, token expiry, and a server 401/403 remain the only reasons to
  clear the persisted session and route the user to login.
- The login form does not offer a remember-me checkbox because it no longer
  changes refresh behavior.

## Attendance month and year filtering

- Date: 2026-08-17
- Status: Implemented

- The saved Attendance report uses Month and Year selectors instead of a From
  date / To date combination. Selecting either value immediately reloads the
  matching monthly attendance sheet and resets the horizontal calendar scroll.
- Employee, status, source, and search filters remain client-side filters on
  the loaded month.

## Monthly manual attendance

- Monthly Attendance lists every active employee in the selected company,
  including employees linked to active ERP users. The existing attendance
  records, employment-period, and weekly-off rules still determine whether an
  individual day can be edited.

- Date: 2026-08-17
- Status: Implemented

### Objective and rules

- The Attendance screen uses the shared employee-by-day calendar as a monthly
  report. It lists only employees with persisted attendance in that month and
  displays only saved Activity Watch or manual records; blank days stay `—`.
- The report has no employee selection, default-Present generation,
  draft/submit actions, or multi-record save. Selecting an existing saved cell
  opens the existing attendance editor directly, without an intermediate JSON
  detail dialog.
- The report Filter action toggles the shared full-width HR filter bar for
  search, employee, status, source, month, and year. It does not use a popup
  or a separate inline Month/Year/Load toolbar.
- All live HR list filters (Attendance, Leave Requests, Expense Claims,
  Payroll Runs, and Payslips) use the same toggleable `HrInlineFilterBar`;
  filters are no longer presented in popups. Each page keeps its existing
  fields, clear behavior, and load request. Payroll Runs includes From date and
  To date, which filter the persisted run date alongside search and status.
- On `SettingsWorkspace` HR pages, the bar uses the workspace-level full-width
  header slot so it spans the list and editor area rather than the list pane.
- The inline bar follows the Sales filter action pattern: it has no Apply
  button and uses the shared Clear action at the end of the filter row.
- Successfully submitted Bulk Attendance is persisted in `attendance_records`,
  then opens the Attendance report on the submitted company/month so the new
  manual rows are visible immediately.
- The saved-record report is a clean, horizontally scrollable grid
  with serial number, employee identity, department, numbered day headers with
  three-letter weekday labels, daily status pills, horizontal row separators,
  and pagination. It intentionally omits vertical daily-column lines. Filter,
  Reload, and Bulk Attendance remain in the page action area; the report does
  not render a separate title/control bar, Employee Status column, or
  status-legend card.
- `MonthlyAttendanceCalendarGrid` owns the shared employee/day table layout;
  the report and Bulk Attendance use the same serial, employee avatar,
  department, day-header, and row-separator presentation. Their distinct cell
  actions and Bulk Attendance selection state do not duplicate the calendar
  structure.
- Report rows may include inactive or terminated employees when they have
  attendance inside the selected employment period; Bulk Attendance remains
  restricted to active eligible employees.
- Unsupported reference actions such as Export, Import, Template, and Summary
  are not displayed until their workflows exist.
- Its Bulk Attendance action opens the separate editable calendar scoped to
  employees without an active ERP user.
- Eligible Monday-through-Saturday dates through company-local today default to
  Present. HR marks exceptions as Half day, Paid leave, LOP, or Absent.
- Sunday, future dates, and dates outside employment are non-editable report
  cells. HR may open a saved Activity Watch record individually and change it
  through the established editor; the resulting manual decision becomes the
  payroll source and later agent events cannot replace it.
- In Bulk Attendance, Activity Watch and submitted manual rows remain locked;
  the flow only prepares non-system employees.
- Selected employee rows are saved in one bounded transaction. The request is
  capped at 15,000 employee/date cells and reports created/skipped counts.
- Paid leave is one payable unit, Half day is 0.5, and LOP/Absent are unpaid.
- User linkage is schema-compatible: installations with `users.employee_id`
  use the direct relation; legacy installations use matching employee codes.
- The all-employee request sends `include_system_employees` as numeric `1` or
  `0`, compatible with the existing Lumen boolean query validator.
- Monthly attendance has two actions: Draft saves editable manual cells without
  making them payroll-ready; Submit locks those cells as payroll-ready.
- Activity Watch and earlier submitted/manual attendance remain locked. Payroll
  processing is rejected while any manual draft attendance exists in its period.

### Acceptance criteria

- The drawer contains one Attendance entry, which opens the saved-record-only
  monthly report. Authorized HR users can open the non-system Bulk Attendance
  workflow through the Bulk Attendance action.
- HR can select employee rows, review the full calendar, mark exceptions, save
  a draft, then explicitly submit the selected attendance.
- Existing attendance remains unchanged and is counted as skipped.
- The monthly sheet reloads after save and displays created rows as locked.
- Submitted bulk rows appear in Attendance with source `M` for the same month.

## Activity Watch/manual attendance and attendance-based payroll

- Date: 2026-08-17
- Status: Implemented

### Objective and rules

- ERP login does not create attendance. A paired Activity Watch agent creates
  at most one `activity_watch` record for its linked active employee on the
  company-local date; manual status rows retain authority.
- The first check-in is queued locally before transmission and retried across
  network failures or service restarts. Detailed monitoring uploads remain
  restricted to ERP logout.
- Employees and departments without system access continue using the existing
  manual attendance create/edit workflow.
- Attendance list responses retain the API's nested employee name/code in the
  typed Flutter model. The register displays the employee name, falling back to
  employee code only when the name is absent; it must not issue a per-row
  employee request.
- Payroll preview reports scheduled, present, paid, and LOP units. Monday
  through Saturday are scheduled and Sunday is a paid weekly off requiring no
  login in this first release.
- Processed payroll lines display earned gross, deductions, net pay, paid days,
  present units, and total LOP. Half-days remain decimal.
- Processing blocks structures whose components belong elsewhere, contain
  duplicate names, or whose earning total differs from gross by over INR 0.01.
- A rejected Process request (including HTTP 422 salary validation) keeps the
  payroll detail dialog usable and displays the API validation message. Only a
  successful process closes the dialog and refreshes the payroll register.
- The API owns timezone, idempotency, proration, snapshots, lifecycle, and
  accounting balance.

### Acceptance criteria

- Attendance register identifies Activity Watch versus manual source.
- Attendance register displays the employee returned by the existing API
  relation for both Activity Watch and manual rows.
- Draft preview identifies ready employees and paid/scheduled/LOP units.
- Processed lines show earned gross and preserve decimal attendance.
- Later salary edits do not change processed payslip snapshot values.
- Focused Flutter and backend validation passes.

## Payslip gross and net salary summary fallback

- Date: 2026-08-13
- Status: Approved for implementation

### Objective

Show the calculated Gross Salary and Net Salary on every rendered payslip,
including older saved templates that lack a salary summary.

### Scope and rules

- Earnings and deductions stay as individual pay heads; calculated Gross and
  Net amounts are not inserted into either table.
- The deductions table never includes a calculated `Total Deductions` row;
  that aggregate appears only in the salary summary.
- The salary summary shows CTC Monthly alongside Gross Salary, Total
  Deductions, and Net Salary.
- A saved `hr_payslip` template without a Gross/Net salary-summary binding
  receives a non-editing preview fallback beneath the breakup tables.
- Templates that already bind either salary-summary Gross or Net value retain
  their existing layout without an added fallback.
- The values come from the existing payslip `salary_summary` payload; no
  payroll, API, database, or salary-component calculation changes.

### Acceptance criteria

- A payslip with no summary text shows Gross Salary, CTC Monthly, Total
  Deductions, and Net Salary beneath its breakup tables.
- A template that already displays the salary summary is not duplicated.
- Earnings and Deductions tables retain their current rows and bindings.

## Payroll run deletion from processed state

- Date: 2026-08-13
- Status: Implemented

### Objective

Allow an authorized HR user to delete a processed payroll run from its detail
dialog, matching the existing backend lifecycle rule.

### Scope and rules

- The detail dialog shows **Delete** for both `draft` and `processed` runs.
- A confirmation is required before either deletion. The processed-state prompt
  explicitly warns that generated payroll lines and payslips are permanently
  removed through the existing database cascade.
- Posted runs retain no delete action. The existing API remains the authority
  and rejects voucher-linked or otherwise ineligible records.
- No API, database, permission, or accounting behavior changes. A successful
  deletion closes the dialog and refreshes the register; an API failure leaves
  the dialog open and displays the server message.

### Acceptance criteria

- Opening a processed payroll run displays Delete and no Post action.
- Deleting a processed run requires confirmation, calls the existing DELETE
  endpoint, and refreshes the payroll-run register after success.
- Draft and posted-run behavior remains unchanged.

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
3. ERP creates a 30-minute, single-use pairing token and downloads a small
   `.billingawpair` file. The file contains only the API URL, platform, token,
   and format version; it never contains the permanent device credential.
4. Opening the pairing file invokes the installed agent. The agent exchanges
   the token once, provisions encrypted local storage when absent, writes the
   credential/configuration atomically with user-only permissions, and starts
   the user service.
5. The ERP page shows pending, connected, last-seen, revoked, or expired state.
   Normal ERP logins and computer restarts require no reconfiguration.

Windows installer updates must stop an existing Activity Watch service/process,
wait until the installed executable is unlocked, replace it, and restart the
same service. The launcher requests elevation for this service-aware update so
an in-use agent executable never causes an opaque copy failure.

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

### Activity Watch connection setup status and controls

- The connection setup card contains only its title, the device-label field,
  and the connect button. The existing service request continues to send the
  consent flag required by the backend contract.
- A pending pairing shows `Waiting for connection` while its server-issued
  pairing expiry has not passed. After the 30-minute pairing window passes,
  it shows `Pairing expired`.
- Disconnected/revoked devices are not shown in the Activity Watch device list.
  The list action is labelled `Disconnect`; it uses the existing authenticated
  revoke endpoint and refreshes the list after success.

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
- A Windows Scheduled Task permission failure after the server exchange must
  leave the device paired. The launcher reports connected setup with a separate
  background-start warning; it must not misreport this as a pairing failure.
- Windows pairing-file launch failure: the installed handler must show the
  safe local failure detail rather than silently returning to ERP.

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
   On Windows, idle duration, foreground window/process, pointer position, and
   interactive-desktop availability use direct bounded Windows API calls so the
   15-second sample loop does not depend on PowerShell startup. Windows process
   inventory also uses native process snapshots so the five-minute inventory
   loop is not blocked by PowerShell startup, script policy, or Scheduled Task
   command failures. Remaining multi-part PowerShell inventory commands use
   UTF-16LE `EncodedCommand` transport so Scheduled Task argument reconstruction
   cannot alter pipelines.
   A missing foreground window/process is a valid empty observation, not a
   collector error. Windows idle duration must account for the native 32-bit
   last-input timer wrapping during long system uptimes.
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
   minutes) and immediately before logout; network retry frequency cannot
   create extra summary revisions.
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
  sent for server reporting over HTTPS (loopback HTTP is development-only),
  and only when ERP logout requests an outbox flush.
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
- Graceful shutdown that finalizes local encrypted records without uploading.
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
5. Every ERP logout action must require an explicit user confirmation before
   ending the session. The confirmation explains that a browser session cannot
   invoke the local Windows agent; only a native Flutter session can issue its
   local logout signal.
6. Pending sync remains encrypted locally until a later ERP logout, permanent
   rejection, or policy/device revocation.
7. Shutdown cancels collection, closes open work, and closes SQLCipher without
   an upload attempt.
8. Upload batches are ordered by next-attempt time and creation time and are
   limited by configured batch size. Selection uses the approved dispatch
   index, making each batch `O(B)` after indexed lookup where `B` is batch size.
9. A batch is acknowledged only when the server returns HTTP 2xx with a JSON
   success envelope whose accepted count matches the uploaded batch. HTML,
   malformed JSON, a false success flag, or a mismatched accepted count is a
   retryable invalid response and must never mark local outbox rows as synced.
   Authentication/authorization rejection is permanent until re-enrollment.
   Timeouts, network errors, 408, 429, and 5xx use bounded exponential retry.
10. Logs must never contain database keys, device credentials, decrypted
   payloads, window titles, URLs, or personal activity content.
11. A plaintext SQLite runtime, missing key, wrong key, unsupported schema,
   absent consent, or invalid configuration fails closed.
12. `provision` must create the exact approved schema version, a cryptographically
    random raw 256-bit key encoded in a mode-`0600` file, and the configured
    control-directory parent. It must refuse to overwrite either an existing
    database or an existing key file.
13. If provisioning cannot finish, it must remove only temporary artifacts and
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

Web logout uses device-authenticated control endpoints derived from the batch
URL: `GET /activity-watch/control` reads the server flush flag and
`POST /activity-watch/control/acknowledge` clears it only after the agent has
successfully drained the complete local outbox. Acknowledgement is a separate
request so an initially empty outbox and a final batch exactly equal to the
configured batch size both complete correctly. The existing final-batch header
remains backend-compatible during agent rollout but is not the new agent's
source of completion truth.

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
- The worker starts collector and logout-control loops and stops them with
  bounded cleanup.
- Logout stops session collection but triggers the only synchronization attempt
  without stopping the machine worker.
- Outbox upload handles success, retryable failure, permanent rejection, batch
  limits, and cancellation.
- An HTTP 200 HTML response and malformed/mismatched JSON remain retryable and
  do not mark any outbox item synced.
- Server-driven logout acknowledgement occurs after zero, partial, one-full,
  and multiple-full-batch drains, and acknowledgement failure leaves the server
  flush flag set for retry.
- Retry delay is capped and deterministic under injected randomness.
- Configuration rejects unsafe or missing required values.
- Provisioning creates an encrypted database that passes the store's schema
  verification and rejects existing database/key paths without modifying them.
- SQLCipher runtime and approved schema are verified before writes.
- `go test ./...`, `go vet ./...`, and `go build ./cmd/activity-watch-agent`
  pass where a Go/CGO toolchain is available.
- On Windows, the release packaging command must build one self-contained EXE
  that embeds the compiled Go agent and the reviewed per-user installation
  script. The launcher extracts both into a unique temporary directory, waits
  for the script, reports success or failure, and performs best-effort cleanup.

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
# Privacy-safe input and browser-category durationV
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

### One owner card per day

- Date: 2026-08-20
- Status: Implemented
- Recent daily activity shows at most one card for an owner on a local work
  date, even when logout produces several uploaded summary snapshots.
- Owner identity is the linked employee ID, otherwise the owning user ID, and
  otherwise the device ID for unassigned legacy data.
- For the same device and date, the first row in the newest-first API response
  is retained and older cumulative snapshots are discarded rather than added.
- Distinct devices belonging to that owner on the same date are combined into
  the one card. Duration totals and application/browser totals are additive;
  bounded process, USB-device, and USB-file details are de-duplicated.
- The existing API, viewer scope, date filters, privacy rules, and empty/error
  behavior remain unchanged.
- Acceptance: five same-day logout snapshots for one user render one card with
  the newest daily values; two distinct devices for that user/date also render
  one card with combined values; different users or dates remain separate.

The Activity report reuses `ErpModuleDashboard` to present recent daily
activity from the already-loaded report rows. The active-time trend, keyboard
activity graph, separate distribution card, and duplicate bottom table are
omitted from the dashboard overview. Selecting a recent activity record expands
inline with active/idle, keyboard active/idle, mouse active/idle, browser,
locked, and untracked-time graphs in place of the metric-tile grid.
Untracked time is displayed from the existing `unknown_seconds` response field;
it does not estimate unreported device time. Each graph uses only the selected
owner's already-loaded daily summaries in the current date range. The dashboard
overview must not reserve an empty analytics column or show a `No analytics
configured` card when it contains no insight cards. Each duration graph is a
separate borderless rounded surface with smooth filled mountain curves: green for the main
series and red for the companion idle series. Graph cards omit redundant
legends and point markers, show a duration timeline at the left and compact
month/day labels along the bottom, and reveal the selected day's duration
values in a visible, on-screen hover tooltip.
For a single-day range, each series draws a full-width horizontal value line
instead of leaving its one-point path invisible.
Each recent daily activity row shows a trailing down chevron while closed and
an up chevron while its inline details are open, so the selected record and its
expanded state are clear without changing the row's privacy-safe metrics.
The duration graphs remain visible whenever the daily record is open. The
Application activity, Browser tab titles, Background applications, and USB
activity sections are independently folded by default and toggle from their
icon-led headers, with directional chevrons showing their state.
The expanded view has no enclosing
outlined duration-trends container or supporting label. Input is an aggregate
keyboard/mouse duration; raw input and background-process data are not part of
the API contract. No extra API request is introduced; date filtering,
loading/error/empty behaviour, the API contract, and privacy restrictions are
unchanged.

The application details section presents the existing application totals as a
ranked report. It sorts the existing de-duplicated totals by duration, uses
readable category labels, and renders each result as a card with its duration.
It intentionally is not a table and does not calculate or display a share
percentage, so the presentation makes no claim about the entire workday or
unreported device time. The cards use three equal columns when the panel is
wide enough and stack on narrow layouts, without an enclosing outer card.
The application heading does not repeat the selected date or device label, and
classification formatting must preserve a single unclassified word.

Browser tab titles remain limited to existing foreground titles; URLs and page
content are never shown. The details view de-duplicates and ranks those titles
by duration and presents them as compact title tiles with a browser icon and
duration badge. The tiles use two columns where space permits and stack on
narrow layouts; the section heading does not repeat a supporting privacy
sentence.

Background application inventory uses the existing bounded process name and
state fields. The UI de-duplicates and orders the entries deterministically,
then displays them in a responsive four-column process grid without an
enclosing outer card; it stacks the cards on narrow layouts.

The expanded Full activity details content retains its existing background fill,
rounded shape, and internal spacing.

USB activity continues to display only the existing consented port, device, and
bounded file-metadata fields. The details view renders a concise port-status
line, responsive device cards, and compact file-change rows rather than data
tables, without an enclosing outer card. File paths remain available only as
the existing hover tooltip, and the safety-limit notice remains visible.

Super admins also receive an employee filter on Recent daily activity. The
filter uses employee identity returned with each summary, while the API remains
the source of truth for non-super-admin visibility.

## Activity Watch office monitoring detail

Status: Approved for implementation (2026-08-10)

Objective: Extend consented office-device monitoring with operational detail
without collecting input content or screen content.

Requirements:

- Record sampled keyboard-active and mouse-active duration independently when
  the operating system exposes enough signal. Derive each corresponding idle
  duration from tracked time. These values are sampled estimates, not event
  counts.
- Never record actual keys, typed text, mouse buttons, pointer coordinates,
  clipboard content, screenshots, or form/page content.
- Record the active browser window/tab title only while a recognized browser is
  foreground. Never record or upload URLs.
- Reuse encrypted local title columns and encrypted process inventory snapshots.
- Include at most 50 browser-title totals and 100 background process names in a
  daily summary. Deduplicate names case-insensitively and sort deterministically.
- Expose the fields through validated summary metadata and render them only in
  the expanded daily activity dashboard.
- Existing agents and summaries remain readable with zero/empty defaults.

Acceptance criteria:

- A new agent reports keyboard/mouse active and idle estimates separately.
- Expanded activity shows browser-title duration totals and the latest bounded
  background-process inventory for that device/day.
- Old agents continue syncing and the API accepts summaries without new fields.
- Employee/API viewer scoping remains unchanged.

## Activity Watch release and agent operations

The approved Windows/macOS build, API publication, development-installation,
agent-removal, and command procedures are maintained in
[`activity-watch-release-operations.md`](activity-watch-release-operations.md).
They must retain the backend's stable installer filenames, publish to
`billing-api/public/downloads/activity-watch`, limit unsigned macOS handling to
a hash-verified package-specific quarantine removal, and warn that removing an
agent's application-data directory permanently removes its local encrypted
queue.

The configured public installer base URL must include any deployment-specific
path prefix between the hostname and the API `public` directory. Release
verification must reject frontend HTML, error documents, and unexpectedly small
payloads even when the server reports HTTP 200. An accepted Windows response
has the executable content type and expected published size; macOS has the
expected published package size.

The macOS stable `.pkg` filename must contain a valid XAR installer archive,
never the raw Go agent or launcher Mach-O binary. Before publication,
`pkgutil --payload-files` must parse the package and list the application
bundle, launcher, agent, and `Info.plist`; both bundled executables must retain
mode `755`. The published file's SHA-256 hash must match the validated package.

## Activity Watch device-management access

Only a super administrator may revoke (disconnect) an Activity Watch device.
The disconnect action is not rendered for other users, and the authenticated
revoke endpoint rejects their direct requests. A non-super-admin Activity Watch
request remains limited by the server to devices and summaries whose `user_id`
matches the signed-in user; it must not request or render another employee's
activity. Super-admin company scope and the employee filter remain unchanged.

Acceptance criteria:

1. A super administrator can see and use Disconnect for an active device.
2. A regular user cannot see Disconnect, and a direct revoke request returns
   HTTP 403 without changing the device.
3. A regular user's devices and summaries remain limited to that user's
   employee activity.

## Activity Watch USB audit metadata

Status: Approved for implementation (2026-08-12)

Objective: Extend consented Windows and macOS Activity Watch monitoring with
bounded USB device metadata without reading file contents.

Requirements:

- USB monitoring starts only for a paired agent whose employee accepted consent
  policy version 3 or later. Existing version-2 devices continue activity
  monitoring with USB collection disabled until they are paired again.
- Report best-effort connected USB device name/manufacturer, first observed
  connection time, last observation time, and observed duration on Windows and
  macOS. Windows additionally reports total/occupied port counts, removable
  volume label/drive, and capacity/free bytes.
- Windows reports bounded removable-drive file metadata changes as `added` or
  `deleted`:
  relative path, file name, extension, byte size when known, and observation
  time. Do not claim that an added file was copied because a polling observer
  cannot prove its source.
- Never read or upload file contents, file hashes, document text, clipboard
  data, command lines, or deleted-file contents.
- The Windows scan is bounded to 5,000 files per observation and daily summaries
  contain at most 200 most-recent file events and 50 devices. A truncation flag
  tells the UI when the boundary was reached.
- USB payloads reuse encrypted `system_events` metadata and the existing daily
  summary/outbox pipeline; no additional local table is introduced.
- Linux agents and older summaries remain valid with zero/empty USB defaults.

Limitations and error handling:

- USB physical-port counts are best-effort because Windows firmware, hubs, and
  drivers do not always expose a reliable chassis-port topology.
- The initial removable-drive scan establishes a baseline and does not report
  every existing file as newly added. Short-lived changes between scans can be
  missed; the UI labels the feed as observed changes.
- A failed or timed-out USB scan does not stop ordinary Activity Watch sampling
  or synchronization.
- The Windows collector must pass its multi-statement PowerShell query through
  an encoding-safe command form so WMI filter quoting is preserved by Windows
  process argument handling, and must materialize its bounded generic file list
  before JSON projection for Windows PowerShell 5.1 compatibility. A command-
  transport or projection failure is logged as a USB scan failure and remains
  isolated from ordinary activity collection.
- The macOS collector reads bounded USB topology from
  `system_profiler SPUSBDataType -json`. It does not enumerate mounted files,
  does not report physical port totals, and remains isolated from ordinary
  activity collection if the command is unavailable.

Acceptance criteria:

1. A newly paired consent-v3 Windows agent records connected USB/removable
   device metadata and updates observed duration.
2. A newly paired consent-v3 macOS agent records connected/disconnected USB
   device metadata and updates observed duration without removable-file data.
3. Adding or deleting a file on a removable drive produces metadata-only audit
   entries without reading the file.
4. The daily Activity Watch detail shows port counts, connected devices, drive
   capacity usage, observed durations, file changes, and truncation notices.
5. Existing consent-v2 devices, agents, and summaries continue to work with USB
   fields absent or empty.

## Activity Watch super-admin company scope and employee labels

Status: Approved for implementation (2026-08-12)

Objective: Let only super administrators see company-wide Activity Watch
devices and employee activity for the selected company, with a distinct,
human-readable owner label for each summary.

Requirements:

- The Activity Watch page determines whether the signed-in user is a super
  administrator before loading devices and summaries.
- Only a super administrator requests `scope=company` for both device and
  summary endpoints and includes the current context company ID when selected.
- Company summary pages are fetched in API-sized batches until every authorized
  summary in the selected date range is available to the employee filter and
  trend calculations.
- With a selected company, records from other companies are excluded. A super
  administrator without a selected company retains the authorized all-company
  view. Every non-super-admin retains personal viewer scope.
- Summary labels use the linked employee's name and code. If a legacy device
  has no linked employee, they use its owning user's display name/username and
  keep that owner as a distinct filter value.
- Enrollment, pairing, consent, device ownership, and revoke authorization are
  unchanged.

Acceptance criteria:

1. Two super administrators using the same company context receive the
   same authorized company device and daily-summary dataset.
2. A super administrator does not receive another company's records when a company
   is selected.
3. Every non-super-admin continues to receive only their own devices and summaries.
4. Every employee or legacy device owner is visible as a separate readable
   employee-filter option.

The setup area places the Connect a computer and Devices cards side by side on
wide screens and stacks them on narrow screens below the Activity dashboard.
Devices are displayed newest first, five per local page, with older records
available through pagination; refresh, enrollment, and revoke actions reset the
device page to the newest records.

## Employee salary component grouped amounts

Status: Approved for implementation (2026-08-11)

Objective: Allow salary component amounts displayed with digit grouping to be
saved without a false numeric-validation error.

Requirements:

- Salary-component amounts such as `1,000.00` are treated as the numeric value
  `1000.00` for both client validation and API serialization.
- Empty, non-numeric, and negative values continue to be rejected where an
  amount is required.
- Salary-structure numeric fields use the same parsing rule when serialized so
  the shared formatted form controls cannot cause a related API mismatch.
- No API, database, authorization, or payroll-calculation behavior changes.

Acceptance criteria:

- A fixed component with `1,000.00` saves as numeric `1000.0`.
- A percentage-based component accepts an optional grouped amount.
- Invalid values and negative values remain invalid.

## Apply employee salary-component order to all employees

Status: Implemented (2026-08-11)

Objective: Let an HR user apply the salary-component display order configured
for one employee salary structure to every employee in the same company,
without changing any generated payroll or payslip.

Requirements:

- The Salary Components tab provides an explicit, confirmed action for each
  saved salary structure to apply its current component order to all employees.
- Only components whose normalized names occur in the source order are moved;
  components that are not in the source remain after them in their existing
  relative order. Amounts, calculation rules, contribution roles, and salary
  structures are not changed.
- The backend persists the component sequence explicitly and returns ordered
  components for employee editing and payroll calculation.
- The action is limited to the selected employee's company and requires the
  existing `hr.update` permission.
- Existing payroll lines and generated payslips are never queried, updated, or
  regenerated. The new order applies only when a future payroll/payslip is
  generated.

Edge cases and error handling:

- The source salary structure must belong to the selected employee.
- Empty source structures are rejected.
- Differences in employees' component lists are allowed; nonmatching rows are
  retained at the end.
- The request runs in a transaction; a failure leaves all component ordering
  unchanged.

Acceptance criteria:

1. A confirmed action applies Basic, HRA, and Allowance ordering from the
   selected structure to matching components in every salary structure in that
   company.
2. A target-only component remains after the matched components.
3. Existing generated payslips and payroll lines are unchanged.
4. A new payroll/payslip displays its breakup in the saved applied order.
5. Users outside the source employee's company cannot be affected.
