import '../../../screen.dart';

class _DocumentPostingLineDraft {
  _DocumentPostingLineDraft({
    this.lineNo,
    this.accountId,
    this.entrySide = 'debit',
    String? amount,
    String? narration,
  }) : amountController = TextEditingController(text: amount ?? ''),
       narrationController = TextEditingController(text: narration ?? '');

  int? lineNo;
  int? accountId;
  String entrySide;
  final TextEditingController amountController;
  final TextEditingController narrationController;

  void dispose() {
    amountController.dispose();
    narrationController.dispose();
  }
}

class DocumentPostingManagementPage extends StatefulWidget {
  const DocumentPostingManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DocumentPostingManagementPage> createState() =>
      _DocumentPostingManagementPageState();
}

class _DocumentPostingManagementPageState
    extends State<DocumentPostingManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'reversed', label: 'Reversed'),
        AppDropdownItem(value: 'failed', label: 'Failed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  static const List<AppDropdownItem<String>> _entryItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'debit', label: 'Debit'),
        AppDropdownItem(value: 'credit', label: 'Credit'),
      ];

  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _moduleController = TextEditingController();
  final TextEditingController _tableController = TextEditingController();
  final TextEditingController _documentIdController = TextEditingController();
  final TextEditingController _documentNoController = TextEditingController();
  final TextEditingController _documentDateController =
      TextEditingController();
  final TextEditingController _voucherIdController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<DocumentPostingModel> _rows = const <DocumentPostingModel>[];
  List<DocumentPostingModel> _filtered = const <DocumentPostingModel>[];
  DocumentPostingModel? _selected;

  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _years = const <FinancialYearModel>[];
  List<PostingRuleGroupModel> _groups = const <PostingRuleGroupModel>[];
  List<AccountModel> _accounts = const <AccountModel>[];

  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _postingRuleGroupId;
  String _postingStatus = 'pending';
  List<_DocumentPostingLineDraft> _lines =
      <_DocumentPostingLineDraft>[_DocumentPostingLineDraft()];

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
    _moduleController.dispose();
    _tableController.dispose();
    _documentIdController.dispose();
    _documentNoController.dispose();
    _documentDateController.dispose();
    _voucherIdController.dispose();
    _remarksController.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _json(DocumentPostingModel? m) =>
      m?.data ?? const <String, dynamic>{};

  List<BranchModel> get _branchOptions => _branches
      .where(
        (b) =>
            b.isActive &&
            (_companyId == null || b.companyId == null || b.companyId == _companyId),
      )
      .toList(growable: false);

  List<BusinessLocationModel> get _locationOptions => _locations
      .where(
        (loc) =>
            loc.isActive &&
            (_branchId == null ||
                loc.branchId == null ||
                loc.branchId == _branchId),
      )
      .toList(growable: false);

  Future<void> _load({int? selectId}) async {
    setState(() {
      _initialLoading = _rows.isEmpty;
      _pageError = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 500, 'sort_by': 'name'},
        ),
        _masterService.businessLocations(
          filters: const {'per_page': 500, 'sort_by': 'name'},
        ),
        _masterService.financialYears(
          filters: const {'per_page': 100, 'sort_by': 'fy_name'},
        ),
        _accountsService.postingRuleGroupsAll(
          filters: const {'sort_by': 'group_name', 'per_page': 200},
        ),
        _accountsService.accountsAll(filters: const {'sort_by': 'account_name'}),
      ]);

      final companies =
          (results[0] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (results[1] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final locations =
          (results[2] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final years =
          (results[3] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      final groups =
          (results[4] as ApiResponse<List<PostingRuleGroupModel>>).data ??
          const <PostingRuleGroupModel>[];
      final accounts =
          (results[5] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];

      final activeCompanies =
          companies.where((c) => c.isActive).toList(growable: false);
      final activeBranches =
          branches.where((b) => b.isActive).toList(growable: false);
      final activeLocations =
          locations.where((l) => l.isActive).toList(growable: false);
      final activeYears =
          years.where((y) => y.isActive).toList(growable: false);

      final ctx = await WorkingContextService.instance.resolveSelection(
        companies: activeCompanies,
        branches: activeBranches,
        locations: activeLocations,
        financialYears: activeYears,
      );

      final postings = await _accountsService.documentPostings(
        filters: <String, dynamic>{
          'per_page': 200,
          'sort_by': 'document_date',
          if (ctx.companyId != null) 'company_id': ctx.companyId,
        },
      );

      if (!mounted) return;
      setState(() {
        _companies = activeCompanies;
        _branches = activeBranches;
        _locations = activeLocations;
        _years = activeYears;
        _companyId ??= ctx.companyId;
        _branchId ??= ctx.branchId;
        _locationId ??= ctx.locationId;
        _financialYearId ??= ctx.financialYearId;
        _groups = groups;
        _accounts = accounts.where((a) => a.isActive).toList();
        _rows = postings.data ?? const <DocumentPostingModel>[];
        _filtered = _filter(_rows, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? _rows.cast<DocumentPostingModel?>().firstWhere(
              (e) => intValue(_json(e), 'id') == selectId,
              orElse: () => null,
            )
          : (_selected == null
                ? (_rows.isNotEmpty ? _rows.first : null)
                : _rows.cast<DocumentPostingModel?>().firstWhere(
                    (e) =>
                        intValue(_json(e), 'id') ==
                        intValue(_json(_selected), 'id'),
                    orElse: () => _rows.isNotEmpty ? _rows.first : null,
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

  List<DocumentPostingModel> _filter(
    List<DocumentPostingModel> source,
    String q,
  ) {
    return filterMasterList(source, q, (item) {
      final d = item.data;
      return [
        stringValue(d, 'document_module'),
        stringValue(d, 'document_table'),
        stringValue(d, 'document_no'),
        stringValue(d, 'posting_status'),
      ];
    });
  }

  void _applySearch() {
    setState(() => _filtered = _filter(_rows, _searchController.text));
  }

  Future<void> _applySelection(DocumentPostingModel item) async {
    final id = intValue(_json(item), 'id');
    if (id == null) return;
    try {
      final response = await _accountsService.documentPosting(id);
      final full = response.data ?? item;
      final d = full.data;
      for (final l in _lines) {
        l.dispose();
      }
      final rawLines =
          (d['lines'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(growable: false);
      _selected = full;
      _companyId = intValue(d, 'company_id');
      _branchId = intValue(d, 'branch_id');
      _locationId = intValue(d, 'location_id');
      _financialYearId = intValue(d, 'financial_year_id');
      _moduleController.text = stringValue(d, 'document_module');
      _tableController.text = stringValue(d, 'document_table');
      _documentIdController.text = stringValue(d, 'document_id');
      _documentNoController.text = stringValue(d, 'document_no');
      _documentDateController.text =
          (d['document_date'] ?? '').toString().split('T').first.split(' ').first;
      _postingRuleGroupId = intValue(d, 'posting_rule_group_id');
      _voucherIdController.text = stringValue(d, 'voucher_id');
      _postingStatus = stringValue(d, 'posting_status', 'pending');
      _remarksController.text = stringValue(d, 'remarks');
      _lines = rawLines.isEmpty
          ? <_DocumentPostingLineDraft>[_DocumentPostingLineDraft()]
          : rawLines
                .map(
                  (m) => _DocumentPostingLineDraft(
                    lineNo: intValue(m, 'line_no'),
                    accountId: intValue(m, 'account_id'),
                    entrySide: stringValue(m, 'entry_side', 'debit'),
                    amount: stringValue(m, 'amount'),
                    narration: stringValue(m, 'narration'),
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
    _moduleController.clear();
    _tableController.clear();
    _documentIdController.clear();
    _documentNoController.clear();
    _documentDateController.text =
        DateTime.now().toIso8601String().split('T').first;
    _postingRuleGroupId = null;
    _voucherIdController.clear();
    _postingStatus = 'pending';
    _remarksController.clear();
    _lines = <_DocumentPostingLineDraft>[_DocumentPostingLineDraft()];
    _formError = null;
    setState(() {});
  }

  void _addLine() {
    setState(() {
      _lines = List<_DocumentPostingLineDraft>.from(_lines)
        ..add(_DocumentPostingLineDraft());
    });
  }

  void _removeLine(int i) {
    setState(() {
      _lines[i].dispose();
      _lines = List<_DocumentPostingLineDraft>.from(_lines)..removeAt(i);
      if (_lines.isEmpty) {
        _lines.add(_DocumentPostingLineDraft());
      }
    });
  }

  Map<String, dynamic> _payload() {
    final lines = <Map<String, dynamic>>[];
    var idx = 1;
    for (final l in _lines) {
      final amt = double.tryParse(l.amountController.text.trim()) ?? 0;
      if (l.accountId == null || amt <= 0) continue;
      lines.add(<String, dynamic>{
        'line_no': l.lineNo ?? idx,
        'account_id': l.accountId,
        'entry_side': l.entrySide,
        'amount': amt,
        'narration': nullIfEmpty(l.narrationController.text),
      });
      idx++;
    }
    final voucherRaw = _voucherIdController.text.trim();
    final voucherId = int.tryParse(voucherRaw);
    return <String, dynamic>{
      'company_id': _companyId,
      'branch_id': _branchId,
      'location_id': _locationId,
      'financial_year_id': _financialYearId,
      'document_module': _moduleController.text.trim(),
      'document_table': _tableController.text.trim(),
      'document_id': int.tryParse(_documentIdController.text.trim()) ?? 0,
      'document_no': nullIfEmpty(_documentNoController.text),
      'document_date': _documentDateController.text.trim(),
      'posting_rule_group_id': _postingRuleGroupId,
      if (voucherRaw.isNotEmpty && voucherId != null) 'voucher_id': voucherId,
      'posting_status': _postingStatus,
      'remarks': nullIfEmpty(_remarksController.text),
      'lines': lines,
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_companyId == null ||
        _branchId == null ||
        _locationId == null ||
        _financialYearId == null) {
      setState(() => _formError = 'Company, branch, location and year required.');
      return;
    }
    final docId = int.tryParse(_documentIdController.text.trim());
    if (docId == null || docId < 1) {
      setState(() => _formError = 'Document ID must be a positive integer.');
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final body = DocumentPostingModel.fromJson(_payload());
    try {
      final ApiResponse<DocumentPostingModel> response;
      final sid = intValue(_json(_selected), 'id');
      if (sid == null) {
        response = await _accountsService.createDocumentPosting(body);
      } else {
        response = await _accountsService.updateDocumentPosting(sid, body);
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
      final response = await _accountsService.deleteDocumentPosting(id);
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
        icon: Icons.post_add_outlined,
        label: 'New Posting',
      ),
    ];
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Document Postings',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading document postings...');
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
      title: 'Document Postings',
      editorTitle: stringValue(_json(_selected), 'document_no').isEmpty
          ? null
          : stringValue(_json(_selected), 'document_no'),
      scrollController: _pageScrollController,
      list: SettingsListCard<DocumentPostingModel>(
        searchController: _searchController,
        searchHint: 'Search postings',
        items: _filtered,
        selectedItem: _selected,
        emptyMessage: 'No document postings.',
        itemBuilder: (item, selected) {
          final d = item.data;
          return SettingsListTile(
            title:
                '${stringValue(d, 'document_module')}.${stringValue(d, 'document_table')} #${stringValue(d, 'document_id')}',
            subtitle: [
              stringValue(d, 'document_no'),
              stringValue(d, 'posting_status'),
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
            Text(
              'For advanced setup and testing. Most postings are created by the system from operational documents.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
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
                  onChanged: (v) => setState(() {
                    _companyId = v;
                    _branchId = null;
                    _locationId = null;
                  }),
                  validator: Validators.requiredSelection('Company'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Branch',
                  mappedItems: _branchOptions
                      .where((b) => b.id != null)
                      .map(
                        (b) => AppDropdownItem<int>(
                          value: b.id!,
                          label: b.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _branchId,
                  onChanged: (v) => setState(() {
                    _branchId = v;
                    _locationId = null;
                  }),
                  validator: Validators.requiredSelection('Branch'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Location',
                  mappedItems: _locationOptions
                      .where((l) => l.id != null)
                      .map(
                        (l) => AppDropdownItem<int>(
                          value: l.id!,
                          label: l.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _locationId,
                  onChanged: (v) => setState(() => _locationId = v),
                  validator: Validators.requiredSelection('Location'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Financial year',
                  mappedItems: _years
                      .where((y) => y.id != null)
                      .map(
                        (y) => AppDropdownItem<int>(
                          value: y.id!,
                          label: y.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _financialYearId,
                  onChanged: (v) => setState(() => _financialYearId = v),
                  validator: Validators.requiredSelection('Financial year'),
                ),
                AppFormTextField(
                  labelText: 'Document module',
                  controller: _moduleController,
                  validator: Validators.compose([
                    Validators.required('Module'),
                    Validators.optionalMaxLength(50, 'Module'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Document table',
                  controller: _tableController,
                  validator: Validators.compose([
                    Validators.required('Table'),
                    Validators.optionalMaxLength(100, 'Table'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Document ID',
                  controller: _documentIdController,
                  keyboardType: TextInputType.number,
                  validator: Validators.required('Document ID'),
                ),
                AppFormTextField(
                  labelText: 'Document no. (optional)',
                  controller: _documentNoController,
                ),
                AppFormTextField(
                  labelText: 'Document date',
                  controller: _documentDateController,
                  validator: Validators.optionalDate('Document date'),
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Posting rule group (optional)',
                  mappedItems: <AppDropdownItem<int?>>[
                    const AppDropdownItem<int?>(value: null, label: 'None'),
                    ..._groups
                        .map(
                          (g) => AppDropdownItem<int?>(
                            value: intValue(g.data, 'id'),
                            label: stringValue(g.data, 'group_name').isEmpty
                                ? stringValue(g.data, 'group_code')
                                : stringValue(g.data, 'group_name'),
                          ),
                        )
                        .where((e) => e.value != null),
                  ],
                  initialValue: _postingRuleGroupId,
                  onChanged: (v) => setState(() => _postingRuleGroupId = v),
                ),
                AppFormTextField(
                  labelText: 'Voucher ID (optional)',
                  controller: _voucherIdController,
                  keyboardType: TextInputType.number,
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Posting status',
                  mappedItems: _statusItems,
                  initialValue: _postingStatus,
                  onChanged: (v) =>
                      setState(() => _postingStatus = v ?? 'pending'),
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: _remarksController,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Row(
              children: [
                Text(
                  'Lines (optional)',
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
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Side',
                        mappedItems: _entryItems,
                        initialValue: line.entrySide,
                        onChanged: (v) =>
                            setState(() => line.entrySide = v ?? 'debit'),
                      ),
                      AppFormTextField(
                        labelText: 'Amount',
                        controller: line.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Narration',
                        controller: line.narrationController,
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
                if (intValue(_json(_selected), 'id') != null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: _saving ? null : _delete,
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
