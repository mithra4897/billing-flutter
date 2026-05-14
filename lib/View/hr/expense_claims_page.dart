import '../../screen.dart';
import '../purchase/purchase_support.dart';
import 'hr_list_filter_helpers.dart';
import 'hr_workflow_dialogs.dart';

void _expenseClaimsNeedCompanySnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Choose a company in the header session control before using expense claims.',
      ),
    ),
  );
}

Map<String, dynamic>? _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _nestedEmployeeName(Map<String, dynamic> data) {
  final emp = _asJsonMap(data['employee']);
  if (emp == null) {
    return '';
  }
  return stringValue(emp, 'employee_name');
}

String _paymentSubtitle(Map<String, dynamic> d) {
  final st = _claimStatusCode(d['claim_status']);
  final rid = intValue(d, 'reimbursement_voucher_id');
  if (st == 'approved' && rid == null) {
    return 'Unpaid · ${stringValue(d, 'total_amount')}';
  }
  if (st == 'reimbursed') {
    return 'Paid · ${stringValue(d, 'total_amount')}';
  }
  return '${_claimStatusLabel(d['claim_status'])} · ${stringValue(d, 'total_amount')}';
}

String _claimStatusCode(dynamic status) {
  final value = status?.toString().trim().toLowerCase() ?? '';
  if (value == '0' || value == 'draft') {
    return 'draft';
  }
  if (value == '1' || value == 'applied' || value == 'submitted') {
    return 'applied';
  }
  if (value == 'approved') {
    return 'approved';
  }
  if (value == 'reimbursed') {
    return 'reimbursed';
  }
  if (value == 'rejected') {
    return 'rejected';
  }
  if (value == 'cancelled') {
    return 'cancelled';
  }
  return value;
}

String _claimStatusLabel(dynamic status) {
  switch (_claimStatusCode(status)) {
    case 'draft':
      return 'Draft';
    case 'applied':
      return 'Applied';
    case 'approved':
      return 'Approved';
    case 'reimbursed':
      return 'Reimbursed';
    case 'rejected':
      return 'Rejected';
    case 'cancelled':
      return 'Cancelled';
    default:
      return (status?.toString().trim().isNotEmpty ?? false)
          ? status.toString()
          : '-';
  }
}

bool _isHrApprovalQueueRow(Map<String, dynamic> data) {
  final status = _claimStatusCode(data['claim_status']);
  final reimbursementVoucherId = intValue(data, 'reimbursement_voucher_id');
  if (status == 'applied') {
    return true;
  }
  if (status == 'rejected') {
    return true;
  }
  if (status == 'approved' && reimbursementVoucherId == null) {
    return true;
  }
  if (status == 'reimbursed') {
    return true;
  }
  return false;
}

class _ExpenseLineEditors {
  _ExpenseLineEditors({
    required this.expenseDate,
    required this.category,
    required this.description,
    required this.amount,
    required this.remarks,
    this.projectId,
    this.projectTaskId,
  });

  final TextEditingController expenseDate;
  final TextEditingController category;
  final TextEditingController description;
  final TextEditingController amount;
  final TextEditingController remarks;
  final int? projectId;
  final int? projectTaskId;

  void dispose() {
    expenseDate.dispose();
    category.dispose();
    description.dispose();
    amount.dispose();
    remarks.dispose();
  }
}

Map<String, dynamic>? _lineMap(dynamic item) {
  if (item is Map<String, dynamic>) {
    return item;
  }
  if (item is Map) {
    return Map<String, dynamic>.from(item);
  }
  return null;
}

