# Sales Invoice Export: Linked Sales Returns

**Date:** 2026-07-29  
**Scope:** Sales Invoice Excel export

## Specification

When an exported sales invoice has linked, active sales returns, the workbook
adds one row for each return. The row uses the return date and return number,
and exports quantity, taxable value, GST, and amount as positive values.
Cancelled or inactive returns are not exported.

The first Excel column is **Document Type**. Invoice rows are marked `SALES
INVOICE` and linked return rows are marked `SALES RETURN`. This label remains
present when the user filters the Sales Invoice register before exporting.

When a date range is applied, invoices are selected by `invoice_date` and
returns are selected independently by `return_date`. The workbook places all
invoice rows first and writes the matching returns in a separate **Sales
Returns** section at the bottom. This includes a return whose original invoice
falls outside the selected date range.

The Qty cell continues to count only inventory-tracked items. A non-inventory
shipping or delivery charge remains part of the negative financial values but
does not change Qty.

## API contract

The invoice export response now includes `sales_returns`, each with `lines`,
`lines.item`, and `lines.tax_code`. The frontend relies on `return_qty` and
the item's `track_inventory` flag.

## Rationale

Keeping linked returns as separate rows preserves the original invoice and
makes the return date and document number available in Excel. An explicit
document-type label prevents return rows from being mistaken for invoices,
including in filtered exports.

## Verification

- Targeted Flutter analysis.
- Existing Flutter regression test.
- PHP syntax validation for the backend relationship change.

## Related records

- [`../../billing-api/doc/sales-invoice-export-sales-returns.md`](../../billing-api/doc/sales-invoice-export-sales-returns.md)
- [`../../docs/decisions/2026-07-29-sales-invoice-export-sales-returns.md`](../../docs/decisions/2026-07-29-sales-invoice-export-sales-returns.md)
- [`../../docs/decisions/2026-08-04-sales-invoice-export-return-date-sections.md`](../../docs/decisions/2026-08-04-sales-invoice-export-return-date-sections.md)
