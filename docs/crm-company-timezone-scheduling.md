# CRM Company-timezone scheduling — 2026-09-10

CRM follow-up and lead-activity forms show and accept time in the record's
Company timezone. The API converts a timezone-neutral entered value to UTC for
storage and supplies `*_local` values for the editor on reload. UTC remains the
source for server-side ordering and overdue calculations.

The existing typed CRM models retain the UTC API values and the existing draft
objects prefer the local display fields. No new Flutter package or additional
network request is introduced.

For a newly added Lead activity or Enquiry/Opportunity follow-up, the loaded
detail response also provides `current_datetime_local`, calculated by the
server in that record's Company timezone. The draft uses that value as its
initial datetime; it does not read browser/device time. Follow-ups additionally
inherit the record assignee, while notes and next-follow-up remain empty.
