import '../../screen.dart';
import '../purchase/purchase_support.dart';
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
  final st = stringValue(d, 'claim_status');
  final rid = intValue(d, 'reimbursement_voucher_id');
  if (st == 'approved' && rid == null) {
    return 'Unpaid · ${stringValue(d, 'total_amount')}';
  }
  if (st == 'reimbursed') {
    return 'Paid · ${stringValue(d, 'total_amount')}';
  }
  return '${stringValue(d, 'claim_status')} · ${stringValue(d, 'total_amount')}';
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
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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

  bool _canApprove = false;
  bool _canUpdateHr = false;
  bool _canDelete = false;

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
    AppDropdownItem<String?>(value: 'draft', label: 'Draft'),
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
    _loadPermissions();
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

  Future<void> _loadPermissions() async {
    final codes = await SessionStorage.getPermissionCodes();
    final user = await SessionStorage.getCurrentUser();
    if (!mounted) {
      return;
    }
    final superAdmin =
        user?['is_super_admin'] == true || user?['is_super_admin'] == 1;
    setState(() {
      _canApprove = superAdmin || codes.contains('hr.approve');
      _canUpdateHr = superAdmin || codes.contains('hr.update');
      _canDelete = superAdmin || codes.contains('hr.delete');
    });
  }

  void _disposeLineEditors() {
    for (final e in _lineEditors) {
      e.dispose();
    }
    _lineEditors = <_ExpenseLineEditors>[];
  }

  List<ExpenseClaimModel> get _filteredRows {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      return _rows;
    }
    return _rows
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
    if (_canViewAllClaims) {
      return base;
    }
    if (_linkedEmployeeId == null) {
      return base;
    }
    return base
        .where((e) => e.id == _linkedEmployeeId)
        .toList(growable: false);
  }

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
          ctx['can_view_all_claims'] == true || ctx['can_view_all_claims'] == 1;
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

  Future<void> _hydrateEditorFromClaimId(int id) async {
    if (_companyId == null) {
      return;
    }
    setState(() {
      _editorLoading = true;
      _formError = null;
      _isNewClaim = false;
      _editingClaimId = id;
    });

    final res = await _hr.expenseClaim(id);
    if (!mounted) {
      return;
    }

    if (res.success != true || res.data == null) {
      setState(() {
        _editorLoading = false;
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
      _editorLoading = false;
    });
  }

  Future<void> _saveDraft() async {
    if (_companyId == null) {
      return;
    }
    if (_formKey.currentState?.validate() != true) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
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
      return stringValue(_editorSnapshot!, 'claim_status');
    }
    final row = _selectedListRow?.toJson();
    if (row == null) {
      return null;
    }
    return stringValue(row, 'claim_status');
  }

  bool get _editorEditable {
    final st = _editorStatus();
    return st == null || st == 'draft';
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
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
          if (_canViewAllClaims) ...[
            AppDropdownField<int?>.fromMapped(
              labelText: 'Employee filter',
              mappedItems: <AppDropdownItem<int?>>[
                const AppDropdownItem<int?>(value: null, label: 'All employees'),
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
              onChanged: (v) {
                setState(() => _filterEmployeeId = v);
                _loadPage();
              },
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          AppDropdownField<String?>.fromMapped(
            labelText: 'Payment',
            mappedItems: _paymentFilterItems,
            initialValue: _filterPaymentStatus,
            onChanged: (v) {
              setState(() => _filterPaymentStatus = v);
              _loadPage();
            },
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          AppDropdownField<String?>.fromMapped(
            labelText: 'Status',
            mappedItems: _statusFilterItems,
            initialValue: _filterClaimStatus,
            onChanged: (v) {
              setState(() => _filterClaimStatus = v);
              _loadPage();
            },
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<ExpenseClaimModel>(
            searchController: _searchController,
            searchHint: 'Search claims…',
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
    final reimbId = _editorSnapshot != null
        ? intValue(_editorSnapshot!, 'reimbursement_voucher_id')
        : (_selectedListRow == null
              ? null
              : intValue(
                  _selectedListRow!.toJson(),
                  'reimbursement_voucher_id',
                ));
    final showReimburse =
        status == 'approved' && reimbId == null && _canUpdateHr;
    final showSaveDraft =
        _editorEditable && (_isNewClaim || status == 'draft' || status == null);

    return Form(
      key: _formKey,
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
                'Status: $status'
                '${status == 'approved' && reimbId == null ? ' (unpaid)' : ''}'
                '${status == 'reimbursed' ? ' (paid)' : ''}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          SettingsFormWrap(
            children: [
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
          if (showSaveDraft) ...[
            FilledButton(
              onPressed: _saving ? null : _saveDraft,
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
          if (!_isNewClaim && _editingClaimId != null) ...[
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (status == 'draft' && _canApprove) ...[
                  FilledButton.tonal(
                    onPressed: () async {
                      final res = await _hr.approveExpenseClaim(
                        _editingClaimId!,
                        ExpenseClaimModel(<String, dynamic>{}),
                      );
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res.message)),
                      );
                      if (res.success == true) {
                        await _loadPage(selectClaimId: _editingClaimId);
                      }
                    },
                    child: const Text('Approve'),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      await openExpenseClaimRejectDialog(
                        context,
                        hr: _hr,
                        claimId: _editingClaimId!,
                        onChanged: () => _loadPage(selectClaimId: _editingClaimId),
                      );
                    },
                    child: const Text('Reject'),
                  ),
                ],
                if (status == 'draft' && _canUpdateHr) ...[
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
                if (status == 'draft' && _canDelete)
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
                          content: const Text(
                            'Delete this draft expense claim?',
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
                      ScaffoldMessenger.of(context).showSnackBar(
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
                      await openExpenseClaimReimburseDialog(
                        context,
                        hr: _hr,
                        accountsService: _accounts,
                        companyId: _companyId!,
                        claimId: _editingClaimId!,
                        onChanged: () =>
                            _loadPage(selectClaimId: _editingClaimId),
                      );
                    },
                    child: const Text('Reimburse'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
