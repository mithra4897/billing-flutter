import '../../../screen.dart';

class UomManagementPage extends StatefulWidget {
  const UomManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<UomManagementPage> createState() => _UomManagementPageState();
}

class _UomManagementPageState extends State<UomManagementPage> {
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<UomModel> _uoms = const <UomModel>[];
  List<UomModel> _filteredUoms = const <UomModel>[];
  UomModel? _selectedUom;
  bool _isActive = true;
  bool _isFractionAllowed = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadUoms();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  Future<void> _loadUoms({int? selectId}) async {
    setState(() {
      _initialLoading = _uoms.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _inventoryService.uoms(
        filters: const {'per_page': 100, 'sort_by': 'uom_name'},
      );
      final items = response.data ?? const <UomModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _uoms = items;
        _filteredUoms = filterMasterList(items, _searchController.text, (uom) {
          return [uom.uomCode ?? '', uom.uomName ?? '', uom.symbol ?? ''];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<UomModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedUom == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<UomModel?>().firstWhere(
                    (item) => item?.id == _selectedUom?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectUom(selected);
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
      _filteredUoms = filterMasterList(_uoms, _searchController.text, (uom) {
        return [uom.uomCode ?? '', uom.uomName ?? '', uom.symbol ?? ''];
      });
    });
  }

  void _selectUom(UomModel uom) {
    _selectedUom = uom;
    _codeController.text = uom.uomCode ?? '';
    _nameController.text = uom.uomName ?? '';
    _symbolController.text = uom.symbol ?? '';
    _isFractionAllowed = uom.isFractionAllowed;
    _isActive = uom.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedUom = null;
    _codeController.clear();
    _nameController.clear();
    _symbolController.clear();
    _isFractionAllowed = false;
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

    final model = UomModel(
      id: _selectedUom?.id,
      uomCode: _codeController.text.trim(),
      uomName: _nameController.text.trim(),
      symbol: _symbolController.text.trim(),
      isFractionAllowed: _isFractionAllowed,
      isActive: _isActive,
    );

    try {
      final response = _selectedUom == null
          ? await _inventoryService.createUom(model)
          : await _inventoryService.updateUom(_selectedUom!.id!, model);
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
      await _loadUoms(selectId: saved.id);
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
    final id = _selectedUom?.id;
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _inventoryService.deleteUom(id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadUoms();
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
    final content = _buildContent(context);
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNewUom,
        icon: Icons.add_circle_outline,
        label: 'New UOM',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'UOM',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading UOM...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load UOM',
        message: _pageError!,
        onRetry: _loadUoms,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'UOM',
      editorTitle: _selectedUom?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<UomModel>(
        searchController: _searchController,
        searchHint: 'Search UOM',
        items: _filteredUoms,
        selectedItem: _selectedUom,
        emptyMessage: 'No UOM records found.',
        itemBuilder: (uom, selected) => SettingsListTile(
          title: uom.uomName ?? '-',
          subtitle: uom.symbol ?? uom.uomCode ?? '',
          selected: selected,
          onTap: () => _selectUom(uom),
          trailing: SettingsStatusPill(
            label: uom.isActive ? 'Active' : 'Inactive',
            active: uom.isActive,
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
              const SizedBox(height: 16),
            ],
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  labelText: 'UOM Code',
                  controller: _codeController,
                  validator: Validators.required('UOM code'),
                ),
                AppFormTextField(
                  labelText: 'UOM Name',
                  controller: _nameController,
                  validator: Validators.required('UOM name'),
                ),
                AppFormTextField(
                  labelText: 'Symbol',
                  controller: _symbolController,
                  validator: Validators.required('Symbol'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Fraction Allowed',
                    subtitle: 'Enable decimal quantity for this unit.',
                    value: _isFractionAllowed,
                    onChanged: (value) =>
                        setState(() => _isFractionAllowed = value),
                  ),
                ),
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Active',
                    subtitle: 'Inactive UOMs stay hidden from normal use.',
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedUom == null ? 'Save UOM' : 'Update UOM',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedUom?.id != null)
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
    );
  }

  void _startNewUom() {
    _resetForm();

    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }
}
