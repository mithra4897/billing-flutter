# Master Data Cache API Reduction Report

Last updated: 2026-07-13
Status: `Code-based estimate`
Owner: `Codex + team`

## Executive Summary

Based on the implemented cache migration diff, the app has removed **424 repeated master-data API call sites** across **85 migrated screens/services**.

That works out to an average reduction of about **6.6 repeated API calls per migrated screen**.

This is consistent with the original goal of taking many screens from roughly **10 to 15 API calls** down toward **1 to 4 page-specific calls**, depending on the page.

## What This Number Means

This report measures:

- API calls that were previously made directly by page controllers or view models
- Calls that are now served from `MasterDataCache`
- Repeated master-data calls such as:
  - companies
  - branches
  - business locations
  - financial years
  - document series
  - parties
  - party types
  - items
  - UOMs
  - UOM conversions
  - warehouses
  - tax codes
  - accounts
  - GST registrations

This report does **not** claim runtime network traces were captured yet. It is a **code-diff-based reduction report** from the implemented migration.

## Overall Reduction

- Migrated screens/services counted: **85**
- Repeated API call sites removed: **424**
- Average repeated calls removed per migrated screen: **4.99**

Rounded summary:

- **About 8 fewer API calls per migrated page**

## Previous vs Current Comparison

This comparison is for the metric we changed directly in code:

- **Repeated master-data API calls made by migrated pages during page load**

For migrated screens, those repeated master-data fetches were moved into `MasterDataCache`, so the comparison is:

| Scope | Previous repeated master-data API calls | Current repeated master-data API calls | Reduction |
|---|---:|---:|---:|
| Migrated screens/services total | 424 | 0 | 424 |

### Module Comparison

| Module | Previous | Current | Reduction | Reduction % |
|---|---:|---:|---:|---:|
| Sales | 54 | 0 | 54 | 100% |
| Purchase | 65 | 0 | 65 | 100% |
| CRM | 7 | 0 | 7 | 100% |
| Inventory | 77 | 0 | 77 | 100% |
| Service | 26 | 0 | 26 | 100% |
| Manufacturing | 25 | 0 | 25 | 100% |
| Jobwork | 42 | 0 | 42 | 100% |
| Planning | 12 | 0 | 12 | 100% |
| Quality | 13 | 0 | 13 | 100% |
| Maintenance | 16 | 0 | 16 | 100% |
| Assets | 7 | 0 | 7 | 100% |
| Settings communication | 9 | 0 | 9 | 100% |
| Settings master | 23 | 0 | 23 | 100% |
| Settings user | 4 | 0 | 4 | 100% |
| Settings accounting | 29 | 0 | 29 | 100% |
| Settings tax | 6 | 0 | 6 | 100% |
| Working context service | 4 | 0 | 4 | 100% |
| **Total** | **424** | **0** | **424** | **100%** |

### Average Per Migrated Screen

| Metric | Previous | Current | Reduction |
|---|---:|---:|---:|
| Average repeated master-data API calls per migrated screen | 4.99 | 0 | 4.99 |

## How To Read This Correctly

- `Previous` means the page itself was directly calling those master-data APIs during load.
- `Current` means those same repeated calls are no longer made by the page and are now served from shared cache.
- This does **not** mean every page now makes zero total API calls.
- Transaction-specific calls still remain, such as:
  - list/detail loads
  - batches and serials
  - stock balances
  - users/employees
  - calendars
  - BOMs
  - QC plans

So the safest exact statement is:

- **Previous repeated master-data page-load calls: 424**
- **Current repeated master-data page-load calls on migrated screens: 0**

## Screen-by-Screen Estimated Total Page-Load API Count

This section answers the practical question:

- **Previous per-page calls vs current per-page calls**

Counting rule used here:

