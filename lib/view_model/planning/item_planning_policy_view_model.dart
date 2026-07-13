import '../../../screen.dart';

class ItemPlanningPolicyViewModel extends GetxController {
  final PlanningService _service = PlanningService();
  final ManufacturingService _manufacturingService = ManufacturingService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController planningMethodController =
      TextEditingController();
  final TextEditingController procurementTypeController =
      TextEditingController();
  final TextEditingController leadTimeDaysController = TextEditingController();
  final TextEditingController safetyStockQtyController =
      TextEditingController();
  final TextEditingController reorderLevelQtyController =
      TextEditingController();
  final TextEditingController reorderQtyController = TextEditingController();
  final TextEditingController minimumOrderQtyController =
      TextEditingController();
  final TextEditingController maxOrderQtyController = TextEditingController();
  final TextEditingController orderMultipleQtyController =
      TextEditingController();
  final TextEditingController planningFenceDaysController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<ItemPlanningPolicyModel> rows = const <ItemPlanningPolicyModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<PartyModel> suppliers = const <PartyModel>[];
  List<BomModel> boms = const <BomModel>[];

  ItemPlanningPolicyModel? selected;
  int? companyId;
  int? itemId;
  int? warehouseId;
  int? preferredSupplierPartyId;
  int? preferredBomId;
  int? preferredWarehouseId;
  bool isActive = true;
  bool isMrpEnabled = true;
  bool isReorderEnabled = true;

