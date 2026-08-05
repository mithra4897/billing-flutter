# Print PDF Rupee Font Asset

**Date:** 2026-08-05  
**Scope:** Flutter web document-PDF generation

## Objective

Ensure the Poppins font used as the PDF rupee-symbol fallback is packaged in
the Flutter web asset manifest.

## Requirements

- Register `assets/fonts/Poppins-Regular.ttf` explicitly in `pubspec.yaml`.
- Preserve the existing font families and PDF fallback logic.
- On web, `rootBundle.load('assets/fonts/Poppins-Regular.ttf')` must resolve
  without a 404 response.
- If the primary vector-PDF path fails for an unrelated reason, retain the
  existing high-resolution fallback behaviour.
- Make no API, database, accounting, or print-template persistence changes.

## Acceptance criteria

1. The generated Flutter web asset manifest contains
   `assets/fonts/Poppins-Regular.ttf`.
2. A web build completes successfully.
3. Existing focused quotation-print tests and static analysis continue to pass.

## Verification

- `flutter build web` completed on 2026-08-05.
- The output contains `build/web/assets/assets/fonts/Poppins-Regular.ttf` and
  its asset manifest entry.
- The six focused quotation-print tests and focused Flutter analysis passed.
