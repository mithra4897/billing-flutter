# Specifications

## Project overview and detail workspace — 2026-09-05

Status: Implemented

Projects gain a display-only Kanban overview and a route-addressable detail
workspace. The Projects page reuses the loaded `ProjectManagementController`
data for search and project cards. Cards open a full Project detail page with
overview, Tasks, Milestones, Timeline,
Billing, and Vendor Works tabs. Embedded child pages retain their existing
project constraint and permission behavior.

The existing `/projects` navigation entry is the Kanban overview. Selecting a
project card must open that project’s detail Overview; `/projects?new=1`
continues to open the existing Project editor for creation.

The dashboard remains the only location for cross-project aggregate metrics;
the Projects Kanban has no separate status-filter bar. No model, API,
persistence, or authorization changes are required.

## Sales invoice settlement after sales returns — 2026-09-05

Status: Implemented

- `paid_amount` represents only posted customer receipt/advance allocations. A
  sales-return credit note reduces the invoice balance but is not customer
  payment.
- A posted invoice with no receipt allocation is Payment pending unless it is
  overdue or has a posted return.
- A fully returned invoice is Returned. An invoice with any returned quantity
  below the invoiced quantity is Partially returned. These return states take
  precedence over Paid, Partially paid, Payment pending, and Overdue.
- The invoice balance is reduced by all valid posted settlements, including
  receipt allocations and sales-return credit-note adjustments.
- A new sales-return adjustment is limited to the invoice's remaining balance.
  Any excess credit remains on the return voucher as customer credit instead
  of over-settling the invoice.
- Sales invoice filters expose Partially returned and Returned and must not
  include either state in Paid or other payment-state results.
- Existing live records are changed only through an explicit, dry-run-first
  reconciliation command. Reconciliation changes settlement metadata and
  derived invoice fields only; it never rewrites voucher debits or credits.

Acceptance cases:

1. A 10,000 Payment-pending invoice with a 3,000 posted return has paid amount
   0, balance 7,000, and status Partially returned.
2. A fully returned 10,000 invoice has status Returned even when its balance is
   zero.
3. A 10,000 invoice with a 4,000 receipt and a 2,000 return has paid amount
   4,000, balance 4,000, and status Partially returned.
4. A return posted after the invoice is already fully settled creates customer
   credit but no invoice allocation.

## Sales Proforma Invoice print bindings — 2026-09-05

Status: Implemented

Sales Proforma Invoice print data exposes the same standard binding keys as
Sales Invoice: line discount label/percent/amount, tax summary labels and
currencies, discount and round-off summary values, `adjustment_amount`, tax
totals, taxable total, direct-customer flag, amount in words, and draft
watermark. Proforma-specific document number, date, status, and tax totals
remain sourced from the Proforma editor.

The Proforma payload does not invent invoice-only adjustments; it publishes
`adjustment_amount` as zero for template compatibility.

## Dynamic form field labels — 2026-09-04

Status: Implemented

Shared text, link, and dropdown fields render cleaned labels through one
utility. It removes case-insensitive parenthesized optional suffixes matching
`\\s*\\(optional.*?\\)` and appends a red `*` when `isRequired` is true or a
built-in required-validator factory is detected. `isRequired` defaults to
`false`, so existing callers remain compatible and validation behavior is
unchanged. Null or empty labels produce no label.

Acceptance criteria:

1. Required shared fields show a red `*`.
2. Legacy optional suffixes are not displayed.
3. Floating-label rendering continues to use the existing field style.
4. Widget tests cover cleanup, styling, and forwarding.

## Project Head task monitoring — 2026-09-04

Status: Implemented

Users with `project_head.access` can view all projects in the selected company
context and all tasks nested under those projects, including tasks assigned to
other employees. Ordinary employees continue to see only projects containing
their assigned tasks and only their assigned task records. Project Head access
changes visibility only; task mutation permissions remain governed by the
existing Project create/update/delete permissions.

## Shared centered dialog presentation — 2026-09-04

Status: Implemented

Filter panels and project task editors use a centered `AppDialog` shell with a
themed header, close action, divider, scrollable content, and optional sticky
actions area. Existing responsive `SettingsFormWrap` layouts remain in place;
the dialog changes presentation and spacing without changing form behavior,
validation, save flows, or filter semantics. Existing confirmation/detail
dialogs are out of scope for this focused migration.

The Project task dialog uses two equal-width responsive columns across the
available content width and collapses to one column below the existing mobile
breakpoint. Its editor subscribes to the task controller while open, so
Billable, saving, validation-error, and other controller-driven states update
inside the modal immediately.

## Project task priority badges — 2026-09-04

Status: Implemented

Project tasks persist one required priority value: `low`, `medium`, `high`, or
`critical`. New tasks default to `medium`; the editor exposes the four values
next to Task Status. Existing task list tiles and Kanban cards display the
priority through the shared `AppStatusBadge` in the header. Kanban filtering
and sorting remain status-based and are out of scope.

The API accepts priority on task create and update and rejects other values.
Existing rows are backfilled by the database default. Display mapping uses
theme tokens: success green for Low, warning for Medium, error for High, and the
dark error foreground token for Critical.

## Project task Kanban status and role restrictions — 2026-09-04

Status: Implemented

Project tasks persist six statuses: `open`, `working`, `in_review`, `completed`,
`on_hold`, and `cancelled`. `in_review` is a distinct review stage; `on_hold`
is retained as a separate paused state. Existing `on_hold` tasks are not
rewritten.

- Normal assigned users see Open, Working, In Review, and Completed columns.
  They cannot create or delete tasks, edit task details, move a completed task,
  or move a task into Completed, On Hold, or Cancelled.
- Normal assigned users may update only the status of their own non-completed
  task to Open, Working, or In Review. Progress remains status-derived.
- Project Heads (`project_head.access`) and Super Admins see all six columns
  and retain full create, edit, delete, and status-transition access.
- The Flutter UI must make detail fields read-only for normal users, while the
  API remains authoritative and discards/rejects restricted mutations.
- Standalone Task Kanban creation and lane-plus actions are management-only.

Acceptance criteria:

1. `in_review` appears as an independent Kanban/status/filter value; `on_hold`
   displays as “On Hold”.
2. Role-specific columns and drag restrictions follow the rules above.
3. Normal user task updates cannot alter fields other than an allowed status,
   even when sent directly to the API.
4. Schema, API validation, status-progress logic, Flutter model/controller, and
   Kanban presentation accept the same six values.
5. Focused backend/Flutter tests cover status and role gates.

## Project board presentation — 2026-09-04

Status: Implemented

The standalone Projects route uses the Project Tasks Kanban visual language:
status lanes, task-style cards, a persistent bottom scrollbar, top-app-bar
project search, shared filters, and card selection. Existing fields, scoped
loading, child tabs, validation, and save APIs remain unchanged. Cards are
selection-only; Project Status remains editable only in the existing form.

Acceptance criteria:

1. Projects are grouped into persisted-status lanes after the existing filters
   and top-app-bar search have been applied.
2. Selecting a project opens the existing multi-tab editor in `AppDialog`.
3. No new request, data source, or status drag/drop mutation is introduced.
4. The view reuses `ProjectKanbanBoard` and is covered by focused tests.

## Project register readability

Status: Implemented (2026-09-03)

### Problem and objective

Project registers exposed raw API date timestamps, and some right-aligned
amounts sat immediately against Status progress indicators, making values hard
to read.

### Scope and acceptance criteria

- Display Project Billing, Expenses, Resource Usage, and Timesheets dates
  through the existing configured business-date formatter, omitting the time
  portion of API timestamps.
- Keep amount/billable and status visually distinct in the desktop tables by
  reserving spacing around adjacent columns and allowing status indicators
  sufficient width.
- Keep Vendor Work amount and Status columns separated using the same local
  spacing rule.
- Format all Project register amounts with the existing company amount-grouping
  and decimal-place settings, while keeping numeric cells right-aligned.
- Right-align numeric amount, cost, rate, quantity, and hours inputs in Project
  editors for consistent data entry.
- After creating or updating any Project child record, invalidate the cached
  project collection before reloading so the new row is visible immediately.
- Apply the same cache invalidation before delete reloads.
- Apply the same date display to constrained project tiles.
- Preserve API payloads, filters, saved dates, billing calculations, and
  statuses.
- Verify formatting and focused static analysis; manually confirm the desktop
  row containing a billable value and Draft status has no collision.

## Sales customer advance allocation

Status: Implemented (2026-09-03)

### Problem and objective

Sales receipts currently allocate themselves to open invoices when the client
sends no allocation rows, and the receipt editor can derive the received amount
from its allocation rows. This prevents a user from intentionally recording an
on-account customer advance and makes the accounting control amount ambiguous.

The Sales receipt and invoice workflow must mirror the approved Purchase
advance workflow while preserving Sales terminology and customer scope.

### Scope and business rules

- `customer advance = received amount - invoice-linked allocation total`.
- Received Amount remains independently editable and is never overwritten by
  allocation-line edits.
- Saving or posting a receipt with no allocation rows leaves the full received
  amount as customer advance. Posting never creates allocation rows silently.
- Auto Allocate is an explicit receipt-editor action. It previews allocations
  against the selected customer's oldest outstanding invoices by invoice date
  and id, and adds rows only after the user invokes it.
- Multiple rows may reference the same invoice. Their combined amount must not
  exceed that invoice's current outstanding amount, and the total of every
  invoice-linked row must not exceed the receipt's available amount.
- A posted or partially allocated receipt may receive additional explicit
  allocation rows, limited to its remaining customer advance.
- When a registered-customer invoice is posted and posted customer advance is
  available, the user is asked whether to use it for that invoice. Choosing Yes
  consumes the oldest receipt advances by receipt date and id; choosing No
  leaves both the invoice and advances unchanged.
- Invoice posting applies advance only to the invoice currently being posted.
  It must not allocate to other older invoices.
- Direct customers do not participate in cross-document advance matching
  because they do not have a stable customer account identity.
- Allocation changes update receipt allocation state, invoice settlement state,
  voucher allocations, on-account voucher references, and audit metadata in one
  transaction. Customer, receipt, and invoice records used by FIFO allocation
  are locked to prevent double allocation.
- Existing historical receipts are not reconciled or changed automatically.

### API, persistence, and failure rules

- Receipt auto-allocation preview, available-customer-advance, and allocation of
  a posted receipt's remaining advance use company-scoped API endpoints.
- Invoice posting accepts an explicit `use_customer_advance` boolean. Missing or
  false means the API must not consume advance.
- `sales_receipt_allocations` records whether a row was automatic, its source
  receipt, allocating user, and allocation timestamp.
- Validation failures return an actionable error without partially changing
  receipt, invoice, voucher, or allocation state.
- Authorization and existing company/context checks remain mandatory on all
  endpoints.

### Acceptance criteria and tests

1. A 10,000 receipt with no rows posts with 10,000 customer advance and no
   invoice allocation row.
2. A 10,000 receipt with 6,000 invoice allocations retains 4,000 advance; a
   fully allocated receipt retains zero.
3. Auto Allocate creates preview rows only after the user clicks it and orders
   invoices deterministically by invoice date and id.
4. Duplicate invoice rows are accepted up to their combined outstanding limit
   and rejected above it.
5. Remaining advance on a posted receipt can be allocated later, with visible
   receipt rows and voucher allocations.
6. Invoice posting shows the customer-advance choice; Yes applies FIFO advance
   only to that invoice and No makes no allocation change.
7. Direct-customer invoices never trigger cross-document advance matching.
8. Concurrent attempts cannot allocate the same advance or invoice balance
   twice.
9. Focused backend tests, Flutter tests, formatting, PHP syntax checks, and
   Flutter analysis pass, or unavailable checks are explicitly reported.

## Resolved Email PDF template preview

Status: Implemented (2026-09-03)

The Email PDF template-selection dialog must preview the selected template's
subject and body with the current printable document's values, rather than
displaying raw `{{binding}}` tokens. It reuses the existing print-template
resolver and document data, including compatible email aliases such as
`document_no` and `grand_total`. The server remains authoritative for the
email ultimately sent. A batch Payslip action has no single document before
selection, so it must explain that values resolve per payslip instead of
showing unresolved bindings.

Acceptance criteria: selecting a template from a document's print preview or
direct Email PDF action shows its current document number, party, company, and
available totals in the preview; no raw binding is shown for that selected
document. The preview performs one O(k) placeholder substitution pass over
template length k and makes no extra API request.

## Deferred hover state updates

Status: Implemented (2026-09-03)

Objective: Prevent Flutter Web mouse-tracker assertions when shared table rows
and dashboard/activity graphs update their visual hover state.

Requirements:

- `ErpLineItemTable`, `ErpModuleDashboard` trend cards, and Activity Watch
  duration graphs must preserve their existing hover highlight or tooltip.
- Mouse enter, exit, and hover callbacks must not invoke `setState` during
  Flutter's device-update phase. They must request one post-frame state update
  instead.
- Multiple pointer events in one frame must apply only the latest hover value;
  a disposed widget must not be updated.
- The change is presentation-only: it must not change document data, graph
  values, API requests, permissions, or Activity Watch privacy behavior.

Performance and acceptance criteria:

- Hover requests are coalesced in O(1) time and O(1) additional state per
  widget, with at most one state update scheduled per frame.
- Rapid hover across line rows, dashboard trends, and Activity Watch graphs
  produces the final highlight/tooltip without
  `!_debugDuringDeviceUpdate` assertions.


## Register Email PDF actions for printable sales and purchase documents

- Date: 2026-09-03
- Status: Implemented

