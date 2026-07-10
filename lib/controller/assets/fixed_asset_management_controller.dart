import '../../screen.dart';
import '../../view_model/assets/asset_module_refresh_controller.dart';

Map<String, dynamic>? fixedAssetJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String fixedAssetCategoryLabel(Map<String, dynamic> data) {
  final category = fixedAssetJsonMap(data['category']);
  if (category == null) {
    return '';
  }
  final code = stringValue(category, 'category_code');
  final name = stringValue(category, 'category_name');
  if (code.isNotEmpty && name.isNotEmpty) {
    return '$code - $name';
  }
  return code.isNotEmpty ? code : name;
}

class FixedAssetManagementController extends GetxController {
  FixedAssetManagementController({this.initialId});

  final int? initialId;

  final AssetsService _assets = AssetsService();
  final AssetModuleRefreshController _refreshController =
      AssetModuleRefreshController.ensureRegistered();
  final PartiesService _partiesService = PartiesService();
  final MasterService _master = MasterService();
  final HrService _hrService = HrService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController assetCodeController = TextEditingController();
  final TextEditingController assetNameController = TextEditingController();
  final TextEditingController assetTagController = TextEditingController();
  final TextEditingController serialNoController = TextEditingController();
  final TextEditingController manufacturerController = TextEditingController();
  final TextEditingController modelNoController = TextEditingController();
  final TextEditingController purchaseDateController = TextEditingController();
  final TextEditingController capitalizationDateController =
      TextEditingController();
  final TextEditingController putToUseDateController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController employeeController = TextEditingController();
  final TextEditingController acquisitionCostController =
      TextEditingController();
  final TextEditingController additionalCostController =
      TextEditingController();
  final TextEditingController capitalizationValueController =
      TextEditingController();
  final TextEditingController salvageValueController = TextEditingController();
  final TextEditingController conditionStatusController =
      TextEditingController();
  final TextEditingController warrantyStartController = TextEditingController();
  final TextEditingController warrantyEndController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  bool actionBusy = false;
  String? pageError;
  String? formError;
  String? actionMessage;
  int? sessionCompanyId;

