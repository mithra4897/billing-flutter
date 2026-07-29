# Sales Invoice Export: Linked Sales Returns

**Date:** 2026-07-29  
**Scope:** Sales Invoice Excel export

## Specification

When an exported sales invoice has linked, active sales returns, the workbook
adds one row for each return. The row uses the return date and return number,
and exports quantity, taxable value, GST, and amount as positive values.
Cancelled or inactive returns are not exported.

The Qty cell continues to count only inventory-tracked items. A non-inventory
shipping or delivery charge remains part of the negative financial values but
does not change Qty.

## API contract

The invoice export response now includes `sales_returns`, each with `lines`,
`lines.item`, and `lines.tax_code`. The frontend relies on `return_qty` and
the item's `track_inventory` flag.

## Rationale

Keeping linked returns as separate rows preserves the original invoice and
makes the return date and document number available in Excel without adding a
return label to the report.

## Verification

- Targeted Flutter analysis.
- Existing Flutter regression test.
- PHP syntax validation for the backend relationship change.

## Related records

- [`../../billing-api/doc/sales-invoice-export-sales-returns.md`](../../billing-api/doc/sales-invoice-export-sales-returns.md)
- [`../../docs/decisions/2026-07-29-sales-invoice-export-sales-returns.md`](../../docs/decisions/2026-07-29-sales-invoice-export-sales-returns.md)
