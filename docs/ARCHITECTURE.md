# Architecture

## Activity Watch self-service pairing

```mermaid
sequenceDiagram
    participant Employee as "Employee in ERP Web"
    participant API as "ERP pairing API"
    participant File as ".billingawpair file"
    participant Agent as "Installed Go agent"
    Employee->>API: Create pairing session (auth + consent)
    API-->>Employee: 10-minute token + pairing URL
    Employee->>File: Download versioned bundle
    Employee->>Agent: Open bundle through OS file association
    Agent->>Agent: Provision encrypted storage if absent
    Agent->>API: Token + locally generated credential
    API->>API: Lock device row; hash credential
    API-->>Agent: Device ID + batch URL
    Agent->>Agent: Protected writes; enable and restart service
```

Pairing state reuses `activity_watch_devices`; no fourth Activity Watch table is
introduced. Token lookup uses a unique hash and transactional row lock. The
browser handles only the short-lived token. Per-platform signed installers
register the pairing file and bootstrap a disabled service that cannot collect
until pairing succeeds.

## Activity Watch desktop runtime

The implemented desktop runtime is a Go user-service executable under
`activity-watch-agent`. It is managed in the enrolled user's login context by
Windows, launchd, or the Linux service manager and remains independent of the
Flutter application's lifecycle while that OS session exists.

```mermaid
flowchart LR
    OS["User login/service manager"] --> Service["Go Activity Watch service"]
    Flutter["Authorized Flutter enrollment"] -->|"protected config + credential"| Service
    Service --> DB["SQLCipher 10-table database"]
    Service --> Outbox["Indexed sync_outbox batches"]
    Outbox -->|"device credential + idempotency"| ERP["ERP Activity Watch API"]
    Logout["ERP or OS logout"] -->|"finalize summary + flush"| Service
    Shutdown["OS shutdown"] -->|"bounded final flush"| Service
```

### Runtime responsibilities

- Service host: install/start/stop integration and bounded lifecycle callbacks.
- Worker: coordinate collection, immediate flush requests, periodic sync, and
  graceful shutdown.
- Store: apply the SQLCipher key first, verify cipher/schema, and transact each
  approved lifecycle event with its pending outbox record. It is the business
  writer and uses the tested encrypted WAL configuration; helpers must not
  open the database directly.
- Collector: use bounded OS commands/APIs to return idle duration, lock state,
  foreground executable identity/category, foreground browser title,
  process/service names, and content-free keyboard/pointer activity signals.
  Missing capabilities return empty/zero observations. No input value, click,
  coordinate, URL, screenshot, clipboard, or page content crosses this boundary.
- Store/aggregator: consolidate state/application/input samples, encrypt browser
  titles and inventory payloads, produce bounded daily title/process projections,
  generate revisioned summaries, and purge synchronized data after 90 days.
- Syncer: select bounded indexed batches, upload encrypted payloads plus their
  approved reporting projection, acknowledge successes, and schedule retries.
- Secret provider: supply database and device credentials without placing them
  in configuration or logs.
- Provisioner: generate and publish a new encrypted database/key pair only
  when both configured targets are absent. It builds files under protected
  temporary names and uses no-replace publication to avoid overwriting data.
- Flutter service control: retain only installed executable/configuration paths
  in secure storage and issue a bounded `signal-logout` command during native
  ERP logout. Failure never blocks normal ERP session clearing.

### Recovery and intervention

- An unexpected worker failure exits non-zero so the configured service-manager
  restart policy can recover pending outbox records from SQLCipher.
- Retryable failures retain data and use capped backoff.
- Revoked/invalid device credentials require re-enrollment. Authentication-only
  permanent failures are requeued when the service restarts with a new device
  credential.
- Missing consent, key, or compatible schema prevents collection.
- Server ingestion validates ciphertext/checksums and stores only approved
  summary metadata for authenticated, user/company-scoped reports.

## Existing Flutter application

`billing-flutter` is a route-first Flutter ERP client for web, mobile, and
desktop. Screens live under `lib/view`, controllers under `lib/controller`,
typed data under `lib/model`, API services under `lib/service`, and shared
infrastructure under `lib/core`. It communicates with the sibling Lumen API
under `/api/v1` and stores normal ERP session state separately.

### HR salary-component order propagation

The Employee Salary Components tab sends the selected employee and salary
structure to the authenticated HR API only after confirmation. The API derives
the component-name order from that saved structure, updates the explicit
`sort_order` field of matching salary components belonging to employees in the
same company, and returns the number of affected structures and components.
Unmatched target components retain their relative order after matched rows.
Employee and payroll relations load components by `sort_order`, then `id` for
legacy zero-order rows. Payroll lines and payslips are separate persisted
records and are deliberately not read or mutated by this operation.

### Party-code editing flow

The Parties page owns the remote lookup required to find codes already used by
the target prefix across all party types, matching the database's global
`party_code` unique key. Pure lookup-filter, prefix, next-number, original-type
restoration, and async-refresh validation rules live in
`helper/party_code_helper.dart` so they can be tested without constructing the
full page. A monotonically increasing request token on the page prevents an
older type lookup from overwriting the code for a newer selection. The backend
remains responsible for final global uniqueness validation when the party is
saved. Selecting an existing party also compares its generated-code prefix
with its saved type and prepares a corrected value when legacy data is
inconsistent.

## Activity Watch local persistence

Activity Watch persistence is an opt-in native subsystem under
`lib/core/activity_watch`. Normal application startup does not open the
database. An enrollment/consent workflow must explicitly construct the manager
and request a database context.

```mermaid
flowchart LR
    Caller["Authorized Activity Watch runtime"] --> Manager["Database manager"]
    Manager --> KeyStore["Platform secure key store"]
    Manager --> Path["Application-support path"]
    Manager --> Cipher["SQLCipher database"]
    Cipher --> Schema["Versioned 10-table schema"]
    Caller --> Payload["AES-GCM / HMAC helper"]
    Caller --> Tx["Database transactions"]
```

### Component responsibilities

- Key store: generate or load three independent 256-bit keys without exposing
  them to logs or configuration files.
- Database path provider: choose a private application-support directory.
- Database manager: reject web, load keys, open SQLCipher, and return a
  lifecycle context.
- Database connection: apply the key first, verify SQLCipher, configure
  durability/privacy pragmas, create/migrate schema, and expose transactions.
- Payload cipher: encrypt/decrypt sensitive BLOB values with AES-256-GCM and
  generate keyed identifier HMACs.
- Context: own the connection and key buffers and dispose them together.

### Failure and recovery

- SQLCipher or secure-store unavailability fails closed.
- Schema creation/migration is transactional.
- A database with a newer schema version is not opened.
- Wrong-key and integrity failures occur before business writes.
- Caller transactions roll back on exceptions.
- Full activity segment crash repair belongs to the later collection layer.

### Human intervention

- Enrollment and consent are required before initialization.
- Lost secure-store keys require device re-enrollment; local encrypted data is
  intentionally unrecoverable.
- Platform permission denial is handled by later capability adapters and must
  be shown to the employee/administrator.
