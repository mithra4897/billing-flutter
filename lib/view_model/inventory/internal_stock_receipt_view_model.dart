import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

/// Backend `receipt_source` enum values; labels are UI-facing.
const List<AppDropdownItem<String>> internalStockReceiptSourceItems =
    <AppDropdownItem<String>>[
  AppDropdownItem<String>(value: 'department_return', label: 'Department return'),
  AppDropdownItem<String>(value: 'sample_return', label: 'Sample return'),
  AppDropdownItem<String>(value: 'jobwork_return', label: 'Jobwork return'),
  AppDropdownItem<String>(value: 'production_return', label: 'Production return'),
  AppDropdownItem<String>(value: 'other', label: 'Other'),
];

class InternalStockReceiptLineDraft {
  InternalStockReceiptLineDraft({
    this.itemId,
    this.batchId,
    this.serialId,
    this.uomId,
    String? qty,
    String? unitCost,
    String? totalCost,
    String? remarks,
  })  : qtyController = TextEditingController(text: qty ?? ''),
        unitCostController = TextEditingController(text: unitCost ?? ''),
        totalCostController = TextEditingController(text: totalCost ?? ''),
        remarksController = TextEditingController(text: remarks ?? '');

  int? itemId;
  int? batchId;
  int? serialId;
  int? uomId;
  final TextEditingController qtyController;
  final TextEditingController unitCostController;
  final TextEditingController totalCostController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'item_id': itemId,
        'uom_id': uomId,
        'batch_id': batchId,
        'serial_id': serialId,
        'receipt_qty': double.tryParse(qtyController.text.trim()) ?? 0,
        'unit_cost': double.tryParse(unitCostController.text.trim()) ?? 0,
        'total_cost': double.tryParse(totalCostController.text.trim()),
        'remarks': nullIfEmpty(remarksController.text),
      };

  void dispose() {
    qtyController.dispose();
    unitCostController.dispose();
    totalCostController.dispose();
    remarksController.dispose();
  }
}

class InternalStockReceiptViewModel extends ChangeNotifier {
  InternalStockReceiptViewModel({this.initialItemId}) {
    searchController.addListener(notifyListeners);
  }

  final int? initialItemId;
  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController receiptNoController = TextEditingController();
  final TextEditingController receiptDateController = TextEditingController();
  final TextEditingController receivedFromController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;
  List<InternalStockReceiptModel> rows = const <InternalStockReceiptModel>[];
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
  InternalStockReceiptModel? selected;
  InternalStockReceiptModel? selectedDetail;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? warehouseId;
  String receiptSource = 'department_return';
  List<InternalStockReceiptLineDraft> lines = <InternalStockReceiptLineDraft>[];

  String get status =>
      stringValue(selected?.toJson() ?? const <String, dynamic>{}, 'receipt_status', 'draft');

  List<BranchModel> get branchOptions => branchesForCompany(branches, companyId);
  List<BusinessLocationModel> get locationOptions => locationsForBranch(locations, branchId);

  List<WarehouseModel> get warehouseOptions => warehouses.where((w) {
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
      }).toList(growable: false);

  List<DocumentSeriesModel> get seriesOptions => documentSeries
      .where((item) =>
          (item.documentType == null || item.documentType == 'STOCK_RECEIPT_INTERNAL') &&
          (companyId == null || item.companyId == companyId) &&
          (branchId == null ||
              intValue(item.raw ?? const <String, dynamic>{}, 'branch_id') == null ||
              intValue(item.raw ?? const <String, dynamic>{}, 'branch_id') == branchId) &&
          (locationId == null ||
              intValue(item.raw ?? const <String, dynamic>{}, 'location_id') == null ||
              intValue(item.raw ?? const <String, dynamic>{}, 'location_id') == locationId) &&
          (financialYearId == null || item.financialYearId == financialYearId))
      .toList(growable: false);

