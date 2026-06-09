import '../../screen.dart';
import 'sales_module_refresh_controller.dart';

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
      'delivered_qty':
          Validators.parseFlexibleNumber(deliveredQtyController.text) ?? 0,
      'rate': Validators.parseFlexibleNumber(rateController.text) ?? 0,
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

class SalesDeliveryReturnableDcDraft {
  SalesDeliveryReturnableDcDraft({
    this.itemId,
    this.uomId,
    String? itemName,
    String? description,
    String? qty,
    String? remarks,
  }) : itemNameController = TextEditingController(text: itemName ?? ''),
       descriptionController = TextEditingController(text: description ?? ''),
       qtyController = TextEditingController(text: qty ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory SalesDeliveryReturnableDcDraft.fromJson(Map<String, dynamic> json) {
    return SalesDeliveryReturnableDcDraft(
      itemId: intValue(json, 'item_id'),
      uomId: intValue(json, 'uom_id'),
      itemName: stringValue(json, 'item_name'),
      description: stringValue(json, 'description'),
      qty: stringValue(json, 'qty'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? itemId;
  int? uomId;
  final TextEditingController itemNameController;
  final TextEditingController descriptionController;
  final TextEditingController qtyController;
  final TextEditingController remarksController;

  void dispose() {
    itemNameController.dispose();
    descriptionController.dispose();
    qtyController.dispose();
    remarksController.dispose();
  }
}

class SalesDeliveryManagementController extends GetxController {
  SalesDeliveryManagementController();

  static const String lineItemsSectionId = 'sales_delivery_line_items';

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
  final SalesModuleRefreshController _refreshController =
      SalesModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController deliveryNoController = TextEditingController();
  final TextEditingController deliveryDateController = TextEditingController();
  final TextEditingController vehicleNoController = TextEditingController();
  final TextEditingController lrNoController = TextEditingController();
  final TextEditingController lrDateController = TextEditingController();
  final TextEditingController roundOffController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController termsController = TextEditingController();

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
  final Map<int, PartyModel> customerDetailsById = <int, PartyModel>{};
  final Map<int, List<PartyGstDetailModel>> customerGstDetailsById =
      <int, List<PartyGstDetailModel>>{};
  List<PartyModel> allParties = const <PartyModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  final Map<int, ItemModel> itemLookupById = <int, ItemModel>{};
  List<ItemPriceModel> itemPrices = const <ItemPriceModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  final Map<String, List<Map<String, dynamic>>>
  availableBatchesByItemWarehouse = <String, List<Map<String, dynamic>>>{};
  final Set<String> batchOptionsLoadingKeys = <String>{};
  final Map<String, List<Map<String, dynamic>>>
  availableSerialsByItemWarehouse = <String, List<Map<String, dynamic>>>{};
  final Map<String, Map<String, Map<String, dynamic>>>
  availableSerialLookupByItemWarehouse =
      <String, Map<String, Map<String, dynamic>>>{};
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
  String deliveryKind = 'dc';
  bool applyRoundOff = false;
  bool isActive = true;
  Map<String, dynamic>? salesChain;
  List<SalesDeliveryLineDraft> lines = <SalesDeliveryLineDraft>[];
  List<SalesDeliveryReturnableDcDraft> returnableDcs =
      <SalesDeliveryReturnableDcDraft>[];

  bool _initialized = false;

  String get deliveryKindLabel =>
      deliveryKind == 'rdc' ? 'Returnable DC' : 'DC';

  bool get isReturnableDc => deliveryKind == 'rdc';

  String get printDocumentType =>
      isReturnableDc ? 'sales_returnable_delivery' : 'sales_delivery';

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
    dateFromController.dispose();
    dateToController.dispose();
    searchController
      ..removeListener(_applyFilters)
      ..dispose();
    deliveryNoController.dispose();
    deliveryDateController.dispose();
    vehicleNoController.dispose();
    lrNoController.dispose();
    lrDateController.dispose();
    roundOffController.dispose();
    notesController.dispose();
    termsController.dispose();
    _disposeLines(lines);
    _disposeReturnableDcs(returnableDcs);
    super.onClose();
  }

  Future<void> initialize({
    int? initialId,
    int? initialOrderId,
    bool editorOnly = false,
  }) async {
    if (!_initialized) {
      _initialized = true;
    }
    await loadPage(
      selectId: initialId,
      initialOrderId: initialOrderId,
      editorOnly: editorOnly,
    );
  }

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(
      selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
    );
  }

  bool get mounted => !isClosed;

  List<AppDropdownItem<int>> get financialYearDropdownItems => financialYears
      .where((item) => item.id != null)
      .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
      .toList(growable: false);

  List<AppDropdownItem<int>> get documentSeriesDropdownItems => seriesOptions()
      .where((item) => item.id != null)
      .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
      .toList(growable: false);

  List<AppDropdownItem<int>> get customerDropdownItems => customers
      .where((item) => item.id != null)
      .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
      .toList(growable: false);

  List<AppDropdownItem<int>> get orderDropdownItems => orders
      .where((item) => intValue(item.toJson(), 'id') != null)
      .map(
        (item) => AppDropdownItem(
          value: intValue(item.toJson(), 'id')!,
          label: stringValue(item.toJson(), 'order_no', 'Order'),
        ),
      )
      .toList(growable: false);

  List<AppDropdownItem<int>> get transporterDropdownItems => allParties
      .where((item) => item.id != null)
      .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
      .toList(growable: false);

  List<AppSearchPickerOption<int>> get itemPickerOptions => itemsLookup
      .where((item) => item.id != null)
      .map(
        (item) => AppSearchPickerOption<int>(
          value: item.id!,
          label: item.toString(),
          subtitle: item.itemCode,
        ),
      )
      .toList(growable: false);

  List<AppDropdownItem<int>> get warehouseDropdownItems => warehouses
      .where((item) {
        if (item.id == null) {
          return false;
        }
        if (companyId != null && item.companyId != companyId) {
          return false;
        }
        if (branchId != null && item.branchId != branchId) {
          return false;
        }
        if (locationId != null && item.locationId != locationId) {
          return false;
        }
        return true;
      })
      .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
      .toList(growable: false);

  String? itemLabelById(int? itemId) => itemById(itemId)?.toString();

  void refreshLineItemsSection() => update(<Object>[lineItemsSectionId]);

  PartyModel? customerListEntryById(int? partyId) {
    if (partyId == null) {
      return null;
    }
    return customers.cast<PartyModel?>().firstWhere(
      (party) => party?.id == partyId,
      orElse: () => null,
    );
  }

  PartyModel? customerForPrintContext(int? partyId) {
    if (partyId == null) {
      return null;
    }
    return customerDetailsById[partyId] ?? customerListEntryById(partyId);
  }

  Future<void> ensureCustomerPrintContext(int? partyId) async {
    if (partyId == null) {
      return;
    }
    try {
      final responses = await Future.wait<dynamic>([
        _partiesService.party(partyId),
        _partiesService.partyAddresses(
          partyId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
        _partiesService.partyContacts(
          partyId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
        _partiesService.partyGstDetails(
          partyId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
      ]);
      if (!mounted) {
        return;
      }
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
        customerGstDetailsById[partyId] =
            (responses[3] as PaginatedResponse<PartyGstDetailModel>).data ??
            const <PartyGstDetailModel>[];
      }
    } catch (_) {}
  }

  ItemModel? itemById(int? itemId) {
    return itemId == null ? null : itemLookupById[itemId];
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

  Map<String, Map<String, dynamic>> serialLookupForLine(
    SalesDeliveryLineDraft line,
  ) {
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

  Set<String> serialLabelSetForLine(SalesDeliveryLineDraft line) =>
      serialLookupForLine(line).keys.toSet();

  Map<String, dynamic>? serialOptionByLabelForLine(
    SalesDeliveryLineDraft line,
    String serialNo,
  ) => serialLookupForLine(line)[serialNo.trim().toLowerCase()];

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
                      Validators.parseFlexibleNumber(
                        batch['balance_qty']?.toString(),
                      ) ??
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
      availableSerialLookupByItemWarehouse[cacheKey] = {
        for (final serial in serials)
          (serial['serial_no']?.toString().trim().toLowerCase() ?? ''): serial,
      }..remove('');
      final validLabels = availableSerialLookupByItemWarehouse[cacheKey]!.keys;
      final filtered = lineSerialNumbers(line)
          .where((value) => validLabels.contains(value.toLowerCase()))
          .toList(growable: false);
      setLineSerialNumbers(line, filtered);
      update();
    } catch (_) {
      availableSerialsByItemWarehouse[cacheKey] =
          const <Map<String, dynamic>>[];
      availableSerialLookupByItemWarehouse[cacheKey] =
          const <String, Map<String, dynamic>>{};
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
    final result = <Map<String, dynamic>>[];
    for (final line in lines) {
      final deliveredQty =
          Validators.parseFlexibleNumber(line.deliveredQtyController.text) ?? 0;
      final rate =
          Validators.parseFlexibleNumber(line.rateController.text) ?? 0;
      final description = nullIfEmpty(line.descriptionController.text);
      final remarks = nullIfEmpty(line.remarksController.text);
      final basePayload = <String, dynamic>{
        if (line.salesOrderLineId != null)
          'sales_order_line_id': line.salesOrderLineId,
        'item_id': line.itemId,
        'warehouse_id': line.warehouseId,
        'uom_id': line.uomId,
        if (line.batchId != null) 'batch_id': line.batchId,
        'description': description,
        'rate': rate,
        'remarks': remarks,
      };

      if (isSerialManagedItem(line.itemId)) {
        for (final serialNo in lineSerialNumbers(line)) {
          final matched = serialOptionByLabelForLine(line, serialNo);
          result.add(<String, dynamic>{
            ...basePayload,
            if (matched != null)
              'serial_id': int.tryParse(matched['serial_id']?.toString() ?? ''),
            'delivered_qty': 1,
          });
        }
        continue;
      }

      result.add(<String, dynamic>{
        ...basePayload,
        'delivered_qty': deliveredQty,
      });
    }
    return result;
  }

  List<Map<String, dynamic>> returnableDcsForSave() {
    return returnableDcs
        .map(
          (row) => <String, dynamic>{
            'item_id': row.itemId,
            'item_name': nullIfEmpty(row.itemNameController.text),
            'uom_id': row.uomId,
            'description': nullIfEmpty(row.descriptionController.text),
            'qty': Validators.parseFlexibleNumber(row.qtyController.text) ?? 0,
            'remarks': nullIfEmpty(row.remarksController.text),
          },
        )
        .toList(growable: false);
  }

  Future<void> loadPage({
    int? selectId,
    int? initialOrderId,
    bool editorOnly = false,
  }) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _salesService.deliveriesAll(
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
        _inventoryService.itemPrices(
          filters: const {
            'per_page': 1000,
            'sort_by': 'valid_from',
            'sort_order': 'desc',
          },
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
          (responses[0] as ApiResponse<List<SalesDeliveryModel>>).data ??
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
      customerDetailsById
        ..clear()
        ..addEntries(
          customers
              .where((item) => item.id != null)
              .map((item) => MapEntry(item.id!, item)),
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
      itemPrices =
          ((responses[11] as PaginatedResponse<ItemPriceModel>).data ??
                  const <ItemPriceModel>[])
              .where((price) => price.isActive)
              .toList(growable: false);
      itemLookupById
        ..clear()
        ..addEntries(
          itemsLookup
              .where((item) => item.id != null)
              .map((item) => MapEntry(item.id!, item)),
        );
      uoms =
          ((responses[12] as PaginatedResponse<UomModel>).data ??
                  const <UomModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      uomConversions =
          ((responses[13] as ApiResponse<List<UomConversionModel>>).data ??
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
          : (editorOnly
                ? null
                : (selectedItem == null
                      ? (items.isNotEmpty ? items.first : null)
                      : null));
      if (selected == null && selectId != null) {
        try {
          final detail = (await _salesService.delivery(selectId)).data;
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
        if (initialOrderId != null && editorOnly) {
          await applySalesOrderSelection(initialOrderId);
        }
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
    final nextReturnableDcs =
        (data['returnable_dcs'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(SalesDeliveryReturnableDcDraft.fromJson)
            .toList(growable: true);
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    salesOrderId = intValue(data, 'sales_order_id');
    customerPartyId = intValue(data, 'customer_party_id');
    transporterPartyId = intValue(data, 'transporter_party_id');
    deliveryKind = nextReturnableDcs.isNotEmpty && nextLines.isEmpty
        ? 'rdc'
        : 'dc';
    deliveryNoController.text = stringValue(data, 'delivery_no');
    deliveryDateController.text = displayDate(
      nullableStringValue(data, 'delivery_date'),
    );
    vehicleNoController.text = stringValue(data, 'vehicle_no');
    lrNoController.text = stringValue(data, 'lr_no');
    lrDateController.text = displayDate(nullableStringValue(data, 'lr_date'));
    roundOffController.text =
        stringValue(data, 'round_off_amount').trim().isEmpty
        ? ''
        : stringValue(data, 'round_off_amount');
    applyRoundOff =
        (Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0) !=
        0;
    notesController.text = stringValue(data, 'notes');
    termsController.text = stringValue(data, 'terms_conditions');
    isActive = boolValue(data, 'is_active', fallback: true);
    _replaceLines(nextLines, notify: false);
    _replaceReturnableDcs(nextReturnableDcs, notify: false);
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
    selectedItem = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    final series = seriesOptions();
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    salesOrderId = null;
    customerPartyId = null;
    transporterPartyId = null;
    deliveryKind = 'dc';
    deliveryNoController.clear();
    deliveryDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    vehicleNoController.clear();
    lrNoController.clear();
    lrDateController.clear();
    roundOffController.clear();
    applyRoundOff = false;
    notesController.clear();
    termsController.clear();
    isActive = true;
    _replaceLines(const <SalesDeliveryLineDraft>[], notify: false);
    _replaceReturnableDcs(
      const <SalesDeliveryReturnableDcDraft>[],
      notify: false,
    );
    formError = null;
    salesChain = null;
    if (notify) update();
  }

  void _applyFilters({bool notify = true}) {
    filteredItems =
        filterBySearchAndStatus(
              items,
              query: searchController.text,
              status: statusFilter,
              statusOf: (item) => stringValue(item.toJson(), 'delivery_status'),
              searchFieldsOf: (item) {
                final data = item.toJson();
                return <String>[
                  stringValue(data, 'delivery_no'),
                  stringValue(data, 'delivery_status'),
                  quotationCustomerLabel(data),
                ];
              },
            )
            .where(
              (item) => matchesDateValueRange(
                nullableStringValue(item.toJson(), 'delivery_date'),
                fromValue: dateFromController.text,
                toValue: dateToController.text,
              ),
            )
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

  int? defaultUomIdForItemId(int? itemId, {int? current}) {
    return defaultUomIdForItem(
      itemById(itemId),
      uoms,
      uomConversions,
      current: current,
    );
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final documentType = (item.documentType ?? '').trim().toUpperCase();
          final typeOk =
              documentType.isEmpty ||
              (deliveryKind == 'rdc'
                  ? _isReturnableDeliverySeriesType(documentType)
                  : _isDeliverySeriesType(documentType));
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  bool _isReturnableDeliverySeriesType(String documentType) {
    return documentType.contains('DELIVERY_CHALLAN');
  }

  bool _isDeliverySeriesType(String documentType) {
    if (documentType == 'SALES_DELIVERY') {
      return true;
    }
    if (!documentType.contains('DELIVERY_CHALLAN')) {
      return false;
    }
    return !documentType.contains('RETURNABLE');
  }

  int? deliveryDocumentSeriesIdFrom(Map<String, dynamic> data) {
    final seriesId = intValue(data, 'document_series_id');
    final series = seriesOptions();
    if (series.any((item) => item.id == seriesId)) {
      return seriesId;
    }
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
    roundOffController.text =
        stringValue(data, 'round_off_amount').trim().isEmpty
        ? ''
        : stringValue(data, 'round_off_amount');
    applyRoundOff =
        (Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0) !=
        0;
    notesController.text = stringValue(data, 'notes');
    termsController.text = stringValue(data, 'terms_conditions');
  }

  double deliverySubTotal() {
    if (isReturnableDc) {
      return 0;
    }
    return lines.fold<double>(0, (sum, line) {
      final qty =
          Validators.parseFlexibleNumber(line.deliveredQtyController.text) ?? 0;
      final rate =
          Validators.parseFlexibleNumber(line.rateController.text) ?? 0;
      return sum + (qty * rate);
    });
  }

  double deliveryRoundOff() {
    if (!applyRoundOff) {
      return 0;
    }
    return Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0;
  }

  double deliveryTotal() => deliverySubTotal() + deliveryRoundOff();

  void _syncAutoRoundOff() {
    Validators.syncAutoRoundOffController(
      roundOffController,
      enabled: applyRoundOff,
      baseTotal: deliverySubTotal(),
    );
  }

  void applyLinesFromOrderJson(Map<String, dynamic> data) {
    final drafts = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((line) {
          final ordered =
              Validators.parseFlexibleNumber(line['ordered_qty']?.toString()) ??
              0;
          final delivered =
              Validators.parseFlexibleNumber(
                line['delivered_qty']?.toString(),
              ) ??
              0;
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
              Validators.parseFlexibleNumber(
                line.deliveredQtyController.text,
              ) ??
              0;
          return qty > 0;
        })
        .toList(growable: true);
    _replaceLines(drafts, notify: false);
  }

  DocumentPrintDataModel salesDeliveryPrintData() {
    final company = companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == companyId,
      orElse: () => null,
    );
    final customer = customerForPrintContext(customerPartyId);
    final selected = selectedItem?.toJson() ?? const <String, dynamic>{};
    final preferredAddress = preferredPartyAddress(
      customer,
      shippingAddressId: intValue(selected, 'shipping_address_id'),
      billingAddressId: intValue(selected, 'billing_address_id'),
    );
    var subtotal = 0.0;
    final printLines = isReturnableDc
        ? returnableDcs
              .where(
                (row) =>
                    row.itemId != null ||
                    row.itemNameController.text.trim().isNotEmpty,
              )
              .map((row) {
                final qty =
                    Validators.parseFlexibleNumber(row.qtyController.text) ?? 0;
                final item = itemById(row.itemId);
                return DocumentPrintLineModel(
                  itemName:
                      item?.itemName ??
                      item?.itemCode ??
                      row.itemNameController.text.trim(),
                  description: row.descriptionController.text.trim(),
                  qty: qty,
                  rate: 0,
                  lineTotal: 0,
                );
              })
              .toList(growable: false)
        : lines
              .where((line) => line.itemId != null && line.itemId! > 0)
              .map((line) {
                final qty =
                    Validators.parseFlexibleNumber(
                      line.deliveredQtyController.text,
                    ) ??
                    0;
                final rate =
                    Validators.parseFlexibleNumber(line.rateController.text) ??
                    0;
                final total = qty * rate;
                subtotal += total;
                final item = itemById(line.itemId);
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

    return buildManagedDocumentPrintData(
      companies: companies,
      companyId: companyId,
      company: company,
      documentNumber: nullIfEmpty(deliveryNoController.text) ?? 'Draft',
      documentDate: deliveryDateController.text.trim(),
      partyName: customer?.partyName ?? '',
      partyAddress: formatPartyAddress(preferredAddress),
      partyContact: resolvePartyContact(customer),
      partyGstin: resolvePreferredPartyGstin(
        customerGstDetailsById[customerPartyId] ??
            const <PartyGstDetailModel>[],
        sourceData: selected['customer'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(
                selected['customer'] as Map<String, dynamic>,
              )
            : const <String, dynamic>{},
      ),
      notes: notesController.text.trim(),
      termsConditions: termsController.text.trim(),
      subtotal: roundToDouble(subtotal, 2),
      taxAmount: 0,
      totalAmount: roundToDouble(subtotal, 2),
      currencyCode: 'INR',
      lines: printLines,
    );
  }

  Future<void> openPrintPreview(BuildContext context) async {
    await openManagedDocumentPrintPreview(
      context,
      prepare: () => ensureCustomerPrintContext(customerPartyId),
      documentType: printDocumentType,
      title: isReturnableDc
          ? 'Returnable Delivery Challan'
          : 'Delivery Challan',
      documentDataBuilder: salesDeliveryPrintData,
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

  void setApplyRoundOff(bool value) {
    applyRoundOff = value;
    if (value) {
      _syncAutoRoundOff();
    } else {
      roundOffController.clear();
    }
    update();
  }

  void addLine() {
    lines = List<SalesDeliveryLineDraft>.from(lines)
      ..add(SalesDeliveryLineDraft());
    refreshLineItemsSection();
  }

  void removeLine(int index) {
    final next = List<SalesDeliveryLineDraft>.from(lines);
    next.removeAt(index);
    _replaceLines(next);
  }

  void _replaceLines(
    List<SalesDeliveryLineDraft> nextLines, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<SalesDeliveryLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => SalesDeliveryLineDraft(),
      assign: (entries) => lines = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify ? refreshLineItemsSection : null,
    );
  }

  void addReturnableDc() {
    returnableDcs = List<SalesDeliveryReturnableDcDraft>.from(returnableDcs)
      ..add(SalesDeliveryReturnableDcDraft());
    refreshLineItemsSection();
  }

  void removeReturnableDc(int index) {
    final next = List<SalesDeliveryReturnableDcDraft>.from(returnableDcs);
    next.removeAt(index);
    _replaceReturnableDcs(next);
  }

  void _replaceReturnableDcs(
    List<SalesDeliveryReturnableDcDraft> nextValues, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<SalesDeliveryReturnableDcDraft>(
      previous: returnableDcs,
      next: nextValues,
      createEmpty: () => SalesDeliveryReturnableDcDraft(),
      assign: (entries) => returnableDcs = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify ? refreshLineItemsSection : null,
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

  void setDeliveryKind(String? value) {
    final next = (value ?? 'dc').trim().toLowerCase();
    deliveryKind = next == 'rdc' ? 'rdc' : 'dc';
    final series = seriesOptions();
    documentSeriesId = series.any((item) => item.id == documentSeriesId)
        ? documentSeriesId
        : (series.isNotEmpty ? series.first.id : null);
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
    final item = itemById(value);
    applySalesLineDefaultsFromItemMaster(
      item: item,
      itemPrices: itemPrices,
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
    refreshLineItemsSection();
  }

  Future<void> setLineWarehouseId(int index, int? value) async {
    final line = lines[index];
    line.warehouseId = value;
    line.batchId = null;
    line.serialNumbers = <String>[];
    line.serialNoController.clear();
    refreshLineItemsSection();
    await syncBatchOptionsForLine(line);
    await syncSerialOptionsForLine(line);
  }

  Future<void> setLineBatchId(int index, int? value) async {
    final line = lines[index];
    line.batchId = value;
    line.serialNumbers = <String>[];
    line.serialNoController.clear();
    refreshLineItemsSection();
    await syncSerialOptionsForLine(line);
  }

  void setLineUomId(int index, int? value) {
    lines[index].uomId = value;
    refreshLineItemsSection();
  }

  void setReturnableDcItemId(int index, int? value) {
    final row = returnableDcs[index];
    row.itemId = value;
    if (value != null) {
      row.itemNameController.clear();
    }
    row.uomId = defaultUomIdForItemId(value, current: row.uomId);
    refreshLineItemsSection();
  }

  void setReturnableDcUomId(int index, int? value) {
    returnableDcs[index].uomId = value;
    refreshLineItemsSection();
  }

  void refreshState() {
    _syncAutoRoundOff();
    refreshLineItemsSection();
  }

  Future<void> save(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    syncInventoryOptionsForLines(lines);
    if (deliveryKind == 'dc') {
      if (lines.any(
        (line) =>
            line.itemId == null ||
            line.uomId == null ||
            line.warehouseId == null ||
            (Validators.parseFlexibleNumber(line.deliveredQtyController.text) ??
                    0) <=
                0,
      )) {
        formError =
            'Each line needs item, warehouse, UOM, and delivered quantity.';
        update();
        return;
      }
    } else {
      if (returnableDcs.any(
        (row) =>
            (row.itemId == null &&
                row.itemNameController.text.trim().isEmpty) ||
            row.uomId == null ||
            (Validators.parseFlexibleNumber(row.qtyController.text) ?? 0) <= 0,
      )) {
        formError =
            'Each returnable DC row needs an item or new item name, UOM, and quantity.';
        update();
        return;
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
      'sales_order_id': salesOrderId,
      'delivery_no': nullIfEmpty(deliveryNoController.text),
      'delivery_date': deliveryDateController.text.trim(),
      'customer_party_id': customerPartyId,
      'transporter_party_id': transporterPartyId,
      'vehicle_no': nullIfEmpty(vehicleNoController.text),
      'lr_no': nullIfEmpty(lrNoController.text),
      'lr_date': nullIfEmpty(lrDateController.text),
      'round_off_amount': applyRoundOff
          ? (Validators.parseFlexibleNumber(roundOffController.text.trim()) ??
                0)
          : 0,
      'delivery_kind': deliveryKind,
      'notes': nullIfEmpty(notesController.text),
      'terms_conditions': nullIfEmpty(termsController.text),
      'is_active': isActive,
      'lines': deliveryKind == 'rdc'
          ? const <Map<String, dynamic>>[]
          : linesForSave(),
      'returnable_dcs': deliveryKind == 'rdc'
          ? returnableDcsForSave()
          : const <Map<String, dynamic>>[],
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
      _refreshController.notifyChanged(source: 'sales_delivery');
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
      _refreshController.notifyChanged(source: 'sales_delivery');
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

  void _disposeReturnableDcs(List<SalesDeliveryReturnableDcDraft> values) {
    for (final row in values) {
      row.dispose();
    }
  }
}
