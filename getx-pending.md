# GetX Pending Tracker

This tracker lists the remaining files that still need GetX MVC migration or cleanup.

Status legend:

| Status | Meaning |
| --- | --- |
| `pending` | Not migrated yet |
| `in_progress` | Currently being migrated |
| `done` | Completed and verified |
| `blocked` | Needs a decision or prerequisite |

## Pending Pages

| Area | File | Type | Status | Notes |
| --- | --- | --- | --- | --- |
| Assets | `lib/View/assets/asset_cost_center_page.dart` | page | `done` | Migrated to `AssetCostCenterManagementController` |
| Assets | `lib/View/assets/asset_disposal_page.dart` | page | `done` | Migrated to `AssetDisposalManagementController` |
| Assets | `lib/View/assets/fixed_asset_page.dart` | page | `done` | Migrated to `FixedAssetManagementController` |
| Auth | `lib/View/auth/login_page.dart` | page | `done` | Migrated to `LoginManagementController` |
| Core | `lib/View/core/app_bootstrap_page.dart` | page | `done` | Migrated to `AppBootstrapController` |
| Core | `lib/View/core/app_shell_page.dart` | page | `done` | Migrated to `AppShellController` |
| Dashboard | `lib/View/dashboard/crm_dashboard_page.dart` | page | `done` | Already stateless wrapper over shared ERP dashboard loader |
| Dashboard | `lib/View/dashboard/erp_module_dashboard_page.dart` | page | `done` | Migrated to `ErpModuleDashboardController` |
| HR | `lib/View/hr/employee_page.dart` | page | `done` | Fully moved employee page state off local `setState` to `EmployeeManagementController` |
| HR | `lib/View/hr/expense_claims_page.dart` | page | `done` | Migrated to `ExpenseClaimsManagementController` |
| HR | `lib/View/hr/hr_statutory_settings_page.dart` | page | `done` | Migrated to `HrStatutorySettingsController` |
| HR | `lib/View/hr/leave_request_page.dart` | page | `done` | Migrated to `LeaveRequestManagementController` |
| HR | `lib/View/hr/leave_type_page.dart` | page | `done` | Migrated to `LeaveTypeManagementController` |
| Inventory | `lib/View/inventory/inventory_inquiry_page.dart` | page | `done` | Migrated to `InventoryInquiryManagementController` |
| Inventory | `lib/View/inventory/opening_stock_page.dart` | page | `done` | Moved remaining page shell draft state to `OpeningStockPageController` |
| Manufacturing | `lib/View/manufacturing/production_material_issue_page.dart` | page | `done` | Moved remaining page shell audit-log state to `ProductionMaterialIssuePageController` |
| Parties | `lib/View/parties/party_management_page.dart` | page | `done` | Shell, filters, load/save workflow, and detail draft state moved to `PartyManagementController` |
| Project | `lib/View/project/project_billing_page.dart` | page | `done` | Migrated to `ProjectBillingManagementController` |
| Project | `lib/View/project/project_expense_page.dart` | page | `done` | Migrated to `ProjectExpenseManagementController` |
| Project | `lib/View/project/project_milestone_page.dart` | page | `done` | Migrated to `ProjectMilestoneManagementController` |
| Project | `lib/View/project/project_page.dart` | page | `done` | Migrated to `ProjectManagementController` |
| Project | `lib/View/project/project_resource_usage_page.dart` | page | `done` | Migrated to `ProjectResourceUsageManagementController` |
| Project | `lib/View/project/project_task_page.dart` | page | `done` | Migrated to `ProjectTaskManagementController` |
| Project | `lib/View/project/project_timesheet_page.dart` | page | `done` | Migrated to `ProjectTimesheetManagementController` |
| Project | `lib/View/project/project_vendor_work_page.dart` | page | `done` | Migrated to `ProjectVendorWorkManagementController` |
| Purchase | `lib/View/purchase/purchase_invoice_page.dart` | page | `done` | Migrated to `PurchaseInvoiceManagementController` |
| Purchase | `lib/View/purchase/purchase_order_page.dart` | page | `done` | Migrated to `PurchaseOrderManagementController` |
| Purchase | `lib/View/purchase/purchase_payment_page.dart` | page | `done` | Migrated to `PurchasePaymentManagementController` |
| Purchase | `lib/View/purchase/purchase_receipt_page.dart` | page | `done` | Migrated to `PurchaseReceiptManagementController` |
| Purchase | `lib/View/purchase/purchase_register_page.dart` | page | `done` | Migrated local pagination state to `PurchaseRegisterPageController` |
| Purchase | `lib/View/purchase/purchase_requisition_page.dart` | page | `done` | Migrated to `PurchaseRequisitionManagementController` |
| Purchase | `lib/View/purchase/purchase_return_page.dart` | page | `done` | Migrated to `PurchaseReturnManagementController` |
| Sales | `lib/View/sales/sales_delivery_page.dart` | page | `done` |  |
| Sales | `lib/View/sales/sales_invoice_page.dart` | page | `done` | Migrated to `SalesInvoiceManagementController` |
| Sales | `lib/View/sales/sales_order_page.dart` | page | `done` |  |
| Sales | `lib/View/sales/sales_quotation_page.dart` | page | `done` |  |
| Sales | `lib/View/sales/sales_receipt_page.dart` | page | `done` |  |
| Sales | `lib/View/sales/sales_return_page.dart` | page | `done` |  |
| Settings Accounting | `lib/View/settings/accounting/budget_page.dart` | page | `done` | Migrated to `BudgetManagementController` |
| Settings Accounting | `lib/View/settings/accounting/cash_session_page.dart` | page | `done` | Migrated to `CashSessionManagementController` |
| Settings Accounting | `lib/View/settings/accounting/document_posting_page.dart` | page | `done` | Migrated to `DocumentPostingManagementController` |
| Settings Accounting | `lib/View/settings/accounting/financial_reports_page.dart` | page | `done` | Migrated to `FinancialReportsController` |
| Settings Accounting | `lib/View/settings/accounting/party_account_register_page.dart` | page | `done` | Migrated to `PartyAccountRegisterController` |
| Settings Accounting | `lib/View/settings/accounting/voucher_page.dart` | page | `done` | Migrated to `VoucherManagementController` |
| Settings Communication | `lib/View/settings/communication/email_messages_page.dart` | page | `done` | Migrated to `EmailMessagesManagementController` |
| Settings Communication | `lib/View/settings/communication/email_module_settings_page.dart` | page | `done` | Migrated to `EmailModuleSettingsManagementController` |
| Settings Communication | `lib/View/settings/communication/email_rules_page.dart` | page | `done` | Migrated to `EmailRulesManagementController` |
| Settings Communication | `lib/View/settings/communication/email_settings_page.dart` | page | `done` | Migrated to `EmailSettingsManagementController` |
| Settings Communication | `lib/View/settings/communication/email_templates_page.dart` | page | `done` | Migrated to `EmailTemplatesManagementController` |
| Settings Master | `lib/View/settings/master/business_location_page.dart` | page | `done` | Migrated to `BusinessLocationManagementController` |
| Settings Master | `lib/View/settings/master/item_alternate_page.dart` | page | `done` | Migrated to `ItemAlternateManagementController` |
| Settings Master | `lib/View/settings/master/item_price_page.dart` | page | `done` | Migrated to `ItemPriceManagementController` |
| Settings Master | `lib/View/settings/master/item_supplier_map_page.dart` | page | `done` | Migrated to `ItemSupplierMapManagementController` |
| Settings Master | `lib/View/settings/master/physical_stock_count_page.dart` | page | `done` | Migrated to `PhysicalStockCountManagementController` |
| Settings Master | `lib/View/settings/master/stock_balance_page.dart` | page | `done` | Migrated to `StockBalanceManagementController` |
| Settings Master | `lib/View/settings/master/uom_conversion_page.dart` | page | `done` | Migrated to `UomConversionManagementController` |
| Settings Master | `lib/View/settings/master/warehouse_page.dart` | page | `done` | Migrated to `WarehouseManagementController` |
| Settings Tax | `lib/View/settings/tax/document_tax_lines_register_page.dart` | page | `done` | Migrated to `DocumentTaxLinesRegisterManagementController` |
| Settings Tax | `lib/View/settings/tax/gst_registration_page.dart` | page | `done` | Migrated to `GstRegistrationManagementController` |
| Settings User | `lib/View/settings/user/login_history_page.dart` | page | `done` | Migrated to `LoginHistoryManagementController` |
| Settings User | `lib/View/settings/user/module_preferences_page.dart` | page | `done` | Migrated to `ModulePreferencesManagementController` |
| Settings User | `lib/View/settings/user/profile_page.dart` | page | `done` | Migrated to `ProfileManagementController` |

