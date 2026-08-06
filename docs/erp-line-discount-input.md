# ERP line discount input

Status: Implemented (2026-08-06)

## Objective

Allow editable ERP line-item tables to accept a discount either as a percentage
of the row gross amount or as a fixed currency amount.

## Scope and rules

- The Discount cell provides a `%` / `Amount` mode selector and one numeric
  input.
- Existing rows default to percentage mode unless the manual SQL backfill detects a
  stored amount/derived-percentage rounding mismatch; newly added rows default
  to percentage mode.
- Percentage must be between 0 and 100.
- A fixed amount must be non-negative and cannot exceed `quantity × rate`.
- Fixed-amount mode keeps the entered amount unchanged when quantity or rate
  changes. The effective percentage is derived for persistence and reporting.
- The API treats `discount_amount` as authoritative in amount mode; percentage
  mode retains the existing percentage calculation.
- Existing percentage and amount columns are reused. A manual additive
  `discount_mode` column change records the selected input type.
- The selected mode is persisted as `discount_mode` (`percent` or `amount`) so
  reopening an amount-based line does not convert it back to a rounded percent.

## Acceptance criteria

1. A user can switch each editable Discount cell between `%` and `Amount`.
2. Row tax, taxable value, line total, and document totals update immediately.
3. Saving in either mode stores a correct `discount_percent` and
   `discount_amount`.
4. Existing percentage-only clients and saved records remain compatible.
5. Invalid percentages and amounts are rejected by both UI and API validation.
6. Saving and reopening a ₹3,000 amount discount keeps Amount mode and the exact
   ₹3,000 deduction without a ₹0.01 total drift.

## Required verification

- Flutter widget/calculation tests for percentage and fixed amount.
- API unit tests for precedence, derived percentage, and invalid amount bounds.
- Targeted Flutter analysis and relevant PHP tests.

## Verification results

- Targeted Flutter analysis: passed with no issues.
- Full Flutter tests: passed, 26 tests.
- Discount API unit tests: passed, 6 tests / 18 assertions.
- Full API suite: 23 tests passed and 5 existing access-scope tests errored
  because the SQLite test schema does not contain `user_roles`; the errors do
  not execute the discount code.
- The documented manual `ALTER TABLE` and backfill queries are required before
  the updated API is served. They add `discount_mode` and recover older amount
  entries affected by percentage-rounding drift.
- API compatibility remains additive: percentage-only requests behave as before.