Sales Quotation, Proforma Invoice, Sales Order, Delivery, Sales Receipt,
Purchase Order, Purchase Receipt, Purchase Invoice, and Purchase Payment
registers must expose
an `Email PDF` column beside their document status. A row action loads the
persisted document into its existing management controller and uses the shared
template-selected printable-document email flow; it does not navigate away
from the register or create a second email API.

Rules and acceptance criteria:

1. An action is available only for a persisted document whose status is neither
   `draft` nor `cancelled`, matching the existing Sales Invoice register rule.
2. Clicking an eligible action shows its local progress state, opens the shared
   template selection flow, and sends a PDF whose filename safely derives from
   the document number (or uses a stable document-type/id fallback).
3. A stale row is rechecked after its controller loads; an ineligible document
   remains unsendable and explains why without sending anything.
4. Each controller builds PDF data through its existing print-data builder and
   prepares its existing customer/supplier context before emailing.
5. Returns remain out of scope. Purchase Receipts must also provide their
   existing-document Print/Email preview action, using the shared
   `purchase_receipt` printable-email registry and an active matching template.

Validation: focused widget/unit coverage must include eligible, draft,
cancelled, and missing-id eligibility; format and analyze all touched Dart
files. Manual authenticated testing must confirm template selection, progress,
and a delivered attachment for every supported register.

### Register row identity repair — 2026-09-03

Register rows containing stateful Email PDF actions must use their persisted
document id as their sibling key. Filters, sorting, pagination, or a reload
must not reuse an action state for a different record or retake an inactive
widget element by transient row index. Rows without a persisted JSON id retain
an index fallback. The repair is presentation-only and does not alter email,
API, or document rules.

### Purchase printable email-template configuration — 2026-09-03

Email Template configuration must offer the canonical lowercase document types
accepted by the printable-email API, including `purchase_order`,
`purchase_invoice`, and `purchase_payment`, regardless of the uppercase values
configured for document series. When no active matching template exists, the
shared selector must name the affected document type in its actionable error.
This applies equally to Sales and Purchase and does not change template lookup,
recipient, permissions, or delivery behavior.

### Purchase register email failure feedback — 2026-09-03

When a Purchase register Email PDF action cannot select a template, it must
show the same exact actionable error returned by the shared selector, including
the affected document name. The temporary register action must not silently
consume this error. Other direct-email callers retain the existing toast-based
failure behavior.

### Purchase register Email PDF load isolation — 2026-09-03

The temporary Purchase Order, Invoice, and Payment controllers created by a
register Email PDF action must load only their selected document and must not
publish a purchase-module refresh. Their normal page initialization and
working-context refresh behavior remain unchanged. The shared error formatter
must preserve `ApiException.displayMessage` and `ApiResponse.message`, so a
template-configuration error is visible after the isolated load completes.

### Printable email feedback severity — 2026-09-03

An absent active email template is a configuration warning, not a sending
failure. The shared direct-email flow must render this condition with the
amber warning treatment in Sales and Purchase. PDF generation, API, recipient,
authorization, and delivery failures remain red errors.

## CRM enquiry quotation bootstrap

- Date: 2026-08-31
- Status: Implemented

Creating a quotation from an existing CRM enquiry/opportunity must retain the
CRM link and preselect the enquiry's customer. The sales user must not need to
choose the same customer again. The quotation remains editable, so the user can
replace the customer deliberately before saving when business circumstances
require it.

Acceptance criteria:

1. The CRM "New quotation" action opens a quotation with the opportunity id
   retained in the save payload.
2. The quotation customer defaults to the linked opportunity's
   `customer_party_id` when one exists, including when the party is not present
   in the initial Sales customer lookup response.
3. The quotation's company defaults to the linked opportunity's company and
   the notes identify the linked opportunity without overwriting entered notes.
4. Missing or unavailable CRM bootstrap data leaves a normal editable new
   quotation; it does not block quotation creation.

## Configurable LOP calculation basis and payslip summary

- Date: 2026-08-27
- Status: Implemented

Company Settings provides three LOP calculation bases: Percentage-based,
Month-based, and Working-days-based. Percentage-based uses the configured
percentage of monthly gross per LOP day; for example, 5% of ₹12,000 is ₹600
for one LOP day. Existing companies retain Working-days-based behavior by
default. Payslip salary summaries include the calculated LOP deduction.

Acceptance criteria:

1. The selected basis is saved per company and used when a payroll is processed.
2. Percentage-based calculation applies the configured percentage once per
   effective LOP day.
3. Month-based prorates the saved monthly net salary by payable calendar days;
   Working-days-based prorates monthly gross by scheduled working days.
4. Payslip summary data displays LOP deduction alongside salary totals.

### Month-based contractual-net salary proration

- When a company selects calendar-month, contractual net, and floor rounding,
  payroll uses `floor(monthly net salary × payable calendar days ÷ calendar
  days)`.
- Payable calendar days include payable scheduled attendance units and weekly
  offs adjacent to at least one payable scheduled day. A weekly off surrounded
  by an ongoing LOP/absence period is not payable.
- The processed payroll line reports this calendar-payable value as paid days
  and snapshots scheduled paid units separately for auditability.
- Earned gross and earning components use the same calendar factor. When the
  explicit deduction components do not reconcile earned gross to the prorated
  stored net, payroll records a `Net salary adjustment` deduction so the
  payslip breakdown equals its total deductions and final net.
- For EMP/00014 in May 2026, 8 payable working days plus 2 qualified Sundays
  equals 10 payable calendar days; `floor(23,467 × 10 ÷ 31)` is INR 7,570.
- For EMP/00004 in May 2026, 30 payable calendar days gives
  `floor(11,235 × 30 ÷ 31)` = INR 10,872. Statutory deductions must reconcile
  against this floored target without rejecting the payroll run.

Acceptance criteria:

1. Month-based contractual-net processing uses the salary structure's saved
   monthly net.
2. Continuous LOP does not make every weekly off in the month payable.
3. Payslip earnings minus displayed deductions equals final net salary.
4. Selecting component-calculated net uses earned gross less employee
   deductions instead of the stored net target.
5. Existing processed payroll and payslip snapshots remain unchanged until an
   eligible run is recalculated.
6. The configured rounding method is applied deterministically.

### Configurable company payroll proration policy

Status: Approved (2026-09-02)

Objective: Let a sellable ERP reproduce calendar-month, scheduled-working-day,
fixed-divisor, and percentage LOP policies without changing application code.

Requirements:

- Company Leave Policy stores the LOP basis: percentage, actual calendar days,
  scheduled working days, or a positive fixed divisor.
- Calendar and fixed-divisor modes derive unpaid calendar units from payable
  calendar days. Calendar mode uses payable days divided by month days; fixed
  mode deducts each unpaid unit at `1 ÷ fixed divisor`. Weekly offs can be
  always payable, attendance-qualified, or excluded.
- Each company selects whether final net is calculated from prorated earnings
  and deductions (`components`) or from the salary structure's contractual net
  multiplied by the same factor (`contractual_net`).
- Contractual-net results support floor, nearest-whole-rupee, ceiling, or
  two-decimal rounding. Component-calculated net retains normal two-decimal
  currency precision.
- The processing snapshot records every selected policy value and the divisor
  actually used. Historical processed snapshots are not rewritten.
- Existing calendar-month companies retain contractual-net/floor behavior on
  migration. Other existing companies retain component-calculated behavior.
- PF and ESI component formulas consume the active effective-dated statutory
  profile's configured wage ceilings. The existing INR 15,000 and INR 21,000
  constants are fallback defaults only when a profile ceiling is absent.
- Validation rejects an unsupported enum or a non-positive fixed divisor.
- No additional table is introduced; company policy extends `companies`, while
  statutory ceilings continue to use `hr_statutory_pf` and `hr_statutory_esi`.

Acceptance criteria:

1. A company can save, reload, and change every policy from Company Settings.
2. Calendar + contractual net + floor produces EMP/00004 INR 10,872 and
   EMP/00014 INR 7,570 for the approved May inputs.
3. Calendar + components reproduces the supplied workbook pattern: earned
   earnings less calculated employee deductions.
4. Scheduled-working-day and fixed-divisor modes use their configured divisor.
5. Always-pay, qualified, and exclude weekly-off policies produce distinct,
   deterministic payable-day counts.
6. Changing a statutory profile ceiling changes the special PF/ESI component
   result for payroll periods covered by that profile.
7. Focused backend syntax/tests and Flutter format/analyze/tests pass.

## Employee salary-component drag reorder Flutter compatibility

- Date: 2026-08-27
- Status: Implemented

The Employee Salary Components tab must use Flutter's supported
`ReorderableListView.builder` callback while preserving the existing drag-order
and persistence behavior. No API, database, or salary calculation behavior is
changed.

Acceptance criteria:

1. The Flutter web build accepts the salary-component reorder list constructor.
2. Moving a component upward or downward still persists the intended order.
3. Saving-state interaction remains disabled and unrelated salary behavior is
   unchanged.

## CRM lead completion after delivery or invoice

- Date: 2026-08-26
- Status: Implemented

CRM lead conversion to an opportunity or quotation is not a completed lead.
The lead remains **In Progress** until the linked sales chain reaches a
delivery or invoice. The Flutter register displays the server-provided status;
no new frontend status or API field is introduced. A delivery- or invoice-linked
lead displays **Own**/completed as before.

Acceptance criteria:

1. A lead with only a quotation or sales order remains In Progress.
2. A lead with a linked delivery or invoice displays Own/completed.
3. Refreshing CRM after a Sales transition shows the updated status.
4. Existing Lost behavior and API compatibility are preserved.

## Global status toast

- Date: 2026-08-25
- Status: Implemented

Controller-originated application feedback uses a single centered toast instead
of the scaffold snackbar. The toast replaces the previous message, disappears
after three seconds, and uses green for success, amber for warnings, red for
errors, and blue for informational messages. It does not change API behavior,
form validation, or persistence.

The app root must use Flutter's standard `ScaffoldMessenger`; `AppToast` remains
an independent overlay and must not subclass messenger framework state.

## CRM Enquiries expected-value presentation

- Date: 2026-08-25
- Status: Implemented

Objective: Make the Expected Value column in the CRM Enquiries register
readable and prevent zero or absent amounts from appearing as a meaningful
value.

Requirements:

1. The Expected Value column has sufficient register width to remain visibly
   separate from the adjacent Lead By column.
2. A missing, blank, numeric zero, or zero-formatted Expected Value renders as
   a centered `-` in register and read-only table views.
3. A non-zero numeric amount retains its API-provided display text; malformed
   non-empty legacy text remains visible rather than being discarded, and the
   Expected Value column remains center-aligned.
4. No CRM API, database, persistence, filtering, sorting, or calculation
   behavior changes.

Acceptance criteria:

1. `0`, `0.0`, `0.00`, blank, and absent values show a centered `-`.
2. A value such as `25000` is shown unchanged and centered.
3. Expected Value and Lead By do not visually merge in the desktop register.
4. Focused formatter tests, formatting, and analysis pass.

## CRM inline filter bars

- Date: 2026-08-25
- Status: Implemented

- CRM Enquiries, Leads, and Opportunities use the same toggleable inline filter
  bar interaction as Sales registers.
- Clicking **Filter** opens the filter bar in the page layout; clicking it
  again hides the bar. Search, date, lookup, and status changes update the
  visible register without an Apply button.
- The existing CRM filter fields and dashboard status defaults remain
  unchanged. A shared Clear action resets the current page's filters.
- CRM lists include a Sales-style Sort control with **Newest first** as the
  default, plus Oldest first and name ordering where applicable.
- CRM Leads, Enquiries, and Opportunities expose an Employee filter only to
  Super Admin users. It filters by the existing assigned-user data in the
  loaded CRM rows; regular users do not see or use this control.
- CRM Follow-ups exposes the same Super Admin-only Employee filter alongside
  its From Date and To Date controls; Clear resets both date and employee
  selections.
- The CRM Dashboard Employee filter uses a searchable ERP link field rather
  than a static dropdown. Other dashboard secondary filters retain their
  existing control.
- No backend, API, or database contract changes are required.
- CRM Follow-ups also uses the toggleable bar for inclusive From Date and To
  Date filtering; either boundary may be left empty. The former always-visible
  date filter card is removed.
- The CRM filter bar and its controls use the full available page width on
  desktop and responsive widths on smaller screens; fields are not capped by
  the shared settings form's default field width.
- On wide screens, CRM filter controls are laid out six per row; they collapse
  responsively on tablet and mobile widths.
- CRM list search is provided once in the application bar, not duplicated
  inside the filter bar or list/table content.
- The Clear action is an icon-only X control without an outline and fills the
  same filter-grid column width and height as the surrounding controls.
- The application-bar search is centered in the main header area, with the page
  title on the left and CRM filter/create actions on the right. It uses a wider
  360 px desktop field while remaining horizontally scrollable on compact
  screens.

## CRM Dashboard all-employees filter selection

- Date: 2026-09-01
- Status: Implemented

- In the Super Admin CRM Dashboard employee filter, selecting **All employees**
  checks and displays that option and checks every employee name in the
  searchable employee field.
- Selecting a specific employee clears the all-employees selection and leaves
  only the selected employee checked; selecting **All employees** checks every
  employee again.
- Unchecking **All employees** clears the All employees checkbox and every
  employee-name checkbox.
- The dashboard's existing empty employee-filter value remains the canonical
  value for loading unfiltered CRM data. No API, database, permission, or
  persistence contract changes are required.
- Clearing the employee field restores the same all-employees state and
  reloads the unfiltered dashboard snapshot.

Acceptance criteria:

1. The All employees row and every employee-name row show checked states when
   All employees is selected.
