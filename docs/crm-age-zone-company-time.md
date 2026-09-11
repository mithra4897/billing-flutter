# Register age zones use Company-local time

## Scope

Every register that uses the shared age-zone helper colours open rows by age:
green through day 7, blue through day 15, amber through day 30, and red
afterwards. This currently includes CRM Leads/Enquiries and the affected Sales
and Purchase document registers. The colour must be calculated against the
Company-local calendar date, not the browser or device clock.

## Contract

- Every paginated API response provides additive `company_today_local`
  (`YYYY-MM-DD`), calculated from the server UTC clock in the active Company's
  timezone. The API client keeps this date only for the current working context.
- Lead-list responses additionally provide additive `created_at_local` and
  `company_today_local` (`YYYY-MM-DD`). The API converts the stored UTC
  creation instant and derives today from the server UTC clock, both in each
  Lead's Company timezone.
- The typed Lead model preserves this display/comparison field.
- The existing shared `documentAgeZoneColor` helper consumes the retained
  server date. CRM Leads supplies row-specific local creation and today values;
  date-based documents use their existing date-only business field. It never
  uses `DateTime.now()` for age zones.
- If a legacy response lacks the reference date, the helper retains its
  existing fallback for unaffected callers. The CRM Lead register does not use
  that fallback.

## Acceptance criteria

1. Changing a browser/device clock cannot change any register age-zone colour.
2. A row at a Company-local calendar boundary is placed in the correct
   7/15/30-day zone.
3. Closed Leads still have no age-zone colour.
4. The list request remains one request and no database schema changes occur.

## Verification

- Add focused tests for a supplied Company-local reference date and the typed
  list value.
- Run PHP syntax checks, Dart formatting, focused Flutter analysis, and the
  focused test suite.
