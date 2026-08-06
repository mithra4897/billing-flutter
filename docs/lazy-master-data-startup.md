# Lazy Master Data at Startup

**Status:** Implemented  
**Date:** 2026-08-05

## Objective

Improve perceived application speed by preventing the shell from loading every
master-data collection immediately after authentication.

## Observed Bottleneck

`AppShellController` starts `MasterDataCache.ensureLoaded()` after both initial
shell bootstrap and access-context refresh. That operation concurrently loads
14 master collections, including all pages of parties, items, accounts, and
other reference data. It runs even when the user opens a dashboard that needs
none of those collections.

## Decision

Remove only the shell-level eager cache warm-up. Existing form, lookup, and
working-context callers keep their `ensureLoaded()` calls, so master data loads
on the first screen that actually needs it and remains shared for the session.
Public branding and remembered-session restoration also begin concurrently,
instead of waiting for one another during bootstrap.

## Requirements

- Dashboard and route shell become usable without waiting for the full master
  cache request set.
- Branding and session restoration overlap during bootstrap.
- Entry screens that require master data continue to load exactly as before.
- Authentication, access checks, working-context selection, and cache
  invalidation behaviour remain unchanged.
- No API or database contract changes are introduced.

## Acceptance Criteria

1. Shell bootstrap and access refresh do not call `ensureLoaded()` directly.
2. A master-data-dependent form still calls `ensureLoaded()` before using its
   options.
3. Static analysis and existing focused cache tests pass.

## Verification

- Full Flutter test suite passed: 22 tests.
- Targeted static analysis of the changed startup controllers passed.
- A production release web bundle built successfully with
  `API_BASE_URL=https://bill.sakthicontroller.com/api/public`.
- Full static analysis completed with two unrelated existing warnings: an unused
  import in `app_config.dart` and an unused CRM helper.
