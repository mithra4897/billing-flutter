import 'dart:math' as math;

import '../../../screen.dart';
import 'inventory_module_refresh_controller.dart';

const List<AppDropdownItem<String>> produceTrackingFlowItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'sales_delivery', label: 'Sales Delivery'),
      AppDropdownItem(value: 'purchase_order', label: 'Purchase Order'),
    ];

const List<AppDropdownItem<String>> produceTrackingAssignedTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'employee', label: 'Employee'),
      AppDropdownItem(value: 'supplier', label: 'Supplier'),
    ];

const List<AppDropdownItem<String>> produceTrackingStatusItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'draft', label: 'Draft'),
      AppDropdownItem(value: 'ready_to_dispatch', label: 'Ready To Dispatch'),
      AppDropdownItem(value: 'dispatched', label: 'Dispatched'),
      AppDropdownItem(value: 'in_transit', label: 'In Transit'),
      AppDropdownItem(
        value: 'reached_destination',
        label: 'Reached Destination',
      ),
      AppDropdownItem(value: 'delivered', label: 'Delivered'),
      AppDropdownItem(value: 'returned', label: 'Returned'),
      AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
    ];

const List<AppDropdownItem<String>> produceTrackingDestinationTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'customer', label: 'Customer'),
      AppDropdownItem(value: 'supplier', label: 'Supplier'),
      AppDropdownItem(value: 'branch', label: 'Branch'),
      AppDropdownItem(value: 'warehouse', label: 'Warehouse'),
      AppDropdownItem(value: 'job_site', label: 'Job Site'),
      AppDropdownItem(value: 'other', label: 'Other'),
    ];

const List<AppDropdownItem<String>> produceTrackingLineStatusItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'open', label: 'Open'),
      AppDropdownItem(value: 'in_transit', label: 'In Transit'),
      AppDropdownItem(value: 'delivered', label: 'Delivered'),
      AppDropdownItem(value: 'returned', label: 'Returned'),
      AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
    ];

class ProduceTrackingLineDraft {
  ProduceTrackingLineDraft({
    this.id,
    this.salesDeliveryLineId,
    this.purchaseOrderLineId,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.batchId,
    this.serialId,
    this.lineStatus = 'open',
    String? trackedQty,
    String? deliveredQty,
    String? receivedQty,
    String? balanceQty,
    String? currentLocation,
    String? remarks,
  }) : trackedQtyController = TextEditingController(text: trackedQty ?? ''),
       deliveredQtyController = TextEditingController(text: deliveredQty ?? ''),
       receivedQtyController = TextEditingController(text: receivedQty ?? ''),
       balanceQtyController = TextEditingController(text: balanceQty ?? ''),
       currentLocationController = TextEditingController(
         text: currentLocation ?? '',
       ),
       remarksController = TextEditingController(text: remarks ?? '') {
    trackedQtyController.addListener(_syncBalanceQty);
    deliveredQtyController.addListener(_syncBalanceQty);
    receivedQtyController.addListener(_syncBalanceQty);
    _syncBalanceQty();
  }

  int? id;
  int? salesDeliveryLineId;
  int? purchaseOrderLineId;
  int? itemId;
  int? warehouseId;
  int? uomId;
  int? batchId;
  int? serialId;
  String lineStatus;
  final TextEditingController trackedQtyController;
  final TextEditingController deliveredQtyController;
  final TextEditingController receivedQtyController;
  final TextEditingController balanceQtyController;
  final TextEditingController currentLocationController;
  final TextEditingController remarksController;

  void _syncBalanceQty() {
    final trackedQty =
        Validators.parseFlexibleNumber(trackedQtyController.text) ?? 0;
    final deliveredQty =
        Validators.parseFlexibleNumber(deliveredQtyController.text) ?? 0;
    final receivedQty =
        Validators.parseFlexibleNumber(receivedQtyController.text) ?? 0;
    final balanceQty = math
        .max(trackedQty - math.max(deliveredQty, receivedQty), 0)
        .toDouble();
    final nextValue = _formatQty(balanceQty);
    if (balanceQtyController.text == nextValue) {
      return;
    }
    balanceQtyController.text = nextValue;
  }

  String _formatQty(double value) {
    return formatQuantity(value);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'sales_delivery_line_id': salesDeliveryLineId,
    'purchase_order_line_id': purchaseOrderLineId,
    'item_id': itemId,
    'warehouse_id': warehouseId,
    'uom_id': uomId,
    'batch_id': batchId,
    'serial_id': serialId,
    'tracked_qty':
        Validators.parseFlexibleNumber(trackedQtyController.text) ?? 0,
    'delivered_qty':
        Validators.parseFlexibleNumber(deliveredQtyController.text) ?? 0,
    'received_qty':
        Validators.parseFlexibleNumber(receivedQtyController.text) ?? 0,
    'balance_qty':
        Validators.parseFlexibleNumber(balanceQtyController.text) ?? 0,
    'line_status': lineStatus,
    'current_location': nullIfEmpty(currentLocationController.text),
    'remarks': nullIfEmpty(remarksController.text),
  };

