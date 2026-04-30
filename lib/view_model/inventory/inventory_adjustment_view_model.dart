import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

const List<AppDropdownItem<String>> inventoryAdjustmentTypeItems = <AppDropdownItem<String>>[
  AppDropdownItem<String>(value: 'increase', label: 'Increase'),
  AppDropdownItem<String>(value: 'decrease', label: 'Decrease'),
  AppDropdownItem<String>(value: 'mixed', label: 'Mixed'),
];

const List<AppDropdownItem<String>> inventoryAdjustmentReasonItems = <AppDropdownItem<String>>[
  AppDropdownItem<String>(value: 'manual_correction', label: 'Manual correction'),
  AppDropdownItem<String>(value: 'system_correction', label: 'System correction'),
  AppDropdownItem<String>(value: 'count_difference', label: 'Count difference'),
  AppDropdownItem<String>(value: 'warehouse_error', label: 'Warehouse error'),
  AppDropdownItem<String>(value: 'data_migration', label: 'Data migration'),
  AppDropdownItem<String>(value: 'other', label: 'Other'),
];

class InventoryAdjustmentLineDraft {
  InventoryAdjustmentLineDraft({
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.uomId,
    String? systemQty,
    String? actualQty,
    String? adjustmentQty,
    String? unitCost,
    String? totalCost,
    this.adjustmentDirection,
    String? remarks,
  })  : systemQtyController = TextEditingController(text: systemQty ?? ''),
        actualQtyController = TextEditingController(text: actualQty ?? ''),
        adjustmentQtyController = TextEditingController(text: adjustmentQty ?? ''),
        unitCostController = TextEditingController(text: unitCost ?? ''),
        totalCostController = TextEditingController(text: totalCost ?? ''),
        remarksController = TextEditingController(text: remarks ?? '');

  int? itemId;
  int? warehouseId;
  int? batchId;
  int? serialId;
  int? uomId;
  String? adjustmentDirection;
  final TextEditingController systemQtyController;
  final TextEditingController actualQtyController;
  final TextEditingController adjustmentQtyController;
  final TextEditingController unitCostController;
  final TextEditingController totalCostController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() {
    final systemQty = double.tryParse(systemQtyController.text.trim()) ?? 0;
    final actualQty = double.tryParse(actualQtyController.text.trim()) ?? 0;
    final adjustmentQtyText = adjustmentQtyController.text.trim();
    final adjustmentQty = adjustmentQtyText.isEmpty
        ? actualQty - systemQty
        : (double.tryParse(adjustmentQtyText) ?? (actualQty - systemQty));
    final direction = adjustmentDirection ?? (adjustmentQty >= 0 ? 'in' : 'out');
    return <String, dynamic>{
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'batch_id': batchId,
      'serial_id': serialId,
      'uom_id': uomId,
      'system_qty': systemQty,
      'actual_qty': actualQty,
      'adjustment_qty': adjustmentQty,
      'unit_cost': double.tryParse(unitCostController.text.trim()) ?? 0,
      'total_cost': double.tryParse(totalCostController.text.trim()),
      'adjustment_direction': direction,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    systemQtyController.dispose();
    actualQtyController.dispose();
    adjustmentQtyController.dispose();
    unitCostController.dispose();
    totalCostController.dispose();
    remarksController.dispose();
  }
}

class InventoryAdjustmentViewModel extends ChangeNotifier {
  InventoryAdjustmentViewModel({this.initialItemId}) {
    searchController.addListener(notifyListeners);
  }

  final int? initialItemId;
  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController adjustmentNoController = TextEditingController();
  final TextEditingController adjustmentDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<InventoryAdjustmentModel> rows = const <InventoryAdjustmentModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<StockBatchModel> batches = const <StockBatchModel>[];
  List<StockSerialModel> serials = const <StockSerialModel>[];

  InventoryAdjustmentModel? selected;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  String adjustmentType = 'mixed';
  String reasonCode = 'manual_correction';
  List<InventoryAdjustmentLineDraft> lines = <InventoryAdjustmentLineDraft>[];

  String get status =>
      stringValue(selected?.toJson() ?? const <String, dynamic>{}, 'adjustment_status', 'draft');

  List<BranchModel> get branchOptions => branchesForCompany(branches, companyId);
  List<BusinessLocationModel> get locationOptions => locationsForBranch(locations, branchId);
  List<WarehouseModel> get warehouseOptions => warehouses.where((w) {
        if (w.id == null) return false;
        if (companyId != null && w.companyId != companyId) return false;
        if (branchId != null && w.branchId != branchId) return false;
        if (locationId != null && w.locationId != locationId) return false;
        return true;
      }).toList(growable: false);

