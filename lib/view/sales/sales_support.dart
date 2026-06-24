import '../../screen.dart';

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
  final code =
      (stringValue(data, 'code').isNotEmpty
              ? stringValue(data, 'code')
              : stringValue(data, 'type_code'))
          .trim()
          .toLowerCase();
  final name =
      (stringValue(data, 'name').isNotEmpty
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

Future<void> openSalesSearchStatusFilterPanel({
  required BuildContext context,
  required String title,
  required TextEditingController searchController,
  required TextEditingController dateFromController,
  required TextEditingController dateToController,
  required String searchHint,
  required String status,
  required List<AppDropdownItem<String>> statusItems,
  required void Function(
    String search,
    String status,
    String dateFrom,
    String dateTo,
  )
  onApply,
  required VoidCallback onClear,
}) async {
  final screenWidth = MediaQuery.of(context).size.width;
  final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
  final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;
  final dialogSearchController = TextEditingController(
    text: searchController.text,
  );
  final dialogDateFromController = TextEditingController(
    text: dateFromController.text,
  );
  final dialogDateToController = TextEditingController(
    text: dateToController.text,
  );
  var tempStatus = status;

  await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final appTheme = Theme.of(dialogContext).extension<AppThemeExtension>()!;
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  dialogPadding,
                  dialogPadding,
                  dialogPadding,
                  MediaQuery.of(dialogContext).viewInsets.bottom +
                      dialogPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(dialogContext).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          tooltip: 'Close',
                          icon: const Icon(Icons.close),
                          color: appTheme.mutedText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SalesSearchStatusFilters(
                      searchController: dialogSearchController,
                      dateFromController: dialogDateFromController,
                      dateToController: dialogDateToController,
                      searchHint: searchHint,
                      status: tempStatus,
                      statusItems: statusItems,
                      onStatusChanged: (value) {
                        setDialogState(() {
                          tempStatus = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            onApply(
                              dialogSearchController.text,
                              tempStatus,
                              dialogDateFromController.text,
                              dialogDateToController.text,
                            );
                            Navigator.of(dialogContext).pop(true);
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Apply Filters'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            onClear();
                            Navigator.of(dialogContext).pop(true);
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  dialogSearchController.dispose();
  dialogDateFromController.dispose();
  dialogDateToController.dispose();
}

class _SalesSearchStatusFilters extends StatelessWidget {
  const _SalesSearchStatusFilters({
    required this.searchController,
    required this.dateFromController,
    required this.dateToController,
    required this.searchHint,
    required this.status,
    required this.statusItems,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final TextEditingController dateFromController;
  final TextEditingController dateToController;
  final String searchHint;
  final String status;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final children = <Widget>[
          AppFormTextField(
            labelText: searchHint,
            controller: searchController,
            prefixIcon: const Icon(Icons.search_outlined),
          ),
          AppDateField(labelText: 'From Date', controller: dateFromController),
          AppDateField(labelText: 'To Date', controller: dateToController),
          AppDropdownField<String>.fromMapped(
            labelText: 'Status',
            mappedItems: statusItems,
            initialValue: status,
            onChanged: onStatusChanged,
          ),
        ];
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppUiConstants.spacingSm,
                    ),
                    child: child,
                  ),
                )
                .toList(growable: false),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: children[0]),
            const SizedBox(width: AppUiConstants.spacingSm),
            Expanded(child: children[1]),
            const SizedBox(width: AppUiConstants.spacingSm),
            Expanded(child: children[2]),
            const SizedBox(width: AppUiConstants.spacingSm),
            Expanded(child: children[3]),
          ],
        );
      },
    );
  }
}

