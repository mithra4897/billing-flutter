import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

/// Mutable line state for the opening stock editor (View binds controllers).
class OpeningStockLineDraft {
  OpeningStockLineDraft({
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    List<int>? serialIds,
    this.uomId,
    List<String>? serialNumbers,
    String? qty,
    String? unitCost,
    String? totalCost,
    String? remarks,
  }) : qtyController = TextEditingController(text: qty ?? ''),
       unitCostController = TextEditingController(text: unitCost ?? ''),
       totalCostController = TextEditingController(text: totalCost ?? ''),
       remarksController = TextEditingController(text: remarks ?? ''),
       serialIds = List<int>.from(serialIds ?? const <int>[]),
       serialNumbers = List<String>.from(serialNumbers ?? const <String>[]);

  int? itemId;
  int? warehouseId;
  int? batchId;
  int? serialId;
  List<int> serialIds;
  int? uomId;
  List<String> serialNumbers;
  final TextEditingController qtyController;
  final TextEditingController unitCostController;
  final TextEditingController totalCostController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'item_id': itemId,
    'warehouse_id': warehouseId,
    'batch_id': batchId,
    'serial_id': serialId,
    if (serialNumbers.length == 1 && serialNumbers.first.trim().isNotEmpty)
      'serial_no': serialNumbers.first.trim(),
    'uom_id': uomId,
    'qty': double.tryParse(qtyController.text.trim()) ?? 0,
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

class OpeningStockViewModel extends ChangeNotifier {
  OpeningStockViewModel({this.initialItemId}) {
    searchController.addListener(notifyListeners);
  }

  final int? initialItemId;
  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController openingNoController = TextEditingController();
  final TextEditingController openingDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;
  List<OpeningStockModel> rows = const <OpeningStockModel>[];
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
  OpeningStockModel? selected;
  OpeningStockModel? selectedDetail;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  List<OpeningStockLineDraft> lines = <OpeningStockLineDraft>[];

  String get status => stringValue(
    selected?.toJson() ?? const <String, dynamic>{},
    'opening_status',
    'draft',
  );

  List<BranchModel> get branchOptions =>
      branchesForCompany(branches, companyId);
  List<BusinessLocationModel> get locationOptions =>
      locationsForBranch(locations, branchId);
  List<ItemModel> get itemOptions => items
      .where((item) {
        if (!item.trackInventory) {
          return false;
        }
        if (companyId != null && item.companyId != companyId) {
          return false;
        }
        return true;
      })
      .toList(growable: false);

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

  List<DocumentSeriesModel> get seriesOptions => documentSeries
      .where(
        (item) =>
            (item.documentType == null ||
                item.documentType == 'STOCK_OPENING') &&
            (companyId == null || item.companyId == companyId) &&
            (branchId == null ||
                intValue(item.raw ?? const <String, dynamic>{}, 'branch_id') ==
                    null ||
                intValue(item.raw ?? const <String, dynamic>{}, 'branch_id') ==
                    branchId) &&
            (locationId == null ||
                intValue(
                      item.raw ?? const <String, dynamic>{},
                      'location_id',
                    ) ==
                    null ||
                intValue(
                      item.raw ?? const <String, dynamic>{},
                      'location_id',
                    ) ==
                    locationId) &&
            (financialYearId == null ||
                item.financialYearId == financialYearId),
      )
      .toList(growable: false);

