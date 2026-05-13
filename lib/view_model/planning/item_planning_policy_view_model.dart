import 'package:billing/screen.dart';

class ItemPlanningPolicyViewModel extends ChangeNotifier {
  final PlanningService _service = PlanningService();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController planningMethodController = TextEditingController();
  final TextEditingController procurementTypeController = TextEditingController();
  final TextEditingController reorderLevelQtyController = TextEditingController();
  final TextEditingController reorderQtyController = TextEditingController();
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

  ItemPlanningPolicyModel? selected;
  int? companyId;
  int? itemId;
  bool isActive = true;
  bool isMrpEnabled = true;
  bool isReorderEnabled = true;

  ItemPlanningPolicyViewModel() {
    searchController.addListener(notifyListeners);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  void _handleWorkingContextChanged() {
    final id =
        intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    load(selectId: id);
  }

  List<ItemPlanningPolicyModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) return true;
      final item = data['item'];
      final itemMap = item is Map<String, dynamic> ? item : const <String, dynamic>{};
      return [
        stringValue(itemMap, 'item_code'),
        stringValue(itemMap, 'item_name'),
        stringValue(data, 'planning_method'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  List<ItemModel> get itemOptions => items.where((x) {
    if (!x.isActive || x.id == null) return false;
    if (companyId != null && x.companyId != companyId) return false;
    return true;
  }).toList(growable: false);

  String? consumeActionMessage() {
    final value = actionMessage;
    actionMessage = null;
    return value;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _service.itemPolicies(filters: const {'per_page': 200}),
        _masterService.companies(filters: const {'per_page': 200}),
        _inventoryService.items(filters: const {'per_page': 500}),
      ]);
      rows = (responses[0] as PaginatedResponse<ItemPlanningPolicyModel>).data ??
          const <ItemPlanningPolicyModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      items = ((responses[2] as PaginatedResponse<ItemModel>).data ??
              const <ItemModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      companyId = contextSelection.companyId;
      loading = false;
      if (selectId != null) {
        final existing = rows.cast<ItemPlanningPolicyModel?>().firstWhere(
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
    formError = null;
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    itemId = null;
    planningMethodController.text = 'reorder';
    procurementTypeController.text = 'purchase';
    reorderLevelQtyController.clear();
    reorderQtyController.clear();
    remarksController.clear();
    isActive = true;
    isMrpEnabled = true;
    isReorderEnabled = true;
    notifyListeners();
  }

  Future<void> select(ItemPlanningPolicyModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.itemPolicy(id);
      final data = (response.data ?? row).toJson();
      companyId = intValue(data, 'company_id');
      itemId = intValue(data, 'item_id');
      planningMethodController.text = stringValue(data, 'planning_method', 'reorder');
      procurementTypeController.text = stringValue(data, 'procurement_type', 'purchase');
      reorderLevelQtyController.text = stringValue(data, 'reorder_level_qty');
      reorderQtyController.text = stringValue(data, 'reorder_qty');
      remarksController.text = stringValue(data, 'remarks');
      isActive = boolValue(data, 'is_active', fallback: true);
      isMrpEnabled = boolValue(data, 'is_mrp_enabled', fallback: true);
      isReorderEnabled = boolValue(data, 'is_reorder_enabled', fallback: true);
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  void onCompanyChanged(int? value) {
    companyId = value;
    if (!itemOptions.any((x) => x.id == itemId)) {
      itemId = null;
    }
    notifyListeners();
  }

  void setItemId(int? value) {
    itemId = value;
    notifyListeners();
  }

  void setIsMrpEnabled(bool value) {
    isMrpEnabled = value;
    notifyListeners();
  }

  void setIsReorderEnabled(bool value) {
    isReorderEnabled = value;
    notifyListeners();
  }

  void setIsActive(bool value) {
    isActive = value;
    notifyListeners();
  }

  String? _validate() {
    if (companyId == null) return 'Company is required.';
    if (itemId == null) return 'Item is required.';
    return null;
  }

  Future<void> save() async {
    final err = _validate();
    if (err != null) {
      formError = err;
      notifyListeners();
      return;
    }
    saving = true;
    formError = null;
    notifyListeners();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'item_id': itemId,
      'planning_method': nullIfEmpty(planningMethodController.text),
      'procurement_type': nullIfEmpty(procurementTypeController.text),
      'reorder_level_qty': double.tryParse(reorderLevelQtyController.text.trim()),
      'reorder_qty': double.tryParse(reorderQtyController.text.trim()),
      'is_active': isActive ? 1 : 0,
      'is_mrp_enabled': isMrpEnabled ? 1 : 0,
      'is_reorder_enabled': isReorderEnabled ? 1 : 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
    try {
      final response = selected == null
          ? await _service.createItemPolicy(ItemPlanningPolicyModel(payload))
          : await _service.updateItemPolicy(
              intValue(selected!.toJson(), 'id')!,
              ItemPlanningPolicyModel(payload),
            );
      actionMessage = response.message;
      await load(
        selectId: intValue(response.data?.toJson() ?? const <String, dynamic>{}, 'id'),
      );
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
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
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    searchController.dispose();
    planningMethodController.dispose();
    procurementTypeController.dispose();
    reorderLevelQtyController.dispose();
    reorderQtyController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}