List<_ExpenseLineEditors> _editorsFromClaimJson(Map<String, dynamic> data) {
  final linesRaw = data['lines'];
  final editors = <_ExpenseLineEditors>[];
  if (linesRaw is List) {
    for (final item in linesRaw) {
      final m = _lineMap(item);
      if (m == null) {
        continue;
      }
      editors.add(
        _ExpenseLineEditors(
          expenseDate: TextEditingController(
            text: displayDate(nullableStringValue(m, 'expense_date')),
          ),
          category: TextEditingController(
            text: stringValue(m, 'expense_category'),
          ),
          description: TextEditingController(
            text: stringValue(m, 'description'),
          ),
          amount: TextEditingController(
            text: stringValue(m, 'amount'),
          ),
          remarks: TextEditingController(
            text: stringValue(m, 'remarks'),
          ),
          projectId: intValue(m, 'project_id'),
          projectTaskId: intValue(m, 'project_task_id'),
        ),
      );
    }
  }
  if (editors.isEmpty) {
    editors.add(
      _ExpenseLineEditors(
        expenseDate: TextEditingController(
          text: displayDate(DateTime.now().toIso8601String()),
        ),
        category: TextEditingController(),
        description: TextEditingController(),
        amount: TextEditingController(),
        remarks: TextEditingController(),
      ),
    );
  }
  return editors;
}

class ExpenseClaimsManagementPage extends StatefulWidget {
  const ExpenseClaimsManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ExpenseClaimsManagementPage> createState() =>
      _ExpenseClaimsManagementPageState();
}

class _ExpenseClaimsManagementPageState extends State<ExpenseClaimsManagementPage> {
  final HrService _hr = HrService();
  final AccountsService _accounts = AccountsService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _expenseClaimFormKey = GlobalKey<FormState>();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _claimNoCtrl = TextEditingController();
  final TextEditingController _claimDateCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  bool _initialLoading = true;
  bool _editorLoading = false;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String? _companyBanner;
  int? _companyId;
  List<ExpenseClaimModel> _rows = const <ExpenseClaimModel>[];
  ExpenseClaimModel? _selectedListRow;
  Map<String, dynamic>? _editorSnapshot;
  int? _editingClaimId;
  bool _isNewClaim = false;
  int _formGeneration = 0;

  int? _linkedEmployeeId;
  bool _canViewAllClaims = false;

  List<EmployeeModel> _employees = const <EmployeeModel>[];
  int? _employeeId;

  int? _filterEmployeeId;
  String? _filterPaymentStatus;
  String? _filterClaimStatus;

  List<_ExpenseLineEditors> _lineEditors = <_ExpenseLineEditors>[];

  static const List<AppDropdownItem<String?>> _paymentFilterItems =
      <AppDropdownItem<String?>>[
    AppDropdownItem<String?>(value: null, label: 'All payments'),
    AppDropdownItem<String?>(value: 'unpaid', label: 'Unpaid'),
    AppDropdownItem<String?>(value: 'paid', label: 'Paid'),
  ];