  List<AssetModel> rows = const <AssetModel>[];
  List<AssetCategoryModel> categories = const <AssetCategoryModel>[];
  List<CostCenterModel> costCenters = const <CostCenterModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<DepartmentModel> departments = const <DepartmentModel>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];

  AssetModel? selected;
  AssetModel? detail;

  int? companyId;
  int? branchId;
  int? locationId;
  int? categoryId;
  int? costCenterId;
  int? warehouseId;
  int? supplierPartyId;
  bool isDepreciable = true;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(update);
    load(selectId: initialId);
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(update)
      ..dispose();
    assetCodeController.dispose();
    assetNameController.dispose();
    assetTagController.dispose();
    serialNoController.dispose();
    manufacturerController.dispose();
    modelNoController.dispose();
    purchaseDateController.dispose();
    capitalizationDateController.dispose();
    putToUseDateController.dispose();
    departmentController.dispose();
    employeeController.dispose();
    acquisitionCostController.dispose();
    additionalCostController.dispose();
    capitalizationValueController.dispose();
    salvageValueController.dispose();
    conditionStatusController.dispose();
    warrantyStartController.dispose();
    warrantyEndController.dispose();
    notesController.dispose();
    super.onClose();
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  List<AssetModel> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          if (query.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'asset_code'),
            stringValue(data, 'asset_name'),
            stringValue(data, 'asset_status'),
            fixedAssetCategoryLabel(data),
          ].join(' ').toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<AssetCategoryModel> get categoryOptions {
    return categories
        .where((category) {
          if (companyId == null) {
            return true;
          }
          return intValue(category.toJson(), 'company_id') == companyId;
        })
        .toList(growable: false);
  }

  List<CostCenterModel> get costCenterOptions {
    return costCenters
        .where((costCenter) {
          if (companyId == null) {
            return true;
          }
          return costCenter.companyId == companyId;
        })
        .toList(growable: false);
  }

  List<WarehouseModel> get warehouseOptions {
    return warehouses
        .where((warehouse) {
          if (companyId != null && warehouse.companyId != companyId) {
            return false;
          }
          if (branchId != null && warehouse.branchId != branchId) {
            return false;
          }
          if (locationId != null && warehouse.locationId != locationId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<DepartmentModel> get departmentOptions {
    return departments
        .where((department) => department.isActive)
        .toList(growable: false);
  }

  List<EmployeeModel> get employeeOptions {
    return employees
        .where((employee) {
          if (companyId != null && employee.companyId != companyId) {
            return false;
          }
          final status = (employee.status ?? '').trim().toLowerCase();
          return status.isEmpty || status == 'active';
        })
        .toList(growable: false);
  }

  Future<List<T>> _safeOptionList<T>(
    Future<PaginatedResponse<T>> request,
  ) async {
    try {
      return (await request).data ?? <T>[];
    } catch (_) {
      return <T>[];
    }
  }

  String listTitle(AssetModel row) {
    final data = row.toJson();
    final code = stringValue(data, 'asset_code');
    if (code.isNotEmpty) {
      return code;
    }
    return stringValue(data, 'asset_name');
  }

  String listSubtitle(AssetModel row) {
    final data = row.toJson();
    return [
      stringValue(data, 'asset_name'),
      fixedAssetCategoryLabel(data),
      stringValue(data, 'asset_status'),
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  void resetDraft() {
    selected = null;
    detail = null;
    formError = null;
    companyId = sessionCompanyId;
    branchId = null;
    locationId = null;
    categoryId = null;
    costCenterId = null;
    warehouseId = null;
    supplierPartyId = null;
    isDepreciable = true;
    isActive = true;
    assetCodeController.clear();
    assetNameController.clear();
    assetTagController.clear();
    serialNoController.clear();
    manufacturerController.clear();
    modelNoController.clear();
    purchaseDateController.clear();
    capitalizationDateController.clear();
    putToUseDateController.clear();
    departmentController.clear();
    employeeController.clear();
    acquisitionCostController.clear();
    additionalCostController.clear();
    capitalizationValueController.clear();
    salvageValueController.clear();
    conditionStatusController.text = 'good';
    warrantyStartController.clear();
    warrantyEndController.clear();
    notesController.clear();
    update();
  }

  void applyFromModel(AssetModel model) {
    final data = model.toJson();
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    categoryId = intValue(data, 'asset_category_id');
    costCenterId = intValue(data, 'cost_center_id');
    warehouseId = intValue(data, 'warehouse_id');
    supplierPartyId = intValue(data, 'supplier_party_id');
    isDepreciable =
        data['is_depreciable'] == true || data['is_depreciable'] == 1;
    isActive = data['is_active'] == true || data['is_active'] == 1;
    assetCodeController.text = stringValue(data, 'asset_code');
    assetNameController.text = stringValue(data, 'asset_name');
    assetTagController.text = stringValue(data, 'asset_tag_no');
    serialNoController.text = stringValue(data, 'serial_no');
    manufacturerController.text = stringValue(data, 'manufacturer');
    modelNoController.text = stringValue(data, 'model_no');
    purchaseDateController.text = normalizeDateValue(
      stringValue(data, 'purchase_date'),
    );
    capitalizationDateController.text = normalizeDateValue(
      stringValue(data, 'capitalization_date'),
    );
    putToUseDateController.text = normalizeDateValue(
      stringValue(data, 'put_to_use_date'),
    );
    departmentController.text = stringValue(data, 'department_name');
    employeeController.text = stringValue(data, 'employee_name');
    acquisitionCostController.text = data['acquisition_cost']?.toString() ?? '';
    additionalCostController.text = data['additional_cost']?.toString() ?? '';
    capitalizationValueController.text =
        data['capitalization_value']?.toString() ?? '';
    salvageValueController.text = data['salvage_value']?.toString() ?? '';
    conditionStatusController.text = stringValue(data, 'condition_status');
    warrantyStartController.text = normalizeDateValue(
      stringValue(data, 'warranty_start_date'),
    );
    warrantyEndController.text = normalizeDateValue(
      stringValue(data, 'warranty_end_date'),
    );
    notesController.text = stringValue(data, 'notes');
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      sessionCompanyId = info.companyId;
      final listFilters = <String, dynamic>{'per_page': 200};
      final optionFilters = <String, dynamic>{'per_page': 500};
      if (info.companyId != null) {
        listFilters['company_id'] = info.companyId;
        optionFilters['company_id'] = info.companyId;
      }

      final responses = await Future.wait<dynamic>([
        _assets.assets(filters: listFilters),
        _assets.categories(filters: optionFilters),
        _assets.costCenters(filters: optionFilters),
        _safeOptionList<WarehouseModel>(
          _master.warehouses(filters: const {'per_page': 500}),
        ),
        _safeOptionList<PartyModel>(
          _partiesService.parties(filters: const {'per_page': 500}),
        ),
        _safeOptionList<DepartmentModel>(
          _hrService.departments(filters: const {'per_page': 300}),
        ),
        _safeOptionList<EmployeeModel>(
          _hrService.employees(filters: optionFilters),
        ),
      ]);

      rows =
          (responses[0] as PaginatedResponse<AssetModel>).data ??
          const <AssetModel>[];
      categories =
          (responses[1] as PaginatedResponse<AssetCategoryModel>).data ??
          const <AssetCategoryModel>[];
      costCenters =
          (responses[2] as PaginatedResponse<CostCenterModel>).data ??
          const <CostCenterModel>[];
      warehouses = (responses[3] as List<WarehouseModel>)
          .where((warehouse) => warehouse.isActive)
          .toList(growable: false);
      parties = (responses[4] as List<PartyModel>)
          .where((party) => party.isActive)
          .toList(growable: false);
      departments = (responses[5] as List<DepartmentModel>)
          .where((department) => department.isActive)
          .toList(growable: false);
      employees = (responses[6] as List<EmployeeModel>)
          .where((employee) {
            final status = (employee.status ?? '').trim().toLowerCase();
            return status.isEmpty || status == 'active';
          })
          .toList(growable: false);

      loading = false;

      if (selectId != null) {
        if (await restoreSelectionAfterReload<AssetModel>(
          selectId: selectId,
          rows: rows,
          selected: selected,
          onSelect: select,
          replaceRows: (nextRows) => rows = nextRows,
          notify: update,
          onMissingId: loadDetailById,
        )) {
          return;
        }
      }

      resetDraft();
    } catch (errorValue) {
      pageError = errorValue.toString();
      loading = false;
      update();
    }
  }

  Future<void> reloadList() async {
    final info = await hrSessionCompanyInfo();
    final filters = <String, dynamic>{'per_page': 200};
    if (info.companyId != null) {
      filters['company_id'] = info.companyId;
    }
    final response = await _assets.assets(filters: filters);
    rows = response.data ?? const <AssetModel>[];
    update();
  }

  Future<void> loadDetailById(int id) async {
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _assets.asset(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
        selected = response.data;
        applyFromModel(response.data!);
      } else {
        formError = response.message;
      }
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  Future<void> select(AssetModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _assets.asset(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
        applyFromModel(response.data!);
      } else {
        formError = response.message;
      }
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  void setCategoryId(int? value) {
    categoryId = value;
    update();
  }

  void setSupplierPartyId(int? value) {
    supplierPartyId = value;
    update();
  }

  void setCostCenterId(int? value) {
    costCenterId = value;
    update();
  }

  void setWarehouseId(int? value) {
    warehouseId = value;
    update();
  }

  void setDepartmentName(String? value) {
    departmentController.text = (value ?? '').trim();
    update();
  }

  void setEmployeeName(String? value) {
    employeeController.text = (value ?? '').trim();
    update();
  }

  void setIsDepreciable(bool value) {
    isDepreciable = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  Future<int?> save() async {
    final nextCompanyId = companyId;
    final nextCategoryId = categoryId;
    final code = assetCodeController.text.trim();
    final name = assetNameController.text.trim();
    if (nextCompanyId == null) {
      formError = 'Company is required.';
      update();
      return null;
    }
    if (nextCategoryId == null) {
      formError = 'Asset category is required.';
      update();
      return null;
    }
    if (code.isEmpty || name.isEmpty) {
      formError = 'Asset code and asset name are required.';
      update();
      return null;
    }

    saving = true;
    formError = null;
    update();
    try {
      final payload = <String, dynamic>{
        'company_id': nextCompanyId,
        'asset_category_id': nextCategoryId,
        'asset_code': code,
        'asset_name': name,
        'condition_status':
            nullIfEmpty(conditionStatusController.text.trim()) ?? 'good',
        'is_depreciable': isDepreciable,
        'is_active': isActive,
        if (branchId != null) 'branch_id': branchId,
        if (locationId != null) 'location_id': locationId,
        if (costCenterId != null) 'cost_center_id': costCenterId,
        if (warehouseId != null) 'warehouse_id': warehouseId,
        if (supplierPartyId != null) 'supplier_party_id': supplierPartyId,
        if (nullIfEmpty(assetTagController.text.trim()) != null)
          'asset_tag_no': assetTagController.text.trim(),
        if (nullIfEmpty(serialNoController.text.trim()) != null)
          'serial_no': serialNoController.text.trim(),
        if (nullIfEmpty(manufacturerController.text.trim()) != null)
          'manufacturer': manufacturerController.text.trim(),
        if (nullIfEmpty(modelNoController.text.trim()) != null)
          'model_no': modelNoController.text.trim(),
        if (nullIfEmpty(purchaseDateController.text.trim()) != null)
          'purchase_date': purchaseDateController.text.trim(),
        if (nullIfEmpty(capitalizationDateController.text.trim()) != null)
          'capitalization_date': capitalizationDateController.text.trim(),
        if (nullIfEmpty(putToUseDateController.text.trim()) != null)
          'put_to_use_date': putToUseDateController.text.trim(),
        if (nullIfEmpty(departmentController.text.trim()) != null)
          'department_name': departmentController.text.trim(),
        if (nullIfEmpty(employeeController.text.trim()) != null)
          'employee_name': employeeController.text.trim(),
        if (Validators.parseFlexibleNumber(acquisitionCostController.text) != null)
          'acquisition_cost': double.parse(
            acquisitionCostController.text.trim(),
          ),
        if (Validators.parseFlexibleNumber(additionalCostController.text) != null)
          'additional_cost': double.parse(additionalCostController.text.trim()),
        if (Validators.parseFlexibleNumber(capitalizationValueController.text) != null)
          'capitalization_value': double.parse(
            capitalizationValueController.text.trim(),
          ),
        if (Validators.parseFlexibleNumber(salvageValueController.text) != null)
          'salvage_value': double.parse(salvageValueController.text.trim()),
        if (nullIfEmpty(warrantyStartController.text.trim()) != null)
          'warranty_start_date': warrantyStartController.text.trim(),
        if (nullIfEmpty(warrantyEndController.text.trim()) != null)
          'warranty_end_date': warrantyEndController.text.trim(),
        if (nullIfEmpty(notesController.text.trim()) != null)
          'notes': notesController.text.trim(),
      };

      final existingId = intValue(detail?.toJson() ?? const {}, 'id');
      final response = existingId == null
          ? await _assets.createAsset(AssetModel.fromJson(normalizeDatePayload(payload)))
          : await _assets.updateAsset(existingId, AssetModel.fromJson(normalizeDatePayload(payload)));
      if (response.success != true || response.data == null) {
        formError = response.message;
        return null;
      }

      detail = response.data;
      selected = response.data;
      applyFromModel(response.data!);
      await reloadList();
      final savedId = intValue(response.data!.toJson(), 'id');
      if (savedId != null) {
        selected =
            rows.cast<AssetModel?>().firstWhere(
              (row) => intValue(row?.toJson() ?? const {}, 'id') == savedId,
              orElse: () => null,
            ) ??
            response.data;
      }
      actionMessage = existingId == null ? 'Asset created.' : 'Asset updated.';
      _refreshController.notifyChanged(source: 'fixed_asset');
      return savedId;
    } catch (errorValue) {
      formError = errorValue.toString();
      return null;
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> runAction(
    Future<ApiResponse<AssetModel>> Function() fn,
    String message,
  ) async {
    actionBusy = true;
    formError = null;
    update();
    try {
      final response = await fn();
      if (response.success != true || response.data == null) {
        formError = response.message;
        return;
      }
      detail = response.data;
      selected = response.data;
      applyFromModel(response.data!);
      await reloadList();
      actionMessage = message;
      _refreshController.notifyChanged(source: 'fixed_asset');
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      actionBusy = false;
      update();
    }
  }

  Future<bool> deleteCurrent() async {
    final id = intValue(detail?.toJson() ?? const {}, 'id');
    if (id == null) {
      return false;
    }
    actionBusy = true;
    formError = null;
    update();
    try {
      final response = await _assets.deleteAsset(id);
      if (response.success != true) {
        formError = response.message;
        return false;
      }
      await reloadList();
      resetDraft();
      actionMessage = 'Asset deleted.';
      _refreshController.notifyChanged(source: 'fixed_asset');
      return true;
    } catch (errorValue) {
      formError = errorValue.toString();
      return false;
    } finally {
      actionBusy = false;
      update();
    }
  }

  Future<void> activate() async {
    final id = intValue(detail?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    await runAction(
      () => _assets.activateAsset(id, AssetModel.fromJson(<String, dynamic>{})),
      'Asset updated.',
    );
  }

  void startNew({required bool isDesktop}) {
    resetDraft();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}