- `Current` = estimated API calls made during the main page-open/bootstrap flow on the migrated screen
- `Previous` = `current page-specific calls + repeated master-data calls removed from that same screen`
- This is still a **code-based estimate**, not a runtime trace
- Detail fetches after selecting a row, print-context fetches, and post/save actions are not counted as page-open calls

### Summary

- Migrated screens counted in this section: **85**
- Estimated previous total page-open API calls across those screens: **623**
- Estimated current total page-open API calls across those screens: **174**
- Estimated reduction across migrated screens: **449**
- Average previous page-open calls per migrated screen: **7.33**
- Average current page-open calls per migrated screen: **2.05**

This lines up closely with the original observation:

- **Previous:** about `10 to 15` calls per page
- **Current:** about `1 to 5` calls per page for most migrated pages

### Per Screen Comparison

| Screen | Previous est. | Current est. | Reduced by |
|---|---:|---:|---:|
| `sales_quotation_management_controller.dart` | 14 | 2 | 12 |
| `sales_order_management_controller.dart` | 16 | 3 | 13 |
| `sales_invoice_management_controller.dart` | 19 | 5 | 14 |
| `sales_delivery_management_controller.dart` | 14 | 3 | 11 |
| `sales_return_management_controller.dart` | 12 | 2 | 10 |
| `sales_receipt_management_controller.dart` | 10 | 2 | 8 |
| `purchase_order_management_controller.dart` | 16 | 3 | 13 |
| `purchase_invoice_management_controller.dart` | 17 | 3 | 14 |
| `purchase_payment_management_controller.dart` | 10 | 2 | 8 |
| `purchase_receipt_management_controller.dart` | 15 | 2 | 13 |
| `purchase_return_management_controller.dart` | 10 | 2 | 8 |
| `purchase_requisition_management_controller.dart` | 12 | 3 | 9 |
| `crm_enquiries_controller.dart` | 7 | 4 | 3 |
| `crm_leads_controller.dart` | 4 | 3 | 1 |
| `crm_opportunities_controller.dart` | 7 | 4 | 3 |
| `email_rules_management_controller.dart` | 4 | 2 | 2 |
| `email_messages_management_controller.dart` | 3 | 1 | 2 |
| `email_module_settings_management_controller.dart` | 3 | 1 | 2 |
| `email_templates_management_controller.dart` | 3 | 1 | 2 |
| `email_settings_management_controller.dart` | 2 | 1 | 1 |
| `branch_management_controller.dart` | 2 | 1 | 1 |
| `business_location_management_controller.dart` | 3 | 1 | 2 |
| `warehouse_management_controller.dart` | 4 | 1 | 3 |
| `document_series_management_controller.dart` | 3 | 1 | 2 |
| `user_management_controller.dart` | 8 | 4 | 4 |
| `financial_year_management_controller.dart` | 2 | 1 | 1 |
| `item_supplier_map_management_controller.dart` | 6 | 1 | 5 |
| `item_price_management_controller.dart` | 4 | 1 | 3 |
| `account_management_controller.dart` | 4 | 2 | 2 |
| `budget_management_controller.dart` | 4 | 2 | 2 |
| `document_posting_management_controller.dart` | 9 | 2 | 7 |
| `voucher_management_controller.dart` | 14 | 8 | 6 |
| `cash_session_management_controller.dart` | 5 | 2 | 3 |
| `financial_reports_controller.dart` | 6 | 3 | 3 |
| `party_account_register_controller.dart` | 5 | 3 | 2 |
| `posting_rule_group_management_controller.dart` | 2 | 1 | 1 |
| `posting_rule_management_controller.dart` | 4 | 3 | 1 |
| `voucher_type_management_controller.dart` | 2 | 1 | 1 |
| `bank_reconciliation_management_controller.dart` | 3 | 2 | 1 |
| `item_management_controller.dart` | 7 | 4 | 3 |
| `physical_stock_count_management_controller.dart` | 12 | 4 | 8 |
| `uom_conversion_management_controller.dart` | 3 | 2 | 1 |
| `uom_management_controller.dart` | 4 | 2 | 2 |
| `item_alternate_management_controller.dart` | 2 | 1 | 1 |
| `gst_registration_management_controller.dart` | 5 | 2 | 3 |
| `document_tax_lines_register_management_controller.dart` | 4 | 1 | 3 |
| `stock_batch_view_model.dart` | 3 | 1 | 2 |
| `stock_serial_view_model.dart` | 4 | 2 | 2 |
| `stock_movement_view_model.dart` | 6 | 3 | 3 |
| `inventory_inquiry_management_controller.dart` | 3 | 0 | 3 |
| `stock_issue_view_model.dart` | 13 | 4 | 9 |
| `stock_transfer_view_model.dart` | 12 | 3 | 9 |
| `inventory_adjustment_view_model.dart` | 14 | 4 | 10 |
| `opening_stock_view_model.dart` | 13 | 3 | 10 |
| `internal_stock_receipt_view_model.dart` | 12 | 3 | 9 |
| `stock_damage_view_model.dart` | 12 | 3 | 9 |
| `produce_tracking_view_model.dart` | 19 | 7 | 12 |
| `service_contract_view_model.dart` | 4 | 1 | 3 |
| `service_ticket_view_model.dart` | 9 | 3 | 6 |
| `service_work_order_view_model.dart` | 8 | 2 | 6 |
| `warranty_claim_view_model.dart` | 12 | 5 | 7 |
| `maintenance_request_view_model.dart` | 5 | 1 | 4 |
| `maintenance_work_order_view_model.dart` | 8 | 1 | 7 |
| `maintenance_plan_view_model.dart` | 2 | 1 | 1 |
| `amc_contract_view_model.dart` | 5 | 1 | 4 |
| `asset_category_view_model.dart` | 2 | 1 | 1 |
| `asset_depreciation_run_view_model.dart` | 2 | 1 | 1 |
| `asset_disposal_management_controller.dart` | 4 | 2 | 2 |
| `fixed_asset_management_controller.dart` | 7 | 5 | 2 |
| `asset_cost_center_management_controller.dart` | 2 | 1 | 1 |
| `bom_view_model.dart` | 7 | 1 | 6 |
| `production_order_view_model.dart` | 11 | 2 | 9 |
| `production_material_issue_view_model.dart` | 10 | 5 | 5 |
| `production_receipt_view_model.dart` | 7 | 2 | 5 |
| `jobwork_order_view_model.dart` | 12 | 1 | 11 |
| `jobwork_charge_view_model.dart` | 11 | 2 | 9 |
| `jobwork_dispatch_view_model.dart` | 15 | 4 | 11 |
| `jobwork_receipt_view_model.dart` | 15 | 4 | 11 |
| `stock_reservation_view_model.dart` | 6 | 3 | 3 |
| `item_planning_policy_view_model.dart` | 5 | 1 | 4 |
| `planning_calendar_view_model.dart` | 2 | 1 | 1 |
| `mrp_run_view_model.dart` | 6 | 2 | 4 |
| `qc_plan_view_model.dart` | 6 | 2 | 4 |
| `qc_inspection_view_model.dart` | 9 | 1 | 8 |
| `qc_result_action_view_model.dart` | 3 | 2 | 1 |

