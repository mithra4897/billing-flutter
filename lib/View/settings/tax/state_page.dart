import '../../../screen.dart';

class StateManagementPage extends StatefulWidget {
  const StateManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StateManagementPage> createState() => _StateManagementPageState();
}

class _StateManagementPageState extends State<StateManagementPage> {
  final TaxesService _taxesService = TaxesService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _stateCodeController = TextEditingController();
  final TextEditingController _stateNameController = TextEditingController();
  final TextEditingController _gstStateCodeController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<StateModel> _states = const <StateModel>[];
  List<StateModel> _filteredStates = const <StateModel>[];
  StateModel? _selectedState;
  bool _isUnionTerritory = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadStates();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _countryCodeController.dispose();
    _stateCodeController.dispose();
    _stateNameController.dispose();
    _gstStateCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadStates({int? selectId}) async {
    setState(() {
      _initialLoading = _states.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _taxesService.states(
        filters: const {'per_page': 200, 'sort_by': 'state_name'},
      );
      final items = response.data ?? const <StateModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _states = items;
        _filteredStates = filterMasterList(items, _searchController.text, (
          item,
        ) {
          return [item.stateCode, item.stateName, item.gstStateCode];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<StateModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedState == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<StateModel?>().firstWhere(
                    (item) => item?.id == _selectedState?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectState(selected);
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
      _filteredStates = filterMasterList(_states, _searchController.text, (
        item,
      ) {
        return [item.stateCode, item.stateName, item.gstStateCode];
      });
    });
  }

  void _selectState(StateModel item) {
    _selectedState = item;
    _countryCodeController.text = item.countryCode;
    _stateCodeController.text = item.stateCode;
    _stateNameController.text = item.stateName;
    _gstStateCodeController.text = item.gstStateCode;
    _isUnionTerritory = item.isUnionTerritory;
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedState = null;
    _countryCodeController.text = 'IN';
    _stateCodeController.clear();
    _stateNameController.clear();
    _gstStateCodeController.clear();
    _isUnionTerritory = false;
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

    final model = StateModel(
      id: _selectedState?.id,
      countryCode: _countryCodeController.text.trim(),
      stateCode: _stateCodeController.text.trim(),
      stateName: _stateNameController.text.trim(),
      gstStateCode: _gstStateCodeController.text.trim(),
      isUnionTerritory: _isUnionTerritory,
      isActive: _isActive,
    );

    try {
      final response = _selectedState == null
          ? await _taxesService.createState(model)
          : await _taxesService.updateState(_selectedState!.id!, model);
      final saved = response.data;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadStates(selectId: saved?.id);
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
    final id = _selectedState?.id;
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _taxesService.deleteState(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadStates();
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
        icon: Icons.map_outlined,
        label: 'New State',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'States',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading states...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load states',
        message: _pageError!,
        onRetry: _loadStates,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'States',
      editorTitle: _selectedState?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<StateModel>(
        searchController: _searchController,
        searchHint: 'Search states',
        items: _filteredStates,
        selectedItem: _selectedState,
        emptyMessage: 'No states found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.stateName,
          subtitle: [
            item.countryCode,
            item.stateCode,
            if (item.gstStateCode.isNotEmpty) item.gstStateCode,
          ].join(' · '),
          selected: selected,
          onTap: () => _selectState(item),
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
              TextFormField(
                controller: _countryCodeController,
                decoration: const InputDecoration(labelText: 'Country Code'),
                validator: Validators.compose([
                  Validators.required('Country Code'),
                  Validators.optionalMaxLength(10, 'Country Code'),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stateCodeController,
                decoration: const InputDecoration(labelText: 'State Code'),
                validator: Validators.compose([
                  Validators.required('State Code'),
                  Validators.optionalMaxLength(10, 'State Code'),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stateNameController,
                decoration: const InputDecoration(labelText: 'State Name'),
                validator: Validators.compose([
                  Validators.required('State Name'),
                  Validators.optionalMaxLength(100, 'State Name'),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gstStateCodeController,
                decoration: const InputDecoration(labelText: 'GST State Code'),
                validator: Validators.optionalMaxLength(10, 'GST State Code'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Union Territory'),
                value: _isUnionTerritory,
                onChanged: (value) => setState(() => _isUnionTerritory = value),
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
                  if (_selectedState?.id != null)
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
