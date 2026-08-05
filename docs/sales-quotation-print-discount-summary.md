# Sales Quotation Print Discount Summary

**Date:** 2026-08-05  
**Scope:** Sales Quotation print-template data

## Objective

Make the placeholders `{{discount_summary_label}}` and
`{{discount_amount}}` available to Sales Quotation print templates.

## Requirements

- Calculate the document discount as gross line value minus taxable line value,
  summed across quotation lines.
- Set `discount_summary_label` to `DISCOUNT :` when the rounded discount is
  non-zero; otherwise set it to an empty string.
- Set `discount_amount` to the rounded document discount.
- Present `discount_amount` as a positive value; the `DISCOUNT :` label conveys
  that it is a deduction.
- Normalize legacy/custom Sales Quotation total-value shapes that bind
  `{{subtotal}}` so they bind `{{total_amount}}`; do not replace legitimate
  subtotal rows elsewhere in the template.
- The displayed total must equal the already calculated net quotation amount;
  the summary discount is presentation-only and must not be subtracted again.
- In the quotation item table, `line_total` and the table footer total must show
  the original gross line amount before discount. The discount is shown
  separately in the summary.
- Reset All and Reset Selected must apply the same gross table-footer rule when
  they restore the default quotation table.
- Normalize a legacy table column labelled `Amount` when it is bound to
  `taxable_amount`, or has `line_total` with GST excluded, so it uses the gross
  `line_total` value. Do not alter a column explicitly labelled `Taxable
  Amount`.
- Remove a manually entered minus sign adjacent to `{{discount_amount}}` in a
  saved Sales Quotation template.
- Preserve quotation subtotal, tax, total, amount-in-words, and line behaviour.
- Make no API, database, or stored quotation changes.

## Acceptance criteria

1. A quotation containing a discount resolves both placeholders to the label and
   positive numeric discount amount without a minus symbol.
2. A quotation without a discount resolves the label to empty and the existing
   zero-value print rule hides the amount.
3. A legacy total-value shape using `{{subtotal}}` is corrected to
   `{{total_amount}}` while unrelated subtotal shapes remain unchanged.
4. For quantity 2, rate 100, and 10% discount, the table amount is 200, the
   discount summary is 20, and the final total is 180 before any tax/round-off.
5. Six focused regression tests passed on 2026-08-05, including legacy table
   binding, legacy exclude-GST handling, and hard-coded-minus normalization;
   focused Flutter analysis completed with no issues.
6. After Reset All, the restored Amount column and its table footer both show
   the gross quotation subtotal; the final Total Amount continues to show the
   discounted net document total.

## Related record

- [`../../docs/decisions/2026-08-05-sales-quotation-print-discount-summary.md`](../../docs/decisions/2026-08-05-sales-quotation-print-discount-summary.md)
