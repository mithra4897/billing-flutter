import '../../screen.dart';
import 'project_module_refresh_controller.dart';

class ProjectTaskManagementController extends GetxController {
  ProjectTaskManagementController({
    this.constrainedProjectId,
    this.initialProjectId,
    this.initialTaskId,
    this.initialDashboardFilter = '',
    ProjectService? projectService,
    ProjectModuleRefreshController? refreshController,
  }) : _projectService = projectService ?? ProjectService(),
       _refreshController =
           refreshController ??
           ProjectModuleRefreshController.ensureRegistered();

  final ProjectService _projectService;
  final HrService _hrService = HrService();
  final MasterService _masterService = MasterService();
  final ProjectModuleRefreshController _refreshController;
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

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
  bool showDraftTile = false;
  bool canDeleteTasks = false;
  String? pageError;
  String? formError;
  Worker? _refreshWorker;
  int? constrainedProjectId;
  final int? initialProjectId;
  final int? initialTaskId;
  final String initialDashboardFilter;
  int? projectId;
  int? assignedEmployeeId;
  Set<int> assignedEmployeeIds = <int>{};
  String taskStatus = 'open';
  String taskPriority = 'medium';
  bool isBillable = true;
  bool isSuperAdmin = false;
  int? linkedEmployeeId;
  String listStatusFilter = 'all';
  Set<String> selectedStatuses = const <String>{};
  Set<String> selectedPriorities = const <String>{};
  Set<int> filterProjectIds = const <int>{};
  Set<int> filterEmployeeIds = <int>{};
  Set<int> movingTaskIds = <int>{};

