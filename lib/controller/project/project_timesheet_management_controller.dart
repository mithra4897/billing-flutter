import '../../screen.dart';
import '../../helper/project_register_reload_helper.dart';

class ProjectTimesheetManagementController extends GetxController {
  ProjectTimesheetManagementController();

  final ProjectService _projectService = ProjectService();
  final HrService _hrService = HrService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController workDateController = TextEditingController();
  final TextEditingController hoursWorkedController = TextEditingController();
  final TextEditingController hourlyCostController = TextEditingController();
  final TextEditingController billableRateController = TextEditingController();
  final TextEditingController costAmountController = TextEditingController();
  final TextEditingController billableAmountController =
      TextEditingController();
  final TextEditingController voucherIdController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  int? projectId;
  int? taskId;
  int? employeeId;
  String status = 'draft';

  List<ProjectModel> projects = const <ProjectModel>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];
  List<ProjectTimesheetRow> rows = const <ProjectTimesheetRow>[];
  List<ProjectTimesheetRow> filteredRows = const <ProjectTimesheetRow>[];
  ProjectTimesheetRow? selectedRow;

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
    workDateController.dispose();
    hoursWorkedController.dispose();
    hourlyCostController.dispose();
    billableRateController.dispose();
    costAmountController.dispose();
    billableAmountController.dispose();
    voucherIdController.dispose();
    notesController.dispose();
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
            (project) => project.timesheets.map(
              (timesheet) =>
                  ProjectTimesheetRow(project: project, timesheet: timesheet),
            ),
          )
          .toList(growable: false);

      projects = scopedProjects;
      employees = nextEmployees
          .where((item) => item.status == 'active')
          .toList(growable: false);
      rows = nextRows;
      filteredRows = _filterRows(nextRows, searchController.text);
      initialLoading = false;
      update();

      final selected = selectId == null
          ? null
          : nextRows.cast<ProjectTimesheetRow?>().firstWhere(
              (item) => item?.timesheet.id == selectId,
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

  List<ProjectTimesheetRow> _filterRows(
    List<ProjectTimesheetRow> items,
    String query,
  ) {
    return filterMasterList(items, query, (row) {
      return [
        row.project.projectName ?? '',
        employeeName(row.timesheet.employeeId),
        row.timesheet.workDate ?? '',
        row.timesheet.timesheetStatus ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredRows = _filterRows(rows, searchController.text);
    update();
  }

  void selectRow(ProjectTimesheetRow row, {bool notify = true}) {
    selectedRow = row;
    projectId = row.project.id;
    taskId = row.timesheet.projectTaskId;
    employeeId = row.timesheet.employeeId;
    workDateController.text = normalizeDateValue(row.timesheet.workDate);
    hoursWorkedController.text = decimalText(row.timesheet.hoursWorked);
    hourlyCostController.text = decimalText(row.timesheet.hourlyCost);
    billableRateController.text = decimalText(row.timesheet.billableRate);
    costAmountController.text = decimalText(row.timesheet.costAmount);
    billableAmountController.text = decimalText(row.timesheet.billableAmount);
    voucherIdController.text = row.timesheet.voucherId?.toString() ?? '';
    notesController.text = row.timesheet.notes ?? '';
    status = row.timesheet.timesheetStatus ?? 'draft';
    formError = null;
    if (notify) update();
  }

  void resetForm({bool notify = true}) {
    selectedRow = null;
    projectId = projects.isNotEmpty ? projects.first.id : null;
    taskId = null;
    employeeId = null;
    workDateController.clear();
    hoursWorkedController.clear();
    hourlyCostController.clear();
    billableRateController.clear();
    costAmountController.clear();
    billableAmountController.clear();
    voucherIdController.clear();
    notesController.clear();
    status = 'draft';
    formError = null;
    if (notify) update();
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

  String employeeName(int? id) {
    return employees
            .cast<EmployeeModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.toString() ??
        '';
  }

  void setProjectId(int? value) {
    projectId = value;
    taskId = null;
    update();
  }

  void setTaskId(int? value) {
    taskId = value;
    update();
  }

  void setEmployeeId(int? value) {
    employeeId = value;
    update();
  }

  void setStatus(String value) {
    status = value;
    update();
  }

  double? doubleValue(String text) => double.tryParse(text.trim());
  int? intValue(String text) => int.tryParse(text.trim());

  String decimalText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());

  Future<String?> saveTimesheet() async {
    if (!formKey.currentState!.validate()) return null;
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
      final model = ProjectTimesheetModel(
        id: selectedRow?.timesheet.id,
        projectId: resolvedProjectId,
        projectTaskId: taskId,
        employeeId: employeeId,
        workDate: workDateController.text.trim(),
        hoursWorked: doubleValue(hoursWorkedController.text),
        hourlyCost: doubleValue(hourlyCostController.text),
        billableRate: doubleValue(billableRateController.text),
        costAmount: doubleValue(costAmountController.text),
        billableAmount: doubleValue(billableAmountController.text),
        voucherId: intValue(voucherIdController.text),
        timesheetStatus: status,
        notes: nullIfEmpty(notesController.text),
      );
      final response = selectedRow?.timesheet.id == null
          ? await _projectService.createTimesheet(resolvedProjectId, model)
          : await _projectService.updateTimesheet(
              selectedRow!.timesheet.id!,
              model,
            );
      await loadData(selectId: response.data?.id ?? selectedRow?.timesheet.id);
      reloadProjectTimesheetRegister();
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

  Future<String?> deleteTimesheet() async {
    final row = selectedRow;
    if (row?.timesheet.id == null) return null;
    final response = await _projectService.deleteTimesheet(row!.timesheet.id!);
    await loadData();
    reloadProjectTimesheetRegister();
    return response.message;
  }

  void startNewTimesheet({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) workspaceController.openEditor();
  }
}

class ProjectTimesheetRow {
  const ProjectTimesheetRow({required this.project, required this.timesheet});

  final ProjectModel project;
  final ProjectTimesheetModel timesheet;
}
