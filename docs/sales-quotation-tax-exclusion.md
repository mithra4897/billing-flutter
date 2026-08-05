# Sales Quotation Tax Exclusion

**Date:** 2026-08-05  
**Scope:** Sales Quotation entry, storage, totals, and print data

## Objective

Do not apply GST or cess to Sales Quotations.

## Requirements

- A quotation line's amount is quantity × rate less its discount; no tax is
  added.
- Hide the tax-code column from the Sales Quotation line editor.
- Ignore tax codes from legacy or API-sent quotation lines and store no tax code
  or tax amounts on quotation lines.
- Persist all quotation CGST, SGST, IGST, and cess amounts as zero.
- Print data and final quotation totals exclude tax.
- Do not change tax handling for orders, invoices, deliveries, returns, or any
  other document type.

## Acceptance criteria

1. A discounted quotation line with a tax code still has zero tax and a
   tax-free final total.
2. Saved quotation lines have a null tax code and zero tax values.
3. The quotation editor does not display a tax-code column.
4. Focused Flutter and backend tests pass.
