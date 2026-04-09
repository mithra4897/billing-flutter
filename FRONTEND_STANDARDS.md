# Frontend Standards

This file is the shared working contract for `billing-flutter`.

Use it before building or changing any frontend module. It is written to be shared with multiple users and with Codex, so it focuses on decisions that must stay consistent across sessions.

## Purpose

- avoid rescanning backend, database, old screens, and past chats every time
- keep Flutter work aligned with `install.sql` and the live API
- prevent duplicate UI/API exposure
- keep ERP screens simple, strong, and consistent

## Core Direction

- build for mobile, tablet, desktop, and web together
- keep route-first design
- keep shell static and swap only the main content area
- prefer typed model/service flow, not raw map flow
- prefer reusable components over page-level duplicated UI code
- if a visual behavior should change globally, control it from theme/component level

## App Structure

- `lib/view`
  screens/pages only
- `lib/components`
  reusable UI widgets
- `lib/model`
  typed request/response/domain models
- `lib/service`
  typed API/service layer
- `lib/core`
  API, storage, session, common infrastructure
- `lib/screen.dart`
  shared barrel for common screen-layer imports

## Non-Negotiable Thumb Rules

1. Check database schema first.
2. Check API/controller/service second.
3. Check existing Flutter screen and shared components third.
4. Only then design or change the form.

If table, API, and frontend disagree, the database and real API contract win. Do not invent new field names in Flutter.

## Source Of Truth Order

For frontend work, trust sources in this order:

1. `install.sql`
2. backend model + validation + repository/list-query output
3. actual API response
4. Flutter model/service/page
5. old docs

If an old Flutter model or page disagrees with `install.sql`, fix the Flutter side. If backend code disagrees with `install.sql`, audit whether backend drift or schema drift is the real issue before touching the UI.

## Import Rule

- for screen files, prefer importing `screen.dart`
- keep only truly local/special imports beside it
- avoid long repeated import blocks in every page
- if the same import repeats across multiple screens, export it from `screen.dart`

## Theme Rule

- colors, typography, spacing, and component look should come from shared theme/constants
- do not hardcode random colors in pages
- if a style is reused or likely to change globally, move it to theme/constants
- app-level behaviors such as expansion visuals should stay app-level, not page-level
- shared layout/spacing tokens should live in `AppUiConstants`
- when a width, gap, radius, or padding repeats across screens, move it to `AppUiConstants` instead of keeping magic numbers in pages

## Navigation Rule

- use path-based routes
- web URL should reflect the current module/page
- authenticated screens must stay inside the persistent shell
- do not rebuild the full shell on every route change
- drawer state and selection should remain stable across page changes
- keep one menu entry per real concept
- remove duplicate exposure if the same feature appears in two places without a business reason

## Required Build Flow For Any Form

For every new screen or major edit:

1. inspect the table in `install.sql`
2. inspect controller validation rules
3. inspect service/repository/list-query fields
4. align or create typed Flutter model
5. add validators in `lib/helper/validators.dart`
6. build the form with shared widgets
7. verify create, update, delete, and list flows

Do not start from UI assumptions.

## Model Rules

Prefer typed models.

Good pattern:

- final typed fields
- `fromJson()`
- `toJson()`
- `toString()`

Avoid using `Map<String, dynamic> data` as the primary model shape for important masters/settings screens.

`raw` is acceptable only as a fallback escape hatch for extra fields not yet modeled.

### `toString()` Rule

Any model that can appear in:

- list labels
- dropdowns
- editor titles

should expose a meaningful `toString()`.

Preferred output:

- the business-facing display name
- fallback like `New Company`, `New Item`, `New GST Tax Rule`

This keeps `SettingsWorkspace(editorTitle: selected?.toString())` simple and consistent.

## API Service Rules

- keep API communication inside service classes only
- do not build raw HTTP calls inside pages
- keep one canonical service path per concept
- if backend has duplicate paths, remove or stop using the duplicate path