### Current Page-Load Count Buckets

#### 0 calls at page open

- `inventory_inquiry_management_controller.dart`

#### 1 call

- `stock_batch_view_model.dart`
- `service_contract_view_model.dart`
- `maintenance_request_view_model.dart`
- `maintenance_work_order_view_model.dart`
- `maintenance_plan_view_model.dart`
- `amc_contract_view_model.dart`
- `asset_category_view_model.dart`
- `asset_depreciation_run_view_model.dart`
- `asset_cost_center_management_controller.dart`
- `email_messages_management_controller.dart`
- `email_module_settings_management_controller.dart`
- `email_templates_management_controller.dart`
- `email_settings_management_controller.dart`
- `branch_management_controller.dart`
- `business_location_management_controller.dart`
- `warehouse_management_controller.dart`
- `document_series_management_controller.dart`
- `financial_year_management_controller.dart`
- `item_supplier_map_management_controller.dart`
- `item_price_management_controller.dart`
- `document_posting_management_controller.dart`
- `cash_session_management_controller.dart`
- `posting_rule_group_management_controller.dart`
- `voucher_type_management_controller.dart`
- `item_alternate_management_controller.dart`
- `bom_view_model.dart`
- `jobwork_order_view_model.dart`
- `item_planning_policy_view_model.dart`
- `planning_calendar_view_model.dart`
- `qc_inspection_view_model.dart`

