import 'dart:async' show unawaited;

import '../../../screen.dart';
import 'financial_year_page.dart';

class CompanyManagementPage extends StatefulWidget {
  const CompanyManagementPage({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
  });

  final bool embedded;
  final int initialTabIndex;

  @override
  State<CompanyManagementPage> createState() => _CompanyManagementPageState();
}

class _CompanyManagementPageState extends State<CompanyManagementPage>
    with SingleTickerProviderStateMixin {
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _legalNameController = TextEditingController();
  final TextEditingController _tradeNameController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<CompanyModel> _filteredCompanies = const <CompanyModel>[];
  CompanyModel? _selectedCompany;
  bool _isActive = true;
  String _companyType = 'private_limited';
  late final TabController _tabController;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _loadCompanies();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _codeController.dispose();
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _currencyController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies({int? selectId}) async {
    setState(() {
      _initialLoading = _companies.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _masterService.companies(
        filters: const {'per_page': 100, 'sort_by': 'legal_name'},
      );
      final items = response.data ?? const <CompanyModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _companies = items;
        _filteredCompanies = filterMasterList(items, _searchController.text, (
          company,
        ) {
          return [
            company.code ?? '',
            company.legalName ?? '',
            company.tradeName ?? '',
            company.city ?? '',
          ];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<CompanyModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedCompany == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<CompanyModel?>().firstWhere(
                    (item) => item?.id == _selectedCompany?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectCompany(selected);
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
      _filteredCompanies = filterMasterList(
        _companies,
        _searchController.text,
        (company) {
          return [
            company.code ?? '',
            company.legalName ?? '',
            company.tradeName ?? '',
            company.city ?? '',
          ];
        },
      );
    });
  }

  void _selectCompany(CompanyModel company) {
    _selectedCompany = company;
    _setCode(company.code ?? '', autoGenerated: false);
    _legalNameController.text = company.legalName ?? '';
    _tradeNameController.text = company.tradeName ?? '';
    _gstinController.text = company.gstin ?? '';
    _panController.text = company.pan ?? '';
    _phoneController.text = company.phone ?? '';
    _emailController.text = company.email ?? '';
    _websiteController.text = company.website ?? '';
    _cityController.text = company.city ?? '';
    _stateController.text = company.stateName ?? company.stateCode ?? '';
    _currencyController.text = company.baseCurrency ?? 'INR';
    _remarksController.text = company.remarks ?? '';
    _companyType = company.companyType ?? 'private_limited';
    _isActive = company.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedCompany = null;
    _setCode('', autoGenerated: true);
    _legalNameController.clear();
    _tradeNameController.clear();
    _gstinController.clear();
    _panController.clear();
    _phoneController.clear();
    _emailController.clear();
    _websiteController.clear();
    _cityController.clear();
    _stateController.clear();
    _currencyController.text = 'INR';
    _remarksController.clear();
    _companyType = 'private_limited';
    _isActive = true;
    _formError = null;
    setState(() {});
    unawaited(_primeCodeSuggestion());
  }

  bool get _isNewCompany => _selectedCompany?.id == null;

  void _setCode(String value, {bool autoGenerated = false}) {
    _codeController.value = _codeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _primeCodeSuggestion() async {
    if (!_isNewCompany) {
      return;
    }

    try {
      final code = await _masterService.nextCompanyCode(prefix: 'CMP');
      if (!mounted || !_isNewCompany) {
        return;
      }
      if (code != null && code.trim().isNotEmpty) {
        _setCode(code.trim(), autoGenerated: true);
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = CompanyModel(
      id: _selectedCompany?.id,
      code: _codeController.text.trim(),
      legalName: _legalNameController.text.trim(),
      tradeName: nullIfEmpty(_tradeNameController.text),
      companyType: _companyType,
      gstin: nullIfEmpty(_gstinController.text),
      pan: nullIfEmpty(_panController.text),
      phone: nullIfEmpty(_phoneController.text),
      email: nullIfEmpty(_emailController.text),
      website: nullIfEmpty(_websiteController.text),
      city: nullIfEmpty(_cityController.text),
      stateName: nullIfEmpty(_stateController.text),
      baseCurrency: nullIfEmpty(_currencyController.text) ?? 'INR',
      remarks: nullIfEmpty(_remarksController.text),
      isActive: _isActive,
    );

    try {
      final response = _selectedCompany == null
          ? await _masterService.createCompany(model)
          : await _masterService.updateCompany(_selectedCompany!.id!, model);

      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        setState(() {
          _formError = response.message;
        });
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadCompanies(selectId: saved.id);
    } catch (error) {
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _startNewCompany() {
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
        onPressed: _startNewCompany,
        icon: Icons.add_business_outlined,
        label: 'New Company',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Companies',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading companies...');
    }
    if (_pageError != null) {
      return Center(child: Text(_pageError!));
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Companies',
      editorTitle: _selectedCompany?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<CompanyModel>(
        searchController: _searchController,
        searchHint: 'Search companies',
        items: _filteredCompanies,
        selectedItem: _selectedCompany,
        emptyMessage: 'No companies found.',
        itemBuilder: (company, selected) => SettingsListTile(
          title: company.legalName ?? '',
          subtitle: [
            company.code ?? '',
            company.city ?? '',
            company.stateName ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: SettingsStatusPill(
            label: company.isActive ? 'Active' : 'Inactive',
            active: company.isActive,
          ),
          onTap: () => _selectCompany(company),
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
                  Tab(text: 'Financial Years'),
                ],
              ),
              const SizedBox(height: 20),
              IndexedStack(
                index: _activeTabIndex,
                children: [
                  _buildPrimaryTab(context),
                  _selectedCompany?.id == null
                      ? _buildDependentTabPlaceholder(
                          title: 'Financial Years',
                          message:
                              'Select an existing company or save this company first to manage financial years.',
                        )
                      : FinancialYearManagementPage(
                          embedded: true,
                          fixedCompanyId: _selectedCompany!.id,
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
              AppFormTextField(
                controller: _codeController,
                labelText: 'Code',
                readOnly: true,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Code is required'
                    : null,
              ),
              AppFormTextField(
                controller: _legalNameController,
                labelText: 'Legal Name',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Legal Name is required'
                    : null,
              ),
              AppFormTextField(
                controller: _tradeNameController,
                labelText: 'Trade Name',
              ),
              AppDropdownField<String>.fromMapped(
                initialValue: _companyType,
                labelText: 'Company Type',
                mappedItems: const [
                  AppDropdownItem(
                    value: 'private_limited',
                    label: 'Private Limited',
                  ),
                  AppDropdownItem(
                    value: 'proprietorship',
                    label: 'Proprietorship',
                  ),
                  AppDropdownItem(value: 'partnership', label: 'Partnership'),
                  AppDropdownItem(value: 'llp', label: 'LLP'),
                  AppDropdownItem(
                    value: 'public_limited',
                    label: 'Public Limited',
                  ),
                  AppDropdownItem(value: 'trust', label: 'Trust'),
                  AppDropdownItem(value: 'society', label: 'Society'),
                  AppDropdownItem(value: 'other', label: 'Other'),
                ],
                onChanged: (value) =>
                    setState(() => _companyType = value ?? _companyType),
              ),
              AppFormTextField(
                controller: _gstinController,
                labelText: 'GSTIN',
              ),
              AppFormTextField(controller: _panController, labelText: 'PAN'),
              AppFormTextField(
                controller: _phoneController,
                labelText: 'Phone',
              ),
              AppFormTextField(
                controller: _emailController,
                labelText: 'Email',
              ),
              AppFormTextField(
                controller: _websiteController,
                labelText: 'Website',
              ),
              AppFormTextField(controller: _cityController, labelText: 'City'),
              AppFormTextField(
                controller: _stateController,
                labelText: 'State Name',
              ),
              AppFormTextField(
                controller: _currencyController,
                labelText: 'Base Currency',
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSwitchTile(
            label: 'Active',
            subtitle:
                'Inactive companies stay visible but should not be used for new work.',
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
            runSpacing: 12,
            children: [
              AppActionButton(
                onPressed: _saving ? null : _save,
                icon: _selectedCompany == null
                    ? Icons.add
                    : Icons.save_outlined,
                label: _saving ? 'Saving...' : 'Save Company',
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
