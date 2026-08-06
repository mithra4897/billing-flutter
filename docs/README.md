# Frontend Change Documentation

Maintain this folder whenever `billing-flutter` is changed.

For every meaningful frontend change, add or update a Markdown record that states:

1. Screen, user flow, state, or API contract changed.
2. User-visible business and validation rules.
3. Loading, error, and edge-case behaviour.
4. Tests and verification performed.
5. Required backend contract changes, if any.

For a backend and frontend change that belongs to one feature, use the same decision title/date in both projects and link the two records. Backend records belong in `billing-api/doc/`. The workspace-wide policy is in [`../../docs/README.md`](../../docs/README.md).

## Feature specifications

- [Sales master lookup freshness](sales-master-lookup-freshness.md) — refresh
  Item and customer Party options when Invoice or Quotation opens.
- [Production verification — 2026-08-05](production-verification-2026-08-05.md)
  — verified tests, live API connectivity, and the production web artifact.
- [Lazy master data at startup](lazy-master-data-startup.md) — defer broad
  master-data loading until a screen needs it, reducing dashboard startup work.
- [Simple system tools](simple-system-tools.md) — retain only Clear Cache and
  Backup Database in the super-admin system page.
- [Restore last Billing page after refresh](last-page-restore.md) — reopen the
  last authenticated shell route for a remembered session.
- [Sales Quotation print discount summary](sales-quotation-print-discount-summary.md) — expose conditional discount label and amount placeholders in quotation print templates.
- [Sales Quotation tax exclusion](sales-quotation-tax-exclusion.md) — keep quotations tax-free in entry, storage, totals, and print data.
- [Print PDF rupee font asset](print-pdf-rupee-font-asset.md) — package the Poppins fallback font used by web PDF generation.
- [Activity Watch local database structure](ACTIVITY_WATCH_LOCAL_DATABASE_STRUCTURE.md) — proposed cross-platform 10-table SQLCipher MVP schema, operating-system capabilities, table purposes, encryption, retention, and recovery rules.
- [Payslip template pre-editing](payslip-template-preedit.md) — edit the company payslip layout using sample data before payroll creation.
- [Print designer box border radius](print-designer-box-border-radius.md) — adjust rounded corners for boxed print elements.
- [Company creation access and logo](company-create-access-and-logo.md) — upload a company logo during creation and ensure the creator can access the result.
- [Sales Invoice export GST normalization](sales-invoice-export-persisted-tax-components.md) — correct IGST versus CGST/SGST allocation using normalized place-of-supply data while retaining the document's tax total.
