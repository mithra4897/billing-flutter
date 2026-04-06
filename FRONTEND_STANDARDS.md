# Frontend Standards

This file is the working rulebook for the Billing ERP Flutter frontend.

Whenever we create a new page, form, report, dialog, list, or shell section, we should follow these points unless there is a very strong reason not to.

## Core Direction

- Build for mobile, tablet, desktop, and web together.
- Keep route-first design.
- Keep shell static and swap only the main content area.
- Prefer typed model/service flow, not raw map flow.
- Prefer reusable components over page-level duplicated UI code.
- If a visual behavior should change globally, it should be controlled from widget/theme level.

## App Structure

- `lib/view`
  - screens/pages only
- `lib/components`
  - reusable UI widgets
- `lib/model`
  - typed request/response/domain models
- `lib/service`
  - typed API/service layer
- `lib/core`
  - API, storage, session, common infrastructure
- `lib/screen.dart`
  - shared barrel for common screen-layer imports

## Import Rule

- For screen files, prefer importing [screen.dart](/lib/screen.dart).
- Keep only truly local/special imports beside it.
  - example: sibling helper file, highly specific local widget, or package not meant for global export
- Avoid long repeated import blocks in every page.

## Theme Rule

- Colors, typography, spacing behavior, and component look should come from shared theme/constants.
- Do not hardcode random colors in pages.
- If a color/style is reused or likely to change globally, move it to theme/constants.
- ExpansionTile styling is app-level, not page-level.

## Navigation Rule

- Use path-based routes.
- Web URL should reflect the current module/page.
- Authenticated screens must stay inside the persistent shell.
- Do not rebuild the full app shell on every route change.
- Drawer state and selection should remain stable across page changes.

## Shell Rule

- Drawer/menu stays persistent.
- Page content changes in the center area only.
- Page-specific actions belong to the page header/content area, not the global shell header.
- On mobile, header/actions should adapt for space.
- On desktop/tablet, drawer remains visible and can collapse/expand.

## Form Rule

- Do not use raw `TextFormField` directly in normal forms unless there is a special need.
- Use [AppFormTextField](/lib/components/app_form_text_field.dart).
- Do not use raw `DropdownButtonFormField` directly in normal forms unless there is a special need.
- Use [AppDropdownField](/lib/components/app_dropdown_field.dart).
- Do not use raw `SwitchListTile` directly in normal forms unless there is a special need.
- Use [AppSwitchTile](/lib/components/app_switch_tile.dart).
- Upload fields should use [UploadPathField](/lib/components/upload_path_field.dart).
- Quick-create beside lookup/dropdown fields should use [InlineFieldAction](/lib/components/inline_field_action.dart).

## Dropdown Rule

- For simple dropdowns, use `AppDropdownField.fromMapped(...)`.
- Use `AppDropdownItem(value, label)` for normal option lists.
- Keep dropdown option definitions short and clean.
- If dropdown text/value mapping needs to change globally, change it in the component usage pattern, not ad hoc in every page.

## Field Layout Rule

- Use [AppFieldBox](/lib/components/app_field_box.dart) or shared wrappers that already use it.
- If width is nullable, do not force a `SizedBox`.
- Standard vertical field spacing should come from the shared field wrapper.

## Action Button Rule

- Do not repeat `FilledButton.icon` / `OutlinedButton.icon` boilerplate.
- Use [AppActionButton](/lib/components/app_action_button.dart) for standard form/report actions.
- Busy/loading button state should be handled there when possible.

## Card/Section Rule

- Use [AppSectionCard](/lib/components/app_section_card.dart) for standard section surfaces.
- Do not recreate card decoration repeatedly in pages.
- Use shared settings workspace widgets when the page fits list + editor layout.

## Settings Screen Rule

- Prefer the established list + editor workspace pattern.
- Left side:
  - searchable list
- Right side:
  - create/edit form
  - optional tabs after save
- Use shared settings widgets where applicable:
  - [settings_workspace.dart](/lib/view/settings/widgets/settings_workspace.dart)

## User/Role Permission Rule

- Permission UI should remain consistent across user and role screens.
- Each permission is one expandable item.
- Title is `permission.name`.
- Groups start collapsed by default.
- Rights summary stays compact in the header.

## Report Rule

- Reports should follow the shared report pattern.
- Use:
  - [report_header_action_bar.dart](/lib/components/report_header_action_bar.dart)
  - [report_pagination_bar.dart](/lib/components/report_pagination_bar.dart)
- Mobile:
  - compact/icon-focused controls
  - horizontal scroll if needed
- Desktop/tablet:
  - table-friendly layout
  - single-row pagination when space allows
- Filter dialogs should be centered and space-aware.
- Pagination/filter/sort changes should reload only report data, not the full page.

## Dialog Rule

- Dialogs should use the same field/button components as forms.
- Avoid creating a separate visual language inside dialogs.
- Mobile dialogs must not waste large empty margins.

## Empty/Loading/Error Rule

- First page load can show a full loading state.
- Subsequent data refresh should prefer local loading states.
- Use shared loading/error widgets where possible.
- Empty tabs/sections should use intentional empty-state views, not collapsed blank space.

## Auth/Session Rule

- Branding comes from backend, not hardcoded.
- Remember-me and auto-login should happen before showing login when possible.
- Token refresh should happen automatically before expiry.
- Connectivity failure should be handled explicitly.

## Code Style Rule

- Keep screens focused on screen logic, not low-level widget repetition.
- If a pattern repeats 2-3 times, consider extracting a component.
- Prefer standalone page files over `part of` coupling.
- Keep helper functions in helper files when shared across sibling pages.

## Existing Shared Components

These are the preferred building blocks already in use:

- [AppFormTextField](/lib/components/app_form_text_field.dart)
- [AppDropdownField](/lib/components/app_dropdown_field.dart)
- [AppSwitchTile](/lib/components/app_switch_tile.dart)
- [AppFieldBox](/lib/components/app_field_box.dart)
- [AppSectionCard](/lib/components/app_section_card.dart)
- [AppActionButton](/lib/components/app_action_button.dart)
- [UploadPathField](/lib/components/upload_path_field.dart)
- [InlineFieldAction](/lib/components/inline_field_action.dart)
- [AdaptiveShell](/lib/components/adaptive_shell.dart)
- [SettingsWorkspace](/lib/view/settings/widgets/settings_workspace.dart)

## Preferred Workflow For New UI

When creating a new module screen:

1. Check whether existing shell/layout/settings/report components already fit.
2. Use `screen.dart` for common imports.
3. Use shared form widgets first.
4. Only create a new component if the pattern is reusable.
5. If a new component is created, update future screens to use it rather than duplicating.
6. Run `flutter analyze` after changes.

## Rule Of Thumb

If a future UI change should reflect everywhere, it must live in:

- theme
- constants
- shared component
- shared layout widget

not in individual screen code.
