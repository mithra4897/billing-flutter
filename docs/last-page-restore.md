# Restore Last Billing Page After Refresh

**Status:** Implemented  
**Date:** 2026-08-05

## Objective

When a user has a remembered, valid Billing ERP session and reopens or refreshes
the application at its root URL, restore the last authenticated shell page they
visited instead of always opening the dashboard.

## Requirements

- Save the complete shell route, including query parameters, whenever the user
  navigates inside the authenticated application.
- Do not save public authentication routes such as login, password reset, or
  forgot-password.
- A directly opened URL remains authoritative; this restore applies only to the
  root bootstrap flow.
- If no saved route exists, retain the existing `/dashboard` default.
- Clear the saved route whenever session data is cleared, so a later user cannot
  inherit a previous user's location.
- The normal permission check remains the final guard: a saved route that is no
  longer allowed falls back to the first accessible route.

## Edge Cases

- A stale or malformed stored route is ignored and the dashboard opens.
- A session that cannot be restored still opens login with the normal dashboard
  redirect; saved routes are not exposed outside an authenticated session.
- The feature persists the page location, not unsaved form input or modal state.

## Acceptance Criteria

1. Navigate to a shell page, refresh/open the root application with a remembered
   session, and the same page opens.
2. Query parameters on that page are retained.
3. Logout clears the stored route.
4. A new or invalid stored value still opens the dashboard safely.

## Implementation and Verification

- `SessionStorage` owns the `last_shell_route` preference and removes it with
  session data.
- Generated shell routes and in-shell navigation both save the route, including
  query parameters.
- Bootstrap uses the saved route only after remembered-session restoration;
  otherwise it retains the existing login and dashboard behaviour.
- `flutter test test/core/storage/session_storage_test.dart` passed.
- `flutter analyze` for the changed navigation and storage files passed.
