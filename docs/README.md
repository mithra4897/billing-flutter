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

- [Specifications](SPECIFICATIONS.md) — approved feature requirements and acceptance criteria.
- [Architecture](ARCHITECTURE.md) — implemented and explicitly approved components and data flow.
- [Architecture decisions](DECISIONS.md) — append-only records of durable technical decisions.
- [Testing](TESTING.md) — verification strategy, commands, and known untested environments.
- [Changelog](CHANGELOG.md) — meaningful implementation and operational changes.

- [ERP line discount by percentage or amount](erp-line-discount-input.md) —
  choose `%` or fixed `Amt` in editable sales and purchase line tables.
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
- [Keep Billing ERP login until logout](persistent-login-session.md) — restore
  a valid session after browser refresh without requiring a remember-me choice.
- [Sales Quotation print discount summary](sales-quotation-print-discount-summary.md) — expose conditional discount label and amount placeholders in quotation print templates.
- [Sales Quotation tax exclusion](sales-quotation-tax-exclusion.md) — keep quotations tax-free in entry, storage, totals, and print data.
- [Print PDF rupee font asset](print-pdf-rupee-font-asset.md) — package the Poppins fallback font used by web PDF generation.
- [Activity Watch local database structure](ACTIVITY_WATCH_LOCAL_DATABASE_STRUCTURE.md) — proposed cross-platform 10-table SQLCipher MVP schema, operating-system capabilities, table purposes, encryption, retention, and recovery rules.
- [Activity Watch Go desktop service](activity-watch-go-service.md) — build,
  configure, install, and operate the boot-time Windows/macOS/Linux agent.
- [Activity Watch Windows developer setup](activity-watch-windows-developer-setup.md)
  — install Go/MSYS2 UCRT64, build and publish the Windows agent, pair a test
  device, and diagnose common compiler, installer, cache, and task errors.
- [Activity Watch release and operations](activity-watch-release-operations.md)
  — build and publish Windows/macOS installers, install an approved unsigned
  macOS development package, remove an existing agent, and run service commands.
- [Activity Watch `bill.local` HTTP development exception](activity-watch-bill-local-http-development.md)
  — narrowly scoped pre-TLS Windows pairing and upload validation.
- [Activity Watch dashboard and summary table](activity-watch-summary-table.md)
  — show KPI trends, daily device metrics, and paginated device setup state.
- [Payslip template pre-editing](payslip-template-preedit.md) — edit the company payslip layout using sample data before payroll creation.
- Configurable company payroll proration policy — see `SPECIFICATIONS.md`,
  `ARCHITECTURE.md`, ADR-0039 in `DECISIONS.md`, and the 2026-09-02 testing and
  changelog entries; backend deployment details are in
  `billing-api/doc/configurable-payroll-proration-policy.md`.
- [Print designer box border radius](print-designer-box-border-radius.md) — adjust rounded corners for boxed print elements.
- [Company creation access and logo](company-create-access-and-logo.md) — upload a company logo during creation and ensure the creator can access the result.
- [Sales Invoice export GST normalization](sales-invoice-export-persisted-tax-components.md) — correct IGST versus CGST/SGST allocation using normalized place-of-supply data while retaining the document's tax total.
- Sales customer advance allocation — see `SPECIFICATIONS.md`, `ARCHITECTURE.md`,
  ADR-0040 in `DECISIONS.md`, and the 2026-09-03 testing/changelog entries;
  backend deployment details are in
  `billing-api/doc/sales-customer-advance-allocation.md`.
- [Party code synchronization](party-code-type-sync.md) — regenerate the
  read-only party code when an existing party's type changes.
- Global StaffU-inspired theme foundation — see `SPECIFICATIONS.md`,
  `ARCHITECTURE.md`, ADR-0018 in `DECISIONS.md`, and the 2026-08-22 entries in
  `TESTING.md` and `CHANGELOG.md`.
- Shared bordered cards, module-list tables, and editable line-item tables —
  see `SPECIFICATIONS.md`, `ARCHITECTURE.md`, and the 2026-08-22
  verification/changelog entries.
- StaffU-inspired Project Tasks Kanban board — see `SPECIFICATIONS.md`,
  `ARCHITECTURE.md`, ADR-0040 in `DECISIONS.md`, and the 2026-09-03 entries in
  `TESTING.md` and `CHANGELOG.md`.
- Project task priority badges — see `SPECIFICATIONS.md`, `ARCHITECTURE.md`,
  ADR-0041 in `DECISIONS.md`, and the 2026-09-04 entries in `TESTING.md` and
  `CHANGELOG.md`; backend deployment details are in
  `billing-api/doc/project-task-priority.md`.
