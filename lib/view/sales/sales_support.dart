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
    defaultSalesUomIdForItem(item, uoms, conversions, current: currentUomId),
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

double roundToDouble(double value, int fractionDigits) {
  return double.parse(value.toStringAsFixed(fractionDigits));
}

List<Widget> buildSalesDocumentContextFields({
  required List<AppDropdownItem<int>> financialYearItems,
  required int? financialYearId,
  required ValueChanged<int?> onFinancialYearChanged,
  required List<AppDropdownItem<int>> documentSeriesItems,
  required int? documentSeriesId,
  required ValueChanged<int?> onDocumentSeriesChanged,
}) {
  return <Widget>[
    AppDropdownField<int>.fromMapped(
      labelText: 'Financial Year',
      mappedItems: financialYearItems,
      initialValue: financialYearId,
      onChanged: onFinancialYearChanged,
      validator: Validators.requiredSelection('Financial Year'),
    ),
    AppDropdownField<int>.fromMapped(
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
  required TextEditingController currencyCodeController,
  required TextEditingController exchangeRateController,
  required TextEditingController notesController,
  required TextEditingController termsController,
  ValueChanged<String>? onCurrencyChanged,
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
      labelText: 'Currency',
      controller: currencyCodeController,
      enabled: canEdit,
      onChanged: onCurrencyChanged,
      validator: Validators.optionalMaxLength(10, 'Currency'),
    ),
    AppFormTextField(
      labelText: 'Exchange Rate',
      controller: exchangeRateController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: canEdit,
      validator: Validators.optionalNonNegativeNumber('Exchange Rate'),
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
  final gross = qty > 0 && rate >= 0 ? qty * rate : 0.0;
  final clampedDiscount = discountPercent.clamp(0, 100).toDouble();
  final taxable = gross * (1 - (clampedDiscount / 100));
  final resolvedTaxPercent = (taxPercent ?? taxCode?.taxRate ?? 0).toDouble();
  final resolvedTaxType =
      (taxType ??
              taxCode?.taxType ??
              taxCode?.toJson()['tax_application']?.toString() ??
              '')
          .trim()
          .toLowerCase();
  final useIgst = isInterState ?? resolvedTaxType.contains('igst');
  final cessRate = (taxCode?.cessRate ?? 0).toDouble();

  final igst = useIgst ? taxable * resolvedTaxPercent / 100 : 0.0;
  final halfTax = useIgst ? 0.0 : taxable * resolvedTaxPercent / 200;
  final cgst = halfTax;
  final sgst = halfTax;
  final cess = taxable * cessRate / 100;

  return SalesLineTaxBreakdown(
    gross: gross,
    taxable: taxable,
    taxPercent: resolvedTaxPercent,
    cgst: cgst,
    sgst: sgst,
    igst: igst,
    cess: cess,
    total: taxable + cgst + sgst + igst + cess,
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
