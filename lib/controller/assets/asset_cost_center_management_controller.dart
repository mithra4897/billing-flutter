import '../../screen.dart';
import '../../view_model/assets/asset_module_refresh_controller.dart';

Map<String, dynamic>? assetCostCenterJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String assetCostCenterParentLabel(Map<String, dynamic> data) {
  final parent = assetCostCenterJsonMap(data['parent']);
  if (parent == null) {
    return '';
  }
  final name = stringValue(parent, 'cost_center_name');
  if (name.isNotEmpty) {
    return name;
  }
  return stringValue(parent, 'cost_center_code');
}

class AssetCostCenterManagementController extends GetxController {
  AssetCostCenterManagementController({this.initialId});

  final int? initialId;

  final AssetsService _assets = AssetsService();
  final AssetModuleRefreshController _refreshController =
      AssetModuleRefreshController.ensureRegistered();
  final MasterService _master = MasterService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController typeController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;
  int? sessionCompanyId;

  List<CostCenterModel> rows = const <CostCenterModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  CostCenterModel? selected;
  CostCenterModel? detail;

  int? companyId;
  int? parentId;
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
    codeController.dispose();
    nameController.dispose();
    typeController.dispose();
    super.onClose();
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  List<CostCenterModel> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          if (query.isEmpty) {
            return true;
          }
          final raw = row.toJson();
          return [
            row.costCenterCode ?? '',
            row.costCenterName ?? '',
            stringValue(raw, 'cost_center_type'),
            assetCostCenterParentLabel(raw),
          ].join(' ').toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<CostCenterModel> get parentOptions {
    final editingId = detail?.id;
    return rows
        .where((row) {
          final id = row.id;
          if (id == null) {
            return false;
          }
          if (editingId != null && id == editingId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  String listTitle(CostCenterModel row) {
    return row.costCenterCode?.trim().isNotEmpty == true
        ? row.costCenterCode!
        : (row.costCenterName ?? 'Cost center');
  }

  String listSubtitle(CostCenterModel row) {
    final raw = row.toJson();
    return [
      row.costCenterName ?? '',
      stringValue(raw, 'cost_center_type'),
      assetCostCenterParentLabel(raw),
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  void _apply(CostCenterModel? model) {
    if (model == null) {
      return;
    }
    final raw = model.toJson();
    companyId = intValue(raw, 'company_id');
    parentId = intValue(raw, 'parent_id');
    codeController.text = stringValue(raw, 'cost_center_code');
    nameController.text = stringValue(raw, 'cost_center_name');
    typeController.text = stringValue(raw, 'cost_center_type');
    isActive = raw['is_active'] == true || raw['is_active'] == 1;
  }

  void resetDraft() {
    selected = null;
    detail = null;
    formError = null;
    companyId = sessionCompanyId;
    if (companyId == null && companies.isNotEmpty) {
      companyId = companies.first.id;
    }
    parentId = null;
    codeController.clear();
    nameController.clear();
    typeController.clear();
    isActive = true;
    update();
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      sessionCompanyId = info.companyId;
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final responses = await Future.wait<dynamic>([
        _assets.costCenters(filters: filters),
        _master.companies(filters: const {'per_page': 200}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<CostCenterModel>).data ??
          const <CostCenterModel>[];
      companies =
          ((responses[1] as PaginatedResponse<CompanyModel>).data ??
                  const <CompanyModel>[])
              .where((company) => company.isActive)
              .toList(growable: false);
      loading = false;

      if (selectId != null) {
        if (await restoreSelectionAfterReload<CostCenterModel>(
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

  Future<void> loadDetailById(int id) async {
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _assets.costCenter(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
        selected = response.data;
        _apply(response.data);
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

  Future<void> reloadList() async {
    final info = await hrSessionCompanyInfo();
    final filters = <String, dynamic>{'per_page': 200};
    if (info.companyId != null) {
      filters['company_id'] = info.companyId;
    }
    final response = await _assets.costCenters(filters: filters);
    rows = response.data ?? const <CostCenterModel>[];
    update();
  }

  Future<void> select(CostCenterModel row) async {
    final id = row.id;
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _assets.costCenter(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
        _apply(response.data);
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

  void setCompanyId(int? value) {
    companyId = value;
    update();
  }

  void setParentId(int? value) {
    parentId = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  Future<int?> save() async {
    final nextCompanyId = companyId;
    if (nextCompanyId == null) {
      formError = 'Company is required.';
      update();
      return null;
    }
    final code = codeController.text.trim();
    final name = nameController.text.trim();
    if (code.isEmpty || name.isEmpty) {
      formError = 'Cost center code and name are required.';
      update();
      return null;
    }

    saving = true;
    formError = null;
    update();

    try {
      final existingId = detail?.id;
      if (existingId != null) {
        final response = await _assets.updateCostCenter(
          existingId,
          CostCenterModel(
            id: existingId,
            companyId: nextCompanyId,
            parentId: parentId,
            costCenterCode: code,
            costCenterName: name,
            costCenterType: nullIfEmpty(typeController.text.trim()),
            isActive: isActive,
          ),
        );
        if (response.success != true || response.data == null) {
          formError = response.message;
          return null;
        }
        detail = response.data;
        await reloadList();
        selected =
            rows.cast<CostCenterModel?>().firstWhere(
              (row) => row?.id == existingId,
              orElse: () => null,
            ) ??
            response.data;
        _apply(detail);
        actionMessage = 'Cost center saved.';
        _refreshController.notifyChanged(source: 'asset_cost_center');
        return existingId;
      }

      final response = await _assets.createCostCenter(
        CostCenterModel(
          companyId: nextCompanyId,
          parentId: parentId,
          costCenterCode: code,
          costCenterName: name,
          costCenterType: nullIfEmpty(typeController.text.trim()),
          isActive: isActive,
        ),
      );
      if (response.success != true || response.data == null) {
        formError = response.message;
        return null;
      }
      detail = response.data;
      await reloadList();
      final newId = response.data!.id;
      selected =
          rows.cast<CostCenterModel?>().firstWhere(
            (row) => row?.id == newId,
            orElse: () => null,
          ) ??
          response.data;
      _apply(detail);
      actionMessage = 'Cost center created.';
      _refreshController.notifyChanged(source: 'asset_cost_center');
      return newId;
    } catch (errorValue) {
      formError = errorValue.toString();
      return null;
    } finally {
      saving = false;
      update();
    }
  }

  Future<bool> deleteCurrent() async {
    final id = detail?.id;
    if (id == null) {
      return false;
    }
    saving = true;
    formError = null;
    update();
    try {
      final response = await _assets.deleteCostCenter(id);
      if (response.success != true) {
        formError = response.message;
        return false;
      }
      await reloadList();
      actionMessage = 'Cost center deleted.';
      resetDraft();
      _refreshController.notifyChanged(source: 'asset_cost_center');
      return true;
    } catch (errorValue) {
      formError = errorValue.toString();
      return false;
    } finally {
      saving = false;
      update();
    }
  }

  void startNew({required bool isDesktop}) {
    resetDraft();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}
