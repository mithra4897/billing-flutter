# Sales Invoice Export: Normalize GST Components by Place of Supply

**Date:** 2026-08-05  
**Scope:** Sales Invoice Excel export, including linked sales returns

## Problem

Some documents contain a stored GST component split that conflicts with the
customer GSTIN/state. Preserving those values causes Tamil Nadu invoices to
continue appearing under IGST in the spreadsheet.

## Required behaviour

- Start with the saved document GST total, falling back to calculated line
  components only when saved components are unavailable.
- Determine place of supply using company and customer state codes.
- Prefer a customer's GSTIN prefix over conflicting address state text.
- Normalize Indian state names such as `Tamil Nadu`, `TamilNadu`, and
  `Pondicherry` to GST state codes before comparison.
- For intra-state documents, export the combined GST amount equally as CGST and
  SGST. For inter-state documents, export the combined GST amount as IGST.
- If place of supply cannot be resolved, preserve the source component split.
- Keep HSN, GST rate, inventory quantity, taxable amount, and total amount export
  behaviour unchanged as part of this GST normalization. The later first-HSN
  summary rule is documented in
  [sales-invoice-export-returned-invoices-first-hsn.md](sales-invoice-export-returned-invoices-first-hsn.md).
- Keep zero tax cells blank under the existing export presentation rule.

## Acceptance criteria

1. A Tamil Nadu invoice stored under IGST exports the same tax total as equal
   CGST and SGST values.
2. A genuine inter-state GSTIN exports the same tax total under IGST, even when
   its address state text conflicts.
3. No tax is added or removed during component normalization.
4. Unknown place-of-supply records keep their stored/calculated component split.
5. Sales returns follow the same rule.

## Verification

- Eight unit tests cover both reclassification directions, unknown place of
  supply, saved/fallback components, and Indian state-name normalization; all
  passed on 2026-08-05.
- Focused `flutter analyze` completed with no issues on 2026-08-05.

## Compatibility

This is an export-only correction. It changes no API, database schema, stored
invoice, posting, or tax calculation behaviour.

## Related engineering record

- [`../../docs/decisions/2026-08-05-sales-invoice-export-place-of-supply-normalization.md`](../../docs/decisions/2026-08-05-sales-invoice-export-place-of-supply-normalization.md)
