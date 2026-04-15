import '../../screen.dart';

class ProjectExpenseManagementPage extends StatefulWidget {
  const ProjectExpenseManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectExpenseManagementPage> createState() =>
      _ProjectExpenseManagementPageState();
}

class _ProjectExpenseManagementPageState
    extends State<ProjectExpenseManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'booked', label: 'Booked'),
      ];

  final ProjectService _projectService = ProjectService();
  final PartiesService _partiesService = PartiesService();
  final PurchaseService _purchaseService = PurchaseService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _expenseDateController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _voucherIdController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  int? _projectId;
  int? _taskId;
  int? _supplierPartyId;
  int? _purchaseInvoiceId;
  String _status = 'draft';

  List<ProjectModel> _projects = const <ProjectModel>[];
  List<PartyModel> _parties = const <PartyModel>[];
  List<PurchaseInvoiceModel> _purchaseInvoices = const <PurchaseInvoiceModel>[];
  List<_ProjectExpenseRow> _rows = const <_ProjectExpenseRow>[];
  List<_ProjectExpenseRow> _filteredRows = const <_ProjectExpenseRow>[];
  _ProjectExpenseRow? _selectedRow;

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
    _expenseDateController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
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
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'display_name'},
        ),
        _purchaseService.invoices(
          filters: const {'per_page': 300, 'sort_by': 'invoice_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);
      final projects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
      final parties =
          (responses[1] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];
      final purchaseInvoices =
          (responses[2] as PaginatedResponse<PurchaseInvoiceModel>).data ??
          const <PurchaseInvoiceModel>[];
      final companies =
          (responses[3] as PaginatedResponse<CompanyModel>).data ??
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
            (project) => project.expenses.map(
              (expense) =>
                  _ProjectExpenseRow(project: project, expense: expense),
            ),
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _projects = scopedProjects;
        _parties = parties.where((item) => item.isActive).toList();
        _purchaseInvoices = purchaseInvoices;
        _rows = rows;
        _filteredRows = _filterRows(rows, _searchController.text);
        _initialLoading = false;
      });
      final selected = selectId == null
          ? null
          : rows.cast<_ProjectExpenseRow?>().firstWhere(
              (item) => item?.expense.id == selectId,
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

  List<_ProjectExpenseRow> _filterRows(
    List<_ProjectExpenseRow> rows,
    String query,
  ) {
    return filterMasterList(rows, query, (row) {
      return [
        row.expense.expenseCategory ?? '',
        row.project.projectName ?? '',
        row.expense.expenseDate ?? '',
        row.expense.expenseStatus ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredRows = _filterRows(_rows, _searchController.text);
    });
  }

  void _selectRow(_ProjectExpenseRow row) {
    _selectedRow = row;
    _projectId = row.project.id;
    _taskId = row.expense.projectTaskId;
    _supplierPartyId = row.expense.supplierPartyId;
    _purchaseInvoiceId = row.expense.purchaseInvoiceId;
    _expenseDateController.text = row.expense.expenseDate ?? '';
    _categoryController.text = row.expense.expenseCategory ?? '';
    _descriptionController.text = row.expense.description ?? '';
    _amountController.text = _decimalText(row.expense.amount);
    _voucherIdController.text = row.expense.voucherId?.toString() ?? '';
    _remarksController.text = row.expense.remarks ?? '';
    _status = row.expense.expenseStatus ?? 'draft';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedRow = null;
    _projectId = _projects.isNotEmpty ? _projects.first.id : null;
    _taskId = null;
    _supplierPartyId = null;
    _purchaseInvoiceId = null;
    _expenseDateController.clear();
    _categoryController.clear();
    _descriptionController.clear();
    _amountController.clear();
    _voucherIdController.clear();
    _remarksController.clear();
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

  List<AppDropdownItem<int>> get _partyItems => _parties
      .map(
        (item) =>
            AppDropdownItem<int>(value: item.id ?? 0, label: item.toString()),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get _purchaseInvoiceItems => _purchaseInvoices
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
  int? _intValue(String text) => int.tryParse(text.trim());
  String _decimalText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());

  Future<void> _saveExpense() async {
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
      final model = ProjectExpenseModel(
        id: _selectedRow?.expense.id,
        projectId: projectId,
        projectTaskId: _taskId,
        expenseDate: _expenseDateController.text.trim(),
        expenseCategory: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        supplierPartyId: _supplierPartyId,
        purchaseInvoiceId: _purchaseInvoiceId,
        amount: _doubleValue(_amountController.text),
        voucherId: _intValue(_voucherIdController.text),
        expenseStatus: _status,
        remarks: nullIfEmpty(_remarksController.text),
      );
      final response = _selectedRow?.expense.id == null
          ? await _projectService.createExpense(projectId, model)
          : await _projectService.updateExpense(
              _selectedRow!.expense.id!,
              model,
            );
      if (!mounted) return;
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: response.data?.id ?? _selectedRow?.expense.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteExpense() async {
    final row = _selectedRow;
    if (row?.expense.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Remove this expense entry?'),
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
      final response = await _projectService.deleteExpense(row!.expense.id!);
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
        icon: Icons.receipt_long_outlined,
        label: 'New Expense',
      ),
    ];

    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading project expenses...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project expenses',
        message: _pageError!,
        onRetry: _loadData,
      );
    }
    final selectedRow = _selectedRow;
    final content = SettingsWorkspace(
      controller: _workspaceController,
      title: 'Project Expenses',
      editorTitle: selectedRow?.expense.expenseCategory,
      scrollController: _pageScrollController,
      list: SettingsListCard<_ProjectExpenseRow>(
        searchController: _searchController,
        searchHint: 'Search expenses',
        items: _filteredRows,
        selectedItem: _selectedRow,
        emptyMessage: 'No expenses found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.expense.expenseCategory ?? 'Expense',
          subtitle: [
            row.project.projectName ?? '',
            row.expense.expenseDate ?? '',
            row.expense.expenseStatus ?? '',
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
                AppFormTextField(
                  controller: _expenseDateController,
                  labelText: 'Expense Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Expense Date'),
                    Validators.optionalDate('Expense Date'),
                  ]),
                ),
                AppFormTextField(
                  controller: _categoryController,
                  labelText: 'Expense Category',
                  validator: Validators.compose([
                    Validators.required('Expense Category'),
                    Validators.optionalMaxLength(100, 'Expense Category'),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: _supplierPartyId,
                  labelText: 'Supplier',
                  mappedItems: _partyItems,
                  onChanged: (value) =>
                      setState(() => _supplierPartyId = value),
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: _purchaseInvoiceId,
                  labelText: 'Purchase Invoice',
                  mappedItems: _purchaseInvoiceItems,
                  onChanged: (value) =>
                      setState(() => _purchaseInvoiceId = value),
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: _status,
                  labelText: 'Status',
                  mappedItems: _statusItems,
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
                ),
                AppFormTextField(
                  controller: _amountController,
                  labelText: 'Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Amount'),
                    Validators.optionalNonNegativeNumber('Amount'),
                  ]),
                ),
                AppFormTextField(
                  controller: _voucherIdController,
                  labelText: 'Voucher ID',
                  keyboardType: TextInputType.number,
                ),
                AppFormTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  maxLines: 3,
                  validator: Validators.compose([
                    Validators.required('Description'),
                    Validators.optionalMaxLength(500, 'Description'),
                  ]),
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
                  onPressed: _saving ? null : _saveExpense,
                  icon: _selectedRow?.expense.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: _saving ? 'Saving...' : 'Save Expense',
                  busy: _saving,
                ),
                AppActionButton(
                  onPressed: _saving ? null : _resetForm,
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (_selectedRow?.expense.id != null)
                  AppActionButton(
                    onPressed: _saving ? null : _deleteExpense,
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
      title: 'Project Expenses',
      actions: actions,
      scrollController: _pageScrollController,
      child: content,
    );
  }
}

class _ProjectExpenseRow {
  const _ProjectExpenseRow({required this.project, required this.expense});

  final ProjectModel project;
  final ProjectExpenseModel expense;
}