PartyAddressModel? preferredPartyAddress(
  PartyModel? party, {
  int? shippingAddressId,
  int? billingAddressId,
}) {
  if (party == null) {
    return null;
  }

  PartyAddressModel? byId(int? id) {
    if (id == null) {
      return null;
    }
    return party.addresses.cast<PartyAddressModel?>().firstWhere(
      (address) => address?.id == id,
      orElse: () => null,
    );
  }

  final preferred = byId(shippingAddressId) ?? byId(billingAddressId);
  if (preferred != null && preferred.isActive) {
    return preferred;
  }

  final shipping = party.addresses.where(
    (address) =>
        address.isActive &&
        (address.addressType ?? '').trim().toLowerCase() == 'shipping',
  );
  if (shipping.isNotEmpty) {
    return shipping.firstWhere(
      (address) => address.isDefault,
      orElse: () => shipping.first,
    );
  }

  final billing = party.addresses.where(
    (address) =>
        address.isActive &&
        (address.addressType ?? '').trim().toLowerCase() == 'billing',
  );
  if (billing.isNotEmpty) {
    return billing.firstWhere(
      (address) => address.isDefault,
      orElse: () => billing.first,
    );
  }

  final active = party.addresses.where((address) => address.isActive);
  if (active.isNotEmpty) {
    return active.firstWhere(
      (address) => address.isDefault,
      orElse: () => active.first,
    );
  }

  return null;
}

String? normalizeGstStateCode(String? code) {
  final normalized = (code ?? '').trim().toUpperCase();
  if (normalized.isEmpty) {
    return null;
  }
  final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isNotEmpty && digitsOnly.length <= 2) {
    return digitsOnly.padLeft(2, '0');
  }
  return normalized;
}

String? gstStateCodeFromGstin(String? gstin) {
  final normalized = (gstin ?? '').trim().toUpperCase();
  if (normalized.length < 2) {
    return null;
  }
  final prefix = normalized.substring(0, 2);
  return RegExp(r'^\d{2}$').hasMatch(prefix) ? prefix : null;
}

