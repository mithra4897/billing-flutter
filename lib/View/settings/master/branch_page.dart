import 'dart:async' show unawaited;

import '../../../screen.dart';
import 'business_location_page.dart';
import 'warehouse_page.dart';
import '../tax/gst_registration_page.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> _loadData({int? selectId, int? companyIdHint}) async {
    setState(() {
      _initialLoading = _branches.isEmpty;
      _pageError = null;
    });

    try {
      final companiesResponse = await _masterService.companies(
        filters: const {'per_page': 100, 'sort_by': 'legal_name'},
      );
      final companies =
          companiesResponse.data ?? const <CompanyModel>[];
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

      final filterCompanyId =
          companyIdHint ?? contextSelection.companyId;
      final branchFilters = <String, dynamic>{
        'per_page': 500,
        'sort_by': 'name',
      };
      if (filterCompanyId != null) {
        branchFilters['company_id'] = filterCompanyId;
      }

      final branchesResponse = await _masterService.branches(
        filters: branchFilters,
      );
      List<BranchModel> branches =
          branchesResponse.data ?? const <BranchModel>[];

      BranchModel? selectTarget;
      if (selectId != null) {
        for (final b in branches) {
          if (b.id == selectId) {
            selectTarget = b;
            break;
          }
        }
        if (selectTarget == null) {
          try {
            final detailResp = await _masterService.branch(selectId);
            final detail = detailResp.data;
            if (!mounted) {
              return;
            }
            if (detail != null) {
              branches = [...branches, detail];
              selectTarget = detail;
            }
          } catch (_) {}
        }
      }
      final resolvedContextCompanyId = selectTarget?.companyId ??
          companyIdHint ??
          contextSelection.companyId;

      if (!mounted) {
        return;
      }

      setState(() {
        _branches = branches;
        _companies = activeCompanies;
        _contextCompanyId = resolvedContextCompanyId;
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
              _contextCompanyId == null ||
              branch.companyId == _contextCompanyId,
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
        _contextCompanyId ??
        (_companies.isNotEmpty ? _companies.first.id : null);
    _setCode('', autoGenerated: true);
    _nameController.clear();
    _branchType = 'branch_office';
    _isHeadOffice = false;
    _isActive = true;
    _remarksController.clear();
    _formError = null;
    setState(() {});
    unawaited(_primeCodeSuggestion());
  }

  bool get _isNewBranch => _selectedBranch?.id == null;

  void _setCode(String value, {bool autoGenerated = false}) {
    _codeController.value = _codeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _primeCodeSuggestion() async {
    if (!_isNewBranch || _companyId == null) {
      return;
    }

    final companyId = _companyId!;
    final branchType = _branchType;
    try {
      final code = await _masterService.nextBranchCode(
        companyId: companyId,
        branchType: branchType,
      );
      if (!mounted ||
          !_isNewBranch ||
          _companyId != companyId ||
          _branchType != branchType) {
        return;
      }
      if (code != null && code.trim().isNotEmpty) {
        _setCode(code.trim(), autoGenerated: true);
        setState(() {});
      }
    } catch (_) {}
  }

  void _refreshAutoGeneratedCode() {
    if (!_isNewBranch) {
      return;
    }

    _setCode('', autoGenerated: true);
    unawaited(_primeCodeSuggestion());
  }

  Future<void> _save(BuildContext formContext) async {
    if (!Form.of(formContext).validate()) {
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
      await _loadData(
        selectId: saved.id,
        companyIdHint: saved.companyId,
      );
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
                  Tab(text: 'GST Registrations'),
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
                  _selectedBranch?.id == null
                      ? _buildDependentTabPlaceholder(
                          title: 'GST Registrations',
                          message:
                              'Select an existing branch or save this branch first to manage GST registrations.',
                        )
                      : GstRegistrationManagementPage(
                          key: ValueKey<String>(
                            'branch-gst-${_selectedBranch!.id}',
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
      child: Builder(
        builder: (formContext) {
          return Column(
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
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Code is required'
                        : null,
                  ),
                  AppFormTextField(
                    controller: _nameController,
                    labelText: 'Name',
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  AppDropdownField<String>.fromMapped(
                    initialValue: _branchType,
                    labelText: 'Branch Type',
                    mappedItems: const [
                      AppDropdownItem(
                        value: 'head_office',
                        label: 'Head Office',
                      ),
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  AppActionButton(
                    onPressed: _saving
                        ? null
                        : () => _save(formContext),
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
          );
        },
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
