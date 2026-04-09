import '../../../screen.dart';

class VoucherTypeManagementPage extends StatefulWidget {
  const VoucherTypeManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<VoucherTypeManagementPage> createState() =>
      _VoucherTypeManagementPageState();
}

class _VoucherTypeManagementPageState extends State<VoucherTypeManagementPage> {
  static const List<AppDropdownItem<String>> _categoryItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'payment', label: 'Payment'),
        AppDropdownItem(value: 'receipt', label: 'Receipt'),
        AppDropdownItem(value: 'journal', label: 'Journal'),
        AppDropdownItem(value: 'contra', label: 'Contra'),
        AppDropdownItem(value: 'sales', label: 'Sales'),
        AppDropdownItem(value: 'purchase', label: 'Purchase'),
        AppDropdownItem(value: 'credit_note', label: 'Credit Note'),
        AppDropdownItem(value: 'debit_note', label: 'Debit Note'),
        AppDropdownItem(value: 'opening', label: 'Opening'),
        AppDropdownItem(value: 'adjustment', label: 'Adjustment'),
      ];

  final AccountsService _accountsService = AccountsService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _documentTypeController =
      TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<VoucherTypeModel> _types = const <VoucherTypeModel>[];
  List<VoucherTypeModel> _filteredTypes = const <VoucherTypeModel>[];
  VoucherTypeModel? _selectedType;
  String _voucherCategory = 'journal';
  bool _autoPost = true;
  bool _requiresApproval = false;
  bool _allowsReferenceAllocation = true;
  bool _isSystemType = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadTypes();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _documentTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes({int? selectId}) async {
    setState(() {
      _initialLoading = _types.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _accountsService.voucherTypes(
        filters: const {'per_page': 300, 'sort_by': 'name'},
      );
      final items = response.data ?? const <VoucherTypeModel>[];
      if (!mounted) return;

      setState(() {
        _types = items;
        _filteredTypes = _filterTypes(items, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<VoucherTypeModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedType == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<VoucherTypeModel?>().firstWhere(
                    (item) => item?.id == _selectedType?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectType(selected);
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

  List<VoucherTypeModel> _filterTypes(
    List<VoucherTypeModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [
        item.code ?? '',
        item.name ?? '',
        item.voucherCategory ?? '',
        item.documentType ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredTypes = _filterTypes(_types, _searchController.text);
    });
  }

  void _selectType(VoucherTypeModel item) {
    _selectedType = item;
    _codeController.text = item.code ?? '';
    _nameController.text = item.name ?? '';
    _documentTypeController.text = item.documentType ?? '';
    _voucherCategory = item.voucherCategory ?? 'journal';
    _autoPost = item.autoPost;
    _requiresApproval = item.requiresApproval;
    _allowsReferenceAllocation = item.allowsReferenceAllocation;
    _isSystemType = item.isSystemType;
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedType = null;
    _codeController.clear();
    _nameController.clear();
    _documentTypeController.clear();
    _voucherCategory = 'journal';
    _autoPost = true;
    _requiresApproval = false;
    _allowsReferenceAllocation = true;
    _isSystemType = false;
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = VoucherTypeModel(
      id: _selectedType?.id,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      voucherCategory: _voucherCategory,
      documentType: nullIfEmpty(_documentTypeController.text),
      autoPost: _autoPost,
      requiresApproval: _requiresApproval,
      allowsReferenceAllocation: _allowsReferenceAllocation,
      isSystemType: _isSystemType,
      isActive: _isActive,
    );

    try {
      final response = _selectedType == null
          ? await _accountsService.createVoucherType(model)
          : await _accountsService.updateVoucherType(_selectedType!.id!, model);
      final saved = response.data;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadTypes(selectId: saved?.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = _selectedType?.id;
    if (id == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _accountsService.deleteVoucherType(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadTypes();
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
        icon: Icons.receipt_outlined,
        label: 'New Type',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Voucher Types',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading voucher types...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load voucher types',
        message: _pageError!,
        onRetry: _loadTypes,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Voucher Types',
      editorTitle: _selectedType?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<VoucherTypeModel>(
        searchController: _searchController,
        searchHint: 'Search voucher types',
        items: _filteredTypes,
        selectedItem: _selectedType,
        emptyMessage: 'No voucher types found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.name ?? '',
          subtitle: [
            item.code ?? '',
            item.voucherCategory ?? '',
            if ((item.documentType ?? '').isNotEmpty) item.documentType!,
          ].join(' · '),
          selected: selected,
          onTap: () => _selectType(item),
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
                    labelText: 'Code',
                    controller: _codeController,
                    validator: Validators.compose([
                      Validators.required('Code'),
                      Validators.optionalMaxLength(50, 'Code'),
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Name',
                    controller: _nameController,
                    validator: Validators.compose([
                      Validators.required('Name'),
                      Validators.optionalMaxLength(100, 'Name'),
                    ]),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Voucher Category',
                    mappedItems: _categoryItems,
                    initialValue: _voucherCategory,
                    onChanged: (value) => setState(
                      () => _voucherCategory = value ?? 'journal',
                    ),
                    validator: Validators.requiredSelection('Voucher Category'),
                  ),
                  AppFormTextField(
                    labelText: 'Document Type',
                    controller: _documentTypeController,
                    validator: Validators.optionalMaxLength(50, 'Document Type'),
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
                      label: 'Auto Post',
                      value: _autoPost,
                      onChanged: (value) => setState(() => _autoPost = value),
                    ),
                  ),
                  SizedBox(
                    width: AppUiConstants.switchFieldWidth,
                    child: AppSwitchTile(
                      label: 'Requires Approval',
                      value: _requiresApproval,
                      onChanged: (value) =>
                          setState(() => _requiresApproval = value),
                    ),
                  ),
                  SizedBox(
                    width: AppUiConstants.switchFieldWidth,
                    child: AppSwitchTile(
                      label: 'Reference Allocation',
                      value: _allowsReferenceAllocation,
                      onChanged: (value) => setState(
                        () => _allowsReferenceAllocation = value,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: AppUiConstants.switchFieldWidth,
                    child: AppSwitchTile(
                      label: 'System Type',
                      value: _isSystemType,
                      onChanged: (value) =>
                          setState(() => _isSystemType = value),
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
                    label: _selectedType == null ? 'Save Type' : 'Update Type',
                    onPressed: _save,
                    busy: _saving,
                  ),
                  if (_selectedType?.id != null)
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
