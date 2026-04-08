# Frontend Update Notes

## Centralized Media Upload

- Refactored the generic file picking architecture to use a unified `MediaUploadHelper` (`lib/helper/media_upload_helper.dart`). 
- Extracted and deduplicated the bulky `FilePicker` modal and popup dialog state logic out of 4 separate screens resulting in a massive code cleanup.
- Updated the API Client (`lib/core/api/api_client.dart`) to explicitly wrap files with `http_parser` `MediaType` to resolve unmapped `application/octet-stream` backend errors.
- Added strict path filename sanitization via Regex to guarantee valid `Content-Disposition` multipart transmission headers across OS environments.

## Updated Files

- `lib/helper/media_upload_helper.dart` (New)
- `lib/View/settings/master/item_page.dart`
- `lib/View/settings/master/item_category_page.dart`
- `lib/View/settings/user/profile_page.dart`
- `lib/View/settings/user/user_management_page.dart`
- `lib/core/api/api_client.dart`
