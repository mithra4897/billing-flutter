# Specifications

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
