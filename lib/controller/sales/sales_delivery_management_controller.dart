import '../../screen.dart';

class SalesDeliveryLineDraft {
  SalesDeliveryLineDraft({
    this.salesOrderLineId,
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.uomId,
    List<String>? serialNumbers,
    String? serialNo,
    String? description,
    String? deliveredQty,
    String? rate,
    String? remarks,
  }) : descriptionController = TextEditingController(text: description ?? ''),
       deliveredQtyController = TextEditingController(text: deliveredQty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       remarksController = TextEditingController(text: remarks ?? ''),
       serialNoController = TextEditingController(text: serialNo ?? ''),
       serialNumbers = List<String>.from(serialNumbers ?? const <String>[]);

  factory SalesDeliveryLineDraft.fromJson(Map<String, dynamic> json) {
    return SalesDeliveryLineDraft(
      salesOrderLineId: intValue(json, 'sales_order_line_id'),
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      batchId: intValue(json, 'batch_id'),
      uomId: intValue(json, 'uom_id'),
      serialNumbers: <String>[
        if (stringValue(json, 'serial_no').trim().isNotEmpty)
          stringValue(json, 'serial_no').trim(),
      ],
      serialNo: stringValue(json, 'serial_no'),
      description: stringValue(json, 'description'),
      deliveredQty: stringValue(json, 'delivered_qty'),
      rate: stringValue(json, 'rate'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? salesOrderLineId;
  int? itemId;
  int? warehouseId;
  int? batchId;
  int? uomId;
  List<String> serialNumbers;
  final TextEditingController descriptionController;
  final TextEditingController deliveredQtyController;
  final TextEditingController rateController;
  final TextEditingController remarksController;
  final TextEditingController serialNoController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (salesOrderLineId != null) 'sales_order_line_id': salesOrderLineId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      if (batchId != null) 'batch_id': batchId,
      'uom_id': uomId,
      'description': nullIfEmpty(descriptionController.text),
      'delivered_qty': double.tryParse(deliveredQtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    descriptionController.dispose();
    deliveredQtyController.dispose();
    rateController.dispose();
    remarksController.dispose();
    serialNoController.dispose();
  }
}

class SalesDeliveryManagementController extends GetxController {
  SalesDeliveryManagementController();

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

  final SalesService _salesService = SalesService();
  final CrmService _crmService = CrmService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController deliveryNoController = TextEditingController();
  final TextEditingController deliveryDateController = TextEditingController();
  final TextEditingController vehicleNoController = TextEditingController();
  final TextEditingController lrNoController = TextEditingController();
  final TextEditingController lrDateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  List<SalesDeliveryModel> items = const <SalesDeliveryModel>[];
  List<SalesDeliveryModel> filteredItems = const <SalesDeliveryModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<SalesOrderModel> orders = const <SalesOrderModel>[];
  List<PartyModel> customers = const <PartyModel>[];
  List<PartyModel> allParties = const <PartyModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  final Map<String, List<Map<String, dynamic>>>
  availableBatchesByItemWarehouse = <String, List<Map<String, dynamic>>>{};
  final Set<String> batchOptionsLoadingKeys = <String>{};
  final Map<String, List<Map<String, dynamic>>>
  availableSerialsByItemWarehouse = <String, List<Map<String, dynamic>>>{};
  final Set<String> serialOptionsLoadingKeys = <String>{};
  SalesDeliveryModel? selectedItem;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? salesOrderId;
  int? customerPartyId;
  int? transporterPartyId;
  bool isActive = true;
  Map<String, dynamic>? salesChain;
  List<SalesDeliveryLineDraft> lines = <SalesDeliveryLineDraft>[];

  bool _initialized = false;

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
    deliveryNoController.dispose();
    deliveryDateController.dispose();
    vehicleNoController.dispose();
    lrNoController.dispose();
    lrDateController.dispose();
    notesController.dispose();
    _disposeLines(lines);
    super.onClose();
  }

  Future<void> initialize({int? initialId}) async {
    if (!_initialized) {
      _initialized = true;
    }
    await loadPage(selectId: initialId);
  }

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(
      selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
    );
  }

  ItemModel? itemById(int? itemId) {
    if (itemId == null) return null;
    return itemsLookup.cast<ItemModel?>().firstWhere(
      (item) => item?.id == itemId,
      orElse: () => null,
    );
  }

  bool isSerialManagedItem(int? itemId) => itemById(itemId)?.hasSerial == true;
  bool isBatchManagedItem(int? itemId) => itemById(itemId)?.hasBatch == true;

  String batchCacheKey(int? itemId, int? warehouseId) =>
      '${itemId ?? 0}:${warehouseId ?? 0}:${companyId ?? 0}';

  String serialCacheKey(int? itemId, int? warehouseId, [int? batchId]) =>
      '${itemId ?? 0}:${warehouseId ?? 0}:${batchId ?? 0}:${companyId ?? 0}';

  List<String> lineSerialNumbers(SalesDeliveryLineDraft line) {
    if (line.serialNumbers.isNotEmpty) {
      return List<String>.from(line.serialNumbers);
    }
    final serialNo = line.serialNoController.text.trim();
    return serialNo.isEmpty ? const <String>[] : <String>[serialNo];
  }

  void setLineSerialNumbers(SalesDeliveryLineDraft line, List<String> values) {
    final normalized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    line.serialNumbers = List<String>.from(normalized);
    line.serialNoController.text = normalized.isEmpty ? '' : normalized.first;
    if (isSerialManagedItem(line.itemId)) {
      line.deliveredQtyController.text = normalized.length.toString();
    }
  }

  List<Map<String, dynamic>> batchOptionsForLine(SalesDeliveryLineDraft line) {
    if (!isBatchManagedItem(line.itemId) ||
        line.itemId == null ||
        line.warehouseId == null) {
      return const <Map<String, dynamic>>[];
    }
    return availableBatchesByItemWarehouse[batchCacheKey(
          line.itemId,
          line.warehouseId,
        )] ??
        const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> serialOptionsForLine(SalesDeliveryLineDraft line) {
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

  Future<void> syncBatchOptionsForLine(SalesDeliveryLineDraft line) async {
    final itemId = line.itemId;
    final warehouseId = line.warehouseId;
    if (itemId == null || warehouseId == null || !isBatchManagedItem(itemId)) {
      return;
    }
    final cacheKey = batchCacheKey(itemId, warehouseId);
    final cachedBatches = availableBatchesByItemWarehouse[cacheKey];
    if (cachedBatches != null) {
      final hasSelectedBatch = cachedBatches.any(
        (batch) =>
            int.tryParse(batch['batch_id']?.toString() ?? '') == line.batchId,
      );
      if ((line.batchId != null && !hasSelectedBatch) ||
          (line.batchId == null && cachedBatches.length == 1)) {
        line.batchId = cachedBatches.length == 1
            ? int.tryParse(cachedBatches.first['batch_id']?.toString() ?? '')
            : null;
        update();
      }
      return;
    }
    if (batchOptionsLoadingKeys.contains(cacheKey)) {
      return;
    }
    batchOptionsLoadingKeys.add(cacheKey);
    try {
      final response = await _inventoryService.inquiryBatchWiseStock(
        itemId: itemId,
        warehouseId: warehouseId,
        companyId: companyId,
      );
      final raw = response.data;
      final batches = raw is List
          ? raw
                .whereType<Map>()
                .map((entry) => Map<String, dynamic>.from(entry))
                .where((batch) {
                  final qty =
                      double.tryParse(batch['balance_qty']?.toString() ?? '') ??
                      0;
                  return qty > 0;
                })
                .toList(growable: false)
          : const <Map<String, dynamic>>[];
      availableBatchesByItemWarehouse[cacheKey] = batches;
      final hasSelectedBatch = batches.any(
        (batch) =>
            int.tryParse(batch['batch_id']?.toString() ?? '') == line.batchId,
      );
      if (line.itemId == itemId &&
          line.warehouseId == warehouseId &&
          line.batchId != null &&
          !hasSelectedBatch) {
        line.batchId = batches.length == 1
            ? int.tryParse(batches.first['batch_id']?.toString() ?? '')
            : null;
      } else if (line.itemId == itemId &&
          line.warehouseId == warehouseId &&
          line.batchId == null &&
          batches.length == 1) {
        line.batchId = int.tryParse(
          batches.first['batch_id']?.toString() ?? '',
        );
      }
      update();
    } catch (_) {
      availableBatchesByItemWarehouse[cacheKey] =
          const <Map<String, dynamic>>[];
      update();
    } finally {
      batchOptionsLoadingKeys.remove(cacheKey);
    }
  }

  Future<void> syncSerialOptionsForLine(SalesDeliveryLineDraft line) async {
    final itemId = line.itemId;
    final warehouseId = line.warehouseId;
    if (itemId == null || warehouseId == null || !isSerialManagedItem(itemId)) {
      return;
    }
    final cacheKey = serialCacheKey(itemId, warehouseId, line.batchId);
    final cachedSerials = availableSerialsByItemWarehouse[cacheKey];
    if (cachedSerials != null) {
      return;
    }
    if (serialOptionsLoadingKeys.contains(cacheKey)) {
      return;
    }
    serialOptionsLoadingKeys.add(cacheKey);
    try {
      final response = await _inventoryService.inquiryAvailableSerials(
        itemId: itemId,
        warehouseId: warehouseId,
        batchId: line.batchId,
      );
      final raw = response.data;
      final serials = raw is List
          ? raw
                .whereType<Map>()
                .map((entry) => Map<String, dynamic>.from(entry))
                .toList(growable: false)
          : const <Map<String, dynamic>>[];
      availableSerialsByItemWarehouse[cacheKey] = serials;
      final validLabels = serials
          .map(
            (serial) =>
                (serial['serial_no']?.toString().trim().toLowerCase() ?? ''),
          )
          .where((value) => value.isNotEmpty)
          .toSet();
      final filtered = lineSerialNumbers(line)
          .where((value) => validLabels.contains(value.toLowerCase()))
          .toList(growable: false);
      setLineSerialNumbers(line, filtered);
      update();
    } catch (_) {
      availableSerialsByItemWarehouse[cacheKey] =
          const <Map<String, dynamic>>[];
      update();
    } finally {
      serialOptionsLoadingKeys.remove(cacheKey);
    }
  }

  void syncInventoryOptionsForLines(Iterable<SalesDeliveryLineDraft> values) {
    for (final line in values) {
      unawaited(syncBatchOptionsForLine(line));
      unawaited(syncSerialOptionsForLine(line));
    }
  }

  List<Map<String, dynamic>> linesForSave() {
    return lines
        .expand((line) {
          final deliveredQty =
              double.tryParse(line.deliveredQtyController.text.trim()) ?? 0;
          final rate = double.tryParse(line.rateController.text.trim()) ?? 0;
          final description = nullIfEmpty(line.descriptionController.text);
          final remarks = nullIfEmpty(line.remarksController.text);

          if (isSerialManagedItem(line.itemId)) {
            final serials = lineSerialNumbers(line);
            return serials.map((serialNo) {
              final matched = serialOptionsForLine(line)
                  .cast<Map<String, dynamic>?>()
                  .firstWhere(
                    (serial) =>
                        (serial?['serial_no']
                                ?.toString()
                                .trim()
                                .toLowerCase() ??
                            '') ==
                        serialNo.toLowerCase(),
                    orElse: () => null,
                  );
              return <String, dynamic>{
                if (line.salesOrderLineId != null)
                  'sales_order_line_id': line.salesOrderLineId,
                'item_id': line.itemId,
                'warehouse_id': line.warehouseId,
                'uom_id': line.uomId,
                if (line.batchId != null) 'batch_id': line.batchId,
                if (matched != null)
                  'serial_id': int.tryParse(
                    matched['serial_id']?.toString() ?? '',
                  ),
                'description': description,
                'delivered_qty': 1,
                'rate': rate,
                'remarks': remarks,
              };
            });
          }

          return <Map<String, dynamic>>[
            <String, dynamic>{
              if (line.salesOrderLineId != null)
                'sales_order_line_id': line.salesOrderLineId,
              'item_id': line.itemId,
              'warehouse_id': line.warehouseId,
              'uom_id': line.uomId,
              if (line.batchId != null) 'batch_id': line.batchId,
              'description': description,
              'delivered_qty': deliveredQty,
              'rate': rate,
              'remarks': remarks,
            },
          ];
        })
        .toList(growable: false);
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _salesService.deliveries(
          filters: const {'per_page': 200, 'sort_by': 'delivery_date'},
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
        _salesService.ordersAll(filters: const {'sort_by': 'order_date'}),
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
          (responses[0] as PaginatedResponse<SalesDeliveryModel>).data ??
          const <SalesDeliveryModel>[];
      companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      financialYears =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      documentSeries =
          ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      orders =
          (responses[6] as ApiResponse<List<SalesOrderModel>>).data ??
          const <SalesOrderModel>[];
      allParties =
          (responses[8] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];
      customers = salesCustomersOrFallback(
        parties: allParties,
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
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      contextFinancialYearId = contextSelection.financialYearId;
      initialLoading = false;
      _applyFilters(notify: false);
      final selected = selectId != null
          ? items.cast<SalesDeliveryModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : null;
      if (selected != null) {
        await selectDocument(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
      update();
    } catch (error) {
      pageError = error.toString();
      initialLoading = false;
      update();
    }
  }

  Future<void> selectDocument(
    SalesDeliveryModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _salesService.delivery(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(SalesDeliveryLineDraft.fromJson)
        .toList(growable: true);
    _disposeLines(lines);
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    salesOrderId = intValue(data, 'sales_order_id');
    customerPartyId = intValue(data, 'customer_party_id');
    transporterPartyId = intValue(data, 'transporter_party_id');
    deliveryNoController.text = stringValue(data, 'delivery_no');
    deliveryDateController.text = displayDate(
      nullableStringValue(data, 'delivery_date'),
    );
    vehicleNoController.text = stringValue(data, 'vehicle_no');
    lrNoController.text = stringValue(data, 'lr_no');
    lrDateController.text = displayDate(nullableStringValue(data, 'lr_date'));
    notesController.text = stringValue(data, 'notes');
    isActive = boolValue(data, 'is_active', fallback: true);
    lines = nextLines.isEmpty
        ? <SalesDeliveryLineDraft>[SalesDeliveryLineDraft()]
        : nextLines;
    formError = null;
    syncInventoryOptionsForLines(lines);
    await refreshSalesChain();
    if (notify) update();
  }

  Future<void> refreshSalesChain() async {
    final orderId = salesOrderId;
    try {
      if (orderId != null) {
        final response = await _crmService.salesChain(orderId: orderId);
        salesChain = response.data;
      } else {
        salesChain = null;
      }
    } catch (_) {
      salesChain = null;
    }
    update();
  }

  void resetForm({bool notify = true}) {
    _disposeLines(lines);
    final series = seriesOptions();
    selectedItem = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    salesOrderId = null;
    customerPartyId = null;
    transporterPartyId = null;
    deliveryNoController.clear();
    deliveryDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    vehicleNoController.clear();
    lrNoController.clear();
    lrDateController.clear();
    notesController.clear();
    isActive = true;
    lines = <SalesDeliveryLineDraft>[SalesDeliveryLineDraft()];
    formError = null;
    salesChain = null;
    if (notify) update();
  }

  void _applyFilters({bool notify = true}) {
    final search = searchController.text.trim().toLowerCase();
    filteredItems = items
        .where((item) {
          final data = item.toJson();
          final statusOk =
              statusFilter.isEmpty ||
              stringValue(data, 'delivery_status') == statusFilter;
          final searchOk =
              search.isEmpty ||
              [
                stringValue(data, 'delivery_no'),
                stringValue(data, 'delivery_status'),
                quotationCustomerLabel(data),
              ].join(' ').toLowerCase().contains(search);
          return statusOk && searchOk;
        })
        .toList(growable: false);
    if (notify) update();
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    _applyFilters();
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, uoms, uomConversions);
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'SALES_DELIVERY';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  int? deliveryDocumentSeriesIdFrom(Map<String, dynamic> data) {
    final seriesId = intValue(data, 'document_series_id');
    if (seriesId != 0) {
      return seriesId;
    }
    final series = seriesOptions();
    return series.isNotEmpty ? series.first.id : null;
  }

  void applyDeliveryHeaderFromOrderJson(Map<String, dynamic> data) {
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = deliveryDocumentSeriesIdFrom(data);
    final customerId = intValue(data, 'customer_party_id');
    customerPartyId = customerId == 0 ? null : customerId;
    notesController.text = stringValue(data, 'notes');
  }

  void applyLinesFromOrderJson(Map<String, dynamic> data) {
    _disposeLines(lines);
    final drafts = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((line) {
          final ordered =
              double.tryParse(line['ordered_qty']?.toString() ?? '') ?? 0;
          final delivered =
              double.tryParse(line['delivered_qty']?.toString() ?? '') ?? 0;
          final pending = ordered - delivered;
          return SalesDeliveryLineDraft(
            salesOrderLineId: intValue(line, 'id'),
            itemId: intValue(line, 'item_id'),
            warehouseId: intValue(line, 'warehouse_id'),
            batchId: intValue(line, 'batch_id'),
            serialNumbers: <String>[
              if (stringValue(line, 'serial_no').trim().isNotEmpty)
                stringValue(line, 'serial_no').trim(),
            ],
            serialNo: stringValue(line, 'serial_no'),
            uomId: intValue(line, 'uom_id'),
            description: stringValue(line, 'description'),
            deliveredQty: pending > 0 ? pending.toString() : '',
            rate: stringValue(line, 'rate'),
            remarks: stringValue(line, 'remarks'),
          );
        })
        .where((line) {
          final qty =
              double.tryParse(line.deliveredQtyController.text.trim()) ?? 0;
          return qty > 0;
        })
        .toList(growable: true);
    lines = drafts.isEmpty
        ? <SalesDeliveryLineDraft>[SalesDeliveryLineDraft()]
        : drafts;
  }

  DocumentPrintDataModel salesDeliveryPrintData() {
    final company = companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == companyId,
      orElse: () => null,
    );
    final customer = customers.cast<PartyModel?>().firstWhere(
      (item) => item?.id == customerPartyId,
      orElse: () => null,
    );
    var subtotal = 0.0;
    final printLines = lines
        .where((line) => line.itemId != null && line.itemId! > 0)
        .map((line) {
          final qty =
              double.tryParse(line.deliveredQtyController.text.trim()) ?? 0;
          final rate = double.tryParse(line.rateController.text.trim()) ?? 0;
          final total = qty * rate;
          subtotal += total;
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
            lineTotal: roundToDouble(total, 2),
          );
        })
        .toList(growable: false);

    return DocumentPrintDataModel(
      companyName: companyNameById(companies, companyId),
      companyLogoUrl: AppConfig.resolvePublicFileUrl(company?.logoPath) ?? '',
      companyGstin: company?.gstin ?? '',
      documentNumber: nullIfEmpty(deliveryNoController.text) ?? 'Draft',
      documentDate: deliveryDateController.text.trim(),
      referenceNumber: '',
      partyName: customer?.partyName ?? '',
      partyAddress: '',
      partyContact: '',
      notes: notesController.text.trim(),
      subtotal: roundToDouble(subtotal, 2),
      taxAmount: 0,
      totalAmount: roundToDouble(subtotal, 2),
      amountInWords: printTemplateAmountInWords(
        roundToDouble(subtotal, 2),
        'INR',
      ),
      lines: printLines,
    );
  }

  Future<void> applySalesOrderSelection(int? orderId) async {
    salesOrderId = orderId;
    update();
    if (orderId == null) {
      await refreshSalesChain();
      return;
    }
    try {
      final response = await _salesService.order(orderId);
      final data = response.data?.toJson() ?? <String, dynamic>{};
      applyDeliveryHeaderFromOrderJson(data);
      applyLinesFromOrderJson(data);
      formError = null;
      update();
      syncInventoryOptionsForLines(lines);
    } catch (error) {
      formError = error.toString();
      update();
    }
    await refreshSalesChain();
  }

  void addLine() {
    lines = List<SalesDeliveryLineDraft>.from(lines)
      ..add(SalesDeliveryLineDraft());
    update();
  }

  void removeLine(int index) {
    final next = List<SalesDeliveryLineDraft>.from(lines);
    next.removeAt(index).dispose();
    lines = next;
    if (lines.isEmpty) {
      lines.add(SalesDeliveryLineDraft());
    }
    update();
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

  void setCustomerPartyId(int? value) {
    customerPartyId = value;
    update();
  }

  void setTransporterPartyId(int? value) {
    transporterPartyId = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void setLineItemId(int index, int? value) {
    final line = lines[index];
    line.itemId = value;
    line.batchId = null;
    line.serialNumbers = <String>[];
    line.serialNoController.clear();
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == value,
      orElse: () => null,
    );
    applySalesLineDefaultsFromItemMaster(
      item: item,
      uoms: uoms,
      conversions: uomConversions,
      rateController: line.rateController,
      setUom: (uomId) => line.uomId = uomId,
      currentUomId: line.uomId,
      setWarehouseId: (warehouseId) => line.warehouseId = warehouseId,
      currentWarehouseId: line.warehouseId,
      warehouses: warehouses,
    );
    if (isSerialManagedItem(value)) {
      line.deliveredQtyController.text = '';
    }
    update();
  }

  Future<void> setLineWarehouseId(int index, int? value) async {
    final line = lines[index];
    line.warehouseId = value;
    line.batchId = null;
    line.serialNumbers = <String>[];
    line.serialNoController.clear();
    update();
    await syncBatchOptionsForLine(line);
    await syncSerialOptionsForLine(line);
  }

  Future<void> setLineBatchId(int index, int? value) async {
    final line = lines[index];
    line.batchId = value;
    line.serialNumbers = <String>[];
    line.serialNoController.clear();
    update();
    await syncSerialOptionsForLine(line);
  }

  void setLineUomId(int index, int? value) {
    lines[index].uomId = value;
    update();
  }

  void refreshState() {
    update();
  }

  Future<void> save(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    syncInventoryOptionsForLines(lines);
    if (lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          line.warehouseId == null ||
          (double.tryParse(line.deliveredQtyController.text.trim()) ?? 0) <= 0,
    )) {
      formError =
          'Each line needs item, warehouse, UOM, and delivered quantity.';
      update();
      return;
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
      'sales_order_id': salesOrderId,
      'delivery_no': nullIfEmpty(deliveryNoController.text),
      'delivery_date': deliveryDateController.text.trim(),
      'customer_party_id': customerPartyId,
      'transporter_party_id': transporterPartyId,
      'vehicle_no': nullIfEmpty(vehicleNoController.text),
      'lr_no': nullIfEmpty(lrNoController.text),
      'lr_date': nullIfEmpty(lrDateController.text),
      'notes': nullIfEmpty(notesController.text),
      'is_active': isActive,
      'lines': linesForSave(),
    };
    try {
      final response = selectedItem == null
          ? await _salesService.createDelivery(
              SalesDeliveryModel.fromJson(payload),
            )
          : await _salesService.updateDelivery(
              intValue(selectedItem!.toJson(), 'id')!,
              SalesDeliveryModel.fromJson(payload),
            );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> docAction(
    BuildContext context,
    Future<ApiResponse<SalesDeliveryModel>> Function() action,
  ) async {
    try {
      final response = await action();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  Future<void> postSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.postDelivery(
        id,
        SalesDeliveryModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  Future<void> cancelSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.cancelDelivery(
        id,
        SalesDeliveryModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  void _disposeLines(List<SalesDeliveryLineDraft> values) {
    for (final line in values) {
      line.dispose();
    }
  }
}
