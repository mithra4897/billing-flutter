import '../../../screen.dart';

class ModulePreferencesPage extends StatefulWidget {
  const ModulePreferencesPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ModulePreferencesPage> createState() => _ModulePreferencesPageState();
}

class _ModulePreferencesPageState extends State<ModulePreferencesPage> {
  final AuthService _authService = AuthService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _sortOrderController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<ModuleModel> _modules = const <ModuleModel>[];
  List<ModuleModel> _filteredModules = const <ModuleModel>[];
  ModuleModel? _selectedModule;
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadModules();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _loadModules({String? selectCode}) async {
    setState(() {
      _initialLoading = _modules.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _authService.menuPreferences();
      final items = response.data ?? const <ModuleModel>[];
      if (!mounted) {
        return;
      }

      final sorted = [...items]
        ..sort((left, right) {
          final leftOrder = left.effectiveSortOrder ?? left.sortOrder ?? 0;
          final rightOrder = right.effectiveSortOrder ?? right.sortOrder ?? 0;
          final byOrder = leftOrder.compareTo(rightOrder);
          if (byOrder != 0) {
            return byOrder;
          }
          return (left.moduleName ?? '').compareTo(right.moduleName ?? '');
        });

      setState(() {
        _modules = sorted;
        _filteredModules = filterMasterList(sorted, _searchController.text, (
          item,
        ) {
          return [
            item.moduleName ?? '',
            item.moduleCode ?? '',
            item.moduleGroup ?? '',
          ];
        });
        _initialLoading = false;
      });

      final selected = selectCode != null
          ? sorted.cast<ModuleModel?>().firstWhere(
              (item) => item?.moduleCode == selectCode,
              orElse: () => null,
            )
          : (_selectedModule == null
                ? (sorted.isNotEmpty ? sorted.first : null)
                : sorted.cast<ModuleModel?>().firstWhere(
                    (item) => item?.moduleCode == _selectedModule?.moduleCode,
                    orElse: () => sorted.isNotEmpty ? sorted.first : null,
                  ));

      if (selected != null) {
        _selectModule(selected);
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
      _filteredModules = filterMasterList(_modules, _searchController.text, (
        item,
      ) {
        return [
          item.moduleName ?? '',
          item.moduleCode ?? '',
          item.moduleGroup ?? '',
        ];
      });
    });
  }

  void _selectModule(ModuleModel module) {
    _selectedModule = module;
    _sortOrderController.text = (module.userSortOrder ?? module.sortOrder ?? 0)
        .toString();
    _isHidden = module.isHidden ?? false;
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    final selected = _selectedModule;
    if (selected == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final updatedModules = _modules
        .map((item) {
          if (item.moduleCode != selected.moduleCode) {
            return ModuleModel(
              moduleCode: item.moduleCode,
              moduleName: item.moduleName,
              moduleGroup: item.moduleGroup,
              routePath: item.routePath,
              iconKey: item.iconKey,
              description: item.description,
              sortOrder: item.sortOrder,
              userSortOrder: item.userSortOrder ?? item.sortOrder,
              effectiveSortOrder:
                  item.userSortOrder ??
                  item.effectiveSortOrder ??
                  item.sortOrder,
              isHidden: item.isHidden ?? false,
              isActive: item.isActive,
            );
          }

          final sortOrder =
              int.tryParse(_sortOrderController.text.trim()) ??
              item.sortOrder ??
              0;

          return ModuleModel(
            moduleCode: item.moduleCode,
            moduleName: item.moduleName,
            moduleGroup: item.moduleGroup,
            routePath: item.routePath,
            iconKey: item.iconKey,
            description: item.description,
            sortOrder: item.sortOrder,
            userSortOrder: sortOrder,
            effectiveSortOrder: sortOrder,
            isHidden: _isHidden,
            isActive: item.isActive,
          );
        })
        .toList(growable: false);

    try {
      final response = await _authService.syncMenuPreferences(updatedModules);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadModules(selectCode: selected.moduleCode);
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

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: const <Widget>[], child: content);
    }

    return AppStandaloneShell(
      title: 'Module Preferences',
      scrollController: _pageScrollController,
      actions: const <Widget>[],
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading module preferences...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load module preferences',
        message: _pageError!,
        onRetry: _loadModules,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Module Preferences',
      editorTitle: _selectedModule?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<ModuleModel>(
        searchController: _searchController,
        searchHint: 'Search modules',
        items: _filteredModules,
        selectedItem: _selectedModule,
        emptyMessage: 'No modules found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.moduleName ?? '',
          subtitle: [
            item.moduleCode ?? '',
            item.moduleGroup ?? '',
            if (item.isHidden == true) 'Hidden',
          ].where((part) => part.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => _selectModule(item),
        ),
      ),
      editor: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedModule == null)
              const Text('Select a module to manage its menu preference.')
            else ...[
              if (_formError != null) ...[
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              Text('Module Code: ${_selectedModule!.moduleCode ?? ''}'),
              const SizedBox(height: 8),
              Text('Group: ${_selectedModule!.moduleGroup ?? '-'}'),
              const SizedBox(height: 8),
              Text('Route: ${_selectedModule!.routePath ?? '-'}'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sortOrderController,
                decoration: const InputDecoration(labelText: 'Menu Sort Order'),
                keyboardType: TextInputType.number,
                validator: Validators.optionalNonNegativeInteger(
                  'Menu Sort Order',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hide This Module In Menu'),
                value: _isHidden,
                onChanged: (value) => setState(() => _isHidden = value),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ],
        ),
    );
  }
}
