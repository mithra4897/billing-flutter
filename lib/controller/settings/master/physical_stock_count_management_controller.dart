import '../../../screen.dart';

class PhysicalStockCountManagementController extends GetxController {
  PhysicalStockCountManagementController();

  static const List<AppDropdownItem<String>> scopeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'selected_items', label: 'Selected Items'),
        AppDropdownItem(value: 'full_warehouse', label: 'Full Warehouse'),
        AppDropdownItem(value: 'category', label: 'Category'),
        AppDropdownItem(value: 'batch', label: 'Batch'),
        AppDropdownItem(value: 'serial', label: 'Serial'),
      ];

  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController countNoController = TextEditingController();
  final TextEditingController countDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<PhysicalStockCountModel> items = const <PhysicalStockCountModel>[];
  List<PhysicalStockCountModel> filteredItems =
      const <PhysicalStockCountModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<ItemModel> allItems = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<StockBatchModel> batches = const <StockBatchModel>[];
  List<StockSerialModel> serials = const <StockSerialModel>[];
  List<StockBalanceModel> stockBalances = const <StockBalanceModel>[];
  PhysicalStockCountModel? selectedCount;
  List<PhysicalStockCountLineModel> lines = <PhysicalStockCountLineModel>[];
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? warehouseId;
  String countScope = 'selected_items';

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadData();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    countNoController.dispose();
    countDateController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.physicalStockCounts(
          filters: const {'per_page': 200, 'sort_by': 'count_date'},
        ),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.branches(filters: const {'per_page': 200}),
        _masterService.businessLocations(filters: const {'per_page': 200}),
        _masterService.financialYears(filters: const {'per_page': 200}),
        _masterService.documentSeries(filters: const {'per_page': 200}),
        _masterService.warehouses(filters: const {'per_page': 200}),
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'uom_name'},
        ),
        _inventoryService.stockBatchesDropdown(filters: const {}),
        _inventoryService.stockSerialsDropdown(filters: const {}),
        _inventoryService.stockBalances(
          filters: const {'per_page': 1000, 'sort_by': 'qty_available'},
        ),
      ]);

      final counts =
          (responses[0] as PaginatedResponse<PhysicalStockCountModel>).data ??
          const <PhysicalStockCountModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branchesResponse =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final locationsResponse =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final financialYears =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      final documentSeriesResponse =
          (responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
          const <DocumentSeriesModel>[];
      final warehouseResponse =
          (responses[6] as PaginatedResponse<WarehouseModel>).data ??
          const <WarehouseModel>[];
      final itemsResponse =
          (responses[7] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final uomsResponse =
          (responses[8] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final batchesResponse =
          (responses[9] as ApiResponse<List<StockBatchModel>>).data ??
          const <StockBatchModel>[];
      final serialsResponse =
          (responses[10] as ApiResponse<List<StockSerialModel>>).data ??
          const <StockSerialModel>[];
      final stockBalanceResponse =
          (responses[11] as PaginatedResponse<StockBalanceModel>).data ??
          const <StockBalanceModel>[];

      final activeCompanies = companies
          .where((company) => company.isActive)
          .toList();
      final activeBranches = branchesResponse
          .where((branch) => branch.isActive)
          .toList();
      final activeLocations = locationsResponse
          .where((location) => location.isActive)
          .toList();
      final activeFinancialYears = financialYears
          .where((fy) => fy.isActive)
          .toList();
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: activeBranches,
            locations: activeLocations,
            financialYears: activeFinancialYears,
          );

      items = counts;
      filteredItems = filterCounts(counts, searchController.text);
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      contextFinancialYearId = contextSelection.financialYearId;
      documentSeries = documentSeriesResponse
          .where((series) => series.documentType == 'STOCK_COUNT')
          .toList();
      warehouses = warehouseResponse
          .where((warehouse) => warehouse.isActive)
          .toList();
      allItems = itemsResponse.where((item) => item.isActive).toList();
      uoms = uomsResponse.where((uom) => uom.isActive).toList();
      batches = batchesResponse;
      serials = serialsResponse;
      stockBalances = stockBalanceResponse;
      initialLoading = false;

      final selected = selectId != null
          ? counts.cast<PhysicalStockCountModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedCount == null
                ? (counts.isNotEmpty ? counts.first : null)
                : counts.cast<PhysicalStockCountModel?>().firstWhere(
                    (item) => item?.id == selectedCount?.id,
                    orElse: () => counts.isNotEmpty ? counts.first : null,
                  ));

      if (selected != null) {
        selectCount(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
    }

    update();
  }

  List<PhysicalStockCountModel> filterCounts(
    List<PhysicalStockCountModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [
        item.countNo ?? '',
        item.countStatus ?? '',
        item.countScope ?? '',
        item.warehouseName ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredItems = filterCounts(items, searchController.text);
    update();
  }

  void selectCount(PhysicalStockCountModel item, {bool notify = true}) {
    selectedCount = item;
    companyId = item.companyId;
    branchId = item.branchId;
    locationId = item.locationId;
    financialYearId = item.financialYearId;
    documentSeriesId = item.documentSeriesId;
    warehouseId = item.warehouseId;
    countNoController.text = item.countNo ?? '';
    countDateController.text =
        item.countDate?.split('T').first.split(' ').first ??
        DateTime.now().toIso8601String().split('T').first;
    remarksController.text = item.remarks ?? '';
    countScope = item.countScope ?? 'selected_items';
    lines = item.items.toList(growable: true);
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedCount = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    documentSeriesId = filteredDocumentSeriesOptions.isNotEmpty
        ? filteredDocumentSeriesOptions.first.id
        : null;
    warehouseId = filteredWarehouseOptions.isNotEmpty
        ? filteredWarehouseOptions.first.id
        : null;
    countNoController.clear();
    countDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    remarksController.clear();
    countScope = 'selected_items';
    lines = <PhysicalStockCountLineModel>[];
    formError = null;
    if (notify) {
      update();
    }
  }

  List<DocumentSeriesModel> get filteredDocumentSeriesOptions => documentSeries
      .where((series) => companyId == null || series.companyId == companyId)
      .toList(growable: false);

  List<WarehouseModel> get filteredWarehouseOptions => warehouses
      .where(
        (warehouse) =>
            (companyId == null || warehouse.companyId == companyId) &&
            (branchId == null || warehouse.branchId == branchId) &&
            (locationId == null || warehouse.locationId == locationId),
      )
      .toList(growable: false);

  void addLine() {
    final defaultItem = allItems.isNotEmpty ? allItems.first : null;
    final defaultUomId =
        defaultItem?.baseUomId ?? (uoms.isNotEmpty ? uoms.first.id : null);
    lines = <PhysicalStockCountLineModel>[
      ...lines,
      _applySystemStock(
        PhysicalStockCountLineModel(
          itemId: defaultItem?.id,
          uomId: defaultUomId,
          countedQty: 0,
        ),
      ),
    ];
    update();
  }

  void updateLine(int index, PhysicalStockCountLineModel line) {
    lines[index] = _applySystemStock(line);
    update();
  }

  void removeLine(int index) {
    lines.removeAt(index);
    update();
  }

  List<StockBatchModel> batchOptionsForItem(int? itemId) {
    return batches
        .where((batch) {
          final json = batch.toJson();
          return itemId == null ||
              json['item_id']?.toString() == itemId.toString();
        })
        .toList(growable: false);
  }

  List<StockSerialModel> serialOptionsForItem(int? itemId, int? batchId) {
    return serials
        .where((serial) {
          final json = serial.toJson();
          final matchesItem =
              itemId == null ||
              json['item_id']?.toString() == itemId.toString();
          final matchesBatch =
              batchId == null ||
              json['batch_id']?.toString() == batchId.toString();
          return matchesItem && matchesBatch;
        })
        .toList(growable: false);
  }

  String batchLabel(StockBatchModel batch) {
    final json = batch.toJson();
    return json['batch_no']?.toString() ?? 'Batch';
  }

  String serialLabel(StockSerialModel serial) {
    final json = serial.toJson();
    return json['serial_no']?.toString() ?? 'Serial';
  }

  PhysicalStockCountLineModel _applySystemStock(
    PhysicalStockCountLineModel line,
  ) {
    final systemQty = _resolveSystemQty(line);
    final unitCost = line.unitCost ?? _resolveUnitCost(line);
    final countedQty = line.countedQty;
    final varianceQty = countedQty == null || systemQty == null
        ? null
        : countedQty - systemQty;

    return PhysicalStockCountLineModel(
      id: line.id,
      itemId: line.itemId,
      uomId: line.uomId,
      batchId: line.batchId,
      serialId: line.serialId,
      systemQty: systemQty,
      countedQty: countedQty,
      varianceQty: varianceQty,
      unitCost: unitCost,
      varianceValue: varianceQty == null || unitCost == null
          ? null
          : varianceQty * unitCost,
      varianceType: varianceQty == null
          ? null
          : varianceQty > 0
          ? 'excess'
          : varianceQty < 0
          ? 'shortage'
          : 'matched',
      isReconciled: line.isReconciled,
      remarks: line.remarks,
      itemCode: line.itemCode,
      itemName: line.itemName,
      batchNo: line.batchNo,
      serialNo: line.serialNo,
      uomCode: line.uomCode,
      uomName: line.uomName,
      uomSymbol: line.uomSymbol,
    );
  }

  double? _resolveSystemQty(PhysicalStockCountLineModel line) {
    if (warehouseId == null || line.itemId == null) {
      return null;
    }

    final matches = stockBalances.where((balance) {
      final sameWarehouse = balance.warehouseId == warehouseId;
      final sameItem = balance.itemId == line.itemId;
      final sameBatch = line.batchId == null || balance.batchId == line.batchId;
      final sameSerial =
          line.serialId == null || balance.serialId == line.serialId;
      return sameWarehouse && sameItem && sameBatch && sameSerial;
    });

    final total = matches.fold<double>(
      0,
      (sum, balance) => sum + (balance.qtyAvailable ?? 0),
    );
    return total;
  }

  double? _resolveUnitCost(PhysicalStockCountLineModel line) {
    if (warehouseId == null || line.itemId == null) {
      return null;
    }
    final balance = stockBalances.cast<StockBalanceModel?>().firstWhere(
      (entry) =>
          entry?.warehouseId == warehouseId &&
          entry?.itemId == line.itemId &&
          (line.batchId == null || entry?.batchId == line.batchId) &&
          (line.serialId == null || entry?.serialId == line.serialId),
      orElse: () => null,
    );
    return balance?.avgCost;
  }

  PhysicalStockCountModel buildModel() {
    return PhysicalStockCountModel(
      id: selectedCount?.id,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
      documentSeriesId: documentSeriesId,
      warehouseId: warehouseId,
      countNo: nullIfEmpty(countNoController.text),
      countDate: countDateController.text.trim(),
      countScope: countScope,
      remarks: nullIfEmpty(remarksController.text),
      items: lines,
    );
  }

  Future<void> save() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }
    if (lines.isEmpty) {
      formError = 'At least one item line is required';
      update();
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = buildModel();
    try {
      final response = selectedCount == null
          ? await _inventoryService.createPhysicalStockCount(model)
          : await _inventoryService.updatePhysicalStockCount(
              selectedCount!.id!,
              model,
            );
      final saved = response.data;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: saved?.id);
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> deleteSelected() async {
    final id = selectedCount?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _inventoryService.deletePhysicalStockCount(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData();
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> markCounted() async {
    final id = selectedCount?.id;
    if (id == null) {
      return;
    }
    await runDocumentAction(
      () => _inventoryService.markPhysicalCounted(id, buildModel()),
    );
  }

  Future<void> reconcile() async {
    final id = selectedCount?.id;
    if (id == null) {
      return;
    }
    await runDocumentAction(
      () => _inventoryService.reconcilePhysicalStockCount(id, buildModel()),
    );
  }

  Future<void> cancel() async {
    final id = selectedCount?.id;
    if (id == null) {
      return;
    }
    await runDocumentAction(
      () => _inventoryService.cancelPhysicalStockCount(id, buildModel()),
    );
  }

  Future<void> runDocumentAction(
    Future<ApiResponse<PhysicalStockCountModel>> Function() action,
  ) async {
    saving = true;
    formError = null;
    update();

    try {
      final response = await action();
      final saved = response.data;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: saved?.id);
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  void startNew({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void setDocumentSeriesId(int? value) {
    documentSeriesId = value;
    update();
  }

  void setWarehouseId(int? value) {
    warehouseId = value;
    lines = lines.map(_applySystemStock).toList(growable: true);
    update();
  }

  void setCountScope(String? value) {
    countScope = value ?? 'selected_items';
    update();
  }
}
