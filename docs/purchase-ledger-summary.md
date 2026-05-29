# Purchase Ledger Summary

## What was built

- Added a new Purchase submodule page: `Purchase Ledger`
- Reused the existing `PurchaseRegisterPage` register layout for the ledger list
- Added a linked purchase ledger detail page that opens when a register row is clicked
- Added one shared ledger statement widget for the reusable table layout

## Purchase ledger register

- Source data: party account mappings filtered to `account_purpose = payable`
- Existing reusable layout used: `lib/view/purchase/purchase_register_page.dart`
- Register columns:
  - `Code`
  - `Ledger Name`
  - `Supplier`
  - `Status`
  - `Transactions`
  - `Balance`

## Purchase ledger detail page

- Opens from: `/purchase/ledgers/:id`
- Title block shows the selected ledger and supplier
- Summary area shows:
  - ledger code
  - ledger name
  - supplier
  - invoice total
  - paid amount
  - outstanding

## Shared widget created for later reuse

- File: `lib/components/ledger_statement_table.dart`
- Widget: `LedgerStatementTable`
- Shared row model: `LedgerStatementRowData`

This shared widget already supports the exact table structure needed later in:

- `Sales Ledger`
- `Employee Ledger`

## Statement table structure

The reusable statement table is built with these columns:

- `Date`
- `Code`
- `Ledger Name`
- `Cash / Bank Ledger`
- `Credit or Debit`
- `Amount`

## Purchase data mapping used

- Register rows come from `partyAccountsRegister` with payable mappings
- Detail rows are derived from:
  - purchase invoices
  - purchase payments

Current transaction behavior:

- Purchase invoice rows are shown as `Credited`
- Purchase payment rows are shown as `Debited`
- `Cash / Bank Ledger` is populated from the payment account when available

## Reuse plan for next modules

For `Sales Ledger` and `Employee Ledger`, keep the same pattern:

1. Reuse the module register shell already used by that module
2. Reuse `LedgerStatementTable`
3. Build module-specific register row mapping
4. Build module-specific detail transaction mapping
5. Add module navigation entry and shell route mapping
