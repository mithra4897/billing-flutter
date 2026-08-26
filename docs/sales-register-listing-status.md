# ERP Register Listing Implementation Checklist

## Standard to complete for every module

- API filters the full database result before pagination.
- Flutter sends search, status, date and relevant module filters to the API.
- Search is debounced; any filter change reloads page 1.
- The register uses API pagination metadata and shows page controls.
- Company, branch, location and financial-year context remain enforced.

## Module progress

| Module | Registers included | API list support | Flutter server filters | Server pagination UI | Status |
|---|---|---|---|---|---|
| Sales | Quotations, Proformas, Orders, Deliveries, Invoices, Returns, Receipts | Done | Done | Done | Complete |
| Purchase | Requisitions, Orders, Receipts, Invoices, Returns, Payments | Done | Done | Done | Complete |
| Accounts | Vouchers, account masters, postings, reconciliation, cash sessions, budgets, party accounts, reports | Done | Done | Done | Complete |
| Inventory | Items, opening stock, issues, internal receipts, transfers, produce tracking, damage, adjustments, movements, batches, serials, physical counts, stock balances | Done | Done | Done | Complete |
| HR | Employees, payroll runs, payslips, leave requests, expense claims, attendance, HR masters, employee ledger | Done | Done | Done | Complete |
| CRM | Leads, enquiries, opportunities | Partial | Pending | Pending | Pending |
| Assets | Fixed assets, disposals, cost-centre transactions | Partial | Pending | Pending | Pending |
| Projects | Tasks, expenses, billing, resource usage | Partial | Pending | Pending | Pending |
| Settings | Users, roles, companies, branches, warehouses, items, parties, document series | Partial | Pending | Pending | Pending |

## Sales detailed progress

| Register | Server filtering | Server pagination | Page controls | Status |
|---|---:|---:|---:|---|
| Sales Quotations | Done | Done | Done | Complete |
| Sales Proforma Invoices | Done | Done | Done | Complete |
| Sales Invoices | Done | Done | Done | Complete |
| Sales Orders | Done | Done | Done | Complete |
| Sales Deliveries | Done | Done | Done | Complete |
| Sales Returns | Done | Done | Done | Complete |
| Sales Receipts | Done | Done | Done | Complete |

### Sales verification completed

- Search and date fields reload page 1 after a short debounce.
- Customer, status and sort changes reload page 1 automatically. Clear resets
  all filters; no separate Apply action is required.
- Date, document-number and outstanding-balance sorting run on the API before
  pagination.
- Multi-status dashboard filters are sent to the API.
- Invoice Paid, Partially paid and Overdue filters use their effective business
  status rather than only the stored posting status.
- Customer choices, register totals and invoice export use the complete filtered
  result while the visible register continues to use API pagination.
- Flutter Sales analysis and PHP syntax verification pass.

## Purchase detailed progress

| Register | Server filtering | Server pagination | Page controls | Status |
|---|---:|---:|---:|---|
| Purchase Requisitions | Done | Done | Done | Complete |
| Purchase Orders | Done | Done | Done | Complete |
| Purchase Receipts | Done | Done | Done | Complete |
| Purchase Invoices | Done | Done | Done | Complete |
| Purchase Returns | Done | Done | Done | Complete |
| Purchase Payments | Done | Done | Done | Complete |

### Purchase verification completed

- Search and date fields reload page 1 after a short debounce.
- Supplier, status and sort changes reload page 1 automatically; Clear resets
  the filters.
- Date, document-number and invoice outstanding sorting run on the API before
  pagination.
- Multi-status dashboard filters are processed by the API.
- Purchase invoice Paid, Partially paid and Overdue filters use effective
  business status.
- Supplier choices and register totals use the complete filtered result while
  visible rows use API pagination.
- Flutter Purchase analysis has no errors, and all modified PHP files pass
  syntax verification.

## Accounts detailed progress

| Register / list | Server filtering | Server pagination | Page controls | Status |
|---|---:|---:|---:|---|
| Vouchers | Done | Done | Done | Complete |
| Party Account Register | Done | Done | Done | Complete |
| Document Postings | Done | Done | Done | Complete |
| Bank Reconciliation | Done | Done | Done | Complete |
| Cash Sessions | Done | Done | Done | Complete |
| Budgets | Done | Done | Done | Complete |
| Chart of Accounts | Done | Done | Done | Complete |
| Account Groups | Done | Done | Done | Complete |
| Voucher Types | Done | Done | Done | Complete |
| Posting Rule Groups | Done | Done | Done | Complete |
| Posting Rules | Done | Done | Done | Complete |
| Voucher Allocations | Done | Source-line scoped | Not required | Complete |
| Financial Reports | Done | Report result | Not required | Complete |

