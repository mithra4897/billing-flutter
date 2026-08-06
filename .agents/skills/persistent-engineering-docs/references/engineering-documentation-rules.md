# Engineering documentation rules

## Required documentation

Maintain these project files when applicable:

- `docs/README.md`: project documentation index and operating notes.
- `docs/SPECIFICATIONS.md`: objective, scope, requirements, rules, validation,
  edge cases, security, acceptance criteria, and required tests.
- `docs/ARCHITECTURE.md`: actual and explicitly approved components, data flow,
  persistence, integrations, authentication, and recovery behavior.
- `docs/DECISIONS.md`: append-only architecture decision records.
- `docs/TESTING.md`: strategy, commands, manual verification, environments, and
  known untested areas.
- `docs/CHANGELOG.md`: meaningful code changes, effects, validation, limitations,
  and follow-up work.

## Specification rules

Before implementation:

1. State the problem and objective.
2. Separate in-scope and out-of-scope work.
3. Define functional requirements and business rules.
4. Define inputs, outputs, validation, edge cases, and error handling.
5. Define security and privacy constraints.
6. Define acceptance criteria and tests.
7. Resolve high-impact ambiguity before changing behavior.

## Background component rules

For agents, workers, services, queues, schedulers, or automated pipelines,
document:

- responsibility;
- inputs and outputs;
- permissions and limitations;
- communication paths;
- retry and timeout behavior;
- crash and offline recovery;
- safe logging; and
- human approval or intervention points.

Use the fewest components that safely satisfy the requirement and record why
the chosen architecture was selected.

## ADR format

```markdown
## ADR-XXXX: Decision title

- Date:
- Status: Proposed | Accepted | Superseded
- Context:
- Decision:
- Reason:
- Alternatives considered:
- Consequences:
- Related files:
```

Never remove ADR history. Mark obsolete decisions as superseded and reference
their replacements.

## Changelog format

```markdown
## YYYY-MM-DD — Change title

- Request:
- Specification:
- Implementation:
- Files changed:
- Database/API impact:
- Security impact:
- Tests added or updated:
- Tests executed and results:
- Documentation updated:
- Known limitations:
- Follow-up work:
```

## Completion checklist

1. Read `AGENTS.md` and relevant documentation.
2. Inspect the existing code and dependencies.
3. Update the specification.
4. Identify affected code, APIs, database tables, tests, and documentation.
5. Present a plan when work is large, risky, destructive, or architectural.
6. Implement the smallest maintainable change.
7. Add or update automated tests.
8. Run formatting, analysis, builds, and focused tests.
9. Fix failures caused by the change.
10. Update documentation and changelog.
11. Review the final diff for accidental or undocumented behavior.
12. Report changes, validation, risks, and remaining work.