2. The field displays All employees when no specific employee is selected.
3. Choosing a named employee unchecks All employees and the other names, then
   filters by that employee.
4. Choosing All employees after a named employee checks every name and removes
   the employee filter from dashboard requests.
5. Unchecking All employees leaves all employee checkboxes unchecked without
   preventing the dashboard from showing unfiltered data.

## CRM Enquiries completed followup presentation

- Date: 2026-09-01
- Status: Implemented

- In the Enquiries Followups tab, a followup whose internal status is `done` or
  `completed` is treated as history and hidden from the editable followup list.
- If a completed followup has a Next Followup date, the tab shows that date in
  an editable followup card matching the existing expandable-card
  presentation, with a pending Next Followup badge.
- The followup editor does not show a manual Status field. A non-empty Next
  Followup date automatically sets the current followup status to `done`.
- Existing save payloads and backend followup status rules remain compatible;
  the frontend derives the status from the next-date input.

Acceptance criteria:

1. Marking a followup Done hides its previous followup card.
2. A Done followup with a Next Followup date shows an editable matching
   followup card with a Next Followup badge.
3. The Done followup's Status dropdown is not visible.
4. Pending and next followups show editable date, assignee, and notes fields
   without a manual Status dropdown.

## Sales quotation PDF email attachment

- Date: 2026-09-01
- Status: Implemented

- **Send to customer** generates the existing quotation print-template PDF and
  includes it in the email attachment request.
- PDF generation failure prevents a text-only email from being sent.

Acceptance criteria:

1. The received quotation email contains a PDF attachment.
2. The emailed PDF uses the same template as quotation print/download.

## Persistent authenticated browser session

- Date: 2026-08-20
- Status: Implemented
- A valid stored authentication token restores the ERP session after a browser
  refresh regardless of the legacy remember-me preference.
- Manual logout, token expiry, and a server 401/403 remain the only reasons to
  clear the persisted session and route the user to login.
- The login form does not offer a remember-me checkbox because it no longer
  changes refresh behavior.

## Attendance month and year filtering

- Date: 2026-08-17
- Status: Implemented

- The saved Attendance report uses Month and Year selectors instead of a From
  date / To date combination. Selecting either value immediately reloads the
  matching monthly attendance sheet and resets the horizontal calendar scroll.
- Employee, status, source, and search filters remain client-side filters on
  the loaded month.

## Monthly manual attendance

- Monthly Attendance lists every active employee in the selected company,
  including employees linked to active ERP users. The existing attendance
  records, employment-period, and weekly-off rules still determine whether an
  individual day can be edited.

## Leave Requests use the logged-in employee

- Date: 2026-08-21
- Status: Implemented

- A new Leave Request automatically uses the logged-in user's employee record
  for the active company. The form displays that employee as read-only and
  does not offer an all-employee selector.
- Existing requests retain their recorded employee when opened. HR users keep
  their existing request-list filtering and approval access; this UI change
  does not alter backend authorization.
- If the user has no employee record linked in the active company, the form
  cannot submit until HR creates or links that record.

## Leave Request approval actions

- Date: 2026-08-21
- Status: Implemented

- A selected pending Leave Request shows **Approve** and **Reject** only to a
  Super Admin or a user with the `hr.approve` permission.
- Approval and rejection use the existing dedicated HR endpoints. Approving
  triggers the company-policy paid-leave/LOP allocation; employees cannot
  change the read-only request status themselves.

## Company leave policy and LOP configuration

- Date: 2026-08-21
- Status: Approved for implementation

Each company owns a leave policy for every leave type. Company Settings exposes
the annual entitlement, leave availability schedule, excess action, active state, and the
company LOP deduction multiplier. CL is not fixed at 12 days: the configured
company entitlement may be higher or lower.

- Supported LOP multipliers are 1, 1.5, and 2; the default is 1.
- Pending requests do not consume paid leave and do not create LOP. At
  approval, the paid-leave/LOP split uses the company policy and only the
  employee's already-approved leave in the same leave year. Rejected requests
  do not consume entitlement.
- Annual-upfront policies expose the complete annual entitlement. Monthly
  policies accrue annual entitlement / 12 through the application month.
- When a paid entitlement is exhausted, `convert_to_lop` allocates the excess
  request duration to LOP. A `reject` policy blocks the request instead.
- Unpaid leave allocates its full duration to LOP.
- Payroll applies the company multiplier after reconciling attendance and
  approved leave LOP, caps the result at working days, and snapshots the
  multiplier used. Existing processed payroll is never recalculated.
- Existing companies default to multiplier 1. Existing leave-type maximums
  seed company policies; CL defaults to monthly accrual and excess-to-LOP.
- The Leave Request screen selects an existing leave type only. The dedicated
  Leave Types master is the sole create/update/delete workflow for the shared
  leave-type catalog; Company Settings configures how those types apply to one
  company and does not create catalog entries.
- The policy UI labels the schedule dropdown **Leave availability schedule**
  and keeps its choices compact: **Yearly** and **Monthly**. The stored values
  and calculation rules remain `annual_upfront` and `monthly` respectively.
- Company editor forms must not use a shared `GlobalKey`, because the
  responsive SettingsWorkspace can temporarily mount its editor more than once
  while changing layouts. The save action validates through its local form
  context.
- Responsive SettingsWorkspace editor navigation defers route-state updates
  until the current pointer event completes, preventing Flutter Web
  MouseTracker re-entrancy assertions when opening settings editors such as
  Email Templates.
- Shell Back navigation pops unnamed nested editor routes before consuming
  module history, keeping Project child editors consistent with Sales register
  navigation.
- Project Billing, Expense, Resource Usage, Timesheet, and Vendor Work create
  and edit actions use `/projects/<register>/new` or
  `/projects/<register>/<id>` shell routes. The application drawer and header
  remain mounted while only the center content changes, matching Sales.
- Project Kanban boards expose one compact add (`+`) action in the Open lane;
  the duplicate full-width lane add button is removed. The Open-lane action
  remains available after cards move between statuses.
- Kanban cards remain draggable for status changes, but do not display a
  “Drag to change status” handle icon.
- Company Settings renders only its selected tab body. It does not retain every
  tab in an `IndexedStack`, because the embedded Financial Years editor has its
  own stateful form and must not be mounted while hidden.
- The embedded Financial Years list may build more than one expandable editor,
  so each editor validates with its own local `Form` context rather than a
  controller-owned global key.

- Date: 2026-08-17
- Status: Implemented

### Objective and rules

- The Attendance screen uses the shared employee-by-day calendar as a monthly
  report. It lists only employees with persisted attendance in that month and
  displays only saved Activity Watch or manual records; blank days stay `—`.
- The report has no employee selection, default-Present generation,
  draft/submit actions, or multi-record save. Selecting an existing saved cell
  opens the existing attendance editor directly, without an intermediate JSON
  detail dialog.
- The report Filter action toggles the shared full-width HR filter bar for
  search, employee, status, source, month, and year. It does not use a popup
  or a separate inline Month/Year/Load toolbar.
- All live HR list filters (Attendance, Leave Requests, Expense Claims,
  Payroll Runs, and Payslips) use the same toggleable `HrInlineFilterBar`;
  filters are no longer presented in popups. Each page keeps its existing
  fields, clear behavior, and load request. Payroll Runs includes From date and
  To date, which filter the persisted run date alongside search and status.
- On `SettingsWorkspace` HR pages, the bar uses the workspace-level full-width
  header slot so it spans the list and editor area rather than the list pane.
- The inline bar follows the Sales filter action pattern: it has no Apply
  button and uses the shared Clear action at the end of the filter row.
- Successfully submitted Bulk Attendance is persisted in `attendance_records`,
  then opens the Attendance report on the submitted company/month so the new
  manual rows are visible immediately.
- The saved-record report is a clean, horizontally scrollable grid
  with serial number, employee identity, department, numbered day headers with
  three-letter weekday labels, daily status pills, horizontal row separators,
  and pagination. It intentionally omits vertical daily-column lines. Filter,
  Reload, and Bulk Attendance remain in the page action area; the report does
  not render a separate title/control bar, Employee Status column, or
  status-legend card.
- `MonthlyAttendanceCalendarGrid` owns the shared employee/day table layout;
  the report and Bulk Attendance use the same serial, employee avatar,
  department, day-header, and row-separator presentation. Their distinct cell
  actions and Bulk Attendance selection state do not duplicate the calendar
  structure.
- Report rows may include inactive or terminated employees when they have
  attendance inside the selected employment period; Bulk Attendance remains
  restricted to active eligible employees.
- Unsupported reference actions such as Export, Import, Template, and Summary
  are not displayed until their workflows exist.
- Its Bulk Attendance action opens the separate editable calendar scoped to
  employees without an active ERP user.
- Eligible Monday-through-Saturday dates through company-local today default to
  Present. HR marks exceptions as Half day, Paid leave, LOP, or Absent.
- Sunday, future dates, and dates outside employment are non-editable report
  cells. HR may open a saved Activity Watch record individually and change it
  through the established editor; the resulting manual decision becomes the
  payroll source and later agent events cannot replace it.
- In Bulk Attendance, Activity Watch and submitted manual rows remain locked;
  the flow only prepares non-system employees.
- Selected employee rows are saved in one bounded transaction. The request is
  capped at 15,000 employee/date cells and reports created/skipped counts.

### Bulk Attendance employee selection

- Bulk Attendance starts with no employee rows selected. Selecting one row
  submits attendance only for that employee; it must not silently submit other
  employees.
- The existing shared calendar table header checkbox explicitly selects or
  clears every employee row currently loaded in the bulk sheet. Its checked and
  indeterminate states reflect the selected employee IDs.
- The calendar derives its final day from the selected year and month, rather
  than trusting an optional API day count. A June sheet can never create or
  submit a July 1 record.
- Paid leave is one payable unit, Half day is 0.5, and LOP/Absent are unpaid.
- User linkage is schema-compatible: installations with `users.employee_id`
  use the direct relation; legacy installations use matching employee codes.
- The all-employee request sends `include_system_employees` as numeric `1` or
  `0`, compatible with the existing Lumen boolean query validator.
- Bulk Attendance exposes only Submit attendance. It creates payroll-ready,
  locked manual attendance; the UI does not offer a draft-save action.
- Activity Watch and earlier submitted/manual attendance remain locked. Payroll
  processing is rejected while any manual draft attendance exists in its period.

### Acceptance criteria

- The drawer contains one Attendance entry, which opens the saved-record-only
  monthly report. Authorized HR users can open the non-system Bulk Attendance
  workflow through the Bulk Attendance action.
- HR can select employee rows, review the full calendar, mark exceptions, and
  submit the selected attendance.
- Existing attendance remains unchanged and is counted as skipped.
- The monthly sheet reloads after save and displays created rows as locked.
- Submitted bulk rows appear in Attendance with source `M` for the same month.

## Activity Watch/manual attendance and attendance-based payroll

- Date: 2026-08-17
- Status: Implemented

### Objective and rules

- ERP login does not create attendance. A paired Activity Watch agent creates
  at most one `activity_watch` record for its linked active employee on the
  company-local date; manual status rows retain authority.
- The first check-in is queued locally before transmission and retried across
  network failures or service restarts. Detailed monitoring uploads remain
  restricted to ERP logout.
- Employees and departments without system access continue using the existing
  manual attendance create/edit workflow.
- Attendance list responses retain the API's nested employee name/code in the
  typed Flutter model. The register displays the employee name, falling back to
  employee code only when the name is absent; it must not issue a per-row
  employee request.
- Payroll preview reports scheduled, present, paid, and LOP units. Monday
  through Saturday are scheduled and Sunday is a paid weekly off requiring no
  login in this first release.
- Processed payroll lines display earned gross, deductions, net pay, paid days,
  present units, and total LOP. Half-days remain decimal.
- Processing blocks structures whose components belong elsewhere, contain
  duplicate names, or whose earning total differs from gross by over INR 0.01.
- A rejected Process request (including HTTP 422 salary validation) keeps the
  payroll detail dialog usable and displays the API validation message. Only a
  successful process closes the dialog and refreshes the payroll register.
- The API owns timezone, idempotency, proration, snapshots, lifecycle, and
  accounting balance.

### Acceptance criteria

- Attendance register identifies Activity Watch versus manual source.
- Attendance register displays the employee returned by the existing API
  relation for both Activity Watch and manual rows.
- Draft preview identifies ready employees and paid/scheduled/LOP units.
- Processed lines show earned gross and preserve decimal attendance.
- Later salary edits do not change processed payslip snapshot values.
- Focused Flutter and backend validation passes.

## Payslip gross and net salary summary fallback

- Date: 2026-08-13
- Status: Approved for implementation

### Objective

Show the calculated Gross Salary and Net Salary on every rendered payslip,
including older saved templates that lack a salary summary.

### Scope and rules

- Earnings and deductions stay as individual pay heads; calculated Gross and
  Net amounts are not inserted into either table.
- The deductions table never includes a calculated `Total Deductions` row;
  that aggregate appears only in the salary summary.
- The salary summary shows CTC Monthly alongside Gross Salary, Total
  Deductions, and Net Salary.
- A saved `hr_payslip` template without a Gross/Net salary-summary binding
  receives a non-editing preview fallback beneath the breakup tables.
- Templates that already bind either salary-summary Gross or Net value retain
  their existing layout without an added fallback.
- The values come from the existing payslip `salary_summary` payload; no
  payroll, API, database, or salary-component calculation changes.

### Acceptance criteria

- A payslip with no summary text shows Gross Salary, CTC Monthly, Total
  Deductions, and Net Salary beneath its breakup tables.
