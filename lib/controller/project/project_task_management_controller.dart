import '../../screen.dart';

class ProjectTaskManagementController extends GetxController {
  ProjectTaskManagementController();

  final ProjectService _projectService = ProjectService();
  final HrService _hrService = HrService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController taskCodeController = TextEditingController();
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController plannedStartDateController =
      TextEditingController();
  final TextEditingController plannedEndDateController =
      TextEditingController();
  final TextEditingController actualStartDateController =
      TextEditingController();
  final TextEditingController actualEndDateController = TextEditingController();
  final TextEditingController estimatedHoursController =
      TextEditingController();
  final TextEditingController actualHoursController = TextEditingController();
  final TextEditingController estimatedCostController = TextEditingController();
  final TextEditingController actualCostController = TextEditingController();
  final TextEditingController progressPercentController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool loadingTaskCode = false;
  bool suppressTaskCodeListener = false;
  bool taskCodeManuallyEdited = false;
  String? pageError;
  String? formError;
  int? projectId;
  int? assignedEmployeeId;
  String taskStatus = 'open';
  bool isBillable = true;

  List<ProjectModel> projects = const <ProjectModel>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];
  List<ProjectTaskRow> rows = const <ProjectTaskRow>[];
  List<ProjectTaskRow> filteredRows = const <ProjectTaskRow>[];
  ProjectTaskRow? selectedRow;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    taskCodeController.addListener(_handleTaskCodeChanged);
    loadData();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    taskCodeController
      ..removeListener(_handleTaskCodeChanged)
      ..dispose();
    taskNameController.dispose();
    descriptionController.dispose();
    plannedStartDateController.dispose();
    plannedEndDateController.dispose();
    actualStartDateController.dispose();
    actualEndDateController.dispose();
    estimatedHoursController.dispose();
    actualHoursController.dispose();
    estimatedCostController.dispose();
    actualCostController.dispose();
    progressPercentController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectTaskId}) async {
    initialLoading = rows.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _projectService.projects(
          filters: const {'per_page': 200, 'sort_by': 'project_name'},
        ),
        _hrService.employees(
          filters: const {'per_page': 300, 'sort_by': 'employee_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);

      final nextProjects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
      final nextEmployees =
          (responses[1] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];
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
      final scopedProjects = contextSelection.companyId == null
          ? nextProjects
          : nextProjects
                .where((item) => item.companyId == contextSelection.companyId)
                .toList(growable: false);

      final nextRows = scopedProjects
          .expand(
            (project) => project.tasks.map(
              (task) => ProjectTaskRow(project: project, task: task),
            ),
          )
          .toList(growable: false);

      projects = scopedProjects;
      employees = nextEmployees
          .where((item) => item.status == 'active')
          .toList(growable: false);
      rows = nextRows;
      filteredRows = filterRows(nextRows, searchController.text);
      initialLoading = false;
      update();

      if (selectTaskId != null) {
        final selected = nextRows.cast<ProjectTaskRow?>().firstWhere(
          (item) => item?.task.id == selectTaskId,
          orElse: () => null,
        );
        if (selected != null) {
          selectRow(selected, notify: false);
          return;
        }
      }

      if (selectedRow != null) {
        final selected = nextRows.cast<ProjectTaskRow?>().firstWhere(
          (item) => item?.task.id == selectedRow?.task.id,
          orElse: () => null,
        );
        if (selected != null) {
          selectRow(selected, notify: false);
          return;
        }
      }

      if (filteredRows.isNotEmpty) {
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

  void _applySearch() {
    filteredRows = filterRows(rows, searchController.text);
    update();
  }

  List<ProjectTaskRow> filterRows(List<ProjectTaskRow> items, String query) {
    return filterMasterList(items, query, (row) {
      return [
        row.task.taskCode ?? '',
        row.task.taskName ?? '',
        row.project.projectName ?? '',
        employeeName(row.task.assignedEmployeeId),
        row.task.taskStatus ?? '',
      ];
    });
  }

  void selectRow(ProjectTaskRow row, {bool notify = true}) {
    selectedRow = row;
    projectId = row.project.id;
    setTaskCode(row.task.taskCode ?? '', autoGenerated: false);
    taskNameController.text = row.task.taskName ?? '';
    descriptionController.text = row.task.description ?? '';
    plannedStartDateController.text = row.task.plannedStartDate ?? '';
    plannedEndDateController.text = row.task.plannedEndDate ?? '';
    actualStartDateController.text = row.task.actualStartDate ?? '';
    actualEndDateController.text = row.task.actualEndDate ?? '';
    estimatedHoursController.text = decimalText(row.task.estimatedHours);
    actualHoursController.text = decimalText(row.task.actualHours);
    estimatedCostController.text = decimalText(row.task.estimatedCost);
    actualCostController.text = decimalText(row.task.actualCost);
    progressPercentController.text = decimalText(row.task.progressPercent);
    remarksController.text = row.task.remarks ?? '';
    assignedEmployeeId = row.task.assignedEmployeeId;
    taskStatus = row.task.taskStatus ?? 'open';
    isBillable = row.task.isBillable ?? true;
    loadingTaskCode = false;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedRow = null;
    projectId = projects.isNotEmpty ? projects.first.id : null;
    setTaskCode('', autoGenerated: true);
    taskNameController.clear();
    descriptionController.clear();
    plannedStartDateController.clear();
    plannedEndDateController.clear();
    actualStartDateController.clear();
    actualEndDateController.clear();
    estimatedHoursController.clear();
    actualHoursController.clear();
    estimatedCostController.clear();
    actualCostController.clear();
    progressPercentController.clear();
    remarksController.clear();
    assignedEmployeeId = null;
    taskStatus = 'open';
    isBillable = true;
    loadingTaskCode = false;
    formError = null;
    taskCodeManuallyEdited = false;
    if (notify) {
      update();
    }
    unawaited(primeTaskCodeSuggestion());
  }

  bool get isNewTask => selectedRow?.task.id == null;

  void _handleTaskCodeChanged() {
    if (suppressTaskCodeListener || !isNewTask) {
      return;
    }
    taskCodeManuallyEdited = taskCodeController.text.trim().isNotEmpty;
  }

  void setTaskCode(String value, {required bool autoGenerated}) {
    suppressTaskCodeListener = true;
    taskCodeController.value = taskCodeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    suppressTaskCodeListener = false;
    taskCodeManuallyEdited = !autoGenerated && value.trim().isNotEmpty;
  }

  Future<void> primeTaskCodeSuggestion() async {
    final resolvedProjectId = projectId;
    if (!isNewTask || taskCodeManuallyEdited || resolvedProjectId == null) {
      return;
    }

    loadingTaskCode = true;
    update();
    try {
      final code = await _projectService.nextTaskCode(
        projectId: resolvedProjectId,
      );
      if (!isNewTask ||
          taskCodeManuallyEdited ||
          resolvedProjectId != projectId) {
        return;
      }
      final trimmed = (code ?? '').trim();
      if (trimmed.isEmpty) {
        return;
      }
      setTaskCode(trimmed, autoGenerated: true);
      update();
    } catch (_) {
    } finally {
      loadingTaskCode = false;
      update();
    }
  }

  Future<String?> saveTask() async {
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
      final model = ProjectTaskModel(
        id: selectedRow?.task.id,
        projectId: resolvedProjectId,
        taskCode: nullIfEmpty(taskCodeController.text),
        taskName: taskNameController.text.trim(),
        description: nullIfEmpty(descriptionController.text),
        assignedEmployeeId: assignedEmployeeId,
        plannedStartDate: nullIfEmpty(plannedStartDateController.text),
        plannedEndDate: nullIfEmpty(plannedEndDateController.text),
        actualStartDate: nullIfEmpty(actualStartDateController.text),
        actualEndDate: nullIfEmpty(actualEndDateController.text),
        estimatedHours: doubleValue(estimatedHoursController.text),
        actualHours: doubleValue(actualHoursController.text),
        estimatedCost: doubleValue(estimatedCostController.text),
        actualCost: doubleValue(actualCostController.text),
        progressPercent: doubleValue(progressPercentController.text),
        taskStatus: taskStatus,
        isBillable: isBillable,
        remarks: nullIfEmpty(remarksController.text),
      );

      final response = selectedRow?.task.id == null
          ? await _projectService.createTask(resolvedProjectId, model)
          : await _projectService.updateTask(selectedRow!.task.id!, model);
      await loadData(selectTaskId: response.data?.id ?? selectedRow?.task.id);
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

  Future<String?> deleteTask() async {
    final row = selectedRow;
    if (row?.task.id == null) {
      return null;
    }
    final response = await _projectService.deleteTask(row!.task.id!);
    await loadData();
    return response.message;
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

  List<AppDropdownItem<int>> get employeeItems => employees
      .map(
        (item) =>
            AppDropdownItem<int>(value: item.id ?? 0, label: item.toString()),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  String employeeName(int? id) {
    return employees
            .cast<EmployeeModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.toString() ??
        '';
  }

  void setProjectId(int? value) {
    projectId = value;
    update();
    unawaited(primeTaskCodeSuggestion());
  }

  void setAssignedEmployeeId(int? value) {
    assignedEmployeeId = value;
    update();
  }

  void setTaskStatus(String value) {
    taskStatus = value;
    update();
  }

  void setIsBillable(bool value) {
    isBillable = value;
    update();
  }

  double? doubleValue(String text) => double.tryParse(text.trim());

  String decimalText(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  void startNewTask({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}

class ProjectTaskRow {
  const ProjectTaskRow({required this.project, required this.task});

  final ProjectModel project;
  final ProjectTaskModel task;
}
