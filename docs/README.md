# Frontend Change Documentation

Maintain this folder whenever `billing-flutter` is changed.

For every meaningful frontend change, add or update a Markdown record that states:

1. Screen, user flow, state, or API contract changed.
2. User-visible business and validation rules.
3. Loading, error, and edge-case behaviour.
4. Tests and verification performed.
5. Required backend contract changes, if any.

For a backend and frontend change that belongs to one feature, use the same decision title/date in both projects and link the two records. Backend records belong in `billing-api/doc/`. The workspace-wide policy is in [`../../docs/README.md`](../../docs/README.md).

## Feature specifications

- [Activity Watch local database structure](ACTIVITY_WATCH_LOCAL_DATABASE_STRUCTURE.md) — proposed cross-platform 10-table SQLCipher MVP schema, operating-system capabilities, table purposes, encryption, retention, and recovery rules.