- A template that already displays the salary summary is not duplicated.
- Earnings and Deductions tables retain their current rows and bindings.

## Payslip PDF table stroke consistency

- Date: 2026-08-26
- Status: Implemented

### Objective

Keep salary-table borders visually uniform in downloaded payslip PDFs when the
template stroke width is configured to 1, matching the print-designer preview.

### Scope and rules

- Apply the fix only to the vector PDF table renderer.
- Preserve the configured stroke width, colors, rounded outer border, rows,
  columns, totals, and table content.
- Draw the internal row and column dividers as one PDF stroke operation model,
  rather than adjacent filled rectangles that can rasterize unevenly at
  fractional coordinates.
- Make no payroll calculation, API, database, or template-persistence changes.

### Acceptance criteria

- Downloaded payslip salary tables render consistent horizontal and vertical
  borders at stroke width 1.
- The on-screen designer preview remains unchanged.
- Focused formatting and Flutter analysis pass.

## Payroll run deletion from processed state

- Date: 2026-08-13
- Status: Implemented

### Objective

Allow an authorized HR user to delete a processed payroll run from its detail
dialog, matching the existing backend lifecycle rule.

### Scope and rules

- The detail dialog shows **Delete** for both `draft` and `processed` runs.
- A confirmation is required before either deletion. The processed-state prompt
  explicitly warns that generated payroll lines and payslips are permanently
  removed through the existing database cascade.
- Posted runs retain no delete action. The existing API remains the authority
  and rejects voucher-linked or otherwise ineligible records.
- No API, database, permission, or accounting behavior changes. A successful
  deletion closes the dialog and refreshes the register; an API failure leaves
  the dialog open and displays the server message.

### Acceptance criteria

- Opening a processed payroll run displays Delete and no Post action.
- Deleting a processed run requires confirmation, calls the existing DELETE
  endpoint, and refreshes the payroll-run register after success.
- Draft and posted-run behavior remains unchanged.

## Activity Watch self-service employee onboarding

- Date: 2026-08-07
- Status: Approved for implementation

### Objective

Replace developer-only device-ID, credential-file, JSON, and Terminal setup
with a one-time employee workflow suitable for Flutter Web and all supported
desktop operating systems.

### User workflow

1. An employee installs the organization-provided signed Activity Watch agent
   once on a Windows, macOS, or Linux computer.
2. In ERP Settings → Activity Watch, the employee enters a device label,
   accepts consent, and selects **Connect this computer**.
3. ERP creates a 30-minute, single-use pairing token and downloads a small
   `.billingawpair` file. The file contains only the API URL, platform, token,
   and format version; it never contains the permanent device credential.
4. Opening the pairing file invokes the installed agent. The agent exchanges
   the token once, provisions encrypted local storage when absent, writes the
   credential/configuration atomically with user-only permissions, and starts
   the user service.
5. The ERP page shows pending, connected, last-seen, revoked, or expired state.
   Normal ERP logins and computer restarts require no reconfiguration.

Windows installer updates must stop an existing Activity Watch service/process,
wait until the installed executable is unlocked, replace it, and restart the
same service. The launcher requests elevation for this service-aware update so
an in-use agent executable never causes an opaque copy failure.

### API, storage, and security requirements

- Use the existing `activity_watch_devices` table; do not introduce a migration
  framework table or an additional Activity Watch pairing table.
- Store only a SHA-256 pairing-token hash, expiry, and paired timestamp. The raw
  token is returned once and expires after ten minutes.
- Pairing exchange is transactional and single-use. Concurrent or repeated
  exchanges fail without returning another credential.
- The device credential is generated locally by the agent during exchange,
  stored server-side only as a hash, and never included in the pairing file,
  Flutter state, server response, logs, or documentation. Retrying the same
  token with the same credential is idempotent until token expiry.
- The generated credential is a 64-character hexadecimal value, matching the
  server's alphanumeric validation. A leftover URL-safe Base64 candidate from
  an older development build is replaced before exchange.
- Production pairing URLs require HTTPS. Loopback HTTP remains allowed only for
  local development.
- During the approved internal development phase, the agent may also accept
  `http://bill.local/...` and `http://192.168.31.83:8000/...` for pairing and
  synchronization. No other remote HTTP hostname is permitted. This temporary
  exception must be removed or superseded by trusted internal HTTPS before
  wider deployment.
- Pairing bundles are bounded, versioned, strict-decoded, and removed by the
  handler after a successful setup.
- Existing direct enrollment remains available for native/developer
  compatibility but Flutter Web uses token pairing by default.

### Activity Watch connection setup status and controls

- The connection setup card contains only its title, the device-label field,
  and the connect button. The existing service request continues to send the
  consent flag required by the backend contract.
- A pending pairing shows `Waiting for connection` while its server-issued
  pairing expiry has not passed. After the 30-minute pairing window passes,
  it shows `Pairing expired`.
- Disconnected/revoked devices are not shown in the Activity Watch device list.
  The list action is labelled `Disconnect`; it uses the existing authenticated
  revoke endpoint and refreshes the list after success.

### Failure and recovery

- Missing agent/file association: keep the pending device visible and provide
  installer/open-file guidance; no activity collection begins.
- Expired or already-used token: ERP creates a new pairing session; old pending
  devices may be revoked by the owner.
- Provision/configuration failure: do not partially publish a credential file
  or configuration; rerunning the same bundle is allowed only until the server
  has consumed the token.
- Service installation/start failure: preserve the paired configuration and
  show an actionable local error so install/start can be retried without
  exposing the credential.
- A Windows Scheduled Task permission failure after the server exchange must
  leave the device paired. The launcher reports connected setup with a separate
  background-start warning; it must not misreport this as a pairing failure.
- Windows pairing-file launch failure: the installed handler must show the
  safe local failure detail rather than silently returning to ERP.

### Acceptance criteria

- A web employee never copies a device ID or permanent credential and never
  edits JSON.
- Backend tests cover expiry, one-time exchange, ownership/company scope, and
  token hashing; PHP syntax checks pass.
- Go tests cover strict bundle parsing, URL policy, exchange response handling,
  atomic protected writes, provisioning reuse, and failure preservation.
- Flutter model/service tests cover pairing responses and the web page downloads
  the versioned bundle using the existing shared file-download utility.
- Existing Activity Watch collection, reports, direct enrollment, and logout
  synchronization remain compatible.

## Activity Watch cross-platform completion

- Date: 2026-08-07
- Status: Approved for implementation

### Objective

Complete the consent-gated Windows, macOS, and Linux Activity Watch workflow so
an enrolled desktop can sample privacy-safe user presence and foreground
application identity, retain consolidated encrypted local records, publish
daily summaries through the durable outbox, and expose device/report status in
the ERP.

### Functional requirements

1. Collection starts only when synchronization has an enrolled device
   credential and `collection.disabled` is not set.
2. The collector samples at a configurable interval (default 15 seconds), uses
   only OS idle duration and foreground executable/application identity, and
   classifies active, idle, locked, or unknown state. Unsupported or denied OS
   APIs produce `unknown`; they must not crash the service.
   On Windows, idle duration, foreground window/process, pointer position, and
   interactive-desktop availability use direct bounded Windows API calls so the
   15-second sample loop does not depend on PowerShell startup. Windows process
   inventory also uses native process snapshots so the five-minute inventory
   loop is not blocked by PowerShell startup, script policy, or Scheduled Task
   command failures. Remaining multi-part PowerShell inventory commands use
   UTF-16LE `EncodedCommand` transport so Scheduled Task argument reconstruction
   cannot alter pipelines.
   A missing foreground window/process is a valid empty observation, not a
   collector error. Windows idle duration must account for the native 32-bit
   last-input timer wrapping during long system uptimes.
3. State and application samples are consolidated into local segments. An
   unchanged state/application updates the current segment in constant time;
   a change closes the current segment and opens one new segment.
4. Process inventory is sampled every 5 minutes and service inventory every 15
   minutes by default. Canonically sorted names are hashed, and an unchanged
   snapshot is not stored again.
5. Daily summaries contain active/idle/locked/unknown totals, overlapping
   offline duration, and application duration grouped by executable
   name/category. Segments spanning local midnight are clipped to each local
   date. Summaries are regenerated on a separate bounded interval (default 15
   minutes) and immediately before logout; network retry frequency cannot
   create extra summary revisions.
6. Local synchronized detail older than 90 days is deleted in bounded indexed
   operations. Pending/retry/permanently-failed records are retained for human
   resolution and are never silently discarded.
7. Server ingestion validates all base64 fields, checks SHA-256 ciphertext
   checksums, accepts only approved entity/operation values, stores a bounded
   privacy-safe metadata projection for reports, and is idempotent.
8. A new credential for an existing device identity may recover locally queued
   authentication failures; unrelated permanent validation failures remain
   failed.
9. Authenticated ERP users can list their own enrolled devices, summaries, and
   revoke a device. Users with `hr.view` may view devices/summaries within their
   authorized company context. Reporting is date-bounded and paginated.
10. The Flutter Activity Watch page reuses the existing API client, section
    cards, form controls, and shell. It shows enrollment, device state,
    revocation, filters, and daily totals without exposing credentials after
    the one-time enrollment response.

### Security and privacy

- Never collect keystrokes, clipboard contents, screenshots, pointer
  coordinates, command-line arguments, window/tab titles, URLs, or page/form
  content.
- Foreground collection is limited to process/executable name and a local
  category. Inventory is limited to process/service names and states.
- Detailed local payloads remain AES-GCM encrypted and the database remains
  SQLCipher encrypted. Only an explicit, bounded summary metadata projection is
  sent for server reporting over HTTPS (loopback HTTP is development-only),
  and only when ERP logout requests an outbox flush.
- Collection errors log operation names only, never observed content or secret
  material.

### Acceptance criteria

- Go unit/integration tests cover sample consolidation, idle thresholds,
  inventory deduplication, local-midnight summary aggregation, retention,
  credential recovery, and existing synchronization behavior.
- Go formatting, tests, vet, and build pass on the available host; OS adapters
  fail safely when permissions/tools are unavailable.
- PHP syntax checks pass and Activity Watch routes are authenticated and
  company/user scoped.
- Flutter formatting, analysis, and focused tests pass where the SDK is
  available.
- `install.sql` remains the fresh-install source of truth; the existing
  additive Activity Watch patch is updated for already-created test/server
  tables. No framework migration table is introduced.

## Activity Watch privacy-safe enrollment and ingestion MVP

- Date: 2026-08-06
- Status: Approved for implementation

### Objective

Complete the consent-gated Activity Watch path from an ERP user enrolling a
desktop device through the local Go service retaining an offline queue and the
ERP receiving idempotent device batches.

### Data and access rules

- Collect only active/idle/locked durations, timestamped lifecycle state, and
  application executable name/category. Browser collection, when enabled by a
  later native adapter, is domain/category only.
- Never collect keystrokes, clipboard contents, screenshots, pointer
  coordinates, window or tab titles, full URLs, page/form content, or process
  command-line arguments.
- Enrollment requires an authenticated ERP user, explicit consent, a device
  label/platform, and a consent policy version.
- Device credentials are random, device-scoped, stored server-side only as a
  hash, returned once at enrollment, and invalid after revocation.
- The service uses the credential only for `POST /api/v1/activity-watch/batches`.
  It never retains the employee's ERP JWT after logout.
- HR managers (the existing `hr.approve` scope) and super administrators may
  view organization records; regular employees may view only their own device
  status. Server data is retained for 90 days, then deleted.

### API and persistence requirements

- `POST /api/v1/activity-watch/enroll` creates/replaces an active device
  credential for the authenticated user after explicit consent.
- `POST /api/v1/activity-watch/batches` authenticates a device credential and
  accepts at most 500 ordered outbox records. Device/idempotency keys make a
  retried batch safe.
- Server ingestion stores opaque encrypted payload fields and metadata only;
  it does not attempt to decrypt a device-local SQLCipher/AES payload.
- Revocation disables future batches immediately. Retention cleanup removes
  records and batch receipts older than 90 days.

### Acceptance criteria

- Missing consent, invalid device credential, mismatched device header, an
  oversized batch, or malformed item is rejected without partial writes.
- Retried batch/idempotency keys do not create duplicate stored events.
- Credentials, encrypted payload contents, and database keys never appear in
  API responses or logs.
- Flutter exposes an explicit consent/status path before configuring a native
  service.

## Activity Watch Go desktop service

- Date: 2026-08-06
- Status: Implemented; collection/reporting details are governed by the
  cross-platform completion specification above

### Problem and objective

Activity Watch must start with a desktop computer, store authorized monitoring
events locally while offline, and continue uploading queued records after the
ERP user logs out until the operating system shuts the service down.

Run the Go executable in the enrolled user's service/login context. This keeps
encrypted persistence and synchronization independent from Flutter while also
giving privacy-safe OS adapters access to that user's idle and foreground
application state. System-service contexts such as Windows Session 0 are not
used for interactive collection.

### In scope

- Windows, macOS, and Linux desktop service lifecycle.
- Non-destructive `provision` command that creates a new encrypted local
  database/key pair and its control directory from a valid configuration.
- Install, uninstall, start, stop, restart, status, and foreground-run commands.
- Enrolled-user service execution from OS login until logout/shutdown.
- SQLCipher database opening and approved schema verification.
- Machine/session lifecycle, idle/application sampling, and bounded health
  events.
- Bounded `sync_outbox` batch selection with idempotent HTTP upload.
- Exponential retry with a maximum delay and server `Retry-After` support.
- Logout-triggered sync flush while the machine service remains alive.
- Graceful shutdown that finalizes local encrypted records without uploading.
- Interfaces for later native session collectors and secure secret providers.
- Unit tests with in-memory fakes and HTTP test servers.