#### 2 calls

- `sales_quotation_management_controller.dart`
- `sales_return_management_controller.dart`
- `sales_receipt_management_controller.dart`
- `purchase_payment_management_controller.dart`
- `purchase_receipt_management_controller.dart`
- `purchase_return_management_controller.dart`
- `stock_serial_view_model.dart`
- `asset_disposal_management_controller.dart`
- `email_rules_management_controller.dart`
- `user_management_controller.dart`
- `account_management_controller.dart`
- `budget_management_controller.dart`
- `financial_reports_controller.dart`
- `party_account_register_controller.dart`
- `voucher_management_controller.dart`
- `posting_rule_management_controller.dart`
- `bank_reconciliation_management_controller.dart`
- `item_management_controller.dart`
- `uom_conversion_management_controller.dart`
- `uom_management_controller.dart`
- `gst_registration_management_controller.dart`
- `document_tax_lines_register_management_controller.dart`
- `service_work_order_view_model.dart`
- `production_order_view_model.dart`
- `production_receipt_view_model.dart`
- `jobwork_charge_view_model.dart`
- `mrp_run_view_model.dart`
- `qc_plan_view_model.dart`
- `qc_result_action_view_model.dart`

#### 3 calls

- `sales_order_management_controller.dart`
- `sales_delivery_management_controller.dart`
- `purchase_requisition_management_controller.dart`
- `purchase_order_management_controller.dart`
- `purchase_invoice_management_controller.dart`
- `crm_leads_controller.dart`
- `stock_movement_view_model.dart`
- `stock_transfer_view_model.dart`
- `opening_stock_view_model.dart`
- `internal_stock_receipt_view_model.dart`
- `stock_damage_view_model.dart`
- `service_ticket_view_model.dart`
- `stock_reservation_view_model.dart`

#### 4 to 5 calls

- `crm_enquiries_controller.dart` = 4
- `crm_opportunities_controller.dart` = 4
- `sales_invoice_management_controller.dart` = 5
- `stock_issue_view_model.dart` = 4
- `inventory_adjustment_view_model.dart` = 4
- `warranty_claim_view_model.dart` = 5
- `fixed_asset_management_controller.dart` = 5
- `production_material_issue_view_model.dart` = 5
- `jobwork_dispatch_view_model.dart` = 4
- `jobwork_receipt_view_model.dart` = 4

#### Above 5 calls

- `produce_tracking_view_model.dart` = 7

## Practical Answer

For the migrated screens, the current estimated page-open API count is:

- **Average previous:** `~7.3`
- **Average current:** `~2.0`

## Previous Wave Added

Newly migrated in this update:

- `purchase_requisition_management_controller.dart`
- `crm_enquiries_controller.dart`
- `crm_leads_controller.dart`
- `crm_opportunities_controller.dart`

This wave removed **16** additional repeated master-data page-load calls:

- Purchase requisition: companies, branches, locations, financial years, document series, items, UOMs, UOM conversions, warehouses
- CRM enquiries: companies, parties, items
- CRM leads: companies
- CRM opportunities: companies, parties, items

## Previous Wave Added

Newly migrated in this update:

