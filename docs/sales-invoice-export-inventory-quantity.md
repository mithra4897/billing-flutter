# Sales Invoice Export: Inventory Quantity Only

**Date:** 2026-07-29  
**Scope:** Sales Invoice Excel export

## Specification

The `Qty` value for each exported invoice is the sum of invoiced quantities for
items where `item.track_inventory` is enabled. Non-inventory items, such as
shipping or delivery charges, are excluded from that quantity.

Taxable amount, GST, and invoice amount continue to include every invoice line.

## Rationale

Non-inventory charges can have a quantity for pricing, but that quantity is not
product stock. Including it makes the exported product quantity misleading.

## Implementation

- `lib/components/sales_invoice_export_button.dart` adds a line quantity to
  `totalQty` only when the exported line item has `track_inventory: true`.
- The existing API relation `lines.item` supplies this flag; no API or database
  change is required.

## Acceptance criteria

- Product quantity 4 plus shipping-charge quantity 1 exports as `Qty = 4`.
- A non-inventory line still contributes to taxable amount, GST, and amount.
- An invoice with no inventory-tracked lines has a blank Qty cell, following
  the existing zero-value export rule.

## Verification

- Targeted Flutter analysis.
- Existing Flutter regression test.

## Related engineering record

- [`../../docs/decisions/2026-07-29-sales-invoice-export-inventory-quantity.md`](../../docs/decisions/2026-07-29-sales-invoice-export-inventory-quantity.md)
