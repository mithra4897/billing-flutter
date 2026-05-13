import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

/// Backend `receipt_source` enum values; labels are UI-facing.
const List<AppDropdownItem<String>> internalStockReceiptSourceItems =
    <AppDropdownItem<String>>[
      AppDropdownItem<String>(
        value: 'department_return',
        label: 'Department return',
      ),
      AppDropdownItem<String>(value: 'sample_return', label: 'Sample return'),
      AppDropdownItem<String>(value: 'jobwork_return', label: 'Jobwork return'),
      AppDropdownItem<String>(
        value: 'production_return',
        label: 'Production return',
      ),
      AppDropdownItem<String>(value: 'other', label: 'Other'),
    ];

class InternalStockReceiptLineDraft {
  InternalStockReceiptLineDraft({
    this.itemId,
    this.batchId,
    String? batchNo,
    this.serialId,
    List<int>? serialIds,
    List<String>? serialNumbers,
    this.uomId,
    String? qty,
    String? unitCost,
    String? totalCost,
    String? remarks,
  }) : batchNoController = TextEditingController(text: batchNo ?? ''),
       qtyController = TextEditingController(text: qty ?? ''),
       unitCostController = TextEditingController(text: unitCost ?? ''),
       totalCostController = TextEditingController(text: totalCost ?? ''),
       remarksController = TextEditingController(text: remarks ?? ''),
       serialIds = List<int>.from(serialIds ?? const <int>[]),
       serialNumbers = List<String>.from(serialNumbers ?? const <String>[]);

  int? itemId;
  int? batchId;
  final TextEditingController batchNoController;
  int? serialId;
  List<int> serialIds;
  List<String> serialNumbers;
  int? uomId;
  final TextEditingController qtyController;
  final TextEditingController unitCostController;
  final TextEditingController totalCostController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'item_id': itemId,
    'uom_id': uomId,
    'batch_id': batchId,
    'batch_no': nullIfEmpty(batchNoController.text),
    'serial_id': serialIds.length == 1 ? serialIds.first : serialId,
    if (serialNumbers.length == 1 && serialNumbers.first.trim().isNotEmpty)
      'serial_no': serialNumbers.first.trim(),
    'receipt_qty': double.tryParse(qtyController.text.trim()) ?? 0,
    'unit_cost': double.tryParse(unitCostController.text.trim()) ?? 0,
    'total_cost': double.tryParse(totalCostController.text.trim()),
    'remarks': nullIfEmpty(remarksController.text),
  };

  void dispose() {
    batchNoController.dispose();
    qtyController.dispose();
    unitCostController.dispose();
    totalCostController.dispose();
    remarksController.dispose();
  }
}

