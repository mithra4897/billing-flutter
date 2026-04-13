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
  final code = stringValue(data, 'type_code').trim().toLowerCase();
  final name = stringValue(data, 'type_name').trim().toLowerCase();
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
