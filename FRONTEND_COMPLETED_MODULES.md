# Frontend Completed Modules

This file is the working handover note for the Flutter ERP frontend.

It records only the modules and foundations that are already completed enough to use as a reference for future work. When building the next screens, we should follow this file together with [FRONTEND_STANDARDS.md](/FRONTEND_STANDARDS.md).

## Overall Frontend Direction

The frontend is built around a persistent shell and route-first navigation:

- mobile, tablet, desktop, and web are handled together
- authenticated navigation stays inside one static shell
- only the main content area changes between routes
- drawer and header stay mounted
- typed models and typed services are preferred over raw maps for the main module flow

Core structure:

- `lib/view`
  - screens/pages
- `lib/components`
  - shared UI widgets
- `lib/model`
  - typed models
- `lib/service`
  - typed API services
- `lib/core`
  - API, auth/session, storage, and shared infrastructure
- `lib/screen.dart`
  - common screen-layer barrel import

## Shared Frontend Foundation Completed

These parts are already in place and should be reused instead of rebuilt:

- route-based startup and auth bootstrap
- persistent responsive shell
- backend branding fetch and cache
- remember-me auto login
- JWT refresh before expiry
- permission-aware menu rendering
- backend-driven module/menu order support
- offline / server error handling basics
- theme-driven UI rules
- shared form widgets
- shared report header and pagination widgets
- shared settings workspace layout
- shared mobile list-to-editor behavior for settings workspaces

Important base files:

- [main.dart](/lib/main.dart)
- [app_shell_page.dart](/lib/view/core/app_shell_page.dart)
- [adaptive_shell.dart](/lib/components/adaptive_shell.dart)
- [app_navigation.dart](/lib/app/navigation/app_navigation.dart)
- [screen.dart](/lib/screen.dart)

## Shared UI Components Completed

These are the main reusable widgets already established:

- [AppFormTextField](/lib/components/app_form_text_field.dart)
- [AppDropdownField](/lib/components/app_dropdown_field.dart)
- [AppSwitchTile](/lib/components/app_switch_tile.dart)
- [AppActionButton](/lib/components/app_action_button.dart)
- [AppSectionCard](/lib/components/app_section_card.dart)
- [UploadPathField](/lib/components/upload_path_field.dart)
- [InlineFieldAction](/lib/components/inline_field_action.dart)
- [AppErrorStateView](/lib/components/app_error_state_view.dart)
- [AppLoadingView](/lib/components/app_loading_view.dart)
- [ReportPaginationBar](/lib/components/report_pagination_bar.dart)

Shared layout helpers:

- [settings_workspace.dart](/lib/view/settings/widgets/settings_workspace.dart)
- [master_setup_helpers.dart](/lib/view/settings/master/master_setup_helpers.dart)

## Completed Frontend Modules

### 1. Auth / Bootstrap / Session

Completed:

- login screen
- app bootstrap screen
- remember-me flow
- auto-login
- token refresh timer
- branding from backend

Main files:

- [login_page.dart](/lib/view/auth/login_page.dart)
- [app_bootstrap_page.dart](/lib/view/core/app_bootstrap_page.dart)
- [app_session_service.dart](/lib/service/app/app_session_service.dart)
- [auth_service.dart](/lib/service/auth/auth_service.dart)

### 2. Shell / Drawer / Navigation

Completed:

- responsive drawer
- persistent shell layout
- nested drawer groups
- permission-based drawer visibility
- module ordering support
- current-route highlighting
- drawer auto-scroll to selected item
- mobile topbar auto-hide behavior

Main files:

- [adaptive_shell.dart](/lib/components/adaptive_shell.dart)
- [app_navigation.dart](/lib/app/navigation/app_navigation.dart)
- [app_shell_page.dart](/lib/view/core/app_shell_page.dart)
- [settings_workspace.dart](/lib/view/settings/widgets/settings_workspace.dart)

Mobile settings workspace behavior:

