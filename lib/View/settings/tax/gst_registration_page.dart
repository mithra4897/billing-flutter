import '../../../screen.dart';

class GstRegistrationManagementPage extends StatefulWidget {
  const GstRegistrationManagementPage({super.key, this.embedded = false});

  final bool embedded;

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
  String? _pageError;
  String? _formError;
  List<GstRegistrationModel> _items = const <GstRegistrationModel>[];
  List<GstRegistrationModel> _filteredItems = const <GstRegistrationModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<StateModel> _states = const <StateModel>[];
  GstRegistrationModel? _selectedItem;
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

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _companies = companies;
        _branches = branches;
        _locations = locations;
        _states = states;
        _filteredItems = filterMasterList(items, _searchController.text, (
          item,
        ) {
          return [
            item.registrationName,
            item.gstin,
            item.tradeName,
            item.legalName,
          ];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<GstRegistrationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<GstRegistrationModel?>().firstWhere(
                    (item) => item?.id == _selectedItem?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
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

  void _applySearch() {
    setState(() {
      _filteredItems = filterMasterList(_items, _searchController.text, (item) {
        return [
          item.registrationName,
          item.gstin,
          item.tradeName,
          item.legalName,
        ];
      });
    });
  }

  void _selectItem(GstRegistrationModel item) {
    _selectedItem = item;
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
    _companyId = _companies.isNotEmpty ? _companies.first.id : null;
    final companyBranches = branchesForCompany(_branches, _companyId);
    _branchId = companyBranches.isNotEmpty ? companyBranches.first.id : null;
    final branchLocations = locationsForBranch(_locations, _branchId);
    _locationId = branchLocations.isNotEmpty ? branchLocations.first.id : null;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
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
        icon: Icons.assignment_ind_outlined,
        label: 'New GST Registration',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'GST Registrations',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
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

    final branchOptions = branchesForCompany(_branches, _companyId);
    final locationOptions = locationsForBranch(_locations, _branchId);

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'GST Registrations',
      editorTitle: _selectedItem?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<GstRegistrationModel>(
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
          onTap: () => _selectItem(item),
        ),
      ),
      editor: AppSectionCard(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_formError != null) ...[
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<int>(
                initialValue: _companyId,
                decoration: const InputDecoration(labelText: 'Company'),
                items: _companies
                    .map(
                      (company) => DropdownMenuItem<int>(
                        value: company.id,
                        child: Text(company.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _companyId = value;
                    final branches = branchesForCompany(_branches, value);
                    _branchId = branches.isNotEmpty ? branches.first.id : null;
                    final locations = locationsForBranch(_locations, _branchId);
                    _locationId = locations.isNotEmpty
                        ? locations.first.id
                        : null;
                  });
                },
                validator: (value) =>
                    Validators.requiredSelectionField(value, 'Company'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _branchId,
                decoration: const InputDecoration(labelText: 'Branch'),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...branchOptions.map(
                    (branch) => DropdownMenuItem<int?>(
                      value: branch.id,
                      child: Text(branch.toString()),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _branchId = value;
                    final locations = locationsForBranch(_locations, value);
                    _locationId = locations.isNotEmpty
                        ? locations.first.id
                        : null;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _locationId,
                decoration: const InputDecoration(labelText: 'Location'),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...locationOptions.map(
                    (location) => DropdownMenuItem<int?>(
                      value: location.id,
                      child: Text(location.toString()),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _locationId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Registration Name',
                ),
                validator: Validators.compose([
                  Validators.required('Registration Name'),
                  Validators.optionalMaxLength(255, 'Registration Name'),
                ]),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _stateId,
                decoration: const InputDecoration(labelText: 'State'),
                items: _states
                    .map(
                      (state) => DropdownMenuItem<int>(
                        value: state.id,
                        child: Text(state.stateName),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _stateId = value),
                validator: (value) =>
                    Validators.requiredSelectionField(value, 'State'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _registrationType,
                decoration: const InputDecoration(
                  labelText: 'Registration Type',
                ),
                items: _registrationTypes,
                onChanged: (value) => setState(() {
                  _registrationType = value ?? 'regular';
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gstinController,
                decoration: const InputDecoration(labelText: 'GSTIN'),
                validator: Validators.optionalMaxLength(20, 'GSTIN'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(labelText: 'PAN No'),
                validator: Validators.optionalMaxLength(20, 'PAN No'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _legalNameController,
                decoration: const InputDecoration(labelText: 'Legal Name'),
                validator: Validators.optionalMaxLength(255, 'Legal Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tradeNameController,
                decoration: const InputDecoration(labelText: 'Trade Name'),
                validator: Validators.optionalMaxLength(255, 'Trade Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _effectiveFromController,
                decoration: const InputDecoration(labelText: 'Effective From'),
                validator: Validators.optionalDate('Effective From'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _effectiveToController,
                decoration: const InputDecoration(labelText: 'Effective To'),
                validator: Validators.optionalDateOnOrAfter(
                  'Effective To',
                  () => _effectiveFromController.text,
                  startFieldName: 'Effective From',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default Registration'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_selectedItem?.id != null)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      child: const Text('Delete'),
                    ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save'),
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
