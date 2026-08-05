# Simple System Tools

**Status:** Implemented  
**Date:** 2026-08-05

## Objective

Replace the detailed Cache Controls dashboard with the two DTRadio-style
administration actions requested for Billing ERP: **Clear Cache** and **Backup
Database**.

## Requirements

- The `/settings/cache-controls` page contains only the two expandable action
  cards; cache statistics, per-group controls, warm controls, and local-cache
  toggles are removed from its UI.
- Clear Cache requires confirmation and clears only Flutter/browser-side cache.
  It does not call or change server cache state.
- The obsolete server cache administration API and Flutter client wrappers are
  removed. Existing server-side automatic cache invalidation remains internal.
- Backup Database requires confirmation and downloads a `.sql` file.
- Both actions remain visible only through the existing super-admin System menu.
- Backup requests use the authenticated API, and the downloaded file is saved
  using the platform's normal file-download flow.

## Security and Edge Cases

- The API backup endpoint is protected by existing authentication and
  `super_admin` middleware, with a server audit log for every request.
- Failed requests display an actionable message and must not create a partial
  saved file.
- The feature creates no server-side retained backup copy; it streams the SQL
  response to the requesting administrator.

## Acceptance Criteria

1. The system tools page displays only Clear Cache and Backup Database.
2. Clear Cache clears only browser/app cache after confirmation.
3. A super admin downloads an SQL backup after confirmation.
4. A non-super-admin cannot access the backup endpoint.
5. The retired `/admin/cache/*` endpoints are no longer registered.

## Implementation and Verification

- The System Tools menu item retains the existing super-admin-only parent menu
  and opens the two-card page.
- The clear action confirms before clearing the Flutter local caches only; it
  makes no server-cache API request.
- The backup action confirms before fetching the authenticated SQL download and
  using the platform file-save flow.
- The retired server-cache client wrappers were removed from `AdminService`.
- Focused Flutter tests and static analysis passed.