- on desktop, settings pages keep list and editor side by side
- on mobile and tablet, tapping a list record opens the editor in a new themed screen
- this behavior is centralized in `SettingsWorkspace`, so new settings pages should inherit it automatically

### 3. Dashboard

Completed:

- dashboard route and shell integration
- dashboard is already part of the static shell flow

Main file:

- [dashboard_page.dart](/lib/view/dashboard/dashboard_page.dart)

### 4. Access Control

Completed:

- profile
- users
- roles
- login history

Main files:

- [profile_page.dart](/lib/view/settings/user/profile_page.dart)
- [user_management_page.dart](/lib/view/settings/user/user_management_page.dart)
- [role_management_page.dart](/lib/view/settings/user/role_management_page.dart)
- [login_history_page.dart](/lib/view/settings/user/login_history_page.dart)

How these were done:

- `Users` follows left-list + right editor with tabs
- `Roles` follows the same pattern, simplified for role profile and role permissions
- user permissions and role permissions use a matching permission UI style
- tabs become visible/useful based on saved record state where applicable

### 5. Settings > Company Setup

Completed:

- companies
- branches
- business locations
- warehouses

Main files:

- [company_page.dart](/lib/view/settings/master/company_page.dart)
- [branch_page.dart](/lib/view/settings/master/branch_page.dart)
- [business_location_page.dart](/lib/view/settings/master/business_location_page.dart)
- [warehouse_page.dart](/lib/view/settings/master/warehouse_page.dart)

How these were done:

- all use the same settings workspace pattern
- left searchable list
- right create/edit form
- shared helpers and shared form widgets

### 6. Settings > UOM

Completed:

- UOM list
- create/update
- delete

Main file:

- [uom_page.dart](/lib/view/settings/master/uom_page.dart)

Backend note:

- the backend master route contract was corrected so `/masters/uoms` now points to the real inventory controller

### 7. Settings > Tax Categories

Completed:

- tax category list
- create/update
- delete

Main file:

- [tax_category_page.dart](/lib/view/settings/master/tax_category_page.dart)

Backend note:

- the backend master route contract was corrected so `/masters/tax-codes` now points to the real inventory controller

### 8. Settings > Communication

Completed:

- email settings
- module settings
- email templates
- email rules
- email messages
- send email dialog

Main files:

- [email_settings_page.dart](/lib/view/settings/communication/email_settings_page.dart)
- [email_module_settings_page.dart](/lib/view/settings/communication/email_module_settings_page.dart)
- [email_templates_page.dart](/lib/view/settings/communication/email_templates_page.dart)
- [email_rules_page.dart](/lib/view/settings/communication/email_rules_page.dart)
- [email_messages_page.dart](/lib/view/settings/communication/email_messages_page.dart)

How these were done:

- settings/templates/rules use left-list + right editor pattern
- messages uses left-list + right detail view
- manual send email is handled from the messages area

Important service note:

- [communication_service.dart](/lib/service/communication/communication_service.dart) was corrected so `emailSettings()` and `emailModuleSettings()` use collection responses instead of paginated responses, matching the backend

### 9. HR Foundation

Completed:

- departments
- designations
- employees

Main files:

- [department_page.dart](/lib/view/hr/department_page.dart)
- [designation_page.dart](/lib/view/hr/designation_page.dart)
- [employee_page.dart](/lib/view/hr/employee_page.dart)
- [hr_service.dart](/lib/service/hr/hr_service.dart)

How these were done:

- `Departments` and `Designations` follow the standard list + editor workspace
- `Employees` uses list + editor with tabs:
  - `Primary`
  - `Employee Accounts`
  - `Salary Structures`
  - `Salary Components`
- `Department` and `Designation` inside Employee use inline add flow beside the dropdown, following the same pattern as Role creation in user management
- child employee tabs follow save-first behavior, just like Companies, Branches, Parties, and Items
- `Employee Accounts` reflects backend-generated ledgers
- `Salary Structures` and `Salary Components` are edited through the employee update contract, matching the current HR backend design

Model note:

- the HR models used by these screens were converted from raw map wrappers to typed models so future HR work can build on a stable contract