  List<InternalStockReceiptModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) {
        return true;
      }
      return [
        stringValue(data, 'receipt_no'),
        stringValue(data, 'receipt_status'),
        stringValue(data, 'receipt_source'),
        stringValue(data, 'remarks'),
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
        _inventoryService.internalStockReceipts(
          filters: const {'per_page': 200, 'sort_by': 'receipt_date'},
        ),
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
      rows =
          (responses[0] as PaginatedResponse<InternalStockReceiptModel>).data ??
              const <InternalStockReceiptModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ?? const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      branches = ((responses[2] as PaginatedResponse<BranchModel>).data ?? const <BranchModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      locations =
          ((responses[3] as PaginatedResponse<BusinessLocationModel>).data ?? const <BusinessLocationModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      financialYears = ((responses[4] as PaginatedResponse<FinancialYearModel>).data ??
              const <FinancialYearModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      documentSeries = ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
              const <DocumentSeriesModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      items = ((responses[6] as PaginatedResponse<ItemModel>).data ?? const <ItemModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      warehouses = ((responses[7] as PaginatedResponse<WarehouseModel>).data ?? const <WarehouseModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      uoms = ((responses[8] as PaginatedResponse<UomModel>).data ?? const <UomModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      uomConversions = ((responses[9] as PaginatedResponse<UomConversionModel>).data ?? const <UomConversionModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      batches = (responses[10] as PaginatedResponse<StockBatchModel>).data ?? const <StockBatchModel>[];
      serials = (responses[11] as PaginatedResponse<StockSerialModel>).data ?? const <StockSerialModel>[];
      loading = false;
      if (selectId != null) {
        final existing = rows.cast<InternalStockReceiptModel?>().firstWhere(
              (x) => intValue(x?.toJson() ?? const <String, dynamic>{}, 'id') == selectId,
              orElse: () => null,
            );
        if (existing != null) {
          await select(existing);
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
    selectedDetail = null;
    formError = null;
    final now = DateTime.now().toIso8601String().split('T').first;
    receiptNoController.clear();
    receiptDateController.text = now;
    receivedFromController.clear();
    remarksController.clear();
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    financialYearId ??= financialYears.isNotEmpty ? financialYears.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    warehouseId = warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    receiptSource = 'department_return';
    for (final line in lines) {
      line.dispose();
    }
    final itemId = initialItemId;
    lines = <InternalStockReceiptLineDraft>[
      InternalStockReceiptLineDraft(
        itemId: itemId,
      ),
    ];
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

  Future<void> select(InternalStockReceiptModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _inventoryService.internalStockReceipt(id);
      final data = (response.data ?? row).toJson();
      selectedDetail = response.data ?? row;
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      documentSeriesId = intValue(data, 'document_series_id');
      warehouseId = intValue(data, 'warehouse_id');
      receiptSource = stringValue(data, 'receipt_source', 'department_return');
      if (!internalStockReceiptSourceItems.any((e) => e.value == receiptSource)) {
        receiptSource = 'department_return';
      }
      receiptNoController.text = stringValue(data, 'receipt_no');
      receiptDateController.text = displayDate(nullableStringValue(data, 'receipt_date'));
      receivedFromController.text = stringValue(data, 'received_from');
      remarksController.text = stringValue(data, 'remarks');
      for (final line in lines) {
        line.dispose();
      }
      final apiLines = (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      lines = apiLines.isEmpty
          ? <InternalStockReceiptLineDraft>[InternalStockReceiptLineDraft()]
          : apiLines
              .map(
                (line) => InternalStockReceiptLineDraft(
                  itemId: intValue(line, 'item_id'),
                  batchId: intValue(line, 'batch_id'),
                  serialId: intValue(line, 'serial_id'),
                  uomId: intValue(line, 'uom_id'),
                  qty: stringValue(line, 'receipt_qty'),
                  unitCost: stringValue(line, 'unit_cost'),
                  totalCost: stringValue(line, 'total_cost'),
                  remarks: stringValue(line, 'remarks'),
                ),
              )
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
    warehouseId = warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    _clearLineBatchAndSerial();
    notifyListeners();
  }

  void onBranchChanged(int? value) {
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    warehouseId = warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    _clearLineBatchAndSerial();
    notifyListeners();
  }

  void onLocationChanged(int? value) {
    locationId = value;
    warehouseId = warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    _clearLineBatchAndSerial();
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

  void onWarehouseChanged(int? value) {
    warehouseId = value;
    _clearLineBatchAndSerial();
    notifyListeners();
  }

  void onReceiptSourceChanged(String? value) {
    receiptSource = value ?? 'department_return';
    notifyListeners();
  }

  void _clearLineBatchAndSerial() {
    for (final line in lines) {
      line.batchId = null;
      line.serialId = null;
    }
  }

  void addLine() {
    lines = List<InternalStockReceiptLineDraft>.from(lines)..add(InternalStockReceiptLineDraft());
    notifyListeners();
  }

  void removeLine(int index) {
    if (index < 0 || index >= lines.length) {
      return;
    }
    final next = List<InternalStockReceiptLineDraft>.from(lines);
    next.removeAt(index).dispose();
    lines =
        next.isEmpty ? <InternalStockReceiptLineDraft>[InternalStockReceiptLineDraft()] : next;
    notifyListeners();
  }

  void onLineItemChanged(int index, int? value) {
    lines[index].itemId = value;
    lines[index].batchId = null;
    lines[index].serialId = null;
    // Keep UOM consistent with the selected Item (uses UOM conversions graph).
    final item = (() {
      for (final x in items) {
        if (x.id == value) return x;
      }
      return null;
    })();
    lines[index].uomId = defaultUomIdForItem(
      item,
      uoms,
      uomConversions,
      current: lines[index].uomId,
    );
    notifyListeners();
  }

  void onLineUomChanged(int index, int? value) {
    lines[index].uomId = value;
    notifyListeners();
  }

  void onLineBatchChanged(int index, int? value) {
    lines[index].batchId = value;
    lines[index].serialId = null;
    notifyListeners();
  }

  void onLineSerialChanged(int index, int? value) {
    lines[index].serialId = value;
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

  List<Map<String, dynamic>> batchOptions(int? itemId) {
    final wh = warehouseId;
    return batches
        .map((e) => e.toJson())
        .where((b) {
          final itemOk = itemId == null || intValue(b, 'item_id') == itemId;
          final whOk = wh == null || intValue(b, 'warehouse_id') == wh;
          return itemOk && whOk;
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> serialOptions(int? itemId, int? batchId) {
    final wh = warehouseId;
    return serials
        .map((e) => e.toJson())
        .where((s) {
          final itemOk = itemId == null || intValue(s, 'item_id') == itemId;
          final whOk = wh == null || intValue(s, 'warehouse_id') == wh;
          final batchOk = batchId == null || intValue(s, 'batch_id') == batchId;
          final status = stringValue(s, 'status');
          return itemOk && whOk && batchOk && (status == 'available' || status == 'returned');
        })
        .toList(growable: false);
  }

  String? _validate() {
    if (companyId == null || branchId == null || locationId == null || financialYearId == null) {
      return 'Company, branch, location, and financial year are required.';
    }
    if (warehouseId == null) {
      return 'Warehouse is required.';
    }
    if (documentSeriesId == null && receiptNoController.text.trim().isEmpty) {
      return 'Either receipt number or document series is required.';
    }
    if (receiptDateController.text.trim().isEmpty) {
      return 'Receipt date is required.';
    }
    if (!internalStockReceiptSourceItems.any((e) => e.value == receiptSource)) {
      return 'Invalid receipt source.';
    }
    if (lines.isEmpty) {
      return 'At least one line is required.';
    }
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNo = i + 1;
      final qty = double.tryParse(line.qtyController.text.trim()) ?? 0;
      final unitCost = double.tryParse(line.unitCostController.text.trim()) ?? 0;
      final totalCostText = line.totalCostController.text.trim();
      final totalCost = totalCostText.isEmpty ? null : double.tryParse(totalCostText);
      if (line.itemId == null || line.uomId == null) {
        return 'Item and UOM are required at line $lineNo.';
      }
      if (qty <= 0) {
        return 'Receipt quantity must be greater than zero at line $lineNo.';
      }
      if (unitCost < 0) {
        return 'Unit cost cannot be negative at line $lineNo.';
      }
      if (totalCost != null && totalCost < 0) {
        return 'Total cost cannot be negative at line $lineNo.';
      }

      final itemData = items
          .map((e) => e.toJson())
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (item) => intValue(item ?? const <String, dynamic>{}, 'id') == line.itemId,
            orElse: () => null,
          );
      if (itemData == null) {
        return 'Invalid inventory item at line $lineNo.';
      }
      final itemCompanyId = intValue(itemData, 'company_id');
      if (!boolValue(itemData, 'track_inventory') || itemCompanyId != companyId) {
        return 'Invalid inventory item at line $lineNo.';
      }

      if (line.batchId != null) {
        final validBatch = batchOptions(line.itemId).any((batch) => intValue(batch, 'id') == line.batchId);
        if (!boolValue(itemData, 'has_batch') || !validBatch) {
          return 'Invalid batch at line $lineNo.';
        }
      }

      if (line.serialId != null) {
        final matchingSerial = serialOptions(line.itemId, line.batchId)
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (serial) => intValue(serial ?? const <String, dynamic>{}, 'id') == line.serialId,
              orElse: () => null,
            );
        if (matchingSerial == null) {
          return 'Invalid serial at line $lineNo.';
        }
        if (line.batchId != null &&
            intValue(matchingSerial, 'batch_id') != null &&
            intValue(matchingSerial, 'batch_id') != line.batchId) {
          return 'Serial does not belong to selected batch at line $lineNo.';
        }
        if (qty != 1) {
          return 'Serial receipt quantity must be exactly 1 at line $lineNo.';
        }
      }
    }
    return null;
  }

  Future<void> save() async {
    final validationError = _validate();
    if (validationError != null) {
      formError = validationError;
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
      'warehouse_id': warehouseId,
      'receipt_source': receiptSource,
      'receipt_no': nullIfEmpty(receiptNoController.text),
      'receipt_date': receiptDateController.text.trim(),
      'received_from': nullIfEmpty(receivedFromController.text),
      'remarks': nullIfEmpty(remarksController.text),
      'items': lines.map((e) => e.toJson()).toList(growable: false),
    };
    try {
      final response = selected == null
          ? await _inventoryService.createInternalStockReceipt(InternalStockReceiptModel(payload))
          : await _inventoryService.updateInternalStockReceipt(
              intValue(selected!.toJson(), 'id')!,
              InternalStockReceiptModel(payload),
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
    if (id == null) {
      return;
    }
    try {
      final response = await _inventoryService.postInternalStockReceipt(
        id,
        InternalStockReceiptModel(const <String, dynamic>{}),
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
    if (id == null) {
      return;
    }
    try {
      final response = await _inventoryService.cancelInternalStockReceipt(
        id,
        InternalStockReceiptModel(const <String, dynamic>{}),
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
    if (id == null) {
      return;
    }
    try {
      final response = await _inventoryService.deleteInternalStockReceipt(id);
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
    receiptNoController.dispose();
    receiptDateController.dispose();
    receivedFromController.dispose();
    remarksController.dispose();
    for (final line in lines) {
      line.dispose();
    }
    super.dispose();
  }
}