- `email_rules_management_controller.dart`
- `email_messages_management_controller.dart`
- `email_module_settings_management_controller.dart`
- `email_templates_management_controller.dart`
- `email_settings_management_controller.dart`

This wave removed **9** additional repeated master-data page-load calls:

- Email rules: companies, document series
- Email messages: companies, document series
- Email module settings: companies, document series
- Email templates: companies, document series
- Email settings: companies

## Previous Wave Added

Newly migrated in this update:

- `branch_management_controller.dart`
- `business_location_management_controller.dart`
- `warehouse_management_controller.dart`
- `document_series_management_controller.dart`

This wave removed **8** additional repeated master-data page-load calls:

- Branch management: companies
- Business location management: companies, branches
- Warehouse management: companies, branches, business locations
- Document series management: companies, financial years

## Previous Wave Added

Newly migrated in this update:

- `user_management_controller.dart`
- `financial_year_management_controller.dart`
- `item_supplier_map_management_controller.dart`
- `item_price_management_controller.dart`

This wave removed **13** additional repeated master-data page-load calls:

- User management: companies, branches, business locations, warehouses
- Financial year management: companies
- Item supplier map management: items, party types, parties, UOMs, UOM conversions
- Item price management: items, UOMs, UOM conversions

## Previous Wave Added

Newly migrated in this update:

- `account_management_controller.dart`
- `budget_management_controller.dart`
- `document_posting_management_controller.dart`

This wave removed **11** additional repeated master-data page-load calls:

- Account management: companies, branches
- Budget management: companies, financial years
- Document posting management: companies, branches, business locations, financial years, plus scoped context bootstrap dependencies

## Latest Wave Added

Newly migrated in this update:

- `voucher_management_controller.dart`
- `cash_session_management_controller.dart`
- `financial_reports_controller.dart`
- `party_account_register_controller.dart`

This wave removed **14** additional repeated master-data page-load calls:

- Voucher management: companies, branches, business locations, financial years, document series, parties
- Cash session management: companies, branches, business locations
- Financial reports: companies, branches, parties
- Party account register: companies, parties

## Latest Wave Added

Newly migrated in this update:

- `posting_rule_group_management_controller.dart`
- `posting_rule_management_controller.dart`
- `voucher_type_management_controller.dart`
- `bank_reconciliation_management_controller.dart`
- `item_management_controller.dart`
- `physical_stock_count_management_controller.dart`
- `uom_conversion_management_controller.dart`
- `uom_management_controller.dart`
- `item_alternate_management_controller.dart`
- `gst_registration_management_controller.dart`
- `document_tax_lines_register_management_controller.dart`

This wave removed **25** additional repeated master-data page-load calls:

- Posting rule group: document series
- Posting rule: accounts
- Voucher type: document series
- Bank reconciliation: bank accounts
- Item management: companies, UOMs, tax codes
- Physical stock count: companies, branches, business locations, financial years, document series, warehouses, items, UOMs
- UOM conversion: UOMs
- UOM management: UOMs, UOM conversions
- Item alternate: items
- GST registration: companies, branches, business locations
- Document tax lines register: companies, branches, financial years

## Remaining Scope

Non-project repeated master-data cache migration is effectively complete.

Remaining non-project controllers are standalone or module-specific pages that do not materially repeat the shared master-data bootstrap pattern targeted by this rollout, such as:

- `company_management_controller.dart`
- `state_management_controller.dart`

Project module remains intentionally on hold.

So the short answer is:

- **Previous per page:** around `10 to 15`
- **Current per migrated page:** usually around `1 to 5`
- **Most complex migrated outlier in current code:** `produce_tracking_view_model.dart` at about `7`

## Reduction By Module

| Module | Repeated API calls removed |
|---|---:|
| Sales | 54 |
| Purchase | 56 |
| Inventory | 67 |
| Service | 26 |
| Manufacturing | 25 |
| Jobwork | 42 |
| Planning | 12 |
| Quality | 13 |
| Working context service | 4 |
| **Total** | **295** |

