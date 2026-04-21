import '../../screen.dart';

List<PartyModel> purchaseSuppliers({
  required List<PartyModel> parties,
  required List<PartyTypeModel> partyTypes,
}) {
  final supplierTypeIds = partyTypes
      .where(_looksLikeSupplierType)
      .map((item) => intValue(item.toJson(), 'id'))
      .whereType<int>()
      .toSet();

  return parties
      .where(
        (party) =>
            party.isActive && supplierTypeIds.contains(party.partyTypeId),
      )
      .toList(growable: false);
}

bool _looksLikeSupplierType(PartyTypeModel type) {
  final data = type.toJson();
  final code = (stringValue(data, 'code').isNotEmpty
          ? stringValue(data, 'code')
          : stringValue(data, 'type_code'))
      .trim()
      .toLowerCase();
  final name = (stringValue(data, 'name').isNotEmpty
          ? stringValue(data, 'name')
          : stringValue(data, 'type_name'))
      .trim()
      .toLowerCase();
  return code.contains('supplier') ||
      code.contains('vendor') ||
      name.contains('supplier') ||
      name.contains('vendor');
}

String displayDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }

  return value.split('T').first.split(' ').first;
}

String displayDateTime(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }

  final parsed = DateTime.tryParse(value.trim());
  if (parsed != null) {
    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  final normalized = value.trim().replaceFirst('T', ' ');
  return normalized.endsWith('Z')
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
}

String currentDateTimeInput() {
  return displayDateTime(DateTime.now().toIso8601String());
}

Set<int> allowedUomIdsForItem(
  ItemModel? item,
  List<UomConversionModel> conversions,
) {
  if (item == null) {
    return <int>{};
  }

  final seedIds = <int>{
    if (item.baseUomId != null) item.baseUomId!,
    if (item.purchaseUomId != null) item.purchaseUomId!,
    if (item.salesUomId != null) item.salesUomId!,
  };

  if (seedIds.isEmpty) {
    return <int>{};
  }

  final allowed = <int>{...seedIds};
  final pending = List<int>.from(seedIds);

  while (pending.isNotEmpty) {
    final currentId = pending.removeLast();
    for (final conversion in conversions) {
      final fromId = conversion.fromUomId;
      final toId = conversion.toUomId;
      if (fromId == null || toId == null) {
        continue;
      }

      if (fromId == currentId && allowed.add(toId)) {
        pending.add(toId);
      }
      if (toId == currentId && allowed.add(fromId)) {
        pending.add(fromId);
      }
    }
  }

  return allowed;
}

List<UomModel> allowedUomsForItem(
  ItemModel? item,
  List<UomModel> uoms,
  List<UomConversionModel> conversions,
) {
  final allowedIds = allowedUomIdsForItem(item, conversions);
  if (allowedIds.isEmpty) {
    return const <UomModel>[];
  }

  return uoms
      .where((uom) => uom.id != null && allowedIds.contains(uom.id))
      .toList(growable: false);
}

int? defaultUomIdForItem(
  ItemModel? item,
  List<UomModel> uoms,
  List<UomConversionModel> conversions, {
  int? current,
}) {
  final allowedIds = allowedUomIdsForItem(item, conversions);
  if (current != null && (allowedIds.isEmpty || allowedIds.contains(current))) {
    return current;
  }

  final preferred = <int?>[
    item?.purchaseUomId,
    item?.baseUomId,
    item?.salesUomId,
  ];
  for (final id in preferred) {
    if (id != null && (allowedIds.isEmpty || allowedIds.contains(id))) {
      return id;
    }
  }

  final allowed = allowedUomsForItem(item, uoms, conversions);
  return allowed.isNotEmpty ? allowed.first.id : null;
}

class PurchaseListCard<T> extends StatelessWidget {
  const PurchaseListCard({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.emptyMessage,
    required this.searchController,
    required this.searchHint,
    this.statusValue,
    this.statusItems = const <AppDropdownItem<String>>[],
    this.onStatusChanged,
    required this.itemBuilder,
  });

  final List<T> items;
  final T? selectedItem;
  final String emptyMessage;
  final TextEditingController searchController;
  final String searchHint;
  final String? statusValue;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?>? onStatusChanged;
  final Widget Function(T item, bool selected) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          if (statusItems.isNotEmpty && onStatusChanged != null) ...[
            const SizedBox(height: AppUiConstants.spacingSm),
            AppDropdownField<String>.fromMapped(
              labelText: 'Status',
              mappedItems: statusItems,
              initialValue: statusValue,
              onChanged: onStatusChanged!,
            ),
          ],
          const SizedBox(height: AppUiConstants.spacingMd),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppUiConstants.spacingXl,
              ),
              child: Text(emptyMessage),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppUiConstants.spacingXs),
              itemBuilder: (context, index) => itemBuilder(
                items[index],
                identical(items[index], selectedItem),
              ),
            ),
        ],
      ),
    );
  }
}

class PurchaseCompactLineCard extends StatelessWidget {
  const PurchaseCompactLineCard({
    super.key,
    required this.index,
    required this.total,
    required this.child,
    this.onRemove,
    this.removeEnabled = true,
  });

  final int index;
  final int total;
  final Widget child;
  final VoidCallback? onRemove;
  final bool removeEnabled;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return AppSectionCard(
      padding: const EdgeInsets.all(AppUiConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppUiConstants.spacingSm,
                  vertical: AppUiConstants.spacingXxs,
                ),
                decoration: BoxDecoration(
                  color: appTheme.subtleFill,
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.pillRadius,
                  ),
                ),
                child: Text(
                  total > 1 ? '#${index + 1}' : 'Line',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: removeEnabled ? onRemove : null,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          child,
        ],
      ),
    );
  }
}

class PurchaseCompactFieldGrid extends StatelessWidget {
  const PurchaseCompactFieldGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppUiConstants.spacingSm;
        final width = constraints.maxWidth;
        final columns = width >= 1320
            ? 4
            : width >= 980
            ? 3
            : width >= 620
            ? 2
            : 1;
        final itemWidth = columns == 1
            ? width
            : (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth > 0 ? itemWidth : width,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
