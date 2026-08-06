---
name: persistent-engineering-docs
description: Maintain durable engineering documentation for this ERP frontend. Use for every feature, bug fix, refactor, API or database change, background worker, architecture decision, security change, or workflow modification that requires specifications, decisions, tests, compatibility notes, or changelog records.
---

# Persistent Engineering Docs

Use `AGENTS.md` and `docs/` as the project source of truth. Read
[`references/engineering-documentation-rules.md`](references/engineering-documentation-rules.md)
before making a meaningful change.

## Workflow

1. Inspect the affected implementation, dependencies, APIs, schema, tests, and
   existing documentation.
2. Write or update the specification before implementation.
3. Identify ambiguities and request direction before making high-impact
   assumptions.
4. Record an ADR for durable architecture, storage, API, or security decisions.
5. Implement the smallest maintainable change and preserve unrelated work.
6. Add or update tests and execute relevant formatting, analysis, and tests.
7. Update architecture, testing notes, changelog, and compatibility or
   migration impact.
8. Compare the result with each acceptance criterion and report untested areas.

## Non-negotiable rules

- Never document credentials, tokens, or secret keys.
- Never claim a test passed unless it was executed.
- Never change behavior without updating its specification and changelog.
- Never change architecture without an ADR and architecture update.
- Keep documentation factual: implemented or explicitly approved behavior only.
- Do not overwrite unrelated user changes.