### Out of scope

- Mobile background execution on Android or iOS.
- Browser extension/native messaging.
- Raw browser tab capture, window-title capture, or Wayland permission bypasses.
- Installing the service without administrator approval.
- ERP-side reporting and retention jobs beyond raw idempotent ingestion.
- Storing user passwords or reusing a logged-in user's ERP access token.

### Required behavior

1. Installation must not begin collection. Enrollment, device authorization,
   active consent, and machine credentials are prerequisites.
2. The user service starts at operating-system login and runs independently of
   the Flutter process for the remainder of that interactive session.
3. The service records only policy-approved system lifecycle/health events when
   there is no authorized interactive helper. Each accepted lifecycle event and
   its AES-GCM-encrypted opaque outbox record must commit in one SQLCipher
   transaction, so a crash cannot leave an event recorded without a
   corresponding upload item (or the reverse).
4. Native Flutter logout finalizes user activity collection, regenerates the
   daily summary, and requests an immediate outbox flush.
5. Every ERP logout action must require an explicit user confirmation before
   ending the session. The confirmation explains that a browser session cannot
   invoke the local Windows agent; only a native Flutter session can issue its
   local logout signal.
6. Pending sync remains encrypted locally until a later ERP logout, permanent
   rejection, or policy/device revocation.
7. Shutdown cancels collection, closes open work, and closes SQLCipher without
   an upload attempt.
8. Upload batches are ordered by next-attempt time and creation time and are
   limited by configured batch size. Selection uses the approved dispatch
   index, making each batch `O(B)` after indexed lookup where `B` is batch size.
9. A batch is acknowledged only when the server returns HTTP 2xx with a JSON
   success envelope whose accepted count matches the uploaded batch. HTML,
   malformed JSON, a false success flag, or a mismatched accepted count is a
   retryable invalid response and must never mark local outbox rows as synced.
   Authentication/authorization rejection is permanent until re-enrollment.
   Timeouts, network errors, 408, 429, and 5xx use bounded exponential retry.
10. Logs must never contain database keys, device credentials, decrypted
   payloads, window titles, URLs, or personal activity content.
11. A plaintext SQLite runtime, missing key, wrong key, unsupported schema,
   absent consent, or invalid configuration fails closed.
12. `provision` must create the exact approved schema version, a cryptographically
    random raw 256-bit key encoded in a mode-`0600` file, and the configured
    control-directory parent. It must refuse to overwrite either an existing
    database or an existing key file.
13. If provisioning cannot finish, it must remove only temporary artifacts and
    artifacts it created during that same invocation; it must never modify an
    existing configured path.

### Configuration and API contract

Non-secret configuration defines database path, sync URL, device identifier,
intervals, batch size, and shutdown timeout. Database and device credentials
come from a machine secret provider, not the JSON configuration file.

For an authorized fresh installation, run `activity-watch-agent provision`
before `run` or native service installation. It creates a new independent
machine database/key pair. It must not be used to replace an existing
Flutter-managed database because that would create a different key.

The implemented endpoint is `POST /api/v1/activity-watch/batches` with:

- a device-scoped bearer credential;
- `X-Device-Id` and `Idempotency-Key` headers; and
- a JSON body containing an ordered batch of opaque encrypted outbox payloads.

Web logout uses device-authenticated control endpoints derived from the batch
URL: `GET /activity-watch/control` reads the server flush flag and
`POST /activity-watch/control/acknowledge` clears it only after the agent has
successfully drained the complete local outbox. Acknowledgement is a separate
request so an initially empty outbox and a final batch exactly equal to the
configured batch size both complete correctly. The existing final-batch header
remains backend-compatible during agent rollout but is not the new agent's
source of completion truth.

When sync is disabled or the endpoint is unavailable, the service retains
pending records without data loss for a later retry.

### Security and privacy

- The enrolled user service owns the database/key lifecycle for its session.
- SQLCipher compatibility 4 and a raw 256-bit key are required.
- Secrets are injected through a provider interface. Production packaging must
  use a machine-scoped credential/ACL implementation for each OS.
- The service never captures keystrokes, clipboard data, screenshots, pointer
  coordinates, full URLs, form/page content, or command-line arguments.
- All collectors are consent- and capability-gated and return unknown when a
  platform API or permission is unavailable.

### Acceptance criteria and tests

- Service commands are wired through the native service manager abstraction.
- Native Flutter logout notifies a configured service, while web and
  non-enrolled installations remain safe no-ops.
- The worker starts collector and logout-control loops and stops them with
  bounded cleanup.
- Logout stops session collection but triggers the only synchronization attempt
  without stopping the machine worker.
- Outbox upload handles success, retryable failure, permanent rejection, batch
  limits, and cancellation.
- An HTTP 200 HTML response and malformed/mismatched JSON remain retryable and
  do not mark any outbox item synced.
- Server-driven logout acknowledgement occurs after zero, partial, one-full,
  and multiple-full-batch drains, and acknowledgement failure leaves the server
  flush flag set for retry.
- Retry delay is capped and deterministic under injected randomness.
- Configuration rejects unsafe or missing required values.
- Provisioning creates an encrypted database that passes the store's schema
  verification and rejects existing database/key paths without modifying them.
- SQLCipher runtime and approved schema are verified before writes.
- `go test ./...`, `go vet ./...`, and `go build ./cmd/activity-watch-agent`
  pass where a Go/CGO toolchain is available.
- On Windows, the release packaging command must build one self-contained EXE
  that embeds the compiled Go agent and the reviewed per-user installation
  script. The launcher extracts both into a unique temporary directory, waits
  for the script, reports success or failure, and performs best-effort cleanup.

## Engineering optimization and reuse policy

- Date: 2026-08-06
- Status: Active

Every implementation, fix, review, and refactor must search for reusable
project components before adding an equivalent widget, helper, service, model,
or utility. Existing abstractions should be reused or compatibly extended only
when their responsibility and contract match; otherwise the reason for a new
abstraction must be recorded.

Non-trivial logic must choose algorithms and data structures from real access
patterns and expected input sizes. Implementations must avoid accidental
quadratic work, repeated scans, unnecessary sorting or copying, and unbounded
data loading. Performance claims require measurement. Optimization must not
reduce correctness, accessibility, maintainability, security, or readability.

Acceptance criteria:

- Repository reuse search is completed before new shared UI or utility code.
- New abstractions have a distinct responsibility or documented justification.
- Non-trivial performance-sensitive logic records meaningful time/space
  complexity and relevant validation.
- No benchmark or optimization claim is reported without execution evidence.

## Activity Watch encrypted local persistence

- Date: 2026-08-06
- Status: Implemented

### Problem

The cross-platform Activity Watch agent needs durable offline storage for
sessions, consolidated activity, application/browser observations, inventory,
system events, summaries, and synchronization. The data is privacy-sensitive
and must remain encrypted at rest.

### Objective

Implement the approved 10-table SQLCipher schema as an opt-in Flutter
persistence foundation with secure key management, authenticated payload
encryption, schema versioning, foreign keys, transactions, and automated tests.

### In scope

- Native Android, iOS, macOS, Linux, and Windows database support.
- SQLCipher full-database encryption with a verified cipher runtime.
- Platform secure storage for database, payload, and HMAC keys.
- AES-256-GCM helpers for sensitive payload columns.
- The 10 approved tables and 11 indexes.
- Schema version 1 creation and future migration boundary.
- Transaction API and fail-closed database opening.
- Tests for schema, constraints, encryption, reopen, and rollback.

### Out of scope

- Activity collection and OS platform adapters.
- Browser extensions or native messaging.
- Enrollment UI, consent UI, and automatic startup.
- ERP server tables or synchronization endpoints.
- Web persistence; Activity Watch is a native-agent facility.
- Production key recovery or device migration.

### Requirements

1. Do not initialize the database from normal Flutter startup before consent.
2. Generate three independent 256-bit keys: SQLCipher, payload AES-GCM, and
   identifier HMAC.
3. Store keys only through the platform secure credential provider.
4. Verify `PRAGMA cipher_version` before creating any schema.
5. Apply the encryption key before all other database reads.
6. Enable foreign keys, secure deletion, full synchronous writes, WAL where
   supported, and a bounded busy timeout.
7. Create exactly the approved 10 application tables and 11 indexes.
8. Reject databases newer than the supported schema version.
9. Run schema creation and migrations transactionally.
10. Roll back caller transactions when an operation throws.
11. Never log keys or decrypted sensitive payloads.

### Inputs and outputs

- Input: native database path and key material, normally obtained through the
  database manager.
- Output: an open `ActivityWatchDatabaseContext` containing an encrypted
  database connection and in-memory key material for authorized runtime use.
- Failure: typed initialization exception without secret values.

### Validation and edge cases

- Keys must be exactly 32 bytes after decoding.
- Missing or unavailable secure storage prevents initialization.
- A plaintext SQLite runtime is rejected even if it accepts `PRAGMA key`.
- A wrong database key must fail before migrations run.
- Foreign-key and CHECK constraint violations must surface to the caller.
- Empty/invalid secure-storage values are treated as corruption, not silently
  reused.
- Web initialization throws `UnsupportedError`.

### Security and privacy

- SQLCipher encrypts the complete database.
- Sensitive BLOB payloads use independent AES-256-GCM encryption.
- Identifier hashing uses independent HMAC-SHA-256 key material.
- In-memory key buffers are cleared when the context is disposed, subject to
  Dart runtime limitations.
- Tests must not contain production keys or personal activity data.

### Acceptance criteria

- Schema exposes exactly 10 application tables and the documented indexes.
- SQLCipher runtime verification succeeds in the native test environment.
- A database can be closed and reopened with the correct key.
- Opening with the wrong key fails.
- Foreign keys and CHECK constraints reject invalid rows.
- A failed transaction leaves no partial records.
- Payload encryption round-trips and detects tampering.
- Formatting, analysis, and focused tests pass.
- Documentation and changelog match the implementation.

### Required tests

- Schema table/index inventory.
- SQLCipher availability and encrypted file reopen.
- Wrong-key failure.
- Foreign-key enforcement.
- Platform and state CHECK constraints.
- Transaction commit and rollback.
- Key generation and secure-storage persistence through a fake provider.
- AES-GCM round trip and tamper rejection.
- HMAC stability and key separation.

## Party code synchronization when party type changes

The approved requirements, edge cases, compatibility constraints, acceptance
criteria, and verification plan are maintained in
[`party-code-type-sync.md`](party-code-type-sync.md).
# Privacy-safe input and browser-category durationV
Status: Implementing (2026-08-07)

Objective: Report useful keyboard/mouse interaction and browser-use duration
without capturing employee content.

Requirements:

- The desktop agent records whether any keyboard or pointer input occurred
  between bounded activity samples. Keyboard keys, click targets, button values,
  and pointer coordinates are never stored.
- Daily summaries expose `input_seconds`, an approximation consisting of sample
  intervals in which input was detected, and `browser_seconds`, the duration for
  which a recognized browser was the foreground application.
- Browser reporting is category-only. Raw tab/window titles, domains, URLs,
  private/incognito activity, page content, and form content remain excluded.
- Existing version-1 encrypted local databases are upgraded in place by adding
  the non-content `input_detected` flag; no migration-history table is created.
- Older agents remain API-compatible; omitted new summary fields default to zero.

Acceptance criteria:

- Input state changes split local activity segments and aggregate without
  double counting.
- Browser time is calculated from existing foreground application segments.
- API validation accepts bounded new counters and old summaries.
- ERP daily summaries display input and browser durations.
- Tests confirm aggregation and backward-compatible parsing.

# Activity Watch concise screen

Status: Implementing (2026-08-07)

Objective: Make the Activity Watch setup and report page understandable at a
glance without removing consent, pairing, device state, or activity metrics.

Requirements:

- Use the existing Activity Watch cards, fields, and summary data.
- Replace explanatory paragraphs and low-value labels with concise titles and
  grouped primary metrics.
- Keep consent wording explicit and retain the actionable pairing expiry,
  device connection state, refresh, revoke, date filters, and application
  totals.
- Keep every reported duration and application total available in the daily
  summary table.

Acceptance criteria:

- The first view has one clear connect action and concise privacy wording.
- Device rows show label and connection state without duplicated platform and
  timestamp labels.
- Summary rows show active, idle, and browser duration first; expanded details
  retain keyboard/mouse, lock, offline, unknown, and application information.

## Activity Watch summary table

Status: Implemented (2026-08-10)

### One owner card per day

- Date: 2026-08-20
- Status: Implemented
- Recent daily activity shows at most one card for an owner on a local work
  date, even when logout produces several uploaded summary snapshots.
- Owner identity is the linked employee ID, otherwise the owning user ID, and
  otherwise the device ID for unassigned legacy data.
- For the same device and date, the first row in the newest-first API response
  is retained and older cumulative snapshots are discarded rather than added.
- Distinct devices belonging to that owner on the same date are combined into
  the one card. Duration totals and application/browser totals are additive;
  bounded process, USB-device, and USB-file details are de-duplicated.
- The existing API, viewer scope, date filters, privacy rules, and empty/error
  behavior remain unchanged.
- Acceptance: five same-day logout snapshots for one user render one card with
  the newest daily values; two distinct devices for that user/date also render
  one card with combined values; different users or dates remain separate.