Examples already standardized:

- inventory masters use canonical `/inventory/*` routes
- read-only inquiry concepts should not expose editable frontend CRUD

## Shared UX Pattern

Default pattern for settings and masters:

- list + editor
- desktop: list and editor together
- non-desktop: list first, editor opens separately

Use `SettingsWorkspace` and `SettingsWorkspaceController` unless there is a real reason not to.

### New Record Behavior

- desktop: clicking `New` clears the editor
- non-desktop: clicking `New` clears the editor and opens the empty editor view

### Editor Titles

Use:

```dart
editorTitle: _selectedItem?.toString(),
```

Do not hand-build repeated title strings unless the screen truly needs custom wording.

## Shell Rule

- drawer/menu stays persistent
- page content changes in the center area only
- page-specific actions belong to the page header/content area, not the global shell header
- on mobile, header/actions should adapt for space
- on desktop/tablet, drawer remains visible and can collapse/expand

## Tab Pattern

If a record must exist before child tabs are meaningful, follow the `Parties` and `Items` pattern:

- `Primary` tab stays editable for new records
- other tabs show one clear message until the record is saved or selected

Do not partially enable child tabs with broken state.

If a tab body depends on `_tabController.index`, make sure the body rebuilds when the tab changes. In popup/mobile flows, use an `AnimatedBuilder` or equivalent listener pattern so tab content does not appear stuck.

## Form Design Rules

### Keep The UI Simple

- avoid stacked cards inside cards
- avoid repeated headings inside each embedded tab
- present big features in a simple way
- prefer calm layouts over decorative complexity

### Form Rule

- do not use raw `TextFormField` directly in normal forms unless there is a special need
- use `AppFormTextField`
- do not use raw `DropdownButtonFormField` directly in normal forms unless there is a special need
- use `AppDropdownField`
- do not use raw switch tiles directly in normal forms unless there is a special need
- use shared toggle/switch components
- upload fields should use `UploadPathField`
- quick-create beside lookup/dropdown fields should use `InlineFieldAction` where appropriate

### Embedded Child Collections

Inside a parent editor, child tabs should usually be:

- current rows first
- add/search area below
- compact editor only when adding or editing

If clicking the same selected child row again, clear the draft form so a new row can be started quickly.

If already-linked rows should not be added again, hide them from add/search results.

### Dropdown Rule

- for simple dropdowns, prefer `AppDropdownField.fromMapped(...)`
- use clean `value` / `label` option lists
- keep dropdown option definitions short and consistent

### Dropdown Add-New Pattern

If a supporting master is commonly needed while editing another master, allow inline add flow beside the dropdown.

Examples:

- category
- brand
- tax code

### UOM Filtering Rule

If a screen asks for a UOM related to a specific item, show only:

- the item's own UOM
- purchase/sales/base UOMs if modeled
- directly convertible UOMs

Do not show the full global UOM list when the business rule is narrower.

## Settings Screen Rule

- prefer the established list + editor workspace pattern
- left side is usually a searchable list
- right side is usually create/edit form
- optional tabs appear after save when the record exists

## Validation Rules

- put normal reusable validation in `lib/helper/validators.dart`
- page-local validation is only for true special cases
- frontend validation must mirror backend-required fields and safe field lengths

Before shipping a form, verify:

- required fields
- max lengths
- numeric rules
- date rules
- cross-field rules

If backend returns `422`, prefer showing helpful field or flattened error messages instead of generic failure text.

## Media / File Upload Rules

Do not use plain text path entry for image/file fields when browser/file-picker flow is appropriate.

Preferred pattern:

- browse or pick file
- upload through `MediaService`
- store returned `file_path`
- show preview when useful

Use existing helpers/components first:

- `UploadPathField`
- `MediaUploadHelper`
- `MediaService`
- local file picker helpers

Recommended fields that should follow this pattern:

- company logo
- letter head
- profile photo
- item image
- item-category image

