import '../../screen.dart';
import 'hr_workflow_dialogs.dart';

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

  static const List<AppDropdownItem<String?>> _listStatusFilterItems =
      <AppDropdownItem<String?>>[
        AppDropdownItem<String?>(value: null, label: 'All statuses'),
        AppDropdownItem<String?>(value: 'pending', label: 'Pending'),
        AppDropdownItem<String?>(value: 'approved', label: 'Approved'),
        AppDropdownItem<String?>(value: 'rejected', label: 'Rejected'),
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
  final TextEditingController _listDateFromController = TextEditingController();
  final TextEditingController _listDateToController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String? _companyBanner;
  int? _sessionCompanyId;
  bool _canViewAllHr = false;
  int? _linkedEmployeeId;
  int? _listFilterEmployeeId;
  String? _listFilterStatus;
  List<LeaveRequestModel> _leaveRequests = const <LeaveRequestModel>[];
  List<LeaveRequestModel> _filteredLeaveRequests = const <LeaveRequestModel>[];
  List<EmployeeModel> _employees = const <EmployeeModel>[];
  List<LeaveTypeModel> _leaveTypes = const <LeaveTypeModel>[];
  LeaveRequestModel? _selectedLeaveRequest;
  int? _employeeId;
  int? _leaveTypeId;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _reasonController.dispose();
    _listDateFromController.dispose();
    _listDateToController.dispose();
    super.dispose();
  }

  void _onWorkingContextChanged() {
    _loadData();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _leaveRequests.isEmpty;
      _pageError = null;
    });

    try {
      final info = await hrSessionCompanyInfo();
      final cid = info.companyId;
      if (cid == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _companyBanner = info.banner;
          _sessionCompanyId = null;
          _canViewAllHr = false;
          _linkedEmployeeId = null;
          _leaveRequests = const <LeaveRequestModel>[];
          _filteredLeaveRequests = const <LeaveRequestModel>[];
          _initialLoading = false;
          _pageError = 'Select a session company to load leave requests.';
        });
        _resetForm();
        return;
      }

      final ctxRes = await _hrService.expenseClaimsLinkedEmployee(
        companyId: cid,
      );
      final ctx = ctxRes.data ?? const <String, dynamic>{};
      final viewAll =
          ctx['can_view_all_hr_records'] == true ||
          ctx['can_view_all_hr_records'] == 1 ||
          ctx['can_view_all_claims'] == true ||
          ctx['can_view_all_claims'] == 1;
      final linked = intValue(ctx, 'employee_id');

      if (!viewAll && linked == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _companyBanner = info.banner;
          _sessionCompanyId = cid;
          _canViewAllHr = false;
          _linkedEmployeeId = null;
          _leaveRequests = const <LeaveRequestModel>[];
          _filteredLeaveRequests = const <LeaveRequestModel>[];
          _initialLoading = false;
          _pageError =
              'No employee record is linked to your user for this company. '
              'Your user employee code must match an employee in HR.';
        });
        _resetForm();
        return;
      }

      final filters = <String, dynamic>{
        'company_id': cid,
        'per_page': 200,
      };
      if (viewAll && _listFilterEmployeeId != null) {
        filters['employee_id'] = _listFilterEmployeeId;
      }
      if (viewAll &&
          _listFilterStatus != null &&
          _listFilterStatus!.isNotEmpty) {
        filters['status'] = _listFilterStatus;
      }
      final dateFrom = _listDateFromController.text.trim();
      final dateTo = _listDateToController.text.trim();
      if (dateFrom.isNotEmpty) {
        filters['date_from'] = dateFrom;
      }
      if (dateTo.isNotEmpty) {
        filters['date_to'] = dateTo;
      }

      final responses = await Future.wait<dynamic>([
        _hrService.leaveRequests(filters: filters),
        _hrService.leaveTypes(
          filters: const {'per_page': 200, 'sort_by': 'leave_name'},
        ),
        _hrService.employees(
          filters: <String, dynamic>{
            'per_page': 500,
            'sort_by': 'employee_name',
            'company_id': cid,
          },
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

      if (!mounted) {
        return;
      }

      setState(() {
        _companyBanner = info.banner;
        _sessionCompanyId = cid;
        _canViewAllHr = viewAll;
        _linkedEmployeeId = linked;
        _leaveRequests = leaveRequests;
        _leaveTypes = leaveTypes;
        _employees = employees;
        _filteredLeaveRequests = _filterLeaveRequests(
          leaveRequests,
          _searchController.text,
        );
        _initialLoading = false;
        _pageError = null;
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
      if (!mounted) {
        return;
      }
      setState(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  List<EmployeeModel> get _formEmployees {
    if (_sessionCompanyId == null) {
      return const <EmployeeModel>[];
    }
    final base = _employees
        .where(
          (item) => item.companyId == _sessionCompanyId && item.id != null,
        )
        .toList(growable: false);
    if (_canViewAllHr) {
      return base;
    }
    if (_linkedEmployeeId == null) {
      return base;
    }
    return base
        .where((item) => item.id == _linkedEmployeeId)
        .toList(growable: false);
  }

  LeaveTypeModel? get _activeLeaveType {
    for (final t in _leaveTypes) {
      if (t.id == _leaveTypeId) {
        return t;
      }
    }
    return null;
  }

  bool _isCasualLeaveType(LeaveTypeModel? type) {
    if (type == null) {
      return false;
    }
    final code = (type.leaveCode ?? '').toUpperCase().trim();
    if (code == 'CL') {
      return true;
    }
    final name = (type.leaveName ?? '').toLowerCase();
    return name == 'casual leave' || name.contains('casual');
  }

  List<LeaveRequestModel> _filterLeaveRequests(
    List<LeaveRequestModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (LeaveRequestModel item) {
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
    _employeeId =
        (!_canViewAllHr && _linkedEmployeeId != null) ? _linkedEmployeeId : null;
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
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_companyBanner != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.apartment_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppUiConstants.spacingSm),
                  Expanded(
                    child: Text(
                      'Session company: $_companyBanner',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          if (_canViewAllHr) ...[
            AppDropdownField<int?>.fromMapped(
              labelText: 'Employee filter',
              mappedItems: <AppDropdownItem<int?>>[
                const AppDropdownItem<int?>(value: null, label: 'All employees'),
                ..._employees
                    .where(
                      (e) =>
                          e.companyId == _sessionCompanyId && e.id != null,
                    )
                    .map(
                      (e) => AppDropdownItem<int?>(
                        value: e.id,
                        label: e.toString(),
                      ),
                    ),
              ],
              initialValue: _listFilterEmployeeId,
              onChanged: (int? v) {
                setState(() => _listFilterEmployeeId = v);
                _loadData();
              },
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            AppDropdownField<String?>.fromMapped(
              labelText: 'Status filter',
              mappedItems: _listStatusFilterItems,
              initialValue: _listFilterStatus,
              onChanged: (String? v) {
                setState(() => _listFilterStatus = v);
                _loadData();
              },
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          AppFormTextField(
            controller: _listDateFromController,
            labelText: 'List from date',
            hintText: 'Filter overlapping from…',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          AppFormTextField(
            controller: _listDateToController,
            labelText: 'List to date',
            hintText: 'Filter overlapping to…',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.filter_alt_outlined, size: 20),
              label: const Text('Apply date filters'),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<LeaveRequestModel>(
            searchController: _searchController,
            searchHint: 'Search leave requests',
            items: _filteredLeaveRequests,
            selectedItem: _selectedLeaveRequest,
            emptyMessage: 'No leave requests found.',
            itemBuilder: (LeaveRequestModel item, bool selected) =>
                SettingsListTile(
              title: item.employeeName ?? item.employeeCode ?? '-',
              subtitle: [
                item.leaveTypeName ?? '',
                item.fromDate ?? '',
                item.toDate ?? '',
                item.status ?? '',
              ].where((String value) => value.isNotEmpty).join(' • '),
              detail: item.reason ?? '',
              selected: selected,
              onTap: () => _selectLeaveRequest(item),
            ),
          ),
        ],
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
                  mappedItems: _formEmployees
                      .where((EmployeeModel item) => item.id != null)
                      .map(
                        (EmployeeModel item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _employeeId,
                  onChanged: (int? value) => setState(() => _employeeId = value),
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
                if (_isCasualLeaveType(_activeLeaveType)) ...[
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Text(
                    'Casual leave uses 1 accrued CL day per elapsed month in the '
                    'calendar year (max 12). Any days above your CL balance are '
                    'recorded as LOP (unpaid). Split is calculated when you save '
                    'and recalculated again when HR approves (using balances as of '
                    'that day). Payroll deducts LOP when the monthly run is processed.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_selectedLeaveRequest != null &&
                    ((_selectedLeaveRequest!.clApprovedDays ?? 0) > 0 ||
                        (_selectedLeaveRequest!.lopDays ?? 0) > 0)) ...[
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Text(
                    'CL days (paid): ${_selectedLeaveRequest!.clApprovedDays ?? 0} · '
                    'LOP days (unpaid): ${_selectedLeaveRequest!.lopDays ?? 0}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
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
