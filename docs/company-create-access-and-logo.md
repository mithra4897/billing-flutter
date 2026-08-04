# Company Creation: Access and Logo

The Company form provides an optional **Company Logo** upload field for both new and existing companies. The uploaded public media path is saved as `logo_path` with the company record, so the existing print-template logo binding can use it.

The Companies list also shows a persistent **Create Company** button above the list, so the action remains available when embedded-page header actions are not visible.

The Primary form includes Address Line 1 and Address Line 2, plus Area,
District, and Postal Code. These saved details are used by the Payslip Company
Details preview.

The create action follows the active tab: **New Company** on Primary and **New Financial Year** on the Financial Years tab. The Formats tab has no create action.

After a successful create, the frontend refreshes the user context and loads the new company. The backend guarantees the creator has company access, fixing the prior “company not found” outcome for non-super-admin users.

## Verification

- Focused Flutter analysis of the changed controller and form.
