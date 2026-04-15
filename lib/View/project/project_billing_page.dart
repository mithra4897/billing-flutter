import '../../screen.dart';

class ProjectBillingManagementPage extends StatefulWidget {
  const ProjectBillingManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectBillingManagementPage> createState() =>
      _ProjectBillingManagementPageState();
}

class _ProjectBillingManagementPageState
    extends State<ProjectBillingManagementPage> {
  static const List<AppDropdownItem<String>> _basisItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'milestone', label: 'Milestone'),
        AppDropdownItem(value: 'timesheet', label: 'Timesheet'),
        AppDropdownItem(value: 'fixed', label: 'Fixed'),
        AppDropdownItem(value: 'cost_plus', label: 'Cost Plus'),
      ];

  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'invoiced', label: 'Invoiced'),
        AppDropdownItem(value: 'paid', label: 'Paid'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final ProjectService _projectService = ProjectService();
  final SalesService _salesService = SalesService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _billingDateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  int? _projectId;
  int? _milestoneId;
  int? _salesInvoiceId;
  String _basis = 'fixed';
  String _status = 'draft';

  List<ProjectModel> _projects = const <ProjectModel>[];
  List<SalesInvoiceModel> _salesInvoices = const <SalesInvoiceModel>[];
  List<_ProjectBillingRow> _rows = const <_ProjectBillingRow>[];
  List<_ProjectBillingRow> _filteredRows = const <_ProjectBillingRow>[];
  _ProjectBillingRow? _selectedRow;

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
    _billingDateController.dispose();
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
        _salesService.invoices(
          filters: const {'per_page': 300, 'sort_by': 'invoice_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);
      final projects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
      final salesInvoices =
          (responses[1] as PaginatedResponse<SalesInvoiceModel>).data ??
          const <SalesInvoiceModel>[];
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
            (project) => project.billings.map(
              (billing) =>
                  _ProjectBillingRow(project: project, billing: billing),
            ),
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _projects = scopedProjects;
        _salesInvoices = salesInvoices;
        _rows = rows;
        _filteredRows = _filterRows(rows, _searchController.text);
        _initialLoading = false;
      });
      final selected = selectId == null
          ? null
          : rows.cast<_ProjectBillingRow?>().firstWhere(
              (item) => item?.billing.id == selectId,
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

  List<_ProjectBillingRow> _filterRows(
    List<_ProjectBillingRow> rows,
    String query,
  ) {
    return filterMasterList(rows, query, (row) {
      return [
        row.project.projectName ?? '',
        row.billing.billingDate ?? '',
        row.billing.billingBasis ?? '',
        row.billing.billingStatus ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredRows = _filterRows(_rows, _searchController.text);
    });
  }

  void _selectRow(_ProjectBillingRow row) {
    _selectedRow = row;
    _projectId = row.project.id;
    _milestoneId = row.billing.projectMilestoneId;
    _salesInvoiceId = row.billing.salesInvoiceId;
    _billingDateController.text = row.billing.billingDate ?? '';
    _amountController.text = _decimalText(row.billing.billingAmount);
    _remarksController.text = row.billing.remarks ?? '';
    _basis = row.billing.billingBasis ?? 'fixed';
    _status = row.billing.billingStatus ?? 'draft';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedRow = null;
    _projectId = _projects.isNotEmpty ? _projects.first.id : null;
    _milestoneId = null;
    _salesInvoiceId = null;
    _billingDateController.clear();
    _amountController.clear();
    _remarksController.clear();
    _basis = 'fixed';
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

  List<AppDropdownItem<int>> get _milestoneItems {
    final project = _projects.cast<ProjectModel?>().firstWhere(
      (item) => item?.id == _projectId,
      orElse: () => null,
    );
    return (project?.milestones ?? const <ProjectMilestoneModel>[])
        .map(
          (item) => AppDropdownItem<int>(
            value: item.id ?? 0,
            label: item.milestoneName ?? 'Milestone',
          ),
        )
        .where((item) => item.value != 0)
        .toList(growable: false);
  }

  List<AppDropdownItem<int>> get _salesInvoiceItems => _salesInvoices
      .map(
        (item) => AppDropdownItem<int>(
          value: item.id,
          label: item.invoiceNo?.trim().isNotEmpty == true
              ? item.invoiceNo!
              : 'Invoice #${item.id}',
        ),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  double? _doubleValue(String text) => double.tryParse(text.trim());
  String _decimalText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());

  Future<void> _saveBilling() async {
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
      final model = ProjectBillingModel(
        id: _selectedRow?.billing.id,
        projectId: projectId,
        projectMilestoneId: _milestoneId,
        billingDate: _billingDateController.text.trim(),
        billingBasis: _basis,
        billingAmount: _doubleValue(_amountController.text),
        salesInvoiceId: _salesInvoiceId,
        billingStatus: _status,
        remarks: nullIfEmpty(_remarksController.text),
      );
      final response = _selectedRow?.billing.id == null
          ? await _projectService.createBilling(projectId, model)
          : await _projectService.updateBilling(
              _selectedRow!.billing.id!,
              model,
            );
      if (!mounted) return;
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: response.data?.id ?? _selectedRow?.billing.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteBilling() async {
    final row = _selectedRow;
    if (row?.billing.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Billing'),
        content: const Text('Remove this billing entry?'),
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
      final response = await _projectService.deleteBilling(row!.billing.id!);
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
        icon: Icons.request_quote_outlined,
        label: 'New Billing',
      ),
    ];

    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading project billings...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project billings',
        message: _pageError!,
        onRetry: _loadData,
      );
    }
    final selectedRow = _selectedRow;
    final content = SettingsWorkspace(
      controller: _workspaceController,
      title: 'Project Billings',
      editorTitle: selectedRow?.project.projectName,
      scrollController: _pageScrollController,
      list: SettingsListCard<_ProjectBillingRow>(
        searchController: _searchController,
        searchHint: 'Search billings',
        items: _filteredRows,
        selectedItem: _selectedRow,
        emptyMessage: 'No billings found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.project.projectName ?? 'Billing',
          subtitle: [
            row.billing.billingDate ?? '',
            row.billing.billingBasis ?? '',
            row.billing.billingStatus ?? '',
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
                    _milestoneId = null;
                  }),
                  validator: Validators.requiredSelection('Project'),
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: _milestoneId,
                  labelText: 'Milestone',
                  mappedItems: _milestoneItems,
                  onChanged: (value) => setState(() => _milestoneId = value),
                ),
                AppFormTextField(
                  controller: _billingDateController,
                  labelText: 'Billing Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Billing Date'),
                    Validators.optionalDate('Billing Date'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: _basis,
                  labelText: 'Billing Basis',
                  mappedItems: _basisItems,
                  onChanged: (value) =>
                      setState(() => _basis = value ?? _basis),
                ),
                AppFormTextField(
                  controller: _amountController,
                  labelText: 'Billing Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Billing Amount'),
                    Validators.optionalNonNegativeNumber('Billing Amount'),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: _salesInvoiceId,
                  labelText: 'Sales Invoice',
                  mappedItems: _salesInvoiceItems,
                  onChanged: (value) => setState(() => _salesInvoiceId = value),
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: _status,
                  labelText: 'Billing Status',
                  mappedItems: _statusItems,
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
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
                  onPressed: _saving ? null : _saveBilling,
                  icon: _selectedRow?.billing.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: _saving ? 'Saving...' : 'Save Billing',
                  busy: _saving,
                ),
                AppActionButton(
                  onPressed: _saving ? null : _resetForm,
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (_selectedRow?.billing.id != null)
                  AppActionButton(
                    onPressed: _saving ? null : _deleteBilling,
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
      title: 'Project Billings',
      actions: actions,
      scrollController: _pageScrollController,
      child: content,
    );
  }
}

class _ProjectBillingRow {
  const _ProjectBillingRow({required this.project, required this.billing});

  final ProjectModel project;
  final ProjectBillingModel billing;
}
