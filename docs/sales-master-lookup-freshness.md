# Sales Master Lookup Freshness

**Status:** Implemented  
**Date:** 2026-08-05

## Problem

Sales Invoice and Sales Quotation copy Items and customer Parties from the
shared master-data cache during page initialization. When that cache was loaded
earlier, a newly created or updated Item/Party can be absent from the picker,
particularly when the change came from another tab or browser.

## Decision

When Invoice or Quotation opens, ensure the master cache exists and, only when
it was already loaded, refresh the sales lookup subset: Items, Parties, and
Party Types. Do this once during page initialization, not during every document
selection or form update.

## Requirements

- Newly created active Items appear in Invoice and Quotation item pickers.
- Newly created active customer Parties appear in their customer pickers.
- Same-session mutation upserts remain in place.
- The optimization that avoids a full master-cache load at dashboard startup
  remains unchanged.
- No backend or database contract changes are required.

## Acceptance Criteria

1. Opening Invoice or Quotation with an empty cache performs the normal initial
   master load without duplicate sales-lookup requests.
2. Opening either page with an existing cache refreshes only Items, Parties, and
   Party Types.
3. Subsequent document operations on the open page do not repeatedly force the
   sales lookup refresh.

## Verification

- Targeted static analysis passed with no issues.
- Full Flutter suite passed: 22 tests.
- Production web bundle rebuilt successfully with the live API URL.
- Existing sales filtering remains: only active customer/buyer Party Types are
  shown when such types exist.
