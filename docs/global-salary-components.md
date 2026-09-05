# Global salary components

Status: Implemented — 2026-09-05

The Salary Components settings page configures one company-wide component
definition, including calculation, percentage/default amount, and manual
sort order. The page uses the active session company and the backend contract
documented in [`billing-api/doc/global-salary-components.md`](../../billing-api/doc/global-salary-components.md).

Employee salary structures no longer expose drag-and-drop or “apply to all”.
Employee-only components can still be created and removed from the employee
page; company-wide components are created and maintained only in the global
Salary Components settings. Global component metadata is read-only on the
employee page, while employee amounts remain editable.
Loading and API errors remain visible through the shared settings workspace.
