# Sales Invoice Export: Returned Invoices and First HSN

**Date:** 2026-09-05  
**Status:** Implemented  
**Scope:** Sales Invoice Excel export and its export-data API

## Objective

Keep the selected invoice in the workbook when it is Partially returned or
Returned, while continuing to show each linked Sales Return as a separate
document row. Represent a multi-line document with one deterministic HSN/SAC
value in its summary row.

## Business rules

- Every selected invoice returned by the scoped export query is exported,
  including invoices whose status is `partially_returned` or `returned`.
- Active, non-cancelled Sales Returns remain in the separate Sales Returns
  section. They do not replace or suppress the original invoice row.
- The HSN cell contains the first non-empty item HSN/SAC code in persisted line
  order. Later HSN/SAC values are not appended.
- The same first-HSN summary rule applies to invoice and Sales Return rows,
  because both use the shared document-row builder.
- Existing company, branch, location, financial-year, selected-ID, and return-
  date scoping remains unchanged.
- No database values, accounting entries, or document statuses are modified.

## Acceptance criteria

1. A multi-item invoice with line HSN values `1001` then `2002` exports `1001`.
2. If the first line has no HSN and the second line has `2002`, the export uses
   `2002`.
3. A selected Partially returned or Returned invoice has its own Sales Invoice
   row and its active linked return has a separate Sales Return row.
4. Cancelled or inactive returns remain excluded.
5. A returned invoice is not reported as skipped when its invoice record is
   present in the API response.

## Performance and compatibility

HSN selection remains part of the existing single O(n) pass over document
lines and uses O(1) additional HSN storage. The endpoint response shape and
database schema do not change.
