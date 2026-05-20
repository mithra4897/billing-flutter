import '../../../screen.dart';

class UomConversionManagementPage extends StatefulWidget {
  const UomConversionManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<UomConversionManagementPage> createState() =>
      _UomConversionManagementPageState();
}

class _UomConversionManagementPageState
    extends State<UomConversionManagementPage> {
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _factorController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<UomConversionModel> _items = const <UomConversionModel>[];
  List<UomConversionModel> _filteredItems = const <UomConversionModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  UomConversionModel? _selectedItem;
  int? _fromUomId;
  int? _toUomId;
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
    _factorController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.uomConversions(
          filters: const {
            'per_page': 200,
            'sort_by': 'id',
            'sort_order': 'desc',
          },
        ),
        _inventoryService.uoms(
          filters: const {
            'per_page': 200,
            'sort_by': 'uom_name',
            'sort_order': 'asc',
          },
        ),
      ]);

      final items =
          (responses[0] as PaginatedResponse<UomConversionModel>).data ??
          const <UomConversionModel>[];
      final uoms =
          (responses[1] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _uoms = uoms;
        _filteredItems = filterMasterList(items, _searchController.text, (
          item,
        ) {
          return [
            item.fromDisplay,
            item.toDisplay,
            item.fromUomCode,
            item.toUomCode,
            item.conversionFactor?.toString() ?? '',
          ];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<UomConversionModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<UomConversionModel?>().firstWhere(
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
          item.fromDisplay,
          item.toDisplay,
          item.fromUomCode,
          item.toUomCode,
          item.conversionFactor?.toString() ?? '',
        ];
      });
    });
  }

  void _selectItem(UomConversionModel item) {
    _selectedItem = item;
    _fromUomId = item.fromUomId;
    _toUomId = item.toUomId;
    _factorController.text = item.conversionFactor?.toString() ?? '';
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedItem = null;
    _fromUomId = _uoms.isNotEmpty ? _uoms.first.id : null;
    _toUomId = _uoms.length > 1
        ? _uoms
              .firstWhere(
                (item) => item.id != _fromUomId,
                orElse: () => _uoms.first,
              )
              .id
        : null;
    _factorController.clear();
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

    final model = UomConversionModel(
      id: _selectedItem?.id,
      fromUomId: _fromUomId,
      toUomId: _toUomId,
      conversionFactor: double.tryParse(_factorController.text.trim()),
      isActive: _isActive,
    );

    try {
      final response = _selectedItem == null
          ? await _inventoryService.createUomConversion(model)
          : await _inventoryService.updateUomConversion(
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
      final response = await _inventoryService.deleteUomConversion(id);
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
        icon: Icons.swap_vert_outlined,
        label: 'New Conversion',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'UOM Conversions',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading UOM conversions...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load UOM conversions',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    final toUomOptions = _uoms
        .where((uom) => uom.id != _fromUomId)
        .toList(growable: false);

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'UOM Conversions',
      editorTitle: _selectedItem?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<UomConversionModel>(
        searchController: _searchController,
        searchHint: 'Search UOM conversions',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No UOM conversions found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: '${item.fromDisplay} -> ${item.toDisplay}',
          subtitle: [
            if (item.fromUomSymbol.isNotEmpty) item.fromUomSymbol,
            if (item.toUomSymbol.isNotEmpty) item.toUomSymbol,
            if (item.conversionFactor != null)
              'Factor ${item.conversionFactor}',
          ].join(' · '),
          selected: selected,
          onTap: () => _selectItem(item),
        ),
      ),
      editor: AppSectionCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_formError != null) ...[
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<int>(
                initialValue: _fromUomId,
                decoration: const InputDecoration(labelText: 'From UOM'),
                items: _uoms
                    .where((uom) => uom.id != null)
                    .map(
                      (uom) => DropdownMenuItem<int>(
                        value: uom.id,
                        child: Text(uom.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _fromUomId = value;
                    if (_toUomId == value) {
                      _toUomId = toUomOptions.isNotEmpty
                          ? toUomOptions.first.id
                          : null;
                    }
                  });
                },
                validator: (value) =>
                    Validators.requiredSelectionField(value, 'From UOM'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _toUomId,
                decoration: const InputDecoration(labelText: 'To UOM'),
                items: toUomOptions
                    .where((uom) => uom.id != null)
                    .map(
                      (uom) => DropdownMenuItem<int>(
                        value: uom.id,
                        child: Text(uom.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _toUomId = value),
                validator: (value) =>
                    Validators.requiredSelectionField(value, 'To UOM'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _factorController,
                decoration: const InputDecoration(
                  labelText: 'Conversion Factor',
                  hintText: '1 Base = ? Target',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.compose([
                  Validators.required('Conversion Factor'),
                  Validators.optionalNonNegativeNumber('Conversion Factor'),
                  (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Conversion Factor must be greater than 0';
                    }
                    return null;
                  },
                ]),
              ),
              const SizedBox(height: 12),
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
