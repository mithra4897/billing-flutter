# Activity Watch summary table

Status: Implementing (2026-08-07)

## Objective

Make the Activity Watch report easy to scan by presenting each daily device
summary as a table row instead of a vertically expanded card.

## Scope and requirements

- Keep the existing date-range filters, loading/error/empty states, summary
  API model, and privacy-safe metrics unchanged.
- Display one row per returned daily device summary with date, device, active,
  idle, input, browser, locked, offline, unknown, and tracked durations.
- Keep the primary daily table compact. An Applications action opens a second,
  compact application-totals table directly below the selected daily row set.
- Permit horizontal scrolling when the available width cannot fit all columns;
  do not hide duration values or change the server request.
- Preserve the existing human-readable duration format and show a clear empty
  message when no application totals are available.

## Acceptance criteria

- The initial Activity view is a labelled table with consistently aligned
  daily metrics rather than a stacked list of text blocks.
- Selecting Applications reveals only that daily row's application breakdown;
  selecting it again closes the breakdown.
- Date filtering, loading, errors, and empty responses retain their current
  behaviour.
- The change is presentation-only: no Activity Watch API, storage, consent, or
  data-collection behaviour changes.

## Verification

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart`:
  passed.
- `flutter test test/model/activity_watch_model_test.dart`: passed (4 tests).
- `flutter analyze`: completed with only the pre-existing unrelated warnings in
  `lib/app/constants/app_config.dart` and
  `lib/view/crm/crm_followups_page.dart`.
- Manual verification at desktop and narrow widths in Flutter web remains
  pending.
