# Payslip Template Pre-editing

## User flow

The **HR → Payslips** register includes a **Design payslip** action. It opens
the existing `hr_payslip` template editor before a payroll run or payslip has
been created.

## Rules

- The editor requires a selected session company, because templates are
  company-scoped.
- Preview fields use illustrative sample data only.
- Opening or saving the template does not create or modify an employee,
  payroll run, payslip, voucher, or ledger transaction.
- Generated payslip previews and emails continue to use the same saved
  template with actual payroll data.

## Verification

- Focused Flutter analysis of the changed files.

