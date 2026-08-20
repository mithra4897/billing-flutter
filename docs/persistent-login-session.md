# Keep Billing ERP Login Until Logout

**Status:** Implemented  
**Date:** 2026-08-20

## Objective

Keep a valid authenticated web session across a browser refresh. A user should
return to the login page only after an explicit logout, an expired token, or a
server rejection of the stored session.

## Requirements

- A successful login stores the token and its expiry in existing session
  storage and restores any valid token at bootstrap without requiring a
  separate "Remember me" choice.
- The login screen does not show a misleading option that suggests an unchecked
  box will discard an otherwise valid session on refresh.
- Manual logout and authentication failures still clear the stored session and
  route context.

## Verification

1. Log in, refresh the browser, and confirm the current authenticated route is
   restored.
2. Log out manually, refresh, and confirm the login screen is shown.
3. Use an expired or rejected token and confirm the session is cleared.
