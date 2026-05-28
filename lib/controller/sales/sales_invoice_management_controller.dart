import '../../screen.dart';

class SalesInvoiceManagementController extends GetxController {
  SalesInvoiceManagementController();

  static const List<AppDropdownItem<String>> listStatusFilter =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'partially_paid', label: 'Partially paid'),
        AppDropdownItem(value: 'paid', label: 'Paid'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final SalesService salesService = SalesService();
  final CrmService crmService = CrmService();
  final MasterService masterService = MasterService();
  final PartiesService partiesService = PartiesService();
  final AccountsService accountsService = AccountsService();
  final InventoryService inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController invoiceNoController = TextEditingController();
  final TextEditingController invoiceDateController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController customerRefNoController = TextEditingController();
  final TextEditingController customerRefDateController =
      TextEditingController();
  final TextEditingController currencyCodeController = TextEditingController();
  final TextEditingController exchangeRateController = TextEditingController();
  final TextEditingController adjustmentAmountController =
      TextEditingController();
  final TextEditingController adjustmentRemarksController =
      TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController termsController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  List<SalesInvoiceModel> items = const <SalesInvoiceModel>[];
  List<SalesInvoiceModel> filteredItems = const <SalesInvoiceModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> customers = const <PartyModel>[];
  final Map<int, PartyModel> customerDetailsById = <int, PartyModel>{};
  final Map<int, List<PartyGstDetailModel>> customerGstDetailsById =
      <int, List<PartyGstDetailModel>>{};
  List<AccountModel> accounts = const <AccountModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  List<ItemPriceModel> itemPrices = const <ItemPriceModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  List<SalesOrderModel> ordersAll = const <SalesOrderModel>[];
  List<SalesDeliveryModel> deliveriesAll = const <SalesDeliveryModel>[];
  List<Map<String, dynamic>>? orderLinesCache;
  List<Map<String, dynamic>>? deliveryLinesCache;
  final Map<int, Set<int>> allowedWarehouseIdsByItem = <int, Set<int>>{};
  final Set<int> warehouseOptionsLoadingItemIds = <int>{};
  final Map<String, List<Map<String, dynamic>>>
  availableBatchesByItemWarehouse = <String, List<Map<String, dynamic>>>{};
  final Set<String> batchOptionsLoadingKeys = <String>{};
  final Map<String, List<Map<String, dynamic>>>
  availableSerialsByItemWarehouse = <String, List<Map<String, dynamic>>>{};
  final Map<String, Map<String, Map<String, dynamic>>>
  availableSerialLookupByItemWarehouse =
      <String, Map<String, Map<String, dynamic>>>{};
  final Set<String> serialOptionsLoadingKeys = <String>{};
  int? salesOrderId;
  int? salesDeliveryId;
  SalesInvoiceModel? selectedItem;
  SalesInvoiceModel? pendingSelection;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? customerPartyId;
  int? billingAddressId;
  int? shippingAddressId;
  int? adjustmentAccountId;
  bool isActive = true;
  Map<String, dynamic>? salesChain;
  List<InvoiceLineDraft> lines = <InvoiceLineDraft>[];

  String errorMessage(Object error) {
    if (error is ApiException) {
      return error.displayMessage;
    }
    if (error is ApiResponse) {
      return error.message;
    }
    return error.toString();
  }

  bool get canEdit {
    if (selectedItem == null) {
      return true;
    }
    return selectedItem!.invoiceStatus == 'draft';
  }

  String get status => selectedItem?.invoiceStatus ?? 'draft';

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null || item.documentType == 'SALES_INVOICE';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  List<AccountModel> get accountOptions {
    final selectedCompanyId = companyId;
    if (selectedCompanyId == null) {
      return accounts;
    }
    return accounts
        .where((a) => a.companyId == null || a.companyId == selectedCompanyId)
        .toList(growable: false);
  }

  Map<String, dynamic> rowJson(SalesInvoiceModel row) => row.toJson();

  ItemModel? itemById(int? itemId) {
    if (itemId == null) {
      return null;
    }
    return itemsLookup.cast<ItemModel?>().firstWhere(
      (item) => item?.id == itemId,
      orElse: () => null,
    );
  }

  bool isSerialManagedItem(int? itemId) => itemById(itemId)?.hasSerial == true;

  bool isBatchManagedItem(int? itemId) => itemById(itemId)?.hasBatch == true;

  int? get currentDraftInvoiceId =>
      selectedItem != null && selectedItem!.invoiceStatus == 'draft'
      ? selectedItem!.id
      : null;

  List<String> lineSerialNumbers(InvoiceLineDraft line) {
    if (line.serialNumbers.isNotEmpty) {
      return List<String>.from(line.serialNumbers);
    }
    final serialNo = line.serialNoController.text.trim();
    return serialNo.isEmpty ? const <String>[] : <String>[serialNo];
  }

  void setLineSerialNumbers(InvoiceLineDraft line, List<String> values) {
    final normalized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    line.serialNumbers = List<String>.from(normalized);
    line.serialNoController.text = normalized.isEmpty ? '' : normalized.first;
    if (!isSerialManagedItem(line.itemId)) {
      return;
    }
    line.qtyController.text = normalized.length.toString();
    if (normalized.length == 1) {
      final matched = serialOptionByLabelForLine(line, normalized.first);
      line.serialId = matched == null
          ? null
          : int.tryParse(matched['serial_id']?.toString() ?? '');
      if (matched != null && line.batchId == null) {
        line.batchId = int.tryParse(matched['batch_id']?.toString() ?? '');
      }
    } else {
      line.serialId = null;
    }
  }

  void reconcileLineSerials(
    InvoiceLineDraft line,
    List<Map<String, dynamic>> serialOptions,
  ) {
    final allowedByLabel = <String, Map<String, dynamic>>{
      for (final serial in serialOptions)
        (serial['serial_no']?.toString().trim().toLowerCase() ?? ''): serial,
    }..remove('');

    final existing = lineSerialNumbers(line);
    final preserved = existing
        .where((serialNo) => allowedByLabel.containsKey(serialNo.toLowerCase()))
        .toList(growable: false);

    if (existing.isNotEmpty && preserved.isEmpty) {
      return;
    }

    line.serialNumbers = List<String>.from(preserved);
    line.serialNoController.text = preserved.isEmpty ? '' : preserved.first;

    if (preserved.length == 1) {
      final matched = allowedByLabel[preserved.first.toLowerCase()];
      line.serialId = matched == null
          ? null
          : int.tryParse(matched['serial_id']?.toString() ?? '');
      if (matched != null && line.batchId == null) {
        line.batchId = int.tryParse(matched['batch_id']?.toString() ?? '');
      }
    } else {
      line.serialId = null;
    }

    if (isSerialManagedItem(line.itemId)) {
      line.qtyController.text = preserved.length.toString();
    }
  }

  void replaceLineWithSerialDrafts(InvoiceLineDraft line, List<String> values) {
    final normalized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final lineIndex = lines.indexOf(line);
    if (lineIndex < 0) {
      setLineSerialNumbers(line, normalized);
      return;
    }

    final replacements = normalized
        .map((serialNo) {
          final matched = serialOptionByLabelForLine(line, serialNo);
          return InvoiceLineDraft(
            salesOrderLineId: line.salesOrderLineId,
            salesDeliveryLineId: line.salesDeliveryLineId,
            itemId: line.itemId,
            warehouseId: line.warehouseId,
            batchId: line.batchId,
            serialId: matched == null
                ? null
                : int.tryParse(matched['serial_id']?.toString() ?? ''),
            serialNumbers: <String>[serialNo],
            serialNo: serialNo,
            uomId: line.uomId,
            taxCodeId: line.taxCodeId,
            description: line.descriptionController.text,
            qty: '1',
            rate: line.rateController.text,
            discountPercent: line.discountController.text,
            remarks: line.remarksController.text,
          );
        })
        .toList(growable: false);

    final nextLines = List<InvoiceLineDraft>.from(lines);
    nextLines.removeAt(lineIndex);
    line.dispose();
    nextLines.insertAll(lineIndex, replacements);
    lines = nextLines;
  }

  List<InvoiceLineDraft> buildInvoiceDraftsFromLines(
    List<SalesInvoiceLineModel> lines,
  ) {
    return lines.map(InvoiceLineDraft.fromLine).toList(growable: false);
  }

  TaxCodeModel? taxCodeById(int? taxCodeId) {
    if (taxCodeId == null) {
      return null;
    }
    return taxCodes.cast<TaxCodeModel?>().firstWhere(
      (taxCode) => taxCode?.id == taxCodeId,
      orElse: () => null,
    );
  }

  PartyModel? customerListEntryById(int? partyId) {
    if (partyId == null) {
      return null;
    }
    return customers.cast<PartyModel?>().firstWhere(
      (party) => party?.id == partyId,
      orElse: () => null,
    );
  }

  PartyModel? customerForTaxContext(int? partyId) {
    if (partyId == null) {
      return null;
    }
    return customerDetailsById[partyId] ?? customerListEntryById(partyId);
  }

  String? normalizeStateCode(String? code) {
    final trimmed = (code ?? '').trim().toUpperCase();
    if (trimmed.isEmpty) {
      return null;
    }
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return trimmed.padLeft(2, '0');
    }
    return trimmed;
  }

  String? gstStateFromGstin(String? gstin) {
    final normalized = (gstin ?? '').trim().toUpperCase();
    if (normalized.length < 2) {
      return null;
    }
    final prefix = normalized.substring(0, 2);
    return RegExp(r'^\d{2}$').hasMatch(prefix) ? prefix : null;
  }

  String? resolveCompanyStateCodeForSummary() {
    final location = locations.cast<BusinessLocationModel?>().firstWhere(
      (entry) => entry?.id == locationId,
      orElse: () => null,
    );
    final fromLocation = normalizeStateCode(location?.stateCode);
    if (fromLocation != null) {
      return fromLocation;
    }

    final company = companies.cast<CompanyModel?>().firstWhere(
      (entry) => entry?.id == companyId,
      orElse: () => null,
    );
    final fromCompany = normalizeStateCode(company?.stateCode);
    if (fromCompany != null) {
      return fromCompany;
    }

    return gstStateFromGstin(company?.gstin);
  }

  PartyAddressModel? preferredCustomerAddress(PartyModel? customer) {
    return preferredPartyAddress(
      customer,
      shippingAddressId: shippingAddressId,
      billingAddressId: billingAddressId,
    );
  }

  String? resolveCustomerStateCodeForSummary() {
    final customer = customerForTaxContext(customerPartyId);
    final preferredAddress = preferredCustomerAddress(customer);
    final fromAddress = normalizeStateCode(preferredAddress?.stateCode);
    if (fromAddress != null) {
      return fromAddress;
    }

    final partyId = customerPartyId;
    if (partyId != null) {
      final gstDetails =
          customerGstDetailsById[partyId] ?? const <PartyGstDetailModel>[];
      final activeDetails = gstDetails
          .where((detail) {
            final data = detail.toJson();
            return data['is_active'] != false && data['is_active'] != 0;
          })
          .toList(growable: false);
      if (activeDetails.isNotEmpty) {
        final preferred = activeDetails.firstWhere((detail) {
          final data = detail.toJson();
          return data['is_default'] == true || data['is_default'] == 1;
        }, orElse: () => activeDetails.first);
        final data = preferred.toJson();
        final fromStateCode = normalizeStateCode(
          data['state_code']?.toString(),
        );
        if (fromStateCode != null) {
          return fromStateCode;
        }
        final fromGstin = gstStateFromGstin(data['gstin']?.toString());
        if (fromGstin != null) {
          return fromGstin;
        }
      }
    }

    return null;
  }

  String resolveCustomerPrintGstin(Map<String, dynamic> customerData) {
    return resolvePreferredPartyGstin(
      customerGstDetailsById[customerPartyId] ??
          const <PartyGstDetailModel>[],
      sourceData: customerData,
      fallback: stringValue(customerData, 'gstin'),
    );
  }

  bool? isInterStateForSummary() {
    final companyState = resolveCompanyStateCodeForSummary();
    final customerState = resolveCustomerStateCodeForSummary();
    if (companyState == null || customerState == null) {
      return null;
    }
    return companyState != customerState;
  }

  Future<void> ensureCustomerTaxContext(int? partyId) async {
    if (partyId == null) {
      return;
    }
    try {
      final responses = await Future.wait<dynamic>([
        partiesService.party(partyId),
        partiesService.partyAddresses(
          partyId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
        partiesService.partyContacts(
          partyId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
        partiesService.partyGstDetails(
          partyId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
      ]);
      if (!mounted) {
        return;
      }
      State(() {
        final party = (responses[0] as ApiResponse<PartyModel>).data;
        if (party != null) {
          customerDetailsById[partyId] = party.copyWith(
            addresses:
                (responses[1] as PaginatedResponse<PartyAddressModel>).data ??
                party.addresses,
            contacts:
                (responses[2] as PaginatedResponse<PartyContactModel>).data ??
                party.contacts,
          );
        }
        customerGstDetailsById[partyId] =
            (responses[3] as PaginatedResponse<PartyGstDetailModel>).data ??
            const <PartyGstDetailModel>[];
      });
    } catch (_) {}
  }

  String serialCacheKey(int? itemId, int? warehouseId, [int? batchId]) =>
      '${itemId ?? 0}:${warehouseId ?? 0}:${batchId ?? 0}:${currentDraftInvoiceId ?? 0}';

  String batchCacheKey(int? itemId, int? warehouseId) =>
      '${itemId ?? 0}:${warehouseId ?? 0}:${companyId ?? 0}';

  List<WarehouseModel> warehouseOptionsForLine(InvoiceLineDraft line) {
    final itemId = line.itemId;
    if (itemId == null) {
      return warehouses;
    }
    final allowedWarehouseIds = allowedWarehouseIdsByItem[itemId];
    if (allowedWarehouseIds == null) {
      return warehouses;
    }
    return warehouses
        .where((warehouse) => warehouse.id != null)
        .where(
          (warehouse) =>
              allowedWarehouseIds.contains(warehouse.id) ||
              warehouse.id == line.warehouseId,
        )
        .toList(growable: false);
  }

  bool applyAllowedWarehousesToLine(
    InvoiceLineDraft line,
    Set<int> allowedWarehouseIds,
  ) {
    if (lineSerialNumbers(line).isNotEmpty || line.serialId != null) {
      return false;
    }
    if (line.warehouseId != null &&
        !allowedWarehouseIds.contains(line.warehouseId)) {
      line.warehouseId = allowedWarehouseIds.length == 1
          ? allowedWarehouseIds.first
          : null;
      line.serialId = null;
      return true;
    }
    return false;
  }

  Future<void> syncWarehouseOptionsForLine(InvoiceLineDraft line) async {
    final itemId = line.itemId;
    if (itemId == null) {
      return;
    }
    final cachedWarehouseIds = allowedWarehouseIdsByItem[itemId];
    if (cachedWarehouseIds != null) {
      if (!mounted) {
        return;
      }
      if (applyAllowedWarehousesToLine(line, cachedWarehouseIds)) {
        State(() {});
      }
      return;
    }
    if (warehouseOptionsLoadingItemIds.contains(itemId)) {
      return;
    }
    warehouseOptionsLoadingItemIds.add(itemId);
    try {
      final raw = isSerialManagedItem(itemId)
          ? (await inventoryService.inquiryAvailableSerials(
              itemId: itemId,
              salesInvoiceId: currentDraftInvoiceId,
            )).data
          : (await inventoryService.inquiryWarehouseWiseStock(
              itemId: itemId,
              companyId: companyId,
            )).data;
      final rows = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e))
          : const Iterable<Map<String, dynamic>>.empty();
      final allowedWarehouseIds = rows
          .where((row) {
            if (isSerialManagedItem(itemId)) {
              return true;
            }
            final qty =
                double.tryParse(row['qty_available']?.toString() ?? '') ?? 0;
            return qty > 0;
          })
          .map((row) => int.tryParse(row['warehouse_id']?.toString() ?? ''))
          .whereType<int>()
          .toSet();
      if (!mounted) {
        return;
      }
      applyAllowedWarehousesToLine(line, allowedWarehouseIds);
      State(() {
        allowedWarehouseIdsByItem[itemId] = allowedWarehouseIds;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      State(() => allowedWarehouseIdsByItem[itemId] = <int>{});
    } finally {
      warehouseOptionsLoadingItemIds.remove(itemId);
    }
  }

  void syncWarehouseOptionsForLines(Iterable<InvoiceLineDraft> lines) {
    for (final line in lines) {
      unawaited(syncWarehouseOptionsForLine(line));
    }
  }

  List<Map<String, dynamic>> batchOptionsForLine(InvoiceLineDraft line) {
    if (!isBatchManagedItem(line.itemId) ||
        line.itemId == null ||
        line.warehouseId == null) {
      return const <Map<String, dynamic>>[];
    }
    final batches =
        availableBatchesByItemWarehouse[batchCacheKey(
          line.itemId,
          line.warehouseId,
        )] ??
        const <Map<String, dynamic>>[];
    final selectedBatchId = line.batchId;
    if (selectedBatchId == null ||
        batches.any(
          (batch) =>
              int.tryParse(batch['batch_id']?.toString() ?? '') ==
              selectedBatchId,
        )) {
      return batches;
    }
    return <Map<String, dynamic>>[
      ...batches,
      <String, dynamic>{
        'batch_id': selectedBatchId,
        'batch_no': (line.batchNo ?? '').trim().isNotEmpty
            ? line.batchNo!.trim()
            : 'Saved batch',
      },
    ];
  }

  Future<void> syncBatchOptionsForLine(InvoiceLineDraft line) async {
    final itemId = line.itemId;
    final warehouseId = line.warehouseId;
    if (itemId == null || warehouseId == null || !isBatchManagedItem(itemId)) {
      return;
    }
    final cacheKey = batchCacheKey(itemId, warehouseId);
    final cachedBatches = availableBatchesByItemWarehouse[cacheKey];
    if (cachedBatches != null) {
      if (!mounted) {
        return;
      }
      final hasSelectedBatch = cachedBatches.any(
        (batch) =>
            int.tryParse(batch['batch_id']?.toString() ?? '') == line.batchId,
      );
      if (line.batchId == null && cachedBatches.length == 1) {
        State(() {
          line.batchId = int.tryParse(
            cachedBatches.first['batch_id']?.toString() ?? '',
          );
          line.batchNo = cachedBatches.first['batch_no']?.toString();
        });
      } else if (line.batchId != null &&
          hasSelectedBatch &&
          line.batchNo == null) {
        final selectedBatch = cachedBatches.firstWhere(
          (batch) =>
              int.tryParse(batch['batch_id']?.toString() ?? '') == line.batchId,
        );
        line.batchNo = selectedBatch['batch_no']?.toString();
      }
      return;
    }
    if (batchOptionsLoadingKeys.contains(cacheKey)) {
      return;
    }
    batchOptionsLoadingKeys.add(cacheKey);
    try {
      final response = await inventoryService.inquiryBatchWiseStock(
        itemId: itemId,
        warehouseId: warehouseId,
        companyId: companyId,
      );
      final raw = response.data;
      final batches = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .where((batch) {
                  final qty =
                      double.tryParse(batch['balance_qty']?.toString() ?? '') ??
                      0;
                  return qty > 0;
                })
                .toList(growable: false)
          : const <Map<String, dynamic>>[];
      if (!mounted) {
        return;
      }
      State(() {
        availableBatchesByItemWarehouse[cacheKey] = batches;
        final hasSelectedBatch = batches.any(
          (batch) =>
              int.tryParse(batch['batch_id']?.toString() ?? '') == line.batchId,
        );
        if (line.itemId == itemId &&
            line.warehouseId == warehouseId &&
            line.batchId == null &&
            batches.length == 1) {
          line.batchId = int.tryParse(
            batches.first['batch_id']?.toString() ?? '',
          );
          line.batchNo = batches.first['batch_no']?.toString();
        } else if (line.itemId == itemId &&
            line.warehouseId == warehouseId &&
            line.batchId != null &&
            hasSelectedBatch &&
            line.batchNo == null) {
          final selectedBatch = batches.firstWhere(
            (batch) =>
                int.tryParse(batch['batch_id']?.toString() ?? '') ==
                line.batchId,
          );
          line.batchNo = selectedBatch['batch_no']?.toString();
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      State(() {
        availableBatchesByItemWarehouse[cacheKey] =
            const <Map<String, dynamic>>[];
      });
    } finally {
      batchOptionsLoadingKeys.remove(cacheKey);
    }
  }

  void syncBatchOptionsForLines(Iterable<InvoiceLineDraft> lines) {
    for (final line in lines) {
      unawaited(syncBatchOptionsForLine(line));
    }
  }

  List<Map<String, dynamic>> serialOptionsForLine(InvoiceLineDraft line) {
    if (!isSerialManagedItem(line.itemId) ||
        line.itemId == null ||
        line.warehouseId == null) {
      return const <Map<String, dynamic>>[];
    }
    return availableSerialsByItemWarehouse[serialCacheKey(
          line.itemId,
          line.warehouseId,
          line.batchId,
        )] ??
        const <Map<String, dynamic>>[];
  }

  Map<String, Map<String, dynamic>> serialLookupForLine(InvoiceLineDraft line) {
    if (!isSerialManagedItem(line.itemId) ||
        line.itemId == null ||
        line.warehouseId == null) {
      return const <String, Map<String, dynamic>>{};
    }
    final cacheKey = serialCacheKey(
      line.itemId,
      line.warehouseId,
      line.batchId,
    );
    final existing = availableSerialLookupByItemWarehouse[cacheKey];
    if (existing != null) {
      return existing;
    }
    final serials = availableSerialsByItemWarehouse[cacheKey];
    if (serials == null) {
      return const <String, Map<String, dynamic>>{};
    }
    final built = <String, Map<String, dynamic>>{
      for (final serial in serials)
        (serial['serial_no']?.toString().trim().toLowerCase() ?? ''): serial,
    }..remove('');
    availableSerialLookupByItemWarehouse[cacheKey] = built;
    return built;
  }

  Set<String> serialLabelSetForLine(InvoiceLineDraft line) =>
      serialLookupForLine(line).keys.toSet();

  Map<String, dynamic>? serialOptionByLabelForLine(
    InvoiceLineDraft line,
    String serialNo,
  ) => serialLookupForLine(line)[serialNo.trim().toLowerCase()];

  Future<void> syncSerialOptionsForLine(InvoiceLineDraft line) async {
    final itemId = line.itemId;
    final warehouseId = line.warehouseId;
    if (itemId == null || warehouseId == null || !isSerialManagedItem(itemId)) {
      return;
    }
    final cacheKey = serialCacheKey(itemId, warehouseId, line.batchId);
    final cachedSerials = availableSerialsByItemWarehouse[cacheKey];
    if (cachedSerials != null) {
      if (!mounted) {
        return;
      }
      final hasSelectedSerial = cachedSerials.any(
        (serial) =>
            int.tryParse(serial['serial_id']?.toString() ?? '') ==
            line.serialId,
      );
      if (line.serialId == null &&
          cachedSerials.length == 1 &&
          lineSerialNumbers(line).isEmpty) {
        State(() {
          line.serialId = int.tryParse(
            cachedSerials.first['serial_id']?.toString() ?? '',
          );
          if (lineSerialNumbers(line).isEmpty) {
            line.serialNoController.text =
                cachedSerials.first['serial_no']?.toString() ?? '';
          }
        });
      }
      return;
    }
    if (serialOptionsLoadingKeys.contains(cacheKey)) {
      return;
    }
    serialOptionsLoadingKeys.add(cacheKey);
    try {
      final response = await inventoryService.inquiryAvailableSerials(
        itemId: itemId,
        warehouseId: warehouseId,
        batchId: line.batchId,
        salesInvoiceId: currentDraftInvoiceId,
      );
      final raw = response.data;
      final serials = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : const <Map<String, dynamic>>[];
      if (!mounted) {
        return;
      }
      State(() {
        availableSerialsByItemWarehouse[cacheKey] = serials;
        availableSerialLookupByItemWarehouse[cacheKey] = {
          for (final serial in serials)
            (serial['serial_no']?.toString().trim().toLowerCase() ?? ''):
                serial,
        }..remove('');
        reconcileLineSerials(line, serials);
        final hasSelectedSerial = serials.any(
          (serial) =>
              int.tryParse(serial['serial_id']?.toString() ?? '') ==
              line.serialId,
        );
        if (line.itemId == itemId &&
            line.warehouseId == warehouseId &&
            line.serialId == null &&
            serials.length == 1 &&
            lineSerialNumbers(line).isEmpty) {
          line.serialId = int.tryParse(
            serials.first['serial_id']?.toString() ?? '',
          );
          if (lineSerialNumbers(line).isEmpty) {
            line.serialNoController.text =
                serials.first['serial_no']?.toString() ?? '';
          }
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      State(() {
        availableSerialsByItemWarehouse[cacheKey] =
            const <Map<String, dynamic>>[];
        availableSerialLookupByItemWarehouse[cacheKey] =
            const <String, Map<String, dynamic>>{};
      });
    } finally {
      serialOptionsLoadingKeys.remove(cacheKey);
    }
  }

  void syncSerialOptionsForLines(Iterable<InvoiceLineDraft> lines) {
    for (final line in lines) {
      unawaited(syncSerialOptionsForLine(line));
    }
  }

  void syncInventoryOptionsForLines(Iterable<InvoiceLineDraft> lines) {
    syncWarehouseOptionsForLines(lines);
    syncBatchOptionsForLines(lines);
    syncSerialOptionsForLines(lines);
  }

  Future<void> refreshSerialAvailabilityForSave() async {
    final serialManagedLines = lines
        .where((line) => isSerialManagedItem(line.itemId))
        .where((line) => line.itemId != null && line.warehouseId != null)
        .toList(growable: false);

    if (serialManagedLines.isEmpty) {
      return;
    }

    await Future.wait(serialManagedLines.map(syncSerialOptionsForLine));
  }

  List<SalesOrderModel> get orderChoices {
    final selectedCompanyId = companyId;
    final cust = customerPartyId;
    return ordersAll
        .where((o) {
          final j = o.toJson();
          if (selectedCompanyId != null &&
              intValue(j, 'company_id') != selectedCompanyId) {
            return false;
          }
          if (cust != null && intValue(j, 'customer_party_id') != cust) {
            return false;
          }
          final st = stringValue(j, 'order_status');
          return const {
            'confirmed',
            'partially_delivered',
            'fully_delivered',
            'partially_invoiced',
          }.contains(st);
        })
        .toList(growable: false);
  }

  List<SalesDeliveryModel> get deliveryChoices {
    final selectedCompanyId = companyId;
    final cust = customerPartyId;
    final orderId = salesOrderId;
    return deliveriesAll
        .where((d) {
          final j = d.toJson();
          if (selectedCompanyId != null &&
              intValue(j, 'company_id') != selectedCompanyId) {
            return false;
          }
          if (cust != null && intValue(j, 'customer_party_id') != cust) {
            return false;
          }
          final st = stringValue(j, 'delivery_status');
          if (!const {'posted', 'partially_invoiced'}.contains(st)) {
            return false;
          }
          if (orderId != null) {
            final dSo = intValue(j, 'sales_order_id');
            if (dSo != null && dSo != 0 && dSo != orderId) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  Map<String, dynamic>? deliveryJsonById(int? id) {
    if (id == null) {
      return null;
    }
    for (final d in deliveriesAll) {
      final j = d.toJson();
      if (intValue(j, 'id') == id) {
        return j;
      }
    }
    return null;
  }

  String orderLinePickerLabel(Map<String, dynamic> line) {
    final itemId = intValue(line, 'item_id');
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (i) => i?.id == itemId,
      orElse: () => null,
    );
    final ordered = double.tryParse(line['ordered_qty']?.toString() ?? '') ?? 0;
    final invoiced =
        double.tryParse(line['invoiced_qty']?.toString() ?? '') ?? 0;
    final rem = ordered - invoiced;
    final lineNo = intValue(line, 'line_no') ?? 0;
    final name = (item?.itemName ?? '').trim().isNotEmpty
        ? item!.itemName
        : 'Item $itemId';
    return 'L$lineNo · $name · rem $rem';
  }

  String deliveryLinePickerLabel(Map<String, dynamic> line) {
    final itemId = intValue(line, 'item_id');
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (i) => i?.id == itemId,
      orElse: () => null,
    );
    final pend =
        double.tryParse(line['pending_invoice_qty']?.toString() ?? '') ?? 0;
    final lineNo = intValue(line, 'line_no') ?? 0;
    final name = (item?.itemName ?? '').trim().isNotEmpty
        ? item!.itemName
        : 'Item $itemId';
    return 'L$lineNo · $name · pending $pend';
  }

  Future<void> reloadSourceDocumentsForCompany(int? companyId) async {
    if (companyId == null) {
      if (!mounted) {
        return;
      }
      State(() {
        ordersAll = const <SalesOrderModel>[];
        deliveriesAll = const <SalesDeliveryModel>[];
      });
      await refreshSalesChain();
      return;
    }
    try {
      final src = await Future.wait<dynamic>([
        salesService.ordersAll(
          filters: <String, dynamic>{
            'company_id': companyId,
            'is_active': 1,
            'sort_by': 'order_date',
          },
        ),
        salesService.deliveriesAll(
          filters: <String, dynamic>{
            'company_id': companyId,
            'is_active': 1,
            'sort_by': 'delivery_date',
          },
        ),
      ]);
      if (!mounted) {
        return;
      }
      State(() {
        ordersAll =
            (src[0] as ApiResponse<List<SalesOrderModel>>).data ??
            const <SalesOrderModel>[];
        deliveriesAll =
            (src[1] as ApiResponse<List<SalesDeliveryModel>>).data ??
            const <SalesDeliveryModel>[];
      });
      await refreshSalesChain();
    } catch (_) {}
  }

  int? invoiceDocumentSeriesIdFrom(Map<String, dynamic> j) {
    final sid = intValue(j, 'document_series_id');
    if (sid != 0) {
      return sid;
    }
    final opts = seriesOptions();
    return opts.isNotEmpty ? opts.first.id : null;
  }

  void applyInvoiceHeaderFromOrderJson(Map<String, dynamic> j) {
    companyId = intValue(j, 'company_id');
    branchId = intValue(j, 'branch_id');
    locationId = intValue(j, 'location_id');
    financialYearId = intValue(j, 'financial_year_id');
    documentSeriesId = invoiceDocumentSeriesIdFrom(j);
    final cust = intValue(j, 'customer_party_id');
    customerPartyId = cust == 0 ? null : cust;
    final rawBillingAddressId = intValue(j, 'billing_address_id');
    billingAddressId = rawBillingAddressId == null || rawBillingAddressId == 0
        ? null
        : rawBillingAddressId;
    final rawShippingAddressId = intValue(j, 'shipping_address_id');
    shippingAddressId =
        rawShippingAddressId == null || rawShippingAddressId == 0
        ? null
        : rawShippingAddressId;
    currencyCodeController.text = stringValue(j, 'currency_code', 'INR');
    exchangeRateController.text = stringValue(j, 'exchange_rate', '1');
    customerRefNoController.text = stringValue(j, 'customer_reference_no');
    customerRefDateController.text = displayDate(
      nullableStringValue(j, 'customer_reference_date'),
    );
    notesController.text = stringValue(j, 'notes');
    termsController.text = stringValue(j, 'terms_conditions');
    dueDateController.text = displayDate(
      nullableStringValue(j, 'expected_delivery_date'),
    );
    adjustmentAmountController.clear();
    adjustmentRemarksController.clear();
    adjustmentAccountId = null;
  }

  void applyInvoiceHeaderFromQuotationJson(Map<String, dynamic> j) {
    companyId = intValue(j, 'company_id');
    branchId = intValue(j, 'branch_id');
    locationId = intValue(j, 'location_id');
    financialYearId = intValue(j, 'financial_year_id');
    documentSeriesId = invoiceDocumentSeriesIdFrom(j);
    final cust = intValue(j, 'customer_party_id');
    customerPartyId = cust == 0 ? null : cust;
    final rawBillingAddressId = intValue(j, 'billing_address_id');
    billingAddressId = rawBillingAddressId == null || rawBillingAddressId == 0
        ? null
        : rawBillingAddressId;
    final rawShippingAddressId = intValue(j, 'shipping_address_id');
    shippingAddressId =
        rawShippingAddressId == null || rawShippingAddressId == 0
        ? null
        : rawShippingAddressId;
    currencyCodeController.text = stringValue(j, 'currency_code', 'INR');
    exchangeRateController.text = stringValue(j, 'exchange_rate', '1');
    customerRefNoController.text = stringValue(j, 'customer_reference_no');
    customerRefDateController.text = displayDate(
      nullableStringValue(j, 'customer_reference_date'),
    );
    notesController.text = stringValue(j, 'notes');
    termsController.text = stringValue(j, 'terms_conditions');
    dueDateController.text = displayDate(nullableStringValue(j, 'valid_until'));
    final adj = double.tryParse(j['adjustment_amount']?.toString() ?? '') ?? 0;
    adjustmentAmountController.text = adj == 0 ? '' : adj.toString();
    final adjAcc = intValue(j, 'adjustment_account_id');
    adjustmentAccountId = adjAcc == 0 ? null : adjAcc;
    adjustmentRemarksController.text = stringValue(j, 'adjustment_remarks');
  }

  void applyInvoiceHeaderFromDeliveryJson(Map<String, dynamic> j) {
    companyId = intValue(j, 'company_id');
    branchId = intValue(j, 'branch_id');
    locationId = intValue(j, 'location_id');
    financialYearId = intValue(j, 'financial_year_id');
    documentSeriesId = invoiceDocumentSeriesIdFrom(j);
    final cust = intValue(j, 'customer_party_id');
    customerPartyId = cust == 0 ? null : cust;
    final rawBillingAddressId = intValue(j, 'billing_address_id');
    billingAddressId = rawBillingAddressId == null || rawBillingAddressId == 0
        ? null
        : rawBillingAddressId;
    final rawShippingAddressId = intValue(j, 'shipping_address_id');
    shippingAddressId =
        rawShippingAddressId == null || rawShippingAddressId == 0
        ? null
        : rawShippingAddressId;
    notesController.text = stringValue(j, 'notes');
  }

  Future<Map<String, dynamic>?> fetchOrderDetail(int orderId) async {
    try {
      final r = await salesService.order(orderId);
      final j = r.data?.toJson() ?? <String, dynamic>{};
      final rawLines = j['lines'] as List<dynamic>?;
      final list = rawLines
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) {
        return null;
      }
      State(() {
        orderLinesCache = list ?? const <Map<String, dynamic>>[];
      });
      return j;
    } catch (_) {
      if (mounted) {
        State(() => orderLinesCache = const <Map<String, dynamic>>[]);
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchDeliveryDetail(int deliveryId) async {
    try {
      final r = await salesService.delivery(deliveryId);
      final j = r.data?.toJson() ?? <String, dynamic>{};
      final rawLines = j['lines'] as List<dynamic>?;
      final list = rawLines
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) {
        return null;
      }
      State(() {
        deliveryLinesCache = list ?? const <Map<String, dynamic>>[];
      });
      return j;
    } catch (_) {
      if (mounted) {
        State(() => deliveryLinesCache = const <Map<String, dynamic>>[]);
      }
      return null;
    }
  }

  int? orderIdForSalesChain() {
    if (salesOrderId != null) {
      return salesOrderId;
    }
    if (salesDeliveryId != null) {
      final dj = deliveryJsonById(salesDeliveryId);
      final o = intValue(dj ?? const <String, dynamic>{}, 'sales_order_id');
      if (o != null && o != 0) {
        return o;
      }
    }
    return null;
  }

  Future<void> refreshSalesChain({int? quotationId}) async {
    final iid = selectedItem?.id;
    final oid = orderIdForSalesChain();
    try {
      if (iid != null && iid != 0) {
        final r = await crmService.salesChain(invoiceId: iid);
        if (!mounted) {
          return;
        }
        State(() => salesChain = r.data);
        return;
      }
      if (oid != null) {
        final r = await crmService.salesChain(orderId: oid);
        if (!mounted) {
          return;
        }
        State(() => salesChain = r.data);
        return;
      }
      if (quotationId != null) {
        final r = await crmService.salesChain(quotationId: quotationId);
        if (!mounted) {
          return;
        }
        State(() => salesChain = r.data);
        return;
      }
      if (!mounted) {
        return;
      }
      State(() => salesChain = null);
    } catch (_) {
      if (!mounted) {
        return;
      }
      State(() => salesChain = null);
    }
  }

  Future<void> hydrateSourceCaches() async {
    if (salesOrderId != null) {
      await fetchOrderDetail(salesOrderId!);
    } else if (mounted) {
      State(() => orderLinesCache = null);
    }
    if (salesDeliveryId != null) {
      await fetchDeliveryDetail(salesDeliveryId!);
    } else if (mounted) {
      State(() => deliveryLinesCache = null);
    }
  }

  void pruneSourcesForCustomer() {
    final cust = customerPartyId;
    if (salesOrderId != null) {
      final ok = ordersAll.any((o) {
        final j = o.toJson();
        return intValue(j, 'id') == salesOrderId &&
            (cust == null || intValue(j, 'customer_party_id') == cust);
      });
      if (!ok) {
        salesOrderId = null;
        orderLinesCache = null;
        for (final line in lines) {
          line.salesOrderLineId = null;
        }
      }
    }
    if (salesDeliveryId != null) {
      final ok = deliveriesAll.any((d) {
        final j = d.toJson();
        return intValue(j, 'id') == salesDeliveryId &&
            (cust == null || intValue(j, 'customer_party_id') == cust);
      });
      if (!ok) {
        salesDeliveryId = null;
        deliveryLinesCache = null;
        for (final line in lines) {
          line.salesDeliveryLineId = null;
        }
      }
    }
  }

  Future<void> onHeaderSalesOrderChanged(int? value) async {
    if (!canEdit) {
      return;
    }
    State(() {
      salesOrderId = value;
      orderLinesCache = value == null ? null : const <Map<String, dynamic>>[];
      if (salesDeliveryId != null && value != null) {
        final dj = deliveryJsonById(salesDeliveryId);
        final dSo = intValue(dj ?? <String, dynamic>{}, 'sales_order_id');
        if (dSo != null && dSo != 0 && dSo != value) {
          salesDeliveryId = null;
          deliveryLinesCache = null;
        }
      }
    });
    if (value != null) {
      final orderJson = await fetchOrderDetail(value);
      if (!mounted || !canEdit) {
        await refreshSalesChain();
        return;
      }
      State(() {
        if (orderJson != null) {
          applyInvoiceHeaderFromOrderJson(orderJson);
        }
        applyAutoInvoiceLinesFromSources();
      });
      syncInventoryOptionsForLines(lines);
      unawaited(ensureCustomerTaxContext(customerPartyId));
      await reloadSourceDocumentsForCompany(companyId);
    } else {
      if (mounted) {
        State(() => orderLinesCache = null);
      }
      if (mounted && canEdit) {
        State(() {
          disposeAllInvoiceLineDrafts();
          lines = <InvoiceLineDraft>[InvoiceLineDraft()];
        });
      }
    }
    await refreshSalesChain();
  }

  Future<void> onHeaderSalesDeliveryChanged(int? value) async {
    if (!canEdit) {
      return;
    }
    State(() {
      salesDeliveryId = value;
      deliveryLinesCache = value == null
          ? null
          : const <Map<String, dynamic>>[];
    });
    if (value != null) {
      final dJson = await fetchDeliveryDetail(value);
      final dOrd = intValue(dJson ?? <String, dynamic>{}, 'sales_order_id');
      Map<String, dynamic>? orderJson;
      if (dOrd != null && dOrd != 0) {
        if (salesOrderId == null) {
          State(() => salesOrderId = dOrd);
        }
        orderJson = await fetchOrderDetail(dOrd);
      } else if (salesOrderId != null) {
        orderJson = await fetchOrderDetail(salesOrderId!);
      }
      if (!mounted || !canEdit) {
        await refreshSalesChain();
        return;
      }
      State(() {
        if (orderJson != null) {
          applyInvoiceHeaderFromOrderJson(orderJson);
        } else if (dJson != null) {
          applyInvoiceHeaderFromDeliveryJson(dJson);
          currencyCodeController.text = 'INR';
          exchangeRateController.text = '1';
          termsController.clear();
          customerRefNoController.clear();
          customerRefDateController.clear();
        }
        applyAutoInvoiceLinesFromSources();
      });
      syncInventoryOptionsForLines(lines);
      unawaited(ensureCustomerTaxContext(customerPartyId));
      await reloadSourceDocumentsForCompany(companyId);
    } else {
      if (mounted) {
        State(() => deliveryLinesCache = null);
      }
      if (mounted && canEdit && salesOrderId != null) {
        await fetchOrderDetail(salesOrderId!);
        if (!mounted) {
          await refreshSalesChain();
          return;
        }
        State(() {
          if (orderLinesCache != null && orderLinesCache!.isNotEmpty) {
            applyLinesFromOrderCache();
          } else {
            disposeAllInvoiceLineDrafts();
            lines = <InvoiceLineDraft>[InvoiceLineDraft()];
          }
        });
      } else if (mounted && canEdit) {
        State(() {
          disposeAllInvoiceLineDrafts();
          lines = <InvoiceLineDraft>[InvoiceLineDraft()];
        });
      }
    }
    await refreshSalesChain();
  }

  void applyOrderLinePick(InvoiceLineDraft line, int? orderLineId) {
    State(() {
      line.salesOrderLineId = orderLineId;
      line.salesDeliveryLineId = null;
      if (orderLineId == null) {
        return;
      }
      Map<String, dynamic>? ol;
      for (final m in orderLinesCache ?? const <Map<String, dynamic>>[]) {
        if (intValue(m, 'id') == orderLineId) {
          ol = m;
          break;
        }
      }
      if (ol == null) {
        return;
      }
      line.itemId = intValue(ol, 'item_id');
      line.uomId = intValue(ol, 'uom_id');
      line.warehouseId = intValue(ol, 'warehouse_id');
      line.batchId = InvoiceLineDraft.nullableIntKey(ol, 'batch_id');
      line.serialId = InvoiceLineDraft.nullableIntKey(ol, 'serial_id');
      line.rateController.text = stringValue(ol, 'rate');
      final ordered = double.tryParse(ol['ordered_qty']?.toString() ?? '') ?? 0;
      final invoiced =
          double.tryParse(ol['invoiced_qty']?.toString() ?? '') ?? 0;
      final rem = ordered - invoiced;
      final serialNo = stringValue(ol, 'serial_no').trim();
      if (isSerialManagedItem(line.itemId)) {
        setLineSerialNumbers(
          line,
          serialNo.isEmpty ? const <String>[] : <String>[serialNo],
        );
      } else if (rem > 0) {
        line.qtyController.text = rem.toString();
      }
    });
    unawaited(syncBatchOptionsForLine(line));
    unawaited(syncSerialOptionsForLine(line));
  }

  void applyDeliveryLinePick(InvoiceLineDraft line, int? deliveryLineId) {
    State(() {
      line.salesDeliveryLineId = deliveryLineId;
      if (deliveryLineId == null) {
        return;
      }
      Map<String, dynamic>? dl;
      for (final m in deliveryLinesCache ?? const <Map<String, dynamic>>[]) {
        if (intValue(m, 'id') == deliveryLineId) {
          dl = m;
          break;
        }
      }
      if (dl == null) {
        return;
      }
      final sol = intValue(dl, 'sales_order_line_id');
      line.salesOrderLineId = sol == 0 ? null : sol;
      line.itemId = intValue(dl, 'item_id');
      line.uomId = intValue(dl, 'uom_id');
      line.warehouseId = intValue(dl, 'warehouse_id');
      line.batchId = InvoiceLineDraft.nullableIntKey(dl, 'batch_id');
      line.serialId = InvoiceLineDraft.nullableIntKey(dl, 'serial_id');
      line.rateController.text = stringValue(dl, 'rate');
      final pend =
          double.tryParse(dl['pending_invoice_qty']?.toString() ?? '') ?? 0;
      final serialNo = stringValue(dl, 'serial_no').trim();
      if (isSerialManagedItem(line.itemId)) {
        setLineSerialNumbers(
          line,
          serialNo.isEmpty ? const <String>[] : <String>[serialNo],
        );
      } else if (pend > 0) {
        line.qtyController.text = pend.toString();
      }
    });
    unawaited(syncBatchOptionsForLine(line));
    unawaited(syncSerialOptionsForLine(line));
  }

  void disposeAllInvoiceLineDrafts() {
    for (final line in lines) {
      line.dispose();
    }
  }

  void applyLinesFromOrderCache() {
    final cache = orderLinesCache;
    if (cache == null || cache.isEmpty) {
      return;
    }
    final drafts = <InvoiceLineDraft>[];
    for (final ol in cache) {
      final ordered = double.tryParse(ol['ordered_qty']?.toString() ?? '') ?? 0;
      final invoiced =
          double.tryParse(ol['invoiced_qty']?.toString() ?? '') ?? 0;
      if (ordered - invoiced <= 0) {
        continue;
      }
      drafts.add(InvoiceLineDraft.fromOrderLineMap(ol));
    }
    disposeAllInvoiceLineDrafts();
    lines = drafts.isEmpty ? <InvoiceLineDraft>[InvoiceLineDraft()] : drafts;
  }

  void applyLinesFromDeliveryCache() {
    final cache = deliveryLinesCache;
    if (cache == null || cache.isEmpty) {
      return;
    }
    final drafts = <InvoiceLineDraft>[];
    for (final dl in cache) {
      final pend =
          double.tryParse(dl['pending_invoice_qty']?.toString() ?? '') ?? 0;
      if (pend <= 0) {
        continue;
      }
      int? taxId;
      final sol = intValue(dl, 'sales_order_line_id');
      if (sol != null && sol != 0) {
        for (final ol in orderLinesCache ?? const <Map<String, dynamic>>[]) {
          if (intValue(ol, 'id') == sol) {
            taxId = intValue(ol, 'tax_code_id');
            break;
          }
        }
      }
      drafts.add(InvoiceLineDraft.fromDeliveryLineMap(dl, taxCodeId: taxId));
    }
    disposeAllInvoiceLineDrafts();
    lines = drafts.isEmpty ? <InvoiceLineDraft>[InvoiceLineDraft()] : drafts;
  }

  void applyAutoInvoiceLinesFromSources() {
    if (!canEdit) {
      return;
    }
    if (salesDeliveryId != null &&
        (deliveryLinesCache != null && deliveryLinesCache!.isNotEmpty)) {
      applyLinesFromDeliveryCache();
    } else if (salesOrderId != null &&
        (orderLinesCache != null && orderLinesCache!.isNotEmpty)) {
      applyLinesFromOrderCache();
    }
  }

  double outstandingBalanceForSelectedInvoice() {
    if (selectedItem == null) {
      return 0;
    }
    final d = rowJson(selectedItem!);
    return double.tryParse(d['balance_amount']?.toString() ?? '') ?? 0;
  }

  bool hasInitialized = false;
  bool editorOnly = false;
  int? initialId;
  int? initialQuotationId;
  int? initialOrderId;

  bool get mounted => !isClosed;

  void State(VoidCallback fn) {
    if (isClosed) {
      return;
    }
    fn();
    update();
  }

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(handleWorkingContextChanged);
    searchController.addListener(applyFilters);
  }

  Future<void> initialize({
    int? initialId,
    int? initialQuotationId,
    int? initialOrderId,
    bool editorOnly = false,
  }) async {
    this.initialId = initialId;
    this.initialQuotationId = initialQuotationId;
    this.initialOrderId = initialOrderId;
    this.editorOnly = editorOnly;
    hasInitialized = true;
    await loadPage(selectId: initialId);
  }

  void handleWorkingContextChanged() {
    unawaited(loadPage(selectId: selectedItem?.id));
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(handleWorkingContextChanged);
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(applyFilters)
      ..dispose();
    invoiceNoController.dispose();
    invoiceDateController.dispose();
    dueDateController.dispose();
    customerRefNoController.dispose();
    customerRefDateController.dispose();
    currencyCodeController.dispose();
    exchangeRateController.dispose();
    adjustmentAmountController.dispose();
    adjustmentRemarksController.dispose();
    notesController.dispose();
    termsController.dispose();
    for (final line in lines) {
      line.dispose();
    }
    super.onClose();
  }

  Future<void> loadReferenceDataInBackground() async {
    try {
      final responses = await Future.wait<dynamic>([
        accountsService.accountsAll(filters: const {'sort_by': 'account_name'}),
        inventoryService.items(
          filters: const {'per_page': 400, 'sort_by': 'item_name'},
        ),
        inventoryService.itemPrices(
          filters: const {
            'per_page': 1000,
            'sort_by': 'valid_from',
            'sort_order': 'desc',
          },
        ),
        inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        inventoryService.uomConversionsAll(
          filters: const {'per_page': 500, 'sort_by': 'from_uom_id'},
        ),
        masterService.warehouses(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        inventoryService.taxCodes(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
      ]);

      if (!mounted) {
        return;
      }

      State(() {
        accounts =
            ((responses[0] as ApiResponse<List<AccountModel>>).data ??
                    const <AccountModel>[])
                .where((item) => item.isActive)
                .toList();
        itemsLookup =
            ((responses[1] as PaginatedResponse<ItemModel>).data ??
                    const <ItemModel>[])
                .where((item) => item.isActive)
                .toList();
        itemPrices =
            ((responses[2] as PaginatedResponse<ItemPriceModel>).data ??
                    const <ItemPriceModel>[])
                .where((price) => price.isActive)
                .toList();
        uoms =
            ((responses[3] as PaginatedResponse<UomModel>).data ??
                    const <UomModel>[])
                .where((item) => item.isActive)
                .toList();
        uomConversions =
            ((responses[4] as PaginatedResponse<UomConversionModel>).data ??
                    const <UomConversionModel>[])
                .where((item) => item.isActive)
                .toList();
        warehouses =
            ((responses[5] as PaginatedResponse<WarehouseModel>).data ??
                    const <WarehouseModel>[])
                .where((item) => item.isActive)
                .toList();
        taxCodes =
            ((responses[6] as PaginatedResponse<TaxCodeModel>).data ??
                    const <TaxCodeModel>[])
                .where((item) => item.isActive)
                .toList();
      });
    } catch (_) {}
  }

  Future<void> loadPage({int? selectId}) async {
    State(() {
      initialLoading = items.isEmpty;
      pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        salesService.invoices(
          filters: const {'per_page': 200, 'sort_by': 'invoice_date'},
        ),
        masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        masterService.branches(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        masterService.businessLocations(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        masterService.financialYears(
          filters: const {'per_page': 100, 'sort_by': 'fy_name'},
        ),
        masterService.documentSeries(
          filters: const {'per_page': 200, 'sort_by': 'series_name'},
        ),
        partiesService.partyTypes(filters: const {'per_page': 100}),
        partiesService.parties(
          filters: const {'per_page': 400, 'sort_by': 'party_name'},
        ),
      ]);

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies:
                ((responses[1] as PaginatedResponse<CompanyModel>).data ??
                        const <CompanyModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
            branches:
                ((responses[2] as PaginatedResponse<BranchModel>).data ??
                        const <BranchModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
            locations:
                ((responses[3] as PaginatedResponse<BusinessLocationModel>)
                            .data ??
                        const <BusinessLocationModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
            financialYears:
                ((responses[4] as PaginatedResponse<FinancialYearModel>).data ??
                        const <FinancialYearModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
          );

      if (!mounted) {
        return;
      }

      List<SalesOrderModel> ordersAll = const <SalesOrderModel>[];
      List<SalesDeliveryModel> deliveriesAll = const <SalesDeliveryModel>[];
      final sourceCompanyId = contextSelection.companyId;
      if (sourceCompanyId != null) {
        try {
          final src = await Future.wait<dynamic>([
            salesService.ordersAll(
              filters: <String, dynamic>{
                'company_id': sourceCompanyId,
                'is_active': 1,
                'sort_by': 'order_date',
              },
            ),
            salesService.deliveriesAll(
              filters: <String, dynamic>{
                'company_id': sourceCompanyId,
                'is_active': 1,
                'sort_by': 'delivery_date',
              },
            ),
          ]);
          ordersAll =
              (src[0] as ApiResponse<List<SalesOrderModel>>).data ??
              const <SalesOrderModel>[];
          deliveriesAll =
              (src[1] as ApiResponse<List<SalesDeliveryModel>>).data ??
              const <SalesDeliveryModel>[];
        } catch (_) {}
      }

      if (!mounted) {
        return;
      }

      State(() {
        items =
            (responses[0] as PaginatedResponse<SalesInvoiceModel>).data ??
            const <SalesInvoiceModel>[];
        final pending = pendingSelection;
        if (pending != null && pending.id != null) {
          final pendingId = pending.id!;
          final existingIndex = items.indexWhere(
            (item) => item.id == pendingId,
          );
          if (existingIndex >= 0) {
            final nextItems = List<SalesInvoiceModel>.from(items);
            nextItems[existingIndex] = pending;
            items = nextItems;
          } else {
            items = <SalesInvoiceModel>[pending, ...items];
          }
        }
        companies =
            (responses[1] as PaginatedResponse<CompanyModel>).data ??
            const <CompanyModel>[];
        locations =
            (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
            const <BusinessLocationModel>[];
        financialYears =
            (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
            const <FinancialYearModel>[];
        documentSeries =
            ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                    const <DocumentSeriesModel>[])
                .where((item) => item.isActive)
                .toList();
        customers = salesCustomersOrFallback(
          parties:
              ((responses[7] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[]),
          partyTypes:
              (responses[6] as PaginatedResponse<PartyTypeModel>).data ??
              const <PartyTypeModel>[],
        );
        contextCompanyId = contextSelection.companyId;
        contextBranchId = contextSelection.branchId;
        contextLocationId = contextSelection.locationId;
        contextFinancialYearId = contextSelection.financialYearId;
        ordersAll = ordersAll;
        deliveriesAll = deliveriesAll;
        initialLoading = false;
      });
      await loadReferenceDataInBackground();
      applyFilters();

      final selected = selectId != null
          ? items.cast<SalesInvoiceModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () {
                final pending = pendingSelection;
                if (pending?.id == selectId) {
                  return pending;
                }
                final current = selectedItem;
                if (current?.id == selectId) {
                  return current;
                }
                return null;
              },
            )
          : (editorOnly
                ? null
                : (selectedItem == null
                      ? (items.isNotEmpty ? items.first : null)
                      : null));

      if (selected != null) {
        pendingSelection = null;
        await selectDocument(selected);
      } else {
        resetForm();
        final orderPref = initialOrderId;
        if (orderPref != null && editorOnly) {
          await prefillNewInvoiceFromOrder(orderPref);
        } else {
          final qPref = initialQuotationId;
          if (qPref != null && editorOnly) {
            await prefillNewInvoiceFromQuotation(qPref);
          }
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      State(() {
        pageError = errorMessage(error);
        initialLoading = false;
      });
    }
  }

  Future<void> prefillNewInvoiceFromQuotation(int quotationId) async {
    try {
      final r = await salesService.quotation(quotationId);
      final q = r.data;
      if (q == null || !mounted) {
        return;
      }
      final data = q.toJson();
      final quotationLines =
          (data['lines'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(InvoiceLineDraft.fromQuotationLine)
              .toList(growable: true);
      for (final old in lines) {
        old.dispose();
      }
      if (!mounted) {
        return;
      }
      State(() {
        applyInvoiceHeaderFromQuotationJson(data);
        salesOrderId = null;
        salesDeliveryId = null;
        orderLinesCache = null;
        deliveryLinesCache = null;
        invoiceNoController.clear();
        invoiceDateController.text = DateTime.now()
            .toIso8601String()
            .split('T')
            .first;
        isActive = true;
        lines = quotationLines.isEmpty
            ? <InvoiceLineDraft>[InvoiceLineDraft()]
            : quotationLines;
        formError = null;
      });
      syncInventoryOptionsForLines(lines);
      unawaited(ensureCustomerTaxContext(customerPartyId));
      await reloadSourceDocumentsForCompany(companyId);
      await refreshSalesChain(quotationId: quotationId);
    } catch (e) {
      if (mounted) {
        State(() => formError = e.toString());
      }
    }
  }

  Future<void> prefillNewInvoiceFromOrder(int orderId) async {
    try {
      final orderJson = await fetchOrderDetail(orderId);
      if (orderJson == null || !mounted) {
        return;
      }
      State(() {
        salesOrderId = orderId;
        salesDeliveryId = null;
        deliveryLinesCache = null;
        applyInvoiceHeaderFromOrderJson(orderJson);
        invoiceNoController.clear();
        invoiceDateController.text = DateTime.now()
            .toIso8601String()
            .split('T')
            .first;
        isActive = true;
        applyLinesFromOrderCache();
        formError = null;
      });
      syncInventoryOptionsForLines(lines);
      unawaited(ensureCustomerTaxContext(customerPartyId));
      await reloadSourceDocumentsForCompany(companyId);
      await refreshSalesChain();
    } catch (e) {
      if (mounted) {
        State(() => formError = e.toString());
      }
    }
  }

  Future<void> selectDocument(SalesInvoiceModel item) async {
    final id = item.id;
    if (id == 0) {
      return;
    }
    final response = await salesService.invoice(id!);
    final full = response.data ?? item;
    final draftLines = buildInvoiceDraftsFromLines(full.lines);
    for (final old in lines) {
      old.dispose();
    }
    State(() {
      selectedItem = full;
      companyId = full.companyId;
      branchId = full.branchId;
      locationId = full.locationId;
      financialYearId = full.financialYearId;
      documentSeriesId = full.documentSeriesId;
      customerPartyId = full.customerPartyId;
      billingAddressId = full.billingAddressId;
      shippingAddressId = full.shippingAddressId;
      salesOrderId = full.salesOrderId;
      salesDeliveryId = full.salesDeliveryId;
      orderLinesCache = null;
      deliveryLinesCache = null;
      invoiceNoController.text = full.invoiceNo ?? '';
      invoiceDateController.text = displayDate(
        full.invoiceDate.isEmpty ? null : full.invoiceDate,
      );
      dueDateController.text = displayDate(full.dueDate);
      customerRefNoController.text = full.customerReferenceNo ?? '';
      customerRefDateController.text = displayDate(full.customerReferenceDate);
      currencyCodeController.text = full.currencyCode ?? 'INR';
      exchangeRateController.text = (full.exchangeRate ?? 1).toString();
      adjustmentAmountController.text =
          full.adjustmentAmount == null || full.adjustmentAmount == 0
          ? ''
          : full.adjustmentAmount.toString();
      adjustmentRemarksController.text = full.adjustmentRemarks ?? '';
      adjustmentAccountId = full.adjustmentAccountId;
      notesController.text = full.notes ?? '';
      termsController.text = full.termsConditions ?? '';
      isActive = full.isActive ?? true;
      lines = draftLines.isEmpty
          ? <InvoiceLineDraft>[InvoiceLineDraft()]
          : draftLines;
      formError = null;
    });
    syncInventoryOptionsForLines(lines);
    unawaited(ensureCustomerTaxContext(customerPartyId));
    await hydrateSourceCaches();
    if (!mounted) {
      return;
    }
    await reloadSourceDocumentsForCompany(companyId);
    await refreshSalesChain();
  }

  void resetForm() {
    for (final line in lines) {
      line.dispose();
    }
    final series = seriesOptions();
    State(() {
      selectedItem = null;
      companyId = contextCompanyId;
      branchId = contextBranchId;
      locationId = contextLocationId;
      financialYearId = contextFinancialYearId;
      documentSeriesId = series.isNotEmpty ? series.first.id : null;
      customerPartyId = null;
      billingAddressId = null;
      shippingAddressId = null;
      salesOrderId = null;
      salesDeliveryId = null;
      orderLinesCache = null;
      deliveryLinesCache = null;
      invoiceNoController.clear();
      invoiceDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      dueDateController.clear();
      customerRefNoController.clear();
      customerRefDateController.clear();
      currencyCodeController.text = 'INR';
      exchangeRateController.text = '1';
      adjustmentAmountController.clear();
      adjustmentRemarksController.clear();
      adjustmentAccountId = null;
      notesController.clear();
      termsController.clear();
      isActive = true;
      lines = <InvoiceLineDraft>[InvoiceLineDraft()];
      formError = null;
      salesChain = null;
    });
  }

  void applyFilters() {
    final search = searchController.text.trim().toLowerCase();
    State(() {
      filteredItems = items
          .where((item) {
            final data = rowJson(item);
            final status = item.invoiceStatus ?? '';
            final statusOk = statusFilter.isEmpty || status == statusFilter;
            final cust = quotationCustomerLabel(data);
            final searchOk =
                search.isEmpty ||
                [
                  item.invoiceNo ?? '',
                  status,
                  cust,
                ].join(' ').toLowerCase().contains(search);
            return statusOk && searchOk;
          })
          .toList(growable: false);
    });
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, uoms, uomConversions);
  }

  String? serialNumberForLine(InvoiceLineDraft line) {
    final groupedSerials = lineSerialNumbers(line);
    if (groupedSerials.length == 1) {
      return groupedSerials.first;
    }
    final serialNo = line.serialNoController.text.trim();
    if (serialNo.isNotEmpty) {
      return serialNo;
    }
    if (line.serialId == null) {
      return null;
    }
    final serial = serialOptionsForLine(line)
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (entry) =>
              int.tryParse(entry?['serial_id']?.toString() ?? '') ==
              line.serialId,
          orElse: () => null,
        );
    return serial?['serial_no']?.toString();
  }

  InvoiceTaxSummary invoiceTaxSummary() {
    double taxable = 0;
    double cgst = 0;
    double sgst = 0;
    double igst = 0;
    final isInterState = isInterStateForSummary();

    for (final line in lines) {
      final qty = double.tryParse(line.qtyController.text.trim()) ?? 0;
      final rate = double.tryParse(line.rateController.text.trim()) ?? 0;
      final discount =
          double.tryParse(line.discountController.text.trim()) ?? 0;
      if (qty <= 0 || rate < 0) {
        continue;
      }

      final gross = qty * rate;
      final clampedDiscount = discount.clamp(0, 100);
      final taxableAmount = gross * (1 - (clampedDiscount / 100));
      taxable += taxableAmount;

      final taxCode = taxCodeById(line.taxCodeId);
      final taxRate = taxCode?.taxRate ?? 0;
      if (taxRate <= 0) {
        continue;
      }

      final normalizedTaxType =
          ((taxCode?.taxType ?? taxCode?.toJson()['tax_application'])
              ?.toString()
              .trim()
              .toLowerCase()) ??
          '';
      final shouldUseIgst = isInterState ?? normalizedTaxType.contains('igst');
      if (shouldUseIgst) {
        igst += taxableAmount * taxRate / 100;
      } else {
        final halfTax = taxableAmount * taxRate / 200;
        cgst += halfTax;
        sgst += halfTax;
      }
    }

    final adjustment =
        double.tryParse(adjustmentAmountController.text.trim()) ?? 0;
    return InvoiceTaxSummary(
      taxable: taxable,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      total: taxable + cgst + sgst + igst + adjustment,
    );
  }

  DocumentPrintDataModel salesInvoicePrintData() {
    final summary = invoiceTaxSummary();
    final selected = selectedItem?.toJson() ?? const <String, dynamic>{};
    final company = companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == companyId,
      orElse: () => null,
    );
    final customer = customerForTaxContext(customerPartyId);
    final customerData = selected['customer'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(
            selected['customer'] as Map<String, dynamic>,
          )
        : customer?.toJson() ?? const <String, dynamic>{};
    final preferredAddress = preferredCustomerAddress(customer);
    final gstBreakupGroups = <String, dynamic>{};
    final printLines = lines
        .where((line) => line.itemId != null && line.itemId! > 0)
        .map((line) {
          final qty = double.tryParse(line.qtyController.text.trim()) ?? 0;
          final rate = double.tryParse(line.rateController.text.trim()) ?? 0;
          final discount =
              double.tryParse(line.discountController.text.trim()) ?? 0;
          final taxCode = taxCodeById(line.taxCodeId);
          final breakdown = computeSalesLineTaxBreakdown(
            qty: qty,
            rate: rate,
            discountPercent: discount,
            taxCode: taxCode,
            isInterState: isInterStateForSummary(),
          );
          accumulatePrintTemplateGstBreakup(
            gstBreakupGroups,
            taxCode: taxCode,
            taxPercent: breakdown.taxPercent,
            taxable: breakdown.taxable,
            cgst: breakdown.cgst,
            sgst: breakdown.sgst,
            igst: breakdown.igst,
            cess: breakdown.cess,
          );
          final item = itemsLookup.cast<ItemModel?>().firstWhere(
            (entry) => entry?.id == line.itemId,
            orElse: () => null,
          );
          return DocumentPrintLineModel(
            itemName:
                item?.itemName ??
                item?.itemCode ??
                line.descriptionController.text.trim(),
            description: line.descriptionController.text.trim(),
            qty: qty,
            rate: rate,
            taxAmount: roundToDouble(breakdown.total - breakdown.taxable, 2),
            lineTotal: roundToDouble(breakdown.taxable, 2),
          );
        })
        .toList(growable: false);
    final taxAmount = summary.cgst + summary.sgst + summary.igst;

    return DocumentPrintDataModel(
      companyName: companyNameById(companies, companyId),
      companyLogoUrl: AppConfig.resolvePublicFileUrl(company?.logoPath) ?? '',
      companyGstin: company?.gstin ?? '',
      documentNumber: nullIfEmpty(invoiceNoController.text) ?? 'Draft',
      documentDate: invoiceDateController.text.trim(),
      referenceNumber: customerRefNoController.text.trim(),
      partyName: stringValue(customerData, 'party_name').isNotEmpty
          ? stringValue(customerData, 'party_name')
          : stringValue(selected, 'customer_name'),
      partyAddress: formatPartyAddress(
        preferredAddress,
        fallback: stringValue(customerData, 'address_line1'),
      ),
      partyContact: resolvePartyContact(
        customer,
        fallback: stringValue(customerData, 'mobile_no'),
      ),
      partyGstin: resolveCustomerPrintGstin(customerData),
      notes: notesController.text.trim(),
      termsConditions: termsController.text.trim(),
      subtotal: roundToDouble(summary.taxable, 2),
      taxAmount: roundToDouble(taxAmount, 2),
      totalAmount: roundToDouble(summary.total, 2),
      amountInWords: printTemplateAmountInWords(
        roundToDouble(summary.total, 2),
        currencyCodeController.text.trim().isEmpty
            ? 'INR'
            : currencyCodeController.text.trim(),
      ),
      lines: printLines,
      gstBreakup: finalizePrintTemplateGstBreakup(gstBreakupGroups),
    );
  }

  Future<void> openPrintPreview(BuildContext context) {
    return openManagedDocumentPrintPreview(
      context,
      prepare: () => ensureCustomerTaxContext(customerPartyId),
      documentType: 'sales_invoice',
      title: 'Sales Invoice',
      documentDataBuilder: salesInvoicePrintData,
    );
  }

  Widget buildTaxSummaryCard(BuildContext context) {
    final summary = invoiceTaxSummary();
    final currency = currencyCodeController.text.trim().isEmpty
        ? 'INR'
        : currencyCodeController.text.trim();
    final isInterState = isInterStateForSummary();
    return GstSummaryCard(
      taxable: summary.taxable,
      cgst: summary.cgst,
      sgst: summary.sgst,
      igst: summary.igst,
      cess: 0,
      total: summary.total,
      currencyCode: currency,
      subtitle: isInterState == null
          ? 'Live totals for the current invoice lines.'
          : 'Live totals for the current invoice lines. ${isInterState ? 'Inter-state invoice using IGST.' : 'Intra-state invoice using CGST and SGST.'}',
    );
  }

  void addLine() {
    State(() {
      lines = List<InvoiceLineDraft>.from(lines)..add(InvoiceLineDraft());
    });
  }

  void removeLine(int index) {
    late InvoiceLineDraft removed;
    State(() {
      final next = List<InvoiceLineDraft>.from(lines);
      removed = next.removeAt(index);
      lines = next.isEmpty ? <InvoiceLineDraft>[InvoiceLineDraft()] : next;
    });
    disposeDraftEntriesNextFrame<InvoiceLineDraft>([
      removed,
    ], (entry) => entry.dispose());
  }

  List<SalesInvoiceLineModel> linesForSave() {
    final result = <SalesInvoiceLineModel>[];
    for (final line in lines) {
      final qty = double.tryParse(line.qtyController.text.trim()) ?? 0;
      final rate = double.tryParse(line.rateController.text.trim()) ?? 0;
      final disc = double.tryParse(line.discountController.text.trim()) ?? 0;
      final description = nullIfEmpty(line.descriptionController.text);
      final remarks = nullIfEmpty(line.remarksController.text);

      if (isSerialManagedItem(line.itemId)) {
        for (final serialNo in lineSerialNumbers(line)) {
          final matched = serialOptionByLabelForLine(line, serialNo);
          result.add(
            SalesInvoiceLineModel(
              salesOrderLineId: line.salesOrderLineId,
              salesDeliveryLineId: line.salesDeliveryLineId,
              itemId: line.itemId ?? 0,
              uomId: line.uomId ?? 0,
              invoicedQty: 1,
              rate: rate,
              warehouseId: line.warehouseId,
              batchId: line.batchId,
              serialId: matched == null
                  ? null
                  : int.tryParse(matched['serial_id']?.toString() ?? ''),
              serialNo: serialNo,
              taxCodeId: line.taxCodeId,
              description: description,
              discountPercent: disc == 0 ? null : disc,
              remarks: remarks,
            ),
          );
        }
        continue;
      }

      result.add(
        SalesInvoiceLineModel(
          salesOrderLineId: line.salesOrderLineId,
          salesDeliveryLineId: line.salesDeliveryLineId,
          itemId: line.itemId ?? 0,
          uomId: line.uomId ?? 0,
          invoicedQty: qty,
          rate: rate,
          warehouseId: line.warehouseId,
          batchId: line.batchId,
          serialId: line.serialId,
          serialNo: serialNumberForLine(line),
          taxCodeId: line.taxCodeId,
          description: description,
          discountPercent: disc == 0 ? null : disc,
          remarks: remarks,
        ),
      );
    }
    return result;
  }

  Future<void> save(BuildContext context) async {
    if (!canEdit) {
      State(() {
        formError = 'Only draft invoices can be updated.';
      });
      return;
    }

    await refreshSerialAvailabilityForSave();
    if (!mounted) {
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          (double.tryParse(line.qtyController.text.trim()) ?? 0) <= 0,
    )) {
      State(() => formError = 'Each line needs item, UOM, and quantity.');
      return;
    }

    final adjAmt = double.tryParse(adjustmentAmountController.text.trim()) ?? 0;
    if (adjAmt != 0 && adjustmentAccountId == null) {
      State(
        () => formError =
            'Choose an adjustment account when adjustment amount is not zero.',
      );
      return;
    }

    State(() {
      saving = true;
      formError = null;
    });

    final invoice = SalesInvoiceModel(
      id: selectedItem?.id ?? 0,
      companyId: companyId ?? 0,
      branchId: branchId ?? 0,
      locationId: locationId ?? 0,
      financialYearId: financialYearId ?? 0,
      customerPartyId: customerPartyId ?? 0,
      billingAddressId: billingAddressId,
      shippingAddressId: shippingAddressId,
      invoiceDate: invoiceDateController.text.trim(),
      documentSeriesId: documentSeriesId,
      salesOrderId: salesOrderId,
      salesDeliveryId: salesDeliveryId,
      invoiceNo: nullIfEmpty(invoiceNoController.text),
      dueDate: nullIfEmpty(dueDateController.text),
      currencyCode: nullIfEmpty(currencyCodeController.text) ?? 'INR',
      exchangeRate: double.tryParse(exchangeRateController.text.trim()) ?? 1,
      notes: nullIfEmpty(notesController.text),
      termsConditions: nullIfEmpty(termsController.text),
      customerReferenceNo: nullIfEmpty(customerRefNoController.text),
      customerReferenceDate: nullIfEmpty(customerRefDateController.text),
      isActive: isActive,
      adjustmentAmount: adjAmt == 0 ? null : adjAmt,
      adjustmentAccountId: adjAmt == 0 ? null : adjustmentAccountId,
      adjustmentRemarks: nullIfEmpty(adjustmentRemarksController.text),
      lines: linesForSave(),
    );

    try {
      final response = selectedItem == null
          ? await salesService.createInvoice(invoice)
          : await salesService.updateInvoice(selectedItem!.id!, invoice);
      final saved = response.data;
      if (saved != null) {
        pendingSelection = saved;
        final existingIndex = items.indexWhere((item) => item.id == saved.id);
        if (existingIndex >= 0) {
          final nextItems = List<SalesInvoiceModel>.from(items);
          nextItems[existingIndex] = saved;
          items = nextItems;
        } else {
          items = <SalesInvoiceModel>[saved, ...items];
        }
        applyFilters();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage(selectId: response.data?.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      State(() => formError = errorMessage(error));
    } finally {
      if (mounted) {
        State(() => saving = false);
      }
    }
  }

  Future<void> docAction(
    BuildContext context,
    Future<ApiResponse<SalesInvoiceModel>> Function() action,
  ) async {
    try {
      final response = await action();
      final saved = response.data;
      if (saved != null) {
        pendingSelection = saved;
        final existingIndex = items.indexWhere((item) => item.id == saved.id);
        if (existingIndex >= 0) {
          final nextItems = List<SalesInvoiceModel>.from(items);
          nextItems[existingIndex] = saved;
          items = nextItems;
        } else {
          items = <SalesInvoiceModel>[saved, ...items];
        }
        applyFilters();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage(selectId: response.data?.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      State(() => formError = errorMessage(error));
    }
  }

  Future<void> deleteSelected(BuildContext context) async {
    final id = selectedItem?.id;
    if (id == null || id == 0) {
      return;
    }
    try {
      final response = await salesService.deleteInvoice(id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage();
    } catch (error) {
      if (!mounted) {
        return;
      }
      State(() => formError = errorMessage(error));
    }
  }

  Future<ApiResponse<SalesInvoiceModel>> postInvoice(int id) {
    return salesService.postInvoice(id);
  }

  Future<ApiResponse<SalesInvoiceModel>> cancelInvoice(int id) {
    return salesService.cancelInvoice(id);
  }
}

class InvoiceTaxSummary {
  const InvoiceTaxSummary({
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.total,
  });

  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double total;
}

class InvoiceLineDraft {
  InvoiceLineDraft({
    this.salesOrderLineId,
    this.salesDeliveryLineId,
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.batchNo,
    this.serialId,
    List<String>? serialNumbers,
    String? serialNo,
    this.uomId,
    this.taxCodeId,
    String? description,
    String? qty,
    String? rate,
    String? discountPercent,
    String? remarks,
  }) : descriptionController = TextEditingController(text: description ?? ''),
       serialNoController = TextEditingController(text: serialNo ?? ''),
       qtyController = TextEditingController(text: qty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       discountController = TextEditingController(text: discountPercent ?? ''),
       remarksController = TextEditingController(text: remarks ?? ''),
       serialNumbers = List<String>.from(serialNumbers ?? const <String>[]);

  factory InvoiceLineDraft.fromLine(SalesInvoiceLineModel line) {
    return InvoiceLineDraft(
      salesOrderLineId: line.salesOrderLineId,
      salesDeliveryLineId: line.salesDeliveryLineId,
      itemId: line.itemId,
      warehouseId: line.warehouseId,
      batchId: line.batchId,
      batchNo: line.batchNo,
      serialId: line.serialId,
      serialNumbers: <String>[
        if ((line.serialNo ?? '').trim().isNotEmpty) line.serialNo!.trim(),
      ],
      serialNo: line.serialNo,
      uomId: line.uomId,
      taxCodeId: line.taxCodeId,
      description: line.description,
      qty: line.invoicedQty == 0 ? '' : line.invoicedQty.toString(),
      rate: line.rate == 0 ? '' : line.rate.toString(),
      discountPercent: line.discountPercent == null || line.discountPercent == 0
          ? ''
          : line.discountPercent.toString(),
      remarks: line.remarks,
    );
  }

  factory InvoiceLineDraft.fromQuotationLine(Map<String, dynamic> json) {
    final q = json['qty'];
    return InvoiceLineDraft(
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      taxCodeId: nullableIntKey(json, 'tax_code_id'),
      description: stringValue(json, 'description'),
      qty: q?.toString() ?? '',
      rate: stringValue(json, 'rate'),
      discountPercent: stringValue(json, 'discount_percent'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  factory InvoiceLineDraft.fromOrderLineMap(Map<String, dynamic> ol) {
    final ordered = double.tryParse(ol['ordered_qty']?.toString() ?? '') ?? 0;
    final invoiced = double.tryParse(ol['invoiced_qty']?.toString() ?? '') ?? 0;
    final rem = ordered - invoiced;
    return InvoiceLineDraft(
      salesOrderLineId: intValue(ol, 'id'),
      itemId: intValue(ol, 'item_id'),
      warehouseId: intValue(ol, 'warehouse_id'),
      batchId: nullableIntKey(ol, 'batch_id'),
      serialId: nullableIntKey(ol, 'serial_id'),
      serialNumbers: <String>[
        if (stringValue(ol, 'serial_no').trim().isNotEmpty)
          stringValue(ol, 'serial_no').trim(),
      ],
      serialNo: stringValue(ol, 'serial_no'),
      uomId: intValue(ol, 'uom_id'),
      taxCodeId: nullableIntKey(ol, 'tax_code_id'),
      description: stringValue(ol, 'description'),
      qty: rem > 0 ? rem.toString() : '',
      rate: stringValue(ol, 'rate'),
      discountPercent: stringValue(ol, 'discount_percent'),
      remarks: stringValue(ol, 'remarks'),
    );
  }

  factory InvoiceLineDraft.fromDeliveryLineMap(
    Map<String, dynamic> dl, {
    int? taxCodeId,
  }) {
    final pend =
        double.tryParse(dl['pending_invoice_qty']?.toString() ?? '') ?? 0;
    final sol = intValue(dl, 'sales_order_line_id');
    return InvoiceLineDraft(
      salesDeliveryLineId: intValue(dl, 'id'),
      salesOrderLineId: sol == 0 ? null : sol,
      itemId: intValue(dl, 'item_id'),
      warehouseId: intValue(dl, 'warehouse_id'),
      batchId: nullableIntKey(dl, 'batch_id'),
      serialId: nullableIntKey(dl, 'serial_id'),
      serialNumbers: <String>[
        if (stringValue(dl, 'serial_no').trim().isNotEmpty)
          stringValue(dl, 'serial_no').trim(),
      ],
      serialNo: stringValue(dl, 'serial_no'),
      uomId: intValue(dl, 'uom_id'),
      taxCodeId: taxCodeId ?? nullableIntKey(dl, 'tax_code_id'),
      description: stringValue(dl, 'description'),
      qty: pend > 0 ? pend.toString() : '',
      rate: stringValue(dl, 'rate'),
      remarks: stringValue(dl, 'remarks'),
    );
  }

  static int? nullableIntKey(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) {
      return null;
    }
    final i = int.tryParse(v.toString());
    if (i == null || i == 0) {
      return null;
    }
    return i;
  }

  int? salesOrderLineId;
  int? salesDeliveryLineId;
  int? itemId;
  int? warehouseId;
  int? batchId;
  String? batchNo;
  int? serialId;
  List<String> serialNumbers;
  int? uomId;
  int? taxCodeId;
  final TextEditingController descriptionController;
  final TextEditingController serialNoController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final TextEditingController discountController;
  final TextEditingController remarksController;

  void dispose() {
    descriptionController.dispose();
    serialNoController.dispose();
    qtyController.dispose();
    rateController.dispose();
    discountController.dispose();
    remarksController.dispose();
  }
}