  static const List<AppDropdownItem<String?>> _statusFilterItems =
      <AppDropdownItem<String?>>[
    AppDropdownItem<String?>(value: null, label: 'All statuses'),
    AppDropdownItem<String?>(value: '0', label: 'Draft'),
    AppDropdownItem<String?>(value: '1', label: 'Applied'),
    AppDropdownItem<String?>(value: 'approved', label: 'Approved'),
    AppDropdownItem<String?>(value: 'reimbursed', label: 'Reimbursed'),
    AppDropdownItem<String?>(value: 'rejected', label: 'Rejected'),
    AppDropdownItem<String?>(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    _searchController.addListener(() => setState(() {}));
    _loadPage();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    _scrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _claimNoCtrl.dispose();
    _claimDateCtrl.dispose();
    _notesCtrl.dispose();
    _disposeLineEditors();
    super.dispose();
  }

  void _onWorkingContextChanged() {
    _loadPage();
  }

  void _disposeLineEditors() {
    for (final e in _lineEditors) {
      e.dispose();
    }
    _lineEditors = <_ExpenseLineEditors>[];
  }

  List<ExpenseClaimModel> get _filteredRows {
    final q = _searchController.text.trim().toLowerCase();
    final visibleRows = _canViewAllClaims
        ? _rows.where((ExpenseClaimModel row) {
            return _isHrApprovalQueueRow(row.toJson());
          }).toList(growable: false)
        : _rows;
    if (q.isEmpty) {
      return visibleRows;
    }
    return visibleRows
        .where((ExpenseClaimModel row) {
          final data = row.toJson();
          return [
            stringValue(data, 'claim_no'),
            stringValue(data, 'claim_date'),
            stringValue(data, 'claim_status'),
            stringValue(data, 'total_amount'),
            _nestedEmployeeName(data),
            _paymentSubtitle(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  List<EmployeeModel> get _employeesForEditor {
    if (_companyId == null) {
      return const <EmployeeModel>[];
    }
    final base = _employees
        .where((e) => e.companyId == _companyId && e.id != null)
        .toList(growable: false);
    if (_isNewClaim && _linkedEmployeeId != null) {
      return base
          .where((e) => e.id == _linkedEmployeeId)
          .toList(growable: false);
    }
    if (_linkedEmployeeId == null && !_canViewAllClaims) {
      return base;
    }
    return base;
  }

  bool get _employeeFieldReadOnly => true;

  bool get _isSelfServiceUser => !_canViewAllClaims;

  Future<void> _loadPage({int? selectClaimId}) async {
    setState(() {
      _initialLoading = _rows.isEmpty;
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
          _companyId = null;
          _rows = const <ExpenseClaimModel>[];
          _initialLoading = false;
          _pageError = 'Select a session company to load expense claims.';
        });
        _resetEditorToEmpty();
        return;
      }

      final ctxRes = await _hr.expenseClaimsLinkedEmployee(companyId: cid);
      final ctx = ctxRes.data ?? const <String, dynamic>{};
      final viewAll =
          ctx['can_view_all_claims'] == true ||
          ctx['can_view_all_claims'] == 1 ||
          ctx['can_view_all_hr_records'] == true ||
          ctx['can_view_all_hr_records'] == 1;
      final linked = intValue(ctx, 'employee_id');

      final empResp = await _hr.employees(
        filters: <String, dynamic>{
          'per_page': 500,
          'sort_by': 'employee_name',
          'company_id': cid,
        },
      );
      _employees = empResp.data ?? const <EmployeeModel>[];

      final filters = <String, dynamic>{
        'company_id': cid,
        'per_page': 200,
      };
      if (viewAll && _filterEmployeeId != null) {
        filters['employee_id'] = _filterEmployeeId;
      }
      if (_filterPaymentStatus != null && _filterPaymentStatus!.isNotEmpty) {
        filters['payment_status'] = _filterPaymentStatus;
      }
      if (_filterClaimStatus != null && _filterClaimStatus!.isNotEmpty) {
        filters['claim_status'] = _filterClaimStatus;
      }

      final listRes = await _hr.expenseClaims(filters: filters);
      if (!mounted) {
        return;
      }

      final rows = listRes.data ?? const <ExpenseClaimModel>[];

      setState(() {
        _companyBanner = info.banner;
        _companyId = cid;
        _linkedEmployeeId = linked;
        _canViewAllClaims = viewAll;
        _rows = rows;
        _initialLoading = false;
      });

      final pickId = selectClaimId ??
          (_selectedListRow != null
              ? intValue(_selectedListRow!.toJson(), 'id')
              : null);

      if (pickId != null &&
          rows.any((r) => intValue(r.toJson(), 'id') == pickId)) {
        await _hydrateEditorFromClaimId(pickId);
      } else if (rows.isNotEmpty) {
        final firstId = intValue(rows.first.toJson(), 'id');
        if (firstId != null) {
          await _hydrateEditorFromClaimId(firstId);
        }
      } else {
        _resetEditorToEmpty();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pageError = e.toString();
        _initialLoading = false;
      });
    }
  }

  void _resetEditorToEmpty() {
    _disposeLineEditors();
    _claimNoCtrl.clear();
    _claimDateCtrl.text = displayDate(DateTime.now().toIso8601String());
    _notesCtrl.clear();
    _employeeId = _linkedEmployeeId;
    _editingClaimId = null;
    _isNewClaim = false;
    _selectedListRow = null;
    _editorSnapshot = null;
    _formError = null;
    _lineEditors = _editorsFromClaimJson(<String, dynamic>{});
    _formGeneration++;
    setState(() {});
  }

  void _startNewClaim() {
    if (_companyId == null) {
      return;
    }
    _disposeLineEditors();
    _claimNoCtrl.clear();
    _claimDateCtrl.text = displayDate(DateTime.now().toIso8601String());
    _notesCtrl.clear();
    _employeeId = _linkedEmployeeId;
    _editingClaimId = null;
    _isNewClaim = true;
    _selectedListRow = null;
    _editorSnapshot = null;
    _formError = null;
    _editorLoading = false;
    _lineEditors = _editorsFromClaimJson(<String, dynamic>{});
    _formGeneration++;
    setState(() {});
    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  /// Refetch list rows only (same filters as [_loadPage]), without employees fetch
  /// or swapping the editor for a loading placeholder — keeps [Form] mounted on web.
  Future<void> _syncExpenseClaimsListFromServer({int? selectClaimId}) async {
    if (_companyId == null) {
      return;
    }
    final filters = <String, dynamic>{
      'company_id': _companyId,
      'per_page': 200,
    };
    if (_canViewAllClaims && _filterEmployeeId != null) {
      filters['employee_id'] = _filterEmployeeId;
    }
    if (_filterPaymentStatus != null && _filterPaymentStatus!.isNotEmpty) {
      filters['payment_status'] = _filterPaymentStatus;
    }
    if (_filterClaimStatus != null && _filterClaimStatus!.isNotEmpty) {
      filters['claim_status'] = _filterClaimStatus;
    }
    final listRes = await _hr.expenseClaims(filters: filters);
    if (!mounted) {
      return;
    }
    final rows = listRes.data ?? const <ExpenseClaimModel>[];
    final int? pickId = selectClaimId ?? _editingClaimId;
    ExpenseClaimModel? match;
    if (pickId != null) {
      for (final ExpenseClaimModel r in rows) {
        if (intValue(r.toJson(), 'id') == pickId) {
          match = r;
          break;
        }
      }
    }
    setState(() {
      _rows = rows;
      if (match != null) {
        _selectedListRow = match;
      }
    });
  }

  Future<void> _reloadEditorAndListAfterMutation({required int claimId}) async {
    await _hydrateEditorFromClaimId(claimId, showLoading: false);
    if (!mounted || _formError != null) {
      return;
    }
    await _syncExpenseClaimsListFromServer(selectClaimId: claimId);
  }

  Future<void> _hydrateEditorFromClaimId(
    int id, {
    bool showLoading = true,
  }) async {
    if (_companyId == null) {
      return;
    }
    if (showLoading) {
      setState(() {
        _editorLoading = true;
        _formError = null;
        _isNewClaim = false;
        _editingClaimId = id;
      });
    } else {
      _formError = null;
      _isNewClaim = false;
      _editingClaimId = id;
    }

    final res = await _hr.expenseClaim(id);
    if (!mounted) {
      return;
    }

    if (res.success != true || res.data == null) {
      setState(() {
        if (showLoading) {
          _editorLoading = false;
        }
        _formError = res.message;
      });
      return;
    }

    final d = res.data!.toJson();
    _disposeLineEditors();
    _claimNoCtrl.text = stringValue(d, 'claim_no');
    _claimDateCtrl.text = displayDate(nullableStringValue(d, 'claim_date'));
    _notesCtrl.text = stringValue(d, 'notes');
    _employeeId = intValue(d, 'employee_id');
    _lineEditors = _editorsFromClaimJson(d);
    _editorSnapshot = Map<String, dynamic>.from(d);
    ExpenseClaimModel? listMatch;
    for (final r in _rows) {
      if (intValue(r.toJson(), 'id') == id) {
        listMatch = r;
        break;
      }
    }
    _selectedListRow = listMatch;
    _formGeneration++;

    setState(() {
      if (showLoading) {
        _editorLoading = false;
      }
    });
  }

  Future<void> _submitClaim({required bool applyNow}) async {
    if (_companyId == null) {
      return;
    }
    final FormState? form = _expenseClaimFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final lines = <Map<String, dynamic>>[];
    for (final line in _lineEditors) {
      final row = <String, dynamic>{
        'expense_date': line.expenseDate.text.trim(),
        'expense_category': line.category.text.trim(),
        'description': line.description.text.trim(),
        'amount': double.parse(line.amount.text.trim()),
        if (line.remarks.text.trim().isNotEmpty)
          'remarks': line.remarks.text.trim(),
        if (line.projectId != null) 'project_id': line.projectId,
        if (line.projectTaskId != null) 'project_task_id': line.projectTaskId,
      };
      lines.add(row);
    }

    final body = <String, dynamic>{
      'company_id': _companyId,
      'employee_id': _employeeId,
      'claim_date': _claimDateCtrl.text.trim(),
      'claim_status': applyNow ? 1 : 0,
      'lines': lines,
    };
    final cn = _claimNoCtrl.text.trim();
    if (cn.isNotEmpty) {
      body['claim_no'] = cn;
    }
    final nt = _notesCtrl.text.trim();
    if (nt.isNotEmpty) {
      body['notes'] = nt;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final model = ExpenseClaimModel(body);
      final response = _isNewClaim || _editingClaimId == null
          ? await _hr.createExpenseClaim(model)
          : await _hr.updateExpenseClaim(_editingClaimId!, model);
      if (!mounted) {
        return;
      }
      if (response.success != true || response.data == null) {
        setState(() {
          _formError = response.message;
          _saving = false;
        });
        return;
      }
      final newId = intValue(response.data!.toJson(), 'id');
      if (applyNow &&
          !_isNewClaim &&
          _editingClaimId != null &&
          response.success == true) {
        final applyResponse = await _hr.applyExpenseClaim(
          _editingClaimId!,
          ExpenseClaimModel(const <String, dynamic>{}),
        );
        if (!mounted) {
          return;
        }
        if (applyResponse.success != true || applyResponse.data == null) {
          setState(() {
            _formError = applyResponse.message;
            _saving = false;
          });
          return;
        }
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            applyNow
                ? 'Expense claim applied successfully.'
                : response.message,
          ),
        ),
      );
      setState(() => _saving = false);
      await _loadPage(selectClaimId: newId);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _formError = e.toString();
        _saving = false;
      });
    }
  }

