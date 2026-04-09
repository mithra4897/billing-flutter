import '../../../screen.dart';

class AccountGroupManagementPage extends StatefulWidget {
  const AccountGroupManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AccountGroupManagementPage> createState() =>
      _AccountGroupManagementPageState();
}

class _AccountGroupManagementPageState extends State<AccountGroupManagementPage> {
  static const List<AppDropdownItem<String>> _natureItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'asset', label: 'Asset'),
        AppDropdownItem(value: 'liability', label: 'Liability'),
        AppDropdownItem(value: 'income', label: 'Income'),
        AppDropdownItem(value: 'expense', label: 'Expense'),
        AppDropdownItem(value: 'equity', label: 'Equity'),
      ];

  static const List<AppDropdownItem<String>> _categoryItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'cash_bank', label: 'Cash / Bank'),
        AppDropdownItem(value: 'receivable', label: 'Receivable'),
        AppDropdownItem(value: 'payable', label: 'Payable'),
        AppDropdownItem(value: 'stock', label: 'Stock'),
        AppDropdownItem(value: 'tax', label: 'Tax'),
        AppDropdownItem(value: 'sales', label: 'Sales'),
        AppDropdownItem(value: 'purchase', label: 'Purchase'),
        AppDropdownItem(value: 'direct_income', label: 'Direct Income'),
        AppDropdownItem(value: 'direct_expense', label: 'Direct Expense'),
        AppDropdownItem(value: 'indirect_income', label: 'Indirect Income'),
        AppDropdownItem(value: 'indirect_expense', label: 'Indirect Expense'),
        AppDropdownItem(value: 'fixed_asset', label: 'Fixed Asset'),
        AppDropdownItem(value: 'current_asset', label: 'Current Asset'),
        AppDropdownItem(
          value: 'current_liability',
          label: 'Current Liability',
        ),
        AppDropdownItem(
          value: 'long_term_liability',
          label: 'Long Term Liability',
        ),
        AppDropdownItem(value: 'equity', label: 'Equity'),
        AppDropdownItem(value: 'other', label: 'Other'),
      ];

  final AccountsService _accountsService = AccountsService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _groupCodeController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<AccountGroupModel> _groups = const <AccountGroupModel>[];
  List<AccountGroupModel> _filteredGroups = const <AccountGroupModel>[];
  AccountGroupModel? _selectedGroup;
  int? _parentGroupId;
  String _groupNature = 'asset';
  String _groupCategory = 'other';
  bool _affectsProfitLoss = true;
  bool _isSystemGroup = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadGroups();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _groupCodeController.dispose();
    _groupNameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups({int? selectId}) async {
    setState(() {
      _initialLoading = _groups.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _accountsService.accountGroups(
        filters: const {'per_page': 300, 'sort_by': 'group_name'},
      );
      final items = response.data ?? const <AccountGroupModel>[];
      if (!mounted) return;

      setState(() {
        _groups = items;
        _filteredGroups = _filterGroups(items, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<AccountGroupModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedGroup == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<AccountGroupModel?>().firstWhere(
                    (item) => item?.id == _selectedGroup?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectGroup(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  List<AccountGroupModel> _filterGroups(
    List<AccountGroupModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [
        item.groupCode ?? '',
        item.groupName ?? '',
        item.groupNature ?? '',
        item.groupCategory ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredGroups = _filterGroups(_groups, _searchController.text);
    });
  }

  List<AccountGroupModel> get _parentOptions {
    final selectedId = _selectedGroup?.id;
    return _groups
        .where((item) => item.id != null && item.id != selectedId)
        .toList(growable: false);
  }

  void _selectGroup(AccountGroupModel item) {
    _selectedGroup = item;
    _groupCodeController.text = item.groupCode ?? '';
    _groupNameController.text = item.groupName ?? '';
    _parentGroupId = item.parentGroupId;
    _groupNature = item.groupNature ?? 'asset';
    _groupCategory = item.groupCategory ?? 'other';
    _affectsProfitLoss = item.affectsProfitLoss;
    _isSystemGroup = item.isSystemGroup;
    _isActive = item.isActive;
    _remarksController.text = item.remarks ?? '';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedGroup = null;
    _groupCodeController.clear();
    _groupNameController.clear();
    _parentGroupId = null;
    _groupNature = 'asset';
    _groupCategory = 'other';
    _affectsProfitLoss = true;
    _isSystemGroup = false;
    _isActive = true;
    _remarksController.clear();
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = AccountGroupModel(
      id: _selectedGroup?.id,
      groupCode: _groupCodeController.text.trim(),
      groupName: _groupNameController.text.trim(),
      parentGroupId: _parentGroupId,
      groupNature: _groupNature,
      groupCategory: _groupCategory,
      affectsProfitLoss: _affectsProfitLoss,
      isSystemGroup: _isSystemGroup,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedGroup == null
          ? await _accountsService.createAccountGroup(model)
          : await _accountsService.updateAccountGroup(_selectedGroup!.id!, model);
      final saved = response.data;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadGroups(selectId: saved?.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = _selectedGroup?.id;
    if (id == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _accountsService.deleteAccountGroup(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadGroups();
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
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
        icon: Icons.account_tree_outlined,
        label: 'New Group',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Account Groups',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading account groups...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load account groups',
        message: _pageError!,
        onRetry: _loadGroups,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Account Groups',
      editorTitle: _selectedGroup?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<AccountGroupModel>(
        searchController: _searchController,
        searchHint: 'Search account groups',
        items: _filteredGroups,
        selectedItem: _selectedGroup,
        emptyMessage: 'No account groups found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.groupName ?? '',
          subtitle: [
            item.groupCode ?? '',
            item.groupNature ?? '',
            if ((item.groupCategory ?? '').isNotEmpty) item.groupCategory!,
          ].join(' · '),
          selected: selected,
          onTap: () => _selectGroup(item),
        ),
      ),
      editor: AppSectionCard(
        child: Form(
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
                  AppFormTextField(
                    labelText: 'Group Code',
                    controller: _groupCodeController,
                    validator: Validators.compose([
                      Validators.required('Group Code'),
                      Validators.optionalMaxLength(50, 'Group Code'),
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Group Name',
                    controller: _groupNameController,
                    validator: Validators.compose([
                      Validators.required('Group Name'),
                      Validators.optionalMaxLength(150, 'Group Name'),
                    ]),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Parent Group',
                    mappedItems: _parentOptions
                        .where((item) => item.id != null)
                        .map(
                          (item) => AppDropdownItem<int>(
                            value: item.id!,
                            label: item.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: _parentGroupId,
                    onChanged: (value) => setState(() => _parentGroupId = value),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Group Nature',
                    mappedItems: _natureItems,
                    initialValue: _groupNature,
                    onChanged: (value) =>
                        setState(() => _groupNature = value ?? 'asset'),
                    validator: Validators.requiredSelection('Group Nature'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Group Category',
                    mappedItems: _categoryItems,
                    initialValue: _groupCategory,
                    onChanged: (value) =>
                        setState(() => _groupCategory = value ?? 'other'),
                  ),
                  AppFormTextField(
                    labelText: 'Remarks',
                    controller: _remarksController,
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Wrap(
                spacing: AppUiConstants.spacingMd,
                runSpacing: AppUiConstants.spacingSm,
                children: [
                  SizedBox(
                    width: AppUiConstants.switchFieldWidth,
                    child: AppSwitchTile(
                      label: 'Affects P&L',
                      value: _affectsProfitLoss,
                      onChanged: (value) =>
                          setState(() => _affectsProfitLoss = value),
                    ),
                  ),
                  SizedBox(
                    width: AppUiConstants.switchFieldWidth,
                    child: AppSwitchTile(
                      label: 'System Group',
                      value: _isSystemGroup,
                      onChanged: (value) =>
                          setState(() => _isSystemGroup = value),
                    ),
                  ),
                  SizedBox(
                    width: AppUiConstants.switchFieldWidth,
                    child: AppSwitchTile(
                      label: 'Active',
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
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
                    label: _selectedGroup == null ? 'Save Group' : 'Update Group',
                    onPressed: _save,
                    busy: _saving,
                  ),
                  if (_selectedGroup?.id != null)
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
      ),
    );
  }
}