String? resolveCompanyStateCodeForGstSummary({
  required List<GstRegistrationModel> gstRegistrations,
  required List<BusinessLocationModel> locations,
  required List<CompanyModel> companies,
  required int? companyId,
  required int? branchId,
  required int? locationId,
}) {
  final matchingRegistrations = gstRegistrations
      .where(
        (entry) =>
            entry.isActive &&
            (companyId == null || entry.companyId == companyId),
      )
      .toList(growable: false);
  if (matchingRegistrations.isNotEmpty) {
    matchingRegistrations.sort((a, b) {
      int score(GstRegistrationModel entry) {
        var value = 0;
        if (locationId != null && entry.locationId == locationId) {
          value += 4;
        }
        if (branchId != null && entry.branchId == branchId) {
          value += 2;
        }
        if (entry.isDefault) {
          value += 1;
        }
        return value;
      }

      final byScore = score(b).compareTo(score(a));
      if (byScore != 0) {
        return byScore;
      }
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    final fromRegistration = gstStateCodeFromGstin(
      matchingRegistrations.first.gstin,
    );
    if (fromRegistration != null) {
      return fromRegistration;
    }
  }

  final location = locations.cast<BusinessLocationModel?>().firstWhere(
    (entry) => entry?.id == locationId,
    orElse: () => null,
  );
  final fromLocation = normalizeGstStateCode(location?.stateCode);
  if (fromLocation != null) {
    return fromLocation;
  }

  final company = companies.cast<CompanyModel?>().firstWhere(
    (entry) => entry?.id == companyId,
    orElse: () => null,
  );
  final fromCompany = normalizeGstStateCode(company?.stateCode);
  if (fromCompany != null) {
    return fromCompany;
  }

  return gstStateCodeFromGstin(company?.gstin);
}

String? resolvePartyStateCodeForGstSummary({
  required PartyModel? party,
  List<PartyGstDetailModel> gstDetails = const <PartyGstDetailModel>[],
  int? shippingAddressId,
  int? billingAddressId,
  String preferredAddressType = 'shipping',
}) {
  if (party == null) {
    return null;
  }

  PartyAddressModel? byId(int? id) {
    if (id == null) {
      return null;
    }
    return party.addresses.cast<PartyAddressModel?>().firstWhere(
      (address) => address?.id == id,
      orElse: () => null,
    );
  }

  final normalizedPreferredType = preferredAddressType.trim().toLowerCase();
  final preferredAddress = normalizedPreferredType == 'billing'
      ? (byId(billingAddressId) ?? byId(shippingAddressId))
      : (byId(shippingAddressId) ?? byId(billingAddressId));
  final fromPreferredAddress = normalizeGstStateCode(
    preferredAddress?.stateCode,
  );
  if (fromPreferredAddress != null) {
    return fromPreferredAddress;
  }

  final typedAddresses = party.addresses.where(
    (address) =>
        address.isActive &&
        (address.addressType ?? '').trim().toLowerCase() ==
            normalizedPreferredType,
  );
  if (typedAddresses.isNotEmpty) {
    final preferredTypedAddress = typedAddresses.firstWhere(
      (address) => address.isDefault,
      orElse: () => typedAddresses.first,
    );
    final fromTypedAddress = normalizeGstStateCode(
      preferredTypedAddress.stateCode,
    );
    if (fromTypedAddress != null) {
      return fromTypedAddress;
    }
  }

  final activeAddresses = party.addresses.where((address) => address.isActive);
  if (activeAddresses.isNotEmpty) {
    final activeAddress = activeAddresses.firstWhere(
      (address) => address.isDefault,
      orElse: () => activeAddresses.first,
    );
    final fromActiveAddress = normalizeGstStateCode(activeAddress.stateCode);
    if (fromActiveAddress != null) {
      return fromActiveAddress;
    }
  }

  final activeGstDetails = gstDetails
      .where((detail) => detail.isActive != false)
      .toList(growable: false);
  if (activeGstDetails.isNotEmpty) {
    final preferredGstDetail = activeGstDetails.firstWhere(
      (detail) => detail.isDefault == true,
      orElse: () => activeGstDetails.first,
    );
    final fromStateCode = normalizeGstStateCode(preferredGstDetail.stateCode);
    if (fromStateCode != null) {
      return fromStateCode;
    }
    final fromGstin = gstStateCodeFromGstin(preferredGstDetail.gstin);
    if (fromGstin != null) {
      return fromGstin;
    }
  }

  return null;
}

bool? resolveIsInterStateForGstSummary({
  required String? companyStateCode,
  required String? counterpartyStateCode,
}) {
  if (companyStateCode == null || counterpartyStateCode == null) {
    return null;
  }
  return companyStateCode != counterpartyStateCode;
}

String formatPartyAddress(PartyAddressModel? address, {String fallback = ''}) {
  if (address == null) {
    return fallback;
  }
  final values = <String>[
    address.addressLine1 ?? '',
    address.addressLine2 ?? '',
    address.area ?? '',
    address.city ?? '',
    address.district ?? '',
    address.stateName ?? '',
    address.postalCode ?? '',
    address.countryCode ?? '',
  ].where((value) => value.trim().isNotEmpty).toList(growable: false);
  if (values.isEmpty) {
    return fallback;
  }
  return values.join(', ');
}

String resolvePreferredPartyGstin(
  List<PartyGstDetailModel> gstDetails, {
  Map<String, dynamic> sourceData = const <String, dynamic>{},
  String fallback = '',
}) {
  final activeDetails = gstDetails
      .where((detail) => detail.isActive != false)
      .toList(growable: false);
  if (activeDetails.isNotEmpty) {
    final preferred = activeDetails.firstWhere(
      (detail) => detail.isDefault == true,
      orElse: () => activeDetails.first,
    );
    final gstin = (preferred.gstin ?? '').trim();
    if (gstin.isNotEmpty) {
      return gstin;
    }
  }

  String firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = (value ?? '').trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  final direct = firstNonEmpty(<String?>[
    sourceData['gstin']?.toString(),
    sourceData['party_gstin']?.toString(),
    sourceData['customer_gstin']?.toString(),
    sourceData['gst_no']?.toString(),
  ]);
  if (direct.isNotEmpty) {
    return direct;
  }

  for (final key in <String>[
    'gst_details',
    'gstDetails',
    'party_gst_details',
  ]) {
    final raw = sourceData[key];
    if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        final data = Map<String, dynamic>.from(
          item.map((k, v) => MapEntry(k.toString(), v)),
        );
        final nested = firstNonEmpty(<String?>[
          data['gstin']?.toString(),
          data['party_gstin']?.toString(),
          data['customer_gstin']?.toString(),
          data['gst_no']?.toString(),
        ]);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }
    if (raw is Map) {
      final data = Map<String, dynamic>.from(
        raw.map((k, v) => MapEntry(k.toString(), v)),
      );
      final nested = firstNonEmpty(<String?>[
        data['gstin']?.toString(),
        data['party_gstin']?.toString(),
        data['customer_gstin']?.toString(),
        data['gst_no']?.toString(),
      ]);
      if (nested.isNotEmpty) {
        return nested;
      }
    }
  }

  return fallback;
}

PartyContactModel? preferredPartyContact(PartyModel? party) {
  if (party == null) {
    return null;
  }

  final active = party.contacts.where((contact) => contact.isActive);
  if (active.isEmpty) {
    return null;
  }

  return active.firstWhere(
    (contact) => contact.isPrimary,
    orElse: () => active.first,
  );
}

String resolvePartyContact(PartyModel? party, {String fallback = ''}) {
  final contact = preferredPartyContact(party);
  if (contact == null) {
    return fallback;
  }
  return (contact.mobile ?? '').trim().isNotEmpty
      ? contact.mobile!.trim()
      : (contact.phone ?? '').trim().isNotEmpty
      ? contact.phone!.trim()
      : (contact.email ?? '').trim().isNotEmpty
      ? contact.email!.trim()
      : fallback;
}

String? _formatSalesRate(double? rate) {
  final p = rate;
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

/// Selling price from item master for defaulting document lines (standard rate, else MRP).
String? formattedStandardSellingRate(ItemModel item) =>
    _formatSalesRate(item.standardSellingPrice ?? item.mrp);

DateTime? _tryParseSalesPriceDate(String? raw) {
  final parsed = DateTime.tryParse((raw ?? '').trim());
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

bool _isActiveSalesItemPriceForToday(ItemPriceModel price, DateTime today) {
  if (!price.isActive) {
    return false;
  }
  final type = (price.priceType ?? '').trim().toLowerCase();
  if (type.isNotEmpty && type != 'sales') {
    return false;
  }
  final validFrom = _tryParseSalesPriceDate(price.validFrom);
  final validTo = _tryParseSalesPriceDate(price.validTo);
  if (validFrom != null && validFrom.isAfter(today)) {
    return false;
  }
  if (validTo != null && validTo.isBefore(today)) {
    return false;
  }
  return true;
}

ItemPriceModel? preferredActiveSalesItemPrice({
  required ItemModel item,
  required List<ItemPriceModel> itemPrices,
  int? preferredUomId,
}) {
  final itemId = item.id;
  if (itemId == null) {
    return null;
  }
  final todayNow = DateTime.now();
  final today = DateTime(todayNow.year, todayNow.month, todayNow.day);
  final active = itemPrices
      .where((price) => price.itemId == itemId)
      .where((price) => price.price != null)
      .where((price) => _isActiveSalesItemPriceForToday(price, today))
      .toList(growable: false);
  if (active.isEmpty) {
    return null;
  }

  final ranked = List<ItemPriceModel>.from(active)
    ..sort((a, b) {
      final defaultCompare = (b.isDefault ? 1 : 0).compareTo(
        a.isDefault ? 1 : 0,
      );
      if (defaultCompare != 0) {
        return defaultCompare;
      }
      final preferredUomCompare = ((b.uomId == preferredUomId) ? 1 : 0)
          .compareTo((a.uomId == preferredUomId) ? 1 : 0);
      if (preferredUomCompare != 0) {
        return preferredUomCompare;
      }
      final bValidFrom = _tryParseSalesPriceDate(b.validFrom);
      final aValidFrom = _tryParseSalesPriceDate(a.validFrom);
      if (aValidFrom == null && bValidFrom == null) {
        return 0;
      }
      if (aValidFrom == null) {
        return 1;
      }
      if (bValidFrom == null) {
        return -1;
      }
      return bValidFrom.compareTo(aValidFrom);
    });
  return ranked.first;
}

String? formattedSalesRateFromItemPricing(
  ItemModel item,
  List<ItemPriceModel> itemPrices, {
  int? preferredUomId,
}) {
  final activePrice = preferredActiveSalesItemPrice(
    item: item,
    itemPrices: itemPrices,
    preferredUomId: preferredUomId ?? item.salesUomId ?? item.baseUomId,
  );
  return _formatSalesRate(activePrice?.price) ??
      formattedStandardSellingRate(item);
}

/// When the user picks an item, fill rate / UOM / tax (and optionally single-warehouse) from master.
void applySalesLineDefaultsFromItemMaster({
  required ItemModel? item,
  required List<ItemPriceModel> itemPrices,
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
    defaultSalesUomIdForItem(item, uoms, conversions, current: currentUomId),
  );
  setTaxCodeId?.call(item.taxCodeId);
  final rate = formattedSalesRateFromItemPricing(
    item,
    itemPrices,
    preferredUomId: currentUomId,
  );
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

double roundToDouble(double value, int fractionDigits) {
  return double.parse(value.toStringAsFixed(fractionDigits));
}

List<Widget> buildSalesDocumentContextFields({
  required List<AppDropdownItem<int>> documentSeriesItems,
  required int? documentSeriesId,
  required ValueChanged<int?> onDocumentSeriesChanged,
}) {
  return <Widget>[
    DocumentSeriesSelector<int>(
      labelText: 'Document Series',
      mappedItems: documentSeriesItems,
      initialValue: documentSeriesId,
      onChanged: onDocumentSeriesChanged,
    ),
  ];
}

List<Widget> buildSalesCustomerCommercialFields({
  required BuildContext context,
  required bool canEdit,
  required List<AppDropdownItem<int>> customerItems,
  required int? customerPartyId,
  required ValueChanged<int?> onCustomerChanged,
  required TextEditingController customerRefNoController,
  required TextEditingController customerRefDateController,
  required TextEditingController notesController,
  required TextEditingController termsController,
}) {
  return <Widget>[
    AppDropdownField<int>.fromMapped(
      labelText: 'Customer',
      doctypeLabel: 'Customer',
      allowCreate: true,
      onNavigateToCreateNew: (name) {
        final uri = Uri(
          path: '/parties',
          queryParameters: {
            'new': '1',
            'party_context': 'customer',
            if (name.trim().isNotEmpty) 'party_name': name.trim(),
          },
        );
        openModuleShellRoute(context, uri.toString());
      },
      mappedItems: customerItems,
      initialValue: customerPartyId,
      onChanged: onCustomerChanged,
      validator: Validators.requiredSelection('Customer'),
    ),
    AppFormTextField(
      labelText: 'Customer PO / Ref',
      controller: customerRefNoController,
      enabled: canEdit,
      validator: Validators.optionalMaxLength(100, 'Reference'),
    ),
    AppFormTextField(
      labelText: 'Customer Ref Date',
      controller: customerRefDateController,
      keyboardType: TextInputType.datetime,
      inputFormatters: const [DateInputFormatter()],
      enabled: canEdit,
      validator: Validators.optionalDate('Customer Ref Date'),
    ),
    AppFormTextField(
      labelText: 'Notes (shown to customer)',
      controller: notesController,
      maxLines: 3,
      enabled: canEdit,
    ),
    AppFormTextField(
      labelText: 'Terms & Conditions',
      controller: termsController,
      maxLines: 3,
      enabled: canEdit,
    ),
  ];
}

class SalesDocumentLineSection extends StatelessWidget {
  const SalesDocumentLineSection({
    super.key,
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.children,
    this.footer,
  });

  final String title;
  final String addLabel;
  final VoidCallback? onAdd;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            AppActionButton(
              icon: Icons.add_outlined,
              label: addLabel,
              onPressed: onAdd,
              filled: false,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        ...children,
        if (footer != null) ...[
          const SizedBox(height: AppUiConstants.spacingMd),
          footer!,
        ],
      ],
    );
  }
}

class SalesDocumentActionRow extends StatelessWidget {
  const SalesDocumentActionRow({super.key, required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppUiConstants.spacingSm,
      runSpacing: AppUiConstants.spacingSm,
      children: actions,
    );
  }
}

TaxCodeModel? salesTaxCodeById(List<TaxCodeModel> taxCodes, int? taxCodeId) {
  if (taxCodeId == null) {
    return null;
  }
  return taxCodes.cast<TaxCodeModel?>().firstWhere(
    (taxCode) => taxCode?.id == taxCodeId,
    orElse: () => null,
  );
}

class SalesLineTaxBreakdown {
  const SalesLineTaxBreakdown({
    required this.gross,
    required this.taxable,
    required this.taxPercent,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.total,
  });

  final double gross;
  final double taxable;
  final double taxPercent;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double total;
}

class SalesDocumentTaxSummary {
  const SalesDocumentTaxSummary({
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.total,
  });

  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double total;
}

SalesLineTaxBreakdown computeSalesLineTaxBreakdown({
  required double qty,
  required double rate,
  required double discountPercent,
  required TaxCodeModel? taxCode,
  bool? isInterState,
  double? taxPercent,
  String? taxType,
}) {
  final gross = roundToDouble(qty > 0 && rate >= 0 ? qty * rate : 0.0, 2);
  final clampedDiscount = discountPercent.clamp(0, 100).toDouble();
  final discountAmount = roundToDouble((gross * clampedDiscount) / 100, 2);
  final taxable = roundToDouble(gross - discountAmount, 2);
  var resolvedTaxPercent = (taxPercent ?? taxCode?.taxRate ?? 0).toDouble();
  final resolvedTaxType =
      (taxType ??
              taxCode?.taxType ??
              taxCode?.toJson()['tax_application']?.toString() ??
              '')
          .trim()
          .toLowerCase();
  final cessRate = (taxCode?.cessRate ?? 0).toDouble();
  final useIgst = isInterState ?? resolvedTaxType.contains('igst');

  var cgst = 0.0;
  var sgst = 0.0;
  var igst = 0.0;

  switch (resolvedTaxType) {
    case 'cess_only':
    case 'exempt':
    case 'nil_rated':
    case 'non_gst':
      resolvedTaxPercent = 0.0;
      break;
    default:
      if (useIgst) {
        igst = roundToDouble((taxable * resolvedTaxPercent) / 100, 2);
      } else {
        cgst = roundToDouble((taxable * resolvedTaxPercent) / 200, 2);
        sgst = roundToDouble((taxable * resolvedTaxPercent) / 200, 2);
      }
      break;
  }

  final cess = roundToDouble((taxable * cessRate) / 100, 2);

  return SalesLineTaxBreakdown(
    gross: gross,
    taxable: taxable,
    taxPercent: resolvedTaxPercent,
    cgst: cgst,
    sgst: sgst,
    igst: igst,
    cess: cess,
    total: roundToDouble(taxable + cgst + sgst + igst + cess, 2),
  );
}

SalesDocumentTaxSummary summarizeSalesLineTaxes(
  Iterable<SalesLineTaxBreakdown> lines, {
  double adjustment = 0,
}) {
  double taxable = 0;
  double cgst = 0;
  double sgst = 0;
  double igst = 0;
  double cess = 0;

  for (final line in lines) {
    taxable += line.taxable;
    cgst += line.cgst;
    sgst += line.sgst;
    igst += line.igst;
    cess += line.cess;
  }

  return SalesDocumentTaxSummary(
    taxable: taxable,
    cgst: cgst,
    sgst: sgst,
    igst: igst,
    cess: cess,
    total: taxable + cgst + sgst + igst + cess + adjustment,
  );
}
