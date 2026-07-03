import '../../../screen.dart';
import 'manufacturing_module_refresh_controller.dart';

class ProductionOrderViewModel extends GetxController {
  final ManufacturingModuleRefreshController _refreshController =
      ManufacturingModuleRefreshController.ensureRegistered();
  final ManufacturingService _service = ManufacturingService();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController productionNoController = TextEditingController();
  final TextEditingController productionDateController =
      TextEditingController();
  final TextEditingController plannedQtyController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<ProductionOrderModel> rows = const <ProductionOrderModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<BomModel> boms = const <BomModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];

  ProductionOrderModel? selected;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? bomId;
  int? outputItemId;
  int? outputUomId;
  int? warehouseId;
  bool isActive = true;

  void _handleWorkingContextChanged() {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    load(selectId: id);
  }

  ProductionOrderViewModel() {
    searchController.addListener(update);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  bool get isLocked {
    final status = stringValue(
      selected?.toJson() ?? const <String, dynamic>{},
      'production_status',
      'draft',
    );
    return status == 'completed' || status == 'closed' || status == 'cancelled';
  }

  List<BranchModel> get branchOptions =>
      branchesForCompany(branches, companyId);
  List<BusinessLocationModel> get locationOptions =>
      locationsForBranch(locations, branchId);
  List<FinancialYearModel> get financialYearOptions => financialYears
      .where((fy) => companyId == null || fy.companyId == companyId)
      .toList(growable: false);

  List<DocumentSeriesModel> get seriesOptions {
    final options = documentSeries
        .where((series) {
          if (series.documentType != 'PRODUCTION_ORDER') {
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
        options.any((series) => series.id == documentSeriesId)) {
      return options;
    }

    final current = documentSeries.cast<DocumentSeriesModel?>().firstWhere(
      (series) => series?.id == documentSeriesId,
      orElse: () => null,
    );

    return current == null
        ? options
        : <DocumentSeriesModel>[...options, current];
  }

  DocumentSeriesModel? get _resolvedDocumentSeries {
    DocumentSeriesModel? fallback;
    for (final series in documentSeries) {
      if (series.documentType != 'PRODUCTION_ORDER') {
        continue;
      }
      if (companyId != null && series.companyId != companyId) {
        continue;
      }
      if (branchId != null &&
          series.branchId != null &&
          series.branchId != branchId) {
        continue;
      }
      if (locationId != null &&
          series.locationId != null &&
          series.locationId != locationId) {
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

  List<BomModel> get bomOptions => boms
      .where((bom) {
        final data = bom.toJson();
        final approval = stringValue(data, 'approval_status');
        final sameCompany =
            companyId == null || intValue(data, 'company_id') == companyId;
        return approval == 'approved' && sameCompany;
      })
      .toList(growable: false);

  List<ItemModel> get outputItemOptions => items
      .where((item) {
        return companyId == null || item.companyId == companyId;
      })
      .toList(growable: false);

  List<WarehouseModel> get warehouseOptions => warehouses
      .where((w) {
        if (w.id == null) return false;
        if (companyId != null && w.companyId != companyId) return false;
        if (branchId != null && w.branchId != branchId) return false;
        if (locationId != null && w.locationId != locationId) return false;
        return true;
      })
      .toList(growable: false);

  List<ProductionOrderModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          if (q.isEmpty) return true;
          return [
            stringValue(data, 'production_no'),
            stringValue(data, 'production_status'),
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
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _service.productionOrders(
          filters: const {'per_page': 200, 'sort_by': 'production_date'},
        ),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.branches(filters: const {'per_page': 300}),
        _masterService.businessLocations(filters: const {'per_page': 300}),
        _masterService.financialYears(filters: const {'per_page': 100}),
        _masterService.documentSeries(filters: const {'per_page': 300}),
        _service.boms(filters: const {'per_page': 300}),
        _inventoryService.items(filters: const {'per_page': 500}),
        _inventoryService.uoms(filters: const {'per_page': 300}),
        _inventoryService.uomConversionsAll(
          filters: const {'per_page': 500, 'sort_by': 'from_uom_id'},
        ),
        _masterService.warehouses(filters: const {'per_page': 300}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<ProductionOrderModel>).data ??
          const <ProductionOrderModel>[];
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
      boms =
          (responses[6] as PaginatedResponse<BomModel>).data ??
          const <BomModel>[];
      items =
          ((responses[7] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
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
      warehouses =
          ((responses[10] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
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
        final existing = rows.cast<ProductionOrderModel?>().firstWhere(
          (x) =>
              intValue(x?.toJson() ?? const <String, dynamic>{}, 'id') ==
              selectId,
          orElse: () => null,
        );
        if (existing != null) {
          await select(existing);
          return;
        }
        if (await restoreSelectionAfterReload<ProductionOrderModel>(
          selectId: selectId,
          rows: rows,
          selected: selected,
          onSelect: select,
          replaceRows: (nextRows) => rows = nextRows,
          notify: update,
        )) {
          return;
        }
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
    formError = null;
    final contextSelection = normalizedWorkingContextSelection(
      companies: companies,
      branches: branches,
      locations: locations,
      financialYears: financialYears,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
    );
    companyId = contextSelection.companyId;
    branchId = contextSelection.branchId;
    locationId = contextSelection.locationId;
    financialYearId = contextSelection.financialYearId;
    _syncDocumentSeries();
    bomId = null;
    outputItemId = null;
    outputUomId = null;
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    productionNoController.clear();
    productionDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    plannedQtyController.text = '1';
    notesController.clear();
    isActive = true;
    update();
  }

  Future<void> select(ProductionOrderModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _service.productionOrder(id);
      final data = (response.data ?? row).toJson();
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      documentSeriesId = intValue(data, 'document_series_id');
      bomId = intValue(data, 'bom_id');
      outputItemId = intValue(data, 'output_item_id');
      outputUomId = intValue(data, 'output_uom_id');
      warehouseId = intValue(data, 'warehouse_id');
      productionNoController.text = stringValue(data, 'production_no');
      productionDateController.text = displayDate(
        nullableStringValue(data, 'production_date'),
      );
      plannedQtyController.text = stringValue(data, 'planned_qty');
      notesController.text = stringValue(data, 'notes');
      isActive = boolValue(data, 'is_active', fallback: true);
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  void onCompanyChanged(int? value) {
    if (isLocked) return;
    companyId = value;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    financialYearId = financialYearOptions.isNotEmpty
        ? financialYearOptions.first.id
        : null;
    _syncDocumentSeries();
    bomId = null;
    outputItemId = null;
    outputUomId = null;
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    update();
  }

  void onBranchChanged(int? value) {
    if (isLocked) return;
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    _syncDocumentSeries();
    update();
  }

  void onLocationChanged(int? value) {
    if (isLocked) return;
    locationId = value;
    _syncDocumentSeries();
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    update();
  }

  void onFinancialYearChanged(int? value) {
    if (isLocked) return;
    financialYearId = value;
    _syncDocumentSeries();
    update();
  }

  void setDocumentSeriesId(int? value) {
    if (isLocked) return;
    documentSeriesId = value;
    update();
  }

  void onBomChanged(int? value) {
    if (isLocked) return;
    bomId = value;
    final bom = bomOptions.cast<BomModel?>().firstWhere(
      (b) => intValue(b?.toJson() ?? const <String, dynamic>{}, 'id') == value,
      orElse: () => null,
    );
    if (bom != null) {
      outputItemId = intValue(bom.toJson(), 'output_item_id');
      outputUomId = intValue(bom.toJson(), 'output_uom_id');
    }
    update();
  }

  void setOutputItemId(int? value) {
    if (isLocked) return;
    outputItemId = value;
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == value,
      orElse: () => null,
    );
    outputUomId = defaultUomIdForItem(
      item,
      uoms,
      uomConversions,
      current: outputUomId,
    );
    update();
  }

  void setOutputUomId(int? value) {
    if (isLocked) return;
    outputUomId = value;
    update();
  }

  void setWarehouseId(int? value) {
    if (isLocked) return;
    warehouseId = value;
    update();
  }

  List<UomModel> uomOptionsForOutputItem() {
    if (outputItemId == null) return const <UomModel>[];
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == outputItemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, uoms, uomConversions);
  }

  String? _validate() {
    if (companyId == null ||
        branchId == null ||
        locationId == null ||
        financialYearId == null) {
      return 'Company, branch, location and financial year are required.';
    }
    if (financialYearOptions.every((fy) => fy.id != financialYearId)) {
      return 'Select a financial year for the chosen company.';
    }
    if (documentSeriesId == null) {
      return 'Document series is required.';
    }
    if (seriesOptions.every((series) => series.id != documentSeriesId)) {
      return 'Select a valid production order document series.';
    }
    if (bomId == null || outputItemId == null || outputUomId == null) {
      return 'BOM, output item and output UOM are required.';
    }
    if (bomOptions.every((bom) => intValue(bom.toJson(), 'id') != bomId)) {
      return 'Select an approved BOM for the chosen company.';
    }
    if (outputItemOptions.every((item) => item.id != outputItemId)) {
      return 'Select an output item for the chosen company.';
    }
    if (warehouseId == null) {
      return 'Warehouse is required.';
    }
    if ((Validators.parseFlexibleNumber(plannedQtyController.text) ?? 0) <= 0) {
      return 'Planned quantity must be greater than zero.';
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
      'production_no': nullIfEmpty(productionNoController.text),
      'production_date': productionDateController.text.trim(),
      'bom_id': bomId,
      'output_item_id': outputItemId,
      'output_uom_id': outputUomId,
      'planned_qty': Validators.parseFlexibleNumber(plannedQtyController.text) ?? 0,
      'warehouse_id': warehouseId,
      'notes': nullIfEmpty(notesController.text),
      'is_active': isActive ? 1 : 0,
    };
    try {
      final response = selected == null
          ? await _service.createProductionOrder(
              ProductionOrderModel.fromJson(payload),
            )
          : await _service.updateProductionOrder(
              intValue(selected!.toJson(), 'id')!,
              ProductionOrderModel.fromJson(payload),
            );
      actionMessage = response.message;
      await load(
        selectId: intValue(
          response.data?.toJson() ?? const <String, dynamic>{},
          'id',
        ),
      );
      _refreshController.notifyChanged(source: 'production_order');
    } catch (e) {
      formError = e.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> release() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.releaseProductionOrder(
        id,
        ProductionOrderModel.fromJson(<String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'production_order');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> close() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.closeProductionOrder(
        id,
        ProductionOrderModel.fromJson(<String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'production_order');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> cancel() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.cancelProductionOrder(
        id,
        ProductionOrderModel.fromJson(<String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'production_order');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> delete() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      await _service.deleteProductionOrder(id);
      actionMessage = 'Production order deleted successfully.';
      await load();
      _refreshController.notifyChanged(source: 'production_order');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    searchController.removeListener(update);
    searchController.dispose();
    productionNoController.dispose();
    productionDateController.dispose();
    plannedQtyController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
