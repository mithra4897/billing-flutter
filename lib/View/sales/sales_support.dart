import '../../screen.dart';
import '../purchase/purchase_support.dart';

List<PartyModel> salesCustomers({
  required List<PartyModel> parties,
  required List<PartyTypeModel> partyTypes,
}) {
  final customerTypeIds = partyTypes
      .where(_looksLikeCustomerType)
      .map((item) => intValue(item.toJson(), 'id'))
      .whereType<int>()
      .toSet();

  return parties
      .where(
        (party) =>
            party.isActive && customerTypeIds.contains(party.partyTypeId),
      )
      .toList(growable: false);
}

/// If no party type is tagged as customer, show all active parties so marketing can still quote.
List<PartyModel> salesCustomersOrFallback({
  required List<PartyModel> parties,
  required List<PartyTypeModel> partyTypes,
}) {
  final filtered = salesCustomers(parties: parties, partyTypes: partyTypes);
  if (filtered.isNotEmpty) {
    return filtered;
  }
  return parties.where((p) => p.isActive).toList(growable: false);
}

bool _looksLikeCustomerType(PartyTypeModel type) {
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
  return code.contains('customer') ||
      code.contains('buyer') ||
      name.contains('customer') ||
      name.contains('buyer');
}

String quotationCustomerLabel(Map<String, dynamic> data) {
  final customer = data['customer'];
  if (customer is Map) {
    return stringValue(Map<String, dynamic>.from(customer), 'party_name');
  }
  return stringValue(data, 'customer_name');
}

/// Selling price from item master for defaulting document lines (standard rate, else MRP).
String? formattedStandardSellingRate(ItemModel item) {
  final p = item.standardSellingPrice ?? item.mrp;
  if (p == null) {
    return null;
  }
  if (p == 0) {
    return '0';
  }
  if (p == p.roundToDouble()) {
    return p.round().toString();
  }
  return p.toString();
}

/// When the user picks an item, fill rate / UOM / tax (and optionally single-warehouse) from master.
void applySalesLineDefaultsFromItemMaster({
  required ItemModel? item,
  required List<UomModel> uoms,
  required List<UomConversionModel> conversions,
  required TextEditingController rateController,
  TextEditingController? descriptionController,
  TextEditingController? qtyController,
  required void Function(int? uomId) setUom,
  int? currentUomId,
  void Function(int? taxCodeId)? setTaxCodeId,
  void Function(int? warehouseId)? setWarehouseId,
  int? currentWarehouseId,
  List<WarehouseModel>? warehouses,
}) {
  if (item == null) {
    return;
  }
  setUom(
    defaultSalesUomIdForItem(
      item,
      uoms,
      conversions,
      current: currentUomId,
    ),
  );
  setTaxCodeId?.call(item.taxCodeId);
  final rate = formattedStandardSellingRate(item);
  if (rate != null) {
    rateController.text = rate;
  }
  if (descriptionController != null &&
      descriptionController.text.trim().isEmpty) {
    final description = item.itemName.trim().isNotEmpty
        ? item.itemName.trim()
        : item.itemCode.trim();
    if (description.isNotEmpty) {
      descriptionController.text = description;
    }
  }
  if (qtyController != null &&
      item.hasSerial &&
      qtyController.text.trim().isEmpty) {
    qtyController.text = '1';
  }
  if (setWarehouseId != null &&
      warehouses != null &&
      warehouses.length == 1 &&
      currentWarehouseId == null) {
    setWarehouseId(warehouses.first.id);
  }
}

int? defaultSalesUomIdForItem(
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
    item?.salesUomId,
    item?.baseUomId,
    item?.purchaseUomId,
  ];
  for (final id in preferred) {
    if (id != null && (allowedIds.isEmpty || allowedIds.contains(id))) {
      return id;
    }
  }

  final allowed = allowedUomsForItem(item, uoms, conversions);
  return allowed.isNotEmpty ? allowed.first.id : null;
}
