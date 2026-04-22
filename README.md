# Billing Flutter

Flutter frontend for the Billing ERP platform. This app is being built for mobile, tablet, desktop, and web with a route-first shell and a typed MVVM-friendly service layer.

## Current Foundation

- route-based navigation with web-friendly path URLs
- responsive shell with mobile drawer and persistent tablet/desktop sidebar
- company branding fetched from the backend instead of hardcoded values
- remember-me bootstrap and auto-login flow
- automatic JWT refresh before expiry
- typed service and model layer aligned with the Lumen ERP API

## Backend Dependency

This app works with the sibling backend project:

- [billing-api](/billing-api)

If you change backend schema or **`install.sql` / `sample_erp.sql`**, keep **`billing-api/README.md`** and the repo-root **`todo.md`** in sync when those edits affect setup, seeds, or module coverage.

Key shell/auth endpoints currently used:

- `GET /api/v1/public/branding`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `GET /api/v1/auth/me`
- `POST /api/v1/auth/logout`

## Run

```bash
flutter pub get
flutter run
```

## Architecture Direction

- reusable UI pieces under `lib/components`
- route-aware screens under `lib/view`
- typed models under `lib/model`
- typed module services under `lib/service`
- shared HTTP/session infrastructure under `lib/core`

## Frontend Standards

- shared frontend rulebook: [FRONTEND_STANDARDS.md](/FRONTEND_STANDARDS.md)
- completed frontend module note: [FRONTEND_COMPLETED_MODULES.md](/FRONTEND_COMPLETED_MODULES.md)

## Next Build Areas

- auth/session view models
- dashboard data widgets
- master selection flows
- sales and purchase document forms
- shared query and path-driven list pages


07/04/2026 4:55 pm
Updated the frontend validation in [party_management_page.dart](/lib/view/parties/party_management_page.dart) 
and added reusable helpers in [validators.dart](/lib/helper/validators.dart).

The contact form now validates before submit for:
- `contact_name` required and max `150`
- `designation` max `100`
- `mobile` max `20`
- `phone` max `20`
- `email` valid format and max `150`

The address form now also checks backend-aligned max lengths for fields like 
`address_line1`, `city`, `state_code`, `postal_code`, etc. The save flow already trims values via `nullIfEmpty(...)`,
so whitespace-only values won’t be sent.


## Updated party master setup to simplify party types.

Removed EMPLOYEE, BANK, and CASH from the Party Primary type dropdown in party_management_page.dart,
while keeping legacy backend behavior so existing records are still safe.
Also removed those same three seeded party types from install.sql 
so fresh installs only create the intended party-facing types.

 remove employee bank and cash from party type selection

For this ERP, that’s the cleaner setup:

Employee should live in the HR employee master, not as a party type.
Bank and Cash are usually accounting ledgers, and your install already seeds cash/bank ledgers in accounts, 
so they don’t need to be selectable as party masters.
Customer, Supplier, Job Worker, Transporter, and General still make sense as party-facing types.

## updated the table of party in database 
