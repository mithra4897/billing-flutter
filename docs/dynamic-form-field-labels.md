# Dynamic form field labels — 2026-09-04

Status: Implemented

The shared form wrappers now remove legacy `(optional)` suffixes and append a
red `*` for explicit `isRequired` flags or the built-in required-validator
factories. Required-validator metadata is carried through composed validators
with a weak `Expando`, preserving existing callers and validation behavior. The
focused label builder uses a single regex replacement per label, so its time
and space cost are O(n) in the label length.

The design intentionally changes only shared `AppFormTextField`, `ErpLinkField`,
`AppDropdownField`, and `ValidatedFormTextField` paths. Raw fields and unrelated
custom decorations remain out of scope. Widget tests cover suffix cleanup,
required-marker styling, and forwarding through the validated wrapper.
