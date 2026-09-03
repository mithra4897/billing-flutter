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

If a required file or skill is unavailable, report the gap before
implementation; do not silently skip project guidance.

## Pre-implementation verification gate

Before writing code:

1. Define the requested behavior and acceptance criteria.
2. Inspect relevant implementation, dependencies, callers, tests, and docs.
3. Use `rg` to locate existing widgets, components, helpers, services,
   controllers, models, styles, utilities, and tests that provide any part of
   the required behavior; record what will be reused or why a focused new
   component is needed.
4. Identify real input size, access pattern, ordering, uniqueness, mutation,
   and latency constraints, then choose the simplest correct data structure
   and algorithm.
5. Check for repeated scans, nested work over growing collections, unnecessary
   sorting/loading, redundant rebuilds, and duplicate network/database work.
6. Inspect asynchronous control flow for nested continuations, missing
   cancellation or mounted checks, duplicate submissions, races, and unsafe
   widget-context use after an async gap.
7. Confirm the planned diff is limited to files required by the task.

Do not invent field names, API behavior, business rules, or performance
requirements.

## Code optimization and reuse

- Every implementation must explicitly consider and apply the appropriate data
  structures and algorithms (DSA) for its real inputs, access patterns, and
  performance constraints. Prefer the simplest correct optimized approach;
  document the chosen complexity whenever the logic is non-trivial.
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
- Prevent duplicate requests; reuse in-flight or cached values only when
  lifecycle, invalidation, freshness, and tenant scope are correct.
- Validate measurable performance claims with a benchmark, profiler, or
  representative test; never claim an optimization without evidence.

## Flutter UI and production readiness

- Extract a focused widget only for a reusable visual pattern, distinct UI
  section, or a block with independent state, loading, error, or empty
  behavior. Prefer composition and typed parameters over duplicated screens or
  broad boolean-configured widgets.
- Keep fetching, persistence, business logic, and navigation orchestration out
  of presentation widgets. Keep callbacks typed and shallow; use named
  async/await operations with early returns rather than nested continuations.
- Guard async UI updates with the appropriate mounted or lifecycle check and
  verify relevant loading, empty, success, error, retry, disabled, and
  duplicate-tap states.
- Completed work must handle relevant validation, nullability, failures,
  timeouts, cancellation, retries, idempotency, and concurrency. Do not leave
  swallowed exceptions, debug prints, dead/commented code, mocks, TODOs, or
  unapproved compatibility breaks.
- Keep tenant, company, branch, user, and authorization boundaries intact;
  do not log secrets, tokens, personal data, or sensitive payloads.
- Keep dependencies minimal and justify a new dependency's maintenance,
  licensing, platform support, and size impact.

## Naming and minimal-change policy

- Use concise, domain-accurate names. Avoid vague names such as `data`,
  `item`, `temp`, `value`, `result`, or `manager` when the role can be named
  clearly. Boolean names must state their condition, such as `isLoading` or
  `canRetry`.
- Functions and classes/widgets must each describe one responsibility. Favor
  clarity at the call site over shortening a name until it is ambiguous.
- Modify only code and documentation required for the approved request. Do not
  perform unrelated cleanup, renames, formatting, upgrades, or refactors.
  Explain and minimize any necessary cross-boundary change.

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

Every implementation report must state: delivered behavior; reused/extended
code; any new component and why reuse was unsuitable; data-structure/algorithm
choice and non-trivial complexity; files changed; validation executed; checks
not run and why; and remaining risks or follow-up work.

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
