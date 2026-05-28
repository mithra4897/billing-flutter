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
