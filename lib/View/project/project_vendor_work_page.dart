import '../../screen.dart';

class ProjectVendorWorkManagementPage extends StatefulWidget {
  const ProjectVendorWorkManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectVendorWorkManagementPage> createState() =>
      _ProjectVendorWorkManagementPageState();
}

class _ProjectVendorWorkManagementPageState
    extends State<ProjectVendorWorkManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'ordered', label: 'Ordered'),
        AppDropdownItem(value: 'in_progress', label: 'In Progress'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
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
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _voucherIdController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  int? _filterProjectId;
  int? _filterTaskId;
  int? _filterVendorPartyId;
  int? _projectId;
  int? _taskId;
  int? _vendorPartyId;
  int? _purchaseOrderId;
  int? _purchaseInvoiceId;
  String _status = 'open';

  List<ProjectModel> _projects = const <ProjectModel>[];
  List<PartyModel> _parties = const <PartyModel>[];
  List<PurchaseOrderModel> _purchaseOrders = const <PurchaseOrderModel>[];
  List<PurchaseInvoiceModel> _purchaseInvoices = const <PurchaseInvoiceModel>[];
  List<_ProjectVendorWorkRow> _rows = const <_ProjectVendorWorkRow>[];
  List<_ProjectVendorWorkRow> _filteredRows = const <_ProjectVendorWorkRow>[];
  _ProjectVendorWorkRow? _selectedRow;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
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
        _purchaseService.orders(
          filters: const {'per_page': 300, 'sort_by': 'order_date'},
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
      final purchaseOrders =
          (responses[2] as PaginatedResponse<PurchaseOrderModel>).data ??
          const <PurchaseOrderModel>[];
      final purchaseInvoices =
          (responses[3] as PaginatedResponse<PurchaseInvoiceModel>).data ??
          const <PurchaseInvoiceModel>[];
      final companies =
          (responses[4] as PaginatedResponse<CompanyModel>).data ??
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
            (project) => project.vendorWorks.map(
              (work) => _ProjectVendorWorkRow(project: project, work: work),
            ),
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _projects = scopedProjects;
        _parties = parties.where((item) => item.isActive).toList();
        _purchaseOrders = purchaseOrders;
        _purchaseInvoices = purchaseInvoices;
        _rows = rows;
        _filteredRows = _filterRows(rows);
        _initialLoading = false;
      });
      final selected = selectId == null
          ? null
          : rows.cast<_ProjectVendorWorkRow?>().firstWhere(
              (item) => item?.work.id == selectId,
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

  List<_ProjectVendorWorkRow> _filterRows(List<_ProjectVendorWorkRow> rows) {
    final scoped = rows.where((row) {
      if (_filterProjectId != null && row.project.id != _filterProjectId) {
        return false;
      }
      if (_filterTaskId != null && row.work.projectTaskId != _filterTaskId) {
        return false;
      }
      if (_filterVendorPartyId != null &&
          row.work.vendorPartyId != _filterVendorPartyId) {
        return false;
      }
      return true;
    }).toList(growable: false);

    return filterMasterList(scoped, _searchController.text, (row) {
      return [
        row.project.projectName ?? '',
        _taskName(row.project, row.work.projectTaskId),
        _partyName(row.work.vendorPartyId),
        row.work.workStatus ?? '',
        row.work.workDescription ?? '',
      ];
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredRows = _filterRows(_rows);
    });
  }

  void _selectRow(_ProjectVendorWorkRow row) {
    _selectedRow = row;
    _projectId = row.project.id;
    _taskId = row.work.projectTaskId;
    _vendorPartyId = row.work.vendorPartyId;
    _purchaseOrderId = row.work.purchaseOrderId;
    _purchaseInvoiceId = row.work.purchaseInvoiceId;
    _descriptionController.text = row.work.workDescription ?? '';
    _amountController.text = _decimalText(row.work.amount);
    _voucherIdController.text = row.work.voucherId?.toString() ?? '';
    _remarksController.text = row.work.remarks ?? '';
    _status = row.work.workStatus ?? 'open';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedRow = null;
    _projectId = _projects.isNotEmpty ? _projects.first.id : null;
    _taskId = null;
    _vendorPartyId = null;
    _purchaseOrderId = null;
    _purchaseInvoiceId = null;
    _descriptionController.clear();
    _amountController.clear();
    _voucherIdController.clear();
    _remarksController.clear();
    _status = 'open';
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

  List<AppDropdownItem<int>> get _purchaseOrderItems => _purchaseOrders
      .map(
        (item) => AppDropdownItem<int>(
          value: int.tryParse(item.data['id']?.toString() ?? '') ?? 0,
          label: item.data['order_no']?.toString().trim().isNotEmpty == true
              ? item.data['order_no'].toString()
              : 'Order #${item.data['id']}',
        ),
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

  String _partyName(int? id) {
    return _parties
            .cast<PartyModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.toString() ??
        '';
  }

  String _taskName(ProjectModel project, int? id) {
    return project.tasks
            .cast<ProjectTaskModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.taskName ??
        project.tasks
            .cast<ProjectTaskModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.taskCode ??
        '';
  }

  List<AppDropdownItem<int>> get _filterProjectItems => _projects
      .map(
        (item) => AppDropdownItem<int>(
          value: item.id ?? 0,
          label: item.projectName ?? item.projectCode ?? 'Project',
        ),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get _filterTaskItems {
    final project = _projects.cast<ProjectModel?>().firstWhere(
      (item) => item?.id == _filterProjectId,
      orElse: () => null,
    );
    final source = project == null
        ? _projects.expand((item) => item.tasks).toList(growable: false)
        : project.tasks;
    return source
        .map(
          (item) => AppDropdownItem<int>(
            value: item.id ?? 0,
            label: item.taskName ?? item.taskCode ?? 'Task',
          ),
        )
        .where((item) => item.value != 0)
        .toList(growable: false);
  }

  Future<void> _openFilterPanel() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
    final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;

    final applied = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    dialogPadding,
                    dialogPadding,
                    dialogPadding,
                    MediaQuery.of(dialogContext).viewInsets.bottom +
                        dialogPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter Vendor Work',
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            color: appTheme.mutedText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _filterBox(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Search',
                              ),
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<int>.fromMapped(
                              initialValue: _filterProjectId,
                              labelText: 'Project',
                              mappedItems: _filterProjectItems,
                              onChanged: (value) {
                                setDialogState(() {
                                  _filterProjectId = value;
                                  final taskExists = _filterTaskItems.any(
                                    (item) => item.value == _filterTaskId,
                                  );
                                  if (!taskExists) {
                                    _filterTaskId = null;
                                  }
                                });
                              },
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<int>.fromMapped(
                              initialValue: _filterTaskId,
                              labelText: 'Task',
                              mappedItems: _filterTaskItems,
                              onChanged: (value) =>
                                  setDialogState(() => _filterTaskId = value),
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<int>.fromMapped(
                              initialValue: _filterVendorPartyId,
                              labelText: 'Vendor',
                              mappedItems: _partyItems,
                              onChanged: (value) => setDialogState(
                                () => _filterVendorPartyId = value,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            icon: const Icon(Icons.search),
                            label: const Text('Apply Filters'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                _searchController.clear();
                                _filterProjectId = null;
                                _filterTaskId = null;
                                _filterVendorPartyId = null;
                              });
                              Navigator.of(dialogContext).pop(true);
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (applied == true) {
      _applyFilters();
    }
  }

  Widget _filterBox({required Widget child}) {
    return SizedBox(width: 220, child: child);
  }

  int? _intValue(String text) => int.tryParse(text.trim());
  double? _doubleValue(String text) => double.tryParse(text.trim());
  String _decimalText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());

  Future<void> _saveVendorWork() async {
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
      final model = ProjectVendorWorkModel(
        id: _selectedRow?.work.id,
        projectId: projectId,
        projectTaskId: _taskId,
        vendorPartyId: _vendorPartyId,
        purchaseOrderId: _purchaseOrderId,
        purchaseInvoiceId: _purchaseInvoiceId,
        workDescription: _descriptionController.text.trim(),
        amount: _doubleValue(_amountController.text),
        voucherId: _intValue(_voucherIdController.text),
        workStatus: _status,
        remarks: nullIfEmpty(_remarksController.text),
      );
      final response = _selectedRow?.work.id == null
          ? await _projectService.createVendorWork(projectId, model)
          : await _projectService.updateVendorWork(
              _selectedRow!.work.id!,
              model,
            );
      if (!mounted) return;
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: response.data?.id ?? _selectedRow?.work.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteVendorWork() async {
    final row = _selectedRow;
    if (row?.work.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor Work'),
        content: const Text('Remove this vendor work entry?'),
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
      final response = await _projectService.deleteVendorWork(row!.work.id!);
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
        onPressed: _openFilterPanel,
        icon: Icons.filter_alt_outlined,
        label: 'Filter',
        filled: false,
      ),
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.handyman_outlined,
        label: 'New Vendor Work',
      ),
    ];

    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading project vendor works...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project vendor works',
        message: _pageError!,
        onRetry: _loadData,
      );
    }
    final content = SettingsWorkspace(
      controller: _workspaceController,
      title: 'Project Vendor Works',
      editorTitle: _partyName(_selectedRow?.work.vendorPartyId),
      scrollController: _pageScrollController,
      list: SettingsListCard<_ProjectVendorWorkRow>(
        items: _filteredRows,
        selectedItem: _selectedRow,
        emptyMessage: 'No vendor works found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: _partyName(row.work.vendorPartyId).isNotEmpty
              ? _partyName(row.work.vendorPartyId)
              : 'Vendor Work',
          subtitle: [
            row.project.projectName ?? '',
            row.work.workStatus ?? '',
            _decimalText(row.work.amount),
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
                  initialValue: _vendorPartyId,
                  labelText: 'Vendor',
                  mappedItems: _partyItems,
                  onChanged: (value) => setState(() => _vendorPartyId = value),
                  validator: Validators.requiredSelection('Vendor'),
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: _purchaseOrderId,
                  labelText: 'Purchase Order',
                  mappedItems: _purchaseOrderItems,
                  onChanged: (value) =>
                      setState(() => _purchaseOrderId = value),
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
                  labelText: 'Work Status',
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
                  labelText: 'Work Description',
                  maxLines: 3,
                  validator: Validators.compose([
                    Validators.required('Work Description'),
                    Validators.optionalMaxLength(500, 'Work Description'),
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
                  onPressed: _saving ? null : _saveVendorWork,
                  icon: _selectedRow?.work.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: _saving ? 'Saving...' : 'Save Vendor Work',
                  busy: _saving,
                ),
                AppActionButton(
                  onPressed: _saving ? null : _resetForm,
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (_selectedRow?.work.id != null)
                  AppActionButton(
                    onPressed: _saving ? null : _deleteVendorWork,
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
      title: 'Project Vendor Works',
      actions: actions,
      scrollController: _pageScrollController,
      child: content,
    );
  }
}

class _ProjectVendorWorkRow {
  const _ProjectVendorWorkRow({required this.project, required this.work});

  final ProjectModel project;
  final ProjectVendorWorkModel work;
}
