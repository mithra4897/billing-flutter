import '../../../screen.dart';

class GstRegistrationManagementPage extends StatefulWidget {
  const GstRegistrationManagementPage({
    super.key,
    this.embedded = false,
    this.fixedCompanyId,
    this.fixedBranchId,
  });

  final bool embedded;
  final int? fixedCompanyId;
  final int? fixedBranchId;

  @override
  State<GstRegistrationManagementPage> createState() =>
      _GstRegistrationManagementPageState();
}

class _GstRegistrationManagementPageState
    extends State<GstRegistrationManagementPage> {
  static const List<DropdownMenuItem<String>> _registrationTypes =
      <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'regular', child: Text('Regular')),
        DropdownMenuItem(value: 'composition', child: Text('Composition')),
        DropdownMenuItem(value: 'sez', child: Text('SEZ')),
        DropdownMenuItem(value: 'sez_unit', child: Text('SEZ Unit')),
        DropdownMenuItem(value: 'casual', child: Text('Casual')),
        DropdownMenuItem(value: 'non_resident', child: Text('Non Resident')),
        DropdownMenuItem(value: 'unregistered', child: Text('Unregistered')),
      ];

  final TaxesService _taxesService = TaxesService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _legalNameController = TextEditingController();
  final TextEditingController _tradeNameController = TextEditingController();
  final TextEditingController _effectiveFromController =
      TextEditingController();
  final TextEditingController _effectiveToController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  bool _showDraftTile = false;
  String? _pageError;
  String? _formError;
  List<GstRegistrationModel> _items = const <GstRegistrationModel>[];
  List<GstRegistrationModel> _filteredItems = const <GstRegistrationModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<StateModel> _states = const <StateModel>[];
  GstRegistrationModel? _selectedItem;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _stateId;
  String _registrationType = 'regular';
  bool _isDefault = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant GstRegistrationManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixedCompanyId != widget.fixedCompanyId ||
        oldWidget.fixedBranchId != widget.fixedBranchId) {
      _selectedItem = null;
      _loadData();
    }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _effectiveFromController.dispose();
    _effectiveToController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _taxesService.gstRegistrations(filters: const {'per_page': 200}),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.branches(filters: const {'per_page': 200}),
        _masterService.businessLocations(filters: const {'per_page': 200}),
        _taxesService.states(filters: const {'per_page': 200}),
      ]);

      final items =
          (responses[0] as PaginatedResponse<GstRegistrationModel>).data ??
          const <GstRegistrationModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final locations =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final states =
          (responses[4] as PaginatedResponse<StateModel>).data ??
          const <StateModel>[];
      final activeCompanies = companies
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeBranches = branches
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeLocations = locations
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: activeBranches,
            locations: activeLocations,
            financialYears: const <FinancialYearModel>[],
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _companies = activeCompanies;
        _branches = activeBranches;
        _locations = activeLocations;
        _states = states;
        _contextCompanyId = contextSelection.companyId;
        _contextBranchId = contextSelection.branchId;
        _contextLocationId = contextSelection.locationId;
        _filteredItems = _filterItems(items);
        _initialLoading = false;
      });

      final visibleItems = _filterItems(items);
      final selected = selectId != null
          ? visibleItems.cast<GstRegistrationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (visibleItems.isNotEmpty ? visibleItems.first : null)
                : visibleItems.cast<GstRegistrationModel?>().firstWhere(
                    (item) => item?.id == _selectedItem?.id,
                    orElse: () =>
                        visibleItems.isNotEmpty ? visibleItems.first : null,
                  ));

      if (selected != null) {
        _selectItem(selected);
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

  List<GstRegistrationModel> _scopedItems(List<GstRegistrationModel> items) {
    return items
        .where((item) {
          final companyId = widget.fixedCompanyId ?? _contextCompanyId;
          final branchId = widget.fixedBranchId ?? _contextBranchId;
          final locationId = widget.fixedBranchId == null
              ? _contextLocationId
              : null;

          if (companyId != null && item.companyId != companyId) {
            return false;
          }
          if (branchId != null && item.branchId != branchId) {
            return false;
          }
          if (widget.fixedBranchId == null &&
              locationId != null &&
              item.locationId != null &&
              item.locationId != locationId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<GstRegistrationModel> _filterItems(List<GstRegistrationModel> items) {
    final scoped = _scopedItems(items);
    if (widget.embedded &&
        (widget.fixedCompanyId != null || widget.fixedBranchId != null)) {
      return scoped;
    }
    return filterMasterList(scoped, _searchController.text, (item) {
      return [
        item.registrationName,
        item.gstin,
        companyNameById(_companies, item.companyId),
        locationNameById(_locations, item.locationId),
      ];
    });
  }

  void _applySearch() {
    if (widget.embedded &&
        (widget.fixedCompanyId != null || widget.fixedBranchId != null)) {
      return;
    }
    setState(() {
      _filteredItems = _filterItems(_items);
    });
  }

  void _selectItem(GstRegistrationModel item) {
    _selectedItem = item;
    _showDraftTile = false;
    _companyId = item.companyId;
    _branchId = item.branchId;
    _locationId = item.locationId;
    _stateId = item.stateId;
    _nameController.text = item.registrationName;
    _gstinController.text = item.gstin;
    _panController.text = item.panNo;
    _legalNameController.text = item.legalName;
    _tradeNameController.text = item.tradeName;
    _effectiveFromController.text = item.effectiveFrom;
    _effectiveToController.text = item.effectiveTo;
    _remarksController.text = item.remarks ?? '';
    _registrationType = item.registrationType.isEmpty
        ? 'regular'
        : item.registrationType;
    _isDefault = item.isDefault;
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedItem = null;
    _companyId =
        widget.fixedCompanyId ??
        _contextCompanyId ??
        (_companies.isNotEmpty ? _companies.first.id : null);
    final companyBranches = branchesForCompany(_branches, _companyId);
    _branchId =
        widget.fixedBranchId ??
        _contextBranchId ??
        (companyBranches.isNotEmpty ? companyBranches.first.id : null);
    final branchLocations = locationsForBranch(_locations, _branchId);
    _locationId =
        _contextLocationId ??
        (branchLocations.isNotEmpty ? branchLocations.first.id : null);
    _stateId = null;
    _nameController.clear();
    _gstinController.clear();
    _panController.clear();
    _legalNameController.clear();
    _tradeNameController.clear();
    _effectiveFromController.clear();
    _effectiveToController.clear();
    _remarksController.clear();
    _registrationType = 'regular';
    _isDefault = false;
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  Future<void> _save(BuildContext formContext) async {
    if (!Form.of(formContext).validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = GstRegistrationModel(
      id: _selectedItem?.id,
      companyId: _companyId,
      branchId: _branchId,
      locationId: _locationId,
      registrationName: _nameController.text.trim(),
      gstin: _gstinController.text.trim(),
      panNo: _panController.text.trim(),
      stateId: _stateId,
      legalName: _legalNameController.text.trim(),
      tradeName: _tradeNameController.text.trim(),
      registrationType: _registrationType,
      effectiveFrom: _effectiveFromController.text.trim(),
      effectiveTo: _effectiveToController.text.trim(),
      isDefault: _isDefault,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedItem == null
          ? await _taxesService.createGstRegistration(model)
          : await _taxesService.updateGstRegistration(
              _selectedItem!.id!,
              model,
            );
      final saved = response.data;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      _showDraftTile = false;
      _resetForm();
      await _loadData(selectId: saved?.id);
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

  Future<void> _delete() async {
    final id = _selectedItem?.id;
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _taxesService.deleteGstRegistration(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData();
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

  void _startNew() {
    _showDraftTile = true;
    _resetForm();
    if (!widget.embedded && !Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  Widget _buildListCard() {
    return SettingsListCard<GstRegistrationModel>(
      searchController: _searchController,
      searchHint: 'Search GST registrations',
      items: _filteredItems,
      selectedItem: _selectedItem,
      emptyMessage: 'No GST registrations found.',
      itemBuilder: (item, selected) => SettingsListTile(
        title: item.registrationName,
        subtitle: [
          item.gstin,
          companyNameById(_companies, item.companyId),
        ].where((part) => part.trim().isNotEmpty).join(' · '),
        selected: selected,
        trailing: SettingsStatusPill(
          label: item.isActive ? 'Active' : 'Inactive',
          active: item.isActive,
        ),
        onTap: () => _selectItem(item),
      ),
    );
  }

  Widget _buildEmbeddedContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.add_outlined,
                label: 'New GST Registration',
                onPressed: _saving ? null : _startNew,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_filteredItems.isEmpty &&
              !_showDraftTile &&
              _selectedItem == null)
            const SettingsEmptyState(
              icon: Icons.assignment_ind_outlined,
              title: 'No GST Registrations',
              message: 'No GST registrations found.',
              minHeight: 160,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showDraftTile && _selectedItem == null) ...[
                  SettingsExpandableTile(
                    key: const ValueKey('gst-registration-draft'),
                    title: 'New GST Registration',
                    subtitle: 'Create a branch-associated GST registration.',
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
                  if (_filteredItems.isNotEmpty)
                    const SizedBox(height: AppUiConstants.spacingSm),
                ],
                ..._filteredItems.map((item) {
                  final expanded = identical(item, _selectedItem);
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppUiConstants.spacingSm,
                    ),
                    child: SettingsExpandableTile(
                      key: ValueKey('gst-registration-${item.id}-$expanded'),
                      title: item.registrationName.isNotEmpty
                          ? item.registrationName
                          : (item.gstin.isNotEmpty ? item.gstin : '-'),
                      subtitle: [
                        item.gstin,
                        locationNameById(_locations, item.locationId),
                        item.registrationType.replaceAll('_', ' '),
                      ].where((value) => value.trim().isNotEmpty).join(' • '),
                      detail: [
                        if (item.isDefault) 'Default',
                        if (item.isActive) 'Active',
                      ].join(' • '),
                      expanded: expanded,
                      highlighted: expanded,
                      trailing: SettingsStatusPill(
                        label: item.isActive ? 'Active' : 'Inactive',
                        active: item.isActive,
                      ),
                      onToggle: () {
                        if (expanded) {
                          _resetForm();
                        } else {
                          _selectItem(item);
                        }
                      },
                      child: _buildInlineEditor(),
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading GST registrations...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load GST registrations',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    if (widget.embedded) {
      return _buildEmbeddedContent();
    }

    return AppStandaloneShell(
      title: 'GST Registrations',
      scrollController: _pageScrollController,
      actions: [
        AdaptiveShellActionButton(
          onPressed: _startNew,
          icon: Icons.add_outlined,
          label: 'New GST Registration',
        ),
      ],
      child: SettingsWorkspace(
        controller: _workspaceController,
        title: 'GST Registrations',
        editorTitle: _selectedItem?.toString(),
        scrollController: _pageScrollController,
        list: _buildListCard(),
        editor: _buildInlineEditor(),
      ),
    );
  }

  Widget _buildInlineEditor() {
    final branchOptions = branchesForCompany(_branches, _companyId)
        .where(
          (branch) =>
              widget.fixedBranchId == null || branch.id == widget.fixedBranchId,
        )
        .toList(growable: false);
    final locationOptions = locationsForBranch(_locations, _branchId);
    final companyValue = _companies.any((company) => company.id == _companyId)
        ? _companyId
        : null;
    final branchValue = branchOptions.any((branch) => branch.id == _branchId)
        ? _branchId
        : null;
    final locationValue =
        locationOptions.any((location) => location.id == _locationId)
        ? _locationId
        : null;
    final stateValue = _states.any((state) => state.id == _stateId)
        ? _stateId
        : null;

    return Form(
      child: Builder(
        builder: (formContext) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((_formError ?? '').isNotEmpty) ...[
                AppErrorStateView.inline(message: _formError!),
                const SizedBox(height: 16),
              ],
              SettingsFormWrap(
                children: [
                  if (widget.fixedCompanyId == null)
                    AppDropdownField<int>.fromMapped(
                      initialValue: companyValue,
                      labelText: 'Company',
                      mappedItems: _companies
                          .where((company) => company.id != null)
                          .map(
                            (company) => AppDropdownItem<int>(
                              value: company.id!,
                              label: company.toString(),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() {
                          _companyId = value;
                          final branches = branchesForCompany(_branches, value)
                              .where(
                                (branch) =>
                                    widget.fixedBranchId == null ||
                                    branch.id == widget.fixedBranchId,
                              )
                              .toList(growable: false);
                          _branchId = branches.isNotEmpty
                              ? branches.first.id
                              : null;
                          final locations = locationsForBranch(
                            _locations,
                            _branchId,
                          );
                          _locationId = locations.isNotEmpty
                              ? locations.first.id
                              : null;
                        });
                      },
                      validator: (value) =>
                          Validators.requiredSelectionField(value, 'Company'),
                    ),
                  if (widget.fixedBranchId == null)
                    AppDropdownField<int?>.fromMapped(
                      initialValue: branchValue,
                      labelText: 'Branch',
                      mappedItems: [
                        const AppDropdownItem<int?>(value: null, label: 'None'),
                        ...branchOptions
                            .where((branch) => branch.id != null)
                            .map(
                              (branch) => AppDropdownItem<int?>(
                                value: branch.id!,
                                label: branch.toString(),
                              ),
                            ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _branchId = value;
                          final locations = locationsForBranch(
                            _locations,
                            value,
                          );
                          _locationId = locations.isNotEmpty
                              ? locations.first.id
                              : null;
                        });
                      },
                    ),
                  AppDropdownField<int?>.fromMapped(
                    initialValue: locationValue,
                    labelText: 'Location',
                    mappedItems: [
                      const AppDropdownItem<int?>(value: null, label: 'None'),
                      ...locationOptions
                          .where((location) => location.id != null)
                          .map(
                            (location) => AppDropdownItem<int?>(
                              value: location.id!,
                              label: location.toString(),
                            ),
                          ),
                    ],
                    onChanged: (value) => setState(() => _locationId = value),
                  ),
                  AppFormTextField(
                    controller: _nameController,
                    labelText: 'Registration Name',
                    validator: Validators.compose([
                      Validators.required('Registration Name'),
                      Validators.optionalMaxLength(255, 'Registration Name'),
                    ]),
                  ),
                  AppDropdownField<int>.fromMapped(
                    initialValue: stateValue,
                    labelText: 'State',
                    mappedItems: _states
                        .where((state) => state.id != null)
                        .map(
                          (state) => AppDropdownItem<int>(
                            value: state.id!,
                            label: state.stateName,
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() => _stateId = value),
                    validator: (value) =>
                        Validators.requiredSelectionField(value, 'State'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    initialValue: _registrationType,
                    labelText: 'Registration Type',
                    mappedItems: _registrationTypes
                        .map(
                          (item) => AppDropdownItem<String>(
                            value: item.value!,
                            label: (item.child as Text).data ?? item.value!,
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() {
                      _registrationType = value ?? 'regular';
                    }),
                    validator: (value) =>
                        Validators.requiredSelectionField(value, 'Registration Type'),
                  ),
                  AppFormTextField(
                    controller: _gstinController,
                    labelText: 'GSTIN',
                    validator: Validators.optionalMaxLength(20, 'GSTIN'),
                  ),
                  AppFormTextField(
                    controller: _panController,
                    labelText: 'PAN No',
                    validator: Validators.optionalMaxLength(20, 'PAN No'),
                  ),
                  AppFormTextField(
                    controller: _legalNameController,
                    labelText: 'Legal Name',
                    validator: Validators.optionalMaxLength(255, 'Legal Name'),
                  ),
                  AppFormTextField(
                    controller: _tradeNameController,
                    labelText: 'Trade Name',
                    validator: Validators.optionalMaxLength(255, 'Trade Name'),
                  ),
                  AppFormTextField(
                    controller: _effectiveFromController,
                    labelText: 'Effective From',
                    validator: Validators.optionalDate('Effective From'),
                  ),
                  AppFormTextField(
                    controller: _effectiveToController,
                    labelText: 'Effective To',
                    validator: Validators.optionalDateOnOrAfter(
                      'Effective To',
                      () => _effectiveFromController.text,
                      startFieldName: 'Effective From',
                    ),
                  ),
                ],
              ),
              AppSwitchTile(
                label: 'Default Registration',
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
                labelText: 'Remarks',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppActionButton(
                    icon: _selectedItem == null
                        ? Icons.add_outlined
                        : Icons.save_outlined,
                    label: _selectedItem == null
                        ? 'Create GST Registration'
                        : 'Update GST Registration',
                    onPressed: _saving ? null : () => _save(formContext),
                    busy: _saving,
                  ),
                  if (_selectedItem?.id != null)
                    AppActionButton(
                      onPressed: _saving ? null : _delete,
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
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
}
