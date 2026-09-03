import '../../screen.dart';
import 'project_module_refresh_controller.dart';

class ProjectMilestoneManagementController extends GetxController {
  ProjectMilestoneManagementController({
    this.constrainedProjectId,
    this.initialDashboardFilter = '',
  });

  final String initialDashboardFilter;

  final ProjectService _projectService = ProjectService();
  final MasterService _masterService = MasterService();
  final ProjectModuleRefreshController _refreshController =
      ProjectModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController targetDateController = TextEditingController();
  final TextEditingController completionDateController =
      TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool showDraftTile = false;
  bool canDeleteMilestones = false;
  String? pageError;
  String? formError;
  int? constrainedProjectId;
  int? projectId;
  String status = 'open';
  String listStatusFilter = 'all';
  Set<int> movingMilestoneIds = <int>{};
  Worker? _refreshWorker;

  List<ProjectModel> projects = const <ProjectModel>[];
  List<ProjectMilestoneRow> rows = const <ProjectMilestoneRow>[];
  List<ProjectMilestoneRow> filteredRows = const <ProjectMilestoneRow>[];
  ProjectMilestoneRow? selectedRow;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    _refreshWorker = ever<ProjectModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null || event.source == 'project_milestone') {
          return;
        }
        unawaited(loadData(selectId: selectedRow?.milestone.id));
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
    nameController.dispose();
    targetDateController.dispose();
    completionDateController.dispose();
    amountController.dispose();
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
      final permissionCodes = await SessionStorage.getPermissionCodes();
      final responses = await Future.wait<dynamic>([
        _refreshController.projects(loader: _projectService.projects),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);
      canDeleteMilestones = permissionCodes.contains('project.delete');
      final nextProjects = responses[0] as List<ProjectModel>;
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
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
            (project) => project.milestones.map(
              (milestone) =>
                  ProjectMilestoneRow(project: project, milestone: milestone),
            ),
          )
          .toList(growable: false);

      projects = scopedProjects;
      rows = nextRows;
      filteredRows = _filterRows(nextRows, searchController.text);
      initialLoading = false;
      update();

      final selected = selectId == null
          ? null
          : nextRows.cast<ProjectMilestoneRow?>().firstWhere(
              (item) => item?.milestone.id == selectId,
              orElse: () => null,
            );
      if (selected != null) {
        selectRow(selected, notify: false);
      } else {
        if (!isProjectConstrained && filteredRows.isNotEmpty) {
          selectRow(filteredRows.first, notify: false);
        } else {
          resetForm(notify: false);
        }
      }
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
      update();
    }
  }

  List<ProjectMilestoneRow> _filterRows(
    List<ProjectMilestoneRow> items,
    String query,
  ) {
    var scopedRows = items;
    if (initialDashboardFilter.trim() == 'due_today') {
      final now = DateTime.now();
      scopedRows = scopedRows
          .where((row) {
            final targetDate = DateTime.tryParse(
              row.milestone.targetDate?.trim() ?? '',
            );
            return targetDate != null &&
                targetDate.year == now.year &&
                targetDate.month == now.month &&
                targetDate.day == now.day;
          })
          .toList(growable: false);
    }

    final normalizedStatusFilter = listStatusFilter.trim().toLowerCase();
    if (normalizedStatusFilter == 'pending') {
      scopedRows = scopedRows
          .where(
            (row) =>
                (row.milestone.milestoneStatus ?? 'open')
                    .trim()
                    .toLowerCase() ==
                'open',
          )
          .toList(growable: false);
    } else if (normalizedStatusFilter != 'all' &&
        projectMilestoneStatusValues.contains(normalizedStatusFilter)) {
      scopedRows = scopedRows
          .where(
            (row) =>
                (row.milestone.milestoneStatus ?? 'open')
                    .trim()
                    .toLowerCase() ==
                normalizedStatusFilter,
          )
          .toList(growable: false);
    }

    return filterMasterList(scopedRows, query, (row) {
      return [
        row.milestone.milestoneName ?? '',
        row.project.projectName ?? '',
        row.milestone.milestoneStatus ?? '',
        row.milestone.remarks ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredRows = _filterRows(rows, searchController.text);
    update();
  }

  void setListStatusFilter(String? value) {
    final next = (value ?? 'all').trim().toLowerCase();
    if (listStatusFilter == next) {
      return;
    }
    listStatusFilter = next;
    filteredRows = _filterRows(rows, searchController.text);
    update();
  }

  void selectRow(
    ProjectMilestoneRow row, {
    bool notify = true,
    bool toggleIfSelected = true,
  }) {
    if (toggleIfSelected && selectedRow?.milestone.id == row.milestone.id) {
      resetForm(notify: notify);
      return;
    }
    showDraftTile = false;
    selectedRow = row;
    projectId = row.project.id;
    nameController.text = row.milestone.milestoneName ?? '';
    targetDateController.text = normalizeDateValue(row.milestone.targetDate);
    completionDateController.text = normalizeDateValue(
      row.milestone.completionDate,
    );
    amountController.text = _decimalText(row.milestone.milestoneAmount);
    remarksController.text = row.milestone.remarks ?? '';
    status = row.milestone.milestoneStatus ?? 'open';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedRow = null;
    projectId =
        constrainedProjectId ??
        (projects.isNotEmpty ? projects.first.id : null);
    nameController.clear();
    targetDateController.clear();
    completionDateController.clear();
    amountController.clear();
    remarksController.clear();
    status = 'open';
    formError = null;
    if (notify) {
      update();
    }
  }

  bool canMoveMilestoneToStatus(ProjectMilestoneRow row, String status) {
    final milestoneId = row.milestone.id;
    final nextStatus = status.trim().toLowerCase();
    final currentStatus = (row.milestone.milestoneStatus ?? 'open')
        .trim()
        .toLowerCase();
    return milestoneId != null &&
        projectMilestoneStatusValues.contains(nextStatus) &&
        nextStatus != currentStatus &&
        !movingMilestoneIds.contains(milestoneId);
  }

  Future<String?> moveMilestoneToStatus(
    ProjectMilestoneRow row,
    String status,
  ) async {
    if (!canMoveMilestoneToStatus(row, status)) {
      return null;
    }

    final milestoneId = row.milestone.id!;
    final nextStatus = status.trim().toLowerCase();
    final previousRows = rows;
    final previousFilteredRows = filteredRows;
    final previousSelectedRow = selectedRow;
    final previousEditorStatus = this.status;
    final updatedRow = ProjectMilestoneRow(
      project: row.project,
      milestone: projectMilestoneWithStatus(row.milestone, nextStatus),
    );

    movingMilestoneIds = <int>{...movingMilestoneIds, milestoneId};
    rows = <ProjectMilestoneRow>[
      for (final currentRow in rows)
        if (currentRow.milestone.id == milestoneId) updatedRow else currentRow,
    ];
    filteredRows = _filterRows(rows, searchController.text);
    if (selectedRow?.milestone.id == milestoneId) {
      selectedRow = updatedRow;
      this.status = nextStatus;
    }
    update();

    try {
      final response = await _projectService.updateMilestone(
        milestoneId,
        updatedRow.milestone,
      );
      await _reloadAfterMilestoneMutation(selectMilestoneId: milestoneId);
      return response.message;
    } catch (_) {
      rows = previousRows;
      filteredRows = previousFilteredRows;
      selectedRow = previousSelectedRow;
      this.status = previousEditorStatus;
      update();
      rethrow;
    } finally {
      movingMilestoneIds = <int>{...movingMilestoneIds}..remove(milestoneId);
      update();
    }
  }

  Future<void> _reloadAfterMilestoneMutation({int? selectMilestoneId}) async {
    _refreshController.invalidateProjects();
    await loadData(selectId: selectMilestoneId);
    _refreshController.notifyChanged(source: 'project_milestone');
  }

  Future<String?> saveMilestone() async {
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
      final model = ProjectMilestoneModel(
        id: selectedRow?.milestone.id,
        projectId: resolvedProjectId,
        milestoneName: nameController.text.trim(),
        targetDate: nullIfEmpty(targetDateController.text),
        completionDate: nullIfEmpty(completionDateController.text),
        milestoneAmount: _doubleValue(amountController.text),
        milestoneStatus: status,
        remarks: nullIfEmpty(remarksController.text),
      );
      final response = selectedRow?.milestone.id == null
          ? await _projectService.createMilestone(resolvedProjectId, model)
          : await _projectService.updateMilestone(
              selectedRow!.milestone.id!,
              model,
            );
      final savedId = response.data?.id ?? selectedRow?.milestone.id;
      showDraftTile = false;
      resetForm(notify: false);
      await _reloadAfterMilestoneMutation(selectMilestoneId: savedId);
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

  Future<String?> deleteMilestone() async {
    final row = selectedRow;
    if (row?.milestone.id == null) {
      return null;
    }
    final response = await _projectService.deleteMilestone(row!.milestone.id!);
    await _reloadAfterMilestoneMutation();
    return response.message;
  }

  void setProjectId(int? value) {
    if (isProjectConstrained) {
      projectId = constrainedProjectId;
      update();
      return;
    }
    projectId = value;
    update();
  }

  void setStatus(String value) {
    status = value;
    update();
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

  void startNewMilestone({required bool isDesktop, String? initialStatus}) {
    showDraftTile = true;
    resetForm();
    if (initialStatus != null &&
        projectMilestoneStatusValues.contains(initialStatus)) {
      status = initialStatus;
    }
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void hideDraftTile() {
    showDraftTile = false;
    resetForm();
    update();
  }

  double? _doubleValue(String text) => Validators.parseFlexibleNumber(text);

  String _decimalText(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}

class ProjectMilestoneRow {
  const ProjectMilestoneRow({required this.project, required this.milestone});

  final ProjectModel project;
  final ProjectMilestoneModel milestone;
}

const Set<String> projectMilestoneStatusValues = <String>{
  'open',
  'completed',
  'cancelled',
};

ProjectMilestoneModel projectMilestoneWithStatus(
  ProjectMilestoneModel milestone,
  String status,
) {
  return ProjectMilestoneModel.fromJson(<String, dynamic>{
    ...milestone.toJson(),
    if (milestone.id != null) 'id': milestone.id,
    'milestone_status': status.trim().toLowerCase(),
  });
}
