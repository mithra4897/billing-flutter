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

- shared frontend rulebook: [FRONTEND_STANDARDS.md](/Users/buddykit/Projects/billing-flutter/FRONTEND_STANDARDS.md)

## Next Build Areas

- auth/session view models
- dashboard data widgets
- master selection flows
- sales and purchase document forms
- shared query and path-driven list pages
