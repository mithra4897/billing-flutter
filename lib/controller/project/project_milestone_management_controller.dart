import '../../screen.dart';
import '../../helper/project_register_reload_helper.dart';

class ProjectMilestoneManagementController extends GetxController {
  ProjectMilestoneManagementController();

  final ProjectService _projectService = ProjectService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController targetDateController = TextEditingController();
  final TextEditingController completionDateController =
      TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  int? projectId;
  String status = 'open';

  List<ProjectModel> projects = const <ProjectModel>[];
  List<ProjectMilestoneRow> rows = const <ProjectMilestoneRow>[];
  List<ProjectMilestoneRow> filteredRows = const <ProjectMilestoneRow>[];
  ProjectMilestoneRow? selectedRow;

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
    nameController.dispose();
    targetDateController.dispose();
    completionDateController.dispose();
    amountController.dispose();
    remarksController.dispose();
    super.onClose();
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
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);
      final nextProjects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
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
      final scopedProjects = contextSelection.companyId == null
          ? nextProjects
          : nextProjects
                .where((item) => item.companyId == contextSelection.companyId)
                .toList(growable: false);
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
      } else if (filteredRows.isNotEmpty) {
        selectRow(filteredRows.first, notify: false);
      } else {
        resetForm(notify: false);
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
    return filterMasterList(items, query, (row) {
      return [
        row.milestone.milestoneName ?? '',
        row.project.projectName ?? '',
        row.milestone.milestoneStatus ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredRows = _filterRows(rows, searchController.text);
    update();
  }

  void selectRow(ProjectMilestoneRow row, {bool notify = true}) {
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
    projectId = projects.isNotEmpty ? projects.first.id : null;
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

  Future<String?> saveMilestone() async {
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
      await loadData(selectId: response.data?.id ?? selectedRow?.milestone.id);
      reloadProjectMilestoneRegister();
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
    await loadData();
    reloadProjectMilestoneRegister();
    return response.message;
  }

  void setProjectId(int? value) {
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

  void startNewMilestone({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  double? _doubleValue(String text) => double.tryParse(text.trim());

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