  String? _editorStatus() {
    if (_isNewClaim) {
      return null;
    }
    if (_editorSnapshot != null) {
      return _claimStatusCode(_editorSnapshot!['claim_status']);
    }
    final row = _selectedListRow?.toJson();
    if (row == null) {
      return null;
    }
    return _claimStatusCode(row['claim_status']);
  }

  bool get _editorEditable {
    final st = _editorStatus();
    return _isSelfServiceUser && (st == null || st == 'draft');
  }

  String _expenseSelectedEmployeeLabel() {
    if (_filterEmployeeId == null) {
      return '';
    }
    for (final EmployeeModel e in _employees) {
      if (e.id == _filterEmployeeId) {
        return e.toString();
      }
    }
    return 'Employee #$_filterEmployeeId';
  }

  String _editorEmployeeLabel() {
    if (_employeeId == null) {
      return '';
    }
    for (final EmployeeModel e in _employeesForEditor) {
      if (e.id == _employeeId) {
        return e.toString();
      }
    }
    return 'Employee #$_employeeId';
  }

  List<String> _expenseAppliedFilterChips() {
    return <String>[
      if (_companyBanner != null) 'Company: $_companyBanner',
      if (_searchController.text.trim().isNotEmpty)
        'Search: ${_searchController.text.trim()}',
      if (_canViewAllClaims && _filterEmployeeId != null)
        'Employee: ${_expenseSelectedEmployeeLabel()}',
      if ((_filterPaymentStatus ?? '').isNotEmpty)
        'Payment: ${hrDropdownLabel(_paymentFilterItems, _filterPaymentStatus)}',
      if ((_filterClaimStatus ?? '').isNotEmpty)
        'Status: ${hrDropdownLabel(_statusFilterItems, _filterClaimStatus)}',
    ];
  }