### 9. Parties

Completed:

- one unified `Parties` workspace
- primary party profile
- addresses
- contacts
- GST details
- bank accounts
- credit limits
- payment terms

Main file:

- [party_management_page.dart](/lib/view/parties/party_management_page.dart)

How this was done:

- left side: searchable party list
- right side: party workspace with tabs
- primary tab keeps only core party fields
- tabs:
  - `Primary`
  - `Addresses`
  - `Contacts`
  - `GST Details`
  - `Bank Accounts`
  - `Credit Limits`
  - `Payment Terms`

Important design choice:

- `Party Types` is not a separate frontend management page in the current completed flow
- party type is used as a dropdown inside the party primary form
- drawer/menu clutter was intentionally reduced
- duplicated contact and GST entry fields were removed from the primary tab
- contacts are maintained in `Contacts`
- GST registration data is maintained in `GST Details`
- bank, credit limit, and payment term data are maintained only in their own tabs

Future note:

- backend party list search now supports related contact/GST data
- the current Flutter left-side party search is still local in-memory filtering
- if live child-data search is needed in that left list, move this page to API-driven search/filter in a future pass

## Typed Model / Service Work Completed

The frontend was also moved further toward real typed data flow.

Important model/service updates completed for the above modules:

- [uom_model.dart](/lib/model/masters/uom_model.dart)
- [tax_code_model.dart](/lib/model/masters/tax_code_model.dart)
- [party_model.dart](/lib/model/masters/party_model.dart)
- [party_address_model.dart](/lib/model/masters/party_address_model.dart)
- [party_contact_model.dart](/lib/model/masters/party_contact_model.dart)
- [communication_service.dart](/lib/service/communication/communication_service.dart)
- [master_service.dart](/lib/service/master/master_service.dart)
- [parties_service.dart](/lib/service/parties/parties_service.dart)

## Route / Shell Integration Completed

These completed modules are already connected into the app shell and should not be treated as placeholders anymore:

- `/dashboard`
- `/settings/profile`
- `/settings/users`
- `/settings/roles`
- `/settings/login-history`
- `/settings/companies`
- `/settings/branches`
- `/settings/business-locations`
- `/settings/warehouses`
- `/settings/uom`
- `/settings/tax-categories`
- `/communication/email-settings`
- `/communication/email-module-settings`
- `/communication/email-templates`
- `/communication/email-rules`
- `/communication/email-messages`
- `/communication/send-email`
- `/parties`
- `/parties/addresses`
- `/parties/contacts`
- `/parties/gst-details`
- `/parties/bank-accounts`
- `/parties/credit-limits`
- `/parties/payment-terms`
- `/purchase/requisitions`
- `/purchase/orders`
- `/purchase/receipts`
- `/purchase/invoices`
- `/purchase/payments`
- `/purchase/returns`

## Purchase Module Completed

The purchase flow is now available as real frontend screens instead of placeholders.

Completed screens:

- `Purchase Requisitions`
- `Purchase Orders`
- `Purchase Receipts`
- `Purchase Invoices`
- `Purchase Payments`
- `Purchase Returns`

Pattern followed:

- report-style recent list on the left
- filter/search support
- full create/edit form on the right
- backend workflow actions exposed where applicable:
  - approve
  - post
  - close
  - cancel

Important ERP behavior covered:

- Purchase Payments support multiple invoice allocations in one payment.
- Purchase Invoices support item/warehouse/UOM/qty/rate/tax-oriented line entry.
- Purchase Returns are invoice-line driven, so return lines stay tied to the original purchase invoice lines.

## What This File Is For

Whenever we continue frontend work later, this file should help answer:

- which modules are already real and usable
- which layout pattern they follow
- which shared widgets/services are already standard
- where to extend instead of rebuilding from scratch

## Rule For Future Work

When building the next completed module:

1. follow [FRONTEND_STANDARDS.md](/FRONTEND_STANDARDS.md)
2. reuse the same workspace/report/dialog patterns
3. update this file after the module becomes truly usable
