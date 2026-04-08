import 'package:flutter/material.dart';

import 'app_field_box.dart';

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
  final FormFieldValidator<T>? validator;
  final double? width;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final dropdownItems = items ?? _buildMappedItems() ?? _buildRecordItems();

    return AppFieldBox(
      width: width,
      child: DropdownButtonFormField<T>(
        initialValue: _resolveInitialValue(dropdownItems),
        decoration: InputDecoration(labelText: labelText, hintText: hintText),
        items: dropdownItems,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  T? _resolveInitialValue(List<DropdownMenuItem<T>> dropdownItems) {
    final value = initialValue;
    if (value == null) {
      return null;
    }

    final hasMatch = dropdownItems.any((item) => item.value == value);
    return hasMatch ? value : null;
  }

  List<DropdownMenuItem<T>>? _buildMappedItems() {
    if (mappedItems == null) {
      return null;
    }

    return mappedItems!
        .map(
          (item) =>
              DropdownMenuItem<T>(value: item.value, child: Text(item.label)),
        )
        .toList(growable: false);
  }

  List<DropdownMenuItem<T>> _buildRecordItems() {
    if (records == null || valueKey == null) {
      return <DropdownMenuItem<T>>[];
    }

    return records!
        .map((record) {
          final rawValue = record[valueKey];
          final rawLabel = labelKey == null ? rawValue : record[labelKey];
          return DropdownMenuItem<T>(
            value: rawValue as T?,
            child: Text((rawLabel ?? rawValue ?? '').toString()),
          );
        })
        .toList(growable: false);
  }
}
