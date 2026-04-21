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
