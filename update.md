# Purchase Order Linked Supplier/Requisition Filtering

## What was implemented

The Purchase Order editor now supports linked filtering between `Supplier` and `Requisition`.

### 1. Requisition selected first
- The selected requisition detail is loaded.
- Purchase Order lines are auto-filled from requisition lines.
- The `Supplier` dropdown is filtered to suppliers available through `item_supplier_map` for those requisition items.

### 2. Supplier selected first
- The selected supplier is used to filter the `Requisition` dropdown.
- Only requisitions with at least one line item mapped to that supplier stay available.
- If no requisition is selected yet, Purchase Order lines are auto-filled from `item_supplier_map`.

### 3. When both are selected
- Purchase Order lines are rebuilt using only the common items between:
  - requisition lines
  - supplier item mappings
- Requisition demand remains the source for quantity.
- Supplier mapping remains the source for default purchase rate and preferred purchase UOM.

## Line field mapping

### From requisition to PO
- `purchase_requisition_line_id`
- `item_id`
- `warehouse_id`
- `uom_id`
- `description`
- `pending_qty` or `requested_qty` -> `ordered_qty`
- `remarks`

### From supplier mapping to PO
- `supplier_rate` -> `rate`
- `purchase_uom_id` -> `uom_id` fallback/preference
- item master `tax_code_id`

## User feedback

- If some requisition items are not mapped to the selected supplier, those items are excluded from the PO lines.
- A small info message is shown in the editor telling how many items were excluded.

## Files changed

- `lib/View/purchase/purchase_order_page.dart`

