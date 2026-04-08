import '../../../screen.dart';

class ItemAlternateManagementPage extends StatefulWidget {
  const ItemAlternateManagementPage({
    super.key,
    this.embedded = false,
    this.fixedItemId,
    this.fixedItemLabel,
  });

  final bool embedded;
  final int? fixedItemId;
  final String? fixedItemLabel;

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
  static const String _pageTitle = 'Item Alternates';
  static const String _masterLabel = 'Item';
  static const String _counterpartyLabel = 'Alternate Item';

  @override
  void initState() {
    super.initState();
    _masterSearchController.addListener(_applyMasterSearch);
    _addSearchController.addListener(_refreshAddSearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _masterSearchController.dispose();
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

      if (widget.fixedItemId != null) {
        _selectedMasterId = widget.fixedItemId;
      } else {
        _selectedMasterId ??= _allItems.isNotEmpty ? _allItems.first.id : null;
      }
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
      final responses =
          await Future.wait<PaginatedResponse<ItemAlternateModel>>([
            _inventoryService.itemAlternates(
              filters: {
                'per_page': 300,
                'sort_by': 'priority_order',
                'sort_order': 'asc',
                'item_id': _selectedMasterId,
              },
            ),
            _inventoryService.itemAlternates(
              filters: {
                'per_page': 300,
                'sort_by': 'priority_order',
                'sort_order': 'asc',
                'alternate_item_id': _selectedMasterId,
              },
            ),
          ]);
      final uniqueItems = <int?, ItemAlternateModel>{};
      for (final item in <ItemAlternateModel>[
        ...(responses[0].data ?? const <ItemAlternateModel>[]),
        ...(responses[1].data ?? const <ItemAlternateModel>[]),
      ]) {
        uniqueItems[item.id] = item;
      }
      final items = uniqueItems.values.toList(growable: false);
      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _filteredItems = items;
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

  void _applyMasterSearch() {
    setState(() {
      _filteredMasterItems = _filterMasterItems(
        _allItems,
        _masterSearchController.text,
      );
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
    if (_selectedItem?.id == item.id) {
      _resetForm();
      return;
    }
    _selectedItem = item;
    _counterpartyId = _counterpartyIdFor(item);
    _priorityController.text = item.priorityOrder?.toString() ?? '1';
    _remarksController.text = item.reason ?? '';
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedItem = null;
    _counterpartyId = null;
    _priorityController.text = '1';
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
      itemId: _itemIdForSave(),
      alternateItemId: _alternateItemIdForSave(),
      priorityOrder: int.tryParse(_priorityController.text.trim()) ?? 1,
      isActive: _isActive,
      reason: nullIfEmpty(_remarksController.text),
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

  int? _itemIdForSave() {
    if (_selectedItem != null && widget.fixedItemId != null) {
      if (_selectedItem!.itemId == _selectedMasterId) {
        return _selectedMasterId;
      }
      if (_selectedItem!.alternateItemId == _selectedMasterId) {
        return _counterpartyId;
      }
    }
    return _selectedMasterId;
  }

  int? _alternateItemIdForSave() {
    if (_selectedItem != null && widget.fixedItemId != null) {
      if (_selectedItem!.itemId == _selectedMasterId) {
        return _counterpartyId;
      }
      if (_selectedItem!.alternateItemId == _selectedMasterId) {
        return _selectedMasterId;
      }
    }
    return _counterpartyId;
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

  Future<void> _confirmDelete(ItemAlternateModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Alternate'),
          content: Text(
            'Remove ${_counterpartyLabelFor(item)} from this item alternates list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    _selectMapping(item);
    await _delete();
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

  int? _counterpartyIdFor(ItemAlternateModel item) {
    if (item.itemId == _selectedMasterId) {
      return item.alternateItemId;
    }
    if (item.alternateItemId == _selectedMasterId) {
      return item.itemId;
    }
    return item.alternateItemId;
  }

  String _counterpartyLabelFor(ItemAlternateModel item) {
    final isDirect = item.itemId == _selectedMasterId;
    final code = isDirect ? item.alternateItemCode : item.itemCode;
    final name = isDirect ? item.alternateItemName : item.itemName;
    if (name.isNotEmpty) {
      return name;
    }
    return code;
  }

  List<ItemModel> get _availableCounterpartyOptions {
    final selectedIds = _items.map(_counterpartyIdFor).whereType<int>().toSet();

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

  List<ItemModel> get _dropdownCounterpartyOptions {
    final options = _availableCounterpartyOptions.toList(growable: true);
    if (_counterpartyId != null) {
      final selected = _allItems.cast<ItemModel?>().firstWhere(
        (item) => item?.id == _counterpartyId,
        orElse: () => null,
      );
      if (selected != null &&
          options.every((option) => option.id != selected.id)) {
        options.insert(0, selected);
      }
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _selectedMasterId == null ? null : _resetForm,
        icon: Icons.compare_arrows_outlined,
        label: 'Add Alternate',
      ),
    ];

    if (widget.fixedItemId != null) {
      return content;
    }

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

    if (widget.fixedItemId != null) {
      return _selectedMasterId == null
          ? const SettingsEmptyState(
              icon: Icons.compare_arrows_outlined,
              title: 'Item Not Found',
              message: 'The selected item is not available.',
            )
          : _buildEditorBody();
    }

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
            : _buildEditorBody(),
      ),
    );
  }

  Widget _buildEditorBody() {
    final hasDraft = _selectedItem != null || _counterpartyId != null;
    final selectedCounterparty = _allItems.cast<ItemModel?>().firstWhere(
      (item) => item?.id == _counterpartyId,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_filteredItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No alternates mapped for this item.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              return SettingsListTile(
                title: _counterpartyLabelFor(item),
                subtitle: [
                  if (item.priorityOrder != null)
                    'Priority ${item.priorityOrder}',
                  if (item.isActive) 'Active',
                ].join(' · '),
                selected: identical(item, _selectedItem),
                onTap: () => _selectMapping(item),
                trailing: IconButton(
                  tooltip: 'Remove alternate',
                  onPressed: _saving ? null : () => _confirmDelete(item),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              );
            },
          ),
        const SizedBox(height: 20),
        TextField(
          controller: _addSearchController,
          decoration: const InputDecoration(
            hintText: 'Search alternate item to add',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        if (_filteredAvailableCounterpartyOptions.isEmpty)
          const Text('No more alternate items available to add.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredAvailableCounterpartyOptions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final option = _filteredAvailableCounterpartyOptions[index];
              return SettingsListTile(
                title: _itemLabel(option),
                subtitle: '',
                selected: option.id == _counterpartyId && _selectedItem == null,
                onTap: () => _startNewWithCounterparty(option.id!),
                trailing: const Icon(Icons.add_circle_outline),
              );
            },
          ),
        if (hasDraft) ...[
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
                if (widget.fixedItemId == null) ...[
                  DropdownButtonFormField<int>(
                    initialValue: _counterpartyId,
                    decoration: const InputDecoration(
                      labelText: _counterpartyLabel,
                    ),
                    items: _allItems
                        .where(
                          (item) => _dropdownCounterpartyOptions.any(
                            (option) => option.id == item.id,
                          ),
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
                    validator: Validators.requiredSelection(_counterpartyLabel),
                  ),
                  const SizedBox(height: 12),
                ] else if (selectedCounterparty != null) ...[
                  Text(
                    _itemLabel(selectedCounterparty),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                ],
                SettingsFormWrap(
                  children: [
                    AppFormTextField(
                      labelText: 'Priority',
                      controller: _priorityController,
                      keyboardType: TextInputType.number,
                      validator: Validators.compose([
                        Validators.required('Priority'),
                        Validators.optionalMinimumInteger(1, 'Priority'),
                      ]),
                    ),
                    AppFormTextField(
                      labelText: 'Reason',
                      controller: _remarksController,
                      maxLines: 3,
                      validator: Validators.optionalMaxLength(255, 'Reason'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 280,
                  child: AppSwitchTile(
                    label: 'Active',
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
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
        ] else ...[
          const SizedBox(height: 16),
          const Text('Pick an alternate above to start this mapping.'),
        ],
      ],
    );
  }
}
