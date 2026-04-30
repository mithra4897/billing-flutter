import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class StockTransferLineDraft {
  StockTransferLineDraft({
    this.itemId,
    this.fromBatchId,
    this.fromSerialId,
    this.toBatchId,
    this.toSerialId,
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
  int? fromBatchId;
  int? fromSerialId;
  int? toBatchId;
  int? toSerialId;
  int? uomId;
  final TextEditingController qtyController;
  final TextEditingController unitCostController;
  final TextEditingController totalCostController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'item_id': itemId,
        'uom_id': uomId,
        'from_batch_id': fromBatchId,
        'from_serial_id': fromSerialId,
        'to_batch_id': toBatchId,
        'to_serial_id': toSerialId,
        'transfer_qty': double.tryParse(qtyController.text.trim()) ?? 0,
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

class StockTransferViewModel extends ChangeNotifier {
  StockTransferViewModel({this.initialItemId}) {
    searchController.addListener(notifyListeners);
  }

  final int? initialItemId;
  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController transferNoController = TextEditingController();
  final TextEditingController transferDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;
  List<StockTransferModel> rows = const <StockTransferModel>[];
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
  StockTransferModel? selected;
  StockTransferModel? selectedDetail;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? fromWarehouseId;
  int? toWarehouseId;
  List<StockTransferLineDraft> lines = <StockTransferLineDraft>[];

  String get status =>
      stringValue(selected?.toJson() ?? const <String, dynamic>{}, 'transfer_status', 'draft');

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
          (item.documentType == null || item.documentType == 'STOCK_TRANSFER') &&
          (companyId == null || item.companyId == companyId) &&
          (branchId == null ||
              intValue(item.raw ?? const <String, dynamic>{}, 'branch_id') == null ||
              intValue(item.raw ?? const <String, dynamic>{}, 'branch_id') == branchId) &&
          (locationId == null ||
              intValue(item.raw ?? const <String, dynamic>{}, 'location_id') == null ||
              intValue(item.raw ?? const <String, dynamic>{}, 'location_id') == locationId) &&
          (financialYearId == null || item.financialYearId == financialYearId))
      .toList(growable: false);

  List<StockTransferModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) {
        return true;
      }
      return [
        stringValue(data, 'transfer_no'),
        stringValue(data, 'transfer_status'),
        stringValue(data, 'remarks'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  int? _firstWarehouseIdOtherThan(int? exclude) {
    for (final w in warehouseOptions) {
      if (w.id != null && w.id != exclude) {
        return w.id;
      }
    }
    return null;
  }

  void _assignDefaultWarehouses() {
    final opts = warehouseOptions;
    fromWarehouseId = opts.isNotEmpty ? opts.first.id : null;
    toWarehouseId = _firstWarehouseIdOtherThan(fromWarehouseId);
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.stockTransfers(
          filters: const {'per_page': 200, 'sort_by': 'transfer_date'},
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
      rows = (responses[0] as PaginatedResponse<StockTransferModel>).data ?? const <StockTransferModel>[];
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
        final existing = rows.cast<StockTransferModel?>().firstWhere(
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
    transferNoController.clear();
    transferDateController.text = now;
    remarksController.clear();
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    financialYearId ??= financialYears.isNotEmpty ? financialYears.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    _assignDefaultWarehouses();
    for (final line in lines) {
      line.dispose();
    }
    lines = <StockTransferLineDraft>[
      StockTransferLineDraft(
        itemId: initialItemId,
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

  Future<void> select(StockTransferModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _inventoryService.stockTransfer(id);
      final data = (response.data ?? row).toJson();
      selectedDetail = response.data ?? row;
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      documentSeriesId = intValue(data, 'document_series_id');
      fromWarehouseId = intValue(data, 'from_warehouse_id');
      toWarehouseId = intValue(data, 'to_warehouse_id');
      transferNoController.text = stringValue(data, 'transfer_no');
      transferDateController.text = displayDate(nullableStringValue(data, 'transfer_date'));
      remarksController.text = stringValue(data, 'remarks');
      for (final line in lines) {
        line.dispose();
      }
      final apiLines = (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      lines = apiLines.isEmpty
          ? <StockTransferLineDraft>[StockTransferLineDraft()]
          : apiLines
              .map(
                (line) => StockTransferLineDraft(
                  itemId: intValue(line, 'item_id'),
                  fromBatchId: intValue(line, 'from_batch_id'),
                  fromSerialId: intValue(line, 'from_serial_id'),
                  toBatchId: intValue(line, 'to_batch_id'),
                  toSerialId: intValue(line, 'to_serial_id'),
                  uomId: intValue(line, 'uom_id'),
                  qty: stringValue(line, 'transfer_qty'),
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
    _assignDefaultWarehouses();
    _clearLineTracking();
    notifyListeners();
  }

  void onBranchChanged(int? value) {
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    _assignDefaultWarehouses();
    _clearLineTracking();
    notifyListeners();
  }

  void onLocationChanged(int? value) {
    locationId = value;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    _assignDefaultWarehouses();
    _clearLineTracking();
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

  void onFromWarehouseChanged(int? value) {
    fromWarehouseId = value;
    if (toWarehouseId == fromWarehouseId) {
      toWarehouseId = _firstWarehouseIdOtherThan(fromWarehouseId);
    }
    _clearLineFromTracking();
    notifyListeners();
  }

  void onToWarehouseChanged(int? value) {
    toWarehouseId = value;
    if (toWarehouseId == fromWarehouseId) {
      fromWarehouseId = _firstWarehouseIdOtherThan(toWarehouseId);
    }
    _clearLineToTracking();
    notifyListeners();
  }

  void _clearLineFromTracking() {
    for (final line in lines) {
      line.fromBatchId = null;
      line.fromSerialId = null;
    }
  }

  void _clearLineToTracking() {
    for (final line in lines) {
      line.toBatchId = null;
      line.toSerialId = null;
    }
  }

  void _clearLineTracking() {
    _clearLineFromTracking();
    _clearLineToTracking();
  }

  void addLine() {
    lines = List<StockTransferLineDraft>.from(lines)..add(StockTransferLineDraft());
    notifyListeners();
  }

  void removeLine(int index) {
    if (index < 0 || index >= lines.length) {
      return;
    }
    final next = List<StockTransferLineDraft>.from(lines);
    next.removeAt(index).dispose();
    lines =
        next.isEmpty ? <StockTransferLineDraft>[StockTransferLineDraft()] : next;
    notifyListeners();
  }

  void onLineItemChanged(int index, int? value) {
    lines[index].itemId = value;
    lines[index].fromBatchId = null;
    lines[index].fromSerialId = null;
    lines[index].toBatchId = null;
    lines[index].toSerialId = null;
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

  void onLineFromBatchChanged(int index, int? value) {
    lines[index].fromBatchId = value;
    lines[index].fromSerialId = null;
    notifyListeners();
  }

  void onLineFromSerialChanged(int index, int? value) {
    lines[index].fromSerialId = value;
    notifyListeners();
  }

  void onLineToBatchChanged(int index, int? value) {
    lines[index].toBatchId = value;
    lines[index].toSerialId = null;
    notifyListeners();
  }

  void onLineToSerialChanged(int index, int? value) {
    lines[index].toSerialId = value;
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

  List<Map<String, dynamic>> batchOptionsForWarehouse(int? warehouseId, int? itemId) {
    return batches
        .map((e) => e.toJson())
        .where((b) {
          final itemOk = itemId == null || intValue(b, 'item_id') == itemId;
          final whOk = warehouseId == null || intValue(b, 'warehouse_id') == warehouseId;
          return itemOk && whOk;
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> serialOptionsForWarehouse(
    int? warehouseId,
    int? itemId,
    int? batchId,
  ) {
    return serials
        .map((e) => e.toJson())
        .where((s) {
          final itemOk = itemId == null || intValue(s, 'item_id') == itemId;
          final whOk = warehouseId == null || intValue(s, 'warehouse_id') == warehouseId;
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
    if (fromWarehouseId == null || toWarehouseId == null) {
      return 'Source and destination warehouses are required.';
    }
    if (fromWarehouseId == toWarehouseId) {
      return 'Source and destination warehouse must be different.';
    }
    if (documentSeriesId == null && transferNoController.text.trim().isEmpty) {
      return 'Either transfer number or document series is required.';
    }
    if (transferDateController.text.trim().isEmpty) {
      return 'Transfer date is required.';
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
        return 'Transfer quantity must be greater than zero at line $lineNo.';
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

      final hasBatch = boolValue(itemData, 'has_batch');
      final hasSerial = boolValue(itemData, 'has_serial');

      if (line.fromBatchId != null) {
        final ok = hasBatch &&
            batchOptionsForWarehouse(fromWarehouseId, line.itemId)
                .any((b) => intValue(b, 'id') == line.fromBatchId);
        if (!ok) {
          return 'Invalid source batch at line $lineNo.';
        }
      }

      if (line.toBatchId != null) {
        final ok = hasBatch &&
            batchOptionsForWarehouse(toWarehouseId, line.itemId)
                .any((b) => intValue(b, 'id') == line.toBatchId);
        if (!ok) {
          return 'Invalid destination batch at line $lineNo.';
        }
      }

      if (hasBatch && line.fromBatchId != null && line.toBatchId == null) {
        return 'Destination batch is required when source batch is set at line $lineNo.';
      }

      if (line.fromSerialId != null) {
        if (!hasSerial) {
          return 'Source serial not allowed for this item at line $lineNo.';
        }
        final matching = serialOptionsForWarehouse(fromWarehouseId, line.itemId, line.fromBatchId)
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (s) => intValue(s ?? const <String, dynamic>{}, 'id') == line.fromSerialId,
              orElse: () => null,
            );
        if (matching == null) {
          return 'Invalid source serial at line $lineNo.';
        }
        if (line.fromBatchId != null &&
            intValue(matching, 'batch_id') != null &&
            intValue(matching, 'batch_id') != line.fromBatchId) {
          return 'Source serial does not belong to selected source batch at line $lineNo.';
        }
        if (qty != 1) {
          return 'Serial transfer quantity must be exactly 1 at line $lineNo.';
        }
      }

      if (line.toSerialId != null) {
        if (!hasSerial) {
          return 'Destination serial not allowed for this item at line $lineNo.';
        }
        final matching = serialOptionsForWarehouse(toWarehouseId, line.itemId, line.toBatchId)
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (s) => intValue(s ?? const <String, dynamic>{}, 'id') == line.toSerialId,
              orElse: () => null,
            );
        if (matching == null) {
          return 'Invalid destination serial at line $lineNo.';
        }
        if (line.toBatchId != null &&
            intValue(matching, 'batch_id') != null &&
            intValue(matching, 'batch_id') != line.toBatchId) {
          return 'Destination serial does not belong to selected destination batch at line $lineNo.';
        }
        if (qty != 1) {
          return 'Destination serial transfer quantity must be exactly 1 at line $lineNo.';
        }
      }

      if (hasSerial && line.fromSerialId != null && line.toSerialId == null) {
        return 'Destination serial is required when source serial is set at line $lineNo.';
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
      'from_warehouse_id': fromWarehouseId,
      'to_warehouse_id': toWarehouseId,
      'transfer_no': nullIfEmpty(transferNoController.text),
      'transfer_date': transferDateController.text.trim(),
      'remarks': nullIfEmpty(remarksController.text),
      'items': lines.map((e) => e.toJson()).toList(growable: false),
    };
    try {
      final response = selected == null
          ? await _inventoryService.createStockTransfer(StockTransferModel(payload))
          : await _inventoryService.updateStockTransfer(
              intValue(selected!.toJson(), 'id')!,
              StockTransferModel(payload),
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
      final response = await _inventoryService.postStockTransfer(
        id,
        StockTransferModel(const <String, dynamic>{}),
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
      final response = await _inventoryService.cancelStockTransfer(
        id,
        StockTransferModel(const <String, dynamic>{}),
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
      final response = await _inventoryService.deleteStockTransfer(id);
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
    transferNoController.dispose();
    transferDateController.dispose();
    remarksController.dispose();
    for (final line in lines) {
      line.dispose();
    }
    super.dispose();
  }
}
