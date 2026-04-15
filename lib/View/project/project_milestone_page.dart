import '../../screen.dart';

class ProjectMilestoneManagementPage extends StatefulWidget {
  const ProjectMilestoneManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectMilestoneManagementPage> createState() =>
      _ProjectMilestoneManagementPageState();
}

class _ProjectMilestoneManagementPageState
    extends State<ProjectMilestoneManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final ProjectService _projectService = ProjectService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetDateController = TextEditingController();
  final TextEditingController _completionDateController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  int? _projectId;
  String _status = 'open';

  List<ProjectModel> _projects = const <ProjectModel>[];
  List<_ProjectMilestoneRow> _rows = const <_ProjectMilestoneRow>[];
  List<_ProjectMilestoneRow> _filteredRows = const <_ProjectMilestoneRow>[];
  _ProjectMilestoneRow? _selectedRow;

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
    _nameController.dispose();
    _targetDateController.dispose();
    _completionDateController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
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
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);
      final projects =
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
          ? projects
          : projects
                .where((item) => item.companyId == contextSelection.companyId)
                .toList();
      final rows = scopedProjects
          .expand(
            (project) => project.milestones.map(
              (milestone) =>
                  _ProjectMilestoneRow(project: project, milestone: milestone),
            ),
          )
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _projects = scopedProjects;
        _rows = rows;
        _filteredRows = _filterRows(rows, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId == null
          ? null
          : rows.cast<_ProjectMilestoneRow?>().firstWhere(
              (item) => item?.milestone.id == selectId,
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
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  List<_ProjectMilestoneRow> _filterRows(
    List<_ProjectMilestoneRow> rows,
    String query,
  ) {
    return filterMasterList(rows, query, (row) {
      return [
        row.milestone.milestoneName ?? '',
        row.project.projectName ?? '',
        row.milestone.milestoneStatus ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredRows = _filterRows(_rows, _searchController.text);
    });
  }

  void _selectRow(_ProjectMilestoneRow row) {
    _selectedRow = row;
    _projectId = row.project.id;
    _nameController.text = row.milestone.milestoneName ?? '';
    _targetDateController.text = row.milestone.targetDate ?? '';
    _completionDateController.text = row.milestone.completionDate ?? '';
    _amountController.text = _decimalText(row.milestone.milestoneAmount);
    _remarksController.text = row.milestone.remarks ?? '';
    _status = row.milestone.milestoneStatus ?? 'open';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedRow = null;
    _projectId = _projects.isNotEmpty ? _projects.first.id : null;
    _nameController.clear();
    _targetDateController.clear();
    _completionDateController.clear();
    _amountController.clear();
    _remarksController.clear();
    _status = 'open';
    _formError = null;
    setState(() {});
  }

  Future<void> _saveMilestone() async {
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
      final model = ProjectMilestoneModel(
        id: _selectedRow?.milestone.id,
        projectId: projectId,
        milestoneName: _nameController.text.trim(),
        targetDate: nullIfEmpty(_targetDateController.text),
        completionDate: nullIfEmpty(_completionDateController.text),
        milestoneAmount: _doubleValue(_amountController.text),
        milestoneStatus: _status,
        remarks: nullIfEmpty(_remarksController.text),
      );
      final response = _selectedRow?.milestone.id == null
          ? await _projectService.createMilestone(projectId, model)
          : await _projectService.updateMilestone(
              _selectedRow!.milestone.id!,
              model,
            );
      if (!mounted) return;
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(
        selectId: response.data?.id ?? _selectedRow?.milestone.id,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteMilestone() async {
    final row = _selectedRow;
    if (row?.milestone.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Milestone'),
        content: Text(
          'Remove ${row!.milestone.milestoneName ?? 'this milestone'}?',
        ),
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
      final response = await _projectService.deleteMilestone(
        row!.milestone.id!,
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

  List<AppDropdownItem<int>> get _projectItems => _projects
      .map(
        (item) => AppDropdownItem<int>(
          value: item.id ?? 0,
          label: item.projectName ?? item.projectCode ?? 'Project',
        ),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  double? _doubleValue(String text) => double.tryParse(text.trim());

  String _decimalText(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.flag_outlined,
        label: 'New Milestone',
      ),
    ];

    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading project milestones...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project milestones',
        message: _pageError!,
        onRetry: _loadData,
      );
    }
    final selectedRow = _selectedRow;
    final content = SettingsWorkspace(
      controller: _workspaceController,
      title: 'Project Milestones',
      editorTitle: selectedRow?.milestone.milestoneName,
      scrollController: _pageScrollController,
      list: SettingsListCard<_ProjectMilestoneRow>(
        searchController: _searchController,
        searchHint: 'Search milestones',
        items: _filteredRows,
        selectedItem: _selectedRow,
        emptyMessage: 'No milestones found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.milestone.milestoneName ?? 'Milestone',
          subtitle: [
            row.project.projectName ?? '',
            row.milestone.targetDate ?? '',
            row.milestone.milestoneStatus ?? '',
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
                  onChanged: (value) => setState(() => _projectId = value),
                  validator: Validators.requiredSelection('Project'),
                ),
                AppFormTextField(
                  controller: _nameController,
                  labelText: 'Milestone Name',
                  validator: Validators.compose([
                    Validators.required('Milestone Name'),
                    Validators.optionalMaxLength(255, 'Milestone Name'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: _status,
                  labelText: 'Status',
                  mappedItems: _statusItems,
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
                ),
                AppFormTextField(
                  controller: _targetDateController,
                  labelText: 'Target Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Target Date'),
                ),
                AppFormTextField(
                  controller: _completionDateController,
                  labelText: 'Completion Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDateOnOrAfter(
                    'Completion Date',
                    () => _targetDateController.text,
                    startFieldName: 'Target Date',
                  ),
                ),
                AppFormTextField(
                  controller: _amountController,
                  labelText: 'Milestone Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Milestone Amount',
                  ),
                ),
              ],
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
                  onPressed: _saving ? null : _saveMilestone,
                  icon: _selectedRow?.milestone.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: _saving ? 'Saving...' : 'Save Milestone',
                  busy: _saving,
                ),
                AppActionButton(
                  onPressed: _saving ? null : _resetForm,
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (_selectedRow?.milestone.id != null)
                  AppActionButton(
                    onPressed: _saving ? null : _deleteMilestone,
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
      title: 'Project Milestones',
      actions: actions,
      scrollController: _pageScrollController,
      child: content,
    );
  }
}

class _ProjectMilestoneRow {
  const _ProjectMilestoneRow({required this.project, required this.milestone});

  final ProjectModel project;
  final ProjectMilestoneModel milestone;
}
