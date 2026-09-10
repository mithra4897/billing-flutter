# Company timezone dropdown — 2026-09-10

The Company primary form uses the existing searchable `AppDropdownField` for
the persisted `timezone` API field. It offers a curated list of common IANA
timezone identifiers, defaults to `Asia/Kolkata`, and retains an existing saved
timezone that is not in the curated list. No API, schema, permission, or
company-context behavior changes.

The list is a bounded static collection: rendering is O(n) for the small option
set and selection uses the shared field's existing value resolution. No network
request or new dependency is introduced.
