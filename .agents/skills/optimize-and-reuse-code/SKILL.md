---
name: optimize-and-reuse-code
description: Improve all project code through repository-first component reuse and appropriate algorithms and data structures. Use whenever Codex implements, fixes, reviews, or refactors code in any codebase—not only Activity Watch or Flutter—especially UI/widget work, collection processing, searches, aggregation, caching, persistence, or performance-sensitive paths.
---

# Optimize and Reuse Code

Apply this workflow to every code change in every project. It is not specific to
Activity Watch, ERP, or Flutter. Optimize for correctness, maintainability,
reuse, and relevant runtime behavior—not cleverness.

## Workflow

1. Define requested behavior and acceptance criteria; read project
   instructions, architecture, standards, and relevant tests. Report a missing
   required instruction or skill before implementation.
2. Search the repository before creating a widget, component, helper, service,
   model, style, validation rule, or utility. Inspect definitions and callers,
   not names alone.
3. Reuse or configure an existing abstraction when its responsibility and
   behavior match. Extend it compatibly when the new behavior is genuinely
   shared.
4. Create a new abstraction only when existing code has a different purpose,
   reuse would break its contract, or coupling would become worse. Record the
   reason in the specification or change summary.
5. Identify input size, access patterns, ordering needs, uniqueness, mutation,
   latency constraints, and likely hot paths.
6. Select algorithms and data structures that fit those requirements. State
   meaningful time and space complexity for non-trivial or performance-sensitive
   logic.
7. Implement the smallest clear solution and preserve unrelated behavior.
8. Test correctness and important boundary sizes. Benchmark or profile before
   claiming a performance improvement.

Before coding, also confirm the planned diff is task-scoped and inspect async
flows for unsafe context use after gaps, nested continuations, missing
cancellation, duplicate submissions, and races. Do not invent API contracts,
business rules, field names, or performance constraints.

## Data-structure and algorithm rules

- Prefer `Set` for repeated membership or uniqueness and `Map` for keyed lookup
  instead of repeated linear scans when input size makes indexing worthwhile.
- Use queues, stacks, heaps, trees, graphs, sorted collections, or streaming
  only when their semantics match the problem; do not force a named DSA into
  simple code.
- Avoid accidental quadratic work, repeated parsing, repeated sorting,
  unbounded recursion, unnecessary copying, and loading unbounded data.
- Batch database and network operations, paginate large results, and use
  indexes that match real query filters and ordering.
- Consider memory and allocation costs alongside runtime complexity.
- Preserve readability when a simpler approach is already fast enough for
  bounded inputs. Document intentional complexity tradeoffs.
- Prevent duplicate network/database work. Reuse an in-flight or cached result
  only when its lifecycle, invalidation, freshness, and tenant scope are
  correct.

## UI and widget reuse

- Search shared UI locations, feature-local widgets, themes, design tokens,
  form controls, tables, dialogs, loaders, empty states, and error states before
  adding UI code.
- Prefer parameters, composition, and small compatible extensions over copied
  widgets or near-duplicate variants.
- Do not turn an unrelated widget into a generic abstraction merely to avoid a
  new file.
- In Flutter, minimize rebuild scope; use `const`, lazy builders, stable keys,
  and state isolation where they are semantically correct and measurable.
- Preserve accessibility, validation, responsive behavior, localization, and
  existing visual conventions when reusing components.
- Extract a focused widget for a reusable visual pattern, distinct UI section,
  or independently stateful/loading/error/empty block. Do not create a generic
  abstraction for a single speculative use.
- Keep fetching, persistence, business logic, and navigation orchestration out
  of presentation widgets. Prefer typed parameters, composition, named
  async/await operations, early returns, and mounted/lifecycle checks over
  nested callbacks.

## Production and clarity checks

- Handle relevant validation, nullability, failures, timeouts, cancellation,
  retries, idempotency, and concurrency; do not leave mocks, swallowed errors,
  debug prints, dead/commented code, or unresolved TODOs.
- Preserve authorization and tenant/company/branch/user boundaries. Never log
  secrets, tokens, personal data, or sensitive payloads.
- Use concise domain names; avoid vague names when the role is knowable, and
  name booleans for their condition. Keep each function/class/widget focused on
  one responsibility.
- Keep changes task-scoped. Explain a necessary cross-boundary change and do
  not combine it with unrelated cleanup or upgrades.

## Completion report

Report delivered behavior, reused components or why a new one was necessary,
data-structure/algorithm choice and non-trivial complexity, files changed,
validation performed, checks not run and why, and remaining risks or follow-up
work.
