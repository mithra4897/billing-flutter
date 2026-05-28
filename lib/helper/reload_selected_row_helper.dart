import 'package:flutter/foundation.dart';

import '../model/common/json_model.dart';

List<T>? preserveSelectedRowAfterReload<T extends JsonModel>({
  required List<T> rows,
  required T? selected,
  required int? selectId,
}) {
  if (selectId == null || selected == null) {
    return null;
  }

  final selectedId =
      selected.id ?? JsonModel.nullableInt(selected.toJson()['id']);
  if (selectedId != selectId) {
    return null;
  }

  return <T>[
    selected,
    ...rows.where(
      (row) =>
          (row.id ?? JsonModel.nullableInt(row.toJson()['id'])) != selectId,
    ),
  ];
}

Future<bool> restoreSelectionAfterReload<T extends JsonModel>({
  required int? selectId,
  required List<T> rows,
  required T? selected,
  required Future<void> Function(T row) onSelect,
  required void Function(List<T> nextRows) replaceRows,
  required VoidCallback notify,
  Future<void> Function(int id)? onMissingId,
  T Function(int id)? placeholderBuilder,
}) async {
  if (selectId == null) {
    return false;
  }

  final existing = rows.cast<T?>().firstWhere(
    (row) =>
        (row?.id ?? JsonModel.nullableInt(row?.toJson()['id'])) == selectId,
    orElse: () => null,
  );
  if (existing != null) {
    await onSelect(existing);
    return true;
  }

  final recoveredRows = preserveSelectedRowAfterReload<T>(
    rows: rows,
    selected: selected,
    selectId: selectId,
  );
  if (recoveredRows != null) {
    replaceRows(recoveredRows);
    notify();
    return true;
  }

  if (onMissingId != null) {
    await onMissingId(selectId);
    return true;
  }

  if (placeholderBuilder != null) {
    await onSelect(placeholderBuilder(selectId));
    return true;
  }

  return false;
}