  void dispose() {
    trackedQtyController.dispose();
    deliveredQtyController.dispose();
    receivedQtyController.dispose();
    balanceQtyController.dispose();
    currentLocationController.dispose();
    remarksController.dispose();
  }
}

class ProduceTrackingViewModel extends GetxController {
  ProduceTrackingViewModel({this.initialId}) {
    searchController.addListener(update);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  static const List<AppDropdownItem<String>> listStatusFilter =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        ...produceTrackingStatusItems,
      ];

  final int? initialId;
  final InventoryService _inventoryService = InventoryService();
  final SalesService _salesService = SalesService();
  final PurchaseService _purchaseService = PurchaseService();
  final HrService _hrService = HrService();
  final InventoryModuleRefreshController _refreshController =
      InventoryModuleRefreshController.ensureRegistered();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController trackingNoController = TextEditingController();
  final TextEditingController trackingDateController = TextEditingController();
  final TextEditingController destinationLocationController =
      TextEditingController();
  final TextEditingController destinationAddressController =
      TextEditingController();
  final TextEditingController vehicleNoController = TextEditingController();
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController driverPhoneController = TextEditingController();
  final TextEditingController lrNoController = TextEditingController();
  final TextEditingController lrDateController = TextEditingController();
  final TextEditingController currentLocationController =
      TextEditingController();
  final TextEditingController currentLatitudeController =
      TextEditingController();
  final TextEditingController currentLongitudeController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<ProduceTrackingModel> rows = const <ProduceTrackingModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<StockBatchModel> batches = const <StockBatchModel>[];
  List<StockSerialModel> serials = const <StockSerialModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];
  List<TransporterModel> transporters = const <TransporterModel>[];
  List<SalesDeliveryModel> salesDeliveries = const <SalesDeliveryModel>[];
  List<PurchaseOrderModel> purchaseOrders = const <PurchaseOrderModel>[];
  ProduceTrackingModel? selected;
  ProduceTrackingModel? selectedDetail;

  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? salesDeliveryId;
  int? purchaseOrderId;
  int? sourceWarehouseId;
  int? assignedEmployeeId;
  int? assignedSupplierPartyId;
  int? destinationPartyId;
  int? destinationWarehouseId;
  int? transporterId;
  String referenceFlow = 'sales_delivery';
  String assignedToType = 'employee';
  String destinationType = 'customer';
  String trackingStatus = 'draft';
  String statusFilter = '';
  bool isActive = true;
  List<ProduceTrackingLineDraft> lines = <ProduceTrackingLineDraft>[];
  bool _initialized = false;
  int? _lastRequestedSelectId;

  void _handleWorkingContextChanged() {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    unawaited(load(selectId: id));
  }

  String get status => selected == null
      ? trackingStatus
      : stringValue(selected!.toJson(), 'tracking_status', trackingStatus);

  List<BranchModel> get branchOptions =>
      branchesForCompany(branches, companyId);

  List<BusinessLocationModel> get locationOptions =>
      locationsForBranch(locations, branchId);

  List<String> get contextLabels => workingContextLabels(
    companies: companies,
    branches: branches,
    locations: locations,
    financialYears: financialYears,
    companyId: companyId,
    branchId: branchId,
    locationId: locationId,
    financialYearId: financialYearId,
  );

  List<WarehouseModel> get warehouseOptions => warehouses
      .where((w) {
        if (w.id == null) {
          return false;
        }
        if (companyId != null && w.companyId != companyId) {
          return false;
        }
        if (branchId != null && w.branchId != branchId) {
          return false;
        }
        if (locationId != null && w.locationId != locationId) {
          return false;
        }
        return true;
      })
      .toList(growable: false);

  List<DocumentSeriesModel> get seriesOptions => documentSeriesForContext(
    documentSeries: documentSeries,
    documentType: 'PRODUCE_TRACKING',
    companyId: companyId,
    branchId: branchId,
    locationId: locationId,
    financialYearId: financialYearId,
  );

  List<AppDropdownItem<int>> get salesDeliveryDropdownItems => salesDeliveries
      .where((row) => row.id != null)
      .map(
        (row) => AppDropdownItem<int>(
          value: row.id!,
          label: JsonModel.combineValues([
            stringValue(row.toJson(), 'delivery_no'),
            displayDate(nullableStringValue(row.toJson(), 'delivery_date')),
          ], defaultValue: 'Delivery'),
        ),
      )
      .toList(growable: false);

  List<AppDropdownItem<int>> get purchaseOrderDropdownItems => purchaseOrders
      .where((row) => row.id != null)
      .map(
        (row) => AppDropdownItem<int>(
          value: row.id!,
          label: JsonModel.combineValues([
            stringValue(row.toJson(), 'order_no'),
            displayDate(nullableStringValue(row.toJson(), 'order_date')),
          ], defaultValue: 'Purchase Order'),
        ),
      )
      .toList(growable: false);

  List<AppDropdownItem<int>> get partyDropdownItems => parties
      .where((row) => row.id != null)
      .map((row) => AppDropdownItem<int>(value: row.id!, label: row.toString()))
      .toList(growable: false);

  List<PartyModel> get supplierOptions => parties
      .where((row) {
        if (!row.isActive) {
          return false;
        }
        final name = (row.partyName ?? row.displayName ?? '').toLowerCase();
        return name.isNotEmpty;
      })
      .toList(growable: false);

  List<AppDropdownItem<int>> get supplierDropdownItems => supplierOptions
      .where((row) => row.id != null)
      .map((row) => AppDropdownItem<int>(value: row.id!, label: row.toString()))
      .toList(growable: false);

  List<AppDropdownItem<int>> get employeeDropdownItems => employees
      .where(
        (row) =>
            row.id != null &&
            (row.status == null ||
                row.status!.toLowerCase() == 'active' ||
                row.status!.toLowerCase() == 'working'),
      )
      .map((row) => AppDropdownItem<int>(value: row.id!, label: row.toString()))
      .toList(growable: false);

  List<AppDropdownItem<int>> get transporterDropdownItems => transporters
      .where((row) => row.id != null && row.isActive)
      .map((row) => AppDropdownItem<int>(value: row.id!, label: row.toString()))
      .toList(growable: false);

  List<ProduceTrackingModel> get filteredRows {
    final fromDate = tryParseCalendarDate(dateFromController.text.trim());
    final toDate = tryParseCalendarDate(dateToController.text.trim());
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          final rowStatus = stringValue(data, 'tracking_status');
          if (statusFilter.isNotEmpty && rowStatus != statusFilter) {
            return false;
          }
          final trackingDate = tryParseCalendarDate(
            nullableStringValue(data, 'tracking_date') ?? '',
          );
          if (fromDate != null &&
              (trackingDate == null || trackingDate.isBefore(fromDate))) {
            return false;
          }
          if (toDate != null &&
              (trackingDate == null || trackingDate.isAfter(toDate))) {
            return false;
          }
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'tracking_no'),
            stringValue(data, 'tracking_status'),
            stringValue(data, 'reference_flow'),
            stringValue(data, 'vehicle_no'),
            stringValue(data, 'current_location'),
            stringValue(data, 'destination_location'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  List<ProduceTrackingModel> get filteredItems => filteredRows;
  ProduceTrackingModel? get selectedItem => selected;

  Future<void> initialize({int? initialId, bool editorOnly = false}) async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _lastRequestedSelectId = initialId ?? this.initialId;
    await load(selectId: _lastRequestedSelectId);
  }

  Future<void> reloadLastRequestedPage() {
    return load(selectId: _lastRequestedSelectId ?? initialId);
  }

  void applyFilters() {
    update();
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  ItemModel? itemById(int? itemId) {
    if (itemId == null) {
      return null;
    }
    for (final item in items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  TransporterModel? transporterById(int? transporterId) {
    if (transporterId == null) {
      return null;
    }
    for (final transporter in transporters) {
      if (transporter.id == transporterId) {
        return transporter;
      }
    }
    return null;
  }

  bool get showTransportDetails {
    final type = transporterById(transporterId)?.transporterType;
    return type == 'courier' || type == 'third_party' || type == 'own_vehicle';
  }

  bool itemHasBatch(int? itemId) => itemById(itemId)?.hasBatch ?? false;

  bool itemHasSerial(int? itemId) => itemById(itemId)?.hasSerial ?? false;

  List<UomModel> uomOptionsForItem(int? itemId) {
    if (itemId == null) {
      return const <UomModel>[];
    }
    return allowedUomsForItem(itemById(itemId), uoms, uomConversions);
  }

  List<Map<String, dynamic>> batchOptionsForLine(
    ProduceTrackingLineDraft line,
  ) {
    return batches
        .map((e) => e.toJson())
        .where((batch) {
          final itemOk =
              line.itemId == null || intValue(batch, 'item_id') == line.itemId;
          final warehouseOk =
              line.warehouseId == null ||
              intValue(batch, 'warehouse_id') == line.warehouseId;
          return itemOk && warehouseOk;
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> serialOptionsForLine(
    ProduceTrackingLineDraft line,
  ) {
    return serials
        .map((e) => e.toJson())
        .where((serial) {
          final itemOk =
              line.itemId == null || intValue(serial, 'item_id') == line.itemId;
          final warehouseOk =
              line.warehouseId == null ||
              intValue(serial, 'warehouse_id') == line.warehouseId;
          final batchOk =
              line.batchId == null ||
              intValue(serial, 'batch_id') == line.batchId;
          final status = stringValue(serial, 'status');
          return itemOk &&
              warehouseOk &&
              batchOk &&
              (status == 'available' || status == 'returned');
        })
        .toList(growable: false);
  }

  Future<void> load({int? selectId}) async {
    _lastRequestedSelectId = selectId;
    loading = true;
    pageError = null;
    update();
    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait<dynamic>([
        _inventoryService.produceTrackings(
          filters: const {'per_page': 200, 'sort_by': 'tracking_date'},
        ),
        _inventoryService.stockBatches(filters: const {'per_page': 500}),
        _inventoryService.stockSerials(filters: const {'per_page': 500}),
        _hrService.employees(filters: const {'per_page': 500}),
        _inventoryService.transporters(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _salesService.deliveries(
          filters: const {'per_page': 300, 'sort_by': 'delivery_date'},
        ),
        _purchaseService.orders(
          filters: const {'per_page': 300, 'sort_by': 'order_date'},
        ),
      ]);

      rows =
          (responses[0] as PaginatedResponse<ProduceTrackingModel>).data ??
          const <ProduceTrackingModel>[];
      companies = cache.activeCompanies;
      branches = cache.activeBranches;
      locations = cache.activeLocations;
      financialYears = cache.activeFinancialYears;
      documentSeries = cache.activeDocumentSeries;
      warehouses = cache.activeWarehouses;
      items = cache.activeItems;
      uoms = cache.activeUoms;
      uomConversions = cache.activeUomConversions;
      batches =
          (responses[1] as PaginatedResponse<StockBatchModel>).data ??
          const <StockBatchModel>[];
      serials =
          (responses[2] as PaginatedResponse<StockSerialModel>).data ??
          const <StockSerialModel>[];
      parties = cache.activeParties;
      employees =
          (responses[3] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];
      transporters =
          ((responses[4] as PaginatedResponse<TransporterModel>).data ??
                  const <TransporterModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      salesDeliveries =
          (responses[5] as PaginatedResponse<SalesDeliveryModel>).data ??
          const <SalesDeliveryModel>[];
      purchaseOrders =
          (responses[6] as PaginatedResponse<PurchaseOrderModel>).data ??
          const <PurchaseOrderModel>[];

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies,
            branches: branches,
            locations: locations,
            financialYears: financialYears,
          );
      companyId = contextSelection.companyId;
      branchId = contextSelection.branchId;
      locationId = contextSelection.locationId;
      financialYearId = contextSelection.financialYearId;
      loading = false;

      if (await restoreSelectionAfterReload<ProduceTrackingModel>(
        selectId: selectId ?? initialId,
        rows: rows,
        selected: selected,
        onSelect: select,
        replaceRows: (nextRows) => rows = nextRows,
        notify: update,
      )) {
        return;
      }

      resetDraft();
      update();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      update();
    }
  }

  void resetDraft() {
    selected = null;
    selectedDetail = null;
    formError = null;
    final now = displayTodayDate();
    trackingNoController.clear();
    trackingDateController.text = now;
    destinationLocationController.clear();
    destinationAddressController.clear();
    vehicleNoController.clear();
    driverNameController.clear();
    driverPhoneController.clear();
    lrNoController.clear();
    lrDateController.clear();
    currentLocationController.clear();
    currentLatitudeController.clear();
    currentLongitudeController.clear();
    remarksController.clear();
    _ensureContextSelection();
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    referenceFlow = 'sales_delivery';
    assignedToType = 'employee';
    assignedEmployeeId = null;
    assignedSupplierPartyId = null;
    destinationType = 'customer';
    trackingStatus = 'draft';
    salesDeliveryId = null;
    purchaseOrderId = null;
    sourceWarehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    destinationPartyId = null;
    destinationWarehouseId = null;
    transporterId = null;
    isActive = true;
    _replaceLines(<ProduceTrackingLineDraft>[ProduceTrackingLineDraft()]);
    update();
  }

  void _ensureContextSelection() {
    if (!containsMasterId(companies, companyId, (item) => item.id)) {
      companyId = companies.isNotEmpty ? companies.first.id : null;
    }
    final scopedBranches = branchOptions;
    if (!containsMasterId(scopedBranches, branchId, (item) => item.id)) {
      branchId = scopedBranches.isNotEmpty ? scopedBranches.first.id : null;
    }
    final scopedLocations = locationOptions;
    if (!containsMasterId(scopedLocations, locationId, (item) => item.id)) {
      locationId = scopedLocations.isNotEmpty ? scopedLocations.first.id : null;
    }
    financialYearId = defaultFinancialYearIdForCompany(
      financialYears,
      companyId,
      current: financialYearId,
    );
  }

  Future<void> select(ProduceTrackingModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _inventoryService.produceTracking(id);
      final data = (response.data ?? row).toJson();
      selectedDetail = response.data ?? row;
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      documentSeriesId = intValue(data, 'document_series_id');
      salesDeliveryId = intValue(data, 'sales_delivery_id');
      purchaseOrderId = intValue(data, 'purchase_order_id');
      sourceWarehouseId = intValue(data, 'source_warehouse_id');
      assignedToType = stringValue(data, 'assigned_to_type', 'employee');
      assignedEmployeeId = intValue(data, 'assigned_employee_id');
      assignedSupplierPartyId = intValue(data, 'assigned_supplier_party_id');
      destinationPartyId = intValue(data, 'destination_party_id');
      destinationWarehouseId = intValue(data, 'destination_warehouse_id');
      transporterId = intValue(data, 'transporter_id');
      referenceFlow = stringValue(data, 'reference_flow', 'sales_delivery');
      destinationType = stringValue(data, 'destination_type', 'customer');
      trackingStatus = stringValue(data, 'tracking_status', 'draft');
      isActive = boolValue(data, 'is_active', fallback: true);

      trackingNoController.text = stringValue(data, 'tracking_no');
      trackingDateController.text = displayDate(
        nullableStringValue(data, 'tracking_date'),
      );
      destinationLocationController.text = stringValue(
        data,
        'destination_location',
      );
      destinationAddressController.text = stringValue(
        data,
        'destination_address',
      );
      vehicleNoController.text = stringValue(data, 'vehicle_no');
      driverNameController.text = stringValue(data, 'driver_name');
      driverPhoneController.text = stringValue(data, 'driver_phone');
      lrNoController.text = stringValue(data, 'lr_no');
      lrDateController.text = displayDate(nullableStringValue(data, 'lr_date'));
      currentLocationController.text = stringValue(data, 'current_location');
      currentLatitudeController.text = stringValue(data, 'current_latitude');
      currentLongitudeController.text = stringValue(data, 'current_longitude');
      remarksController.text = stringValue(data, 'remarks');

      final apiLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      _replaceLines(
        apiLines.isEmpty
            ? <ProduceTrackingLineDraft>[ProduceTrackingLineDraft()]
            : apiLines
                  .map(
                    (line) => ProduceTrackingLineDraft(
                      id: intValue(line, 'id'),
                      salesDeliveryLineId: intValue(
                        line,
                        'sales_delivery_line_id',
                      ),
                      purchaseOrderLineId: intValue(
                        line,
                        'purchase_order_line_id',
                      ),
                      itemId: intValue(line, 'item_id'),
                      warehouseId: intValue(line, 'warehouse_id'),
                      uomId: intValue(line, 'uom_id'),
                      batchId: intValue(line, 'batch_id'),
                      serialId: intValue(line, 'serial_id'),
                      lineStatus: stringValue(line, 'line_status', 'open'),
                      trackedQty: stringValue(line, 'tracked_qty'),
                      deliveredQty: stringValue(line, 'delivered_qty'),
                      receivedQty: stringValue(line, 'received_qty'),
                      balanceQty: stringValue(line, 'balance_qty'),
                      currentLocation: stringValue(line, 'current_location'),
                      remarks: stringValue(line, 'remarks'),
                    ),
                  )
                  .toList(growable: true),
      );
      detailLoading = false;
      update();
    } catch (e) {
      detailLoading = false;
      formError = e.toString();
      update();
    }
  }

  Future<void> selectDocument(ProduceTrackingModel row) {
    return select(row);
  }

  void _replaceLines(List<ProduceTrackingLineDraft> nextLines) {
    replaceDisposableDraftEntries<ProduceTrackingLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => ProduceTrackingLineDraft(),
      assign: (entries) => lines = entries,
      dispose: (entry) => entry.dispose(),
      notify: update,
    );
  }

  void onReferenceFlowChanged(String? value) {
    referenceFlow = value ?? 'sales_delivery';
    if (referenceFlow == 'sales_delivery') {
      purchaseOrderId = null;
    } else if (referenceFlow == 'purchase_order') {
      salesDeliveryId = null;
    }
    update();
  }

  Future<void> onSalesDeliveryChanged(int? value) async {
    salesDeliveryId = value;
    if (value == null) {
      update();
      return;
    }
    await _applySalesDeliveryReference(value);
    update();
  }

  Future<void> onPurchaseOrderChanged(int? value) async {
    purchaseOrderId = value;
    if (value == null) {
      update();
      return;
    }
    await _applyPurchaseOrderReference(value);
    update();
  }

  Future<void> _applySalesDeliveryReference(int id) async {
    try {
      final response = await _salesService.delivery(id);
      final delivery = response.data;
      if (delivery == null) {
        return;
      }

      companyId = delivery.companyId ?? companyId;
      branchId = delivery.branchId ?? branchId;
      locationId = delivery.locationId ?? locationId;
      financialYearId = delivery.financialYearId ?? financialYearId;
      sourceWarehouseId =
          delivery.lines.firstWhere(
                (line) => line['warehouse_id'] != null,
                orElse: () => const <String, dynamic>{},
              )['warehouse_id']
              as int? ??
          sourceWarehouseId;
      destinationType = 'customer';
      destinationPartyId = delivery.customerPartyId ?? destinationPartyId;
      vehicleNoController.text = delivery.vehicleNo ?? vehicleNoController.text;
      lrNoController.text = delivery.lrNo ?? lrNoController.text;
      lrDateController.text = delivery.lrDate ?? lrDateController.text;

      final mappedLines = delivery.lines
          .map(
            (line) => ProduceTrackingLineDraft(
              salesDeliveryLineId: intValue(line, 'id'),
              itemId: intValue(line, 'item_id'),
              warehouseId: intValue(line, 'warehouse_id') ?? sourceWarehouseId,
              uomId: intValue(line, 'uom_id'),
              batchId: intValue(line, 'batch_id'),
              serialId: intValue(line, 'serial_id'),
              trackedQty: _stringQty(
                double.tryParse(line['delivered_qty']?.toString() ?? '') ?? 0,
              ),
              deliveredQty: _stringQty(
                double.tryParse(line['delivered_qty']?.toString() ?? '') ?? 0,
              ),
              receivedQty: '0',
              balanceQty: _stringQty(
                double.tryParse(line['delivered_qty']?.toString() ?? '') ?? 0,
              ),
              remarks: stringValue(line, 'remarks'),
            ),
          )
          .toList(growable: true);
      if (mappedLines.isNotEmpty) {
        _replaceLines(mappedLines);
      }
    } catch (e) {
      formError = e.toString();
    }
  }

  Future<void> _applyPurchaseOrderReference(int id) async {
    try {
      final response = await _purchaseService.order(id);
      final order = response.data;
      if (order == null) {
        return;
      }

      companyId = order.companyId ?? companyId;
      branchId = order.branchId ?? branchId;
      locationId = order.locationId ?? locationId;
      financialYearId = order.financialYearId ?? financialYearId;
      assignedToType = 'supplier';
      assignedSupplierPartyId =
          order.supplierPartyId ?? assignedSupplierPartyId;
      destinationType = 'warehouse';
      destinationPartyId = null;
      sourceWarehouseId =
          order.lines
              .firstWhere(
                (line) => line.warehouseId != null,
                orElse: () => const PurchaseOrderLineModel(),
              )
              .warehouseId ??
          sourceWarehouseId;

      final mappedLines = order.lines
          .map(
            (line) => ProduceTrackingLineDraft(
              purchaseOrderLineId: line.id,
              itemId: line.itemId,
              warehouseId: line.warehouseId ?? sourceWarehouseId,
              uomId: line.uomId,
              trackedQty: _stringQty(line.pendingQty ?? line.orderedQty ?? 0),
              deliveredQty: '0',
              receivedQty: '0',
              balanceQty: _stringQty(line.pendingQty ?? line.orderedQty ?? 0),
              remarks: line.remarks,
            ),
          )
          .toList(growable: true);
      if (mappedLines.isNotEmpty) {
        _replaceLines(mappedLines);
      }
    } catch (e) {
      formError = e.toString();
    }
  }

  String _stringQty(double value) {
    return formatQuantity(value);
  }

  void onSourceWarehouseChanged(int? value) {
    sourceWarehouseId = value;
    for (final line in lines) {
      line.warehouseId = value;
      line.batchId = null;
      line.serialId = null;
    }
    update();
  }

  void onAssignedToTypeChanged(String? value) {
    assignedToType = value ?? 'employee';
    if (assignedToType == 'employee') {
      assignedSupplierPartyId = null;
    } else {
      assignedEmployeeId = null;
    }
    update();
  }

  void onAssignedEmployeeChanged(int? value) {
    assignedEmployeeId = value;
    update();
  }

  void onAssignedSupplierChanged(int? value) {
    assignedSupplierPartyId = value;
    update();
  }

  void onDestinationTypeChanged(String? value) {
    destinationType = value ?? 'customer';
    update();
  }

  void onDestinationPartyChanged(int? value) {
    destinationPartyId = value;
    update();
  }

  void onDestinationWarehouseChanged(int? value) {
    destinationWarehouseId = value;
    update();
  }

  void onTransporterChanged(int? value) {
    transporterId = value;
    if (!showTransportDetails) {
      vehicleNoController.clear();
      driverNameController.clear();
      driverPhoneController.clear();
      lrNoController.clear();
      lrDateController.clear();
      currentLocationController.clear();
      currentLatitudeController.clear();
      currentLongitudeController.clear();
    }
    update();
  }

  void onTrackingStatusChanged(String? value) {
    trackingStatus = value ?? 'draft';
    update();
  }

  void onIsActiveChanged(bool value) {
    isActive = value;
    update();
  }

  void addLine() {
    lines = List<ProduceTrackingLineDraft>.from(lines)
      ..add(ProduceTrackingLineDraft(warehouseId: sourceWarehouseId));
    update();
  }

  void removeLine(int index) {
    if (index < 0 || index >= lines.length) {
      return;
    }
    final next = List<ProduceTrackingLineDraft>.from(lines);
    next.removeAt(index);
    _replaceLines(next);
  }

  void onLineItemChanged(int index, int? value) {
    lines[index].itemId = value;
    lines[index].batchId = null;
    lines[index].serialId = null;
    lines[index].uomId = defaultUomIdForItem(
      itemById(value),
      uoms,
      uomConversions,
      current: lines[index].uomId,
    );
    update();
  }

  void onLineWarehouseChanged(int index, int? value) {
    lines[index].warehouseId = value;
    lines[index].batchId = null;
    lines[index].serialId = null;
    update();
  }

  void onLineUomChanged(int index, int? value) {
    lines[index].uomId = value;
    update();
  }

  void onLineBatchChanged(int index, int? value) {
    lines[index].batchId = value;
    lines[index].serialId = null;
    update();
  }

  void onLineSerialChanged(int index, int? value) {
    lines[index].serialId = value;
    update();
  }

  void onLineStatusChanged(int index, String? value) {
    lines[index].lineStatus = value ?? 'open';
    update();
  }

  String? _validate() {
    if (companyId == null ||
        branchId == null ||
        locationId == null ||
        financialYearId == null) {
      return 'Company, branch, location, and financial year are required.';
    }
    if (documentSeriesId == null && trackingNoController.text.trim().isEmpty) {
      return 'Either tracking number or document series is required.';
    }
    if (trackingDateController.text.trim().isEmpty) {
      return 'Tracking date is required.';
    }
    if (referenceFlow == 'sales_delivery' && salesDeliveryId == null) {
      return 'Sales delivery is required.';
    }
    if (referenceFlow == 'purchase_order' && purchaseOrderId == null) {
      return 'Purchase order is required.';
    }
    if (sourceWarehouseId == null) {
      return 'Source warehouse is required.';
    }
    if (assignedToType == 'employee' && assignedEmployeeId == null) {
      return 'Assigned employee is required.';
    }
    if (assignedToType == 'supplier' && assignedSupplierPartyId == null) {
      return 'Assigned supplier is required.';
    }
    if (lines.isEmpty) {
      return 'At least one line is required.';
    }
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNo = i + 1;
      final trackedQty =
          Validators.parseFlexibleNumber(line.trackedQtyController.text) ?? 0;
      final deliveredQty =
          Validators.parseFlexibleNumber(line.deliveredQtyController.text) ?? 0;
      final receivedQty =
          Validators.parseFlexibleNumber(line.receivedQtyController.text) ?? 0;
      if (line.itemId == null ||
          line.warehouseId == null ||
          line.uomId == null) {
        return 'Item, warehouse, and UOM are required at line $lineNo.';
      }
      if (trackedQty <= 0) {
        return 'Tracked quantity must be greater than zero at line $lineNo.';
      }
      if (deliveredQty < 0 || receivedQty < 0) {
        return 'Delivered and received quantity cannot be negative at line $lineNo.';
      }
      if (line.salesDeliveryLineId == null &&
          line.purchaseOrderLineId == null &&
          referenceFlow != 'purchase_order') {
        // allow manual lines only for PO/combined or when user has no delivery line mapping
      }
      if (itemHasBatch(line.itemId) && line.batchId != null) {
        final validBatch = batchOptionsForLine(
          line,
        ).any((batch) => intValue(batch, 'id') == line.batchId);
        if (!validBatch) {
          return 'Invalid batch selected at line $lineNo.';
        }
      }
      if (itemHasSerial(line.itemId) && line.serialId != null) {
        final validSerial = serialOptionsForLine(
          line,
        ).any((serial) => intValue(serial, 'id') == line.serialId);
        if (!validSerial) {
          return 'Invalid serial selected at line $lineNo.';
        }
        if (trackedQty != 1) {
          return 'Serial tracked quantity must be exactly 1 at line $lineNo.';
        }
      }
    }
    return null;
  }

  Future<void> save() async {
    final validationError = _validate();
    if (validationError != null) {
      formError = validationError;
      update();
      return;
    }
    saving = true;
    formError = null;
    actionMessage = null;
    update();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_series_id': documentSeriesId,
      'tracking_no': nullIfEmpty(trackingNoController.text),
      'tracking_date': trackingDateController.text.trim(),
      'reference_flow': referenceFlow,
      'sales_delivery_id': salesDeliveryId,
      'purchase_order_id': purchaseOrderId,
      'source_warehouse_id': sourceWarehouseId,
      'assigned_to_type': assignedToType,
      'assigned_employee_id': assignedEmployeeId,
      'assigned_supplier_party_id': assignedSupplierPartyId,
      'destination_type': destinationType,
      'destination_party_id': destinationPartyId,
      'destination_warehouse_id': destinationWarehouseId,
      'destination_location': nullIfEmpty(destinationLocationController.text),
      'destination_address': nullIfEmpty(destinationAddressController.text),
      'transporter_id': transporterId,
      'vehicle_no': nullIfEmpty(vehicleNoController.text),
      'driver_name': nullIfEmpty(driverNameController.text),
      'driver_phone': nullIfEmpty(driverPhoneController.text),
      'lr_no': nullIfEmpty(lrNoController.text),
      'lr_date': nullIfEmpty(lrDateController.text),
      'tracking_status': trackingStatus,
      'current_location': nullIfEmpty(currentLocationController.text),
      'current_latitude': Validators.parseFlexibleNumber(
        currentLatitudeController.text,
      ),
      'current_longitude': double.tryParse(
        currentLongitudeController.text.trim(),
      ),
      'remarks': nullIfEmpty(remarksController.text),
      'is_active': isActive,
      'lines': lines.map((entry) => entry.toJson()).toList(growable: false),
    };
    try {
      final response = selected == null
          ? await _inventoryService.createProduceTracking(
              normalizeDatePayload(payload),
            )
          : await _inventoryService.updateProduceTracking(
              intValue(selected!.toJson(), 'id')!,
              normalizeDatePayload(payload),
            );
      final id = intValue(
        response.data?.toJson() ?? const <String, dynamic>{},
        'id',
      );
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'produce_tracking');
    } catch (e) {
      formError = e.toString();
      actionMessage = null;
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> post() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _inventoryService.postProduceTracking(
        id,
        ProduceTrackingModel.fromJson(const <String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'produce_tracking');
    } catch (e) {
      formError = e.toString();
      actionMessage = null;
      update();
    }
  }

  Future<void> cancel() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _inventoryService.cancelProduceTracking(
        id,
        ProduceTrackingModel.fromJson(const <String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'produce_tracking');
    } catch (e) {
      formError = e.toString();
      actionMessage = null;
      update();
    }
  }

  Future<void> delete() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _inventoryService.deleteProduceTracking(id);
      actionMessage = response.message;
      await load();
      _refreshController.notifyChanged(source: 'produce_tracking');
    } catch (e) {
      formError = e.toString();
      actionMessage = null;
      update();
    }
  }

  Future<void> updateLocation() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _inventoryService.updateProduceTrackingLocation(
        id,
        <String, dynamic>{
          'current_location': nullIfEmpty(currentLocationController.text),
          'current_latitude': double.tryParse(
            currentLatitudeController.text.trim(),
          ),
          'current_longitude': double.tryParse(
            currentLongitudeController.text.trim(),
          ),
          'tracking_status': trackingStatus,
          'line_locations': lines
              .where((line) => line.id != null)
              .map(
                (line) => <String, dynamic>{
                  'id': line.id,
                  'current_location': nullIfEmpty(
                    line.currentLocationController.text,
                  ),
                  'line_status': line.lineStatus,
                },
              )
              .toList(growable: false),
        },
      );
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'produce_tracking');
    } catch (e) {
      formError = e.toString();
      actionMessage = null;
      update();
    }
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    FocusManager.instance.primaryFocus?.unfocus();
    pageScrollController.dispose();
    workspaceController.dispose();
    disposeChangeNotifiersNextFrame<TextEditingController>([
      searchController,
      dateFromController,
      dateToController,
      trackingNoController,
      trackingDateController,
      destinationLocationController,
      destinationAddressController,
      vehicleNoController,
      driverNameController,
      driverPhoneController,
      lrNoController,
      lrDateController,
      currentLocationController,
      currentLatitudeController,
      currentLongitudeController,
      remarksController,
    ]);
    disposeDraftEntriesNextFrame<ProduceTrackingLineDraft>(
      List<ProduceTrackingLineDraft>.from(lines),
      (entry) => entry.dispose(),
    );
    super.onClose();
  }
}
