# Activity Watch dashboard and summary table

Status: Implemented (2026-08-10)

## Objective

Make the Activity Watch report easy to understand at a glance through the
shared ERP dashboard pattern, while retaining a complete daily device table.

## Scope and requirements

- Keep the existing date-range filters, loading/error/empty states, summary
  API model, and privacy-safe metrics unchanged.
- Reuse `ErpModuleDashboard` for the report overview instead of creating a
  separate Activity Watch dashboard system.
- Show active, idle, browser, and tracked duration KPI cards; an active-time
  daily trend; recent daily activity records; and input/device/application
  highlights from the already-loaded summaries. Omit the separate distribution
  card.
- Limit the chart to the latest 12 reporting days when a selected range has
  more daily buckets, while keeping KPI totals and the detailed table scoped to
  the complete selected range.
- On wide screens, place the Connect a computer and Devices cards in one equal
  two-column row; stack them below the responsive breakpoint.
- Place that setup-card row below the Activity dashboard so the report is the
  first operational section users see.
- Show five newest devices per page in the Devices card and use the shared
  local pagination control for older devices. Refreshing, enrolling, or
  revoking a device returns the list to its first page.
- Aggregate dashboard totals in one bounded pass over summaries and application
  totals, then sort only the distinct daily trend buckets. Do not issue another
  API request for dashboard data.
- Display one row per returned daily device summary with date, device, active,
  idle, input, browser, locked, offline, unknown, and tracked durations.
- Make Recent daily activity records the entry point to full details. Selecting
  a record opens a dialog with its activity metrics and application totals.
  Remove the duplicate bottom activity table.
- On wide screens, let the Activity report card use the complete available
  shell content width. Keep the enrollment, pairing, credential, and device
  cards constrained to their existing readable width.
- Present the report header as one responsive toolbar: title and supporting
  text on the left, with the date-range controls aligned to the right when
  space permits.
- Keep daily rows compact and remove selection checkboxes. The selected row may
  use the shared subtle highlight only to identify the open application panel.
- Place both tables inside rounded, bordered surfaces using the existing table
  theme colors. The application breakdown must appear as a clearly separated
  details panel with its own heading and close action.
- Permit horizontal scrolling when the available width cannot fit all columns;
  do not hide duration values or change the server request.
- Preserve the existing human-readable duration format and show a clear empty
  message when no application totals are available.
- Label input as an aggregate keyboard/mouse activity duration. Do not expose
  raw keystrokes, clicks, coordinates, or an unprovided background-process list.

## Acceptance criteria

- The initial Activity view is a labelled table with consistently aligned
  daily metrics rather than a stacked list of text blocks.
- The dashboard uses the same reusable visual structure as other ERP module
  dashboards and responds from four KPI columns down to one.
- Dashboard values and the detailed table come from the same loaded summary
  collection and selected date range.
- Selecting a recent activity record reveals active, idle, aggregate
  keyboard/mouse input, browser, locked, offline, unknown, tracked, and
  application totals in the full-details dialog.
- Super admins get an employee filter on Recent daily activity and can switch
  between all employees and each employee represented in the report. Other
  users see only the employee scope enforced by the Activity Watch API.
- At desktop widths, the Activity table fills the page content area rather
  than being limited by the setup-card width.
- The daily table has no checkbox column or oversized empty row area, and the
  application breakdown is visually distinct from the daily table.
- Date filtering, loading, errors, and empty responses retain their current
  behaviour.
- The change is presentation-only: no Activity Watch API, storage, consent, or
  data-collection behaviour changes.

## Verification

- `dart format lib/view/settings/activity_watch/activity_watch_setup_page.dart`:
  completed with no further changes.
- Focused Activity Watch dashboard and model tests passed all 6 tests.
- `flutter test`: passed all 54 tests.
- `flutter build web`: passed.
- `flutter analyze`: completed with only the two pre-existing unrelated
  warnings in `lib/app/constants/app_config.dart` and
  `lib/view/crm/crm_followups_page.dart`.
- The supplied desktop screenshot was used to identify the automatic checkbox
  column and oversized selected row; the supplied dashboard reference guided
  reuse of the ERP dashboard structure. Final browser verification at desktop
  and narrow widths remains manual.
