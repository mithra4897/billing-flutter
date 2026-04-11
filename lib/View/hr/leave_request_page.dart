import '../../screen.dart';

class LeaveRequestManagementPage extends StatefulWidget {
  const LeaveRequestManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LeaveRequestManagementPage> createState() =>
      _LeaveRequestManagementPageState();
}

class _LeaveRequestManagementPageState
    extends State<LeaveRequestManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'rejected', label: 'Rejected'),
      ];

  final HrService _hrService = HrService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<LeaveRequestModel> _leaveRequests = const <LeaveRequestModel>[];
  List<LeaveRequestModel> _filteredLeaveRequests = const <LeaveRequestModel>[];
  List<EmployeeModel> _employees = const <EmployeeModel>[];
  List<LeaveTypeModel> _leaveTypes = const <LeaveTypeModel>[];
  LeaveRequestModel? _selectedLeaveRequest;
  int? _contextCompanyId;
  int? _employeeId;
  int? _leaveTypeId;
  String _status = 'pending';

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
    _fromDateController.dispose();
    _toDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _leaveRequests.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _hrService.leaveRequests(filters: const {'per_page': 200}),
        _hrService.leaveTypes(
          filters: const {'per_page': 200, 'sort_by': 'leave_name'},
        ),
        _hrService.employees(
          filters: const {'per_page': 200, 'sort_by': 'employee_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);

      final leaveRequests =
          (responses[0] as PaginatedResponse<LeaveRequestModel>).data ??
          const <LeaveRequestModel>[];
      final leaveTypes =
          (responses[1] as PaginatedResponse<LeaveTypeModel>).data ??
          const <LeaveTypeModel>[];
      final employees =
          (responses[2] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];
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

      if (!mounted) return;

      setState(() {
        _contextCompanyId = contextSelection.companyId;
        _leaveRequests = leaveRequests;
        _leaveTypes = leaveTypes;
        _employees = employees;
        _filteredLeaveRequests = _filterLeaveRequests(
          leaveRequests,
          _searchController.text,
        );
        _initialLoading = false;
      });

      final selected = selectId != null
          ? leaveRequests.cast<LeaveRequestModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedLeaveRequest == null
                ? (_filteredLeaveRequests.isNotEmpty
                      ? _filteredLeaveRequests.first
                      : null)
                : leaveRequests.cast<LeaveRequestModel?>().firstWhere(
                    (item) => item?.id == _selectedLeaveRequest?.id,
                    orElse: () => _filteredLeaveRequests.isNotEmpty
                        ? _filteredLeaveRequests.first
                        : null,
                  ));

      if (selected != null) {
        _selectLeaveRequest(selected);
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

  final MasterService _masterService = MasterService();

  List<EmployeeModel> get _scopedEmployees {
    return _employees
        .where((item) {
          return _contextCompanyId == null ||
              item.companyId == _contextCompanyId;
        })
        .toList(growable: false);
  }

  List<LeaveRequestModel> _filterLeaveRequests(
    List<LeaveRequestModel> source,
    String query,
  ) {
    final allowedEmployeeIds = _scopedEmployees
        .map((item) => item.id)
        .whereType<int>()
        .toSet();
    final scoped = _contextCompanyId == null
        ? source
        : source
              .where(
                (item) =>
                    item.employeeId == null ||
                    allowedEmployeeIds.contains(item.employeeId),
              )
              .toList(growable: false);

    return filterMasterList(scoped, query, (item) {
      return [
        item.employeeCode ?? '',
        item.employeeName ?? '',
        item.leaveTypeName ?? '',
        item.status ?? '',
        item.reason ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredLeaveRequests = _filterLeaveRequests(
        _leaveRequests,
        _searchController.text,
      );
    });
  }

  void _selectLeaveRequest(LeaveRequestModel item) {
    _selectedLeaveRequest = item;
    _employeeId = item.employeeId;
    _leaveTypeId = item.leaveTypeId;
    _fromDateController.text = item.fromDate ?? '';
    _toDateController.text = item.toDate ?? '';
    _reasonController.text = item.reason ?? '';
    _status = item.status ?? 'pending';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedLeaveRequest = null;
    _employeeId = null;
    _leaveTypeId = null;
    _fromDateController.clear();
    _toDateController.clear();
    _reasonController.clear();
    _status = 'pending';
    _formError = null;
    setState(() {});
  }

  void _startNew() {
    _resetForm();
    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  Future<void> _openCreateLeaveTypeDialog() async {
    final nameController = TextEditingController();
    final maxDaysController = TextEditingController();
    var isPaid = true;
    String? errorText;

    final created = await showDialog<LeaveTypeModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Leave Type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppFormTextField(
                    controller: nameController,
                    labelText: 'Leave Name',
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  AppFormTextField(
                    controller: maxDaysController,
                    labelText: 'Max Days Per Year',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  AppSwitchTile(
                    label: 'Paid Leave',
                    value: isPaid,
                    onChanged: (value) => setDialogState(() => isPaid = value),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppUiConstants.spacingSm),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final leaveName = nameController.text.trim();
                    if (leaveName.isEmpty) {
                      setDialogState(() {
                        errorText = 'Leave Name is required.';
                      });
                      return;
                    }
                    try {
                      final response = await _hrService.createLeaveType(
                        LeaveTypeModel(
                          leaveName: leaveName,
                          maxDaysPerYear: double.tryParse(
                            maxDaysController.text.trim(),
                          ),
                          isPaid: isPaid,
                        ),
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop(response.data);
                    } catch (error) {
                      setDialogState(() {
                        errorText = error.toString();
                      });
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created?.id == null || !mounted) {
      return;
    }

    final refreshed = await _hrService.leaveTypes(
      filters: const {'per_page': 200, 'sort_by': 'leave_name'},
    );
    if (!mounted) return;
    final createdLeaveType = created!;
    setState(() {
      _leaveTypes = refreshed.data ?? <LeaveTypeModel>[createdLeaveType];
      _leaveTypeId = createdLeaveType.id;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = LeaveRequestModel(
      id: _selectedLeaveRequest?.id,
      employeeId: _employeeId,
      leaveTypeId: _leaveTypeId,
      fromDate: nullIfEmpty(_fromDateController.text.trim()),
      toDate: nullIfEmpty(_toDateController.text.trim()),
      reason: nullIfEmpty(_reasonController.text.trim()),
      status: _status,
    );

    try {
      final response = _selectedLeaveRequest == null
          ? await _hrService.createLeaveRequest(model)
          : await _hrService.updateLeaveRequest(
              _selectedLeaveRequest!.id!,
              model,
            );
      final saved = response.data;
      if (!mounted) return;
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = _selectedLeaveRequest?.id;
    if (id == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _hrService.deleteLeaveRequest(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNew,
        icon: Icons.event_available_outlined,
        label: 'New Leave Request',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Leave Requests',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading leave requests...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load leave requests',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Leave Requests',
      editorTitle: _selectedLeaveRequest?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<LeaveRequestModel>(
        searchController: _searchController,
        searchHint: 'Search leave requests',
        items: _filteredLeaveRequests,
        selectedItem: _selectedLeaveRequest,
        emptyMessage: 'No leave requests found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.employeeName ?? item.employeeCode ?? '-',
          subtitle: [
            item.leaveTypeName ?? '',
            item.fromDate ?? '',
            item.toDate ?? '',
            item.status ?? '',
          ].where((value) => value.isNotEmpty).join(' • '),
          detail: item.reason ?? '',
          selected: selected,
          onTap: () => _selectLeaveRequest(item),
        ),
      ),
      editor: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_formError != null) ...[
              AppErrorStateView.inline(message: _formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppDropdownField<int>.fromMapped(
                  labelText: 'Employee',
                  mappedItems: _scopedEmployees
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _employeeId,
                  onChanged: (value) => setState(() => _employeeId = value),
                  validator: Validators.requiredSelection('Employee'),
                ),
                InlineFieldAction(
                  actionTooltip: 'Create leave type',
                  onAddNew: _openCreateLeaveTypeDialog,
                  field: AppDropdownField<int>.fromMapped(
                    labelText: 'Leave Type',
                    mappedItems: _leaveTypes
                        .where((item) => item.id != null)
                        .map(
                          (item) => AppDropdownItem(
                            value: item.id!,
                            label: item.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: _leaveTypeId,
                    onChanged: (value) => setState(() => _leaveTypeId = value),
                    validator: Validators.requiredSelection('Leave Type'),
                  ),
                ),
                AppFormTextField(
                  controller: _fromDateController,
                  labelText: 'From Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('From Date'),
                    Validators.date('From Date'),
                  ]),
                ),
                AppFormTextField(
                  controller: _toDateController,
                  labelText: 'To Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('To Date'),
                    Validators.date('To Date'),
                    Validators.optionalDateOnOrAfter(
                      'To Date',
                      () => _fromDateController.text.trim(),
                      startFieldName: 'From Date',
                    ),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Status',
                  mappedItems: _statusItems,
                  initialValue: _status,
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'pending'),
                ),
                AppFormTextField(
                  controller: _reasonController,
                  labelText: 'Reason',
                  maxLines: 3,
                  validator: Validators.optionalMaxLength(1000, 'Reason'),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedLeaveRequest == null
                      ? 'Save Leave Request'
                      : 'Update Leave Request',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedLeaveRequest?.id != null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: _delete,
                    busy: _saving,
                    filled: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
