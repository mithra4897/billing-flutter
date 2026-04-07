import '../../../screen.dart';

enum ItemAlternateViewMode { itemWise, alternateWise }

class ItemAlternateManagementPage extends StatefulWidget {
  const ItemAlternateManagementPage({
    super.key,
    required this.mode,
    this.embedded = false,
  });

  final ItemAlternateViewMode mode;
  final bool embedded;

  @override
  State<ItemAlternateManagementPage> createState() =>
      _ItemAlternateManagementPageState();
}

class _ItemAlternateManagementPageState
    extends State<ItemAlternateManagementPage> {
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _masterSearchController = TextEditingController();
  final TextEditingController _mappingSearchController =
      TextEditingController();
  final TextEditingController _addSearchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _priorityController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<ItemAlternateModel> _items = const <ItemAlternateModel>[];
  List<ItemAlternateModel> _filteredItems = const <ItemAlternateModel>[];
  List<ItemModel> _allItems = const <ItemModel>[];
  List<ItemModel> _filteredMasterItems = const <ItemModel>[];
  ItemAlternateModel? _selectedItem;
  int? _selectedMasterId;
  int? _counterpartyId;
  bool _isActive = true;

  bool get _isItemWise => widget.mode == ItemAlternateViewMode.itemWise;
  String get _pageTitle => _isItemWise ? 'Item Alternates' : 'Alternate Items';
  String get _masterLabel => _isItemWise ? 'Item' : 'Alternate Item';
  String get _counterpartyLabel => _isItemWise ? 'Alternate Item' : 'Item';

  @override
  void initState() {
    super.initState();
    _masterSearchController.addListener(_applyMasterSearch);
    _mappingSearchController.addListener(_applyMappingSearch);
    _addSearchController.addListener(_refreshAddSearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _masterSearchController.dispose();
    _mappingSearchController.dispose();
    _addSearchController.dispose();
    _priorityController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _allItems.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _inventoryService.items(
        filters: const {'per_page': 300, 'sort_by': 'item_name'},
      );
      final items = response.data ?? const <ItemModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _allItems = items
            .where((item) => item.isActive)
            .toList(growable: false);
        _filteredMasterItems = _filterMasterItems(
          _allItems,
          _masterSearchController.text,
        );
      });

      _selectedMasterId ??= _allItems.isNotEmpty ? _allItems.first.id : null;
      await _loadMappings(selectId: selectId);
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

  Future<void> _loadMappings({int? selectId}) async {
    if (_selectedMasterId == null) {
      setState(() {
        _items = const <ItemAlternateModel>[];
        _filteredItems = const <ItemAlternateModel>[];
        _initialLoading = false;
      });
      _resetForm();
      return;
    }

    try {
      final response = await _inventoryService.itemAlternates(
        filters: {
          'per_page': 300,
          'sort_by': 'priority',
          'sort_order': 'asc',
          if (_isItemWise) 'item_id': _selectedMasterId,
          if (!_isItemWise) 'alternate_item_id': _selectedMasterId,
        },
      );
      final items = response.data ?? const <ItemAlternateModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _filteredItems = _filterMappings(items, _mappingSearchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<ItemAlternateModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? null
                : items.cast<ItemAlternateModel?>().firstWhere(
                    (item) => item?.id == _selectedItem?.id,
                    orElse: () => null,
                  ));

      if (selected != null) {
        _selectMapping(selected);
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

  List<ItemModel> _filterMasterItems(List<ItemModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [item.itemCode, item.itemName, item.itemType ?? ''];
    });
  }

  List<ItemAlternateModel> _filterMappings(
    List<ItemAlternateModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [
        item.itemCode,
        item.itemName,
        item.alternateItemCode,
        item.alternateItemName,
      ];
    });
  }

  void _applyMasterSearch() {
    setState(() {
      _filteredMasterItems = _filterMasterItems(
        _allItems,
        _masterSearchController.text,
      );
    });
  }

  void _applyMappingSearch() {
    setState(() {
      _filteredItems = _filterMappings(_items, _mappingSearchController.text);
    });
  }

  void _refreshAddSearch() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectMaster(int id) {
    setState(() {
      _selectedMasterId = id;
    });
    _loadMappings();
  }

  void _selectMapping(ItemAlternateModel item) {
    _selectedItem = item;
    _counterpartyId = _isItemWise ? item.alternateItemId : item.itemId;
    _priorityController.text = item.priority?.toString() ?? '0';
    _remarksController.text = item.remarks ?? '';
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedItem = null;
    _counterpartyId = null;
    _priorityController.text = '0';
    _remarksController.clear();
    _addSearchController.clear();
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  void _startNewWithCounterparty(int id) {
    _resetForm();
    _counterpartyId = id;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedMasterId == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = ItemAlternateModel(
      id: _selectedItem?.id,
      itemId: _isItemWise ? _selectedMasterId : _counterpartyId,
      alternateItemId: _isItemWise ? _counterpartyId : _selectedMasterId,
      priority: int.tryParse(_priorityController.text.trim()) ?? 0,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedItem == null
          ? await _inventoryService.createItemAlternate(model)
          : await _inventoryService.updateItemAlternate(
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
      await _loadMappings(selectId: saved?.id);
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
      final response = await _inventoryService.deleteItemAlternate(id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadMappings();
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

  String _itemLabel(ItemModel item) {
    final code = item.itemCode.trim();
    final name = item.itemName.trim();
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }
    return name.isNotEmpty ? name : code;
  }

  String get _selectedMasterTitle {
    final selected = _allItems.cast<ItemModel?>().firstWhere(
      (item) => item?.id == _selectedMasterId,
      orElse: () => null,
    );
    return selected == null ? _pageTitle : _itemLabel(selected);
  }

  List<ItemModel> get _availableCounterpartyOptions {
    final selectedIds = _items
        .map((item) => _isItemWise ? item.alternateItemId : item.itemId)
        .whereType<int>()
        .toSet();

    if (_counterpartyId != null) {
      selectedIds.remove(_counterpartyId);
    }

    return _allItems
        .where(
          (item) =>
              item.id != null &&
              item.id != _selectedMasterId &&
              !selectedIds.contains(item.id),
        )
        .toList(growable: false);
  }

  List<ItemModel> get _filteredAvailableCounterpartyOptions {
    final query = _addSearchController.text.trim().toLowerCase();
    final options = _availableCounterpartyOptions;
    if (query.isEmpty) {
      return options.take(8).toList(growable: false);
    }

    return options
        .where((item) => _itemLabel(item).toLowerCase().contains(query))
        .take(8)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _selectedMasterId == null ? null : _resetForm,
        icon: Icons.compare_arrows_outlined,
        label: _isItemWise ? 'Add Alternate' : 'Add Item',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: _pageTitle,
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return AppLoadingView(message: 'Loading ${_pageTitle.toLowerCase()}...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load ${_pageTitle.toLowerCase()}',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    final selectedMaster = _allItems.cast<ItemModel?>().firstWhere(
      (item) => item?.id == _selectedMasterId,
      orElse: () => null,
    );

    return SettingsWorkspace(
      controller: _workspaceController,
      title: _pageTitle,
      editorTitle: _selectedMasterTitle,
      scrollController: _pageScrollController,
      list: SettingsListCard<ItemModel>(
        searchController: _masterSearchController,
        searchHint: 'Search $_masterLabel',
        items: _filteredMasterItems,
        selectedItem: selectedMaster,
        emptyMessage: 'No $_masterLabel records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.itemName,
          subtitle: item.itemCode,
          selected: selected,
          onTap: () => _selectMaster(item.id!),
        ),
      ),
      editor: AppSectionCard(
        child: _selectedMasterId == null
            ? SettingsEmptyState(
                icon: Icons.compare_arrows_outlined,
                title: 'Select $_masterLabel',
                message:
                    'Choose a $_masterLabel from the left to manage alternates.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedMasterTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mappingSearchController,
                    decoration: InputDecoration(
                      hintText: _isItemWise
                          ? 'Search alternates for this item'
                          : 'Search items for this alternate',
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_filteredItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _isItemWise
                            ? 'No alternates mapped for this item.'
                            : 'No items mapped for this alternate.',
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return SettingsListTile(
                          title: _isItemWise
                              ? (item.alternateItemName.isNotEmpty
                                    ? item.alternateItemName
                                    : item.alternateItemCode)
                              : (item.itemName.isNotEmpty
                                    ? item.itemName
                                    : item.itemCode),
                          subtitle: [
                            if (item.priority != null)
                              'Priority ${item.priority}',
                            if (item.isActive) 'Active',
                          ].join(' · '),
                          selected: identical(item, _selectedItem),
                          onTap: () => _selectMapping(item),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  Text(
                    _isItemWise ? 'Add Alternate' : 'Add Item',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addSearchController,
                    decoration: InputDecoration(
                      hintText: _isItemWise
                          ? 'Search alternate item to add'
                          : 'Search item to add',
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_filteredAvailableCounterpartyOptions.isEmpty)
                    Text(
                      _isItemWise
                          ? 'No more alternate items available to add.'
                          : 'No more items available to add.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredAvailableCounterpartyOptions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final option =
                            _filteredAvailableCounterpartyOptions[index];
                        return SettingsListTile(
                          title: _itemLabel(option),
                          subtitle: '',
                          selected:
                              option.id == _counterpartyId &&
                              _selectedItem == null,
                          onTap: () => _startNewWithCounterparty(option.id!),
                          trailing: const Icon(Icons.add_circle_outline),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_formError != null) ...[
                          AppErrorStateView.inline(message: _formError!),
                          const SizedBox(height: 12),
                        ],
                        DropdownButtonFormField<int>(
                          initialValue: _counterpartyId,
                          decoration: InputDecoration(
                            labelText: _counterpartyLabel,
                          ),
                          items: _allItems
                              .where(
                                (item) =>
                                    item.id != null &&
                                    item.id != _selectedMasterId,
                              )
                              .map(
                                (item) => DropdownMenuItem<int>(
                                  value: item.id,
                                  child: Text(_itemLabel(item)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) =>
                              setState(() => _counterpartyId = value),
                          validator: Validators.requiredSelection(
                            _counterpartyLabel,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          labelText: 'Priority',
                          controller: _priorityController,
                          keyboardType: TextInputType.number,
                          validator: Validators.optionalNonNegativeInteger(
                            'Priority',
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          labelText: 'Remarks',
                          controller: _remarksController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        AppSwitchTile(
                          label: 'Active',
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            AppActionButton(
                              icon: Icons.save_outlined,
                              label: _selectedItem == null
                                  ? 'Save Mapping'
                                  : 'Update Mapping',
                              onPressed: _save,
                              busy: _saving,
                            ),
                            if (_selectedItem?.id != null)
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
                ],
              ),
      ),
    );
  }
}
