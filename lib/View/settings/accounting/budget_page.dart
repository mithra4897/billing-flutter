import '../../../screen.dart';

class BudgetManagementPage extends StatefulWidget {
  const BudgetManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetLineDraft {
  _BudgetLineDraft({
    this.accountId,
    String? amount,
    String? remarks,
  }) : amountController = TextEditingController(text: amount ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  int? accountId;
  final TextEditingController amountController;
  final TextEditingController remarksController;

  void dispose() {
    amountController.dispose();
    remarksController.dispose();
  }
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'closed', label: 'Closed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<BudgetModel> _rows = const <BudgetModel>[];
  List<BudgetModel> _filtered = const <BudgetModel>[];
  BudgetModel? _selected;
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<FinancialYearModel> _years = const <FinancialYearModel>[];
  List<AccountModel> _accounts = const <AccountModel>[];

  int? _companyId;
  int? _financialYearId;
  String _status = 'draft';
  bool _isActive = true;
  List<_BudgetLineDraft> _lines = <_BudgetLineDraft>[_BudgetLineDraft()];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _load();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _notesController.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _json(BudgetModel? m) => m?.data ?? const {};

  Future<void> _load({int? selectId}) async {
    setState(() {
      _initialLoading = _rows.isEmpty;
      _pageError = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _accountsService.budgets(
          filters: const {'per_page': 200, 'sort_by': 'budget_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _masterService.financialYears(
          filters: const {'per_page': 100, 'sort_by': 'fy_name'},
        ),
        _accountsService.accountsAll(filters: const {'sort_by': 'account_name'}),
      ]);
      final budgets =
          (results[0] as PaginatedResponse<BudgetModel>).data ??
          const <BudgetModel>[];
      final companies =
          (results[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final years =
          (results[2] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      final accounts =
          (results[3] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];
      final ctx = await WorkingContextService.instance.resolveSelection(
        companies: companies.where((c) => c.isActive).toList(growable: false),
        branches: const <BranchModel>[],
        locations: const <BusinessLocationModel>[],
        financialYears:
            years.where((y) => y.isActive).toList(growable: false),
      );
      if (!mounted) return;
      setState(() {
        _rows = budgets;
        _filtered = _filter(budgets, _searchController.text);
        _companies = companies.where((c) => c.isActive).toList();
        _years = years.where((y) => y.isActive).toList();
        _accounts = accounts.where((a) => a.isActive).toList();
        _companyId ??= ctx.companyId;
        _financialYearId ??= ctx.financialYearId;
        _initialLoading = false;
      });

      final selected = selectId != null
          ? budgets.cast<BudgetModel?>().firstWhere(
              (e) => intValue(_json(e), 'id') == selectId,
              orElse: () => null,
            )
          : (_selected == null
                ? (budgets.isNotEmpty ? budgets.first : null)
                : budgets.cast<BudgetModel?>().firstWhere(
                    (e) =>
                        intValue(_json(e), 'id') ==
                        intValue(_json(_selected), 'id'),
                    orElse: () => budgets.isNotEmpty ? budgets.first : null,
                  ));
      if (selected != null) {
        await _applySelection(selected);
      } else {
        _resetForm();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pageError = e.toString();
        _initialLoading = false;
      });
    }
  }

  List<BudgetModel> _filter(List<BudgetModel> source, String q) {
    return filterMasterList(source, q, (item) {
      final d = item.data;
      return [
        stringValue(d, 'budget_code'),
        stringValue(d, 'budget_name'),
        stringValue(d, 'budget_status'),
      ];
    });
  }

  void _applySearch() {
    setState(() => _filtered = _filter(_rows, _searchController.text));
  }

  Future<void> _applySelection(BudgetModel item) async {
    final id = intValue(_json(item), 'id');
    if (id == null) return;
    try {
      final response = await _accountsService.budget(id);
      final full = response.data ?? item;
      final d = full.data;
      for (final l in _lines) {
        l.dispose();
      }
      final lineMaps =
          (d['lines'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .map((raw) => Map<String, dynamic>.from(raw))
              .toList(growable: false);
      _selected = full;
      _companyId = intValue(d, 'company_id');
      _financialYearId = intValue(d, 'financial_year_id');
      _codeController.text = stringValue(d, 'budget_code');
      _nameController.text = stringValue(d, 'budget_name');
      _dateFromController.text =
          (d['date_from'] ?? '').toString().split('T').first.split(' ').first;
      _dateToController.text =
          (d['date_to'] ?? '').toString().split('T').first.split(' ').first;
      _status = stringValue(d, 'budget_status', 'draft');
      _notesController.text = stringValue(d, 'notes');
      _isActive = boolValue(d, 'is_active', fallback: true);
      _lines = lineMaps.isEmpty
          ? <_BudgetLineDraft>[_BudgetLineDraft()]
          : lineMaps
                .map(
                  (m) => _BudgetLineDraft(
                    accountId: intValue(m, 'account_id'),
                    amount: stringValue(m, 'budget_amount'),
                    remarks: stringValue(m, 'remarks'),
                  ),
                )
                .toList(growable: true);
      _formError = null;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _formError = e.toString());
    }
  }

  void _resetForm() {
    for (final l in _lines) {
      l.dispose();
    }
    _selected = null;
    _codeController.clear();
    _nameController.clear();
    _dateFromController.text =
        DateTime.now().toIso8601String().split('T').first;
    _dateToController.text = DateTime.now().toIso8601String().split('T').first;
    _status = 'draft';
    _notesController.clear();
    _isActive = true;
    _lines = <_BudgetLineDraft>[_BudgetLineDraft()];
    _formError = null;
    setState(() {});
  }

  void _addLine() {
    setState(() {
      _lines = List<_BudgetLineDraft>.from(_lines)..add(_BudgetLineDraft());
    });
  }

  void _removeLine(int i) {
    setState(() {
      _lines[i].dispose();
      _lines = List<_BudgetLineDraft>.from(_lines)..removeAt(i);
      if (_lines.isEmpty) {
        _lines.add(_BudgetLineDraft());
      }
    });
  }

  Map<String, dynamic> _payload() {
    final lines = <Map<String, dynamic>>[];
    for (final l in _lines) {
      final amt = double.tryParse(l.amountController.text.trim()) ?? 0;
      if (l.accountId == null || amt <= 0) continue;
      lines.add(<String, dynamic>{
        'account_id': l.accountId,
        'budget_amount': amt,
        'remarks': nullIfEmpty(l.remarksController.text),
      });
    }
    return <String, dynamic>{
      'company_id': _companyId,
      'financial_year_id': _financialYearId,
      'budget_code': _codeController.text.trim(),
      'budget_name': _nameController.text.trim(),
      'date_from': _dateFromController.text.trim(),
      'date_to': _dateToController.text.trim(),
      'budget_status': _status,
      'notes': nullIfEmpty(_notesController.text),
      'is_active': _isActive,
      'lines': lines,
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_companyId == null) {
      setState(() => _formError = 'Company is required.');
      return;
    }
    final lines = _payload()['lines'] as List;
    if (lines.isEmpty) {
      setState(() => _formError = 'Add at least one budget line with amount.');
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final body = BudgetModel.fromJson(_payload());
    try {
      final ApiResponse<BudgetModel> response;
      final sid = intValue(_json(_selected), 'id');
      if (sid == null) {
        response = await _accountsService.createBudget(body);
      } else {
        response = await _accountsService.updateBudget(sid, body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _load(selectId: intValue(_json(response.data), 'id') ?? sid);
    } catch (e) {
      if (mounted) setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = intValue(_json(_selected), 'id');
    if (id == null) return;
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      final response = await _accountsService.deleteBudget(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _load();
    } catch (e) {
      if (mounted) setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showBudgetVsActual() async {
    final id = intValue(_json(_selected), 'id');
    if (id == null) return;
    try {
      final response = await _accountsService.budgetVsActual(id);
      final data = response.data?.data ?? const <String, dynamic>{};
      if (!mounted) return;
      final summary = (data['summary'] as Map?) ?? {};
      final lineList = (data['lines'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return AlertDialog(
            title: const Text('Budget vs actual'),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Budget: ${summary['budget_amount']} · Actual: ${summary['actual_amount']} · Variance: ${summary['variance_amount']}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder.all(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                            ),
                            children: const [
                              _BudgetVsTh('Account'),
                              _BudgetVsTh('Budget'),
                              _BudgetVsTh('Actual'),
                              _BudgetVsTh('Var.'),
                              _BudgetVsTh('%'),
                            ],
                          ),
                          ...lineList.map(
                            (r) => TableRow(
                              children: [
                                _BudgetVsTd(
                                  '${r['account_code'] ?? ''} ${r['account_name'] ?? ''}',
                                ),
                                _BudgetVsTd('${r['budget_amount'] ?? ''}'),
                                _BudgetVsTd('${r['actual_amount'] ?? ''}'),
                                _BudgetVsTd('${r['variance_amount'] ?? ''}'),
                                _BudgetVsTd('${r['utilization_percent'] ?? ''}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _startNew() {
    _resetForm();
    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNew,
        icon: Icons.savings_outlined,
        label: 'New Budget',
      ),
    ];
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Budgets',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading budgets...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load',
        message: _pageError!,
        onRetry: _load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Budgets',
      editorTitle: stringValue(_json(_selected), 'budget_name').isEmpty
          ? null
          : stringValue(_json(_selected), 'budget_name'),
      scrollController: _pageScrollController,
      list: SettingsListCard<BudgetModel>(
        searchController: _searchController,
        searchHint: 'Search budgets',
        items: _filtered,
        selectedItem: _selected,
        emptyMessage: 'No budgets.',
        itemBuilder: (item, selected) {
          final d = item.data;
          return SettingsListTile(
            title: stringValue(d, 'budget_name'),
            subtitle: [
              stringValue(d, 'budget_code'),
              stringValue(d, 'budget_status'),
            ].join(' · '),
            selected: selected,
            onTap: () => _applySelection(item),
          );
        },
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
                  labelText: 'Company',
                  mappedItems: _companies
                      .where((c) => c.id != null)
                      .map(
                        (c) => AppDropdownItem<int>(
                          value: c.id!,
                          label: c.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _companyId,
                  onChanged: (v) => setState(() => _companyId = v),
                  validator: Validators.requiredSelection('Company'),
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Financial year (optional)',
                  mappedItems: <AppDropdownItem<int?>>[
                    const AppDropdownItem<int?>(
                      value: null,
                      label: 'None',
                    ),
                    ..._years
                        .where((y) => y.id != null)
                        .map(
                          (y) => AppDropdownItem<int?>(
                            value: y.id,
                            label: y.toString(),
                          ),
                        ),
                  ],
                  initialValue: _financialYearId,
                  onChanged: (v) => setState(() => _financialYearId = v),
                ),
                AppFormTextField(
                  labelText: 'Budget code',
                  controller: _codeController,
                  validator: Validators.compose([
                    Validators.required('Code'),
                    Validators.optionalMaxLength(100, 'Code'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Budget name',
                  controller: _nameController,
                  validator: Validators.compose([
                    Validators.required('Name'),
                    Validators.optionalMaxLength(255, 'Name'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Date from',
                  controller: _dateFromController,
                  validator: Validators.optionalDate('Date from'),
                ),
                AppFormTextField(
                  labelText: 'Date to',
                  controller: _dateToController,
                  validator: Validators.optionalDate('Date to'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Status',
                  mappedItems: _statusItems,
                  initialValue: _status,
                  onChanged: (v) => setState(() => _status = v ?? 'draft'),
                ),
                AppFormTextField(
                  labelText: 'Notes',
                  controller: _notesController,
                  maxLines: 3,
                ),
                SizedBox(
                  width: AppUiConstants.switchFieldWidth,
                  child: AppSwitchTile(
                    label: 'Active',
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Row(
              children: [
                Text(
                  'Budget lines',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add line',
                  onPressed: _addLine,
                  filled: false,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            ...List<Widget>.generate(_lines.length, (index) {
              final line = _lines[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Line ${index + 1}'),
                          const Spacer(),
                          IconButton(
                            onPressed: _lines.length == 1
                                ? null
                                : () => _removeLine(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Account',
                        mappedItems: _accounts
                            .where((a) => a.id != null)
                            .map(
                              (a) => AppDropdownItem<int>(
                                value: a.id!,
                                label: a.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.accountId,
                        onChanged: (v) => setState(() => line.accountId = v),
                        validator: Validators.requiredSelection('Account'),
                      ),
                      AppFormTextField(
                        labelText: 'Budget amount',
                        controller: line.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Amount'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Remarks',
                        controller: line.remarksController,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppUiConstants.spacingLg),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: intValue(_json(_selected), 'id') == null
                      ? 'Save'
                      : 'Update',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (intValue(_json(_selected), 'id') != null) ...[
                  AppActionButton(
                    icon: Icons.compare_arrows_outlined,
                    label: 'Vs actual',
                    onPressed: _saving ? null : _showBudgetVsActual,
                    filled: false,
                  ),
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: _saving ? null : _delete,
                    filled: false,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetVsTh extends StatelessWidget {
  const _BudgetVsTh(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BudgetVsTd extends StatelessWidget {
  const _BudgetVsTd(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