## Pending Widgets And Support Files

| Area | File | Type | Status | Notes |
| --- | --- | --- | --- | --- |
| Assets | `lib/View/assets/asset_registers.dart` | widget/support | `done` | Migrated asset register/report/dialog state to shared GetX controllers |
| Dashboard | `lib/View/dashboard/erp_module_dashboard_support.dart` | widget/support | `done` | Support loaders already stateless; custom trend range dialog state moved to GetX in dashboard page |
| HR | `lib/View/hr/hr_registers.dart` | widget/support | `done` | Migrated attendance, payroll run, and payslip register state to GetX controllers |
| Inventory | `lib/View/inventory/inventory_registers.dart` | widget/support | `done` | Consolidated inventory register pages onto a shared GetX register shell |
| Jobwork | `lib/View/jobwork/jobwork_registers.dart` | widget/support | `done` | Consolidated jobwork register pages onto a shared GetX register shell |
| Maintenance | `lib/View/maintenance/maintenance_registers.dart` | widget/support | `done` | Migrated maintenance work order register state to a GetX controller |
| Manufacturing | `lib/View/manufacturing/manufacturing_registers.dart` | widget/support | `done` | Consolidated manufacturing register pages onto a shared GetX register shell |
| Printing | `lib/View/printing/document_print_designer.dart` | widget/support | `done` | Migrated outer print designer editor state from page-local setState to GetX controller |
| Purchase | `lib/View/purchase/purchase_register_screens.dart` | widget/support | `pending` |  |
| Purchase | `lib/View/purchase/purchase_support.dart` | widget/support | `pending` |  |
| Quality | `lib/View/quality/quality_registers.dart` | widget/support | `pending` |  |
| Sales | `lib/View/sales/sales_register_screens.dart` | widget/support | `done` | Migrated register shell state to `SalesRegisterController` |
| Sales | `lib/View/sales/sales_support.dart` | widget/support | `done` | Stateless helper utilities; no GetX migration needed |
| Service | `lib/View/service/service_registers.dart` | widget/support | `pending` |  |
| Settings | `lib/View/settings/widgets/settings_workspace.dart` | widget/support | `pending` |  |

## Suggested Order

| Order | Scope | Status | Notes |
| --- | --- | --- | --- |
| 1 | Settings Master remaining 8 | `pending` | Best next batch |
| 2 | Settings Accounting remaining 6 | `pending` | Best next batch |
| 3 | `employee_page.dart` | `pending` | Large screen, still uses `AnimatedBuilder` |
| 4 | `party_management_page.dart` | `done` | Migrated to `PartyManagementController`; local `AnimatedBuilder`/shell state removed |
| 5 | Communication settings | `pending` | Smaller grouped forms |
| 6 | Sales and Purchase | `pending` | Larger document flows |
| 7 | Project module | `pending` | Multi-form workflows |
| 8 | Support/register widgets | `pending` | Cleanup after pages |