The Activity report reuses `ErpModuleDashboard` to present recent daily
activity from the already-loaded report rows. The active-time trend, keyboard
activity graph, separate distribution card, and duplicate bottom table are
omitted from the dashboard overview. Selecting a recent activity record expands
inline with active/idle, keyboard active/idle, mouse active/idle, browser,
locked, and untracked-time graphs in place of the metric-tile grid.
Untracked time is displayed from the existing `unknown_seconds` response field;
it does not estimate unreported device time. Each graph uses only the selected
owner's already-loaded daily summaries in the current date range. The dashboard
overview must not reserve an empty analytics column or show a `No analytics
configured` card when it contains no insight cards. Each duration graph is a
separate borderless rounded surface with smooth filled mountain curves: green for the main
series and red for the companion idle series. Graph cards omit redundant
legends and point markers, show a duration timeline at the left and compact
month/day labels along the bottom, and reveal the selected day's duration
values in a visible, on-screen hover tooltip.
For a single-day range, each series draws a full-width horizontal value line
instead of leaving its one-point path invisible.
Each recent daily activity row shows a trailing down chevron while closed and
an up chevron while its inline details are open, so the selected record and its
expanded state are clear without changing the row's privacy-safe metrics.
The duration graphs remain visible whenever the daily record is open. The
Application activity, Browser tab titles, Background applications, and USB
activity sections are independently folded by default and toggle from their
icon-led headers, with directional chevrons showing their state.
The expanded view has no enclosing
outlined duration-trends container or supporting label. Input is an aggregate
keyboard/mouse duration; raw input and background-process data are not part of
the API contract. No extra API request is introduced; date filtering,
loading/error/empty behaviour, the API contract, and privacy restrictions are
unchanged.

The application details section presents the existing application totals as a
ranked report. It sorts the existing de-duplicated totals by duration, uses
readable category labels, and renders each result as a card with its duration.
It intentionally is not a table and does not calculate or display a share
percentage, so the presentation makes no claim about the entire workday or
unreported device time. The cards use three equal columns when the panel is
wide enough and stack on narrow layouts, without an enclosing outer card.
The application heading does not repeat the selected date or device label, and
classification formatting must preserve a single unclassified word.

Browser tab titles remain limited to existing foreground titles; URLs and page
content are never shown. The details view de-duplicates and ranks those titles
by duration and presents them as compact title tiles with a browser icon and
duration badge. The tiles use two columns where space permits and stack on
narrow layouts; the section heading does not repeat a supporting privacy
sentence.

Background application inventory uses the existing bounded process name and
state fields. The UI de-duplicates and orders the entries deterministically,
then displays them in a responsive four-column process grid without an
enclosing outer card; it stacks the cards on narrow layouts.

The expanded Full activity details content retains its existing background fill,
rounded shape, and internal spacing.

USB activity continues to display only the existing consented port, device, and
bounded file-metadata fields. The details view renders a concise port-status
line, responsive device cards, and compact file-change rows rather than data
tables, without an enclosing outer card. File paths remain available only as
the existing hover tooltip, and the safety-limit notice remains visible.

Super admins also receive an employee filter on Recent daily activity. The
filter uses employee identity returned with each summary, while the API remains
the source of truth for non-super-admin visibility.

## Activity Watch office monitoring detail

Status: Approved for implementation (2026-08-10)

Objective: Extend consented office-device monitoring with operational detail
without collecting input content or screen content.

Requirements:

- Record sampled keyboard-active and mouse-active duration independently when
  the operating system exposes enough signal. Derive each corresponding idle
  duration from tracked time. These values are sampled estimates, not event
  counts.
- Never record actual keys, typed text, mouse buttons, pointer coordinates,
  clipboard content, screenshots, or form/page content.
- Record the active browser window/tab title only while a recognized browser is
  foreground. Never record or upload URLs.
- Reuse encrypted local title columns and encrypted process inventory snapshots.
- Include at most 50 browser-title totals and 100 background process names in a
  daily summary. Deduplicate names case-insensitively and sort deterministically.
- Expose the fields through validated summary metadata and render them only in
  the expanded daily activity dashboard.
- Existing agents and summaries remain readable with zero/empty defaults.

Acceptance criteria:

- A new agent reports keyboard/mouse active and idle estimates separately.
- Expanded activity shows browser-title duration totals and the latest bounded
  background-process inventory for that device/day.
- Old agents continue syncing and the API accepts summaries without new fields.
- Employee/API viewer scoping remains unchanged.

## Activity Watch release and agent operations

The approved Windows/macOS build, API publication, development-installation,
agent-removal, and command procedures are maintained in
[`activity-watch-release-operations.md`](activity-watch-release-operations.md).
They must retain the backend's stable installer filenames, publish to
`billing-api/public/downloads/activity-watch`, limit unsigned macOS handling to
a hash-verified package-specific quarantine removal, and warn that removing an
agent's application-data directory permanently removes its local encrypted
queue.

The configured public installer base URL must include any deployment-specific
path prefix between the hostname and the API `public` directory. Release
verification must reject frontend HTML, error documents, and unexpectedly small
payloads even when the server reports HTTP 200. An accepted Windows response
has the executable content type and expected published size; macOS has the
expected published package size.

The macOS stable `.pkg` filename must contain a valid XAR installer archive,
never the raw Go agent or launcher Mach-O binary. Before publication,
`pkgutil --payload-files` must parse the package and list the application
bundle, launcher, agent, and `Info.plist`; both bundled executables must retain
mode `755`. The published file's SHA-256 hash must match the validated package.

## Activity Watch device-management access

Only a super administrator may revoke (disconnect) an Activity Watch device.
The disconnect action is not rendered for other users, and the authenticated
revoke endpoint rejects their direct requests. A non-super-admin Activity Watch
request remains limited by the server to devices and summaries whose `user_id`
matches the signed-in user; it must not request or render another employee's
activity. Super-admin company scope and the employee filter remain unchanged.

Acceptance criteria:

1. A super administrator can see and use Disconnect for an active device.
2. A regular user cannot see Disconnect, and a direct revoke request returns
   HTTP 403 without changing the device.
3. A regular user's devices and summaries remain limited to that user's
   employee activity.

## Activity Watch USB audit metadata

Status: Approved for implementation (2026-08-12)

Objective: Extend consented Windows and macOS Activity Watch monitoring with
bounded USB device metadata without reading file contents.

Requirements:

- USB monitoring starts only for a paired agent whose employee accepted consent
  policy version 3 or later. Existing version-2 devices continue activity
  monitoring with USB collection disabled until they are paired again.
- Report best-effort connected USB device name/manufacturer, first observed
  connection time, last observation time, and observed duration on Windows and
  macOS. Windows additionally reports total/occupied port counts, removable
  volume label/drive, and capacity/free bytes.
- Windows reports bounded removable-drive file metadata changes as `added` or
  `deleted`:
  relative path, file name, extension, byte size when known, and observation
  time. Do not claim that an added file was copied because a polling observer
  cannot prove its source.
- Never read or upload file contents, file hashes, document text, clipboard
  data, command lines, or deleted-file contents.
- The Windows scan is bounded to 5,000 files per observation and daily summaries
  contain at most 200 most-recent file events and 50 devices. A truncation flag
  tells the UI when the boundary was reached.
- USB payloads reuse encrypted `system_events` metadata and the existing daily
  summary/outbox pipeline; no additional local table is introduced.
- Linux agents and older summaries remain valid with zero/empty USB defaults.

Limitations and error handling:

- USB physical-port counts are best-effort because Windows firmware, hubs, and
  drivers do not always expose a reliable chassis-port topology.
- The initial removable-drive scan establishes a baseline and does not report
  every existing file as newly added. Short-lived changes between scans can be
  missed; the UI labels the feed as observed changes.
- A failed or timed-out USB scan does not stop ordinary Activity Watch sampling
  or synchronization.
- The Windows collector must pass its multi-statement PowerShell query through
  an encoding-safe command form so WMI filter quoting is preserved by Windows
  process argument handling, and must materialize its bounded generic file list
  before JSON projection for Windows PowerShell 5.1 compatibility. A command-
  transport or projection failure is logged as a USB scan failure and remains
  isolated from ordinary activity collection.
- The macOS collector reads bounded USB topology from
  `system_profiler SPUSBDataType -json`. It does not enumerate mounted files,
  does not report physical port totals, and remains isolated from ordinary
  activity collection if the command is unavailable.

Acceptance criteria:

1. A newly paired consent-v3 Windows agent records connected USB/removable
   device metadata and updates observed duration.
2. A newly paired consent-v3 macOS agent records connected/disconnected USB
   device metadata and updates observed duration without removable-file data.
3. Adding or deleting a file on a removable drive produces metadata-only audit
   entries without reading the file.
4. The daily Activity Watch detail shows port counts, connected devices, drive
   capacity usage, observed durations, file changes, and truncation notices.
5. Existing consent-v2 devices, agents, and summaries continue to work with USB
   fields absent or empty.

## Activity Watch super-admin company scope and employee labels

Status: Approved for implementation (2026-08-12)

Objective: Let only super administrators see company-wide Activity Watch
devices and employee activity for the selected company, with a distinct,
human-readable owner label for each summary.

Requirements:

- The Activity Watch page determines whether the signed-in user is a super
  administrator before loading devices and summaries.
- Only a super administrator requests `scope=company` for both device and
  summary endpoints and includes the current context company ID when selected.
- Company summary pages are fetched in API-sized batches until every authorized
  summary in the selected date range is available to the employee filter and
  trend calculations.
- With a selected company, records from other companies are excluded. A super
  administrator without a selected company retains the authorized all-company
  view. Every non-super-admin retains personal viewer scope.
- Summary labels use the linked employee's name and code. If a legacy device
  has no linked employee, they use its owning user's display name/username and
  keep that owner as a distinct filter value.
- Enrollment, pairing, consent, device ownership, and revoke authorization are
  unchanged.

Acceptance criteria:

1. Two super administrators using the same company context receive the
   same authorized company device and daily-summary dataset.
2. A super administrator does not receive another company's records when a company
   is selected.
3. Every non-super-admin continues to receive only their own devices and summaries.
4. Every employee or legacy device owner is visible as a separate readable
   employee-filter option.

The setup area places the Connect a computer and Devices cards side by side on
wide screens and stacks them on narrow screens below the Activity dashboard.
Devices are displayed newest first, five per local page, with older records
available through pagination; refresh, enrollment, and revoke actions reset the
device page to the newest records.

## Employee salary component grouped amounts

Status: Approved for implementation (2026-08-11)

Objective: Allow salary component amounts displayed with digit grouping to be
saved without a false numeric-validation error.

Requirements:

- Salary-component amounts such as `1,000.00` are treated as the numeric value
  `1000.00` for both client validation and API serialization.
- Empty, non-numeric, and negative values continue to be rejected where an
  amount is required.
- Salary-structure numeric fields use the same parsing rule when serialized so
  the shared formatted form controls cannot cause a related API mismatch.
- No API, database, authorization, or payroll-calculation behavior changes.

Acceptance criteria:

- A fixed component with `1,000.00` saves as numeric `1000.0`.
- A percentage-based component accepts an optional grouped amount.
- Invalid values and negative values remain invalid.

## Apply employee salary-component order to all employees

Status: Implemented (2026-08-11)

Objective: Let an HR user apply the salary-component display order configured
for one employee salary structure to every employee in the same company,
without changing any generated payroll or payslip.

Requirements:

- The Salary Components tab provides an explicit, confirmed action for each
  saved salary structure to apply its current component order to all employees.
- Only components whose normalized names occur in the source order are moved;
  components that are not in the source remain after them in their existing
  relative order. Amounts, calculation rules, contribution roles, and salary
  structures are not changed.
- The backend persists the component sequence explicitly and returns ordered
  components for employee editing and payroll calculation.
- The action is limited to the selected employee's company and requires the
  existing `hr.update` permission.
- Existing payroll lines and generated payslips are never queried, updated, or
  regenerated. The new order applies only when a future payroll/payslip is
  generated.

Edge cases and error handling:

- The source salary structure must belong to the selected employee.
- Empty source structures are rejected.
- Differences in employees' component lists are allowed; nonmatching rows are
  retained at the end.
- The request runs in a transaction; a failure leaves all component ordering
  unchanged.

Acceptance criteria:

1. A confirmed action applies Basic, HRA, and Allowance ordering from the
   selected structure to matching components in every salary structure in that
   company.
2. A target-only component remains after the matched components.
3. Existing generated payslips and payroll lines are unchanged.
4. A new payroll/payslip displays its breakup in the saved applied order.
5. Users outside the source employee's company cannot be affected.

## Global StaffU-inspired theme foundation

Status: Implemented (2026-08-22)

Objective: Establish one global, accessible Flutter theme foundation derived
from the StaffU design-language audit so every ERP module can migrate to a
consistent visual system without introducing module-local theme frameworks.

In scope:

- Preserve `MaterialApp` as the global theme widget boundary.
- Extend the existing `AppTheme` and `AppThemeExtension` contracts with
  complete light and dark palettes.
- Define semantic colors for canvas, surfaces, text, borders, focus, status,
  navigation, cards, tables, inputs, and charts.
- Apply shared typography and Material component themes for common controls.
- Register both themes at the application root and follow the operating-system
  brightness until a persisted user preference is explicitly approved.
- Add focused tests for palette roles, theme extensions, component defaults,
  interpolation, and app-root light/dark registration.

Out of scope:

- Redesigning or migrating any individual business module.
- Replacing existing reusable forms, tables, shells, or dashboard widgets.
- Removing feature-specific color fields before their callers are migrated.
- Adding a persisted theme selector or changing API/database behavior.

Design rules:

- StaffU audit anchors are primary `#4666E1`, dark canvas `#0D2042`, light
  canvas `#EEF2FA`, light surface `#F8F9FD`, muted text `#65688A`, and a
  predominantly 10px control/card radius.