  ItemPlanningPolicyViewModel() {
    searchController.addListener(update);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  void _handleWorkingContextChanged() {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    load(selectId: id);
  }

  List<ItemPlanningPolicyModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          if (q.isEmpty) return true;
          final item = data['item'];
          final itemMap = item is Map<String, dynamic>
              ? item
              : const <String, dynamic>{};
          return [
            stringValue(itemMap, 'item_code'),
            stringValue(itemMap, 'item_name'),
            stringValue(data, 'planning_method'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  List<ItemModel> get itemOptions => items
      .where((x) {
        if (!x.isActive || x.id == null) return false;
        if (companyId != null && x.companyId != companyId) return false;
        return true;
      })
      .toList(growable: false);

  List<WarehouseModel> get warehouseOptions => warehouses
      .where((x) {
        if (!x.isActive || x.id == null) return false;
        if (companyId != null && x.companyId != companyId) return false;
        return true;
      })
      .toList(growable: false);

  List<WarehouseModel> get preferredWarehouseOptions => warehouseOptions;

  List<PartyModel> get supplierOptions => suppliers
      .where((x) {
        if (x.id == null || !x.isActive) return false;
        if (companyId != null && x.companyId != companyId) return false;
        return true;
      })
      .toList(growable: false);

  List<BomModel> get bomOptions => boms
      .where((x) {
        if (x.id == null) return false;
        if (companyId != null && x.companyId != companyId) return false;
        if (itemId != null && x.outputItemId != itemId) return false;
        return (x.isActive ?? true) && (x.approvalStatus ?? '') == 'approved';
      })
      .toList(growable: false);

  String? consumeActionMessage() {
    final value = actionMessage;
    actionMessage = null;
    return value;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    update();
    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait<dynamic>([
        _service.itemPolicies(filters: const {'per_page': 200}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<ItemPlanningPolicyModel>).data ??
          const <ItemPlanningPolicyModel>[];
      companies = cache.activeCompanies;
      items = cache.activeItems;
      warehouses = cache.activeWarehouses;
      boms = await _loadBomsSafely();
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      companyId = contextSelection.companyId;
      suppliers = await _loadSuppliersSafely(companyId: companyId);
      loading = false;
      if (selectId != null) {
        if (await restoreSelectionAfterReload<ItemPlanningPolicyModel>(
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

  Future<List<PartyModel>> _reloadSuppliersForCompany() async {
    suppliers = await _loadSuppliersSafely(companyId: companyId);
    if (!supplierOptions.any((x) => x.id == preferredSupplierPartyId)) {
      preferredSupplierPartyId = null;
    }
    update();
    return suppliers;
  }

  Future<List<PartyModel>> _loadSuppliersSafely({int? companyId}) async {
    final parties = MasterDataCache.to.activeParties;
    return parties
        .where((x) {
          if (x.id == null) {
            return false;
          }
          if (companyId != null && x.companyId != companyId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<List<BomModel>> _loadBomsSafely() async {
    try {
      final response = await _manufacturingService.boms(
        filters: const {'per_page': 300},
      );
      return response.data ?? const <BomModel>[];
    } catch (_) {
      return const <BomModel>[];
    }
  }

  void resetDraft() {
    selected = null;
    formError = null;
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    itemId = null;
    warehouseId = null;
    preferredSupplierPartyId = null;
    preferredBomId = null;
    preferredWarehouseId = null;
    planningMethodController.text = 'reorder';
    procurementTypeController.text = 'purchase';
    leadTimeDaysController.clear();
    safetyStockQtyController.clear();
    reorderLevelQtyController.clear();
    reorderQtyController.clear();
    minimumOrderQtyController.clear();
    maxOrderQtyController.clear();
    orderMultipleQtyController.clear();
    planningFenceDaysController.clear();
    remarksController.clear();
    isActive = true;
    isMrpEnabled = true;
    isReorderEnabled = true;
    update();
  }

  Future<void> select(ItemPlanningPolicyModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _service.itemPolicy(id);
      final data = (response.data ?? row).toJson();
      companyId = intValue(data, 'company_id');
      await _reloadSuppliersForCompany();
      itemId = intValue(data, 'item_id');
      warehouseId = intValue(data, 'warehouse_id');
      preferredSupplierPartyId = intValue(data, 'preferred_supplier_party_id');
      if (!supplierOptions.any((x) => x.id == preferredSupplierPartyId)) {
        preferredSupplierPartyId = null;
      }
      preferredBomId = intValue(data, 'preferred_bom_id');
      preferredWarehouseId = intValue(data, 'preferred_warehouse_id');
      planningMethodController.text = stringValue(
        data,
        'planning_method',
        'reorder',
      );
      procurementTypeController.text = stringValue(
        data,
        'procurement_type',
        'purchase',
      );
      leadTimeDaysController.text = stringValue(data, 'lead_time_days');
      safetyStockQtyController.text = stringValue(data, 'safety_stock_qty');
      reorderLevelQtyController.text = stringValue(data, 'reorder_level_qty');
      reorderQtyController.text = stringValue(data, 'reorder_qty');
      minimumOrderQtyController.text = stringValue(data, 'minimum_order_qty');
      maxOrderQtyController.text = stringValue(data, 'max_order_qty');
      orderMultipleQtyController.text = stringValue(data, 'order_multiple_qty');
      planningFenceDaysController.text = stringValue(
        data,
        'planning_fence_days',
      );
      remarksController.text = stringValue(data, 'remarks');
      isActive = boolValue(data, 'is_active', fallback: true);
      isMrpEnabled = boolValue(data, 'is_mrp_enabled', fallback: true);
      isReorderEnabled = boolValue(data, 'is_reorder_enabled', fallback: true);
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  void onCompanyChanged(int? value) {
    companyId = value;
    if (!itemOptions.any((x) => x.id == itemId)) {
      itemId = null;
    }
    if (!warehouseOptions.any((x) => x.id == warehouseId)) {
      warehouseId = null;
    }
    if (!preferredWarehouseOptions.any((x) => x.id == preferredWarehouseId)) {
      preferredWarehouseId = null;
    }
    if (!bomOptions.any((x) => x.id == preferredBomId)) {
      preferredBomId = null;
    }
    unawaited(_reloadSuppliersForCompany());
    update();
  }

  void setItemId(int? value) {
    itemId = value;
    if (!bomOptions.any((x) => x.id == preferredBomId)) {
      preferredBomId = null;
    }
    update();
  }

  void setWarehouseId(int? value) {
    warehouseId = value == null || value <= 0 ? null : value;
    update();
  }

  void setPreferredSupplierPartyId(int? value) {
    preferredSupplierPartyId = value;
    update();
  }

  void setPreferredBomId(int? value) {
    preferredBomId = value;
    update();
  }

  void setPreferredWarehouseId(int? value) {
    preferredWarehouseId = value;
    update();
  }

  void setIsMrpEnabled(bool value) {
    isMrpEnabled = value;
    update();
  }

  void setIsReorderEnabled(bool value) {
    isReorderEnabled = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  String? _validate() {
    if (companyId == null) return 'Company is required.';
    if (itemId == null) return 'Item is required.';
    final procurementType = procurementTypeController.text.trim().toLowerCase();
    if (procurementType == 'purchase' && preferredSupplierPartyId == null) {
      return 'Preferred supplier is required for purchase planning policies.';
    }
    return null;
  }

  Future<void> save() async {
    final err = _validate();
    if (err != null) {
      formError = err;
      update();
      return;
    }
    saving = true;
    formError = null;
    update();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'planning_method': nullIfEmpty(planningMethodController.text),
      'procurement_type': nullIfEmpty(procurementTypeController.text),
      'lead_time_days': int.tryParse(leadTimeDaysController.text.trim()),
      'safety_stock_qty': Validators.parseFlexibleNumber(
        safetyStockQtyController.text,
      ),
      'reorder_level_qty': double.tryParse(
        reorderLevelQtyController.text.trim(),
      ),
      'reorder_qty': Validators.parseFlexibleNumber(reorderQtyController.text),
      'minimum_order_qty': double.tryParse(
        minimumOrderQtyController.text.trim(),
      ),
      'max_order_qty': Validators.parseFlexibleNumber(
        maxOrderQtyController.text,
      ),
      'order_multiple_qty': double.tryParse(
        orderMultipleQtyController.text.trim(),
      ),
      'planning_fence_days': int.tryParse(
        planningFenceDaysController.text.trim(),
      ),
      'preferred_supplier_party_id': preferredSupplierPartyId,
      'preferred_bom_id': preferredBomId,
      'preferred_warehouse_id': preferredWarehouseId,
      'is_active': isActive ? 1 : 0,
      'is_mrp_enabled': isMrpEnabled ? 1 : 0,
      'is_reorder_enabled': isReorderEnabled ? 1 : 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
    try {
      final response = selected == null
          ? await _service.createItemPolicy(
              ItemPlanningPolicyModel.fromJson(normalizeDatePayload(payload)),
            )
          : await _service.updateItemPolicy(
              intValue(selected!.toJson(), 'id')!,
              ItemPlanningPolicyModel.fromJson(normalizeDatePayload(payload)),
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
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      await _service.deleteItemPolicy(id);
      actionMessage = 'Item planning policy deleted successfully.';
      await load();
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    searchController.dispose();
    planningMethodController.dispose();
    procurementTypeController.dispose();
    leadTimeDaysController.dispose();
    safetyStockQtyController.dispose();
    reorderLevelQtyController.dispose();
    reorderQtyController.dispose();
    minimumOrderQtyController.dispose();
    maxOrderQtyController.dispose();
    orderMultipleQtyController.dispose();
    planningFenceDaysController.dispose();
    remarksController.dispose();
    super.onClose();
  }
}
