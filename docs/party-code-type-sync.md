# Party code synchronization when party type changes

## Status

Approved for implementation on 2026-08-06.

## Problem and objective

Party codes are read-only and generated from the selected party type. Editing
an existing Supplier and changing its type to Customer currently leaves the
old `SUP/...` code in place. That stale code can then block creation of the
next Supplier with "Party code already exists."

Keep the displayed and submitted party code synchronized with the selected
party type during both create and edit flows.

## Scope and business rules

- A user-initiated party-type change regenerates the read-only party code for
  the newly selected type.
- Opening a party whose generated-code prefix does not match its saved type
  prepares a corrected code so the existing bad record can be repaired by
  saving it.
- The generator continues to use the existing PARTY document-series settings.
- Used-code lookup is global because `parties.party_code` is globally unique.
  It searches by the target code prefix across every party type; it must not
  filter by `party_type_id`, because an inconsistent Customer may still own a
  `SUP/...` code.
- If an editor changes a saved party away from its original type and then
  changes it back before saving, restore the saved party code instead of
  consuming a new-looking number.
- If multiple type changes occur while code lookups are in flight, only the
  result for the latest selected type may update the field.
- Save waits for a correction when the displayed prefix does not yet match the
  selected type, covering an immediate save while lookup is still in flight.
- Existing API validation and the global unique `parties.party_code` database
  constraint remain unchanged.

## Inputs, outputs, and errors

- Input: the selected party-type identifier and the currently selected party.
- Output: a code using the selected type prefix and the next available number,
  or the selected party's saved code when returning to its original type.
- If the remote lookup fails, generation falls back to the parties already
  loaded on the page, matching existing behavior.
- Save-time uniqueness errors continue to be shown by the existing form error
  path in case another user creates the same code concurrently.

## Security and compatibility

No credentials, permissions, API fields, or database schema change. Existing
party IDs and related records are preserved; only the editable party's code is
updated when the party record is saved.

## Acceptance criteria

1. Changing an existing `SUP/...` Supplier to Customer displays and saves a
   `CUS/...` code.
2. The old `SUP/...` value is released after save, so a new Supplier can use
   the next available Supplier code without colliding with that party.
3. Switching an unsaved edit back to its original type restores its original
   code.
4. Rapid type changes cannot apply a code generated for an older selection.
5. New-party code generation continues to work as before.
6. Opening an existing Customer with a `SUP/...` code prepares a `CUS/...`
   replacement for save.
7. If a Customer still owns `SUP/0106`, creating a Supplier proposes at least
   `SUP/0107` instead of retrying the globally occupied `SUP/0106`.

## Required verification

- Unit tests for global prefix lookup, cross-type collisions, type-change code
  selection rules, and the stale-request guard.
- `dart format` on changed Dart files.
- Focused `flutter test` for the new regression tests.
- `flutter analyze` for static validation.
