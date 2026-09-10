# Payroll draft calculations and register

Draft payroll must expose the same salary, deductions, net and LOP computation
as processing, without creating payroll lines or payslips. Processing must
refresh the run detail and notify the register. Employee rows must use the
full-width shared register for draft and processed states. Preview failures
remain visible per employee and must not be displayed as zero salary.

Reuse the backend salary calculation for both paths; retain existing attendance
eligibility and company policy. No schema migration is required.

The API preview adds earned_gross, total_deductions, net_salary, lop_amount,
components and statutory for eligible employees. Deploy the backend change
alongside the frontend; older API responses display unavailable values as a
dash. The register has no breakdown column or row-click dialog. Employee
exclusion reasons remain visible beneath the employee code. Processing notifies
HrModuleRefreshController and reloads detail; only deletion leaves the detail.