- Dark surfaces must use readable light foregrounds; the extractor's invalid
  light-scheme/dark-surface combination must not be copied.
- The local Nunito font asset is the application font; print-only font families
  remain unchanged.
- Every generated print text field containing `₹` rasterizes that field with
  Flutter's own high-resolution `TextPainter` output, ensuring the rupee glyph
  exactly matches the UI preview without losing stroke weight during PDF
  downsampling. This applies to quotation, invoice, order, purchase, and other
  print templates without requiring document-specific shape IDs.
- Toast overlay entries must be inserted or removed outside the widget build
  phase so inherited widget dependents remain attached to the active tree.
- Material `ColorScheme` owns standard semantic roles. `AppThemeExtension`
  remains the compatibility layer for ERP-specific roles already consumed by
  the application.
- Theme creation performs fixed-size, constant-time work and returns immutable
  theme values. No collection algorithm is required for this bounded palette.

Accessibility and edge cases:

- Focused controls must retain a visible primary-color outline.
- Disabled, selected, hover, error, and high-contrast text states must remain
  distinguishable in both brightness modes.
- Existing pages with hardcoded colors may not be fully dark-mode ready; they
  remain migration work and must be handled one module at a time.
- Missing theme-extension values are not silently tolerated by current callers;
  both global themes must always register `AppThemeExtension`.

Acceptance criteria:

1. `AppTheme.light()` and `AppTheme.dark()` expose matching semantic roles and
   each contains `AppThemeExtension`.
2. `BillingApp` registers light and dark themes and uses system theme mode.
3. Cards, dialogs, form fields, buttons, tables, menus, navigation controls,
   selection controls, tooltips, and feedback components receive global style
   defaults without page-level edits.
4. Existing `AppThemeExtension` field names remain source-compatible.
5. Focused theme tests pass, formatting succeeds, and static analysis reports
   no issue caused by the foundation.
6. No business module, API, database, or persistence behavior changes.

## Shared bordered cards and module-list tables

Status: Implemented (2026-08-22)

Objective: Apply the StaffU data-table visual language consistently to shared
cards and list/table surfaces used across ERP modules, in both light and dark
themes, without rebuilding every module list independently.

Reference: `https://staffu.mantrakshdevs.com/data_table`, audited with
DesignLang and browser inspection on 2026-08-22.

In scope:

- Give globally themed cards and `AppSectionCard` a visible one-pixel semantic
  border, 12px radius, flat dark-mode depth, and subtle light-mode depth.
- Configure Flutter `DataTable` defaults for a distinct header band, compact
  header/body typography, bounded row heights, cell spacing, row dividers,
  hover state, and selected state.
- Apply the same table header, row, border, hover, and selected-row
  semantics to the shared sales/purchase register renderer and the shared
  editable `ErpLineItemTable` used by document forms.
- Apply the same border/radius language to shared settings and purchase list
  cards, list tiles, local pagination, and report pagination.
- Keep list and table overflow horizontally scrollable where already supported.
- Reuse one integer pagination helper across shared local list controllers.

Out of scope:

- Changing module data, filters, sort behavior, API requests, permissions, or
  business actions.
- Adding avatars, statuses, columns, or actions that are not already supplied
  by a module.
- Page-by-page decorative rewrites where the shared theme/component already
  controls the visual result.

Design and accessibility rules:

- Light cards use the existing light surface with border near `#DEE1E5`; dark
  cards use the existing blue-slate surface and `#33405D` border.
- Table headers use the existing semantic `tableHeaderBackground`; body text,
  links, ordinary rows, selected rows, hover rows, and dividers use
  `AppThemeExtension` roles.
- Card and row outlines must remain visible without relying only on shadows.
- Selected and hovered rows must remain distinguishable in both brightness
  modes, while ordinary rows keep adequate text contrast.
- Dark-theme mouse hover uses black at 20% opacity; light-theme hover remains
  unchanged.
- Pagination controls require tooltips and disabled states and must not expose
  an impossible extra page at exact page-size boundaries.

Performance rules:

- Pagination count is O(1) integer arithmetic; page extraction remains O(k)
  time and O(k) returned-list space for page size k.
- Shared style resolution remains O(1); no module list is rescanned to derive
  visual state.
- Register and line-item rows are rendered in one O(n) indexed pass without
  per-row searches or copied module implementations.
- Existing lazy builders and bounded page sizes remain unchanged.

Acceptance criteria:

1. Light and dark cards show a one-pixel semantic border and 12px radius.
2. Every standard Flutter `DataTable` receives the shared StaffU-inspired
   header, row, divider, spacing, hover, selection, and border defaults.
3. Settings and purchase list cards inherit the bordered surface and shared
   list tiles use semantic border/selection colors.
4. Local and report pagination use bordered compact controls and exact integer
   page counts for empty, partial, exact, and multi-page totals.
5. No module data/API behavior changes and no business-module list is copied.
6. Focused formatting, analysis, widget tests, and existing runnable tests pass.
7. Sales and purchase register lists use the shared StaffU-inspired header and
   row treatment, including the invoice list shown in the supplied screenshot.
8. Shared editable document line-item tables use the same bordered surface,
   header band, uniform ordinary rows, hover state, and selected state.

## CRM follow-up timeline presentation

Status: Implemented (2026-08-24)

Objective: Apply the StaffU Activity Log visual language to the existing CRM
follow-ups page while preserving its API contract, route filters, record
visibility rules, and follow-up actions.

Reference: `https://staffu.mantrakshdevs.com/active_log`, visually audited on
2026-08-24.

Requirements:

- Keep the existing opportunity follow-up board request, hidden won/lost row
  rules, completion filtering, dashboard query filters, refresh action, and
  record-detail navigation unchanged.
- Present each follow-up section as a bordered StaffU-style activity timeline
  with a section heading, vertical rail, primary-colored nodes, compact time
  labels, bordered detail cards, a Follow-up status badge, assignee/notes
  metadata, and the existing Open action.
- Add an optional single-date filter using the shared application date picker.
  Clearing it restores the route's normal Today, Overdue, and Upcoming views.
- Keep loading, error, and empty states on the existing shared components.
- Adapt the timeline for narrow widths without horizontal overflow or hiding
  the record action.

Performance and accessibility:

- Filtering and rendering remain O(n) time for n follow-up rows and O(n)
  rendered-entry space; no additional API request or repeated per-row search is
  introduced.
- Timeline decoration must use semantic theme colors in both brightness modes.
- Date and Open controls require visible labels/tooltips, and follow-up content
  must remain available as normal readable text rather than decoration only.

Acceptance criteria:

1. Default, dashboard-filtered, and date-filtered follow-up rows preserve the
   prior business selection rules.
2. Follow-up sections visibly match the reference timeline structure in light
   and dark themes.
3. Selecting a date limits visible rows to that calendar day; clearing the
   date restores the prior route view.
4. Empty, loading, retry, refresh, and detail-navigation behavior remains
   available.
5. Focused formatting, analysis, and widget tests pass with no new warning.

## Sales outstanding balance drill-down parity

Status: Implemented (2026-08-24)

Problem: The Sales Dashboard Outstanding Balance card totals every eligible
positive invoice balance, but its invoice-register drill-down pre-selects only
`posted` and `partially_paid`. The API exposes past-due positive balances with
the derived `overdue` status, so those rows can be omitted and the register's
overall outstanding total can disagree with the dashboard card.

Objective: Make the dashboard value and its invoice drill-down use one shared
outstanding-invoice definition, in the same deterministic route/filter style
as the Monthly Sales card.

Requirements:

- An outstanding sales invoice has a positive `balance_amount` and a derived
  status other than `draft` or `cancelled`.
- The dashboard card must sum `balance_amount` only; it must not substitute the
  original invoice total when balance data is absent.
- The card route must apply `dashboard_filter=open` and descending balance
  sorting.
- The invoice register's Open preset must pre-select `posted`, `overdue`, and
  `partially_paid`, then apply the same shared outstanding predicate.
- Monthly Sales behavior, invoice API requests, manual filters, exports, and
  database data remain unchanged.

Performance and acceptance criteria:

- Classification is O(1) per invoice and total aggregation is O(n) time with
  O(1) auxiliary space.
- For the same loaded invoice collection, the dashboard Outstanding Balance
  equals the Open drill-down's overall outstanding total.
- Overdue invoices appear in the Open preset, zero/negative balances and
  draft/cancelled invoices do not, and focused tests cover all boundaries.

## Light-theme application sidebar

Status: Implemented (2026-08-22)

Objective: Use a white permanent application menu in light mode while keeping
the established primary-blue active navigation treatment and preserving the
existing dark-mode sidebar.

Requirements:

- The shared desktop sidebar background is white in light mode.
- Unselected light-mode labels and icons use dark foreground and muted semantic
  colors with readable contrast.
- Active and parent-of-active entries use the existing primary color on a
  subtle primary-tinted background.
- Dark mode retains its existing dark sidebar background, foreground, muted,
  and selected treatment.
- Mobile drawer behavior remains unchanged because it already uses the light
  surface and primary active colors.
- No navigation routes, permissions, expansion behavior, or menu ordering
  changes.

Performance: Color selection is O(1) per shared shell build and introduces no
new collections, route scans, or per-module implementation.

Acceptance criteria:

1. Light-mode permanent sidebar background is white.
2. Light-mode active entries use the global primary color and a primary tint.
3. Dark-mode sidebar colors remain unchanged.
4. Focused formatting, analysis, and theme tests pass.

## Dark-theme visual hierarchy refinement

Status: Implemented (2026-08-22)

Problem: The dark theme is active in the supplied purchase-invoice screenshot,
but its canvas, card, table header, and table rows use similarly saturated blue
values. The layers therefore merge visually and the page appears flat.

Objective: Improve dark-mode depth and readability through the existing global
semantic palette without changing the approved light theme, primary color,
layout, data, or module behavior.

Requirements:

- Use a near-neutral navy scaffold behind a lighter blue-slate card surface.
- Keep headers, ordinary rows, alternating rows, hover rows, selected rows,
  dividers, and input fills visually distinct.
- Preserve the existing primary `#4666E1` for actions, focus, links, and active
  navigation.
- Preserve readable light foreground and muted text contrast on dark surfaces.
- Keep dark navigation recognizable and visually separated from page content.
- Apply the refinement only through `AppTheme.dark()` and
  `AppThemeExtension`; do not add module-local dark colors.
- Do not change the light palette, routes, tables, calculations, APIs, database,
  persistence, or permissions.

Performance: Palette construction remains fixed O(1) time and O(1) space;
runtime consumers continue using inherited theme lookups.

Acceptance criteria:

1. Dark scaffold, card, table header, alternate row, hover row, and selected row
   resolve to distinct semantic colors.
2. The card surface is visibly lighter than the scaffold and remains outlined.
3. Dark surface foreground contrast remains at least 4.5:1.
4. Light theme values and the global primary color remain unchanged.
5. Focused formatting, analysis, and theme tests pass.

## CRM lead probability status

Status: Implemented (2026-08-24)

The CRM Leads register includes a StaffU-inspired Probability column rendered
as a compact circular progress indicator with a centered percentage. Explicit
`probability_percent` values are clamped to 0–100; legacy leads without that
field use the existing lead status as a deterministic fallback (Draft 10%, In
Progress 50%, Own 100%, Lost 0%). Color semantics are high teal, medium amber,
and low error/red, while the existing status badge and row navigation remain
unchanged.

Acceptance criteria:

1. Every lead row exposes a readable probability percentage and circular ring.
2. Explicit API probability values are honored and safely clamped.
3. Missing values use the documented status fallback without API writes.
4. The indicator exposes semantic text for assistive technologies.

## Flutter SDK compatibility for shared transitions and API configuration

Status: Implemented (2026-08-29)

The frontend must compile against the Flutter SDK declared by the project. The
shared register filter transition uses the SDK's `SizeTransition` constructor
contract (`axisAlignment`), and `AppConfig.baseHost` always returns a usable
non-null host when `API_BASE_URL` is not supplied. Existing animation behavior,
API path composition, and runtime URL override behavior remain unchanged.

Acceptance criteria:

1. `AppRegisterFiltersSection` compiles with the current `SizeTransition` API
   and expands from the top edge.
2. `AppConfig.baseHost` has a deterministic development fallback while still
   honoring `--dart-define=API_BASE_URL=...`.
3. Focused formatting and Flutter analysis pass without errors.

## Sales invoice warehouse parity with deliveries

Status: Implemented (2026-08-29)

Stock-tracked sales invoice lines must retain a warehouse when they are created
from a delivery or entered directly. A warehouse inherited from a delivery
must not be cleared merely because the delivered stock is no longer currently
available. The invoice editor must show the same
required-field feedback as the delivery editor, and the API must reject a
missing warehouse instead of persisting an incomplete stock line. Service and
non-stock lines remain exempt, as does the existing incomplete inventory
selection path used for draft proforma conversion.

Acceptance criteria:

1. A stock-tracked invoice line with no warehouse shows a field validation
   message and cannot be saved by the Flutter editor.
2. The sales invoice API rejects a missing warehouse on a stock-tracked line,
   including lines mapped to a sales delivery line.
3. Non-stock/service lines and the existing draft proforma incomplete-selection
   flow remain compatible.
4. Focused Flutter analysis/tests and backend syntax/tests pass.
## Stage-based Sales lifecycle badges

Status: Approved for implementation (2026-09-01)

Sales document badges must describe the next business action instead of
treating every posted document as finished. The stored backend status remains
the lifecycle source of truth; Flutter derives only a presentation label and
semantic badge color from that status and the relationship flags returned by
the API.