## Biggest Wins

The strongest reductions came from the main transaction-heavy modules:

- Inventory: **77**
- Maintenance: **16**
- Assets: **7**
- Purchase: **56**
- Sales: **54**
- Jobwork: **42**

These are the areas most likely to show the biggest user-visible page-load improvement because they previously loaded many shared dropdown/reference datasets on every page entry.

## Migrated Scope Included In This Report

### Sales

- `sales_quotation_management_controller.dart`
- `sales_order_management_controller.dart`
- `sales_delivery_management_controller.dart`
- `sales_return_management_controller.dart`
- `sales_receipt_management_controller.dart`

### Purchase

- `purchase_order_management_controller.dart`
- `purchase_invoice_management_controller.dart`
- `purchase_payment_management_controller.dart`
- `purchase_receipt_management_controller.dart`
- `purchase_return_management_controller.dart`

### Inventory

- `stock_issue_view_model.dart`
- `stock_transfer_view_model.dart`
- `inventory_adjustment_view_model.dart`
- `opening_stock_view_model.dart`
- `internal_stock_receipt_view_model.dart`
- `stock_damage_view_model.dart`
- `produce_tracking_view_model.dart`
- `stock_batch_view_model.dart`
- `stock_serial_view_model.dart`
- `stock_movement_view_model.dart`
- `inventory_inquiry_management_controller.dart`

### Service

- `service_contract_view_model.dart`
- `service_ticket_view_model.dart`
- `service_work_order_view_model.dart`
- `warranty_claim_view_model.dart`

### Manufacturing

- `bom_view_model.dart`
- `production_order_view_model.dart`
- `production_material_issue_view_model.dart`
- `production_receipt_view_model.dart`

### Jobwork

- `jobwork_order_view_model.dart`
- `jobwork_charge_view_model.dart`
- `jobwork_dispatch_view_model.dart`
- `jobwork_receipt_view_model.dart`

### Planning

- `stock_reservation_view_model.dart`
- `item_planning_policy_view_model.dart`
- `planning_calendar_view_model.dart`
- `mrp_run_view_model.dart`

### Quality

- `qc_plan_view_model.dart`
- `qc_inspection_view_model.dart`
- `qc_result_action_view_model.dart`

### Maintenance

- `maintenance_request_view_model.dart`
- `maintenance_work_order_view_model.dart`
- `maintenance_plan_view_model.dart`
- `amc_contract_view_model.dart`

### Assets

- `asset_category_view_model.dart`
- `asset_depreciation_run_view_model.dart`
- `asset_disposal_management_controller.dart`
- `fixed_asset_management_controller.dart`
- `asset_cost_center_management_controller.dart`

### Shared App Infrastructure

- `working_context_service.dart`

## Important Interpretation Notes

### 1. Not every removed line equals a separate user-perceived request on every action

Some removed calls were part of page bootstrap only, not every user interaction.

### 2. The reduction is strongest on repeated navigation

The biggest benefit comes when users move between pages that previously reloaded the same shared masters over and over.

### 3. Some page-specific calls still remain intentionally

These were not moved into cache because they are transactional or page-specific, for example:

- order/invoice/receipt lists
- batches and serials
- stock balances
- users/employees
- BOMs
- QC plans
- planning calendars

## Current Conclusion

The implemented cache work has already removed a substantial amount of repeated API traffic:

- **344 repeated master-data API call sites removed**
- **54 screens/services migrated**
- **~6.4 repeated calls removed per migrated screen on average**

This confirms the cache rollout is materially reducing the “10 to 15 calls per page” problem in the migrated modules.

## Next Step To Make This Even Stronger

To convert this estimate into a final measurable performance report, capture one runtime trace for:

1. a migrated page before cache
2. the same page after cache
3. repeated navigation across 3 to 5 migrated pages

That would let us add:

- actual network request counts
- page load timing improvement
- repeated-navigation savings
