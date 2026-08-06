# Architecture decisions

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