  List<ProjectModel> projects = const <ProjectModel>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];
  Map<int, String> employeeNamesById = const <int, String>{};
  List<ProjectTaskRow> rows = const <ProjectTaskRow>[];
  List<ProjectTaskRow> filteredRows = const <ProjectTaskRow>[];
  ProjectTaskRow? selectedRow;

  @override
  void onInit() {
    super.onInit();
    _applyInitialDashboardFilter();
    searchController.addListener(_applySearch);
    dateFromController.addListener(_applySearch);
    dateToController.addListener(_applySearch);
    taskCodeController.addListener(_handleTaskCodeChanged);
    _refreshWorker = ever<ProjectModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null || event.source == 'project_task') {
          return;
        }
        unawaited(loadData(selectTaskId: selectedRow?.task.id));
      },
    );
    loadData(selectTaskId: initialTaskId);
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    dateFromController
      ..removeListener(_applySearch)
      ..dispose();
    dateToController
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

  bool get isProjectConstrained => constrainedProjectId != null;

  bool get canManageTasks => isSuperAdmin;

  bool canEditTaskStatus(ProjectTaskRow? row) {
    if (canManageTasks) {
      return true;
    }
    final currentStatus = (row?.task.taskStatus ?? 'open').trim().toLowerCase();
    return row?.task.id != null && currentStatus != 'completed';
  }

  bool canSetTaskStatus(String currentStatus, String nextStatus) {
    if (canManageTasks) {
      return projectTaskStatusValues.contains(nextStatus);
    }
    return currentStatus != 'completed' &&
        normalUserProjectTaskStatusValues.contains(nextStatus);
  }

  void _applyInitialDashboardFilter() {
    final requested = initialDashboardFilter.trim().toLowerCase();
    if (const <String>{
      'pending',
      'all',
      'open',
      'working',
      'in_review',
      'on_hold',
      'completed',
      'cancelled',
    }.contains(requested)) {
      listStatusFilter = requested;
      selectedStatuses = switch (requested) {
        'pending' => const <String>{'open', 'working', 'in_review'},
        'all' => const <String>{},
        _ => <String>{requested},
      };
    }
  }

  Future<void> applyProjectConstraint(int? value) async {
    if (constrainedProjectId == value) {
      return;
    }
    constrainedProjectId = value;
    filterProjectIds = const <int>{};
    await loadData();
  }

  Future<void> loadData({int? selectTaskId}) async {
    initialLoading = rows.isEmpty;
    pageError = null;
    update();
    try {
      final permissionCodes = await SessionStorage.getPermissionCodes();
      final currentUser = await SessionStorage.getCurrentUser();
      final responses = await Future.wait<dynamic>([
        _refreshController.projects(loader: _projectService.projects),
        _hrService.employees(
          filters: const {'per_page': 300, 'sort_by': 'employee_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);

      final nextProjects = responses[0] as List<ProjectModel>;
      final nextEmployees =
          (responses[1] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];
      final companies =
          (responses[2] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];

      isSuperAdmin =
          currentUser?['is_super_admin'] == true ||
          currentUser?['is_super_admin'] == 1;

      final activeCompanies = companies.where((item) => item.isActive).toList();
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      if (!isSuperAdmin) {
        final cid = contextSelection.companyId;
        if (cid != null) {
          try {
            final ctxRes = await _projectService.linkedEmployee(companyId: cid);
            final ctx = ctxRes.data ?? const <String, dynamic>{};
            final viewAll =
                ctx['can_view_all_projects'] == true ||
                ctx['can_view_all_projects'] == 1;
            if (viewAll) {
              isSuperAdmin = true;
              linkedEmployeeId = null;
            } else {
              linkedEmployeeId = intValue(ctx, 'employee_id');
            }
          } catch (_) {
            linkedEmployeeId = null;
          }
        }
      } else {
        linkedEmployeeId = null;
      }

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
            (project) => project.tasks.map(
              (task) => ProjectTaskRow(project: project, task: task),
            ),
          )
          .toList(growable: false);

      projects = scopedProjects;
      canDeleteTasks = permissionCodes.contains('project.delete');
      employees = nextEmployees
          .where((item) => item.status == 'active')
          .toList(growable: false);
      employeeNamesById = <int, String>{
        for (final employee in employees)
          if (employee.id != null) employee.id!: employee.toString(),
      };
      rows = nextRows;
      filteredRows = filterRows(nextRows, searchController.text);
      initialLoading = false;
      update();

      if (selectTaskId != null) {
        final selected = nextRows.cast<ProjectTaskRow?>().firstWhere(
          (item) =>
              item?.task.id == selectTaskId &&
              (initialProjectId == null ||
                  item?.project.id == initialProjectId),
          orElse: () => null,
        );
        if (selected != null) {
          selectRow(selected, notify: false, toggleIfSelected: false);
          return;
        }
      }

      if (selectedRow != null) {
        final selected = nextRows.cast<ProjectTaskRow?>().firstWhere(
          (item) => item?.task.id == selectedRow?.task.id,
          orElse: () => null,
        );
        if (selected != null) {
          selectRow(selected, notify: false, toggleIfSelected: false);
          return;
        }
      }

      if (!isProjectConstrained && filteredRows.isNotEmpty) {
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
    var visibleRows = items
        .where((row) {
          if (filterProjectIds.isNotEmpty &&
              !filterProjectIds.contains(row.project.id)) {
            return false;
          }
          if (selectedPriorities.isNotEmpty &&
              !selectedPriorities.contains(
                (row.task.priority ?? 'medium').trim().toLowerCase(),
              )) {
            return false;
          }
          if (isSuperAdmin) {
            if (filterEmployeeIds.isEmpty) return true;
            return filterEmployeeIds.any(
              (employeeId) => _isAssignedTo(row.task, employeeId),
            );
          }
          final empId = linkedEmployeeId;
          if (empId == null) return false;
          return _isAssignedTo(row.task, empId);
        })
        .toList(growable: false);

    final statusFilter = listStatusFilter;
    visibleRows = visibleRows
        .where((row) {
          if (initialTaskId != null && row.task.id == initialTaskId) {
            return true;
          }
          final status = (row.task.taskStatus ?? 'open').trim().toLowerCase();
          if (selectedStatuses.isNotEmpty) {
            return selectedStatuses.contains(status);
          }
          if (statusFilter == 'all') return true;
          if (statusFilter == 'pending') {
            return const <String>{
              'open',
              'working',
              'in_review',
            }.contains(status);
          }
          return status == statusFilter;
        })
        .toList(growable: false);

    final from = dateFromController.text.trim();
    final to = dateToController.text.trim();
    if (from.isNotEmpty || to.isNotEmpty) {
      visibleRows = visibleRows
          .where((row) {
            final date = row.task.plannedStartDate ?? '';
            return (from.isEmpty || date.compareTo(from) >= 0) &&
                (to.isEmpty || date.compareTo(to) <= 0);
          })
          .toList(growable: false);
    }

    return filterMasterList(visibleRows, query, (row) {
      return [
        row.task.taskCode ?? '',
        row.task.taskName ?? '',
        row.project.projectName ?? '',
        employeeNames(
          row.task.assignedEmployeeIds.isEmpty &&
                  row.task.assignedEmployeeId != null
              ? <int>[row.task.assignedEmployeeId!]
              : row.task.assignedEmployeeIds,
        ).join(' '),
        row.task.taskStatus ?? '',
      ];
    });
  }

  void selectRow(
    ProjectTaskRow row, {
    bool notify = true,
    bool toggleIfSelected = true,
  }) {
    if (toggleIfSelected && selectedRow?.task.id == row.task.id) {
      resetForm(notify: notify);
      return;
    }
    showDraftTile = false;
    selectedRow = row;
    projectId = row.project.id;
    setTaskCode(row.task.taskCode ?? '', autoGenerated: false);
    taskNameController.text = row.task.taskName ?? '';
    descriptionController.text = row.task.description ?? '';
    plannedStartDateController.text = normalizeDateValue(
      row.task.plannedStartDate,
    );
    plannedEndDateController.text = normalizeDateValue(row.task.plannedEndDate);
    actualStartDateController.text = normalizeDateValue(
      row.task.actualStartDate,
    );
    actualEndDateController.text = normalizeDateValue(row.task.actualEndDate);
    estimatedHoursController.text = decimalText(row.task.estimatedHours);
    actualHoursController.text = decimalText(row.task.actualHours);
    estimatedCostController.text = decimalText(row.task.estimatedCost);
    actualCostController.text = decimalText(row.task.actualCost);
    progressPercentController.text = decimalText(
      taskProgressForStatus(row.task.taskStatus ?? 'open'),
    );
    remarksController.text = row.task.remarks ?? '';
    assignedEmployeeId = row.task.assignedEmployeeId;
    assignedEmployeeIds =
        row.task.assignedEmployeeIds.isEmpty &&
            row.task.assignedEmployeeId != null
        ? <int>{row.task.assignedEmployeeId!}
        : row.task.assignedEmployeeIds.toSet();
    taskStatus = row.task.taskStatus ?? 'open';
    taskPriority = row.task.priority ?? 'medium';
    isBillable = row.task.isBillable ?? true;
    loadingTaskCode = false;
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
    progressPercentController.text = '0';
    remarksController.clear();
    assignedEmployeeId = null;
    assignedEmployeeIds = <int>{};
    taskStatus = 'open';
    taskPriority = 'medium';
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
    final existingRow = selectedRow;
    if (!canManageTasks && existingRow == null) {
      formError = 'Only Project Heads can create project tasks.';
      update();
      return null;
    }
    if (!canEditTaskStatus(existingRow) ||
        !canSetTaskStatus(
          (existingRow?.task.taskStatus ?? 'open').trim().toLowerCase(),
          taskStatus.trim().toLowerCase(),
        )) {
      formError =
          'You can only update an active task to Open, In Progress, or In Review.';
      update();
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
      final draftModel = ProjectTaskModel(
        id: selectedRow?.task.id,
        projectId: resolvedProjectId,
        taskCode: nullIfEmpty(taskCodeController.text),
        taskName: taskNameController.text.trim(),
        description: nullIfEmpty(descriptionController.text),
        assignedEmployeeId: assignedEmployeeId,
        assignedEmployeeIds: assignedEmployeeIds.toList(growable: false),
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
        priority: taskPriority,
        isBillable: isBillable,
        remarks: nullIfEmpty(remarksController.text),
      );
      final model = canManageTasks
          ? draftModel
          : projectTaskWithStatus(existingRow!.task, taskStatus);

      final response = existingRow?.task.id == null
          ? await _projectService.createTask(resolvedProjectId, model)
          : await _projectService.updateTask(existingRow!.task.id!, model);
      showDraftTile = false;
      resetForm(notify: false);
      await _reloadAfterTaskMutation(selectTaskId: response.data?.id);
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
    if (!canManageTasks) {
      formError = 'Only Project Heads can delete project tasks.';
      update();
      return null;
    }
    final row = selectedRow;
    if (row?.task.id == null) {
      return null;
    }
    final response = await _projectService.deleteTask(row!.task.id!);
    await _reloadAfterTaskMutation();
    return response.message;
  }

  bool canMoveTaskToStatus(ProjectTaskRow row, String status) {
    final taskId = row.task.id;
    final nextStatus = status.trim().toLowerCase();
    final currentStatus = (row.task.taskStatus ?? 'open').trim().toLowerCase();
    return taskId != null &&
        projectTaskStatusValues.contains(nextStatus) &&
        nextStatus != currentStatus &&
        canSetTaskStatus(currentStatus, nextStatus) &&
        !movingTaskIds.contains(taskId);
  }

  Future<String?> moveTaskToStatus(ProjectTaskRow row, String status) async {
    if (!canMoveTaskToStatus(row, status)) {
      return null;
    }

    final taskId = row.task.id!;
    final nextStatus = status.trim().toLowerCase();
    final previousRows = rows;
    final previousFilteredRows = filteredRows;
    final previousSelectedRow = selectedRow;
    final previousEditorStatus = taskStatus;
    final updatedRow = ProjectTaskRow(
      project: row.project,
      task: projectTaskWithStatus(row.task, nextStatus),
    );

    movingTaskIds = <int>{...movingTaskIds, taskId};
    rows = <ProjectTaskRow>[
      for (final currentRow in rows)
        if (currentRow.task.id == taskId) updatedRow else currentRow,
    ];
    filteredRows = filterRows(rows, searchController.text);
    if (selectedRow?.task.id == taskId) {
      selectedRow = updatedRow;
      taskStatus = nextStatus;
    }
    update();

    try {
      final response = await _projectService.updateTask(
        taskId,
        updatedRow.task,
      );
      await _reloadAfterTaskMutation(selectTaskId: taskId);
      return response.message;
    } catch (_) {
      rows = previousRows;
      filteredRows = previousFilteredRows;
      selectedRow = previousSelectedRow;
      taskStatus = previousEditorStatus;
      update();
      rethrow;
    } finally {
      movingTaskIds = <int>{...movingTaskIds}..remove(taskId);
      update();
    }
  }

  Future<void> _reloadAfterTaskMutation({int? selectTaskId}) async {
    _refreshController.invalidateProjects();
    await loadData(selectTaskId: selectTaskId);
    _refreshController.notifyChanged(source: 'project_task');
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

  List<AppDropdownItem<int>> get assignedEmployeeFilterItems {
    final assignedIds = rows
        .expand((row) => _assignedEmployeeIds(row.task))
        .toSet();
    return employees
        .where(
          (employee) =>
              employee.id != null && assignedIds.contains(employee.id),
        )
        .map(
          (employee) => AppDropdownItem<int>(
            value: employee.id!,
            label: employee.toString(),
          ),
        )
        .toList(growable: false);
  }

  void setFilterEmployeeIds(Set<int> values) {
    filterEmployeeIds = Set<int>.from(values);
    filteredRows = filterRows(rows, searchController.text);
    if (selectedRow != null && !filteredRows.contains(selectedRow)) {
      selectedRow = null;
    }
    update();
  }

  void setFilterProjectIds(Set<int> values) {
    filterProjectIds = Set<int>.from(values);
    _refreshFilteredRows();
  }

  void setSelectedStatuses(Set<String> values) {
    selectedStatuses = Set<String>.from(values);
    listStatusFilter = selectedStatuses.length == 1
        ? selectedStatuses.first
        : 'all';
    _refreshFilteredRows();
  }

  void setSelectedPriorities(Set<String> values) {
    selectedPriorities = Set<String>.from(values);
    _refreshFilteredRows();
  }

  void clearFilters() {
    dateFromController.clear();
    dateToController.clear();
    selectedStatuses = const <String>{};
    selectedPriorities = const <String>{};
    filterProjectIds = const <int>{};
    filterEmployeeIds = <int>{};
    listStatusFilter = 'all';
    _refreshFilteredRows();
  }

  void _refreshFilteredRows() {
    filteredRows = filterRows(rows, searchController.text);
    if (selectedRow != null && !filteredRows.contains(selectedRow)) {
      selectedRow = null;
    }
    update();
  }

  void setListStatusFilter(String? value) {
    listStatusFilter = value ?? 'all';
    selectedStatuses = switch (listStatusFilter) {
      'pending' => const <String>{'open', 'working', 'in_review'},
      'all' => const <String>{},
      _ => <String>{listStatusFilter},
    };
    filteredRows = filterRows(rows, searchController.text);
    if (selectedRow != null && !filteredRows.contains(selectedRow)) {
      selectedRow = null;
    }
    update();
  }

  List<int> _assignedEmployeeIds(ProjectTaskModel task) {
    if (task.assignedEmployeeIds.isNotEmpty) {
      return task.assignedEmployeeIds;
    }
    return task.assignedEmployeeId == null
        ? const <int>[]
        : <int>[task.assignedEmployeeId!];
  }

  bool _isAssignedTo(ProjectTaskModel task, int employeeId) {
    return _assignedEmployeeIds(task).contains(employeeId);
  }

  String employeeName(int? id) {
    return employeeNamesById[id] ?? '';
  }

  List<String> employeeNames(Iterable<int> ids) {
    return ids
        .map(employeeName)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  void setProjectId(int? value) {
    if (isProjectConstrained) {
      projectId = constrainedProjectId;
      update();
      return;
    }
    projectId = value;
    update();
    unawaited(primeTaskCodeSuggestion());
  }

  void setAssignedEmployeeId(int? value) {
    assignedEmployeeId = value;
    update();
  }

  void toggleAssignedEmployeeId(int value) {
    final next = Set<int>.from(assignedEmployeeIds);
    if (!next.add(value)) {
      next.remove(value);
    }
    setAssignedEmployeeIds(next);
  }

  void setAssignedEmployeeIds(Set<int> values) {
    assignedEmployeeIds = Set<int>.from(values);
    assignedEmployeeId = assignedEmployeeIds.isEmpty
        ? null
        : assignedEmployeeIds.first;
    update();
  }

  void setTaskStatus(String value) {
    final normalized = value.trim().toLowerCase();
    final currentStatus = (selectedRow?.task.taskStatus ?? taskStatus)
        .trim()
        .toLowerCase();
    if (!canSetTaskStatus(currentStatus, normalized)) {
      return;
    }
    taskStatus = normalized;
    progressPercentController.text = taskProgressForStatus(
      taskStatus,
    ).toStringAsFixed(0);
    update();
  }

  void setTaskPriority(String value) {
    taskPriority = value;
    update();
  }

  void setIsBillable(bool value) {
    isBillable = value;
    update();
  }

  double? doubleValue(String text) => Validators.parseFlexibleNumber(text);

  String decimalText(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  void startNewTask({required bool isDesktop}) {
    if (!canManageTasks) {
      formError = 'Only Project Heads can create project tasks.';
      update();
      return;
    }
    showDraftTile = true;
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void hideDraftTile() {
    showDraftTile = false;
    resetForm();
    update();
  }
}

double taskProgressForStatus(String status) {
  switch (status.trim().toLowerCase()) {
    case 'working':
    case 'in_review':
    case 'on_hold':
      return 50;
    case 'completed':
      return 100;
    default:
      return 0;
  }
}

class ProjectTaskRow {
  const ProjectTaskRow({required this.project, required this.task});

  final ProjectModel project;
  final ProjectTaskModel task;
}

const Set<String> projectTaskStatusValues = <String>{
  'open',
  'working',
  'in_review',
  'on_hold',
  'completed',
  'cancelled',
};

const Set<String> normalUserProjectTaskStatusValues = <String>{
  'open',
  'working',
  'in_review',
};

ProjectTaskModel projectTaskWithStatus(ProjectTaskModel task, String status) {
  return ProjectTaskModel.fromJson(<String, dynamic>{
    ...task.toJson(),
    if (task.id != null) 'id': task.id,
    'task_status': status.trim().toLowerCase(),
    'progress_percent': taskProgressForStatus(status),
  });
}
