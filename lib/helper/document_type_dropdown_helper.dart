import '../screen.dart';

List<AppDropdownItem<String>> buildDocumentTypeDropdownItems(
  List<DocumentSeriesModel> source,
) {
  final documentTypes =
      source
          .map((item) => (item.documentType ?? '').trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  return documentTypes
      .map((item) => AppDropdownItem<String>(value: item, label: item))
      .toList(growable: false);
}

({String? selectedValue, List<AppDropdownItem<String>> items})
resolveDocumentTypeSelection({
  required List<AppDropdownItem<String>> items,
  required String? value,
}) {
  final normalized = nullIfEmpty(value ?? '');
  if (normalized == null) {
    return (selectedValue: null, items: items);
  }

  final exists = items.any((item) => item.value == normalized);
  if (exists) {
    return (selectedValue: normalized, items: items);
  }

  return (
    selectedValue: normalized,
    items: <AppDropdownItem<String>>[
      ...items,
      AppDropdownItem<String>(value: normalized, label: normalized),
    ],
  );
}