  List<DocumentSeriesModel> get seriesOptions => documentSeries
      .where((d) =>
          (d.documentType == null || d.documentType == 'STOCK_ADJUSTMENT') &&
          (companyId == null || d.companyId == companyId) &&
          (financialYearId == null || d.financialYearId == financialYearId))
      .toList(growable: false);

  List<InventoryAdjustmentModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) return true;
      return [
        stringValue(data, 'adjustment_no'),
        stringValue(data, 'adjustment_status'),
        stringValue(data, 'adjustment_type'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.inventoryAdjustments(filters: const {'per_page': 200, 'sort_by': 'adjustment_date'}),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.branches(filters: const {'per_page': 300}),
        _masterService.businessLocations(filters: const {'per_page': 300}),
        _masterService.financialYears(filters: const {'per_page': 100}),
        _masterService.documentSeries(filters: const {'per_page': 300}),
        _inventoryService.items(filters: const {'per_page': 500, 'sort_by': 'item_name'}),
        _masterService.warehouses(filters: const {'per_page': 300}),
        _inventoryService.uoms(filters: const {'per_page': 300}),
        _inventoryService.uomConversionsAll(
          filters: const {'per_page': 500, 'sort_by': 'from_uom_id'},
        ),
        _inventoryService.stockBatches(filters: const {'per_page': 500}),
        _inventoryService.stockSerials(filters: const {'per_page': 500}),
      ]);
      rows = (responses[0] as PaginatedResponse<InventoryAdjustmentModel>).data ?? const <InventoryAdjustmentModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ?? const <CompanyModel>[]).where((x) => x.isActive).toList(growable: false);
      branches = ((responses[2] as PaginatedResponse<BranchModel>).data ?? const <BranchModel>[]).where((x) => x.isActive).toList(growable: false);
      locations = ((responses[3] as PaginatedResponse<BusinessLocationModel>).data ?? const <BusinessLocationModel>[]).where((x) => x.isActive).toList(growable: false);
      financialYears = ((responses[4] as PaginatedResponse<FinancialYearModel>).data ?? const <FinancialYearModel>[]).where((x) => x.isActive).toList(growable: false);
      documentSeries = ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ?? const <DocumentSeriesModel>[]).where((x) => x.isActive).toList(growable: false);
      items = ((responses[6] as PaginatedResponse<ItemModel>).data ?? const <ItemModel>[]).where((x) => x.isActive).toList(growable: false);
      warehouses = ((responses[7] as PaginatedResponse<WarehouseModel>).data ?? const <WarehouseModel>[]).where((x) => x.isActive).toList(growable: false);
      uoms = ((responses[8] as PaginatedResponse<UomModel>).data ?? const <UomModel>[]).where((x) => x.isActive).toList(growable: false);
      uomConversions = ((responses[9] as PaginatedResponse<UomConversionModel>).data ?? const <UomConversionModel>[]).where((x) => x.isActive).toList(growable: false);
      batches = (responses[10] as PaginatedResponse<StockBatchModel>).data ?? const <StockBatchModel>[];
      serials = (responses[11] as PaginatedResponse<StockSerialModel>).data ?? const <StockSerialModel>[];
      loading = false;
      if (selectId != null) {
        final row = rows.cast<InventoryAdjustmentModel?>().firstWhere(
              (r) => intValue(r?.toJson() ?? const <String, dynamic>{}, 'id') == selectId,
              orElse: () => null,
            );
        if (row != null) {
          await selectRow(row);
          return;
        }
      }
      resetDraft();
      notifyListeners();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  void resetDraft() {
    selected = null;
    formError = null;
    adjustmentNoController.clear();
    adjustmentDateController.text = DateTime.now().toIso8601String().split('T').first;
    remarksController.clear();
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    financialYearId ??= financialYears.isNotEmpty ? financialYears.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    adjustmentType = 'mixed';
    reasonCode = 'manual_correction';
    for (final line in lines) {
      line.dispose();
    }
    lines = <InventoryAdjustmentLineDraft>[
      InventoryAdjustmentLineDraft(
        itemId: initialItemId,
        warehouseId: warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null,
      ),
    ];
    final itemId = initialItemId;
    final item = (() {
      for (final x in items) {
        if (x.id == itemId) return x;
      }
      return null;
    })();
    lines.first.uomId = defaultUomIdForItem(
      item,
      uoms,
      uomConversions,
      current: lines.first.uomId,
    );
    notifyListeners();
  }

  Future<void> selectRow(InventoryAdjustmentModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    notifyListeners();
    try {
      final response = await _inventoryService.inventoryAdjustment(id);
      final data = (response.data ?? row).toJson();
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      documentSeriesId = intValue(data, 'document_series_id');
      adjustmentType = stringValue(data, 'adjustment_type', 'mixed');
      reasonCode = stringValue(data, 'reason_code', 'manual_correction');
      adjustmentNoController.text = stringValue(data, 'adjustment_no');
      adjustmentDateController.text = displayDate(nullableStringValue(data, 'adjustment_date'));
      remarksController.text = stringValue(data, 'remarks');
      for (final line in lines) {
        line.dispose();
      }
      final apiLines = (data['items'] as List<dynamic>? ?? const <dynamic>[]).whereType<Map<String, dynamic>>().toList(growable: false);
      lines = apiLines.isEmpty
          ? <InventoryAdjustmentLineDraft>[InventoryAdjustmentLineDraft()]
          : apiLines
              .map((line) => InventoryAdjustmentLineDraft(
                    itemId: intValue(line, 'item_id'),
                    warehouseId: intValue(line, 'warehouse_id'),
                    batchId: intValue(line, 'batch_id'),
                    serialId: intValue(line, 'serial_id'),
                    uomId: intValue(line, 'uom_id'),
                    systemQty: stringValue(line, 'system_qty'),
                    actualQty: stringValue(line, 'actual_qty'),
                    adjustmentQty: stringValue(line, 'adjustment_qty'),
                    unitCost: stringValue(line, 'unit_cost'),
                    totalCost: stringValue(line, 'total_cost'),
                    adjustmentDirection: stringValue(line, 'adjustment_direction'),
                    remarks: stringValue(line, 'remarks'),
                  ))
              .toList(growable: true);
      detailLoading = false;
      notifyListeners();
    } catch (e) {
      detailLoading = false;
      formError = e.toString();
      notifyListeners();
    }
  }

  void onCompanyChanged(int? value) {
    companyId = value;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    notifyListeners();
  }

  void onBranchChanged(int? value) {
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    notifyListeners();
  }

  void onLocationChanged(int? value) {
    locationId = value;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    notifyListeners();
  }

  void onFinancialYearChanged(int? value) {
    financialYearId = value;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    notifyListeners();
  }

  void onSeriesChanged(int? value) {
    documentSeriesId = value;
    notifyListeners();
  }

  void onAdjustmentTypeChanged(String? value) {
    adjustmentType = value ?? 'mixed';
    notifyListeners();
  }

  void onReasonCodeChanged(String? value) {
    reasonCode = value ?? 'manual_correction';
    notifyListeners();
  }

  void addLine() {
    lines = List<InventoryAdjustmentLineDraft>.from(lines)
      ..add(InventoryAdjustmentLineDraft(warehouseId: warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null));
    notifyListeners();
  }

  void removeLine(int index) {
    if (index < 0 || index >= lines.length) return;
    final next = List<InventoryAdjustmentLineDraft>.from(lines);
    next.removeAt(index).dispose();
    lines = next.isEmpty ? <InventoryAdjustmentLineDraft>[InventoryAdjustmentLineDraft()] : next;
    notifyListeners();
  }

  void onLineItemChanged(int i, int? value) {
    lines[i].itemId = value;
    lines[i].batchId = null;
    lines[i].serialId = null;
    // Keep UOM consistent with the selected Item (uses UOM conversions graph).
    final item = (() {
      for (final x in items) {
        if (x.id == value) return x;
      }
      return null;
    })();
    lines[i].uomId = defaultUomIdForItem(
      item,
      uoms,
      uomConversions,
      current: lines[i].uomId,
    );
    notifyListeners();
  }

  void onLineWarehouseChanged(int i, int? value) {
    lines[i].warehouseId = value;
    lines[i].batchId = null;
    lines[i].serialId = null;
    notifyListeners();
  }

  void onLineUomChanged(int i, int? value) {
    lines[i].uomId = value;
    notifyListeners();
  }

  void onLineBatchChanged(int i, int? value) {
    lines[i].batchId = value;
    lines[i].serialId = null;
    notifyListeners();
  }

  void onLineSerialChanged(int i, int? value) {
    lines[i].serialId = value;
    notifyListeners();
  }

  void onLineDirectionChanged(int i, String? value) {
    lines[i].adjustmentDirection = value;
    notifyListeners();
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    if (itemId == null) return const <UomModel>[];

    ItemModel? item;
    for (final x in items) {
      if (x.id == itemId) {
        item = x;
        break;
      }
    }

    return allowedUomsForItem(item, uoms, uomConversions);
  }

  List<Map<String, dynamic>> batchOptions(int? warehouseId, int? itemId) {
    return batches.map((e) => e.toJson()).where((b) {
      final itemOk = itemId == null || intValue(b, 'item_id') == itemId;
      final whOk = warehouseId == null || intValue(b, 'warehouse_id') == warehouseId;
      return itemOk && whOk;
    }).toList(growable: false);
  }

  List<Map<String, dynamic>> serialOptions(int? warehouseId, int? itemId, int? batchId) {
    return serials.map((e) => e.toJson()).where((s) {
      final itemOk = itemId == null || intValue(s, 'item_id') == itemId;
      final whOk = warehouseId == null || intValue(s, 'warehouse_id') == warehouseId;
      final batchOk = batchId == null || intValue(s, 'batch_id') == batchId;
      final st = stringValue(s, 'status');
      return itemOk && whOk && batchOk && (st == 'available' || st == 'returned');
    }).toList(growable: false);
  }

  String? _validate() {
    if (companyId == null || branchId == null || locationId == null || financialYearId == null) {
      return 'Company, branch, location, and financial year are required.';
    }
    if (documentSeriesId == null && adjustmentNoController.text.trim().isEmpty) {
      return 'Either adjustment number or document series is required.';
    }
    if (adjustmentDateController.text.trim().isEmpty) return 'Adjustment date is required.';
    if (!inventoryAdjustmentTypeItems.any((e) => e.value == adjustmentType)) return 'Invalid adjustment type.';
    if (!inventoryAdjustmentReasonItems.any((e) => e.value == reasonCode)) return 'Invalid reason code.';
    if (lines.isEmpty) return 'At least one line is required.';
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNo = i + 1;
      final systemQty = double.tryParse(line.systemQtyController.text.trim()) ?? 0;
      final actualQty = double.tryParse(line.actualQtyController.text.trim()) ?? 0;
      final adjustmentQtyText = line.adjustmentQtyController.text.trim();
      final adjustmentQty = adjustmentQtyText.isEmpty ? actualQty - systemQty : (double.tryParse(adjustmentQtyText) ?? 0);
      final direction = line.adjustmentDirection ?? (adjustmentQty >= 0 ? 'in' : 'out');
      if (line.itemId == null || line.warehouseId == null || line.uomId == null) return 'Item, warehouse, and UOM are required at line $lineNo.';
      if (adjustmentQty == 0) return 'Adjustment quantity must not be zero at line $lineNo.';
      if (direction != 'in' && direction != 'out') return 'Invalid adjustment direction at line $lineNo.';
      if (adjustmentType == 'increase' && direction != 'in') return 'Increase adjustment can contain only inward lines (line $lineNo).';
      if (adjustmentType == 'decrease' && direction != 'out') return 'Decrease adjustment can contain only outward lines (line $lineNo).';
      if (line.serialId != null && adjustmentQty.abs() != 1) return 'Serial line quantity must be exactly 1 at line $lineNo.';
    }
    return null;
  }

  Future<void> save() async {
    final error = _validate();
    if (error != null) {
      formError = error;
      notifyListeners();
      return;
    }
    saving = true;
    formError = null;
    actionMessage = null;
    notifyListeners();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_series_id': documentSeriesId,
      'adjustment_type': adjustmentType,
      'reason_code': reasonCode,
      'adjustment_no': nullIfEmpty(adjustmentNoController.text),
      'adjustment_date': adjustmentDateController.text.trim(),
      'remarks': nullIfEmpty(remarksController.text),
      'items': lines.map((e) => e.toJson()).toList(growable: false),
    };
    try {
      final response = selected == null
          ? await _inventoryService.createInventoryAdjustment(InventoryAdjustmentModel(payload))
          : await _inventoryService.updateInventoryAdjustment(
              intValue(selected!.toJson(), 'id')!,
              InventoryAdjustmentModel(payload),
            );
      final id = intValue(response.data?.toJson() ?? const <String, dynamic>{}, 'id');
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      actionMessage = null;
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> post() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _inventoryService.postInventoryAdjustment(
        id,
        InventoryAdjustmentModel(const <String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      actionMessage = null;
      notifyListeners();
    }
  }

  Future<void> cancel() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _inventoryService.cancelInventoryAdjustment(
        id,
        InventoryAdjustmentModel(const <String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      actionMessage = null;
      notifyListeners();
    }
  }

  Future<void> delete() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _inventoryService.deleteInventoryAdjustment(id);
      actionMessage = response.message;
      await load();
    } catch (e) {
      formError = e.toString();
      actionMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    adjustmentNoController.dispose();
    adjustmentDateController.dispose();
    remarksController.dispose();
    for (final line in lines) {
      line.dispose();
    }
    super.dispose();
  }
}
