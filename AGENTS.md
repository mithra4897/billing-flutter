# Billing Flutter agent instructions

These instructions apply to the entire `billing-flutter` project.

## Required reading

Before a meaningful code or documentation change, read:

1. `FRONTEND_STANDARDS.md`
2. `docs/README.md`
3. the relevant sections of `docs/SPECIFICATIONS.md`, `docs/ARCHITECTURE.md`,
   `docs/DECISIONS.md`, and `docs/TESTING.md`
4. `.agents/skills/persistent-engineering-docs/SKILL.md`
5. `.agents/skills/optimize-and-reuse-code/SKILL.md`

Use the repository-local `persistent-engineering-docs` skill for features,
fixes, refactors, API/database changes, background components, architecture,
security, and workflows.

Use `optimize-and-reuse-code` for every implementation, fix, review, and
refactor.

## Code optimization and reuse

- Search existing widgets, components, helpers, services, models, styles, and
  tests before creating new code. Inspect implementations and callers with
  `rg`; do not rely only on similar filenames.
- Reuse or compatibly extend existing widgets when their responsibility and
  behavior match. If a new widget is necessary, keep its responsibility clear
  and record why reuse was unsuitable.
- Choose algorithms and data structures from actual input size, access,
  ordering, uniqueness, mutation, and latency requirements.
- Avoid repeated linear scans, accidental quadratic work, unnecessary sorting,
  unbounded loading, and duplicate database or network requests.
- For non-trivial or performance-sensitive logic, document meaningful time and
  space complexity and validate performance claims with a benchmark or
  profiler.
- Prefer clear bounded code over forced or premature optimization. Correctness,
  maintainability, and measurable behavior are required together.

## Source-of-truth order

For ERP behavior, verify sources in this order:

1. backend `install.sql` and migrations;
2. backend controllers, validation, services, repositories, and real API;
3. Flutter typed models and services;
4. Flutter screens and older documentation.

Investigate disagreements instead of inventing field names or business rules.

## Mandatory change workflow

1. Preserve unrelated user changes.
2. Inspect implementation, dependencies, tests, and documentation.
3. Write or update the specification before code.
4. Add an ADR for architecture, persistence, API, or security decisions.
5. Implement the smallest maintainable change.
6. Add or update tests.
7. Run `dart format`, `flutter analyze`, and relevant `flutter test` commands.
8. Update architecture, testing notes, and changelog.
9. Review the final diff and compare it with acceptance criteria.

Never claim a check passed unless it was executed. Report checks that could
not run and why.

## Security and privacy

- Never commit or document credentials, access tokens, refresh tokens, database
  encryption keys, or production personal data.
- Activity Watch must not capture actual keystrokes, clipboard content,
  screenshots, mouse coordinates, full browser URLs, page/form content, or
  process command-line arguments by default.
- Do not initialize monitoring or create tracking data before enrollment,
  authorization, and consent.
- Fail closed when required encryption or secure credential storage is not
  available.

## Project structure

- UI: `lib/view`, `lib/components`, `lib/widgets`
- controllers: `lib/controller`
- typed models: `lib/model`
- API and domain services: `lib/service`
- shared infrastructure and persistence: `lib/core`
- tests: `test`
- durable engineering documentation: `docs`
