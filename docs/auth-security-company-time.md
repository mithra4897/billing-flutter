# Authentication and Security Company-time Display

Login History and Activity Watch use the existing typed models and API services.
No new widget, request, or client-side timestamp conversion was added.

- Login History displays `login_at_local` and `logout_at_local` when the API
  provides them, retaining UTC fields as a compatibility fallback.
- Activity Watch device timestamps prefer the API `*_local` fields.
- Pairing expiry is decided by the server through `is_pairing_expired`, so a
  browser or device clock cannot mark a pairing incorrectly.

The server stores the underlying timestamp instants in UTC and resolves local
display values using the active device/company timezone. Date-only Activity
Watch summary ranges remain business-date filters.
