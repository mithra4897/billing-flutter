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
| Purchase | Requisitions, Orders, Receipts, Invoices, Returns, Payments | Partial | Pending | Pending | Pending |
| Accounts | Vouchers, Party Account Register, financial registers | Partial | Partial | Partial | In progress |
| Inventory | Items, movements, transfers, adjustments, opening stock, batches, serials, physical counts | Partial | Pending | Pending | Pending |
| HR | Payslips, leave requests, expense claims, attendance | Partial | Pending | Pending | Pending |
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