  List<OpeningStockModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'opening_no'),
            stringValue(data, 'opening_status'),
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

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.openingStocks(
          filters: const {'per_page': 200, 'sort_by': 'opening_date'},
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
          (responses[0] as PaginatedResponse<OpeningStockModel>).data ??
          const <OpeningStockModel>[];
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
      loading = false;
      if (selectId != null) {
        final existing = rows.cast<OpeningStockModel?>().firstWhere(
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
    openingNoController.clear();
    openingDateController.text = now;
    remarksController.clear();
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    financialYearId ??= financialYears.isNotEmpty
        ? financialYears.first.id
        : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    for (final line in lines) {
      line.dispose();
    }
    final itemId = _defaultItemId();
    lines = <OpeningStockLineDraft>[
      OpeningStockLineDraft(
        itemId: itemId,
        warehouseId: warehouseOptions.isNotEmpty
            ? warehouseOptions.first.id
            : null,
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

  Future<void> select(OpeningStockModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _inventoryService.openingStock(id);
      final data = (response.data ?? row).toJson();
      selectedDetail = response.data ?? row;
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      documentSeriesId = intValue(data, 'document_series_id');
      openingNoController.text = stringValue(data, 'opening_no');
      openingDateController.text = displayDate(
        nullableStringValue(data, 'opening_date'),
      );
      remarksController.text = stringValue(data, 'remarks');
      for (final line in lines) {
        line.dispose();
      }
      final apiLines = (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      lines = apiLines.isEmpty
          ? <OpeningStockLineDraft>[OpeningStockLineDraft()]
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
    _resetLineWarehouses();
    notifyListeners();
  }

  void onBranchChanged(int? value) {
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    _resetLineWarehouses();
    notifyListeners();
  }

  void onLocationChanged(int? value) {
    locationId = value;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    _resetLineWarehouses();
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

  void _resetLineWarehouses() {
    final warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    final validItemIds = itemOptions
        .where((item) => item.id != null)
        .map((item) => item.id!)
        .toSet();
    for (final line in lines) {
      if (line.itemId != null && !validItemIds.contains(line.itemId)) {
        line.itemId = null;
        line.serialNumbers = <String>[];
      }
      line.warehouseId = warehouseId;
      line.batchId = null;
      _reconcileLineSerialSelection(line);
    }
  }

  int? _defaultItemId() {
    if (initialItemId != null &&
        itemOptions.any((item) => item.id == initialItemId)) {
      return initialItemId;
    }
    return null;
  }

  void addLine() {
    lines = List<OpeningStockLineDraft>.from(lines)
      ..add(
        OpeningStockLineDraft(
          warehouseId: warehouseOptions.isNotEmpty
              ? warehouseOptions.first.id
              : null,
        ),
      );
    notifyListeners();
  }

  void removeLine(int index) {
    if (index < 0 || index >= lines.length) {
      return;
    }
    final next = List<OpeningStockLineDraft>.from(lines);
    next.removeAt(index).dispose();
    lines = next.isEmpty
        ? <OpeningStockLineDraft>[OpeningStockLineDraft()]
        : next;
    notifyListeners();
  }

  void onLineItemChanged(int index, int? value) {
    lines[index].itemId = value;
    lines[index].batchId = null;
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

  void onLineWarehouseChanged(int index, int? value) {
    lines[index].warehouseId = value;
    lines[index].batchId = null;
    _reconcileLineSerialSelection(lines[index]);
    notifyListeners();
  }

  void onLineUomChanged(int index, int? value) {
    lines[index].uomId = value;
    notifyListeners();
  }

  void onLineBatchChanged(int index, int? value) {
    lines[index].batchId = value;
    _reconcileLineSerialSelection(lines[index]);
    notifyListeners();
  }

  void onLineSerialChanged(int index, int? value) {
    lines[index].serialId = value;
    lines[index].serialIds = value == null ? <int>[] : <int>[value];
    notifyListeners();
  }

  void _reconcileLineSerialSelection(OpeningStockLineDraft line) {
    final allowedSerialIds = serialOptions(
      line.itemId,
      line.warehouseId,
      line.batchId,
    ).map((serial) => intValue(serial, 'id')).whereType<int>().toSet();

    line.serialIds = line.serialIds
        .where(allowedSerialIds.contains)
        .toList(growable: false);
    if (line.serialId != null && !allowedSerialIds.contains(line.serialId)) {
      line.serialId = null;
    }
    if (line.serialId == null && line.serialIds.length == 1) {
      line.serialId = line.serialIds.first;
    }
  }

  bool isBatchManagedItem(int? itemId) {
    if (itemId == null) {
      return false;
    }
    for (final item in items) {
      if (item.id == itemId) {
        return item.hasBatch;
      }
    }
    return false;
  }

  bool isSerialManagedItem(int? itemId) {
    if (itemId == null) {
      return false;
    }
    for (final item in items) {
      if (item.id == itemId) {
        return item.hasSerial;
      }
    }
    return false;
  }

  int serialFieldCountForLine(OpeningStockLineDraft line) {
    if (!isSerialManagedItem(line.itemId)) {
      return 0;
    }
    final qty = double.tryParse(line.qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      return 0;
    }
    return qty.floor();
  }

  void setLineSerialNumbers(int index, List<String> values) {
    if (index < 0 || index >= lines.length) {
      return;
    }
    final line = lines[index];
    final existingSerialMap = <String, int>{};
    for (
      var i = 0;
      i < line.serialNumbers.length && i < line.serialIds.length;
      i++
    ) {
      final serialNo = line.serialNumbers[i].trim().toLowerCase();
      final serialId = line.serialIds[i];
      if (serialNo.isNotEmpty && serialId > 0) {
        existingSerialMap[serialNo] = serialId;
      }
    }
    final normalizedValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    line.serialNumbers = List<String>.from(normalizedValues);
    line.serialIds = normalizedValues
        .map((value) => existingSerialMap[value.toLowerCase()])
        .whereType<int>()
        .toList(growable: false);
    if (isSerialManagedItem(line.itemId)) {
      line.qtyController.text = normalizedValues.length.toString();
    }
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

  List<Map<String, dynamic>> batchOptions(int? itemId, int? warehouseId) {
    return batches
        .map((e) => e.toJson())
        .where((b) {
          final itemOk = itemId == null || intValue(b, 'item_id') == itemId;
          final whOk =
              warehouseId == null || intValue(b, 'warehouse_id') == warehouseId;
          return itemOk && whOk;
        })
        .toList(growable: false);
  }

  List<OpeningStockLineDraft> _buildLineDrafts(
    List<Map<String, dynamic>> apiLines,
  ) {
    final grouped = <String, _OpeningStockGroupedLine>{};
    final ordered = <_OpeningStockGroupedLine>[];

    for (final line in apiLines) {
      final itemId = intValue(line, 'item_id');
      final hasSerial = isSerialManagedItem(itemId);
      if (!hasSerial) {
        ordered.add(_OpeningStockGroupedLine.fromLine(line));
        continue;
      }

      final key = [
        itemId ?? '',
        intValue(line, 'warehouse_id') ?? '',
        intValue(line, 'batch_id') ?? '',
        intValue(line, 'uom_id') ?? '',
        stringValue(line, 'unit_cost'),
        stringValue(line, 'remarks'),
      ].join('|');

      final alreadyGrouped = grouped.containsKey(key);
      final current = grouped.putIfAbsent(key, () {
        final created = _OpeningStockGroupedLine.fromLine(line);
        ordered.add(created);
        return created;
      });

      if (!alreadyGrouped) {
        continue;
      }

      current.qty += double.tryParse(stringValue(line, 'qty')) ?? 0;
      current.totalCost +=
          double.tryParse(stringValue(line, 'total_cost')) ??
          (double.tryParse(stringValue(line, 'unit_cost')) ?? 0);

      final serialNo = line['serial'] is Map<String, dynamic>
          ? stringValue(line['serial'] as Map<String, dynamic>, 'serial_no')
          : stringValue(line, 'serial_no');
      if (serialNo.trim().isNotEmpty) {
        current.serialNumbers.add(serialNo.trim());
      }
      final serialId = intValue(line, 'serial_id');
      if (serialId != null) {
        current.serialIds.add(serialId);
      }
      current.serialId = null;
    }

    return ordered.map((group) => group.toDraft()).toList(growable: true);
  }

  List<Map<String, dynamic>> serialOptions(
    int? itemId,
    int? warehouseId,
    int? batchId,
  ) {
    return serials
        .map((e) => e.toJson())
        .where((s) {
          final itemOk = itemId == null || intValue(s, 'item_id') == itemId;
          final whOk =
              warehouseId == null || intValue(s, 'warehouse_id') == warehouseId;
          final batchOk = batchId == null || intValue(s, 'batch_id') == batchId;
          final status = stringValue(s, 'status');
          return itemOk &&
              whOk &&
              batchOk &&
              (status == 'available' || status == 'returned');
        })
        .toList(growable: false);
  }

  String? validateLineSerialNumbers(int index, List<String> values) {
    if (index < 0 || index >= lines.length) {
      return null;
    }

    final currentLine = lines[index];
    final normalizedValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final normalizedSet = normalizedValues
        .map((value) => value.toLowerCase())
        .toSet();

    final existingSerialOwners = <String, Set<int>>{};
    for (final serial in serials) {
      final serialData = serial.toJson();
      final serialNo = stringValue(
        serialData,
        'serial_no',
      ).trim().toLowerCase();
      final serialId = intValue(serialData, 'id');
      if (serialNo.isEmpty || serialId == null) {
        continue;
      }
      existingSerialOwners.putIfAbsent(serialNo, () => <int>{}).add(serialId);
    }

    final allowedSerialIds = <int>{
      if (currentLine.serialId != null) currentLine.serialId!,
      ...currentLine.serialIds,
    };

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      if (lineIndex == index) {
        continue;
      }
      final otherLine = lines[lineIndex];
      final otherSerials = otherLine.serialNumbers
          .map((serial) => serial.trim())
          .where((serial) => serial.isNotEmpty)
          .toList(growable: false);
      for (final serialNo in otherSerials) {
        if (normalizedSet.contains(serialNo.toLowerCase())) {
          return "Serial number '$serialNo' is already used in another line.";
        }
      }
    }

    for (final serialNo in normalizedValues) {
      final existingIds = existingSerialOwners[serialNo.toLowerCase()];
      if (existingIds == null || existingIds.isEmpty) {
        continue;
      }
      final belongsToCurrentDraft = existingIds.any(allowedSerialIds.contains);
      if (!belongsToCurrentDraft) {
        return "Serial number '$serialNo' already exists. Enter a unique serial.";
      }
    }

    return null;
  }

  String? _validate() {
    if (companyId == null ||
        branchId == null ||
        locationId == null ||
        financialYearId == null) {
      return 'Company, branch, location, and financial year are required.';
    }
    if (documentSeriesId == null && openingNoController.text.trim().isEmpty) {
      return 'Either opening number or document series is required.';
    }
    if (openingDateController.text.trim().isEmpty) {
      return 'Opening date is required.';
    }
    if (lines.isEmpty) {
      return 'At least one line is required.';
    }
    final seenSerialNos = <String, int>{};
    final existingSerialOwners = <String, Set<int>>{};
    for (final serial in serials) {
      final serialData = serial.toJson();
      final serialNo = stringValue(
        serialData,
        'serial_no',
      ).trim().toLowerCase();
      final serialId = intValue(serialData, 'id');
      if (serialNo.isEmpty || serialId == null) {
        continue;
      }
      existingSerialOwners.putIfAbsent(serialNo, () => <int>{}).add(serialId);
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
      if (line.itemId == null ||
          line.warehouseId == null ||
          line.uomId == null) {
        return 'Item, warehouse, and UOM are required at line $lineNo.';
      }
      if (qty <= 0) {
        return 'Quantity must be greater than zero at line $lineNo.';
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

      final warehouseData = warehouses
          .map((e) => e.toJson())
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (warehouse) =>
                intValue(warehouse ?? const <String, dynamic>{}, 'id') ==
                line.warehouseId,
            orElse: () => null,
          );
      if (warehouseData == null) {
        return 'Invalid warehouse for selected context at line $lineNo.';
      }
      if (intValue(warehouseData, 'company_id') != companyId ||
          intValue(warehouseData, 'branch_id') != branchId ||
          intValue(warehouseData, 'location_id') != locationId) {
        return 'Invalid warehouse for selected context at line $lineNo.';
      }

      if (line.batchId != null) {
        final validBatch = batchOptions(
          line.itemId,
          line.warehouseId,
        ).any((batch) => intValue(batch, 'id') == line.batchId);
        if (!boolValue(itemData, 'has_batch') || !validBatch) {
          return 'Invalid batch at line $lineNo.';
        }
      }

      if (line.serialId != null) {
        final matchingSerial =
            serialOptions(
              line.itemId,
              line.warehouseId,
              line.batchId,
            ).cast<Map<String, dynamic>?>().firstWhere(
              (serial) =>
                  intValue(serial ?? const <String, dynamic>{}, 'id') ==
                  line.serialId,
              orElse: () => null,
            );
        if (!boolValue(itemData, 'has_serial') || matchingSerial == null) {
          return 'Invalid serial at line $lineNo.';
        }
        if (line.batchId != null &&
            intValue(matchingSerial, 'batch_id') != null &&
            intValue(matchingSerial, 'batch_id') != line.batchId) {
          return 'Serial does not belong to selected batch at line $lineNo.';
        }
        if (qty != 1) {
          return 'Serial-tracked quantity must be exactly 1 at line $lineNo.';
        }
      } else if (boolValue(itemData, 'has_serial')) {
        if (qty != qty.floorToDouble()) {
          return 'Serial-tracked quantity must be a whole number at line $lineNo.';
        }
        final expectedCount = qty.floor();
        final normalizedSerials = line.serialNumbers
            .map((serial) => serial.trim())
            .where((serial) => serial.isNotEmpty)
            .toList(growable: false);
        if (normalizedSerials.length != expectedCount) {
          return 'Enter exactly $expectedCount serial number(s) at line $lineNo.';
        }
        final unique = normalizedSerials
            .map((serial) => serial.toLowerCase())
            .toSet();
        if (unique.length != normalizedSerials.length) {
          return 'Duplicate serial numbers are not allowed at line $lineNo.';
        }
        final allowedSerialIds = <int>{
          if (line.serialId != null) line.serialId!,
          ...line.serialIds,
        };
        for (final serialNo in normalizedSerials) {
          final normalized = serialNo.toLowerCase();
          final firstSeenLine = seenSerialNos[normalized];
          if (firstSeenLine != null) {
            return "Serial number '$serialNo' is duplicated at line $lineNo.";
          }
          seenSerialNos[normalized] = lineNo;

          final existingIds = existingSerialOwners[normalized];
          if (existingIds == null || existingIds.isEmpty) {
            continue;
          }
          final belongsToCurrentDraft = existingIds.any(
            allowedSerialIds.contains,
          );
          if (!belongsToCurrentDraft) {
            return "Serial number '$serialNo' already exists. Enter a unique serial at line $lineNo.";
          }
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _expandedItemsForSave() {
    final expanded = <Map<String, dynamic>>[];
    for (final line in lines) {
      if (!isSerialManagedItem(line.itemId)) {
        expanded.add(line.toJson());
        continue;
      }

      final serialNumbers = line.serialNumbers
          .map((serial) => serial.trim())
          .where((serial) => serial.isNotEmpty)
          .toList(growable: false);
      if (serialNumbers.isEmpty) {
        expanded.add(line.toJson());
        continue;
      }

      final unitCost =
          double.tryParse(line.unitCostController.text.trim()) ?? 0;
      final remarks = nullIfEmpty(line.remarksController.text);
      for (var index = 0; index < serialNumbers.length; index++) {
        final serialNo = serialNumbers[index];
        expanded.add(<String, dynamic>{
          'item_id': line.itemId,
          'warehouse_id': line.warehouseId,
          'batch_id': line.batchId,
          'serial_id': index < line.serialIds.length
              ? line.serialIds[index]
              : null,
          'serial_no': serialNo,
          'uom_id': line.uomId,
          'qty': 1,
          'unit_cost': unitCost,
          'total_cost': unitCost,
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
      'opening_no': nullIfEmpty(openingNoController.text),
      'opening_date': openingDateController.text.trim(),
      'remarks': nullIfEmpty(remarksController.text),
      'items': _expandedItemsForSave(),
    };
    try {
      final response = selected == null
          ? await _inventoryService.createOpeningStock(
              OpeningStockModel(payload),
            )
          : await _inventoryService.updateOpeningStock(
              intValue(selected!.toJson(), 'id')!,
              OpeningStockModel(payload),
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
      final response = await _inventoryService.postOpeningStock(
        id,
        OpeningStockModel(const <String, dynamic>{}),
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
      final response = await _inventoryService.cancelOpeningStock(
        id,
        OpeningStockModel(const <String, dynamic>{}),
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
      final response = await _inventoryService.deleteOpeningStock(id);
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
    openingNoController.dispose();
    openingDateController.dispose();
    remarksController.dispose();
    for (final line in lines) {
      line.dispose();
    }
    super.dispose();
  }
}

class _OpeningStockGroupedLine {
  _OpeningStockGroupedLine({
    required this.itemId,
    required this.warehouseId,
    required this.batchId,
    required this.serialId,
    required this.serialIds,
    required this.uomId,
    required this.qty,
    required this.unitCost,
    required this.totalCost,
    required this.remarks,
    required this.serialNumbers,
  });

  factory _OpeningStockGroupedLine.fromLine(Map<String, dynamic> line) {
    final serialNo = line['serial'] is Map<String, dynamic>
        ? stringValue(line['serial'] as Map<String, dynamic>, 'serial_no')
        : stringValue(line, 'serial_no');
    return _OpeningStockGroupedLine(
      itemId: intValue(line, 'item_id'),
      warehouseId: intValue(line, 'warehouse_id'),
      batchId: intValue(line, 'batch_id'),
      serialId: intValue(line, 'serial_id'),
      serialIds: intValue(line, 'serial_id') == null
          ? <int>[]
          : <int>[intValue(line, 'serial_id')!],
      uomId: intValue(line, 'uom_id'),
      qty: double.tryParse(stringValue(line, 'qty')) ?? 0,
      unitCost: double.tryParse(stringValue(line, 'unit_cost')) ?? 0,
      totalCost: double.tryParse(stringValue(line, 'total_cost')) ?? 0,
      remarks: stringValue(line, 'remarks'),
      serialNumbers: serialNo.trim().isEmpty
          ? <String>[]
          : <String>[serialNo.trim()],
    );
  }

  int? itemId;
  int? warehouseId;
  int? batchId;
  int? serialId;
  List<int> serialIds;
  int? uomId;
  double qty;
  double unitCost;
  double totalCost;
  String remarks;
  List<String> serialNumbers;

  OpeningStockLineDraft toDraft() => OpeningStockLineDraft(
    itemId: itemId,
    warehouseId: warehouseId,
    batchId: batchId,
    serialId: serialId,
    serialIds: serialIds,
    serialNumbers: serialNumbers,
    uomId: uomId,
    qty: _formatDraftNumber(qty),
    unitCost: _formatDraftNumber(unitCost),
    totalCost: _formatDraftNumber(totalCost),
    remarks: remarks,
  );
}

String _formatDraftNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}
