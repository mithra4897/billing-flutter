import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class ProductionMaterialIssueLineDraft {
  ProductionMaterialIssueLineDraft({
    this.itemId,
    this.productionOrderMaterialId,
    this.batchId,
    this.serialId,
    this.uomId,
    this.warehouseId,
    String? issueQty,
    String? unitCost,
    String? remarks,
  }) : issueQtyController = TextEditingController(text: issueQty ?? ''),
       unitCostController = TextEditingController(text: unitCost ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory ProductionMaterialIssueLineDraft.fromJson(Map<String, dynamic> json) {
    return ProductionMaterialIssueLineDraft(
      itemId: intValue(json, 'item_id'),
      productionOrderMaterialId: intValue(json, 'production_order_material_id'),
      batchId: intValue(json, 'batch_id'),
      serialId: intValue(json, 'serial_id'),
      uomId: intValue(json, 'uom_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      issueQty: stringValue(json, 'issue_qty'),
      unitCost: stringValue(json, 'unit_cost'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? itemId;
  int? productionOrderMaterialId;
  int? batchId;
  int? serialId;
  int? uomId;
  int? warehouseId;
  final TextEditingController issueQtyController;
  final TextEditingController unitCostController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'item_id': itemId,
    'production_order_material_id': productionOrderMaterialId,
    'batch_id': batchId,
    'serial_id': serialId,
    'uom_id': uomId,
    'warehouse_id': warehouseId,
    'issue_qty': double.tryParse(issueQtyController.text.trim()) ?? 0,
    'unit_cost': double.tryParse(unitCostController.text.trim()) ?? 0,
    'remarks': nullIfEmpty(remarksController.text),
  };

  void dispose() {
    issueQtyController.dispose();
    unitCostController.dispose();
    remarksController.dispose();
  }
}

class ProductionMaterialIssueViewModel extends ChangeNotifier {
  final ManufacturingService _service = ManufacturingService();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController issueNoController = TextEditingController();
  final TextEditingController issueDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<ProductionMaterialIssueModel> rows =
      const <ProductionMaterialIssueModel>[];
  List<ProductionOrderModel> productionOrders = const <ProductionOrderModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<StockBatchModel> batches = const <StockBatchModel>[];
  List<StockSerialModel> serials = const <StockSerialModel>[];
  List<StockBalanceModel> stockBalances = const <StockBalanceModel>[];
  final Map<int, ProductionOrderModel> _productionOrderDetailsById =
      <int, ProductionOrderModel>{};

  ProductionMaterialIssueModel? selected;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? productionOrderId;
  int? warehouseId;
  bool isActive = true;
  List<ProductionMaterialIssueLineDraft> lines =
      <ProductionMaterialIssueLineDraft>[];
  bool _isDisposed = false;

  ProductionMaterialIssueViewModel() {
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _notifySafely();
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  bool get isDraft =>
      stringValue(selected?.toJson() ?? const {}, 'issue_status', 'draft') ==
      'draft';

  ProductionOrderModel? get selectedProductionOrder {
    final id = productionOrderId;
    if (id == null) {
      return null;
    }
    return _productionOrderDetailsById[id] ??
        productionOrders.cast<ProductionOrderModel?>().firstWhere(
          (row) =>
              intValue(row?.toJson() ?? const <String, dynamic>{}, 'id') == id,
          orElse: () => null,
        );
  }

  List<Map<String, dynamic>> get productionOrderMaterials {
    final data = selectedProductionOrder?.toJson() ?? const <String, dynamic>{};
    return (data['materials'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  List<ItemModel> get lineItemOptions {
    final materials = productionOrderMaterials;
    if (materials.isEmpty) {
      return items;
    }
    final ids = materials
        .map((m) => intValue(m, 'item_id'))
        .whereType<int>()
        .toSet();
    return items
        .where((item) => item.id != null && ids.contains(item.id))
        .toList(growable: false);
  }

  List<DocumentSeriesModel> get seriesOptions {
    final options = documentSeries
        .where((series) {
          if (series.documentType != 'PRODUCTION_MATERIAL_ISSUE') {
            return false;
          }
          if (companyId != null && series.companyId != companyId) {
            return false;
          }
          if (branchId != null &&
              series.branchId != null &&
              series.branchId != branchId) {
            return false;
          }
          if (locationId != null &&
              series.locationId != null &&
              series.locationId != locationId) {
            return false;
          }
          if (financialYearId != null &&
              series.financialYearId != null &&
              series.financialYearId != financialYearId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    if (documentSeriesId == null ||
        options.any((x) => x.id == documentSeriesId)) {
      return options;
    }

    final current = documentSeries.cast<DocumentSeriesModel?>().firstWhere(
      (x) => x?.id == documentSeriesId,
      orElse: () => null,
    );

    return current == null
        ? options
        : <DocumentSeriesModel>[...options, current];
  }

  List<ProductionMaterialIssueModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          if (q.isEmpty) return true;
          return [
            stringValue(data, 'issue_no'),
            stringValue(data, 'issue_status'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  DocumentSeriesModel? get _resolvedDocumentSeries {
    DocumentSeriesModel? fallback;
    for (final series in documentSeries) {
      final seriesData = series.toJson();
      final seriesBranchId = intValue(seriesData, 'branch_id');
      final seriesLocationId = intValue(seriesData, 'location_id');
      if (series.documentType != 'PRODUCTION_MATERIAL_ISSUE') {
        continue;
      }
      if (companyId != null && series.companyId != companyId) {
        continue;
      }
      if (branchId != null &&
          seriesBranchId != null &&
          seriesBranchId != branchId) {
        continue;
      }
      if (locationId != null &&
          seriesLocationId != null &&
          seriesLocationId != locationId) {
        continue;
      }
      if (financialYearId != null &&
          series.financialYearId != null &&
          series.financialYearId != financialYearId) {
        continue;
      }
      if (documentSeriesId == series.id) {
        return series;
      }
      fallback ??= series;
      if (series.isDefault) {
        return series;
      }
    }
    return fallback;
  }

  void _syncDocumentSeries() {
    documentSeriesId = _resolvedDocumentSeries?.id;
  }

  void setProductionOrderId(int? value) {
    if (!isDraft && selected != null) return;
    productionOrderId = value;
    for (final line in lines) {
      line.productionOrderMaterialId = null;
      line.itemId = null;
      line.batchId = null;
      line.serialId = null;
      line.uomId = null;
      line.warehouseId = warehouseId;
    }
    final order = productionOrders.cast<ProductionOrderModel?>().firstWhere(
      (row) =>
          intValue(row?.toJson() ?? const <String, dynamic>{}, 'id') == value,
      orElse: () => null,
    );
    if (order != null) {
      final data = order.toJson();
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      warehouseId = intValue(data, 'warehouse_id') ?? warehouseId;
      _syncDocumentSeries();
      _loadProductionOrderDetail(value);
    } else {
      _syncDocumentSeries();
    }
    _notifySafely();
  }

  Future<void> _loadProductionOrderDetail(int? id) async {
    if (id == null) {
      return;
    }
    try {
      final response = await _service.productionOrder(id);
      final detail = response.data;
      if (detail == null || _isDisposed) {
        return;
      }
      _productionOrderDetailsById[id] = detail;
      _notifySafely();
    } catch (_) {}
  }

  void setLineWarehouseId(int index, int? value) {
    if ((!isDraft && selected != null) || index < 0 || index >= lines.length) {
      return;
    }
    lines[index].warehouseId = value;
    lines[index].batchId = null;
    lines[index].serialId = null;
    _notifySafely();
  }

  void setDocumentSeriesId(int? value) {
    if (!isDraft && selected != null) {
      return;
    }
    documentSeriesId = value;
    _notifySafely();
  }

  Future<void> load({int? selectId, bool includeList = true}) async {
    loading = true;
    pageError = null;
    _notifySafely();
    try {
      final responses = await Future.wait<dynamic>([
        if (includeList)
          _service.productionMaterialIssues(
            filters: const {'per_page': 200, 'sort_by': 'issue_date'},
          ),
        _service.productionOrders(filters: const {'per_page': 200}),
        _masterService.documentSeries(
          filters: const {
            'per_page': 1000,
            'document_type': 'PRODUCTION_MATERIAL_ISSUE',
          },
        ),
        _inventoryService.items(filters: const {'per_page': 500}),
        _inventoryService.uoms(filters: const {'per_page': 300}),
        _inventoryService.uomConversionsAll(
          filters: const {'per_page': 500, 'sort_by': 'from_uom_id'},
        ),
        _masterService.warehouses(filters: const {'per_page': 300}),
        _inventoryService.stockBatches(filters: const {'per_page': 500}),
        _inventoryService.stockSerials(filters: const {'per_page': 500}),
        _inventoryService.stockBalances(
          filters: const {'per_page': 1000, 'available_only': 1},
        ),
      ]);
      var offset = 0;
      if (includeList) {
        rows =
            (responses[offset]
                    as PaginatedResponse<ProductionMaterialIssueModel>)
                .data ??
            const <ProductionMaterialIssueModel>[];
        offset += 1;
      } else {
        rows = const <ProductionMaterialIssueModel>[];
      }
      productionOrders =
          (responses[offset] as PaginatedResponse<ProductionOrderModel>).data ??
          const <ProductionOrderModel>[];
      offset += 1;
      documentSeries =
          ((responses[offset] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      offset += 1;
      items =
          ((responses[offset] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      offset += 1;
      uoms =
          ((responses[offset] as PaginatedResponse<UomModel>).data ??
                  const <UomModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      offset += 1;
      uomConversions =
          ((responses[offset] as PaginatedResponse<UomConversionModel>).data ??
                  const <UomConversionModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      offset += 1;
      warehouses =
          ((responses[offset] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      offset += 1;
      batches =
          (responses[offset] as PaginatedResponse<StockBatchModel>).data ??
          const <StockBatchModel>[];
      offset += 1;
      serials =
          (responses[offset] as PaginatedResponse<StockSerialModel>).data ??
          const <StockSerialModel>[];
      offset += 1;
      stockBalances =
          (responses[offset] as PaginatedResponse<StockBalanceModel>).data ??
          const <StockBalanceModel>[];
      loading = false;

      if (selectId != null) {
        if (includeList) {
          final existing = rows
              .cast<ProductionMaterialIssueModel?>()
              .firstWhere(
                (x) =>
                    intValue(x?.toJson() ?? const <String, dynamic>{}, 'id') ==
                    selectId,
                orElse: () => null,
              );
          if (existing != null) {
            await select(existing);
            return;
          }
        } else {
          final response = await _service.productionMaterialIssue(selectId);
          if (response.data != null) {
            await select(response.data!);
            return;
          }
        }
      }
      resetDraft();
      _notifySafely();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      _notifySafely();
    }
  }

  void resetDraft() {
    for (final line in lines) {
      line.dispose();
    }
    selected = null;
    formError = null;
    issueNoController.clear();
    issueDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    remarksController.clear();
    productionOrderId = null;
    warehouseId = warehouses.isNotEmpty ? warehouses.first.id : null;
    isActive = true;
    lines = <ProductionMaterialIssueLineDraft>[
      ProductionMaterialIssueLineDraft(),
    ];
    _syncDocumentSeries();
    _notifySafely();
  }

  Future<void> select(ProductionMaterialIssueModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    _notifySafely();
    try {
      final response = await _service.productionMaterialIssue(id);
      final data = (response.data ?? row).toJson();
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      documentSeriesId = intValue(data, 'document_series_id');
      productionOrderId = intValue(data, 'production_order_id');
      warehouseId = intValue(data, 'warehouse_id');
      issueNoController.text = stringValue(data, 'issue_no');
      issueDateController.text = displayDate(
        nullableStringValue(data, 'issue_date'),
      );
      remarksController.text = stringValue(data, 'remarks');
      isActive = boolValue(data, 'is_active', fallback: true);
      for (final line in lines) {
        line.dispose();
      }
      final rawLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      lines = rawLines.isEmpty
          ? <ProductionMaterialIssueLineDraft>[
              ProductionMaterialIssueLineDraft(),
            ]
          : rawLines
                .map(ProductionMaterialIssueLineDraft.fromJson)
                .toList(growable: true);
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      _notifySafely();
    }
  }

  void addLine() {
    if (!isDraft && selected != null) return;
    lines = List<ProductionMaterialIssueLineDraft>.from(lines)
      ..add(ProductionMaterialIssueLineDraft(warehouseId: warehouseId));
    _notifySafely();
  }

  void removeLine(int index) {
    if ((!isDraft && selected != null) || index < 0 || index >= lines.length) {
      return;
    }
    final next = List<ProductionMaterialIssueLineDraft>.from(lines);
    next.removeAt(index).dispose();
    lines = next.isEmpty
        ? <ProductionMaterialIssueLineDraft>[ProductionMaterialIssueLineDraft()]
        : next;
    _notifySafely();
  }

  void setLineItemId(int index, int? value) {
    if ((!isDraft && selected != null) || index < 0 || index >= lines.length) {
      return;
    }
    lines[index].itemId = value;
    final material = productionOrderMaterials
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (entry) =>
              intValue(entry ?? const <String, dynamic>{}, 'item_id') == value,
          orElse: () => null,
        );
    lines[index].productionOrderMaterialId = intValue(
      material ?? const <String, dynamic>{},
      'id',
    );
    lines[index].batchId = null;
    lines[index].serialId = null;
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == value,
      orElse: () => null,
    );
    lines[index].uomId =
        intValue(material ?? const <String, dynamic>{}, 'uom_id') ??
        defaultUomIdForItem(
          item,
          uoms,
          uomConversions,
          current: lines[index].uomId,
        );
    lines[index].warehouseId = _preferredWarehouseIdForItem(
      value,
      intValue(material ?? const <String, dynamic>{}, 'warehouse_id') ??
          warehouseId,
    );
    _notifySafely();
  }

  void setLineUomId(int index, int? value) {
    if ((!isDraft && selected != null) || index < 0 || index >= lines.length) {
      return;
    }
    lines[index].uomId = value;
    _notifySafely();
  }

  void setLineBatchId(int index, int? value) {
    if ((!isDraft && selected != null) || index < 0 || index >= lines.length) {
      return;
    }
    lines[index].batchId = value;
    lines[index].serialId = null;
    _notifySafely();
  }

  void setLineSerialId(int index, int? value) {
    if ((!isDraft && selected != null) || index < 0 || index >= lines.length) {
      return;
    }
    lines[index].serialId = value;
    _notifySafely();
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    if (itemId == null) return const <UomModel>[];
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, uoms, uomConversions);
  }

  List<StockBalanceModel> _matchingBalancesForLine(
    int? itemId,
    int? warehouseId, {
    int? batchId,
    int? serialId,
  }) {
    return stockBalances.where((balance) {
      final itemOk = itemId == null || balance.itemId == itemId;
      final whOk = warehouseId == null || balance.warehouseId == warehouseId;
      final companyOk = companyId == null || balance.companyId == companyId;
      final branchOk = branchId == null || balance.branchId == branchId;
      final locationOk = locationId == null || balance.locationId == locationId;
      final batchOk = batchId == null || balance.batchId == batchId;
      final serialOk = serialId == null || balance.serialId == serialId;
      final qtyOk = (balance.qtyAvailable ?? 0) > 0;
      return itemOk &&
          whOk &&
          companyOk &&
          branchOk &&
          locationOk &&
          batchOk &&
          serialOk &&
          qtyOk;
    }).toList(growable: false);
  }

  List<WarehouseModel> warehouseOptionsForItem(int? itemId) {
    if (itemId == null) {
      return warehouses;
    }

    final warehouseIds = _matchingBalancesForLine(itemId, null)
        .map((balance) => balance.warehouseId)
        .whereType<int>()
        .toSet();

    if (warehouseIds.isEmpty) {
      return warehouses;
    }

    return warehouses
        .where(
          (warehouse) => warehouse.id != null && warehouseIds.contains(warehouse.id),
        )
        .toList(growable: false);
  }

  int? _preferredWarehouseIdForItem(
    int? itemId,
    int? preferredWarehouseId,
  ) {
    final options = warehouseOptionsForItem(itemId);
    if (preferredWarehouseId != null &&
        options.any((warehouse) => warehouse.id == preferredWarehouseId)) {
      return preferredWarehouseId;
    }
    if (options.isNotEmpty) {
      return options.first.id;
    }
    return preferredWarehouseId ?? warehouseId;
  }

  bool hasAvailableStockForLine(
    int? itemId,
    int? warehouseId,
    double requiredQty, {
    int? batchId,
    int? serialId,
  }) {
    if (requiredQty <= 0) {
      return false;
    }

    final directAvailable = _matchingBalancesForLine(
      itemId,
      warehouseId,
      batchId: batchId,
      serialId: serialId,
    ).fold<double>(0, (sum, balance) => sum + (balance.qtyAvailable ?? 0));

    if (directAvailable >= requiredQty) {
      return true;
    }

    if (batchId != null && serialId == null) {
      final legacyAvailable = _matchingBalancesForLine(itemId, warehouseId)
          .where((balance) => balance.batchId == null && balance.serialId == null)
          .fold<double>(0, (sum, balance) => sum + (balance.qtyAvailable ?? 0));
      return legacyAvailable >= requiredQty;
    }

    return false;
  }

  List<StockBatchModel> batchOptions(int? itemId, int? warehouseId) {
    final matchingBalances = _matchingBalancesForLine(itemId, warehouseId);

    final balanceBatchIds = matchingBalances
        .where((balance) {
          return balance.batchId != null;
        })
        .map((balance) => balance.batchId)
        .whereType<int>()
        .toSet();

    final hasLegacyUnbatchedBalance = matchingBalances.any(
      (balance) => balance.batchId == null && balance.serialId == null,
    );
    final hasPositiveBatchSpecificBalance = matchingBalances.any(
      (balance) =>
          balance.batchId != null &&
          ((balance.qtyOnHand ?? 0) > 0 ||
              (balance.qtyAvailable ?? 0) > 0 ||
              (balance.qtyReserved ?? 0) > 0),
    );

    return batches
        .where((batch) {
          final data = batch.toJson();
          final id = intValue(data, 'id');
          final itemOk = itemId == null || intValue(data, 'item_id') == itemId;
          final whOk =
              warehouseId == null ||
              intValue(data, 'warehouse_id') == warehouseId;
          if (!itemOk || !whOk || id == null) {
            return false;
          }
          if (balanceBatchIds.contains(id)) {
            return true;
          }
          if (!hasLegacyUnbatchedBalance || hasPositiveBatchSpecificBalance) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  bool isBatchValidForLine(int? batchId, int? itemId, int? warehouseId) {
    if (batchId == null) {
      return false;
    }

    final inOptions = batchOptions(
      itemId,
      warehouseId,
    ).any((batch) => intValue(batch.toJson(), 'id') == batchId);
    if (inOptions) {
      return true;
    }

    return batches.any((batch) {
      final data = batch.toJson();
      return intValue(data, 'id') == batchId &&
          (itemId == null || intValue(data, 'item_id') == itemId) &&
          (warehouseId == null || intValue(data, 'warehouse_id') == warehouseId);
    });
  }

  List<StockSerialModel> serialOptions(
    int? itemId,
    int? warehouseId,
    int? batchId,
  ) {
    final balanceSerialIds = stockBalances
        .where((balance) {
          final itemOk = itemId == null || balance.itemId == itemId;
          final whOk =
              warehouseId == null || balance.warehouseId == warehouseId;
          final batchOk = batchId == null || balance.batchId == batchId;
          final companyOk = companyId == null || balance.companyId == companyId;
          final branchOk = branchId == null || balance.branchId == branchId;
          final locationOk =
              locationId == null || balance.locationId == locationId;
          final qtyOk = (balance.qtyAvailable ?? 0) > 0;
          return itemOk &&
              whOk &&
              batchOk &&
              companyOk &&
              branchOk &&
              locationOk &&
              qtyOk &&
              balance.serialId != null;
        })
        .map((balance) => balance.serialId)
        .whereType<int>()
        .toSet();

    return serials
        .where((serial) {
          final data = serial.toJson();
          final id = intValue(data, 'id');
          final itemOk = itemId == null || intValue(data, 'item_id') == itemId;
          final whOk =
              warehouseId == null ||
              intValue(data, 'warehouse_id') == warehouseId;
          final batchOk =
              batchId == null || intValue(data, 'batch_id') == batchId;
          final status = stringValue(data, 'status');
          return itemOk &&
              whOk &&
              batchOk &&
              id != null &&
              balanceSerialIds.contains(id) &&
              (status == 'available' || status == 'returned');
        })
        .toList(growable: false);
  }

  String? _validate() {
    if (companyId == null ||
        branchId == null ||
        locationId == null ||
        financialYearId == null) {
      return 'Company, branch, location and financial year are required.';
    }
    if (warehouseId == null) {
      return 'Warehouse is required.';
    }
    if (productionOrderId == null) {
      return 'Production order is required.';
    }
    if (_resolvedDocumentSeries == null &&
        issueNoController.text.trim().isEmpty) {
      return 'A production material issue document series is required for the selected order.';
    }
    if (lines.isEmpty) {
      return 'At least one line is required.';
    }
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.itemId == null ||
          line.uomId == null ||
          line.warehouseId == null) {
        return 'Line ${i + 1}: item, UOM and warehouse are required.';
      }
      if (productionOrderMaterials.isNotEmpty) {
        final validMaterial = productionOrderMaterials.any(
          (material) =>
              intValue(material, 'item_id') == line.itemId &&
              intValue(material, 'id') == line.productionOrderMaterialId,
        );
        if (!validMaterial) {
          return 'Line ${i + 1}: item must belong to the selected production order.';
        }
      }
      final issueQty = double.tryParse(line.issueQtyController.text.trim()) ?? 0;
      if (issueQty <= 0) {
        return 'Line ${i + 1}: issue qty must be > 0.';
      }
      final item = items.cast<ItemModel?>().firstWhere(
        (entry) => entry?.id == line.itemId,
        orElse: () => null,
      );
      if (item == null || !item.trackInventory) {
        return 'Line ${i + 1}: invalid inventory item.';
      }
      if (item.hasBatch) {
        if (line.batchId == null) {
          return 'Line ${i + 1}: batch is required for batch-managed item.';
        }
        final validBatch = isBatchValidForLine(
          line.batchId,
          line.itemId,
          line.warehouseId,
        );
        if (!validBatch) {
          return 'Line ${i + 1}: invalid batch for selected warehouse.';
        }
        if (!hasAvailableStockForLine(
          line.itemId,
          line.warehouseId,
          issueQty,
          batchId: line.batchId,
        )) {
          return 'Line ${i + 1}: no available batch stock found for the selected warehouse.';
        }
      } else if (line.batchId != null) {
        return 'Line ${i + 1}: batch is not allowed for this item.';
      } else if (!hasAvailableStockForLine(
        line.itemId,
        line.warehouseId,
        issueQty,
      )) {
        return 'Line ${i + 1}: no available stock found for the selected warehouse.';
      }
      if (item.hasSerial) {
        if (line.serialId == null) {
          return 'Line ${i + 1}: serial is required for serial-tracked item.';
        }
        if ((double.tryParse(line.issueQtyController.text.trim()) ?? 0) != 1) {
          return 'Line ${i + 1}: serial issue qty must be exactly 1.';
        }
        final serial =
            serialOptions(
              line.itemId,
              line.warehouseId,
              line.batchId,
            ).cast<StockSerialModel?>().firstWhere(
              (entry) =>
                  intValue(
                    entry?.toJson() ?? const <String, dynamic>{},
                    'id',
                  ) ==
                  line.serialId,
              orElse: () => null,
            );
        if (serial == null) {
          return 'Line ${i + 1}: invalid serial for selected warehouse/batch.';
        }
      } else if (line.serialId != null) {
        return 'Line ${i + 1}: serial is not allowed for this item.';
      }
    }
    return null;
  }

  Future<void> save() async {
    final validationError = _validate();
    if (validationError != null) {
      formError = validationError;
      _notifySafely();
      return;
    }
    saving = true;
    formError = null;
    actionMessage = null;
    _syncDocumentSeries();
    _notifySafely();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_series_id': documentSeriesId,
      'issue_no': nullIfEmpty(issueNoController.text),
      'issue_date': issueDateController.text.trim(),
      'production_order_id': productionOrderId,
      'warehouse_id': warehouseId,
      'remarks': nullIfEmpty(remarksController.text),
      'is_active': isActive ? 1 : 0,
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
    };
    try {
      final response = selected == null
          ? await _service.createProductionMaterialIssue(
              ProductionMaterialIssueModel(payload),
            )
          : await _service.updateProductionMaterialIssue(
              intValue(selected!.toJson(), 'id')!,
              ProductionMaterialIssueModel(payload),
            );
      actionMessage = response.message;
      await load(
        selectId: intValue(
          response.data?.toJson() ?? const <String, dynamic>{},
          'id',
        ),
      );
    } catch (e) {
      formError = e.toString();
      _notifySafely();
    } finally {
      saving = false;
      _notifySafely();
    }
  }

  Future<void> post() async {
    final validationError = _validate();
    if (validationError != null) {
      formError = validationError;
      _notifySafely();
      return;
    }
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.postProductionMaterialIssue(
        id,
        const ProductionMaterialIssueModel(<String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      _notifySafely();
    }
  }

  Future<void> cancel() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.cancelProductionMaterialIssue(
        id,
        const ProductionMaterialIssueModel(<String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      _notifySafely();
    }
  }

  Future<void> delete() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      await _service.deleteProductionMaterialIssue(id);
      actionMessage = 'Production material issue deleted successfully.';
      await load();
    } catch (e) {
      formError = e.toString();
      _notifySafely();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    issueNoController.dispose();
    issueDateController.dispose();
    remarksController.dispose();
    for (final line in lines) {
      line.dispose();
    }
    super.dispose();
  }
}
