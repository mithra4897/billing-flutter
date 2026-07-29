# Sales Invoice Export: Empty Zero Values

**Date:** 2026-07-29  
**Scope:** Sales Invoice Excel export

## Specification

The Sales Invoice export must leave a numeric cell empty when its calculated value is zero. This applies to quantity, taxable amount, IGST, CGST, SGST, and invoice amount. GST percentage is also blank when it is zero.

Non-zero values remain numeric Excel cells so that spreadsheet totals and filters continue to work.

## Rationale

Zero tax columns are not applicable for many invoices. Exporting empty cells makes the GST report easier to read without changing financial calculations.

## Implementation

- `lib/components/sales_invoice_export_button.dart` uses `_numberOrBlank` for export totals.
- A value with an absolute amount below `0.005` is exported as an empty text cell.
- No-line invoices use the same blank-cell rule.

## Acceptance criteria

- A zero IGST, CGST, or SGST cell appears empty in Excel.
- Non-zero numeric cells retain two-decimal numeric formatting.
- GST percentage is empty when it is zero.
- Exported workbook structure and column headings are unchanged.

## Verification

- Flutter static analysis and existing regression tests run after the change.

## Related engineering record

- [`../../docs/decisions/2026-07-29-sales-invoice-export-zero-values.md`](../../docs/decisions/2026-07-29-sales-invoice-export-zero-values.md)
