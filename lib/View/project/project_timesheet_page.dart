import '../../screen.dart';

class ProjectTimesheetManagementPage extends StatefulWidget {
  const ProjectTimesheetManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectTimesheetManagementPage> createState() =>
      _ProjectTimesheetManagementPageState();
}

class _ProjectTimesheetManagementPageState
    extends State<ProjectTimesheetManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'rejected', label: 'Rejected'),
      ];

  final ProjectService _projectService = ProjectService();
  final HrService _hrService = HrService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _workDateController = TextEditingController();
  final TextEditingController _hoursWorkedController = TextEditingController();
  final TextEditingController _hourlyCostController = TextEditingController();
  final TextEditingController _billableRateController = TextEditingController();
  final TextEditingController _costAmountController = TextEditingController();
  final TextEditingController _billableAmountController =
      TextEditingController();
  final TextEditingController _voucherIdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  int? _projectId;
  int? _taskId;
  int? _employeeId;
  String _status = 'draft';

  List<ProjectModel> _projects = const <ProjectModel>[];
  List<EmployeeModel> _employees = const <EmployeeModel>[];
  List<_ProjectTimesheetRow> _rows = const <_ProjectTimesheetRow>[];
  List<_ProjectTimesheetRow> _filteredRows = const <_ProjectTimesheetRow>[];
  _ProjectTimesheetRow? _selectedRow;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _workDateController.dispose();
    _hoursWorkedController.dispose();
    _hourlyCostController.dispose();
    _billableRateController.dispose();
    _costAmountController.dispose();
    _billableAmountController.dispose();
    _voucherIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _rows.isEmpty;
      _pageError = null;
    });
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
      final projects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
      final employees =
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
          ? projects
          : projects
                .where((item) => item.companyId == contextSelection.companyId)
                .toList();
      final rows = scopedProjects
          .expand(
            (project) => project.timesheets.map(
              (timesheet) =>
                  _ProjectTimesheetRow(project: project, timesheet: timesheet),
            ),
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _projects = scopedProjects;
        _employees = employees
            .where((item) => item.status == 'active')
            .toList();
        _rows = rows;
        _filteredRows = _filterRows(rows, _searchController.text);
        _initialLoading = false;
      });
      final selected = selectId == null
          ? null
          : rows.cast<_ProjectTimesheetRow?>().firstWhere(
              (item) => item?.timesheet.id == selectId,
              orElse: () => null,
            );
      if (selected != null) {
        _selectRow(selected);
      } else if (_filteredRows.isNotEmpty) {
        _selectRow(_filteredRows.first);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  List<_ProjectTimesheetRow> _filterRows(
    List<_ProjectTimesheetRow> rows,
    String query,
  ) {
    return filterMasterList(rows, query, (row) {
      return [
        row.project.projectName ?? '',
        _employeeName(row.timesheet.employeeId),
        row.timesheet.workDate ?? '',
        row.timesheet.timesheetStatus ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredRows = _filterRows(_rows, _searchController.text);
    });
  }

  void _selectRow(_ProjectTimesheetRow row) {
    _selectedRow = row;
    _projectId = row.project.id;
    _taskId = row.timesheet.projectTaskId;
    _employeeId = row.timesheet.employeeId;
    _workDateController.text = row.timesheet.workDate ?? '';
    _hoursWorkedController.text = _decimalText(row.timesheet.hoursWorked);
    _hourlyCostController.text = _decimalText(row.timesheet.hourlyCost);
    _billableRateController.text = _decimalText(row.timesheet.billableRate);
    _costAmountController.text = _decimalText(row.timesheet.costAmount);
    _billableAmountController.text = _decimalText(row.timesheet.billableAmount);
    _voucherIdController.text = row.timesheet.voucherId?.toString() ?? '';
    _notesController.text = row.timesheet.notes ?? '';
    _status = row.timesheet.timesheetStatus ?? 'draft';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedRow = null;
    _projectId = _projects.isNotEmpty ? _projects.first.id : null;
    _taskId = null;
    _employeeId = null;
    _workDateController.clear();
    _hoursWorkedController.clear();
    _hourlyCostController.clear();
    _billableRateController.clear();
    _costAmountController.clear();
    _billableAmountController.clear();
    _voucherIdController.clear();
    _notesController.clear();
    _status = 'draft';
    _formError = null;
    setState(() {});
  }

  List<AppDropdownItem<int>> get _projectItems => _projects
      .map(
        (item) => AppDropdownItem<int>(
          value: item.id ?? 0,
          label: item.projectName ?? item.projectCode ?? 'Project',
        ),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get _employeeItems => _employees
      .map(
        (item) =>
            AppDropdownItem<int>(value: item.id ?? 0, label: item.toString()),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get _taskItems {
    final project = _projects.cast<ProjectModel?>().firstWhere(
      (item) => item?.id == _projectId,
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

  String _employeeName(int? id) {
    return _employees
            .cast<EmployeeModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.toString() ??
        '';
  }

  double? _doubleValue(String text) => double.tryParse(text.trim());
  int? _intValue(String text) => int.tryParse(text.trim());
  String _decimalText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());

  Future<void> _saveTimesheet() async {
    if (!_formKey.currentState!.validate()) return;
    final projectId = _projectId;
    if (projectId == null) {
      setState(() => _formError = 'Project is required.');
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      final model = ProjectTimesheetModel(
        id: _selectedRow?.timesheet.id,
        projectId: projectId,
        projectTaskId: _taskId,
        employeeId: _employeeId,
        workDate: _workDateController.text.trim(),
        hoursWorked: _doubleValue(_hoursWorkedController.text),
        hourlyCost: _doubleValue(_hourlyCostController.text),
        billableRate: _doubleValue(_billableRateController.text),
        costAmount: _doubleValue(_costAmountController.text),
        billableAmount: _doubleValue(_billableAmountController.text),
        voucherId: _intValue(_voucherIdController.text),
        timesheetStatus: _status,
        notes: nullIfEmpty(_notesController.text),
      );
      final response = _selectedRow?.timesheet.id == null
          ? await _projectService.createTimesheet(projectId, model)
          : await _projectService.updateTimesheet(
              _selectedRow!.timesheet.id!,
              model,
            );
      if (!mounted) return;
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(
        selectId: response.data?.id ?? _selectedRow?.timesheet.id,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTimesheet() async {
    final row = _selectedRow;
    if (row?.timesheet.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timesheet'),
        content: const Text('Remove this timesheet entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await _projectService.deleteTimesheet(
        row!.timesheet.id!,
      );
      if (!mounted) return;
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.schedule_outlined,
        label: 'New Timesheet',
      ),
    ];

    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading project timesheets...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project timesheets',
        message: _pageError!,
        onRetry: _loadData,
      );
    }
    final content = SettingsWorkspace(
      controller: _workspaceController,
      title: 'Project Timesheets',
      editorTitle: _selectedRow == null
          ? null
          : _employeeName(_selectedRow!.timesheet.employeeId),
      scrollController: _pageScrollController,
      list: SettingsListCard<_ProjectTimesheetRow>(
        searchController: _searchController,
        searchHint: 'Search timesheets',
        items: _filteredRows,
        selectedItem: _selectedRow,
        emptyMessage: 'No timesheets found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: _employeeName(row.timesheet.employeeId).isNotEmpty
              ? _employeeName(row.timesheet.employeeId)
              : 'Timesheet',
          subtitle: [
            row.project.projectName ?? '',
            row.timesheet.workDate ?? '',
            row.timesheet.timesheetStatus ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          onTap: () => _selectRow(row),
        ),
      ),
      editor: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
                AppDropdownField<int>.fromMapped(
                  initialValue: _projectId,
                  labelText: 'Project',
                  mappedItems: _projectItems,
                  onChanged: (value) => setState(() {
                    _projectId = value;
                    _taskId = null;
                  }),
                  validator: Validators.requiredSelection('Project'),
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: _taskId,
                  labelText: 'Task',
                  mappedItems: _taskItems,
                  onChanged: (value) => setState(() => _taskId = value),
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: _employeeId,
                  labelText: 'Employee',
                  mappedItems: _employeeItems,
                  onChanged: (value) => setState(() => _employeeId = value),
                  validator: Validators.requiredSelection('Employee'),
                ),
                AppFormTextField(
                  controller: _workDateController,
                  labelText: 'Work Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Work Date'),
                    Validators.optionalDate('Work Date'),
                  ]),
                ),
                AppFormTextField(
                  controller: _hoursWorkedController,
                  labelText: 'Hours Worked',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Hours Worked'),
                    Validators.optionalNonNegativeNumber('Hours Worked'),
                  ]),
                ),
                AppFormTextField(
                  controller: _hourlyCostController,
                  labelText: 'Hourly Cost',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Hourly Cost',
                  ),
                ),
                AppFormTextField(
                  controller: _billableRateController,
                  labelText: 'Billable Rate',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Billable Rate',
                  ),
                ),
                AppFormTextField(
                  controller: _costAmountController,
                  labelText: 'Cost Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Cost Amount',
                  ),
                ),
                AppFormTextField(
                  controller: _billableAmountController,
                  labelText: 'Billable Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Billable Amount',
                  ),
                ),
                AppFormTextField(
                  controller: _voucherIdController,
                  labelText: 'Voucher ID',
                  keyboardType: TextInputType.number,
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: _status,
                  labelText: 'Status',
                  mappedItems: _statusItems,
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppFormTextField(
              controller: _notesController,
              labelText: 'Notes',
              maxLines: 3,
            ),
            if ((_formError ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  onPressed: _saving ? null : _saveTimesheet,
                  icon: _selectedRow?.timesheet.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: _saving ? 'Saving...' : 'Save Timesheet',
                  busy: _saving,
                ),
                AppActionButton(
                  onPressed: _saving ? null : _resetForm,
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (_selectedRow?.timesheet.id != null)
                  AppActionButton(
                    onPressed: _saving ? null : _deleteTimesheet,
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Project Timesheets',
      actions: actions,
      scrollController: _pageScrollController,
      child: content,
    );
  }
}

class _ProjectTimesheetRow {
  const _ProjectTimesheetRow({required this.project, required this.timesheet});

  final ProjectModel project;
  final ProjectTimesheetModel timesheet;
}
