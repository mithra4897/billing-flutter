import '../../screen.dart';
import 'project_module_refresh_controller.dart';

class ProjectResourceUsageManagementController extends GetxController {
  ProjectResourceUsageManagementController({this.constrainedProjectId});

  final ProjectService _projectService = ProjectService();
  final AssetsService _assetsService = AssetsService();
  final MasterService _masterService = MasterService();
  final ProjectModuleRefreshController _refreshController =
      ProjectModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController resourceNameController = TextEditingController();
  final TextEditingController usageDateController = TextEditingController();
  final TextEditingController usageHoursController = TextEditingController();
  final TextEditingController usageQtyController = TextEditingController();
  final TextEditingController unitCostController = TextEditingController();
  final TextEditingController totalCostController = TextEditingController();
  final TextEditingController voucherIdController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  int? constrainedProjectId;
  int? projectId;
  int? taskId;
  int? assetId;
  Worker? _refreshWorker;

  List<ProjectModel> projects = const <ProjectModel>[];
  List<AssetModel> assets = const <AssetModel>[];
  List<ProjectResourceUsageRow> rows = const <ProjectResourceUsageRow>[];
  List<ProjectResourceUsageRow> filteredRows =
      const <ProjectResourceUsageRow>[];
  ProjectResourceUsageRow? selectedRow;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    usageHoursController.addListener(_syncCalculatedTotalCost);
    usageQtyController.addListener(_syncCalculatedTotalCost);
    unitCostController.addListener(_syncCalculatedTotalCost);
    _refreshWorker = ever<ProjectModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null || event.source == 'project_resource_usage') {
          return;
        }
        unawaited(loadData(selectId: selectedRow?.usage.id));
      },
    );
    loadData();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    usageHoursController.removeListener(_syncCalculatedTotalCost);
    usageQtyController.removeListener(_syncCalculatedTotalCost);
    unitCostController.removeListener(_syncCalculatedTotalCost);
    resourceNameController.dispose();
    usageDateController.dispose();
    usageHoursController.dispose();
    usageQtyController.dispose();
    unitCostController.dispose();
    totalCostController.dispose();
    voucherIdController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  bool get isProjectConstrained => constrainedProjectId != null;

  Future<void> applyProjectConstraint(int? value) async {
    if (constrainedProjectId == value) {
      return;
    }
    constrainedProjectId = value;
    await loadData();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = rows.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _projectService.projects(
          filters: const {'per_page': 200, 'sort_by': 'project_name'},
        ),
        _assetsService.assets(
          filters: const {'per_page': 300, 'sort_by': 'asset_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);
      final nextProjects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
      final nextAssets =
          (responses[1] as PaginatedResponse<AssetModel>).data ??
          const <AssetModel>[];
      final companies =
          (responses[2] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final activeCompanies = companies.where((item) => item.isActive).toList();
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      var scopedProjects = contextSelection.companyId == null
          ? nextProjects
          : nextProjects
                .where((item) => item.companyId == contextSelection.companyId)
                .toList(growable: false);
      if (constrainedProjectId != null) {
        scopedProjects = scopedProjects
            .where((item) => item.id == constrainedProjectId)
            .toList(growable: false);
      }
      final nextRows = scopedProjects
          .expand(
            (project) => project.resourceUsages.map(
              (usage) =>
                  ProjectResourceUsageRow(project: project, usage: usage),
            ),
          )
          .toList(growable: false);

      projects = scopedProjects;
      assets = nextAssets;
      rows = nextRows;
      filteredRows = _filterRows(nextRows, searchController.text);
      initialLoading = false;
      update();

      final selected = selectId == null
          ? null
          : nextRows.cast<ProjectResourceUsageRow?>().firstWhere(
              (item) => item?.usage.id == selectId,
              orElse: () => null,
            );
      if (selected != null) {
        selectRow(selected, notify: false);
      } else if (filteredRows.isNotEmpty) {
        selectRow(filteredRows.first, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
      update();
    }
  }

  List<ProjectResourceUsageRow> _filterRows(
    List<ProjectResourceUsageRow> items,
    String query,
  ) {
    return filterMasterList(items, query, (row) {
      return [
        row.usage.resourceName ?? '',
        row.project.projectName ?? '',
        row.usage.usageDate ?? '',
        assetLabel(assetById(row.usage.assetId)),
      ];
    });
  }

  void _applySearch() {
    filteredRows = _filterRows(rows, searchController.text);
    update();
  }

  void selectRow(ProjectResourceUsageRow row, {bool notify = true}) {
    selectedRow = row;
    projectId = row.project.id;
    taskId = row.usage.projectTaskId;
    assetId = row.usage.assetId;
    resourceNameController.text = row.usage.resourceName ?? '';
    usageDateController.text = normalizeDateValue(row.usage.usageDate);
    usageHoursController.text = decimalText(row.usage.usageHours);
    usageQtyController.text = decimalText(row.usage.usageQty);
    unitCostController.text = decimalText(row.usage.unitCost);
    totalCostController.text = decimalText(row.usage.totalCost);
    voucherIdController.text = row.usage.voucherId?.toString() ?? '';
    remarksController.text = row.usage.remarks ?? '';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedRow = null;
    projectId = constrainedProjectId ?? (projects.isNotEmpty ? projects.first.id : null);
    taskId = null;
    assetId = null;
    resourceNameController.clear();
    usageDateController.clear();
    usageHoursController.clear();
    usageQtyController.clear();
    unitCostController.clear();
    totalCostController.clear();
    voucherIdController.clear();
    remarksController.clear();
    formError = null;
    if (notify) {
      update();
    }
  }

  List<AppDropdownItem<int>> get projectItems => projects
      .map(
        (item) => AppDropdownItem<int>(
          value: item.id ?? 0,
          label: item.projectName ?? item.projectCode ?? 'Project',
        ),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get taskItems {
    final project = projects.cast<ProjectModel?>().firstWhere(
      (item) => item?.id == projectId,
      orElse: () => null,
    );
    return (project?.tasks ?? const <ProjectTaskModel>[])
        .map(
          (item) => AppDropdownItem<int>(
            value: item.id ?? 0,
            label: item.taskName ?? item.taskCode ?? 'Task',
          ),
        )
        .where((item) => item.value != 0)
        .toList(growable: false);
  }

  List<AppDropdownItem<int>> get assetItems => assets
      .map(
        (item) =>
            AppDropdownItem<int>(value: item.id ?? 0, label: assetLabel(item)),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  AssetModel? assetById(int? id) => assets.cast<AssetModel?>().firstWhere(
    (item) => item?.id == id,
    orElse: () => null,
  );

  String assetLabel(AssetModel? asset) {
    if (asset == null) {
      return '';
    }
    final name = asset.assetName?.trim() ?? '';
    final code = asset.assetCode?.trim() ?? '';
    if (name.isNotEmpty && code.isNotEmpty) {
      return '$name ($code)';
    }
    return name.isNotEmpty ? name : code;
  }

  void setProjectId(int? value) {
    if (isProjectConstrained) {
      projectId = constrainedProjectId;
      taskId = null;
      update();
      return;
    }
    projectId = value;
    taskId = null;
    update();
  }

  void setTaskId(int? value) {
    taskId = value;
    update();
  }

  void setAssetId(int? value) {
    assetId = value;
    update();
  }

  void clearFormError() {
    if ((formError ?? '').isEmpty) {
      return;
    }
    formError = null;
    update();
  }

  void _syncCalculatedTotalCost() {
    final usageHours = doubleValue(usageHoursController.text) ?? 0;
    final usageQty = doubleValue(usageQtyController.text) ?? 0;
    final unitCost = doubleValue(unitCostController.text) ?? 0;
    final baseQty = usageHours > 0 ? usageHours : usageQty;
    final nextTotalCost = decimalText(baseQty * unitCost);

    if (totalCostController.text != nextTotalCost) {
      totalCostController.text = nextTotalCost;
    }

    update();
  }

  int? intValue(String text) => int.tryParse(text.trim());

  double? doubleValue(String text) => double.tryParse(text.trim());

  String decimalText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''));

  Future<String?> saveUsage() async {
    if (!formKey.currentState!.validate()) {
      return null;
    }
    final resolvedProjectId = projectId;
    if (resolvedProjectId == null) {
      formError = 'Project is required.';
      update();
      return null;
    }
    saving = true;
    formError = null;
    update();
    try {
      final model = ProjectResourceUsageModel(
        id: selectedRow?.usage.id,
        projectId: resolvedProjectId,
        projectTaskId: taskId,
        assetId: assetId,
        resourceName: resourceNameController.text.trim(),
        usageDate: usageDateController.text.trim(),
        usageHours: doubleValue(usageHoursController.text),
        usageQty: doubleValue(usageQtyController.text),
        unitCost: doubleValue(unitCostController.text),
        totalCost: doubleValue(totalCostController.text),
        voucherId: intValue(voucherIdController.text),
        remarks: nullIfEmpty(remarksController.text),
      );
      final response = selectedRow?.usage.id == null
          ? await _projectService.createResourceUsage(resolvedProjectId, model)
          : await _projectService.updateResourceUsage(
              selectedRow!.usage.id!,
              model,
            );
      await loadData(selectId: response.data?.id ?? selectedRow?.usage.id);
      _refreshController.notifyChanged(source: 'project_resource_usage');
      return response.message;
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
      return null;
    } finally {
      saving = false;
      update();
    }
  }

  Future<String?> deleteUsage() async {
    final row = selectedRow;
    if (row?.usage.id == null) {
      return null;
    }
    try {
      final response = await _projectService.deleteResourceUsage(
        row!.usage.id!,
      );
      formError = null;
      await loadData();
      _refreshController.notifyChanged(source: 'project_resource_usage');
      return response.message;
    } on ApiException catch (errorValue) {
      formError = errorValue.displayMessage;
      update();
      return errorValue.displayMessage;
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
      return formError;
    }
  }

  void startNewUsage({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}

class ProjectResourceUsageRow {
  const ProjectResourceUsageRow({required this.project, required this.usage});

  final ProjectModel project;
  final ProjectResourceUsageModel usage;
}
