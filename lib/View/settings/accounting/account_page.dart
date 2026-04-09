import '../../../screen.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  static const List<AppDropdownItem<String>> _accountTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'general', label: 'General'),
        AppDropdownItem(value: 'party', label: 'Party'),
        AppDropdownItem(value: 'cash', label: 'Cash'),
        AppDropdownItem(value: 'bank', label: 'Bank'),
        AppDropdownItem(value: 'tax', label: 'Tax'),
        AppDropdownItem(value: 'employee', label: 'Employee'),
        AppDropdownItem(value: 'customer', label: 'Customer'),
        AppDropdownItem(value: 'supplier', label: 'Supplier'),
        AppDropdownItem(value: 'job_worker', label: 'Job Worker'),
        AppDropdownItem(value: 'transporter', label: 'Transporter'),
      ];

  static const List<AppDropdownItem<String>> _openingBalanceTypeItems =
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
  final TextEditingController _accountCodeController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _openingBalanceController =
      TextEditingController();
  final TextEditingController _currencyCodeController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<AccountModel> _accounts = const <AccountModel>[];
  List<AccountModel> _filteredAccounts = const <AccountModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<AccountGroupModel> _groups = const <AccountGroupModel>[];
  AccountModel? _selectedAccount;
  int? _companyId;
  int? _branchId;
  int? _accountGroupId;
  String _accountType = 'general';
  String _openingBalanceType = 'debit';
  bool _allowManualEntries = true;
  bool _allowReconciliation = false;
  bool _isControlAccount = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadPage();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _accountCodeController.dispose();
    _accountNameController.dispose();
    _openingBalanceController.dispose();
    _currencyCodeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _accounts.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _accountsService.accounts(filters: const {'per_page': 300, 'sort_by': 'account_name'}),
        _masterService.companies(filters: const {'per_page': 200, 'sort_by': 'legal_name'}),
        _masterService.branches(filters: const {'per_page': 300, 'sort_by': 'name'}),
        _accountsService.accountGroupsAll(filters: const {'sort_by': 'group_name'}),
      ]);

      final accounts = (responses[0] as PaginatedResponse<AccountModel>).data ??
          const <AccountModel>[];
      final companies = (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches = (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final groups =
          (responses[3] as ApiResponse<List<AccountGroupModel>>).data ??
              const <AccountGroupModel>[];

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _filteredAccounts = _filterAccounts(accounts, _searchController.text);
        _companies = companies.where((item) => item.isActive).toList(growable: false);
        _branches = branches.where((item) => item.isActive).toList(growable: false);
        _groups = groups.where((item) => item.isActive).toList(growable: false);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? accounts.cast<AccountModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedAccount == null
                ? (accounts.isNotEmpty ? accounts.first : null)
                : accounts.cast<AccountModel?>().firstWhere(
                    (item) => item?.id == _selectedAccount?.id,
                    orElse: () => accounts.isNotEmpty ? accounts.first : null,
                  ));

      if (selected != null) {
        _selectAccount(selected);
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

  List<AccountModel> _filterAccounts(List<AccountModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [
        item.accountCode ?? '',
        item.accountName ?? '',
        item.accountType ?? '',
        item.accountGroupName ?? '',
        item.companyName ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredAccounts = _filterAccounts(_accounts, _searchController.text);
    });
  }

  List<BranchModel> get _branchOptions {
    if (_companyId == null) return _branches;
    return _branches
        .where((item) => item.companyId == null || item.companyId == _companyId)
        .toList(growable: false);
  }

  void _selectAccount(AccountModel item) {
    _selectedAccount = item;
    _companyId = item.companyId;
    _branchId = item.branchId;
    _accountCodeController.text = item.accountCode ?? '';
    _accountNameController.text = item.accountName ?? '';
    _accountGroupId = item.accountGroupId;
    _accountType = item.accountType ?? 'general';
    _openingBalanceController.text = item.openingBalance?.toString() ?? '';
    _openingBalanceType = item.openingBalanceType ?? 'debit';
    _currencyCodeController.text = item.currencyCode ?? 'INR';
    _allowManualEntries = item.allowManualEntries;
    _allowReconciliation = item.allowReconciliation;
    _isControlAccount = item.isControlAccount;
    _isActive = item.isActive;
    _remarksController.text = item.remarks ?? '';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedAccount = null;
    _companyId = _companies.isNotEmpty ? _companies.first.id : null;
    _branchId = null;
    _accountCodeController.clear();
    _accountNameController.clear();
    _accountGroupId = null;
    _accountType = 'general';
    _openingBalanceController.text = '0';
    _openingBalanceType = 'debit';
    _currencyCodeController.text = 'INR';
    _allowManualEntries = true;
    _allowReconciliation = false;
    _isControlAccount = false;
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

    final model = AccountModel(
      id: _selectedAccount?.id,
      companyId: _companyId,
      branchId: _branchId,
      accountCode: _accountCodeController.text.trim(),
      accountName: _accountNameController.text.trim(),
      accountGroupId: _accountGroupId,
      accountType: _accountType,
      openingBalance:
          double.tryParse(_openingBalanceController.text.trim()) ?? 0,
      openingBalanceType: _openingBalanceType,
      currencyCode: _currencyCodeController.text.trim(),
      allowManualEntries: _allowManualEntries,
      allowReconciliation: _allowReconciliation,
      isControlAccount: _isControlAccount,
      isSystemAccount: _selectedAccount?.isSystemAccount ?? false,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedAccount == null
          ? await _accountsService.createAccount(model)
          : await _accountsService.updateAccount(_selectedAccount!.id!, model);
      final saved = response.data;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: saved?.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = _selectedAccount?.id;
    if (id == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _accountsService.deleteAccount(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage();
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
        icon: Icons.account_balance_outlined,
        label: 'New Account',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Accounts',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading accounts...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load accounts',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Accounts',
      editorTitle: _selectedAccount?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<AccountModel>(
        searchController: _searchController,
        searchHint: 'Search accounts',
        items: _filteredAccounts,
        selectedItem: _selectedAccount,
        emptyMessage: 'No accounts found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.accountName ?? '',
          subtitle: [
            item.accountCode ?? '',
            item.accountType ?? '',
            if ((item.accountGroupName ?? '').isNotEmpty) item.accountGroupName!,
          ].join(' · '),
          detail: item.companyName ?? '',
          selected: selected,
          onTap: () => _selectAccount(item),
        ),
      ),
      editor: AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use this screen for ledger creation and structure. Party-to-ledger mapping is maintained in the Parties screen under Party Accounts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).extension<AppThemeExtension>()!.mutedText,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Form(
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
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem<int>(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: _companyId,
                        onChanged: (value) {
                          setState(() {
                            _companyId = value;
                            if (!_branchOptions.any((item) => item.id == _branchId)) {
                              _branchId = null;
                            }
                          });
                        },
                        validator: Validators.requiredSelection('Company'),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Branch',
                        mappedItems: _branchOptions
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem<int>(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: _branchId,
                        onChanged: (value) => setState(() => _branchId = value),
                      ),
                      AppFormTextField(
                        labelText: 'Account Code',
                        controller: _accountCodeController,
                        validator: Validators.compose([
                          Validators.required('Account Code'),
                          Validators.optionalMaxLength(50, 'Account Code'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Account Name',
                        controller: _accountNameController,
                        validator: Validators.compose([
                          Validators.required('Account Name'),
                          Validators.optionalMaxLength(255, 'Account Name'),
                        ]),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Account Group',
                        mappedItems: _groups
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem<int>(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: _accountGroupId,
                        onChanged: (value) =>
                            setState(() => _accountGroupId = value),
                        validator: Validators.requiredSelection('Account Group'),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Account Type',
                        mappedItems: _accountTypeItems,
                        initialValue: _accountType,
                        onChanged: (value) => setState(
                          () => _accountType = value ?? 'general',
                        ),
                        validator: Validators.requiredSelection('Account Type'),
                      ),
                      AppFormTextField(
                        labelText: 'Opening Balance',
                        controller: _openingBalanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Opening Balance',
                        ),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Opening Balance Type',
                        mappedItems: _openingBalanceTypeItems,
                        initialValue: _openingBalanceType,
                        onChanged: (value) => setState(
                          () => _openingBalanceType = value ?? 'debit',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Currency Code',
                        controller: _currencyCodeController,
                        validator: Validators.compose([
                          Validators.required('Currency Code'),
                          Validators.optionalMaxLength(10, 'Currency Code'),
                        ]),
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
                          label: 'Allow Manual Entries',
                          value: _allowManualEntries,
                          onChanged: (value) =>
                              setState(() => _allowManualEntries = value),
                        ),
                      ),
                      SizedBox(
                        width: AppUiConstants.switchFieldWidth,
                        child: AppSwitchTile(
                          label: 'Allow Reconciliation',
                          value: _allowReconciliation,
                          onChanged: (value) =>
                              setState(() => _allowReconciliation = value),
                        ),
                      ),
                      SizedBox(
                        width: AppUiConstants.switchFieldWidth,
                        child: AppSwitchTile(
                          label: 'Control Account',
                          value: _isControlAccount,
                          onChanged: (value) =>
                              setState(() => _isControlAccount = value),
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
                        label: _selectedAccount == null
                            ? 'Save Account'
                            : 'Update Account',
                        onPressed: _save,
                        busy: _saving,
                      ),
                      if (_selectedAccount?.id != null)
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
          ],
        ),
      ),
    );
  }
}