Business rules:

- Draft documents display `Draft` in grey.
- A posted/submitted quotation without a non-cancelled order or proforma
  displays `Waiting for Sales Order` in amber. An accepted or converted
  quotation displays `Finished` in green.
- A posted proforma displays `Waiting for Sales Order` in amber; a converted
  proforma displays `Finished` in green.
- A confirmed/posted order displays `Waiting for Delivery`; a partially
  delivered order remains orange; a fully delivered order displays
  `Waiting for Invoice`; and a fully invoiced or closed order displays
  `Finished`.
- A posted delivery displays `Waiting for Invoice`; a partially invoiced
  delivery remains orange; and a fully invoiced delivery displays `Finished`.
- A posted sales invoice displays `Payment pending`; partially paid is orange,
  paid is green, and overdue is red.
- A posted receipt displays `Waiting for Allocation`; partially allocated
  displays `Partially Completed`; and fully allocated displays `Completed`.
- Cancelled, rejected, expired, returned, and overdue outcomes keep their
  terminal/error wording and color semantics.
- Registers, legacy list panes, document headers, and CRM pipeline subtitles
  use the same shared helpers. Filter labels are friendly presentation text,
  while filter values remain existing backend status values.

API contract:

- Quotation list and detail payloads expose `has_active_order` and
  `has_active_proforma`, excluding cancelled downstream documents.
- Delivery list and detail payloads expose `has_active_invoice`, excluding
  cancelled invoices, and `is_fully_invoiced`, derived from the stored
  delivery status. No schema or request-payload change is required.

Edge cases and compatibility:

- Empty and unknown statuses continue to use the existing empty/title-cased
  fallback behavior.
- Existing stored statuses, lifecycle transitions, routes, and write payloads
  are unchanged.
- Date-based invoice overdue detection continues to override the posted badge.

Acceptance criteria:

1. A posted unconverted quotation shows `Waiting for Sales Order`; linking a
   non-cancelled order/proforma changes it to `Finished` in list and detail.
2. Confirmed orders, posted deliveries, posted invoices, and posted receipts
   show their documented waiting labels in registers and document pages.
3. Partial and terminal lifecycle states retain their documented labels and
   orange/green/red semantics.
4. CRM sales-pipeline subtitles match the relevant document helper.
5. Quotation/delivery detail payload flags match their corresponding list
   payload flags without N+1 relationship queries.
6. Focused formatting, static analysis, helper tests, and backend syntax checks
   pass.
## Sales detail action placement

Status: Implemented (2026-09-01)

Conversion actions are grouped in a `SalesDocumentActionRow` immediately below
the document pipeline/status area. Save, submit, delete, cancel, revise,
customer communication, and document viewing remain at the bottom of the form.
Print/Preview labels use the contextual `View Quotation`, `View Proforma
Invoice`, `View Order`, `View Delivery`, and `View Invoice` wording. Existing
permissions, lifecycle guards, routes, and print-preview behavior are unchanged.

Acceptance criteria:

1. Quotation conversion actions appear only in the top action row.
2. Proforma invoice, order, and delivery conversion actions appear only in the
   top action row.
3. Invoice payment action is grouped in the top action row.
4. Bottom document actions contain contextual View labels and no conversion
   action.
5. Sales document action rows align their buttons to the right and wrap on
   narrow layouts.

## Excel-compatible PF and ESI salary-component bases

Status: Implemented (2026-09-02)

Objective: Extend the existing Salary Components editor so payroll can use the
formulas in the supplied May 2026 wage register instead of approximating PF and
ESI through `% of basic` or `% of gross`.

Requirements:

- Calculation choices include `PF: % of EPF wage (configured ceiling)` and
  `ESI: % of Basic + DA (configured eligibility limit)`.
- Entering the component name `PF` selects deduction, employee contribution,
  12%, and the EPF-wage basis.
- Entering the component name `ESI` selects deduction, employee contribution,
  0.75%, and the Basic + DA upward-rounding basis.
- The defaults remain editable. Saving an explicit valid PF or ESI percentage
  preserves the user's value while the API continues to enforce the correct
  calculation basis.
- Percentage values retain up to four decimal places when loaded into the
  editor and displayed in the component list; monetary fields continue using
  their existing two-decimal formatting.
- `Employer PF` and `Employer ESI` default to employer deductions using 12%
  EPF wage and 3.25% Basic + DA respectively; the API repairs mismatched type
  and contribution roles on save.
- Saved API values are `percent_epf_wage` and `percent_basic_da_ceil`.
- Existing calculation choices remain readable and editable.
- The component list describes each new basis in business language.
- This change does not alter attendance or decide whether EMP/00014 has 9 or
  another number of paid days.

Acceptance criteria:

- PF and ESI can be configured without fixed amounts.
- Reloading an employee preserves the selected calculation basis and rate.
- Invalid or missing percentages remain blocked by existing validation.
- Focused Flutter analysis and tests pass.
## Template-selected email for printable documents

- Date: 2026-09-02
- Status: Implemented

Every document exposed through the shared print preview must offer one Email
PDF action when it has a persisted document id. Email must never be sent on the
first click: the user first selects an active email template scoped to the
document's module and exact document type, then confirms the action. The PDF is
generated by the existing client print-template renderer and attached to a
server-validated document email request.

For Sales Invoices, retain the Email PDF action inside the document preview and
also expose it in the invoice page's top-right action bar and as a compact
Email PDF column immediately after Status in the invoice register. The header
and register actions are enabled only for a persisted non-draft,
non-cancelled invoice, prompt for a template, and send in place without opening
the print preview; they must reuse one direct-send implementation.

The server is authoritative for document existence, module action permission,
template activity and scope, recipient lookup, placeholder rendering, and PDF
attachment validation. Sales documents resolve active customer contacts;
purchase documents resolve active supplier contacts; HR payslips resolve the
employee email. Missing recipients, missing templates, invalid template scope,
invalid PDFs, disabled manual email, and delivery failures must produce useful
errors. Repeated taps are disabled while selection, PDF generation, or sending
is in progress. Existing `email_messages` remains the delivery/audit record.

The supported document-type registry is the same bounded registry used by the
shared print system: Sales quotation, proforma invoice, order, delivery,
invoice, receipt, and return; Purchase order, receipt, invoice, payment, and
return; and HR payslip. No Sales Payment entity is introduced.

Acceptance criteria:

1. Email PDF is visible only for persisted printable documents and permitted
   users.
2. Every Email PDF action opens template selection before PDF generation or
   delivery.
3. Only active templates matching module, document type, and company scope are
   selectable.
4. The existing PDF renderer, template placeholder engine, party/employee
   email lookup, MIME attachment delivery, notifications, and email history are
   reused.
5. Rapid taps cannot create duplicate sends, and canceling template selection
   sends nothing.
6. Focused frontend and backend tests cover filtering, authorization, missing
   recipients, invalid templates/PDFs, successful attachment delivery, and
   duplicate-send UI protection.
7. A selected non-draft, non-cancelled Sales Invoice can select a template and
   send its PDF directly from the top-right page action, while drafts,
   cancelled invoices, and no selection leave that action unavailable.
8. The Sales Invoice register places Email PDF directly after Status and its
   per-row action prompts for a template, generates, and sends the selected
   invoice PDF in place without navigating to the invoice editor or preview;
   ineligible rows remain visibly unavailable.

## 2026-09-03 — StaffU-inspired project task Kanban board

### Objective

Replace the standalone Project Tasks list/editor presentation with a responsive
Kanban board based on the extracted StaffU `/task` design while preserving the
ERP task API, validation, permissions, and embedded Project-subtab workflow.

### Scope and requirements

- `/projects/tasks` must group the already-loaded, already-authorized tasks into
  the backend statuses `open`, `working`, `on_hold`, `completed`, and
  `cancelled` without inventing a new status or priority field.
- The current status, employee, and text filters must continue to determine
  board visibility. The ordinary task route defaults to All Statuses so the
  Completed lane is discoverable; dashboard links may still request Pending.
  Pending shows Open, In Progress, and On Hold lanes; an exact status shows one
  lane; All Statuses shows all five lanes.
- Task cards must expose available task code/project context, due date,
  description, billable state, progress, and assigned employees, and must open
  the existing validated task editor when selected.
- Add, edit, save, delete, loading, retry, permission, and error behavior must
  remain available. The editor must continue to use the typed model/service and
  existing shared fields and validators.
- A persisted task card must be draggable between visible lanes. A drop must
  optimistically update the board, persist the destination's existing backend
  status through the typed task update service, invalidate the cached nested
  project/task collection before the authoritative reload, block duplicate
  moves for the same task, and restore the prior board state with visible
  feedback on failure. A successful move must not be overwritten by stale
  pre-mutation project cache data.
- Dragging must not invent an `in_review` value: the available lanes remain the
  API-supported Open, Working, On Hold, Completed, and Cancelled statuses.
- Desktop/tablet boards may use horizontal lanes; narrow layouts must remain
  readable without shrinking cards below a usable width.
- The Project master embedded Tasks subtab remains the existing compact
  expandable workflow because it shares space with the parent editor.

### Acceptance criteria and tests

- Grouping is a single pass over visible rows and preserves row order inside
  each lane.
- Pending, all, exact-status, and unknown-status inputs produce deterministic
  lane sets.
- A valid cross-lane drop requests exactly one status mutation, while same-lane,
  unsaved, and already-moving cards are rejected.
- After a successful mutation, cache invalidation occurs before the
  authoritative reload so the card remains visibly in its destination lane.
- The standalone screen renders the StaffU-inspired toolbar, tinted lanes,
  cards, progress, assignee summaries, and add actions in light and dark themes.
- No backend, database, route, authorization, or payload change is introduced.
- Focused tests cover lane selection and grouping; formatting, focused analysis,
  and focused tests are executed.

## 2026-09-03 — StaffU-inspired project milestone Kanban board

### Objective

Extend and reuse the StaffU-style Kanban board functionality introduced for
Project Tasks to the standalone Project Milestones module (`/projects/milestones`),
providing responsive drag-and-drop milestone status tracking while preserving
ERP milestone validation, permissions, and embedded Project subtab behavior.

### Scope and requirements

- Provide a single unified `ProjectKanbanBoard<T extends Object>` widget with
  named factory constructors `ProjectKanbanBoard.task` and
  `ProjectKanbanBoard.milestone`, directly reused by both `/projects/tasks` and
  `/projects/milestones`.
- All colors strictly use application theme tokens without ad-hoc alpha or created colors.
- `/projects/milestones` groups milestones into the backend statuses `open`,
  `completed`, and `cancelled` defined in `milestone_status` schema.
- The status and text filters determine board visibility: `pending` displays the
  Open lane; `all` displays Open, Completed, and Cancelled lanes; exact status
  filters display their respective single lane.
- Milestone cards expose target date, completion date, formatted milestone
  amount badge, milestone name, remarks snippet, project context, and actions
  menu (Edit, Delete) with drag handle indicator.
- Persisted milestone cards support drag-and-drop between lanes. Drops
  optimistically update the board, invoke `updateMilestone` via `ProjectService`,
  invalidate the project collection cache, reload authoritatively, and roll
  back gracefully on failure with error feedback.
- The Project master embedded Milestones subtab remains the compact expandable
  tile workflow (`ProjectSubtabExpandableSection`).

### Acceptance criteria and tests

- Grouping preserves order in O(n) time.
- Status filters (`pending`, `all`, exact, fallback) deterministically select
  lanes.
- Cross-lane drops are validated: same-status, unsaved, and in-flight moving
  cards are rejected.
- Unit and widget tests cover lane resolution, grouping, drop validation, and
  status transformations.
- `flutter test` and `flutter analyze` pass with zero regressions.

## 2026-09-04 — Stock Movement party, item, and type filters

### Objective

Make the Stock Movement register useful for tracing item movement by customer,
supplier, item, and movement type without loading unbounded movement history or
calculating overall quantities from only the visible page.

### Scope and business rules

- Reuse the shared expandable `AppRegisterFilters` surface, including automatic
  debounced application, the shared Clear action, and individual field clear
  controls.
- Provide multi-select Customer, Supplier, Item, and Type filters. Customer and
  Supplier selections are combined as an inclusive party match because one
  stock movement can originate from only one linked business document.
- Resolve Customer and Supplier through the movement's persisted
  `reference_table` and `reference_id`. Movements without a matching customer-
  or supplier-owned source document do not match an active party filter.
- Filter and paginate on the server. A filter change issues one stock-movement
  list request; active party and item option lists reuse the tenant-scoped
  master-data cache.
- Show the resolved Customer or Supplier name in a Party column for linked
  movements. Internal movements show no party.
- Provide explicit suggestion chips for common Customer movements, Supplier
  movements, and Transfers. A suggestion changes Type only after the user
  selects it.
- Always show page and overall movement totals using the user-facing labels
  Stock In, Stock Out, and Net. Present the values in a summary table with
  Page total and Overall page total rows. Overall totals are computed over the
  fully filtered server query and returned with the same paginated response.
  The summary remains visible with no filters and with any combination of
  customer, supplier, item, type, date, and search filters.

### Acceptance criteria

1. Each filter can be selected, combined, and cleared without an Apply button.
2. Customer and Supplier filters match their linked Sales, Purchase, or Jobwork
   source documents and preserve company/context scoping.
3. Type and Item accept one or more values and are applied before pagination.
4. A filter interaction produces no duplicate stock-movement request.
5. Party labels are returned for the visible page without per-row API calls.
6. Page and overall quantity totals remain visible and correct across filters
   and pages.
7. Loading, empty, error, retry, and remote pagination behavior remain intact.
