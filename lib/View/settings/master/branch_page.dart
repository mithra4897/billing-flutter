import '../../../screen.dart';
import 'business_location_page.dart';
import 'warehouse_page.dart';

class BranchManagementPage extends StatefulWidget {
  const BranchManagementPage({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
  });

  final bool embedded;
  final int initialTabIndex;

  @override
  State<BranchManagementPage> createState() => _BranchManagementPageState();
}

class _BranchManagementPageState extends State<BranchManagementPage>
    with SingleTickerProviderStateMixin {
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<BranchModel> _branches = const <BranchModel>[];
  List<BranchModel> _filteredBranches = const <BranchModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  BranchModel? _selectedBranch;
  int? _contextCompanyId;
  int? _companyId;
  String _branchType = 'branch_office';
  bool _isHeadOffice = false;
  bool _isActive = true;
  late final TabController _tabController;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialTabIndex >= 0 &&
        widget.initialTabIndex < _tabController.length) {
      _tabController.index = widget.initialTabIndex;
    }
    _activeTabIndex = _tabController.index;
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) {
        return;
      }
      _activeTabIndex = _tabController.index;
      setState(() {});
    });
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _branches.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait([
        _masterService.branches(
          filters: const {'per_page': 100, 'sort_by': 'name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);

      final branches =
          responses[0].data as List<BranchModel>? ?? const <BranchModel>[];
      final companies =
          responses[1].data as List<CompanyModel>? ?? const <CompanyModel>[];
      final activeCompanies = companies
          .where((company) => company.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _branches = branches;
        _companies = activeCompanies;
        _contextCompanyId = contextSelection.companyId;
        _filteredBranches = _filterBranches(branches);
        _initialLoading = false;
      });

      final visibleBranches = _filterBranches(branches);
      final selected = selectId != null
          ? visibleBranches.cast<BranchModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedBranch == null
                ? (visibleBranches.isNotEmpty ? visibleBranches.first : null)
                : visibleBranches.cast<BranchModel?>().firstWhere(
                    (item) => item?.id == _selectedBranch?.id,
                    orElse: () => visibleBranches.isNotEmpty
                        ? visibleBranches.first
                        : null,
                  ));

      if (selected != null) {
        _selectBranch(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _filteredBranches = _filterBranches(_branches);
    });
  }

  List<BranchModel> _filterBranches(List<BranchModel> items) {
    final scoped = items
        .where(
          (branch) =>
              _contextCompanyId == null || branch.companyId == _contextCompanyId,
        )
        .toList(growable: false);

    return filterMasterList(scoped, _searchController.text, (branch) {
      return [branch.code ?? '', branch.name ?? ''];
    });
  }

  void _selectBranch(BranchModel branch) {
    _selectedBranch = branch;
    _companyId = branch.companyId;
    _setCode(branch.code ?? '', autoGenerated: false);
    _nameController.text = branch.name ?? '';
    _branchType = branch.branchType ?? 'branch_office';
    _isHeadOffice = branch.isHeadOffice;
    _isActive = branch.isActive;
    _remarksController.text = branch.remarks ?? '';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedBranch = null;
    _companyId =
        _contextCompanyId ?? (_companies.isNotEmpty ? _companies.first.id : null);
    _setCode('', autoGenerated: true);
    _nameController.clear();
    _branchType = 'branch_office';
    _isHeadOffice = false;
    _isActive = true;
    _remarksController.clear();
    _formError = null;
    setState(() {});
    _primeCodeSuggestion();
  }

  bool get _isNewBranch => _selectedBranch?.id == null;

  String _branchTypeCode() {
    switch (_branchType) {
      case 'head_office':
        return 'HO';
      case 'factory':
        return 'FAC';
      case 'warehouse_office':
        return 'WHO';
      case 'retail_outlet':
        return 'RTL';
      case 'service_center':
        return 'SVC';
      case 'other':
        return 'OTH';
      case 'branch_office':
      default:
        return 'BR';
    }
  }

  String _generateBranchCode() {
    if (_companyId == null) {
      return '';
    }

    final prefix = _branchTypeCode();
    final pattern = RegExp('^${RegExp.escape(prefix)}/(\\d+)\$');
    var nextNumber = 1;

    for (final branch in _branches.where(
      (item) => item.companyId == _companyId,
    )) {
      final match = pattern.firstMatch(
        (branch.code ?? '').trim().toUpperCase(),
      );
      if (match == null) {
        continue;
      }

      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value >= nextNumber) {
        nextNumber = value + 1;
      }
    }

    return '$prefix/${nextNumber.toString().padLeft(5, '0')}';
  }

  void _setCode(String value, {bool autoGenerated = false}) {
    _codeController.value = _codeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _primeCodeSuggestion() {
    if (!_isNewBranch || _companyId == null) {
      return;
    }

    final code = _generateBranchCode();
    if (code.trim().isNotEmpty) {
      _setCode(code.trim(), autoGenerated: true);
      setState(() {});
    }
  }

  void _refreshAutoGeneratedCode() {
    if (!_isNewBranch) {
      return;
    }

    _setCode('', autoGenerated: true);
    _primeCodeSuggestion();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = BranchModel(
      id: _selectedBranch?.id,
      companyId: _companyId,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      branchType: _branchType,
      isHeadOffice: _isHeadOffice,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedBranch == null
          ? await _masterService.createBranch(model)
          : await _masterService.updateBranch(_selectedBranch!.id!, model);
      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved.id);
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _startNewBranch() {
    _resetForm();

    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = [
      AdaptiveShellActionButton(
        onPressed: _startNewBranch,
        icon: Icons.add,
        label: 'New Branch',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Branches',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading branches...');
    }
    if (_pageError != null) {
      return Center(child: Text(_pageError!));
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Branches',
      editorTitle: _selectedBranch?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<BranchModel>(
        searchController: _searchController,
        searchHint: 'Search branches',
        items: _filteredBranches,
        selectedItem: _selectedBranch,
        emptyMessage: 'No branches found.',
        itemBuilder: (branch, selected) => SettingsListTile(
          title: branch.name ?? '',
          subtitle: [
            branch.code ?? '',
            companyNameById(_companies, branch.companyId),
            branch.branchType?.replaceAll('_', ' ') ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: SettingsStatusPill(
            label: branch.isActive ? 'Active' : 'Inactive',
            active: branch.isActive,
          ),
          onTap: () => _selectBranch(branch),
        ),
      ),
      editor: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Primary'),
                  Tab(text: 'Branch Location'),
                  Tab(text: 'Warehouse'),
                ],
              ),
              const SizedBox(height: 20),
              IndexedStack(
                index: _activeTabIndex,
                children: [
                  _buildPrimaryTab(context),
                  _selectedBranch?.id == null
                      ? _buildDependentTabPlaceholder(
                          title: 'Branch Location',
                          message:
                              'Select an existing branch or save this branch first to manage business locations.',
                        )
                      : BusinessLocationManagementPage(
                          key: ValueKey<String>(
                            'branch-location-${_selectedBranch!.id}',
                          ),
                          embedded: true,
                          fixedCompanyId: _selectedBranch!.companyId,
                          fixedBranchId: _selectedBranch!.id,
                        ),
                  _selectedBranch?.id == null
                      ? _buildDependentTabPlaceholder(
                          title: 'Warehouse',
                          message:
                              'Select an existing branch or save this branch first to manage warehouses.',
                        )
                      : WarehouseManagementPage(
                          key: ValueKey<String>(
                            'branch-warehouse-${_selectedBranch!.id}',
                          ),
                          embedded: true,
                          fixedCompanyId: _selectedBranch!.companyId,
                          fixedBranchId: _selectedBranch!.id,
                        ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryTab(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsFormWrap(
            children: [
              AppDropdownField<int>.fromMapped(
                labelText: 'Company',
                initialValue: _companyId,
                mappedItems: _companies
                    .where((company) => company.id != null)
                    .map(
                      (company) => AppDropdownItem<int>(
                        value: company.id!,
                        label: company.legalName ?? '',
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() => _companyId = value);
                  _refreshAutoGeneratedCode();
                },
                validator: (value) =>
                    value == null ? 'Company is required' : null,
              ),
              AppFormTextField(
                controller: _codeController,
                labelText: 'Code',
                readOnly: true,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Code is required'
                    : null,
              ),
              AppFormTextField(
                controller: _nameController,
                labelText: 'Name',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              AppDropdownField<String>.fromMapped(
                initialValue: _branchType,
                labelText: 'Branch Type',
                mappedItems: const [
                  AppDropdownItem(value: 'head_office', label: 'Head Office'),
                  AppDropdownItem(
                    value: 'branch_office',
                    label: 'Branch Office',
                  ),
                  AppDropdownItem(value: 'factory', label: 'Factory'),
                  AppDropdownItem(
                    value: 'warehouse_office',
                    label: 'Warehouse Office',
                  ),
                  AppDropdownItem(
                    value: 'retail_outlet',
                    label: 'Retail Outlet',
                  ),
                  AppDropdownItem(
                    value: 'service_center',
                    label: 'Service Center',
                  ),
                  AppDropdownItem(value: 'other', label: 'Other'),
                ],
                onChanged: (value) {
                  setState(() => _branchType = value ?? _branchType);
                  _refreshAutoGeneratedCode();
                },
              ),
            ],
          ),
          AppSwitchTile(
            label: 'Head Office',
            subtitle: 'Mark only one branch per company as head office.',
            value: _isHeadOffice,
            onChanged: (value) => setState(() => _isHeadOffice = value),
          ),
          AppSwitchTile(
            label: 'Active',
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
          ),
          const SizedBox(height: 8),
          AppFormTextField(
            controller: _remarksController,
            maxLines: 3,
            labelText: 'Remarks',
          ),
          if ((_formError ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _formError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              AppActionButton(
                onPressed: _saving ? null : _save,
                icon: _selectedBranch == null ? Icons.add : Icons.save,
                label: _saving ? 'Saving...' : 'Save Branch',
                busy: _saving,
              ),
              AppActionButton(
                onPressed: _saving ? null : _resetForm,
                icon: Icons.refresh,
                label: 'Reset',
                filled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDependentTabPlaceholder({
    required String title,
    required String message,
  }) {
    return SettingsEmptyState(
      icon: Icons.link_outlined,
      title: title,
      message: message,
      minHeight: 240,
    );
  }
}
