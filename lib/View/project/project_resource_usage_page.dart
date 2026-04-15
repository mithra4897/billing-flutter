import '../../screen.dart';

class ProjectResourceUsageManagementPage extends StatefulWidget {
  const ProjectResourceUsageManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectResourceUsageManagementPage> createState() =>
      _ProjectResourceUsageManagementPageState();
}

class _ProjectResourceUsageManagementPageState
    extends State<ProjectResourceUsageManagementPage> {
  final ProjectService _projectService = ProjectService();
  final AssetsService _assetsService = AssetsService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _resourceNameController = TextEditingController();
  final TextEditingController _usageDateController = TextEditingController();
  final TextEditingController _usageHoursController = TextEditingController();
  final TextEditingController _usageQtyController = TextEditingController();
  final TextEditingController _unitCostController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _voucherIdController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  int? _projectId;
  int? _taskId;
  int? _assetId;

  List<ProjectModel> _projects = const <ProjectModel>[];
  List<AssetModel> _assets = const <AssetModel>[];
  List<_ProjectResourceUsageRow> _rows = const <_ProjectResourceUsageRow>[];
  List<_ProjectResourceUsageRow> _filteredRows =
      const <_ProjectResourceUsageRow>[];
  _ProjectResourceUsageRow? _selectedRow;

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
    _resourceNameController.dispose();
    _usageDateController.dispose();
    _usageHoursController.dispose();
    _usageQtyController.dispose();
    _unitCostController.dispose();
    _totalCostController.dispose();
    _voucherIdController.dispose();
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
        _assetsService.assets(
          filters: const {'per_page': 300, 'sort_by': 'asset_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);
      final projects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
      final assets =
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
      final scopedProjects = contextSelection.companyId == null
          ? projects
          : projects
                .where((item) => item.companyId == contextSelection.companyId)
                .toList();
      final rows = scopedProjects
          .expand(
            (project) => project.resourceUsages.map(
              (usage) =>
                  _ProjectResourceUsageRow(project: project, usage: usage),
            ),
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _projects = scopedProjects;
        _assets = assets;
        _rows = rows;
        _filteredRows = _filterRows(rows, _searchController.text);
        _initialLoading = false;
      });
      final selected = selectId == null
          ? null
          : rows.cast<_ProjectResourceUsageRow?>().firstWhere(
              (item) => item?.usage.id == selectId,
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

  List<_ProjectResourceUsageRow> _filterRows(
    List<_ProjectResourceUsageRow> rows,
    String query,
  ) {
    return filterMasterList(rows, query, (row) {
      return [
        row.usage.resourceName ?? '',
        row.project.projectName ?? '',
        row.usage.usageDate ?? '',
        _assetLabel(_assetById(row.usage.assetId)),
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredRows = _filterRows(_rows, _searchController.text);
    });
  }

  void _selectRow(_ProjectResourceUsageRow row) {
    _selectedRow = row;
    _projectId = row.project.id;
    _taskId = row.usage.projectTaskId;
    _assetId = row.usage.assetId;
    _resourceNameController.text = row.usage.resourceName ?? '';
    _usageDateController.text = row.usage.usageDate ?? '';
    _usageHoursController.text = _decimalText(row.usage.usageHours);
    _usageQtyController.text = _decimalText(row.usage.usageQty);
    _unitCostController.text = _decimalText(row.usage.unitCost);
    _totalCostController.text = _decimalText(row.usage.totalCost);
    _voucherIdController.text = row.usage.voucherId?.toString() ?? '';
    _remarksController.text = row.usage.remarks ?? '';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedRow = null;
    _projectId = _projects.isNotEmpty ? _projects.first.id : null;
    _taskId = null;
    _assetId = null;
    _resourceNameController.clear();
    _usageDateController.clear();
    _usageHoursController.clear();
    _usageQtyController.clear();
    _unitCostController.clear();
    _totalCostController.clear();
    _voucherIdController.clear();
    _remarksController.clear();
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

  List<AppDropdownItem<int>> get _assetItems => _assets
      .map(
        (item) => AppDropdownItem<int>(
          value: _rawInt(item.data['id']) ?? 0,
          label: _assetLabel(item),
        ),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  AssetModel? _assetById(int? id) => _assets.cast<AssetModel?>().firstWhere(
    (item) => _rawInt(item?.data['id']) == id,
    orElse: () => null,
  );

  String _assetLabel(AssetModel? asset) {
    if (asset == null) return '';
    final name = asset.data['asset_name']?.toString().trim() ?? '';
    final code = asset.data['asset_code']?.toString().trim() ?? '';
    if (name.isNotEmpty && code.isNotEmpty) return '$name ($code)';
    return name.isNotEmpty ? name : code;
  }

  int? _rawInt(dynamic value) => int.tryParse(value?.toString() ?? '');
  int? _intValue(String text) => int.tryParse(text.trim());
  double? _doubleValue(String text) => double.tryParse(text.trim());
  String _decimalText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());

  Future<void> _saveUsage() async {
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
      final model = ProjectResourceUsageModel(
        id: _selectedRow?.usage.id,
        projectId: projectId,
        projectTaskId: _taskId,
        assetId: _assetId,
        resourceName: _resourceNameController.text.trim(),
        usageDate: _usageDateController.text.trim(),
        usageHours: _doubleValue(_usageHoursController.text),
        usageQty: _doubleValue(_usageQtyController.text),
        unitCost: _doubleValue(_unitCostController.text),
        totalCost: _doubleValue(_totalCostController.text),
        voucherId: _intValue(_voucherIdController.text),
        remarks: nullIfEmpty(_remarksController.text),
      );
      final response = _selectedRow?.usage.id == null
          ? await _projectService.createResourceUsage(projectId, model)
          : await _projectService.updateResourceUsage(
              _selectedRow!.usage.id!,
              model,
            );
      if (!mounted) return;
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: response.data?.id ?? _selectedRow?.usage.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteUsage() async {
    final row = _selectedRow;
    if (row?.usage.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource Usage'),
        content: const Text('Remove this resource usage entry?'),
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
      final response = await _projectService.deleteResourceUsage(
        row!.usage.id!,
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
        icon: Icons.precision_manufacturing_outlined,
        label: 'New Resource Usage',
      ),
    ];

    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading project resource usage...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project resource usage',
        message: _pageError!,
        onRetry: _loadData,
      );
    }
    final selectedRow = _selectedRow;
    final content = SettingsWorkspace(
      controller: _workspaceController,
      title: 'Project Resource Usage',
      editorTitle: selectedRow?.usage.resourceName,
      scrollController: _pageScrollController,
      list: SettingsListCard<_ProjectResourceUsageRow>(
        searchController: _searchController,
        searchHint: 'Search resource usage',
        items: _filteredRows,
        selectedItem: _selectedRow,
        emptyMessage: 'No resource usage found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.usage.resourceName ?? 'Resource Usage',
          subtitle: [
            row.project.projectName ?? '',
            row.usage.usageDate ?? '',
            _assetLabel(_assetById(row.usage.assetId)),
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
                  initialValue: _assetId,
                  labelText: 'Asset',
                  mappedItems: _assetItems,
                  onChanged: (value) => setState(() => _assetId = value),
                ),
                AppFormTextField(
                  controller: _resourceNameController,
                  labelText: 'Resource Name',
                  validator: Validators.compose([
                    Validators.required('Resource Name'),
                    Validators.optionalMaxLength(255, 'Resource Name'),
                  ]),
                ),
                AppFormTextField(
                  controller: _usageDateController,
                  labelText: 'Usage Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Usage Date'),
                    Validators.optionalDate('Usage Date'),
                  ]),
                ),
                AppFormTextField(
                  controller: _usageHoursController,
                  labelText: 'Usage Hours',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Usage Hours',
                  ),
                ),
                AppFormTextField(
                  controller: _usageQtyController,
                  labelText: 'Usage Qty',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber('Usage Qty'),
                ),
                AppFormTextField(
                  controller: _unitCostController,
                  labelText: 'Unit Cost',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Unit Cost'),
                    Validators.optionalNonNegativeNumber('Unit Cost'),
                  ]),
                ),
                AppFormTextField(
                  controller: _totalCostController,
                  labelText: 'Total Cost',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber('Total Cost'),
                ),
                AppFormTextField(
                  controller: _voucherIdController,
                  labelText: 'Voucher ID',
                  keyboardType: TextInputType.number,
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
                  onPressed: _saving ? null : _saveUsage,
                  icon: _selectedRow?.usage.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: _saving ? 'Saving...' : 'Save Resource Usage',
                  busy: _saving,
                ),
                AppActionButton(
                  onPressed: _saving ? null : _resetForm,
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (_selectedRow?.usage.id != null)
                  AppActionButton(
                    onPressed: _saving ? null : _deleteUsage,
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
      title: 'Project Resource Usage',
      actions: actions,
      scrollController: _pageScrollController,
      child: content,
    );
  }
}

class _ProjectResourceUsageRow {
  const _ProjectResourceUsageRow({required this.project, required this.usage});

  final ProjectModel project;
  final ProjectResourceUsageModel usage;
}
