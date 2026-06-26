import '../../screen.dart';
import 'purchase_module_refresh_controller.dart';

class PurchaseReceiptLineDraft {
  PurchaseReceiptLineDraft({
    this.purchaseOrderLineId,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.serialId,
    this.taxCodeId,
    String? description,
    String? receivedQty,
    String? acceptedQty,
    String? rejectedQty,
    String? rate,
    String? remarks,
  }) : descriptionController = TextEditingController(text: description ?? ''),
       receivedQtyController = TextEditingController(text: receivedQty ?? ''),
       acceptedQtyController = TextEditingController(text: acceptedQty ?? ''),
       rejectedQtyController = TextEditingController(text: rejectedQty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory PurchaseReceiptLineDraft.fromJson(Map<String, dynamic> json) {
    return PurchaseReceiptLineDraft(
      purchaseOrderLineId: intValue(json, 'purchase_order_line_id'),
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      serialId: intValue(json, 'serial_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      description: stringValue(json, 'description'),
      receivedQty: stringValue(json, 'received_qty'),
      acceptedQty: stringValue(json, 'accepted_qty'),
      rejectedQty: stringValue(json, 'rejected_qty'),
      rate: stringValue(json, 'rate'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? purchaseOrderLineId;
  int? itemId;
  int? warehouseId;
  int? uomId;
  int? serialId;
  int? taxCodeId;
  final TextEditingController descriptionController;
  final TextEditingController receivedQtyController;
  final TextEditingController acceptedQtyController;
  final TextEditingController rejectedQtyController;
  final TextEditingController rateController;
  final TextEditingController remarksController;
  bool _disposed = false;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'purchase_order_line_id': purchaseOrderLineId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'uom_id': uomId,
      'serial_id': serialId,
      'description': nullIfEmpty(descriptionController.text),
      'received_qty':
          Validators.parseFlexibleNumber(receivedQtyController.text.trim()) ??
          0,
      'accepted_qty':
          Validators.parseFlexibleNumber(acceptedQtyController.text.trim()) ??
          0,
      'rejected_qty':
          Validators.parseFlexibleNumber(rejectedQtyController.text.trim()) ??
          0,
      'rate': Validators.parseFlexibleNumber(rateController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    descriptionController.dispose();
    receivedQtyController.dispose();
    acceptedQtyController.dispose();
    rejectedQtyController.dispose();
    rateController.dispose();
    remarksController.dispose();
  }
}

class PurchaseReceiptManagementController extends GetxController {
  PurchaseReceiptManagementController();

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(
          value: 'partially_invoiced',
          label: 'Partially Invoiced',
        ),
        AppDropdownItem(value: 'fully_invoiced', label: 'Fully Invoiced'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final PurchaseService _purchaseService = PurchaseService();
  final PurchaseModuleRefreshController _refreshController =
      PurchaseModuleRefreshController.ensureRegistered();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final TaxesService _taxesService = TaxesService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController receiptNoController = TextEditingController();
  final TextEditingController receiptDateController = TextEditingController();
  final TextEditingController supplierInvoiceNoController =
      TextEditingController();
  final TextEditingController supplierInvoiceDateController =
      TextEditingController();
  final TextEditingController supplierDcNoController = TextEditingController();
  final TextEditingController supplierDcDateController =
      TextEditingController();
  final TextEditingController roundOffController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  List<PurchaseReceiptModel> items = const <PurchaseReceiptModel>[];
  List<PurchaseReceiptModel> filteredItems = const <PurchaseReceiptModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PurchaseOrderModel> orders = const <PurchaseOrderModel>[];
  List<PartyModel> suppliers = const <PartyModel>[];
  final Map<int, PartyModel> supplierDetailsById = <int, PartyModel>{};
  final Map<int, List<PartyGstDetailModel>> supplierGstDetailsById =
      <int, List<PartyGstDetailModel>>{};
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  List<GstRegistrationModel> gstRegistrations = const <GstRegistrationModel>[];
  final Map<String, List<StockSerialModel>> serialOptionsByItemWarehouse =
      <String, List<StockSerialModel>>{};
  final Set<String> serialOptionsLoadingKeys = <String>{};
  final Map<int, PurchaseOrderModel> orderDetailCache =
      <int, PurchaseOrderModel>{};
  PurchaseReceiptModel? selectedItem;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? purchaseOrderId;
  int? supplierPartyId;
  int? warehouseId;
  bool applyRoundOff = false;
  bool isActive = true;
  List<PurchaseReceiptLineDraft> lines = <PurchaseReceiptLineDraft>[];
  bool _initialized = false;

  bool get canEditSelectedReceipt {
    if (selectedItem == null) {
      return true;
    }
    return purchaseDocumentIsDraftEditable(
      stringValue(selectedItem!.toJson(), 'receipt_status'),
    );
  }

  bool get isSelectedReceiptReadOnly =>
      selectedItem != null && !canEditSelectedReceipt;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applyFilters);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applyFilters)
      ..dispose();
    receiptNoController.dispose();
    receiptDateController.dispose();
    supplierInvoiceNoController.dispose();
    supplierInvoiceDateController.dispose();
    supplierDcNoController.dispose();
    supplierDcDateController.dispose();
    roundOffController.dispose();
    notesController.dispose();
    _disposeLines(lines);
    super.onClose();
  }

  Future<void> initialize({int? initialId}) async {
    if (!_initialized) {
      _initialized = true;
    }
    await loadPage(selectId: initialId);
    _refreshController.notifyChanged(source: 'purchase_receipt');
  }

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(
      selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
    );
    _refreshController.notifyChanged(source: 'purchase_receipt');
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _purchaseService.receipts(
          filters: const {'per_page': 200, 'sort_by': 'receipt_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.businessLocations(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.financialYears(
          filters: const {'per_page': 100, 'sort_by': 'fy_name'},
        ),
        _masterService.documentSeries(
          filters: const {'per_page': 200, 'sort_by': 'series_name'},
        ),
        _purchaseService.ordersAll(filters: const {'sort_by': 'order_date'}),
        _partiesService.partyTypes(filters: const {'per_page': 100}),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'party_name'},
        ),
        _masterService.warehouses(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _inventoryService.uomConversionsAll(
          filters: const {'per_page': 500, 'sort_by': 'from_uom_id'},
        ),
        _inventoryService.taxCodes(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _taxesService.gstRegistrationsAll(
          filters: const {'is_active': 1, 'sort_by': 'id'},
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

      items =
          (responses[0] as PaginatedResponse<PurchaseReceiptModel>).data ??
          const <PurchaseReceiptModel>[];
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
              .toList(growable: false);
      orders =
          (responses[6] as ApiResponse<List<PurchaseOrderModel>>).data ??
          const <PurchaseOrderModel>[];
      suppliers = purchaseSuppliers(
        parties:
            (responses[8] as PaginatedResponse<PartyModel>).data ??
            const <PartyModel>[],
        partyTypes:
            (responses[7] as PaginatedResponse<PartyTypeModel>).data ??
            const <PartyTypeModel>[],
      );
      warehouses =
          ((responses[9] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      itemsLookup =
          ((responses[10] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      uoms =
          ((responses[11] as PaginatedResponse<UomModel>).data ??
                  const <UomModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      uomConversions =
          ((responses[12] as ApiResponse<List<UomConversionModel>>).data ??
                  const <UomConversionModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      taxCodes =
          ((responses[13] as PaginatedResponse<TaxCodeModel>).data ??
                  const <TaxCodeModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      gstRegistrations =
          (responses[14] as ApiResponse<List<GstRegistrationModel>>).data ??
          const <GstRegistrationModel>[];
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      contextFinancialYearId = contextSelection.financialYearId;
      initialLoading = false;
      filteredItems = _filterItems(items, searchController.text, statusFilter);
      update();

      final selected = selectId != null
          ? items.cast<PurchaseReceiptModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : null;
      if (selected == null && selectId != null) {
        try {
          final detail = (await _purchaseService.receipt(selectId)).data;
          if (detail != null) {
            await selectDocument(detail, notify: false);
            update();
            return;
          }
        } catch (_) {}
      }
      if (selected != null) {
        await selectDocument(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
      update();
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
      update();
    }
  }

  Future<void> selectDocument(
    PurchaseReceiptModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _purchaseService.receipt(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PurchaseReceiptLineDraft.fromJson)
        .toList(growable: true);
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    purchaseOrderId = intValue(data, 'purchase_order_id');
    supplierPartyId = intValue(data, 'supplier_party_id');
    warehouseId = intValue(data, 'warehouse_id');
    receiptNoController.text = stringValue(data, 'receipt_no');
    receiptDateController.text = displayDate(
      nullableStringValue(data, 'receipt_date'),
    );
    supplierInvoiceNoController.text = stringValue(data, 'supplier_invoice_no');
    supplierInvoiceDateController.text = displayDate(
      nullableStringValue(data, 'supplier_invoice_date'),
    );
    supplierDcNoController.text = stringValue(data, 'supplier_dc_no');
    supplierDcDateController.text = displayDate(
      nullableStringValue(data, 'supplier_dc_date'),
    );
    roundOffController.text =
        stringValue(data, 'round_off_amount').trim().isEmpty
        ? ''
        : stringValue(data, 'round_off_amount');
    applyRoundOff =
        (Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0) !=
        0;
    notesController.text = stringValue(data, 'notes');
    isActive = boolValue(data, 'is_active', fallback: true);
    unawaited(ensureSupplierPrintContext(supplierPartyId));
    await _enrichLineTaxCodes(nextLines, purchaseOrderId);
    _replaceLines(nextLines, notify: false);
    formError = null;
    for (final line in lines) {
      if (isSerialManagedItem(line.itemId)) {
        unawaited(syncSerialOptionsForLine(line));
      }
    }
    _upsertReceipt(full, notify: false);
    if (notify) update();
  }

  PartyModel? supplierById(int? supplierId) {
    return suppliers.cast<PartyModel?>().firstWhere(
      (entry) => entry?.id == supplierId,
      orElse: () => null,
    );
  }

  ItemModel? itemById(int? itemId) {
    return itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
  }

  bool lineUsesInventory(int? itemId) =>
      itemById(itemId)?.trackInventory == true;

  bool lineAllowsBlankQty(PurchaseReceiptLineDraft line) {
    final item = itemById(line.itemId);
    return item != null && !item.trackInventory;
  }

  double resolvedReceivedQty(PurchaseReceiptLineDraft line) {
    final qty =
        Validators.parseFlexibleNumber(
          line.receivedQtyController.text.trim(),
        ) ??
        0;
    if (qty > 0) {
      return qty;
    }
    return lineAllowsBlankQty(line) ? 1 : qty;
  }

  double resolvedAcceptedQty(PurchaseReceiptLineDraft line) {
    final qty =
        Validators.parseFlexibleNumber(
          line.acceptedQtyController.text.trim(),
        ) ??
        0;
    if (qty > 0) {
      return qty;
    }
    return lineAllowsBlankQty(line) ? resolvedReceivedQty(line) : qty;
  }

  double resolvedRejectedQty(PurchaseReceiptLineDraft line) =>
      Validators.parseFlexibleNumber(line.rejectedQtyController.text.trim()) ??
      0;

  bool get hasInventoryTrackedLines =>
      lines.any((line) => lineUsesInventory(line.itemId));

  PartyModel? supplierForPrintContext(int? supplierId) {
    if (supplierId == null) {
      return null;
    }
    return supplierDetailsById[supplierId] ?? supplierById(supplierId);
  }

  Future<void> ensureSupplierPrintContext(int? supplierId) async {
    if (supplierId == null) {
      return;
    }
    try {
      final responses = await Future.wait<dynamic>([
        _partiesService.party(supplierId),
        _partiesService.partyAddresses(
          supplierId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
        _partiesService.partyContacts(
          supplierId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
        _partiesService.partyGstDetails(
          supplierId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
      ]);
      final party = (responses[0] as ApiResponse<PartyModel>).data;
      if (party != null) {
        supplierDetailsById[supplierId] = party.copyWith(
          addresses:
              (responses[1] as PaginatedResponse<PartyAddressModel>).data ??
              party.addresses,
          contacts:
              (responses[2] as PaginatedResponse<PartyContactModel>).data ??
              party.contacts,
          gstDetails:
              (responses[3] as PaginatedResponse<PartyGstDetailModel>).data ??
              party.gstDetails,
        );
        supplierGstDetailsById[supplierId] =
            (responses[3] as PaginatedResponse<PartyGstDetailModel>).data ??
            party.gstDetails;
      }
    } catch (_) {}
  }

  void resetForm({bool notify = true}) {
    final series = seriesOptions();
    selectedItem = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    purchaseOrderId = null;
    supplierPartyId = null;
    warehouseId = null;
    receiptNoController.clear();
    receiptDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    supplierInvoiceNoController.clear();
    supplierInvoiceDateController.clear();
    supplierDcNoController.clear();
    supplierDcDateController.clear();
    roundOffController.clear();
    applyRoundOff = false;
    notesController.clear();
    isActive = true;
    _replaceLines(const <PurchaseReceiptLineDraft>[], notify: false);
    formError = null;
    if (notify) update();
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    _applyFilters();
  }

  List<PurchaseReceiptModel> _filterItems(
    List<PurchaseReceiptModel> source,
    String query,
    String status,
  ) {
    return filterBySearchAndStatus(
      source,
      query: query,
      status: status,
      statusOf: (item) => stringValue(item.toJson(), 'receipt_status'),
      searchFieldsOf: (item) {
        final data = item.toJson();
        return <String>[
          stringValue(data, 'receipt_no'),
          purchaseStatusLabel(nullableStringValue(data, 'receipt_status')),
          stringValue(data, 'supplier_name'),
        ];
      },
    );
  }

  void _applyFilters() {
    filteredItems = _filterItems(items, searchController.text, statusFilter);
    update();
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    return allowedUomsForItem(itemById(itemId), uoms, uomConversions);
  }

  int? resolveDefaultUom(int? itemId, int? currentUomId) {
    return defaultUomIdForItem(
      itemById(itemId),
      uoms,
      uomConversions,
      current: currentUomId,
    );
  }

  bool isSerialManagedItem(int? itemId) {
    return itemById(itemId)?.hasSerial ?? false;
  }

  String serialCacheKey(int? itemId, int? warehouseId) =>
      '${itemId ?? 0}:${warehouseId ?? 0}';

  List<StockSerialModel> serialOptionsForLine(PurchaseReceiptLineDraft line) {
    if (!isSerialManagedItem(line.itemId) ||
        line.itemId == null ||
        line.warehouseId == null) {
      return const <StockSerialModel>[];
    }
    return serialOptionsByItemWarehouse[serialCacheKey(
          line.itemId,
          line.warehouseId,
        )] ??
        const <StockSerialModel>[];
  }

  Future<void> syncSerialOptionsForLine(PurchaseReceiptLineDraft line) async {
    final itemId = line.itemId;
    final localWarehouseId = line.warehouseId;
    if (itemId == null ||
        localWarehouseId == null ||
        !isSerialManagedItem(itemId)) {
      return;
    }
    final cacheKey = serialCacheKey(itemId, localWarehouseId);
    final cached = serialOptionsByItemWarehouse[cacheKey];
    if (cached != null) {
      final hasSelected = cached.any(
        (serial) => intValue(serial.toJson(), 'id') == line.serialId,
      );
      if ((line.serialId != null && !hasSelected) ||
          (line.serialId == null && cached.length == 1)) {
        line.serialId = cached.length == 1
            ? intValue(cached.first.toJson(), 'id')
            : null;
        update();
      }
      return;
    }
    if (serialOptionsLoadingKeys.contains(cacheKey)) {
      return;
    }
    serialOptionsLoadingKeys.add(cacheKey);
    try {
      final response = await _inventoryService.stockSerialsDropdown(
        filters: <String, dynamic>{
          'item_id': itemId,
          'warehouse_id': localWarehouseId,
        },
      );
      final serials = response.data ?? const <StockSerialModel>[];
      serialOptionsByItemWarehouse[cacheKey] = serials;
      final hasSelected = serials.any(
        (serial) => intValue(serial.toJson(), 'id') == line.serialId,
      );
      if (line.itemId == itemId &&
          line.warehouseId == localWarehouseId &&
          line.serialId != null &&
          !hasSelected) {
        line.serialId = serials.length == 1
            ? intValue(serials.first.toJson(), 'id')
            : null;
      } else if (line.itemId == itemId &&
          line.warehouseId == localWarehouseId &&
          line.serialId == null &&
          serials.length == 1) {
        line.serialId = intValue(serials.first.toJson(), 'id');
      }
      update();
    } catch (_) {
      serialOptionsByItemWarehouse[cacheKey] = const <StockSerialModel>[];
      if (line.itemId == itemId && line.warehouseId == localWarehouseId) {
        line.serialId = null;
      }
      update();
    } finally {
      serialOptionsLoadingKeys.remove(cacheKey);
    }
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_RECEIPT';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  int? defaultSeriesIdFor({
    required int? companyId,
    required int? financialYearId,
  }) {
    final options = documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_RECEIPT';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
    return options.isNotEmpty ? options.first.id : null;
  }

  List<PurchaseOrderModel> receiptOrderOptions() {
    final selectedOrderId = purchaseOrderId;
    return orders
        .where((item) {
          final data = item.toJson();
          final id = intValue(data, 'id');
          final status = stringValue(data, 'order_status').trim().toLowerCase();
          if (selectedOrderId != null && id == selectedOrderId) {
            return true;
          }
          if (id != null &&
              items.any((receipt) => receipt.purchaseOrderId == id)) {
            return false;
          }
          return !const {'draft', 'closed', 'cancelled'}.contains(status);
        })
        .toList(growable: false);
  }

  double pendingReceiptQtyForOrderLine(Map<String, dynamic> line) {
    final orderedQty =
        Validators.parseFlexibleNumber(stringValue(line, 'ordered_qty')) ?? 0;
    final receivedQty =
        Validators.parseFlexibleNumber(stringValue(line, 'received_qty')) ?? 0;
    return (orderedQty - receivedQty).clamp(0, double.infinity).toDouble();
  }

  List<PurchaseReceiptLineDraft> buildReceiptLinesFromOrder(
    PurchaseOrderModel order,
  ) {
    final orderLines = (order.toJson()['lines'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();

    final drafts = orderLines
        .expand((line) {
          final pendingQty = pendingReceiptQtyForOrderLine(line);
          if (pendingQty <= 0) {
            return const <PurchaseReceiptLineDraft>[];
          }
          final itemId = intValue(line, 'item_id');
          if (isSerialManagedItem(itemId)) {
            final units = pendingQty.floor();
            return List<PurchaseReceiptLineDraft>.generate(
              units > 0 ? units : 1,
              (_) => PurchaseReceiptLineDraft(
                purchaseOrderLineId: intValue(line, 'id'),
                itemId: itemId,
                warehouseId: intValue(line, 'warehouse_id'),
                uomId: intValue(line, 'uom_id'),
                taxCodeId: intValue(line, 'tax_code_id'),
                description: stringValue(line, 'description'),
                receivedQty: '1',
                acceptedQty: '1',
                rejectedQty: '0',
                rate: stringValue(line, 'rate'),
                remarks: stringValue(line, 'remarks'),
              ),
              growable: false,
            );
          }

          return <PurchaseReceiptLineDraft>[
            PurchaseReceiptLineDraft(
              purchaseOrderLineId: intValue(line, 'id'),
              itemId: itemId,
              warehouseId: intValue(line, 'warehouse_id'),
              uomId: intValue(line, 'uom_id'),
              taxCodeId: intValue(line, 'tax_code_id'),
              description: stringValue(line, 'description'),
              receivedQty: pendingQty.toString(),
              acceptedQty: pendingQty.toString(),
              rejectedQty: '0',
              rate: stringValue(line, 'rate'),
              remarks: stringValue(line, 'remarks'),
            ),
          ];
        })
        .toList(growable: false);

    return drafts.isEmpty
        ? <PurchaseReceiptLineDraft>[PurchaseReceiptLineDraft()]
        : drafts;
  }

  Future<void> handlePurchaseOrderChanged(int? orderId) async {
    if (orderId == null) {
      purchaseOrderId = null;
      supplierPartyId = null;
      warehouseId = null;
      _replaceLines(const <PurchaseReceiptLineDraft>[], notify: false);
      formError = null;
      update();
      return;
    }

    final response = await _purchaseService.order(orderId);
    final order = response.data;
    if (order == null) return;
    orderDetailCache[orderId] = order;

    final data = order.toJson();
    final nextLines = buildReceiptLinesFromOrder(order);
    final defaultWarehouseId = nextLines
        .where((line) => lineUsesInventory(line.itemId))
        .map((line) => line.warehouseId)
        .whereType<int>()
        .cast<int?>()
        .firstWhere((value) => value != null, orElse: () => null);
    final nextCompanyId = intValue(data, 'company_id');
    final nextFinancialYearId = intValue(data, 'financial_year_id');

    purchaseOrderId = orderId;
    companyId = nextCompanyId;
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = nextFinancialYearId;
    documentSeriesId = defaultSeriesIdFor(
      companyId: nextCompanyId,
      financialYearId: nextFinancialYearId,
    );
    supplierPartyId = intValue(data, 'supplier_party_id');
    warehouseId = defaultWarehouseId;
    unawaited(ensureSupplierPrintContext(supplierPartyId));
    receiptNoController.clear();
    supplierInvoiceNoController.clear();
    supplierInvoiceDateController.clear();
    supplierDcNoController.clear();
    supplierDcDateController.clear();
    roundOffController.text =
        stringValue(data, 'round_off_amount').trim().isEmpty
        ? ''
        : stringValue(data, 'round_off_amount');
    applyRoundOff =
        (Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0) !=
        0;
    notesController.text = stringValue(data, 'notes');
    _replaceLines(nextLines, notify: false);
    formError = nextLines.length == 1 && nextLines.first.itemId == null
        ? 'Selected purchase order has no pending receipt quantity.'
        : null;
    for (final line in lines) {
      if (isSerialManagedItem(line.itemId)) {
        unawaited(syncSerialOptionsForLine(line));
      }
    }
    update();
  }

  void addLine() {
    lines = List<PurchaseReceiptLineDraft>.from(lines)
      ..add(PurchaseReceiptLineDraft());
    update();
  }

  void removeLine(int index) {
    final updated = List<PurchaseReceiptLineDraft>.from(lines);
    updated.removeAt(index);
    _replaceLines(updated);
  }

  void _replaceLines(
    List<PurchaseReceiptLineDraft> nextLines, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<PurchaseReceiptLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => PurchaseReceiptLineDraft(),
      assign: (entries) => lines = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify ? update : null,
    );
  }

  void setFinancialYearId(int? value) {
    financialYearId = value;
    final series = seriesOptions();
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    update();
  }

  void setDocumentSeriesId(int? value) {
    documentSeriesId = value;
    update();
  }

  void setSupplierPartyId(int? value) {
    supplierPartyId = value;
    unawaited(ensureSupplierPrintContext(value));
    update();
  }

  void setWarehouseId(int? value) {
    warehouseId = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  String? resolveCompanyStateCodeForSummary() {
    return resolveCompanyStateCodeForGstSummary(
      gstRegistrations: gstRegistrations,
      locations: locations,
      companies: companies,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
    );
  }

  String? resolveSupplierStateCodeForSummary() {
    final supplier = supplierForPrintContext(supplierPartyId);
    final selected = selectedItem?.toJson() ?? const <String, dynamic>{};
    final selectedOrder = orderDetailCache[purchaseOrderId]?.toJson();
    return resolvePartyStateCodeForGstSummary(
      party: supplier,
      gstDetails:
          supplierGstDetailsById[supplierPartyId] ??
          supplier?.gstDetails ??
          const <PartyGstDetailModel>[],
      shippingAddressId:
          intValue(selected, 'shipping_address_id') ??
          intValue(
            selectedOrder ?? const <String, dynamic>{},
            'shipping_address_id',
          ),
      billingAddressId:
          intValue(selected, 'billing_address_id') ??
          intValue(
            selectedOrder ?? const <String, dynamic>{},
            'billing_address_id',
          ),
      preferredAddressType: 'billing',
    );
  }

  bool? isInterStateForSummary() {
    return resolveIsInterStateForGstSummary(
      companyStateCode: resolveCompanyStateCodeForSummary(),
      counterpartyStateCode: resolveSupplierStateCodeForSummary(),
    );
  }

  PurchaseLineTaxBreakdown taxBreakdownForLine(PurchaseReceiptLineDraft line) {
    final qty =
        Validators.parseFlexibleNumber(
          line.receivedQtyController.text.trim(),
        ) ??
        0;
    final rate =
        Validators.parseFlexibleNumber(line.rateController.text.trim()) ?? 0;
    return computePurchaseLineTaxBreakdown(
      qty: qty,
      rate: rate,
      discountPercent: 0,
      taxCode: purchaseTaxCodeById(taxCodes, line.taxCodeId),
      isInterState: isInterStateForSummary(),
    );
  }

  PurchaseDocumentTaxSummary receiptTaxSummary() {
    final roundOff = applyRoundOff
        ? (Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0)
        : 0;
    final base = summarizePurchaseLineTaxes(lines.map(taxBreakdownForLine));
    return PurchaseDocumentTaxSummary(
      taxable: base.taxable,
      cgst: base.cgst,
      sgst: base.sgst,
      igst: base.igst,
      cess: base.cess,
      total: base.total + roundOff,
    );
  }

  double receiptSubTotal() {
    return receiptTaxSummary().taxable;
  }

  double receiptRoundOff() {
    if (!applyRoundOff) {
      return 0;
    }
    return Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0;
  }

  double receiptTotal() => receiptTaxSummary().total;

  void _syncAutoRoundOff() {
    final roundOff =
        Validators.parseFlexibleNumber(roundOffController.text) ?? 0;
    Validators.syncAutoRoundOffController(
      roundOffController,
      enabled: applyRoundOff,
      baseTotal: receiptTaxSummary().total - roundOff,
    );
  }

  void setApplyRoundOff(bool value) {
    applyRoundOff = value;
    if (value) {
      _syncAutoRoundOff();
    } else {
      roundOffController.clear();
    }
    update();
  }

  Future<void> setLineItemId(PurchaseReceiptLineDraft line, int? value) async {
    line.itemId = value;
    line.uomId = resolveDefaultUom(value, line.uomId);
    line.serialId = null;
    if (!lineUsesInventory(value)) {
      line.warehouseId = null;
      if ((Validators.parseFlexibleNumber(
                line.receivedQtyController.text.trim(),
              ) ??
              0) <=
          0) {
        line.receivedQtyController.text = '1';
      }
      if ((Validators.parseFlexibleNumber(
                line.acceptedQtyController.text.trim(),
              ) ??
              0) <=
          0) {
        line.acceptedQtyController.text = '1';
      }
    }
    update();
    await syncSerialOptionsForLine(line);
  }

  Future<void> setLineWarehouseId(
    PurchaseReceiptLineDraft line,
    int? value,
  ) async {
    line.warehouseId = value;
    line.serialId = null;
    update();
    await syncSerialOptionsForLine(line);
  }

  void setLineSerialId(PurchaseReceiptLineDraft line, int? value) {
    line.serialId = value;
    update();
  }

  Future<PurchaseOrderModel?> _getOrderDetail(int? orderId) async {
    if (orderId == null) {
      return null;
    }
    final cached = orderDetailCache[orderId];
    if (cached != null) {
      return cached;
    }
    final response = await _purchaseService.order(orderId);
    final order = response.data;
    if (order != null) {
      orderDetailCache[orderId] = order;
    }
    return order;
  }

  Future<void> _enrichLineTaxCodes(
    List<PurchaseReceiptLineDraft> drafts,
    int? orderId,
  ) async {
    if (drafts.isEmpty || orderId == null) {
      return;
    }
    final order = await _getOrderDetail(orderId);
    if (order == null) {
      return;
    }
    final orderLines = (order.toJson()['lines'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    final taxCodeByOrderLineId = <int, int?>{
      for (final line in orderLines)
        if (intValue(line, 'id') != null)
          intValue(line, 'id')!: intValue(line, 'tax_code_id'),
    };
    for (final draft in drafts) {
      final orderLineId = draft.purchaseOrderLineId;
      if (orderLineId == null) {
        continue;
      }
      draft.taxCodeId = taxCodeByOrderLineId[orderLineId];
    }
  }

  void setLineUomId(PurchaseReceiptLineDraft line, int? value) {
    line.uomId = value;
    update();
  }

  Future<void> save(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    if (lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          (lineUsesInventory(line.itemId) && line.warehouseId == null) ||
          (isSerialManagedItem(line.itemId) && line.serialId == null) ||
          resolvedReceivedQty(line) <= 0,
    )) {
      formError =
          'Each line needs item, UOM, received quantity, and serial for serial-managed items. Warehouse is required only for inventory items.';
      update();
      return;
    }
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (isSerialManagedItem(line.itemId)) {
        final receivedQty =
            Validators.parseFlexibleNumber(
              line.receivedQtyController.text.trim(),
            ) ??
            0;
        final acceptedQty =
            Validators.parseFlexibleNumber(
              line.acceptedQtyController.text.trim(),
            ) ??
            0;
        if (receivedQty != 1 || acceptedQty != 1) {
          formError =
              'Serial-managed receipt lines must have received qty 1 and accepted qty 1 at line ${index + 1}.';
          update();
          return;
        }
      }
    }
    saving = true;
    formError = null;
    update();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_series_id': documentSeriesId,
      'purchase_order_id': purchaseOrderId,
      'receipt_no': nullIfEmpty(receiptNoController.text),
      'receipt_date': receiptDateController.text.trim(),
      'supplier_party_id': supplierPartyId,
      'warehouse_id': hasInventoryTrackedLines ? warehouseId : null,
      'supplier_invoice_no': nullIfEmpty(supplierInvoiceNoController.text),
      'supplier_invoice_date': nullIfEmpty(supplierInvoiceDateController.text),
      'supplier_dc_no': nullIfEmpty(supplierDcNoController.text),
      'supplier_dc_date': nullIfEmpty(supplierDcDateController.text),
      'round_off_amount': applyRoundOff
          ? (Validators.parseFlexibleNumber(roundOffController.text.trim()) ??
                0)
          : 0,
      'notes': nullIfEmpty(notesController.text),
      'is_active': isActive,
      'lines': lines
          .map(
            (line) => <String, dynamic>{
              ...line.toJson(),
              'warehouse_id': lineUsesInventory(line.itemId)
                  ? line.warehouseId
                  : null,
              'received_qty': resolvedReceivedQty(line),
              'accepted_qty': resolvedAcceptedQty(line),
              'rejected_qty': resolvedRejectedQty(line),
            },
          )
          .toList(growable: false),
    };
    try {
      final response = selectedItem == null
          ? await _purchaseService.createReceipt(
              PurchaseReceiptModel.fromJson(payload),
            )
          : await _purchaseService.updateReceipt(
              intValue(selectedItem!.toJson(), 'id')!,
              PurchaseReceiptModel.fromJson(payload),
            );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      final saved = response.data;
      if (saved != null) {
        _upsertReceipt(saved);
        await selectDocument(saved, notify: false);
        _refreshController.notifyChanged(source: 'purchase_receipt');
        update();
      } else {
        await loadPage(
          selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
        );
        _refreshController.notifyChanged(source: 'purchase_receipt');
      }
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> docAction(
    BuildContext context,
    Future<ApiResponse<PurchaseReceiptModel>> Function() action,
  ) async {
    try {
      final response = await action();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      final updated = response.data;
      if (updated != null) {
        _upsertReceipt(updated);
        await selectDocument(updated, notify: false);
        _refreshController.notifyChanged(source: 'purchase_receipt');
        update();
      } else {
        await loadPage(
          selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
        );
        _refreshController.notifyChanged(source: 'purchase_receipt');
      }
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    }
  }

  void _upsertReceipt(PurchaseReceiptModel receipt, {bool notify = true}) {
    final id = intValue(receipt.toJson(), 'id');
    if (id == null) {
      return;
    }
    final nextItems = List<PurchaseReceiptModel>.from(items);
    final existingIndex = nextItems.indexWhere(
      (item) => intValue(item.toJson(), 'id') == id,
    );
    if (existingIndex >= 0) {
      nextItems[existingIndex] = receipt;
    } else {
      nextItems.insert(0, receipt);
    }
    items = nextItems;
    if (notify) {
      _applyFilters();
    } else {
      filteredItems = _filterItems(items, searchController.text, statusFilter);
    }
  }

  void _disposeLines(List<PurchaseReceiptLineDraft> entries) {
    for (final line in entries) {
      line.dispose();
    }
  }
}
