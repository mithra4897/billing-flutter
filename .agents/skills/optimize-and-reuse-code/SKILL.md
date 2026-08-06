---
name: optimize-and-reuse-code
description: Improve implementations through repository-first component reuse and appropriate algorithms and data structures. Use whenever Codex implements, fixes, reviews, or refactors code in any project, especially UI/widget work, collection processing, searches, aggregation, caching, persistence, or performance-sensitive paths.
---

# Optimize and Reuse Code

Apply this workflow to every code change. Optimize for correctness,
maintainability, reuse, and relevant runtime behavior—not cleverness.

## Workflow

1. Read project instructions, architecture, standards, and relevant tests.
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

## Completion report

Report the reused components or the reason a new one was necessary. For
non-trivial logic, report the selected data structure, algorithmic complexity,
validation performed, and any remaining performance risk.
