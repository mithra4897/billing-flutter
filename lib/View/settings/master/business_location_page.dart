import 'dart:async' show unawaited;

import '../../../screen.dart';

class BusinessLocationManagementPage extends StatefulWidget {
  const BusinessLocationManagementPage({
    super.key,
    this.embedded = false,
    this.fixedCompanyId,
    this.fixedBranchId,
  });

  final bool embedded;
  final int? fixedCompanyId;
  final int? fixedBranchId;

  @override
  State<BusinessLocationManagementPage> createState() =>
      _BusinessLocationManagementPageState();
}

class _BusinessLocationManagementPageState
    extends State<BusinessLocationManagementPage> {
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  bool _showDraftTile = false;
  String? _pageError;
  String? _formError;
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<BusinessLocationModel> _filteredLocations =
      const <BusinessLocationModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  BusinessLocationModel? _selectedLocation;
  int? _companyId;
  int? _branchId;
  String _locationType = 'billing';
  bool _allowSales = true;
  bool _allowPurchase = true;
  bool _allowStock = true;
  bool _allowAccounts = true;
  bool _allowHr = true;
  bool _isDefault = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BusinessLocationManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixedCompanyId != widget.fixedCompanyId ||
        oldWidget.fixedBranchId != widget.fixedBranchId) {
      _selectedLocation = null;
      _loadData();
    }
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _locations.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait([
        _masterService.businessLocations(
          filters: const {'per_page': 100, 'sort_by': 'name'},
        ),
        _masterService.companies(filters: const {'per_page': 100}),
        _masterService.branches(filters: const {'per_page': 100}),
      ]);

      final locations =
          responses[0].data as List<BusinessLocationModel>? ??
          const <BusinessLocationModel>[];
      final companies =
          responses[1].data as List<CompanyModel>? ?? const <CompanyModel>[];
      final branches =
          responses[2].data as List<BranchModel>? ?? const <BranchModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _locations = locations;
        _companies = companies;
        _branches = branches;
        _filteredLocations = _filterLocations(locations);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? locations.cast<BusinessLocationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedLocation == null
                ? (locations.isNotEmpty ? locations.first : null)
                : locations.cast<BusinessLocationModel?>().firstWhere(
                    (item) => item?.id == _selectedLocation?.id,
                    orElse: () => locations.isNotEmpty ? locations.first : null,
                  ));

      if (selected != null) {
        _selectLocation(selected);
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
      _filteredLocations = _filterLocations(_locations);
    });
  }

  List<BusinessLocationModel> _filterLocations(
    List<BusinessLocationModel> items,
  ) {
    final scoped = items
        .where((location) {
          if (widget.fixedCompanyId != null &&
              location.companyId != widget.fixedCompanyId) {
            return false;
          }
          if (widget.fixedBranchId != null &&
              location.branchId != widget.fixedBranchId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    return filterMasterList(scoped, _searchController.text, (location) {
      return [location.code ?? '', location.name ?? '', location.city ?? ''];
    });
  }

  void _selectLocation(BusinessLocationModel location) {
    _selectedLocation = location;
    _showDraftTile = false;
    _companyId = widget.fixedCompanyId ?? location.companyId;
    _branchId = widget.fixedBranchId ?? location.branchId;
    _setCode(location.code ?? '', autoGenerated: false);
    _nameController.text = location.name ?? '';
    _contactController.text = location.contactPerson ?? '';
    _phoneController.text = location.phone ?? '';
    _emailController.text = location.email ?? '';
    _cityController.text = location.city ?? '';
    _stateController.text = location.stateName ?? location.stateCode ?? '';
    _addressController.text = location.addressLine1 ?? '';
    _locationType = location.locationType ?? 'billing';
    _allowSales = location.allowSales;
    _allowPurchase = location.allowPurchase;
    _allowStock = location.allowStock;
    _allowAccounts = location.allowAccounts;
    _allowHr = location.allowHr;
    _isDefault = location.isDefault;
    _isActive = location.isActive;
    _remarksController.text = location.remarks ?? '';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedLocation = null;
    _companyId =
        widget.fixedCompanyId ??
        (_companies.isNotEmpty ? _companies.first.id : null);
    _branchId =
        widget.fixedBranchId ??
        (branchesForCompany(_branches, _companyId).isNotEmpty
            ? branchesForCompany(_branches, _companyId).first.id
            : null);
    _setCode('', autoGenerated: true);
    _nameController.clear();
    _contactController.clear();
    _phoneController.clear();
    _emailController.clear();
    _cityController.clear();
    _stateController.clear();
    _addressController.clear();
    _locationType = 'billing';
    _allowSales = true;
    _allowPurchase = true;
    _allowStock = true;
    _allowAccounts = true;
    _allowHr = true;
    _isDefault = false;
    _isActive = true;
    _remarksController.clear();
    _formError = null;
    setState(() {});
    unawaited(_primeCodeSuggestion());
  }

  bool get _isNewLocation => _selectedLocation?.id == null;

  void _setCode(String value, {bool autoGenerated = false}) {
    _codeController.value = _codeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _primeCodeSuggestion() async {
    if (!_isNewLocation || _branchId == null) {
      return;
    }

    final branchId = _branchId!;
    try {
      final code = await _masterService.nextBusinessLocationCode(
        branchId: branchId,
      );
      if (!mounted ||
          !_isNewLocation ||
          _branchId != branchId) {
        return;
      }
      if (code != null && code.trim().isNotEmpty) {
        _setCode(code.trim(), autoGenerated: true);
        setState(() {});
      }
    } catch (_) {}
  }

  void _refreshAutoGeneratedCode() {
    if (!_isNewLocation) {
      return;
    }

    _setCode('', autoGenerated: true);
    unawaited(_primeCodeSuggestion());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = BusinessLocationModel(
      id: _selectedLocation?.id,
      companyId: _companyId,
      branchId: _branchId,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      locationType: _locationType,
      contactPerson: nullIfEmpty(_contactController.text),
      phone: nullIfEmpty(_phoneController.text),
      email: nullIfEmpty(_emailController.text),
      addressLine1: nullIfEmpty(_addressController.text),
      city: nullIfEmpty(_cityController.text),
      stateName: nullIfEmpty(_stateController.text),
      allowSales: _allowSales,
      allowPurchase: _allowPurchase,
      allowStock: _allowStock,
      allowAccounts: _allowAccounts,
      allowHr: _allowHr,
      isDefault: _isDefault,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedLocation == null
          ? await _masterService.createBusinessLocation(model)
          : await _masterService.updateBusinessLocation(
              _selectedLocation!.id!,
              model,
            );
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
      _showDraftTile = false;
      _resetForm();
      await _loadData();
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _startNewLocation() {
    _showDraftTile = true;
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
        onPressed: _startNewLocation,
        icon: Icons.add_location_alt_outlined,
        label: 'New Location',
      ),
    ];

    if (widget.embedded) {
      return _buildEmbeddedContent(context);
    }

    return AppStandaloneShell(
      title: 'Business Locations',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading business locations...');
    }
    if (_pageError != null) {
      return Center(child: Text(_pageError!));
    }

    final filteredBranches =
        branchesForCompany(_branches, widget.fixedCompanyId ?? _companyId)
            .where((branch) {
              return widget.fixedBranchId == null ||
                  branch.id == widget.fixedBranchId;
            })
            .toList(growable: false);

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Business Locations',
      editorTitle: _selectedLocation?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<BusinessLocationModel>(
        searchController: _searchController,
        searchHint: 'Search locations',
        items: _filteredLocations,
        selectedItem: _selectedLocation,
        emptyMessage: 'No business locations found.',
        itemBuilder: (location, selected) => SettingsListTile(
          title: location.name ?? '',
          subtitle: [
            location.code ?? '',
            branchNameById(_branches, location.branchId),
            location.city ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: SettingsStatusPill(
            label: location.isActive ? 'Active' : 'Inactive',
            active: location.isActive,
          ),
          onTap: () => _selectLocation(location),
        ),
      ),
      editor: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
                if (widget.fixedCompanyId == null)
                  AppDropdownField<int>.fromMapped(
                    initialValue: _companyId,
                    labelText: 'Company',
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
                      setState(() {
                        _companyId = value;
                        final branches = branchesForCompany(_branches, value)
                            .where((branch) {
                              return widget.fixedBranchId == null ||
                                  branch.id == widget.fixedBranchId;
                            })
                            .toList(growable: false);
                        _branchId = branches.isNotEmpty
                            ? branches.first.id
                            : null;
                      });
                      _refreshAutoGeneratedCode();
                    },
                    validator: (value) =>
                        value == null ? 'Company is required' : null,
                  ),
                if (widget.fixedBranchId == null)
                  AppDropdownField<int>.fromMapped(
                    initialValue: _branchId,
                    labelText: 'Branch',
                    mappedItems: filteredBranches
                        .where((branch) => branch.id != null)
                        .map(
                          (branch) => AppDropdownItem<int>(
                            value: branch.id!,
                            label: branch.name ?? '',
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() => _branchId = value);
                      _refreshAutoGeneratedCode();
                    },
                    validator: (value) =>
                        value == null ? 'Branch is required' : null,
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
                  initialValue: _locationType,
                  labelText: 'Location Type',
                  mappedItems: const [
                    AppDropdownItem(value: 'billing', label: 'Billing'),
                    AppDropdownItem(value: 'office', label: 'Office'),
                    AppDropdownItem(value: 'factory', label: 'Factory'),
                    AppDropdownItem(value: 'retail', label: 'Retail'),
                    AppDropdownItem(value: 'service', label: 'Service'),
                    AppDropdownItem(value: 'jobwork', label: 'Jobwork'),
                    AppDropdownItem(
                      value: 'warehouse',
                      label: 'Warehouse Site',
                    ),
                    AppDropdownItem(value: 'other', label: 'Other'),
                  ],
                  onChanged: (value) =>
                      setState(() => _locationType = value ?? _locationType),
                ),
                AppFormTextField(
                  controller: _contactController,
                  labelText: 'Contact Person',
                ),
                AppFormTextField(
                  controller: _phoneController,
                  labelText: 'Phone',
                ),
                AppFormTextField(
                  controller: _emailController,
                  labelText: 'Email',
                ),
                AppFormTextField(
                  controller: _cityController,
                  labelText: 'City',
                ),
                AppFormTextField(
                  controller: _stateController,
                  labelText: 'State',
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppFormTextField(
              controller: _addressController,
              maxLines: 2,
              labelText: 'Address Line 1',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppToggleChip(
                  label: 'Sales',
                  value: _allowSales,
                  onChanged: (value) => setState(() => _allowSales = value),
                ),
                AppToggleChip(
                  label: 'Purchase',
                  value: _allowPurchase,
                  onChanged: (value) => setState(() => _allowPurchase = value),
                ),
                AppToggleChip(
                  label: 'Stock',
                  value: _allowStock,
                  onChanged: (value) => setState(() => _allowStock = value),
                ),
                AppToggleChip(
                  label: 'Accounts',
                  value: _allowAccounts,
                  onChanged: (value) => setState(() => _allowAccounts = value),
                ),
                AppToggleChip(
                  label: 'HR',
                  value: _allowHr,
                  onChanged: (value) => setState(() => _allowHr = value),
                ),
              ],
            ),
            AppSwitchTile(
              label: 'Default Location',
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
            AppSwitchTile(
              label: 'Active',
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
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
                  icon: _selectedLocation == null ? Icons.add : Icons.save,
                  label: _saving ? 'Saving...' : 'Save Location',
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
      ),
    );
  }

  Widget _buildEmbeddedContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading business locations...');
    }
    if (_pageError != null) {
      return AppErrorStateView.inline(message: _pageError!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppActionButton(
              onPressed: _saving ? null : _startNewLocation,
              icon: Icons.add_location_alt_outlined,
              label: 'New Location',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_filteredLocations.isEmpty &&
            !_showDraftTile &&
            _selectedLocation == null)
          const SettingsEmptyState(
            icon: Icons.add_location_alt_outlined,
            title: 'No Branch Locations',
            message: 'No branch locations found.',
            minHeight: 160,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showDraftTile && _selectedLocation == null) ...[
                SettingsExpandableTile(
                  key: const ValueKey('location-draft'),
                  title: 'New Location',
                  subtitle: 'Create a branch-associated location.',
                  expanded: true,
                  highlighted: true,
                  leadingIcon: Icons.add_outlined,
                  onToggle: () {
                    setState(() {
                      _showDraftTile = false;
                    });
                    _resetForm();
                  },
                  child: _buildInlineEditor(),
                ),
                if (_filteredLocations.isNotEmpty)
                  const SizedBox(height: AppUiConstants.spacingSm),
              ],
              ..._filteredLocations.map((item) {
                final expanded = identical(item, _selectedLocation);
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: SettingsExpandableTile(
                    key: ValueKey('location-${item.id}-$expanded'),
                    title: item.name ?? '-',
                    subtitle: [
                      item.code ?? '',
                      item.city ?? '',
                      item.locationType?.replaceAll('_', ' ') ?? '',
                    ].where((value) => value.isNotEmpty).join(' • '),
                    detail: [
                      if (item.isDefault) 'Default',
                      if (item.isActive) 'Active',
                    ].join(' • '),
                    expanded: expanded,
                    highlighted: expanded,
                    onToggle: () {
                      if (expanded) {
                        _resetForm();
                      } else {
                        _selectLocation(item);
                      }
                    },
                    child: expanded
                        ? _buildInlineEditor()
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildInlineEditor() {
    final filteredBranches =
        branchesForCompany(_branches, widget.fixedCompanyId ?? _companyId)
            .where((branch) {
              return widget.fixedBranchId == null ||
                  branch.id == widget.fixedBranchId;
            })
            .toList(growable: false);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsFormWrap(
            children: [
              if (widget.fixedCompanyId == null)
                AppDropdownField<int>.fromMapped(
                  initialValue: _companyId,
                  labelText: 'Company',
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
                    setState(() {
                      _companyId = value;
                      final branches = branchesForCompany(_branches, value)
                          .where((branch) {
                            return widget.fixedBranchId == null ||
                                branch.id == widget.fixedBranchId;
                          })
                          .toList(growable: false);
                      _branchId = branches.isNotEmpty
                          ? branches.first.id
                          : null;
                    });
                    _refreshAutoGeneratedCode();
                  },
                  validator: (value) =>
                      value == null ? 'Company is required' : null,
                ),
              if (widget.fixedBranchId == null)
                AppDropdownField<int>.fromMapped(
                  initialValue: _branchId,
                  labelText: 'Branch',
                  mappedItems: filteredBranches
                      .where((branch) => branch.id != null)
                      .map(
                        (branch) => AppDropdownItem<int>(
                          value: branch.id!,
                          label: branch.name ?? '',
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() => _branchId = value);
                    _refreshAutoGeneratedCode();
                  },
                  validator: (value) =>
                      value == null ? 'Branch is required' : null,
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
                initialValue: _locationType,
                labelText: 'Location Type',
                mappedItems: const [
                  AppDropdownItem(value: 'billing', label: 'Billing'),
                  AppDropdownItem(value: 'office', label: 'Office'),
                  AppDropdownItem(value: 'factory', label: 'Factory'),
                  AppDropdownItem(value: 'retail', label: 'Retail'),
                  AppDropdownItem(value: 'service', label: 'Service'),
                  AppDropdownItem(value: 'jobwork', label: 'Jobwork'),
                  AppDropdownItem(value: 'warehouse', label: 'Warehouse Site'),
                  AppDropdownItem(value: 'other', label: 'Other'),
                ],
                onChanged: (value) =>
                    setState(() => _locationType = value ?? _locationType),
              ),
              AppFormTextField(
                controller: _contactController,
                labelText: 'Contact Person',
              ),
              AppFormTextField(
                controller: _phoneController,
                labelText: 'Phone',
              ),
              AppFormTextField(
                controller: _emailController,
                labelText: 'Email',
              ),
              AppFormTextField(controller: _cityController, labelText: 'City'),
              AppFormTextField(
                controller: _stateController,
                labelText: 'State',
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppFormTextField(
            controller: _addressController,
            maxLines: 2,
            labelText: 'Address Line 1',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppToggleChip(
                label: 'Sales',
                value: _allowSales,
                onChanged: (value) => setState(() => _allowSales = value),
              ),
              AppToggleChip(
                label: 'Purchase',
                value: _allowPurchase,
                onChanged: (value) => setState(() => _allowPurchase = value),
              ),
              AppToggleChip(
                label: 'Stock',
                value: _allowStock,
                onChanged: (value) => setState(() => _allowStock = value),
              ),
              AppToggleChip(
                label: 'Accounts',
                value: _allowAccounts,
                onChanged: (value) => setState(() => _allowAccounts = value),
              ),
              AppToggleChip(
                label: 'HR',
                value: _allowHr,
                onChanged: (value) => setState(() => _allowHr = value),
              ),
            ],
          ),
          AppSwitchTile(
            label: 'Default Location',
            value: _isDefault,
            onChanged: (value) => setState(() => _isDefault = value),
          ),
          AppSwitchTile(
            label: 'Active',
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
          ),
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
                icon: _selectedLocation == null ? Icons.add : Icons.save,
                label: _saving ? 'Saving...' : 'Save Location',
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
}
