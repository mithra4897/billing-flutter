import '../../screen.dart';

class ProjectTaskManagementPage extends StatefulWidget {
  const ProjectTaskManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectTaskManagementPage> createState() =>
      _ProjectTaskManagementPageState();
}

class _ProjectTaskManagementPageState extends State<ProjectTaskManagementPage> {
  static const List<AppDropdownItem<String>> _taskStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'working', label: 'Working'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
        AppDropdownItem(value: 'on_hold', label: 'On Hold'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final ProjectService _projectService = ProjectService();
  final HrService _hrService = HrService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _taskCodeController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _plannedStartDateController =
      TextEditingController();
  final TextEditingController _plannedEndDateController =
      TextEditingController();
  final TextEditingController _actualStartDateController =
      TextEditingController();
  final TextEditingController _actualEndDateController =
      TextEditingController();
  final TextEditingController _estimatedHoursController =
      TextEditingController();
  final TextEditingController _actualHoursController = TextEditingController();
  final TextEditingController _estimatedCostController =
      TextEditingController();
  final TextEditingController _actualCostController = TextEditingController();
  final TextEditingController _progressPercentController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  bool _loadingTaskCode = false;
  bool _suppressTaskCodeListener = false;
  bool _taskCodeManuallyEdited = false;
  String? _pageError;
  String? _formError;
  int? _projectId;
  int? _assignedEmployeeId;
  String _taskStatus = 'open';
  bool _isBillable = true;

  List<ProjectModel> _projects = const <ProjectModel>[];
  List<EmployeeModel> _employees = const <EmployeeModel>[];
  List<_ProjectTaskRow> _rows = const <_ProjectTaskRow>[];
  List<_ProjectTaskRow> _filteredRows = const <_ProjectTaskRow>[];
  _ProjectTaskRow? _selectedRow;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _taskCodeController.addListener(_handleTaskCodeChanged);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _taskCodeController.dispose();
    _taskNameController.dispose();
    _descriptionController.dispose();
    _plannedStartDateController.dispose();
    _plannedEndDateController.dispose();
    _actualStartDateController.dispose();
    _actualEndDateController.dispose();
    _estimatedHoursController.dispose();
    _actualHoursController.dispose();
    _estimatedCostController.dispose();
    _actualCostController.dispose();
    _progressPercentController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectTaskId}) async {
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
            (project) => project.tasks.map(
              (task) => _ProjectTaskRow(project: project, task: task),
            ),
          )
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _projects = scopedProjects;
        _employees = employees
            .where((item) => item.status == 'active')
            .toList();
        _rows = rows;
        _filteredRows = _filterRows(rows, _searchController.text);
        _initialLoading = false;
      });

      if (selectTaskId != null) {
        final selected = rows.cast<_ProjectTaskRow?>().firstWhere(
          (item) => item?.task.id == selectTaskId,
          orElse: () => null,
        );
        if (selected != null) {
          _selectRow(selected);
          return;
        }
      }

      if (_selectedRow != null) {
        final selected = rows.cast<_ProjectTaskRow?>().firstWhere(
          (item) => item?.task.id == _selectedRow?.task.id,
          orElse: () => null,
        );
        if (selected != null) {
          _selectRow(selected);
          return;
        }
      }

      if (_filteredRows.isNotEmpty) {
        _selectRow(_filteredRows.first);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _filteredRows = _filterRows(_rows, _searchController.text);
    });
  }

  List<_ProjectTaskRow> _filterRows(List<_ProjectTaskRow> rows, String query) {
    return filterMasterList(rows, query, (row) {
      return [
        row.task.taskCode ?? '',
        row.task.taskName ?? '',
        row.project.projectName ?? '',
        _employeeName(row.task.assignedEmployeeId),
        row.task.taskStatus ?? '',
      ];
    });
  }

  void _selectRow(_ProjectTaskRow row) {
    _selectedRow = row;
    _projectId = row.project.id;
    _setTaskCode(row.task.taskCode ?? '', autoGenerated: false);
    _taskNameController.text = row.task.taskName ?? '';
    _descriptionController.text = row.task.description ?? '';
    _plannedStartDateController.text = row.task.plannedStartDate ?? '';
    _plannedEndDateController.text = row.task.plannedEndDate ?? '';
    _actualStartDateController.text = row.task.actualStartDate ?? '';
    _actualEndDateController.text = row.task.actualEndDate ?? '';
    _estimatedHoursController.text = _decimalText(row.task.estimatedHours);
    _actualHoursController.text = _decimalText(row.task.actualHours);
    _estimatedCostController.text = _decimalText(row.task.estimatedCost);
    _actualCostController.text = _decimalText(row.task.actualCost);
    _progressPercentController.text = _decimalText(row.task.progressPercent);
    _remarksController.text = row.task.remarks ?? '';
    _assignedEmployeeId = row.task.assignedEmployeeId;
    _taskStatus = row.task.taskStatus ?? 'open';
    _isBillable = row.task.isBillable ?? true;
    _loadingTaskCode = false;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedRow = null;
    _projectId = _projects.isNotEmpty ? _projects.first.id : null;
    _setTaskCode('', autoGenerated: true);
    _taskNameController.clear();
    _descriptionController.clear();
    _plannedStartDateController.clear();
    _plannedEndDateController.clear();
    _actualStartDateController.clear();
    _actualEndDateController.clear();
    _estimatedHoursController.clear();
    _actualHoursController.clear();
    _estimatedCostController.clear();
    _actualCostController.clear();
    _progressPercentController.clear();
    _remarksController.clear();
    _assignedEmployeeId = null;
    _taskStatus = 'open';
    _isBillable = true;
    _loadingTaskCode = false;
    _formError = null;
    _taskCodeManuallyEdited = false;
    setState(() {});
    _primeTaskCodeSuggestion();
  }

  bool get _isNewTask => _selectedRow?.task.id == null;

  void _handleTaskCodeChanged() {
    if (_suppressTaskCodeListener || !_isNewTask) {
      return;
    }

    _taskCodeManuallyEdited = _taskCodeController.text.trim().isNotEmpty;
  }

  void _setTaskCode(String value, {required bool autoGenerated}) {
    _suppressTaskCodeListener = true;
    _taskCodeController.value = _taskCodeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _suppressTaskCodeListener = false;
    _taskCodeManuallyEdited = !autoGenerated && value.trim().isNotEmpty;
  }

  Future<void> _primeTaskCodeSuggestion() async {
    final projectId = _projectId;
    if (!_isNewTask || _taskCodeManuallyEdited || projectId == null) {
      return;
    }

    setState(() => _loadingTaskCode = true);
    try {
      final code = await _projectService.nextTaskCode(projectId: projectId);
      if (!mounted ||
          !_isNewTask ||
          _taskCodeManuallyEdited ||
          projectId != _projectId) {
        return;
      }
      final trimmed = (code ?? '').trim();
      if (trimmed.isEmpty) {
        return;
      }
      _setTaskCode(trimmed, autoGenerated: true);
      setState(() {});
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingTaskCode = false);
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final projectId = _projectId;
    if (projectId == null) {
      setState(() {
        _formError = 'Project is required.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      final model = ProjectTaskModel(
        id: _selectedRow?.task.id,
        projectId: projectId,
        taskCode: nullIfEmpty(_taskCodeController.text),
        taskName: _taskNameController.text.trim(),
        description: nullIfEmpty(_descriptionController.text),
        assignedEmployeeId: _assignedEmployeeId,
        plannedStartDate: nullIfEmpty(_plannedStartDateController.text),
        plannedEndDate: nullIfEmpty(_plannedEndDateController.text),
        actualStartDate: nullIfEmpty(_actualStartDateController.text),
        actualEndDate: nullIfEmpty(_actualEndDateController.text),
        estimatedHours: _doubleValue(_estimatedHoursController.text),
        actualHours: _doubleValue(_actualHoursController.text),
        estimatedCost: _doubleValue(_estimatedCostController.text),
        actualCost: _doubleValue(_actualCostController.text),
        progressPercent: _doubleValue(_progressPercentController.text),
        taskStatus: _taskStatus,
        isBillable: _isBillable,
        remarks: nullIfEmpty(_remarksController.text),
      );

      final response = _selectedRow?.task.id == null
          ? await _projectService.createTask(projectId, model)
          : await _projectService.updateTask(_selectedRow!.task.id!, model);
      if (!mounted) {
        return;
      }
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectTaskId: response.data?.id ?? _selectedRow?.task.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteTask() async {
    final row = _selectedRow;
    if (row?.task.id == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Remove ${row!.task.taskName ?? 'this task'}?'),
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
    if (confirmed != true) {
      return;
    }
    try {
      final response = await _projectService.deleteTask(row!.task.id!);
      if (!mounted) {
        return;
      }
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _formError = error.toString();
      });
    }
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

  String _employeeName(int? id) {
    return _employees
            .cast<EmployeeModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.toString() ??
        '';
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

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.add_task_outlined,
        label: 'New Task',
      ),
    ];

    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading project tasks...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project tasks',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    final selectedRow = _selectedRow;
    final content = SettingsWorkspace(
      controller: _workspaceController,
      title: 'Project Tasks',
      editorTitle: selectedRow == null
          ? null
          : (selectedRow.task.taskName ?? selectedRow.task.taskCode),
      scrollController: _pageScrollController,
      list: SettingsListCard<_ProjectTaskRow>(
        searchController: _searchController,
        searchHint: 'Search tasks',
        items: _filteredRows,
        selectedItem: _selectedRow,
        emptyMessage: 'No tasks found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.task.taskName ?? 'Task',
          subtitle: [
            row.task.taskCode ?? '',
            row.project.projectName ?? '',
            row.task.taskStatus ?? '',
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
                  onChanged: (value) {
                    setState(() => _projectId = value);
                    _primeTaskCodeSuggestion();
                  },
                  validator: Validators.requiredSelection('Project'),
                ),
                AppFormTextField(
                  controller: _taskCodeController,
                  labelText: 'Task Code',
                  suffixIcon: _loadingTaskCode
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  validator: Validators.optionalMaxLength(100, 'Task Code'),
                ),
                AppFormTextField(
                  controller: _taskNameController,
                  labelText: 'Task Name',
                  validator: Validators.compose([
                    Validators.required('Task Name'),
                    Validators.optionalMaxLength(255, 'Task Name'),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: _assignedEmployeeId,
                  labelText: 'Assigned Employee',
                  mappedItems: _employeeItems,
                  onChanged: (value) =>
                      setState(() => _assignedEmployeeId = value),
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: _taskStatus,
                  labelText: 'Task Status',
                  mappedItems: _taskStatusItems,
                  onChanged: (value) =>
                      setState(() => _taskStatus = value ?? _taskStatus),
                ),
                AppFormTextField(
                  controller: _plannedStartDateController,
                  labelText: 'Planned Start Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Planned Start Date'),
                ),
                AppFormTextField(
                  controller: _plannedEndDateController,
                  labelText: 'Planned End Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDateOnOrAfter(
                    'Planned End Date',
                    () => _plannedStartDateController.text,
                    startFieldName: 'Planned Start Date',
                  ),
                ),
                AppFormTextField(
                  controller: _actualStartDateController,
                  labelText: 'Actual Start Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Actual Start Date'),
                ),
                AppFormTextField(
                  controller: _actualEndDateController,
                  labelText: 'Actual End Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDateOnOrAfter(
                    'Actual End Date',
                    () => _actualStartDateController.text,
                    startFieldName: 'Actual Start Date',
                  ),
                ),
                AppFormTextField(
                  controller: _estimatedHoursController,
                  labelText: 'Estimated Hours',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Estimated Hours',
                  ),
                ),
                AppFormTextField(
                  controller: _actualHoursController,
                  labelText: 'Actual Hours',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Actual Hours',
                  ),
                ),
                AppFormTextField(
                  controller: _estimatedCostController,
                  labelText: 'Estimated Cost',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Estimated Cost',
                  ),
                ),
                AppFormTextField(
                  controller: _actualCostController,
                  labelText: 'Actual Cost',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Actual Cost',
                  ),
                ),
                AppFormTextField(
                  controller: _progressPercentController,
                  labelText: 'Progress Percent',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Progress Percent',
                  ),
                ),
                AppFormTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppSwitchTile(
              label: 'Billable',
              subtitle: 'Use this task for billable work if needed.',
              value: _isBillable,
              onChanged: (value) => setState(() => _isBillable = value),
            ),
            const SizedBox(height: 8),
            AppFormTextField(
              controller: _remarksController,
              labelText: 'Remarks',
              maxLines: 3,
              validator: Validators.optionalMaxLength(500, 'Remarks'),
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
                  onPressed: _saving ? null : _saveTask,
                  icon: _selectedRow?.task.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: _saving ? 'Saving...' : 'Save Task',
                  busy: _saving,
                ),
                AppActionButton(
                  onPressed: _saving ? null : _resetForm,
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (_selectedRow?.task.id != null)
                  AppActionButton(
                    onPressed: _saving ? null : _deleteTask,
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
      title: 'Project Tasks',
      actions: actions,
      scrollController: _pageScrollController,
      child: content,
    );
  }
}

class _ProjectTaskRow {
  const _ProjectTaskRow({required this.project, required this.task});

  final ProjectModel project;
  final ProjectTaskModel task;
}
