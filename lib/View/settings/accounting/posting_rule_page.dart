import '../../../screen.dart';

class PostingRuleManagementPage extends StatefulWidget {
  const PostingRuleManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PostingRuleManagementPage> createState() =>
      _PostingRuleManagementPageState();
}

class _PostingRuleManagementPageState extends State<PostingRuleManagementPage> {
  static const List<AppDropdownItem<String>> _entrySideItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'debit', label: 'Debit'),
        AppDropdownItem(value: 'credit', label: 'Credit'),
      ];

  static const List<AppDropdownItem<String>> _accountSourceItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'fixed_account', label: 'Fixed account'),
        AppDropdownItem(
          value: 'customer_control_account',
          label: 'Customer control',
        ),
        AppDropdownItem(
          value: 'supplier_control_account',
          label: 'Supplier control',
        ),
        AppDropdownItem(value: 'item_sales_account', label: 'Item sales'),
        AppDropdownItem(
          value: 'item_purchase_account',
          label: 'Item purchase',
        ),
        AppDropdownItem(
          value: 'tax_output_cgst_account',
          label: 'Tax output CGST',
        ),
        AppDropdownItem(
          value: 'tax_output_sgst_account',
          label: 'Tax output SGST',
        ),
        AppDropdownItem(
          value: 'tax_output_igst_account',
          label: 'Tax output IGST',
        ),
        AppDropdownItem(
          value: 'tax_input_cgst_account',
          label: 'Tax input CGST',
        ),
        AppDropdownItem(
          value: 'tax_input_sgst_account',
          label: 'Tax input SGST',
        ),
        AppDropdownItem(
          value: 'tax_input_igst_account',
          label: 'Tax input IGST',
        ),
        AppDropdownItem(value: 'cash_bank_account', label: 'Cash / bank'),
        AppDropdownItem(value: 'round_off_account', label: 'Round off'),
        AppDropdownItem(value: 'discount_account', label: 'Discount'),
        AppDropdownItem(value: 'returns_account', label: 'Returns'),
        AppDropdownItem(value: 'stock_account', label: 'Stock'),
        AppDropdownItem(value: 'cogs_account', label: 'COGS'),
      ];

  static const List<AppDropdownItem<String>> _amountSourceItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'subtotal', label: 'Subtotal'),
        AppDropdownItem(value: 'discount_amount', label: 'Discount'),
        AppDropdownItem(value: 'taxable_amount', label: 'Taxable'),
        AppDropdownItem(value: 'cgst_amount', label: 'CGST'),
        AppDropdownItem(value: 'sgst_amount', label: 'SGST'),
        AppDropdownItem(value: 'igst_amount', label: 'IGST'),
        AppDropdownItem(value: 'cess_amount', label: 'Cess'),
        AppDropdownItem(value: 'round_off_amount', label: 'Round off'),
        AppDropdownItem(value: 'total_amount', label: 'Total'),
        AppDropdownItem(value: 'paid_amount', label: 'Paid'),
        AppDropdownItem(value: 'balance_amount', label: 'Balance'),
        AppDropdownItem(value: 'stock_value', label: 'Stock value'),
        AppDropdownItem(value: 'cogs_value', label: 'COGS value'),
      ];

  final AccountsService _accountsService = AccountsService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _lineNoController = TextEditingController(
    text: '1',
  );
  final TextEditingController _narrationTemplateController =
      TextEditingController();
  final TextEditingController _priorityController = TextEditingController(
    text: '1',
  );

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<PostingRuleGroupModel> _groups = const <PostingRuleGroupModel>[];
  List<PostingRuleModel> _rows = const <PostingRuleModel>[];
  List<PostingRuleModel> _filtered = const <PostingRuleModel>[];
  PostingRuleModel? _selected;
  List<AccountModel> _accounts = const <AccountModel>[];

  int? _groupId;
  String _entrySide = 'debit';
  String _accountSourceType = 'fixed_account';
  int? _fixedAccountId;
  String _amountSource = 'total_amount';
  bool _isActive = true;

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
    _lineNoController.dispose();
    _narrationTemplateController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _json(PostingRuleModel? m) =>
      m?.data ?? const <String, dynamic>{};

  Future<void> _load({int? selectId}) async {
    setState(() {
      _initialLoading = _rows.isEmpty && _groups.isEmpty;
      _pageError = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _accountsService.postingRuleGroupsAll(
          filters: const {'sort_by': 'group_name', 'per_page': 500},
        ),
        _accountsService.postingRules(
          filters: const {'per_page': 500, 'sort_by': 'line_no'},
        ),
        _accountsService.accountsAll(filters: const {'sort_by': 'account_name'}),
      ]);
      final groups =
          (results[0] as ApiResponse<List<PostingRuleGroupModel>>).data ??
          const <PostingRuleGroupModel>[];
      final rules =
          (results[1] as PaginatedResponse<PostingRuleModel>).data ??
          const <PostingRuleModel>[];
      final accounts =
          (results[2] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _rows = rules;
        _filtered = _filter(rules, _searchController.text);
        _accounts = accounts.where((a) => a.isActive).toList();
        _initialLoading = false;
        if (_groupId == null && groups.isNotEmpty) {
          _groupId = intValue(groups.first.data, 'id');
        }
      });

      final selected = selectId != null
          ? rules.cast<PostingRuleModel?>().firstWhere(
              (e) => intValue(_json(e), 'id') == selectId,
              orElse: () => null,
            )
          : (_selected == null
                ? (rules.isNotEmpty ? rules.first : null)
                : rules.cast<PostingRuleModel?>().firstWhere(
                    (e) =>
                        intValue(_json(e), 'id') ==
                        intValue(_json(_selected), 'id'),
                    orElse: () => rules.isNotEmpty ? rules.first : null,
                  ));
      if (selected != null) {
        _applySelection(selected);
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

  List<PostingRuleModel> _filter(List<PostingRuleModel> source, String q) {
    return filterMasterList(source, q, (item) {
      final d = item.data;
      return [
        stringValue(d, 'entry_side'),
        stringValue(d, 'account_source_type'),
        stringValue(d, 'amount_source'),
      ];
    });
  }

  void _applySearch() {
    setState(() => _filtered = _filter(_rows, _searchController.text));
  }

  void _applySelection(PostingRuleModel item) {
    final d = item.data;
    _selected = item;
    _groupId = intValue(d, 'posting_rule_group_id');
    _lineNoController.text = stringValue(d, 'line_no', '1');
    _entrySide = stringValue(d, 'entry_side', 'debit');
    _accountSourceType = stringValue(d, 'account_source_type', 'fixed_account');
    _fixedAccountId = intValue(d, 'fixed_account_id');
    _amountSource = stringValue(d, 'amount_source', 'total_amount');
    _narrationTemplateController.text = stringValue(d, 'narration_template');
    _priorityController.text = stringValue(d, 'priority_order', '1');
    _isActive = boolValue(d, 'is_active', fallback: true);
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selected = null;
    _lineNoController.text = '1';
    _entrySide = 'debit';
    _accountSourceType = 'fixed_account';
    _fixedAccountId = null;
    _amountSource = 'total_amount';
    _narrationTemplateController.clear();
    _priorityController.text = '1';
    _isActive = true;
    if (_groups.isNotEmpty) {
      _groupId = intValue(_groups.first.data, 'id');
    }
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_groupId == null) {
      setState(() => _formError = 'Select a posting rule group.');
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final lineNo = int.tryParse(_lineNoController.text.trim()) ?? 1;
    final priority = int.tryParse(_priorityController.text.trim()) ?? 1;
    final body = PostingRuleModel.fromJson(<String, dynamic>{
      'posting_rule_group_id': _groupId,
      'line_no': lineNo,
      'entry_side': _entrySide,
      'account_source_type': _accountSourceType,
      'fixed_account_id': _accountSourceType == 'fixed_account'
          ? _fixedAccountId
          : null,
      'amount_source': _amountSource,
      'narration_template': nullIfEmpty(_narrationTemplateController.text),
      'priority_order': priority,
      'is_active': _isActive,
    });
    try {
      final ApiResponse<PostingRuleModel> response;
      final sid = intValue(_json(_selected), 'id');
      if (sid == null) {
        response = await _accountsService.createPostingRule(body);
      } else {
        response = await _accountsService.updatePostingRule(sid, body);
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
      final response = await _accountsService.deletePostingRule(id);
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
        icon: Icons.rule_folder_outlined,
        label: 'New Rule',
      ),
    ];
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Posting Rules',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading posting rules...');
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
      title: 'Posting Rules',
      editorTitle: intValue(_json(_selected), 'id') == null
          ? null
          : 'Line ${_lineNoController.text}',
      scrollController: _pageScrollController,
      list: SettingsListCard<PostingRuleModel>(
        searchController: _searchController,
        searchHint: 'Search rules',
        items: _filtered,
        selectedItem: _selected,
        emptyMessage: 'No posting rules.',
        itemBuilder: (item, selected) {
          final d = item.data;
          return SettingsListTile(
            title:
                'L${stringValue(d, 'line_no')} · ${stringValue(d, 'entry_side')} · ${stringValue(d, 'amount_source')}',
            subtitle: stringValue(d, 'account_source_type'),
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
                  labelText: 'Rule group',
                  mappedItems: _groups
                      .map(
                        (g) => AppDropdownItem<int>(
                          value: intValue(g.data, 'id') ?? 0,
                          label: stringValue(g.data, 'group_name').isEmpty
                              ? stringValue(g.data, 'group_code')
                              : stringValue(g.data, 'group_name'),
                        ),
                      )
                      .where((e) => e.value != 0)
                      .toList(growable: false),
                  initialValue: _groupId,
                  onChanged: (v) => setState(() => _groupId = v),
                  validator: Validators.requiredSelection('Rule group'),
                ),
                AppFormTextField(
                  labelText: 'Line no.',
                  controller: _lineNoController,
                  keyboardType: TextInputType.number,
                  validator: Validators.compose([
                    Validators.required('Line no.'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Entry side',
                  mappedItems: _entrySideItems,
                  initialValue: _entrySide,
                  onChanged: (v) => setState(() => _entrySide = v ?? 'debit'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Account source',
                  mappedItems: _accountSourceItems,
                  initialValue: _accountSourceType,
                  onChanged: (v) => setState(
                    () => _accountSourceType = v ?? 'fixed_account',
                  ),
                ),
                if (_accountSourceType == 'fixed_account')
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Fixed ledger',
                    mappedItems: _accounts
                        .where((a) => a.id != null)
                        .map(
                          (a) => AppDropdownItem<int>(
                            value: a.id!,
                            label: a.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: _fixedAccountId,
                    onChanged: (v) => setState(() => _fixedAccountId = v),
                    validator: _accountSourceType == 'fixed_account'
                        ? Validators.requiredSelection('Fixed ledger')
                        : null,
                  ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Amount source',
                  mappedItems: _amountSourceItems,
                  initialValue: _amountSource,
                  onChanged: (v) =>
                      setState(() => _amountSource = v ?? 'total_amount'),
                ),
                AppFormTextField(
                  labelText: 'Narration template',
                  controller: _narrationTemplateController,
                  maxLines: 2,
                  validator: Validators.optionalMaxLength(500, 'Narration'),
                ),
                AppFormTextField(
                  labelText: 'Priority',
                  controller: _priorityController,
                  keyboardType: TextInputType.number,
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
