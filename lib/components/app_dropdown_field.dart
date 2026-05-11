import 'package:flutter/material.dart';

import 'erp_link_field.dart';

class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label});

  final T value;
  final String label;

  @override
  String toString() => label;
}

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.labelText,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.validator,
    this.width,
    this.hintText,
    this.doctypeLabel,
    this.onCreateNew,
    this.onNavigateToCreateNew,
    this.allowCreate = false,
    this.createNewLabelBuilder,
  }) : records = null,
       mappedItems = null,
       valueKey = null,
       labelKey = null;

  const AppDropdownField.fromMapped({
    super.key,
    required this.labelText,
    required this.mappedItems,
    required this.onChanged,
    this.initialValue,
    this.validator,
    this.width,
    this.hintText,
    this.doctypeLabel,
    this.onCreateNew,
    this.onNavigateToCreateNew,
    this.allowCreate = false,
    this.createNewLabelBuilder,
  }) : items = null,
       records = null,
       valueKey = null,
       labelKey = null;

  const AppDropdownField.fromRecords({
    super.key,
    required this.labelText,
    required this.records,
    required this.valueKey,
    required this.onChanged,
    this.initialValue,
    this.validator,
    this.width,
    this.hintText,
    this.labelKey,
    this.doctypeLabel,
    this.onCreateNew,
    this.onNavigateToCreateNew,
    this.allowCreate = false,
    this.createNewLabelBuilder,
  }) : items = null,
       mappedItems = null;

  final String labelText;
  final List<DropdownMenuItem<T>>? items;
  final List<AppDropdownItem<T>>? mappedItems;
  final List<Map<String, dynamic>>? records;
  final String? valueKey;
  final String? labelKey;
  final T? initialValue;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T?>? validator;
  final double? width;
  final String? hintText;
  final String? doctypeLabel;
  final Future<ErpLinkFieldOption<T>?> Function(String query)? onCreateNew;
  final ValueChanged<String>? onNavigateToCreateNew;
  final bool allowCreate;
  final String Function(String query, String doctypeLabel)?
  createNewLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final options = _buildOptions();
    final selected = _resolveInitialSelection(options);

    return ErpLinkField<T>(
      labelText: labelText,
      doctypeLabel: doctypeLabel,
      hintText: hintText,
      width: width,
      initialSelection: selected,
      options: options,
      onChanged: onChanged,
      validator: validator,
      onCreateNew: onCreateNew,
      onNavigateToCreateNew: onNavigateToCreateNew,
      allowCreate: allowCreate,
      createNewLabelBuilder: createNewLabelBuilder,
    );
  }

  ErpLinkFieldOption<T>? _resolveInitialSelection(
    List<ErpLinkFieldOption<T>> options,
  ) {
    final value = initialValue;
    if (value == null) {
      return null;
    }
    return options.cast<ErpLinkFieldOption<T>?>().firstWhere(
      (item) => item?.value == value,
      orElse: () => null,
    );
  }

  List<ErpLinkFieldOption<T>> _buildOptions() {
    if (mappedItems != null) {
      return mappedItems!
          .map(
            (item) => ErpLinkFieldOption<T>(
              value: item.value,
              label: item.label,
              searchText: item.label,
            ),
          )
          .toList(growable: false);
    }

    if (records != null && valueKey != null) {
      return records!
          .where((record) => record[valueKey] != null)
          .map((record) {
            final rawValue = record[valueKey];
            final rawLabel = labelKey == null ? rawValue : record[labelKey];
            final label = (rawLabel ?? rawValue ?? '').toString();
            return ErpLinkFieldOption<T>(
              value: rawValue as T,
              label: label,
              searchText: label,
            );
          })
          .toList(growable: false);
    }

    if (items != null) {
      return items!
          .where((item) => item.value != null)
          .map(
            (item) => ErpLinkFieldOption<T>(
              value: item.value as T,
              label: _labelFromWidget(item.child),
              searchText: _labelFromWidget(item.child),
            ),
          )
          .toList(growable: false);
    }

    return <ErpLinkFieldOption<T>>[];
  }

  String _labelFromWidget(Widget child) {
    if (child is Text) {
      return child.data ?? '';
    }
    if (child is DefaultTextStyle && child.child is Text) {
      return (child.child as Text).data ?? '';
    }
    return child.toStringShort();
  }
}