### Accounts verification completed

- Searches wait briefly and then reload page 1 from the API; there is no Apply
  button for register filters.
- API filtering happens before pagination, so older matching rows are not hidden
  by the current page.
- Vouchers, postings, reconciliation, cash sessions, budgets and Accounts master
  lists use API pagination metadata and page controls.
- Party Account purpose and active-state changes reload automatically.
- Form lookups continue to load complete reference collections where required;
  management lists remain paginated.
- Voucher allocations load the complete set for the selected voucher line, and
  financial statements remain server-filtered report responses rather than
  artificial paginated registers.
- Flutter Accounts analysis passes with no issues, and all modified PHP files
  pass syntax verification.

## Inventory detailed progress

| Register / list | Server filtering | Server pagination | Page controls | Status |
|---|---:|---:|---:|---|
| Items | Done | Done | Done | Complete |
| Opening Stock | Done | Done | Done | Complete |
| Stock Issues | Done | Done | Done | Complete |
| Internal Stock Receipts | Done | Done | Done | Complete |
| Stock Transfers | Done | Done | Done | Complete |
| Produce Tracking | Done | Done | Done | Complete |
| Stock Damage | Done | Done | Done | Complete |
| Inventory Adjustments | Done | Done | Done | Complete |
| Stock Movements | Done | Done | Done | Complete |
| Stock Batches | Done | Done | Done | Complete |
| Stock Serials | Done | Done | Done | Complete |
| Physical Stock Counts | Done | Done | Done | Complete |
| Stock Balances | Done | Done | Done | Complete |

### Inventory verification completed

- Shared Inventory registers use debounced API search, API date/status/category
  filtering, and pagination metadata instead of loading a fixed 200-row set.
- Multi-status filters are evaluated before pagination for document registers
  and stock serials.
- Document search includes linked item codes, names, and categories, so older
  item matches remain discoverable.
- Item, physical-count, and stock-balance management lists use API pagination;
  status, category, and applicable date filters run on the server.
- Detail-form lookups remain independent from visible register pages, so item,
  warehouse, batch, serial, and other required reference data still load.
- Flutter analysis passes with no issues, all modified PHP files pass syntax
  verification, and both worktrees pass whitespace checks.

## HR detailed progress

| Register / list | Server filtering | Server pagination | Page controls | Status |
|---|---:|---:|---:|---|
| Employees | Done | Done | Done | Complete |
| Payroll Runs | Done | Done | Done | Complete |
| Payslips | Done | Done | Done | Complete |
| Leave Requests | Done | Done | Done | Complete |
| Expense Claims | Done | Done | Done | Complete |
| Departments | Done | Done | Done | Complete |
| Designations | Done | Done | Done | Complete |
| Leave Types | Done | Done | Done | Complete |
| Monthly Attendance | Done | Monthly report result | Done | Complete |
| Employee Ledger | Done | Derived report result | Not required | Complete |

### HR verification completed

- Employee, payroll, payslip, leave, expense-claim, department, designation,
  and leave-type searches reload page 1 after a short debounce.
- Employee, status, payment-status, payroll-period, and date filters are sent to
  the API and evaluated before pagination.
- HR management lists and registers use API pagination metadata and page
  controls; selecting another page requests that database page.
- Monthly Attendance deliberately loads one complete month sheet and paginates
  its employee rows locally because the calendar is a single report result.
- Employee Ledger deliberately remains a derived report. It now walks every API
  page for employees, payslips, and reimbursed claims, so historical totals are
  no longer limited to the first fixed-size result set.
- Form dropdowns continue to use independent reference-data requests, so
  paginating the visible management lists does not hide required employees,
  leave types, or other linked records.
- Flutter HR analysis has no errors, and all modified PHP files pass syntax
  verification.

## Update rule

Update this document immediately after each register is completed and verified.
Mark a module **Complete** only after every register in that module has server
filtering, server pagination, and working page controls.

## Existing completed register references

| Register | Status |
|---|---|
| Login History | Complete |
| Party Account Register | Complete |
| Document Tax Lines Register | Complete |
