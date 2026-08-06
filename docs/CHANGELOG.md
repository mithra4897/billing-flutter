# Changelog

## 2026-08-06 — Global code optimization and reuse skill

- Request: Apply suitable data structures and algorithms to every code change
  and reuse existing widgets when available, across projects.
- Specification: Engineering optimization and reuse policy in
  `docs/SPECIFICATIONS.md`.
- Implementation: Added the `optimize-and-reuse-code` skill and made its reuse
  and complexity review mandatory in repository instructions.
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