## Shared Component Rules

Before creating a new local widget, check whether a shared component already exists.

Examples:

- use `AppToggleChip` instead of making another item-only toggle widget
- use `AppDropdownField` instead of raw repeated dropdown boilerplate
- use shared settings/report layout widgets instead of rebuilding the structure again
- prefer `SettingsListCard`, `SettingsListTile`, `SettingsStatusPill`, and `AppSectionCard` before creating new list/editor chrome

If a local widget solves a reusable problem, promote the shared component instead of copying the pattern again.

### Dropdown Safety

`AppDropdownField` must never crash when:

- API returns `null`
- selected value is stale
- item list no longer contains the old value

Always resolve initial value against actual item values first.

### Toggle Behavior

`AppToggleChip` default behavior should stay compact.

Use explicit width/style options when a tile-like full-row presentation is needed instead of creating new one-off toggle widgets.

## Report Rule

- reports should follow the shared report pattern
- mobile uses compact/icon-focused controls
- desktop/tablet favors table-friendly layout
- pagination/filter/sort changes should reload report data, not the whole page

## Empty / Loading / Error Rule

- first page load can show a full loading state
- subsequent refresh should prefer local loading states
- use shared loading/error widgets where possible
- empty tabs/sections should use intentional empty states, not blank space

## Auth / Session / Access Rules

### `401` / `403`

If the session is expired or unauthorized:

- clear session safely
- go to login
- preserve the current route as a return target when appropriate

### Permission Refresh

After role/user permission changes:

1. refresh auth context from backend
2. update current session permission state
3. notify shell/navigation listeners
4. redraw menu access immediately
5. redirect away from routes the user no longer has access to

Do not require a manual full reload for permission changes to appear.

## API Error And Debug Rules

For development, failed requests should log enough detail to replay in Postman.

Minimum useful logging on failure:

- HTTP method
- full URL
- request payload or multipart fields
- status code
- response body

Handle these cases intentionally:

- `304`: reuse cached body if conditional GET is active
- `401/403`: session flow
- `422`: flatten and show validation messages
- `500`: show meaningful backend message when available

## Caching Rules

Caching is allowed only when it does not introduce false business data.

Current safe rule:

- use memory cache and request deduplication mainly for stable GET masters/reference data
- use `ETag` / conditional GET where backend supports it
- invalidate related cache after successful writes
- do not casually cache volatile transactional data

If in doubt, prefer correctness over fewer requests.

## Schema-Contract Discipline

Before fixing a frontend bug, always ask:

- is the table column name correct?
- is controller validation using the same field?
- is service/repository returning the same field?
- is Flutter model parsing the same field?
- is form payload sending the same field?

Typical mistakes to avoid:

- stale legacy names when schema uses different columns
- assuming `name` exists on `users`
- using fields in Flutter that do not exist in the table

## Consistency Over Speed

If we already solved a pattern elsewhere, reuse it.

Examples:

- party-style code generation patterns
- party/item save-first tab behavior
- browser-based image selection
- typed model style used by `MediaFileModel`

Do not introduce a second pattern just because it is faster in the moment.

## Preferred Workflow For New UI

When creating a new module screen:

1. check whether existing shell/layout/settings/report components already fit
2. use `screen.dart` for common imports
3. use shared form widgets first
4. only create a new component if the pattern is reusable
5. if a new component is created, update future screens to use it rather than duplicating
6. run `flutter analyze` after changes

## Done Definition

A frontend task is not complete until:

1. database, API, model, validator, and form fields align
2. list and editor flows both work
3. mobile/non-desktop behavior is checked if relevant
4. permission/session behavior is not broken
5. `flutter analyze` passes on touched files
6. today’s decisions are added to a report document when the work is significant

## Rule Of Thumb

If a future UI change should reflect everywhere, it must live in:

- theme
- constants
- shared component
- shared layout widget

not in individual screen code.