  void _clearExpenseFilters() {
    setState(() {
      _searchController.clear();
      _filterEmployeeId = null;
      _filterPaymentStatus = null;
      _filterClaimStatus = null;
    });
  }

  Future<void> _openExpenseFilterPanel() async {
    final applied = await showHrListFilterDialog(
      context: context,
      title: 'Filter Expense Claims',
      header: _companyBanner == null
          ? null
          : Text(
              'Session company: $_companyBanner. Change via the header '
              'session button.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
      filterFields: [
        hrListFilterBox(
          child: AppFormTextField(
            controller: _searchController,
            labelText: 'Search',
            hintText: 'Search claims…',
          ),
        ),
        if (_canViewAllClaims)
          hrListFilterBox(
            child: AppDropdownField<int?>.fromMapped(
              labelText: 'Employee filter',
              mappedItems: <AppDropdownItem<int?>>[
                const AppDropdownItem<int?>(
                  value: null,
                  label: 'All employees',
                ),
                ..._employees
                    .where((e) => e.companyId == _companyId && e.id != null)
                    .map(
                      (e) => AppDropdownItem<int?>(
                        value: e.id,
                        label: e.toString(),
                      ),
                    ),
              ],
              initialValue: _filterEmployeeId,
              onChanged: (int? v) => setState(() => _filterEmployeeId = v),
            ),
          ),
        hrListFilterBox(
          child: AppDropdownField<String?>.fromMapped(
            labelText: 'Payment',
            mappedItems: _paymentFilterItems,
            initialValue: _filterPaymentStatus,
            onChanged: (String? v) =>
                setState(() => _filterPaymentStatus = v),
          ),
        ),
        hrListFilterBox(
          child: AppDropdownField<String?>.fromMapped(
            labelText: 'Status',
            mappedItems: _statusFilterItems,
            initialValue: _filterClaimStatus,
            onChanged: (String? v) =>
                setState(() => _filterClaimStatus = v),
          ),
        ),
      ],
      onClear: _clearExpenseFilters,
    );
    if (applied == true && mounted) {
      await _loadPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        icon: Icons.filter_alt_outlined,
        label: 'Filter',
        filled: false,
        onPressed: _openExpenseFilterPanel,
      ),
      if (_isSelfServiceUser)
        AdaptiveShellActionButton(
          icon: Icons.add_outlined,
          label: 'New claim',
          onPressed: () async {
            final cid = await hrResolveCompanyId(context);
            if (!context.mounted) {
              return;
            }
            if (cid == null) {
              _expenseClaimsNeedCompanySnack(context);
              return;
            }
            _startNewClaim();
          },
        ),
    ];

    final content = _buildContent();

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Expense claims',
      scrollController: _scrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading expense claims…');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load expense claims',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    final editorTitle = _isNewClaim
        ? 'New expense claim'
        : (_editingClaimId != null
              ? 'Claim #$_editingClaimId'
              : 'Expense claim');

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Expense claims',
      editorTitle: editorTitle,
      scrollController: _scrollController,
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hrListAppliedFiltersCard(context, _expenseAppliedFilterChips()),
          const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<ExpenseClaimModel>(
            searchController: _searchController,
            searchHint: 'Search claims…',
            showSearchBar: false,
            items: _filteredRows,
            selectedItem: _selectedListRow,
            emptyMessage: 'No expense claims match the filters.',
            itemBuilder: (ExpenseClaimModel item, bool selected) {
              final data = item.toJson();
              return SettingsListTile(
                title: stringValue(data, 'claim_no').isEmpty
                    ? 'Claim #${stringValue(data, 'id')}'
                    : stringValue(data, 'claim_no'),
                subtitle: <String>[
                  displayDate(nullableStringValue(data, 'claim_date')),
                  _nestedEmployeeName(data),
                  _paymentSubtitle(data),
                ].where((String s) => s.isNotEmpty).join(' · '),
                selected: selected,
                onTap: () async {
                  final id = intValue(data, 'id');
                  if (id == null) {
                    return;
                  }
                  setState(() {
                    _selectedListRow = item;
                    _isNewClaim = false;
                  });
                  await _hydrateEditorFromClaimId(id);
                },
              );
            },
          ),
        ],
      ),
      editor: _editorLoading
          ? const AppLoadingView(message: 'Loading claim…')
          : _buildEditor(),
    );
  }

  Widget _buildEditor() {
    if (_companyId == null) {
      return const Text('Select a company to edit expense claims.');
    }

    final status = _editorStatus();
    final reimbursementVoucherId = _editorSnapshot != null
        ? intValue(_editorSnapshot!, 'reimbursement_voucher_id')
        : (_selectedListRow == null
              ? null
              : intValue(
                  _selectedListRow!.toJson(),
                  'reimbursement_voucher_id',
                ));
    final showReimburse =
        _canViewAllClaims && status == 'approved' && reimbursementVoucherId == null;
    final isDraft = status == null || status == 'draft';
    final isApplied = status == 'applied';
    final showSaveDraft = _isSelfServiceUser && _editorEditable && isDraft;
    final showApply = _isSelfServiceUser && _editorEditable && isDraft;
    final showCancelDraft =
        _isSelfServiceUser && !_isNewClaim && _editingClaimId != null && status == 'draft';
    final showDelete =
        _canViewAllClaims &&
        !_isNewClaim &&
        _editingClaimId != null &&
        (status == 'draft' || status == 'applied');

    // Workflow actions stay outside [Form] so approve/reimburse never interact with
    // form validation scope; avoids unmount/remount jank when syncing after approve.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Form(
          key: _expenseClaimFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          if (_formError != null) ...[
            AppErrorStateView.inline(message: _formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          if (status != null && status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: Text(
                'Status: ${_claimStatusLabel(status)}'
                '${status == 'approved' && reimbursementVoucherId == null ? ' (unpaid)' : ''}'
                '${status == 'reimbursed' ? ' (paid)' : ''}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          SettingsFormWrap(
            children: [
              if (_employeeFieldReadOnly)
                AppFormTextField(
                  key: ValueKey<String>(
                    'emp-readonly-$_formGeneration-${_employeeId ?? 0}',
                  ),
                  initialValue: _editorEmployeeLabel(),
                  labelText: 'Employee',
                  readOnly: true,
                  validator: Validators.required('Employee'),
                )
              else
                AppDropdownField<int>.fromMapped(
                  key: ValueKey<String>(
                    'emp-$_formGeneration-${_employeeId ?? 0}',
                  ),
                  labelText: 'Employee',
                  mappedItems: _employeesForEditor
                      .map(
                        (e) => AppDropdownItem<int>(
                          value: e.id!,
                          label: e.toString(),
                        ),
                      )
                      .toList(),
                  initialValue: _employeeId,
                  onChanged: _editorEditable
                      ? (v) => setState(() => _employeeId = v)
                      : (_) {},
                  validator: Validators.requiredSelection('Employee'),
                ),
              AppFormTextField(
                controller: _claimNoCtrl,
                labelText: 'Claim no. (optional)',
                readOnly: !_editorEditable,
              ),
              AppFormTextField(
                controller: _claimDateCtrl,
                labelText: 'Claim date',
                readOnly: !_editorEditable,
                keyboardType: TextInputType.datetime,
                inputFormatters: const [DateInputFormatter()],
                validator: Validators.compose([
                  Validators.required('Claim date'),
                  Validators.date('Claim date'),
                ]),
              ),
              AppFormTextField(
                controller: _notesCtrl,
                labelText: 'Notes (optional)',
                readOnly: !_editorEditable,
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _editorEditable
                  ? () {
                      setState(() {
                        _lineEditors.add(
                          _ExpenseLineEditors(
                            expenseDate: TextEditingController(
                              text: displayDate(
                                DateTime.now().toIso8601String(),
                              ),
                            ),
                            category: TextEditingController(),
                            description: TextEditingController(),
                            amount: TextEditingController(),
                            remarks: TextEditingController(),
                          ),
                        );
                      });
                    }
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Add line'),
            ),
          ),
          ...List<Widget>.generate(_lineEditors.length, (int i) {
            final line = _lineEditors[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Line ${i + 1}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        if (_editorEditable && _lineEditors.length > 1)
                          IconButton(
                            tooltip: 'Remove line',
                            onPressed: () {
                              setState(() {
                                _lineEditors[i].dispose();
                                _lineEditors.removeAt(i);
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    AppFormTextField(
                      controller: line.expenseDate,
                      labelText: 'Expense date',
                      readOnly: !_editorEditable,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [DateInputFormatter()],
                      validator: Validators.compose([
                        Validators.required('Expense date'),
                        Validators.date('Expense date'),
                      ]),
                    ),
                    AppFormTextField(
                      controller: line.category,
                      labelText: 'Category',
                      readOnly: !_editorEditable,
                      validator: Validators.required('Category'),
                    ),
                    AppFormTextField(
                      controller: line.description,
                      labelText: 'Description',
                      readOnly: !_editorEditable,
                      validator: Validators.required('Description'),
                    ),
                    AppFormTextField(
                      controller: line.amount,
                      labelText: 'Amount',
                      readOnly: !_editorEditable,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.compose([
                        Validators.required('Amount'),
                        (String? v) {
                          final t = v?.trim() ?? '';
                          final d = double.tryParse(t);
                          if (d == null) {
                            return 'Amount must be a valid number';
                          }
                          if (d <= 0) {
                            return 'Amount must be greater than zero';
                          }
                          return null;
                        },
                      ]),
                    ),
                    AppFormTextField(
                      controller: line.remarks,
                      labelText: 'Remarks (optional)',
                      readOnly: !_editorEditable,
                    ),
                  ],
                ),
              ),
            );
          }),
              const SizedBox(height: AppUiConstants.spacingMd),
            ],
          ),
        ),
        if (showSaveDraft) ...[
          FilledButton(
            onPressed: _saving
                ? null
                : () {
                    _submitClaim(applyNow: false);
                  },
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save draft'),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
        ],
        if (showApply) ...[
          FilledButton.tonal(
            onPressed: _saving
                ? null
                : () {
                    _submitClaim(applyNow: true);
                  },
            child: const Text('Apply'),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
        ],
        if (!_isNewClaim && _editingClaimId != null) ...[
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              if (_canViewAllClaims && isApplied) ...[
                FilledButton.tonal(
                  onPressed: () async {
                    final int id = _editingClaimId!;
                    try {
                      final res = await _hr.approveExpenseClaim(
                        id,
                        ExpenseClaimModel(<String, dynamic>{}),
                      );
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(content: Text(res.message)),
                      );
                      if (res.success == true) {
                        await _reloadEditorAndListAfterMutation(claimId: id);
                      } else {
                        setState(() => _formError = res.message);
                      }
                    } on ApiException catch (e) {
                      if (!mounted) {
                        return;
                      }
                      setState(() => _formError = e.message);
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(content: Text(e.displayMessage)),
                      );
                    }
                  },
                  child: const Text('Approve'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    final int id = _editingClaimId!;
                    await openExpenseClaimRejectDialog(
                      context,
                      hr: _hr,
                      claimId: id,
                      onChanged: () => _reloadEditorAndListAfterMutation(claimId: id),
                    );
                  },
                  child: const Text('Reject'),
                ),
              ],
              if (showCancelDraft) ...[
                FilledButton.tonal(
                  onPressed: () async {
                    await openExpenseClaimCancelDialog(
                      context,
                      hr: _hr,
                      claimId: _editingClaimId!,
                      onChanged: () => _loadPage(),
                    );
                  },
                  child: const Text('Cancel draft'),
                ),
              ],
              if (showDelete)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete claim'),
                        content: Text(
                          status == 'applied'
                              ? 'Delete this applied expense claim?'
                              : 'Delete this draft expense claim?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Back'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true || !mounted) {
                      return;
                    }
                    final del = await _hr.deleteExpenseClaim(_editingClaimId!);
                    if (!mounted) {
                      return;
                    }
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(content: Text(del.message)),
                    );
                    if (del.success == true) {
                      await _loadPage();
                    }
                  },
                  child: const Text('Delete'),
                ),
              if (showReimburse)
                FilledButton(
                  onPressed: () async {
                    final int id = _editingClaimId!;
                    await openExpenseClaimReimburseDialog(
                      context,
                      hr: _hr,
                      accountsService: _accounts,
                      companyId: _companyId!,
                      claimId: id,
                      onChanged: () =>
                          _reloadEditorAndListAfterMutation(claimId: id),
                    );
                  },
                  child: const Text('Reimburse'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
