import '../../screen.dart';

class CrmSourcesPage extends StatefulWidget {
  const CrmSourcesPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CrmSourcesPage> createState() => _CrmSourcesPageState();
}

class _CrmSourcesPageState extends State<CrmSourcesPage> {
  final CrmService _crmService = CrmService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CrmSourceModel> _items = const <CrmSourceModel>[];
  List<CrmSourceModel> _filteredItems = const <CrmSourceModel>[];
  CrmSourceModel? _selectedItem;
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
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _crmService.sources(
        filters: const {'per_page': 200, 'sort_by': 'source_name'},
      );
      final items = response.data ?? const <CrmSourceModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _initialLoading = false;
      });
      _applySearch();

      final selected = selectId != null
          ? items.cast<CrmSourceModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<CrmSourceModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(_selectedItem!.toJson(), 'id'),
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
        final data = item.toJson();
        return [stringValue(data, 'source_name')];
      });
    });
  }

  void _selectItem(CrmSourceModel item) {
    final data = item.toJson();
    setState(() {
      _selectedItem = item;
      _nameController.text = stringValue(data, 'source_name');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _formError = null;
    });
  }

  void _resetForm() {
    setState(() {
      _selectedItem = null;
      _nameController.clear();
      _isActive = true;
      _formError = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final payload = CrmSourceModel({
      'source_name': _nameController.text.trim(),
      'is_active': _isActive,
    });

    try {
      final response = _selectedItem == null
          ? await _crmService.createSource(payload)
          : await _crmService.updateSource(
              intValue(_selectedItem!.toJson(), 'id')!,
              payload,
            );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: intValue(response.data?.toJson() ?? const {}, 'id'));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }

    try {
      final response = await _crmService.deleteSource(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: () {
          _resetForm();
          if (!Responsive.isDesktop(context)) {
            _workspaceController.openEditor();
          }
        },
        icon: Icons.add_outlined,
        label: 'New Source',
      ),
    ];

    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'CRM Sources',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading CRM sources...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM sources',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    return SettingsWorkspace(
      title: 'CRM Sources',
      scrollController: _pageScrollController,
      controller: _workspaceController,
      editorTitle: _selectedItem?.toString() ?? 'New Source',
      list: SettingsListCard<CrmSourceModel>(
        searchController: _searchController,
        searchHint: 'Search sources',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No CRM sources found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.toString(),
          subtitle: boolValue(item.toJson(), 'is_active', fallback: true)
              ? 'Active'
              : 'Inactive',
          selected: selected,
          onTap: () => _selectItem(item),
          trailing: SettingsStatusPill(
            label: boolValue(item.toJson(), 'is_active', fallback: true)
                ? 'Active'
                : 'Inactive',
            active: boolValue(item.toJson(), 'is_active', fallback: true),
          ),
        ),
      ),
      editor: Form(
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
                  controller: _nameController,
                  labelText: 'Source Name',
                  validator: Validators.required('Source Name'),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedItem == null ? 'Save Source' : 'Update Source',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedItem != null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                    onPressed: _delete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
