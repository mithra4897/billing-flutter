import '../../../screen.dart';

class ItemPriceManagementPage extends StatefulWidget {
  const ItemPriceManagementPage({
    super.key,
    this.embedded = false,
    this.fixedItemId,
    this.fixedItem,
    this.fixedItemLabel,
  });

  final bool embedded;
  final int? fixedItemId;
  final ItemModel? fixedItem;
  final String? fixedItemLabel;

  @override
  State<ItemPriceManagementPage> createState() =>
      _ItemPriceManagementPageState();
}

class _ItemPriceManagementPageState extends State<ItemPriceManagementPage> {
  static const List<AppDropdownItem<String>> _priceTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'purchase', label: 'Purchase'),
        AppDropdownItem(value: 'sales', label: 'Sales'),
        AppDropdownItem(value: 'retail', label: 'Retail'),
        AppDropdownItem(value: 'wholesale', label: 'Wholesale'),
        AppDropdownItem(value: 'distributor', label: 'Distributor'),
        AppDropdownItem(value: 'dealer', label: 'Dealer'),
        AppDropdownItem(value: 'special', label: 'Special'),
        AppDropdownItem(value: 'mrp', label: 'MRP'),
      ];

  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _masterSearchController = TextEditingController();
  final TextEditingController _priceSearchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxDiscountController = TextEditingController();
  final TextEditingController _validFromController = TextEditingController();
  final TextEditingController _validToController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<ItemModel> _allItems = const <ItemModel>[];
  List<ItemModel> _filteredItems = const <ItemModel>[];
  List<ItemPriceModel> _prices = const <ItemPriceModel>[];
  List<ItemPriceModel> _filteredPrices = const <ItemPriceModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<UomConversionModel> _uomConversions = const <UomConversionModel>[];
  ItemModel? _selectedItemMaster;
  ItemPriceModel? _selectedPrice;
  int? _uomId;
  String _priceType = 'sales';
  bool _isDefault = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _masterSearchController.addListener(_applyMasterSearch);
    _priceSearchController.addListener(_applyPriceSearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _masterSearchController.dispose();
    _priceSearchController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _minPriceController.dispose();
    _maxDiscountController.dispose();
    _validFromController.dispose();
    _validToController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectPriceId}) async {
    setState(() {
      _initialLoading = _allItems.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'uom_name'},
        ),
        _inventoryService.uomConversions(
          filters: const {
            'per_page': 500,
            'sort_by': 'from_uom_id',
            'sort_order': 'asc',
          },
        ),
      ]);

      final items =
          (responses[0] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final uoms =
          (responses[1] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final uomConversions =
          (responses[2] as PaginatedResponse<UomConversionModel>).data ??
          const <UomConversionModel>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _allItems = items;
        _filteredItems = _filterItemList(items, _masterSearchController.text);
        _uoms = uoms.where((uom) => uom.isActive).toList(growable: false);
        _uomConversions = uomConversions
            .where((conversion) => conversion.isActive)
            .toList(growable: false);
      });

      if (widget.fixedItemId != null) {
        _selectedItemMaster =
            widget.fixedItem ??
            items.cast<ItemModel?>().firstWhere(
              (item) => item?.id == widget.fixedItemId,
              orElse: () => null,
            );
      } else {
        _selectedItemMaster ??= items.isNotEmpty ? items.first : null;
      }
      await _loadPrices(selectPriceId: selectPriceId);
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

  Future<void> _loadPrices({int? selectPriceId}) async {
    final itemId = _selectedItemMaster?.id;
    if (itemId == null) {
      setState(() {
        _prices = const <ItemPriceModel>[];
        _filteredPrices = const <ItemPriceModel>[];
        _initialLoading = false;
      });
      _resetForm();
      return;
    }

    try {
      final response = await _inventoryService.itemPrices(
        filters: {
          'per_page': 300,
          'item_id': itemId,
          'sort_by': 'valid_from',
          'sort_order': 'desc',
        },
      );
      final items = response.data ?? const <ItemPriceModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _prices = items;
        _filteredPrices = _filterPrices(items, _priceSearchController.text);
        _initialLoading = false;
      });

      final selected = selectPriceId != null
          ? items.cast<ItemPriceModel?>().firstWhere(
              (item) => item?.id == selectPriceId,
              orElse: () => null,
            )
          : (_selectedPrice == null
                ? null
                : items.cast<ItemPriceModel?>().firstWhere(
                    (item) => item?.id == _selectedPrice?.id,
                    orElse: () => null,
                  ));

      if (selected != null) {
        _selectPrice(selected);
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

  List<ItemModel> _filterItemList(List<ItemModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [item.itemCode, item.itemName, item.itemType ?? ''];
    });
  }

  List<ItemPriceModel> _filterPrices(
    List<ItemPriceModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [
        item.priceType ?? '',
        item.uomName ?? '',
        item.uomSymbol ?? '',
        item.validFrom ?? '',
        item.validTo ?? '',
      ];
    });
  }

  Set<int> _allowedUomIdsForItem(ItemModel? item) {
    final seedIds = <int>{
      if (item?.baseUomId != null) item!.baseUomId!,
      if (item?.purchaseUomId != null) item!.purchaseUomId!,
      if (item?.salesUomId != null) item!.salesUomId!,
    };

    if (seedIds.isEmpty) {
      return <int>{};
    }

    final allowed = <int>{...seedIds};
    for (final conversion in _uomConversions) {
      final fromId = conversion.fromUomId;
      final toId = conversion.toUomId;
      if (fromId == null || toId == null) {
        continue;
      }
      if (seedIds.contains(fromId) || seedIds.contains(toId)) {
        allowed.add(fromId);
        allowed.add(toId);
      }
    }
    return allowed;
  }

  List<UomModel> get _allowedUoms {
    final allowedIds = _allowedUomIdsForItem(_selectedItemMaster);
    if (_selectedPrice?.uomId != null) {
      allowedIds.add(_selectedPrice!.uomId!);
    }
    if (allowedIds.isEmpty) {
      return _uoms;
    }

    return _uoms
        .where((uom) => uom.id != null && allowedIds.contains(uom.id))
        .toList(growable: false);
  }

  int? get _defaultUomId {
    final item = _selectedItemMaster;
    final allowedIds = _allowedUomIdsForItem(item);
    final preferred = <int?>[
      item?.salesUomId,
      item?.baseUomId,
      item?.purchaseUomId,
    ];
    for (final id in preferred) {
      if (id != null && (allowedIds.isEmpty || allowedIds.contains(id))) {
        return id;
      }
    }
    return _allowedUoms.isNotEmpty ? _allowedUoms.first.id : null;
  }

  void _applyMasterSearch() {
    setState(() {
      _filteredItems = _filterItemList(_allItems, _masterSearchController.text);
    });
  }

  void _applyPriceSearch() {
    setState(() {
      _filteredPrices = _filterPrices(_prices, _priceSearchController.text);
    });
  }

  void _selectMasterItem(ItemModel item) {
    _selectedItemMaster = item;
    _selectedPrice = null;
    _uomId = _defaultUomId;
    _loadPrices();
  }

  void _selectPrice(ItemPriceModel item) {
    _selectedPrice = item;
    _uomId = item.uomId;
    _priceType = item.priceType ?? 'sales';
    _priceController.text = item.price?.toString() ?? '';
    _mrpController.text = item.mrp?.toString() ?? '';
    _minPriceController.text = item.minPrice?.toString() ?? '';
    _maxDiscountController.text = item.maxDiscountPercent?.toString() ?? '';
    _validFromController.text = item.validFrom ?? '';
    _validToController.text = item.validTo ?? '';
    _remarksController.text = item.remarks ?? '';
    _isDefault = item.isDefault;
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedPrice = null;
    _uomId = _defaultUomId;
    _priceType = 'sales';
    _priceController.clear();
    _mrpController.clear();
    _minPriceController.clear();
    _maxDiscountController.clear();
    _validFromController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    _validToController.clear();
    _remarksController.clear();
    _isDefault = false;
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    final itemId = _selectedItemMaster?.id;
    if (!_formKey.currentState!.validate() || itemId == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = ItemPriceModel(
      id: _selectedPrice?.id,
      itemId: itemId,
      priceType: _priceType,
      uomId: _uomId,
      price: double.tryParse(_priceController.text.trim()),
      mrp: double.tryParse(_mrpController.text.trim()),
      minPrice: double.tryParse(_minPriceController.text.trim()),
      maxDiscountPercent: double.tryParse(_maxDiscountController.text.trim()),
      validFrom: _validFromController.text.trim(),
      validTo: nullIfEmpty(_validToController.text),
      isDefault: _isDefault,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedPrice == null
          ? await _inventoryService.createItemPrice(model)
          : await _inventoryService.updateItemPrice(_selectedPrice!.id!, model);
      final saved = response.data;
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPrices(selectPriceId: saved?.id);
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
    final id = _selectedPrice?.id;
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _inventoryService.deleteItemPrice(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPrices();
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
    if (widget.fixedItemId == null && !Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _selectedItemMaster == null ? null : _startNew,
        icon: Icons.price_change_outlined,
        label: 'New Price',
      ),
    ];

    if (widget.fixedItemId != null) {
      return content;
    }

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Item Prices',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading item prices...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load item prices',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    if (widget.fixedItemId != null) {
      return _selectedItemMaster == null
          ? const SettingsEmptyState(
              icon: Icons.price_change_outlined,
              title: 'Item Not Found',
              message: 'The selected item is not available.',
            )
          : _buildEditorBody();
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Item Prices',
      editorTitle: _selectedItemMaster?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<ItemModel>(
        searchController: _masterSearchController,
        searchHint: 'Search items',
        items: _filteredItems,
        selectedItem: _selectedItemMaster,
        emptyMessage: 'No items found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.itemName,
          subtitle: item.itemCode,
          selected: selected,
          onTap: () => _selectMasterItem(item),
        ),
      ),
      editor: AppSectionCard(
        child: _selectedItemMaster == null
            ? const SettingsEmptyState(
                icon: Icons.price_change_outlined,
                title: 'Select Item',
                message: 'Choose an item from the left to manage price rows.',
              )
            : _buildEditorBody(),
      ),
    );
  }

  Widget _buildEditorBody() {
    if (_selectedItemMaster == null) {
      return const SizedBox.shrink();
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _priceSearchController,
            decoration: const InputDecoration(
              hintText: 'Search price rows',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          if (_filteredPrices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No price rows found for this item.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredPrices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final price = _filteredPrices[index];
                return SettingsListTile(
                  title:
                      '${price.priceType ?? '-'} · ${price.price?.toString() ?? '0'}',
                  subtitle: [
                    if ((price.uomName ?? '').isNotEmpty) price.uomName!,
                    if ((price.validFrom ?? '').isNotEmpty)
                      'From ${price.validFrom}',
                    if ((price.validTo ?? '').isNotEmpty) 'To ${price.validTo}',
                    if (price.isDefault) 'Default',
                  ].join(' · '),
                  selected: identical(price, _selectedPrice),
                  onTap: () => _selectPrice(price),
                );
              },
            ),
          const SizedBox(height: 20),
          if (_formError != null) ...[
            AppErrorStateView.inline(message: _formError!),
            const SizedBox(height: 12),
          ],
          SettingsFormWrap(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _priceType,
                decoration: const InputDecoration(labelText: 'Price Type'),
                items: _priceTypeItems
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.value,
                        child: Text(item.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) =>
                    setState(() => _priceType = value ?? 'sales'),
              ),
              DropdownButtonFormField<int>(
                initialValue: _uomId,
                decoration: const InputDecoration(labelText: 'UOM'),
                items: _allowedUoms
                    .where((uom) => uom.id != null)
                    .map(
                      (uom) => DropdownMenuItem<int>(
                        value: uom.id,
                        child: Text(uom.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _uomId = value),
                validator: Validators.requiredSelection('UOM'),
              ),
              AppFormTextField(
                labelText: 'Price',
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.compose([
                  Validators.required('Price'),
                  Validators.optionalNonNegativeNumber('Price'),
                ]),
              ),
              AppFormTextField(
                labelText: 'MRP',
                controller: _mrpController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber('MRP'),
              ),
              AppFormTextField(
                labelText: 'Minimum Price',
                controller: _minPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Minimum Price',
                ),
              ),
              AppFormTextField(
                labelText: 'Max Discount %',
                controller: _maxDiscountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Max Discount %',
                ),
              ),
              AppFormTextField(
                labelText: 'Valid From',
                controller: _validFromController,
                hintText: 'YYYY-MM-DD',
                validator: Validators.compose([
                  Validators.required('Valid From'),
                  Validators.optionalDate('Valid From'),
                ]),
              ),
              AppFormTextField(
                labelText: 'Valid To',
                controller: _validToController,
                hintText: 'YYYY-MM-DD',
                validator: Validators.optionalDateOnOrAfter(
                  'Valid To',
                  () => _validFromController.text,
                  startFieldName: 'Valid From',
                ),
              ),
              AppFormTextField(
                labelText: 'Remarks',
                controller: _remarksController,
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: AppSwitchTile(
                  label: 'Default Price',
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                ),
              ),
              SizedBox(
                width: 280,
                child: AppSwitchTile(
                  label: 'Active',
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
                label: _selectedPrice == null ? 'Save Price' : 'Update Price',
                onPressed: _save,
                busy: _saving,
              ),
              if (_selectedPrice?.id != null)
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
    );
  }
}
