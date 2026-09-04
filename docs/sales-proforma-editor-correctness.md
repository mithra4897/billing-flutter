# Sales Proforma editor correctness

## User flow

- A user may create a Sales Proforma Invoice directly. Source Quotation is an
  optional shortcut that pre-fills the customer and lines.
- Clicking New Quotation or New Proforma immediately resets the editor and
  keeps it reset even if an older detail request finishes afterward.
- Creating a Proforma from a Quotation starts from a clean draft and then
  applies only the selected quotation's prefill response. It keeps the
  quotation customer, addresses, reference, validity, notes, terms, item,
  quantity, rate, discount, and source-line identity; it starts with today's
  Proforma date, a blank number, the correct Proforma series, and item tax. An
  already-expired quotation validity is cleared instead of creating an invalid
  Proforma date range.
- The quotation ID remains part of the new-editor load intent, including after
  a working-context refresh, so a blank reload cannot replace the prefilled
  draft with an existing Proforma.
- Applying the route's dashboard-filter state does not schedule a second list
  request, which previously reset the quotation-prefilled draft after a short
  debounce.
- A manually entered proforma round-off remains unchanged until the user edits
  it again. Automatic round-off recalculation still runs when line totals or
  the Apply round off switch change.

## Edge cases

- Clearing Source Quotation detaches quotation-line identifiers from the
  editable draft.
- Selecting another document, resetting, and quotation prefill use a shared
  latest-request guard. Stale responses are ignored in O(1) time and storage.
- Existing quotation-linked validation remains owned by the API.

## Backend dependency

Existing databases must make
`sales_proforma_invoices.sales_quotation_id` nullable. See
`billing-api/doc/sales-proforma-optional-source.md` and its SQL patch.
