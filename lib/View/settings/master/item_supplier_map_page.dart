import '../../../screen.dart';

enum ItemSupplierMapViewMode { itemWise, supplierWise }

class ItemSupplierMapManagementPage extends StatefulWidget {
  const ItemSupplierMapManagementPage({
    super.key,
    required this.mode,
    this.embedded = false,
    this.fixedItemId,
    this.fixedItem,
    this.fixedItemLabel,
  });

  final ItemSupplierMapViewMode mode;
  final bool embedded;
  final int? fixedItemId;
  final ItemModel? fixedItem;
  final String? fixedItemLabel;

  @override
  State<ItemSupplierMapManagementPage> createState() =>
      _ItemSupplierMapManagementPageState();
}

class _ItemSupplierMapManagementPageState
    extends State<ItemSupplierMapManagementPage> {
  final InventoryService _inventoryService = InventoryService();
  final PartiesService _partiesService = PartiesService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _masterSearchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _supplierItemCodeController =
      TextEditingController();
  final TextEditingController _supplierItemNameController =
      TextEditingController();
  final TextEditingController _supplierRateController = TextEditingController();
  final TextEditingController _leadTimeDaysController = TextEditingController();
  final TextEditingController _minOrderQtyController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  bool _showDraftTile = false;
  String? _pageError;
  String? _formError;
  List<ItemSupplierMapModel> _items = const <ItemSupplierMapModel>[];
  List<ItemSupplierMapModel> _filteredItems = const <ItemSupplierMapModel>[];
  List<ItemModel> _allItems = const <ItemModel>[];
  List<ItemModel> _filteredMastersItems = const <ItemModel>[];
  List<PartyModel> _allSuppliers = const <PartyModel>[];
  List<PartyModel> _filteredMasterSuppliers = const <PartyModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<UomConversionModel> _uomConversions = const <UomConversionModel>[];
  ItemSupplierMapModel? _selectedItem;
  int? _selectedMasterId;
  int? _counterpartyId;
  int? _purchaseUomId;
  bool _isPrimarySupplier = false;
  bool _isActive = true;

  bool get _isItemWise => widget.mode == ItemSupplierMapViewMode.itemWise;

  String get _pageTitle => _isItemWise ? 'Item Suppliers' : 'Supplier Items';

  String get _masterLabel => _isItemWise ? 'Item' : 'Supplier';

  String get _counterpartyLabel => _isItemWise ? 'Supplier' : 'Item';

  @override
  void initState() {
    super.initState();
    _masterSearchController.addListener(_applyMasterSearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _masterSearchController.dispose();
    _supplierItemCodeController.dispose();
    _supplierItemNameController.dispose();
    _supplierRateController.dispose();
    _leadTimeDaysController.dispose();
    _minOrderQtyController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _allItems.isEmpty && _allSuppliers.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.items(
          filters: const {
            'per_page': 200,
            'sort_by': 'item_name',
            'sort_order': 'asc',
          },
        ),
        _partiesService.partyTypes(
          filters: const {
            'per_page': 200,
            'sort_by': 'name',
            'sort_order': 'asc',
          },
        ),
        _partiesService.parties(
          filters: const {
            'per_page': 200,
            'sort_by': 'display_name',
            'sort_order': 'asc',
          },
        ),
        _inventoryService.uoms(
          filters: const {
            'per_page': 200,
            'sort_by': 'uom_name',
            'sort_order': 'asc',
          },
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
      final partyTypes =
          (responses[1] as PaginatedResponse<PartyTypeModel>).data ??
          const <PartyTypeModel>[];
      final parties =
          (responses[2] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];
      final uoms =
          (responses[3] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final uomConversions =
          (responses[4] as PaginatedResponse<UomConversionModel>).data ??
          const <UomConversionModel>[];

      if (!mounted) {
        return;
      }

      final supplierTypeIds = partyTypes
          .where(_isSupplierPartyType)
          .map(_partyTypeId)
          .whereType<int>()
          .toSet();

      final suppliers = parties
          .where(
            (party) =>
                party.isActive && supplierTypeIds.contains(party.partyTypeId),
          )
          .toList(growable: false);

      setState(() {
        _allItems = items
            .whereType<ItemModel>()
            .where((item) => item.isActive)
            .toList(growable: false);
        _allSuppliers = suppliers;
        _uoms = uoms.where((uom) => uom.isActive).toList(growable: false);
        _uomConversions = uomConversions
            .where((conversion) => conversion.isActive)
            .toList(growable: false);
        _filteredMastersItems = _filterMasterItems(
          _allItems,
          _masterSearchController.text,
        );
        _filteredMasterSuppliers = _filterMasterSuppliers(
          _allSuppliers,
          _masterSearchController.text,
        );
      });

      if (_isItemWise && widget.fixedItemId != null) {
        _selectedMasterId = widget.fixedItemId;
      } else {
        _selectedMasterId ??= _isItemWise
            ? (_allItems.isNotEmpty ? _allItems.first.id : null)
            : (_allSuppliers.isNotEmpty ? _allSuppliers.first.id : null);
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

  int? _partyTypeId(PartyTypeModel partyType) {
    final json = partyType.toJson();
    return int.tryParse(json['id']?.toString() ?? '');
  }

  bool _isSupplierPartyType(PartyTypeModel partyType) {
    final json = partyType.toJson();
    final code = (json['code'] ?? json['type_code'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final name = (json['name'] ?? json['type_name'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    return code.contains('supplier') ||
        code.contains('vendor') ||
        name.contains('supplier') ||
        name.contains('vendor');
  }

  Future<void> _loadMappings({int? selectId}) async {
    if (_selectedMasterId == null) {
      setState(() {
        _items = const <ItemSupplierMapModel>[];
        _filteredItems = const <ItemSupplierMapModel>[];
        _initialLoading = false;
      });
      _resetForm();
      return;
    }

    setState(() {
      _pageError = null;
    });

    try {
      final response = await _inventoryService.itemSupplierMaps(
        filters: {
          'per_page': 200,
          'sort_by': 'is_primary_supplier',
          'sort_order': 'desc',
          if (_isItemWise) 'item_id': _selectedMasterId,
          if (!_isItemWise) 'supplier_party_id': _selectedMasterId,
        },
      );
      final items = response.data ?? const <ItemSupplierMapModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _filteredItems = items;
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<ItemSupplierMapModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<ItemSupplierMapModel?>().firstWhere(
                    (item) => item?.id == _selectedItem?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
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
      return [item.itemCode, item.itemName];
    });
  }

  List<PartyModel> _filterMasterSuppliers(
    List<PartyModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (party) {
      return [
        party.partyCode ?? '',
        party.displayName ?? '',
        party.partyName ?? '',
        party.partyType ?? '',
      ];
    });
  }

  void _applyMasterSearch() {
    setState(() {
      _filteredMastersItems = _filterMasterItems(
        _allItems,
        _masterSearchController.text,
      );
      _filteredMasterSuppliers = _filterMasterSuppliers(
        _allSuppliers,
        _masterSearchController.text,
      );
    });
  }

  void _selectMapping(ItemSupplierMapModel item) {
    if (_selectedItem?.id == item.id) {
      _resetForm();
      return;
    }
    _showDraftTile = false;
    _selectedItem = item;
    _counterpartyId = _isItemWise ? item.supplierId : item.itemId;
    _purchaseUomId = item.purchaseUomId;
    _supplierItemCodeController.text = item.supplierItemCode ?? '';
    _supplierItemNameController.text = item.supplierItemName ?? '';
    _supplierRateController.text = item.supplierRate?.toString() ?? '';
    _leadTimeDaysController.text = item.leadTimeDays?.toString() ?? '';
    _minOrderQtyController.text = item.minOrderQty?.toString() ?? '';
    _remarksController.text = item.remarks ?? '';
    _isPrimarySupplier = item.isPrimarySupplier;
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedItem = null;
    _counterpartyId = null;
    _purchaseUomId = _defaultPurchaseUomId;
    _supplierItemCodeController.clear();
    _supplierItemNameController.clear();
    _supplierRateController.clear();
    _leadTimeDaysController.clear();
    _minOrderQtyController.clear();
    _remarksController.clear();
    _isPrimarySupplier = false;
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  ItemModel? get _currentItemForUomRules {
    if (_isItemWise) {
      return widget.fixedItem ??
          _allItems.cast<ItemModel?>().firstWhere(
            (item) => item?.id == _selectedMasterId,
            orElse: () => null,
          );
    }

    return _allItems.cast<ItemModel?>().firstWhere(
      (item) => item?.id == _counterpartyId,
      orElse: () => null,
    );
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

  List<UomModel> get _allowedPurchaseUoms {
    final allowedIds = _allowedUomIdsForItem(_currentItemForUomRules);
    if (_selectedItem?.purchaseUomId != null) {
      allowedIds.add(_selectedItem!.purchaseUomId!);
    }
    if (allowedIds.isEmpty) {
      return _uoms;
    }

    return _uoms
        .where((uom) => uom.id != null && allowedIds.contains(uom.id))
        .toList(growable: false);
  }

  int? get _defaultPurchaseUomId {
    final item = _currentItemForUomRules;
    final allowedIds = _allowedUomIdsForItem(item);
    final preferred = <int?>[
      item?.purchaseUomId,
      item?.baseUomId,
      item?.salesUomId,
    ];

    for (final id in preferred) {
      if (id != null && (allowedIds.isEmpty || allowedIds.contains(id))) {
        return id;
      }
    }

    return _allowedPurchaseUoms.isNotEmpty
        ? _allowedPurchaseUoms.first.id
        : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedMasterId == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = ItemSupplierMapModel(
      id: _selectedItem?.id,
      itemId: _isItemWise ? _selectedMasterId : _counterpartyId,
      supplierId: _isItemWise ? _counterpartyId : _selectedMasterId,
      supplierItemCode: nullIfEmpty(_supplierItemCodeController.text),
      supplierItemName: nullIfEmpty(_supplierItemNameController.text),
      purchaseUomId: _purchaseUomId,
      supplierRate: double.tryParse(_supplierRateController.text.trim()),
      leadTimeDays: int.tryParse(_leadTimeDaysController.text.trim()),
      minOrderQty: double.tryParse(_minOrderQtyController.text.trim()),
      isPrimarySupplier: _isPrimarySupplier,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedItem == null
          ? await _inventoryService.createItemSupplierMap(model)
          : await _inventoryService.updateItemSupplierMap(
              _selectedItem!.id!,
              model,
            );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      _showDraftTile = false;
      _resetForm();
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
      final response = await _inventoryService.deleteItemSupplierMap(id);
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

  Future<void> _confirmDelete(ItemSupplierMapModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final label = _isItemWise
            ? (item.supplierName.isNotEmpty
                  ? item.supplierName
                  : item.supplierCode)
            : (item.itemName.isNotEmpty ? item.itemName : item.itemCode);
        return AlertDialog(
          title: Text(_isItemWise ? 'Remove Supplier' : 'Remove Item'),
          content: Text(
            _isItemWise
                ? 'Remove $label from this item suppliers list?'
                : 'Remove $label from this supplier items list?',
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

  void _startNew() {
    _showDraftTile = true;
    _resetForm();
    if (widget.fixedItemId == null && !Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  void _selectMaster(int? id) {
    if (id == null) {
      return;
    }
    setState(() {
      _selectedMasterId = id;
    });
    _loadMappings();
  }

  String _itemLabel(ItemModel item) {
    final name = item.itemName.trim();
    final code = item.itemCode.trim();
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }
    return name.isNotEmpty ? name : code;
  }

  String _supplierLabel(PartyModel party) {
    final name = (party.displayName ?? party.partyName ?? '').trim();
    final code = (party.partyCode ?? '').trim();
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }
    return name.isNotEmpty ? name : code;
  }

  String _itemSubtitle(ItemModel item) {
    return [
      item.itemType ?? '',
      item.categoryName ?? item.categoryCode ?? '',
      item.baseUomSymbol ?? item.baseUomCode ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  String _supplierSubtitle(PartyModel party) {
    return [
      party.partyType ?? '',
      party.defaultCurrency ?? '',
      party.pan ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  String get _selectedMasterTitle {
    if (_selectedMasterId == null) {
      return _pageTitle;
    }

    if (_isItemWise) {
      final item = _allItems.cast<ItemModel?>().firstWhere(
        (entry) => entry?.id == _selectedMasterId,
        orElse: () => null,
      );
      return item == null ? _pageTitle : _itemLabel(item);
    }

    final supplier = _allSuppliers.cast<PartyModel?>().firstWhere(
      (entry) => entry?.id == _selectedMasterId,
      orElse: () => null,
    );
    return supplier == null ? _pageTitle : _supplierLabel(supplier);
  }

  List<dynamic> get _availableCounterpartyOptions {
    final selectedIds = _items
        .map((item) => _isItemWise ? item.supplierId : item.itemId)
        .whereType<int>()
        .toSet();

    if (_isItemWise) {
      return _allSuppliers
          .where((party) => party.id != null && !selectedIds.contains(party.id))
          .toList(growable: false);
    }

    return _allItems
        .where((item) => !selectedIds.contains(item.id))
        .toList(growable: false);
  }

  List<dynamic> get _dropdownCounterpartyOptions {
    final options = _availableCounterpartyOptions.toList(growable: true);
    if (_counterpartyId != null) {
      final dynamic selected = _isItemWise
          ? _allSuppliers.cast<PartyModel?>().firstWhere(
              (entry) => entry?.id == _counterpartyId,
              orElse: () => null,
            )
          : _allItems.cast<ItemModel?>().firstWhere(
              (entry) => entry?.id == _counterpartyId,
              orElse: () => null,
            );
      final selectedId = _isItemWise
          ? (selected as PartyModel?)?.id
          : (selected as ItemModel?)?.id;
      if (selected != null &&
          options.every((option) => option.id != selectedId)) {
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
        onPressed: _selectedMasterId == null ? null : _startNew,
        icon: _isItemWise
            ? Icons.local_shipping_outlined
            : Icons.inventory_2_outlined,
        label: _isItemWise ? 'Add Supplier' : 'Add Item',
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

    if (widget.fixedItemId != null) {
      return _selectedMasterId == null
          ? const SettingsEmptyState(
              icon: Icons.local_shipping_outlined,
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
      list: SettingsListCard<dynamic>(
        searchController: _masterSearchController,
        searchHint: 'Search $_masterLabel',
        items: _isItemWise ? _filteredMastersItems : _filteredMasterSuppliers,
        selectedItem: _isItemWise
            ? _allItems.cast<ItemModel?>().firstWhere(
                (item) => item?.id == _selectedMasterId,
                orElse: () => null,
              )
            : _allSuppliers.cast<PartyModel?>().firstWhere(
                (party) => party?.id == _selectedMasterId,
                orElse: () => null,
              ),
        emptyMessage: 'No $_masterLabel records found.',
        itemBuilder: (entry, selected) {
          if (_isItemWise) {
            final item = entry as ItemModel;
            return SettingsListTile(
              title: item.itemName,
              subtitle: item.itemCode,
              selected: selected,
              onTap: () => _selectMaster(item.id),
            );
          }

          final supplier = entry as PartyModel;
          return SettingsListTile(
            title: supplier.displayName ?? supplier.partyName ?? '-',
            subtitle: supplier.partyCode ?? '',
            selected: selected,
            onTap: () => _selectMaster(supplier.id),
          );
        },
      ),
      editor: AppSectionCard(
        child: _selectedMasterId == null
            ? SettingsEmptyState(
                icon: _isItemWise
                    ? Icons.inventory_2_outlined
                    : Icons.local_shipping_outlined,
                title: 'Select $_masterLabel',
                message:
                    'Choose a $_masterLabel from the left to manage ${_counterpartyLabel.toLowerCase()} mappings.',
              )
            : _buildEditorBody(),
      ),
    );
  }

  Widget _buildEditorBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fixedItemId != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: AppActionButton(
              icon: Icons.local_shipping_outlined,
              label: 'Add Supplier',
              onPressed: _selectedMasterId == null ? null : _startNew,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
        ],
        if (_filteredItems.isEmpty && !_showDraftTile) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppUiConstants.spacingMd,
            ),
            child: Text(
              _isItemWise
                  ? 'No suppliers mapped for this item.'
                  : 'No items mapped for this supplier.',
            ),
          ),
        ],
        if (_showDraftTile && _selectedItem == null) ...[
          SettingsExpandableTile(
            key: const ValueKey('supplier-map-draft'),
            title: _counterpartyId == null
                ? (_isItemWise ? 'New Supplier' : 'New Item')
                : _selectedDraftCounterpartyLabel,
            subtitle: _isItemWise
                ? 'Add a supplier for this item.'
                : 'Add an item for this supplier.',
            expanded: true,
            highlighted: true,
            leadingIcon: Icons.add_outlined,
            onToggle: () {
              setState(() {
                _showDraftTile = false;
              });
              _resetForm();
            },
            child: _buildMappingForm(),
          ),
          if (_filteredItems.isNotEmpty)
            const SizedBox(height: AppUiConstants.spacingSm),
        ],
        ..._filteredItems.map((item) {
          final expanded = identical(item, _selectedItem);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: SettingsExpandableTile(
              key: ValueKey('supplier-map-${item.id}-$expanded'),
              title: _isItemWise
                  ? (item.supplierName.isNotEmpty
                        ? item.supplierName
                        : item.supplierCode)
                  : (item.itemName.isNotEmpty ? item.itemName : item.itemCode),
              subtitle: [
                if (item.supplierItemCode != null) item.supplierItemCode!,
                if (item.purchaseUomSymbol.isNotEmpty) item.purchaseUomSymbol,
                if (item.supplierRate != null) 'Rate ${item.supplierRate}',
                if (item.isPrimarySupplier) 'Primary',
              ].join(' · '),
              expanded: expanded,
              highlighted: expanded,
              trailing: IconButton(
                tooltip: _isItemWise ? 'Remove supplier' : 'Remove item',
                onPressed: _saving ? null : () => _confirmDelete(item),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              onToggle: () {
                if (expanded) {
                  _resetForm();
                } else {
                  _selectMapping(item);
                }
              },
              child: _buildMappingForm(),
            ),
          );
        }),
      ],
    );
  }

  String get _selectedDraftCounterpartyLabel {
    if (_counterpartyId == null) {
      return _isItemWise ? 'New Supplier' : 'New Item';
    }
    if (_isItemWise) {
      final supplier = _allSuppliers.cast<PartyModel?>().firstWhere(
        (entry) => entry?.id == _counterpartyId,
        orElse: () => null,
      );
      return supplier == null ? 'New Supplier' : _supplierLabel(supplier);
    }
    final item = _allItems.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == _counterpartyId,
      orElse: () => null,
    );
    return item == null ? 'New Item' : _itemLabel(item);
  }

  Widget _buildMappingForm() {
    final dynamic selectedCounterparty = _counterpartyId == null
        ? null
        : (_isItemWise
              ? _allSuppliers.cast<PartyModel?>().firstWhere(
                  (entry) => entry?.id == _counterpartyId,
                  orElse: () => null,
                )
              : _allItems.cast<ItemModel?>().firstWhere(
                  (entry) => entry?.id == _counterpartyId,
                  orElse: () => null,
                ));

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_formError != null) ...[
            AppErrorStateView.inline(message: _formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          if (widget.fixedItemId != null && _selectedItem == null)
            AppSearchPickerField<int>(
              labelText: _counterpartyLabel,
              selectedLabel: selectedCounterparty == null
                  ? null
                  : (_isItemWise
                        ? _supplierLabel(selectedCounterparty as PartyModel)
                        : _itemLabel(selectedCounterparty as ItemModel)),
              hintText: _isItemWise
                  ? 'Search supplier to add to this item'
                  : 'Search item to add for this supplier',
              options: _availableCounterpartyOptions
                  .where((entry) => entry.id != null)
                  .map(
                    (entry) => AppSearchPickerOption<int>(
                      value: entry.id as int,
                      label: _isItemWise
                          ? _supplierLabel(entry as PartyModel)
                          : _itemLabel(entry as ItemModel),
                      subtitle: _isItemWise
                          ? _supplierSubtitle(entry as PartyModel)
                          : _itemSubtitle(entry as ItemModel),
                      searchText: _isItemWise
                          ? [
                              (entry as PartyModel).partyName ?? '',
                              entry.website ?? '',
                              entry.remarks ?? '',
                            ].join(' ')
                          : [
                              (entry as ItemModel).sku ?? '',
                              entry.hsnSacCode ?? '',
                              entry.brandName ?? entry.brandCode ?? '',
                            ].join(' '),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _counterpartyId = value;
                  if (!_allowedUomIdsForItem(
                    _currentItemForUomRules,
                  ).contains(_purchaseUomId)) {
                    _purchaseUomId = _defaultPurchaseUomId;
                  }
                });
              },
              validator: (_) => _counterpartyId == null
                  ? '$_counterpartyLabel is required'
                  : null,
            )
          else if (widget.fixedItemId != null && selectedCounterparty != null)
            Text(
              _isItemWise
                  ? _supplierLabel(selectedCounterparty as PartyModel)
                  : _itemLabel(selectedCounterparty as ItemModel),
              style: Theme.of(context).textTheme.titleMedium,
            )
          else
            DropdownButtonFormField<int>(
              initialValue: _counterpartyId,
              decoration: InputDecoration(labelText: _counterpartyLabel),
              items: _dropdownCounterpartyOptions
                  .where((entry) => entry.id != null)
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.id as int,
                      child: Text(
                        _isItemWise
                            ? _supplierLabel(entry as PartyModel)
                            : _itemLabel(entry as ItemModel),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                setState(() {
                  _counterpartyId = value;
                  if (!_allowedUomIdsForItem(
                    _currentItemForUomRules,
                  ).contains(_purchaseUomId)) {
                    _purchaseUomId = _defaultPurchaseUomId;
                  }
                });
              },
              validator: (value) =>
                  Validators.requiredSelectionField(value, _counterpartyLabel),
            ),
          const SizedBox(height: 12),
          SettingsFormWrap(
            children: [
              AppFormTextField(
                labelText: 'Supplier Item Code',
                controller: _supplierItemCodeController,
                validator: Validators.optionalMaxLength(
                  100,
                  'Supplier Item Code',
                ),
              ),
              AppFormTextField(
                labelText: 'Supplier Item Name',
                controller: _supplierItemNameController,
                validator: Validators.optionalMaxLength(
                  255,
                  'Supplier Item Name',
                ),
              ),
              DropdownButtonFormField<int>(
                initialValue: _purchaseUomId,
                decoration: const InputDecoration(labelText: 'Purchase UOM'),
                items: _allowedPurchaseUoms
                    .where((uom) => uom.id != null)
                    .map(
                      (uom) => DropdownMenuItem<int>(
                        value: uom.id,
                        child: Text(uom.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _purchaseUomId = value),
              ),
              AppFormTextField(
                labelText: 'Supplier Rate',
                controller: _supplierRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Supplier Rate',
                ),
              ),
              AppFormTextField(
                labelText: 'Lead Time Days',
                controller: _leadTimeDaysController,
                keyboardType: TextInputType.number,
                validator: Validators.optionalNonNegativeInteger(
                  'Lead Time Days',
                ),
              ),
              AppFormTextField(
                labelText: 'Minimum Order Quantity',
                controller: _minOrderQtyController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Minimum Order Quantity',
                ),
              ),
              AppFormTextField(
                labelText: 'Remarks',
                controller: _remarksController,
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Wrap(
            spacing: AppUiConstants.spacingMd,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              SizedBox(
                width: AppUiConstants.switchFieldWidth,
                child: AppSwitchTile(
                  label: 'Primary Supplier',
                  value: _isPrimarySupplier,
                  onChanged: (value) =>
                      setState(() => _isPrimarySupplier = value),
                ),
              ),
              SizedBox(
                width: AppUiConstants.switchFieldWidth,
                child: AppSwitchTile(
                  label: 'Active',
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_selectedItem?.id != null)
                TextButton(
                  onPressed: _saving ? null : _delete,
                  child: const Text('Delete'),
                ),
              const SizedBox(width: AppUiConstants.spacingSm),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