class InternalStockReceiptViewModel extends ChangeNotifier {
  InternalStockReceiptViewModel({this.initialItemId}) {
    searchController.addListener(notifyListeners);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  void _handleWorkingContextChanged() {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    load(selectId: id);
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

  String get status => stringValue(
    selected?.toJson() ?? const <String, dynamic>{},
    'receipt_status',
    'draft',
  );

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
    documentType: 'STOCK_RECEIPT_INTERNAL',
    companyId: companyId,
    branchId: branchId,
    locationId: locationId,
    financialYearId: financialYearId,
  );

  List<InternalStockReceiptModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
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
        })
        .toList(growable: false);
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

  bool itemHasBatch(int? itemId) => itemById(itemId)?.hasBatch ?? false;

  bool itemHasSerial(int? itemId) => itemById(itemId)?.hasSerial ?? false;

  List<int> lineSerialIds(InternalStockReceiptLineDraft line) {
    if (line.serialIds.isNotEmpty) {
      return List<int>.from(line.serialIds);
    }
    return line.serialId == null ? const <int>[] : <int>[line.serialId!];
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
        _inventoryService.items(
          filters: const {'per_page': 500, 'sort_by': 'item_name'},
        ),
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
      companies =
          ((responses[1] as PaginatedResponse<CompanyModel>).data ??
                  const <CompanyModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      branches =
          ((responses[2] as PaginatedResponse<BranchModel>).data ??
                  const <BranchModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      locations =
          ((responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
                  const <BusinessLocationModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      financialYears =
          ((responses[4] as PaginatedResponse<FinancialYearModel>).data ??
                  const <FinancialYearModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      documentSeries =
          ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      items =
          ((responses[6] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      warehouses =
          ((responses[7] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      uoms =
          ((responses[8] as PaginatedResponse<UomModel>).data ??
                  const <UomModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      uomConversions =
          ((responses[9] as PaginatedResponse<UomConversionModel>).data ??
                  const <UomConversionModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      batches =
          (responses[10] as PaginatedResponse<StockBatchModel>).data ??
          const <StockBatchModel>[];
      serials =
          (responses[11] as PaginatedResponse<StockSerialModel>).data ??
          const <StockSerialModel>[];
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
      if (selectId != null) {
        final existing = rows.cast<InternalStockReceiptModel?>().firstWhere(
          (x) =>
              intValue(x?.toJson() ?? const <String, dynamic>{}, 'id') ==
              selectId,
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
    _ensureContextSelection();
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    receiptSource = 'department_return';
    for (final line in lines) {
      line.dispose();
    }
    final itemId = initialItemId;
    lines = <InternalStockReceiptLineDraft>[
      InternalStockReceiptLineDraft(itemId: itemId),
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

  void _ensureContextSelection() {
    if (!containsMasterId(companies, companyId, (item) => item.id)) {
      companyId = companies.isNotEmpty ? companies.first.id : null;
    }
    final branches = branchOptions;
    if (!containsMasterId(branches, branchId, (item) => item.id)) {
      branchId = branches.isNotEmpty ? branches.first.id : null;
    }
    final locations = locationOptions;
    if (!containsMasterId(locations, locationId, (item) => item.id)) {
      locationId = locations.isNotEmpty ? locations.first.id : null;
    }
    financialYearId = defaultFinancialYearIdForCompany(
      financialYears,
      companyId,
      current: financialYearId,
    );
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
      if (!internalStockReceiptSourceItems.any(
        (e) => e.value == receiptSource,
      )) {
        receiptSource = 'department_return';
      }
      receiptNoController.text = stringValue(data, 'receipt_no');
      receiptDateController.text = displayDate(
        nullableStringValue(data, 'receipt_date'),
      );
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
          : _buildLineDrafts(apiLines);
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
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    _clearLineBatchAndSerial();
    notifyListeners();
  }

  void onBranchChanged(int? value) {
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    _clearLineBatchAndSerial();
    notifyListeners();
  }

  void onLocationChanged(int? value) {
    locationId = value;
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
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
      line.batchNoController.clear();
      line.serialNumbers = <String>[];
      _reconcileLineSerialSelection(line);
    }
  }

  void addLine() {
    lines = List<InternalStockReceiptLineDraft>.from(lines)
      ..add(InternalStockReceiptLineDraft());
    notifyListeners();
  }

  void removeLine(int index) {
    if (index < 0 || index >= lines.length) {
      return;
    }
    final next = List<InternalStockReceiptLineDraft>.from(lines);
    next.removeAt(index).dispose();
    lines = next.isEmpty
        ? <InternalStockReceiptLineDraft>[InternalStockReceiptLineDraft()]
        : next;
    notifyListeners();
  }

  void onLineItemChanged(int index, int? value) {
    lines[index].itemId = value;
    lines[index].batchId = null;
    lines[index].batchNoController.clear();
    lines[index].serialId = null;
    lines[index].serialIds = <int>[];
    lines[index].serialNumbers = <String>[];
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
    if (value == null) {
      lines[index].batchNoController.clear();
    } else {
      final selectedBatch = batchOptions(lines[index].itemId)
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (batch) =>
                intValue(batch ?? const <String, dynamic>{}, 'id') == value,
            orElse: () => null,
          );
      lines[index].batchNoController.text = stringValue(
        selectedBatch ?? const <String, dynamic>{},
        'batch_no',
      );
    }
    _reconcileLineSerialSelection(lines[index]);
    notifyListeners();
  }

  void onLineBatchInputChanged(int index, String value) {
    if (index < 0 || index >= lines.length) {
      return;
    }
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      lines[index].batchId = null;
      _reconcileLineSerialSelection(lines[index]);
      notifyListeners();
      return;
    }

    final matchingBatch = batchOptions(lines[index].itemId)
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (batch) =>
              stringValue(
                batch ?? const <String, dynamic>{},
                'batch_no',
              ).trim().toLowerCase() ==
              normalized,
          orElse: () => null,
        );
    lines[index].batchId = intValue(
      matchingBatch ?? const <String, dynamic>{},
      'id',
    );
    _reconcileLineSerialSelection(lines[index]);
    notifyListeners();
  }

  void onLineSerialChanged(int index, int? value) {
    lines[index].serialId = value;
    lines[index].serialIds = value == null ? <int>[] : <int>[value];
    notifyListeners();
  }

  void setLineSerialIds(int index, List<int> values) {
    if (index < 0 || index >= lines.length) {
      return;
    }
    final normalized = values.toSet().toList(growable: false);
    lines[index].serialIds = List<int>.from(normalized);
    lines[index].serialId = normalized.length == 1 ? normalized.first : null;
    lines[index].serialNumbers = normalized
        .map((id) {
          final serial = serials
              .map((entry) => entry.toJson())
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (entry) =>
                    intValue(entry ?? const <String, dynamic>{}, 'id') == id,
                orElse: () => null,
              );
          return stringValue(serial ?? const <String, dynamic>{}, 'serial_no');
        })
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    if (itemHasSerial(lines[index].itemId)) {
      lines[index].qtyController.text = normalized.length.toString();
    }
    notifyListeners();
  }

  void setLineSerialNumbers(int index, List<String> values) {
    if (index < 0 || index >= lines.length) {
      return;
    }
    final normalized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    lines[index].serialNumbers = normalized;

    final serialIdByLabel = <String, int>{
      for (final serial in serialOptions(
        lines[index].itemId,
        lines[index].batchId,
      ))
        stringValue(serial, 'serial_no').trim().toLowerCase():
            intValue(serial, 'id') ?? 0,
    };
    final resolvedIds = normalized
        .map((value) => serialIdByLabel[value.toLowerCase()])
        .whereType<int>()
        .where((id) => id > 0)
        .toSet()
        .toList(growable: false);
    lines[index].serialIds = resolvedIds;
    lines[index].serialId = resolvedIds.length == 1 ? resolvedIds.first : null;
    if (itemHasSerial(lines[index].itemId)) {
      lines[index].qtyController.text = normalized.length.toString();
    }
    notifyListeners();
  }

  void _reconcileLineSerialSelection(InternalStockReceiptLineDraft line) {
    final allowedSerialIds = serialOptions(
      line.itemId,
      line.batchId,
    ).map((serial) => intValue(serial, 'id')).whereType<int>().toSet();

    final nextSerialIds = line.serialIds
        .where(allowedSerialIds.contains)
        .toSet()
        .toList(growable: false);
    line.serialIds = nextSerialIds;

    if (line.serialId != null && !allowedSerialIds.contains(line.serialId)) {
      line.serialId = null;
    }
    if (line.serialId == null && nextSerialIds.length == 1) {
      line.serialId = nextSerialIds.first;
    }
    if (itemHasSerial(line.itemId)) {
      line.qtyController.text = nextSerialIds.length.toString();
    }
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
          return itemOk &&
              whOk &&
              batchOk &&
              (status == 'available' || status == 'returned');
        })
        .toList(growable: false);
  }

  List<InternalStockReceiptLineDraft> _buildLineDrafts(
    List<Map<String, dynamic>> apiLines,
  ) {
    final grouped = <String, _InternalStockReceiptGroupedLine>{};
    final ordered = <_InternalStockReceiptGroupedLine>[];
    for (final line in apiLines) {
      final itemId = intValue(line, 'item_id');
      if (!itemHasSerial(itemId)) {
        ordered.add(_InternalStockReceiptGroupedLine.fromLine(line));
        continue;
      }
      final key = [
        itemId ?? '',
        intValue(line, 'batch_id') ?? '',
        intValue(line, 'uom_id') ?? '',
        stringValue(line, 'unit_cost'),
        stringValue(line, 'total_cost'),
        stringValue(line, 'remarks'),
      ].join('|');
      final alreadyGrouped = grouped.containsKey(key);
      final current = grouped.putIfAbsent(key, () {
        final created = _InternalStockReceiptGroupedLine.fromLine(line);
        ordered.add(created);
        return created;
      });
      if (!alreadyGrouped) {
        continue;
      }
      current.qty += double.tryParse(stringValue(line, 'receipt_qty')) ?? 0;
      final serialId = intValue(line, 'serial_id');
      final serialNo = line['serial'] is Map<String, dynamic>
          ? stringValue(line['serial'] as Map<String, dynamic>, 'serial_no')
          : stringValue(line, 'serial_no');
      if (serialId != null) {
        current.serialIds.add(serialId);
      }
      if (serialNo.trim().isNotEmpty) {
        current.serialNumbers.add(serialNo.trim());
      }
      current.serialId = null;
    }
    return ordered.map((entry) => entry.toDraft()).toList(growable: true);
  }

  String? _validate() {
    final usedSerialIds = <int>{};
    final usedSerialNos = <String>{};
    if (companyId == null ||
        branchId == null ||
        locationId == null ||
        financialYearId == null) {
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
      final unitCost =
          double.tryParse(line.unitCostController.text.trim()) ?? 0;
      final totalCostText = line.totalCostController.text.trim();
      final totalCost = totalCostText.isEmpty
          ? null
          : double.tryParse(totalCostText);
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
            (item) =>
                intValue(item ?? const <String, dynamic>{}, 'id') ==
                line.itemId,
            orElse: () => null,
          );
      if (itemData == null) {
        return 'Invalid inventory item at line $lineNo.';
      }
      final itemCompanyId = intValue(itemData, 'company_id');
      if (!boolValue(itemData, 'track_inventory') ||
          itemCompanyId != companyId) {
        return 'Invalid inventory item at line $lineNo.';
      }

      if (line.batchId != null) {
        final validBatch = batchOptions(
          line.itemId,
        ).any((batch) => intValue(batch, 'id') == line.batchId);
        if (!boolValue(itemData, 'has_batch') || !validBatch) {
          return 'Invalid batch at line $lineNo.';
        }
      }
      if (boolValue(itemData, 'has_batch') &&
          line.batchId == null &&
          line.batchNoController.text.trim().isEmpty) {
        return 'Batch is required at line $lineNo.';
      }

      if (itemHasSerial(line.itemId)) {
        if (qty != qty.floorToDouble()) {
          return 'Serial receipt quantity must be a whole number at line $lineNo.';
        }
        final normalizedSerials = line.serialNumbers
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
        if (qty != normalizedSerials.length) {
          return 'Receipt quantity must match selected serial count at line $lineNo.';
        }
        final uniqueSerials = normalizedSerials
            .map((value) => value.toLowerCase())
            .toSet();
        if (uniqueSerials.length != normalizedSerials.length) {
          return 'Duplicate serial numbers are not allowed at line $lineNo.';
        }

        final availableSerials = serialOptions(line.itemId, line.batchId);
        final availableByLabel = <String, Map<String, dynamic>>{
          for (final serial in availableSerials)
            stringValue(serial, 'serial_no').trim().toLowerCase(): serial,
        };

        for (final serialNo in normalizedSerials) {
          final normalized = serialNo.toLowerCase();
          final matchingSerial = availableByLabel[normalized];
          if (matchingSerial != null) {
            final serialId = intValue(matchingSerial, 'id');
            if (serialId != null && !usedSerialIds.add(serialId)) {
              return 'Duplicate serial selected at line $lineNo.';
            }
            continue;
          }
          if (!usedSerialNos.add(normalized)) {
            return "Duplicate serial number '$serialNo' at line $lineNo.";
          }
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _expandedItemsForSave() {
    final expanded = <Map<String, dynamic>>[];
    for (final line in lines) {
      if (!itemHasSerial(line.itemId)) {
        expanded.add(line.toJson());
        continue;
      }
      final serialEntries = line.serialNumbers
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      final unitCost =
          double.tryParse(line.unitCostController.text.trim()) ?? 0;
      final totalCost = double.tryParse(line.totalCostController.text.trim());
      final remarks = nullIfEmpty(line.remarksController.text);
      for (var index = 0; index < serialEntries.length; index++) {
        expanded.add(<String, dynamic>{
          'item_id': line.itemId,
          'uom_id': line.uomId,
          'batch_id': line.batchId,
          'batch_no': nullIfEmpty(line.batchNoController.text),
          'serial_id': index < line.serialIds.length
              ? line.serialIds[index]
              : null,
          'serial_no': serialEntries[index],
          'receipt_qty': 1,
          'unit_cost': unitCost,
          'total_cost': totalCost ?? unitCost,
          'remarks': remarks,
        });
      }
    }
    return expanded;
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
      'items': _expandedItemsForSave(),
    };
    try {
      final response = selected == null
          ? await _inventoryService.createInternalStockReceipt(
              InternalStockReceiptModel(payload),
            )
          : await _inventoryService.updateInternalStockReceipt(
              intValue(selected!.toJson(), 'id')!,
              InternalStockReceiptModel(payload),
            );
      final id = intValue(
        response.data?.toJson() ?? const <String, dynamic>{},
        'id',
      );
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
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
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

class _InternalStockReceiptGroupedLine {
  _InternalStockReceiptGroupedLine({
    required this.itemId,
    required this.batchId,
    required this.batchNo,
    required this.serialId,
    required this.serialIds,
    required this.serialNumbers,
    required this.uomId,
    required this.qty,
    required this.unitCost,
    required this.totalCost,
    required this.remarks,
  });

  factory _InternalStockReceiptGroupedLine.fromLine(Map<String, dynamic> line) {
    final serialId = intValue(line, 'serial_id');
    final serialNo = line['serial'] is Map<String, dynamic>
        ? stringValue(line['serial'] as Map<String, dynamic>, 'serial_no')
        : stringValue(line, 'serial_no');
    return _InternalStockReceiptGroupedLine(
      itemId: intValue(line, 'item_id'),
      batchId: intValue(line, 'batch_id'),
      batchNo: line['batch'] is Map<String, dynamic>
          ? stringValue(line['batch'] as Map<String, dynamic>, 'batch_no')
          : stringValue(line, 'batch_no'),
      serialId: serialId,
      serialIds: serialId == null ? <int>[] : <int>[serialId],
      serialNumbers: serialNo.trim().isEmpty
          ? <String>[]
          : <String>[serialNo.trim()],
      uomId: intValue(line, 'uom_id'),
      qty: double.tryParse(stringValue(line, 'receipt_qty')) ?? 0,
      unitCost: double.tryParse(stringValue(line, 'unit_cost')) ?? 0,
      totalCost: double.tryParse(stringValue(line, 'total_cost')) ?? 0,
      remarks: stringValue(line, 'remarks'),
    );
  }

  int? itemId;
  int? batchId;
  String batchNo;
  int? serialId;
  List<int> serialIds;
  List<String> serialNumbers;
  int? uomId;
  double qty;
  double unitCost;
  double totalCost;
  String remarks;

  InternalStockReceiptLineDraft toDraft() => InternalStockReceiptLineDraft(
    itemId: itemId,
    batchId: batchId,
    batchNo: batchNo,
    serialId: serialId,
    serialIds: serialIds,
    serialNumbers: serialNumbers,
    uomId: uomId,
    qty: _internalReceiptFormatNumber(qty),
    unitCost: _internalReceiptFormatNumber(unitCost),
    totalCost: _internalReceiptFormatNumber(totalCost),
    remarks: remarks,
  );
}

String _internalReceiptFormatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}
