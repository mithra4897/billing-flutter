# Activity Watch dashboard and summary table

Status: Implemented (2026-08-10)

## Objective

Make the Activity Watch report easy to understand at a glance through the
shared ERP dashboard pattern, while retaining a complete daily device table.

## Scope and requirements

- Keep the existing date-range filters, loading/error/empty states, summary
  API model, and privacy-safe metrics unchanged.
- Parse Activity Watch integer fields whether the API serializes them as JSON
  numbers or numeric strings; a legacy serialization difference must not block
  the dashboard or device panel from loading.
- Reuse `ErpModuleDashboard` for the report overview instead of creating a
  separate Activity Watch dashboard system.
- Show recent daily activity records from the already-loaded summaries. Omit
  the active-time trend, keyboard activity graph, and separate distribution
  card.
- When a recent activity record is expanded, replace its daily metric tiles
  with active/idle, keyboard active/idle, mouse active/idle, and browser-time
  graphs for that device in the selected date range. Each active series uses a
  strong color and the companion idle series uses a light color.
- Render every duration graph inside its own rounded card with smooth filled
  mountain curves, using green for main duration series and red for idle series.
- Omit redundant legends and date labels, retain a left duration timeline, and
  show the selected day and duration values when the user hovers a graph.
- Do not wrap the graph set in an additional outlined container or show an
  `Activity duration trends` heading; only the individual graph cards remain.
- When an overview supplies only a primary activity list, it must use the full
  available width without rendering the empty analytics configuration state.
- On wide screens, place the Connect a computer and Devices cards in one equal
  two-column row; stack them below the responsive breakpoint.
- Keep the activity list above the setup-card row, while omitting the standalone
  Activity dashboard header bar.
- Show five newest devices per page in the Devices card and use the shared
  local pagination control for older devices. Refreshing, enrolling, or
  revoking a device returns the list to its first page.
- When the responsive setup row gives the Devices card a bounded height, keep
  its paged content vertically scrollable so device rows and navigation remain
  reachable without a RenderFlex overflow.
- Do not issue another API request for dashboard data.
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
  dashboards while showing the recent daily activity list without an active
  trend graph.
- Dashboard values and the detailed table come from the same loaded summary
  collection and selected date range.
- Selecting a recent activity record expands an inline full-details dashboard
  with all activity-duration graphs and application totals.
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

- Verification for the active-trend removal is recorded in `TESTING.md`.
