# Refactor Audit Plan

Status legend:
- `Pending` = not started
- `Done` = completed and validated

## High Priority

- [ ] `Pending` Consolidate duplicated print-preview builders across quotation, sales order, delivery challan, and purchase invoice controllers.
- [ ] `Pending` Replace repeated `firstWhere` item/customer/supplier lookups with indexed maps in controller hot paths.
- [ ] `Pending` Reduce repeated rebuild work in sales document pages by narrowing `GetBuilder` scope and moving derived UI data out of `build()`.

## Medium Priority

- [ ] `Pending` Extract shared sales document UI blocks for header forms, line editors, totals, and action rows.
- [ ] `Pending` Centralize repeated `_applyFilters` and status-filter logic into a reusable mixin/helper.
- [ ] `Pending` Move inline validators into shared validator helpers.
- [ ] `Pending` Reduce repeated serial-option scans and delivery save-time line expansion costs.

## Lower Priority

- [ ] `Pending` Consolidate overlapping text field components (`AppTextField`, `AppFormTextField`, `ValidatedFormTextField`).
- [ ] `Pending` Simplify repetitive CRUD/API service wrappers on top of `ErpModuleService`.
- [ ] `Pending` Review repeated constants/styles usage and extract any remaining shared tokens/layout helpers.

## Validation After Each Refactor

- [ ] `Pending` Run `flutter analyze`.
- [ ] `Pending` Run `flutter test`.
- [ ] `Pending` Smoke test quotation create/edit/print.
- [ ] `Pending` Smoke test sales order create/edit/print.
- [ ] `Pending` Smoke test delivery challan create/edit/print.
- [ ] `Pending` Smoke test purchase invoice create/edit/print.

## Update Rule

When a task is completed, change:

`- [ ] Pending Some task`

to:

`- [x] Done Some task`
