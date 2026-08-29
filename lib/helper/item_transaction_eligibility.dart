import '../model/masters/item_model.dart';

List<ItemModel> saleableItemsForEditor(
  Iterable<ItemModel> items, {
  Iterable<int?> retainedItemIds = const <int?>[],
}) {
  final retainedIds = retainedItemIds.whereType<int>().toSet();
  return items
      .where(
        (item) =>
            item.isSaleable ||
            (item.id != null && retainedIds.contains(item.id)),
      )
      .toList(growable: false);
}

List<ItemModel> purchaseableItemsForEditor(
  Iterable<ItemModel> items, {
  Iterable<int?> retainedItemIds = const <int?>[],
}) {
  final retainedIds = retainedItemIds.whereType<int>().toSet();
  return items
      .where(
        (item) =>
            item.isPurchaseable ||
            (item.id != null && retainedIds.contains(item.id)),
      )
      .toList(growable: false);
}
