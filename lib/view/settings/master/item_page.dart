import '../../../controller/settings/master/item_management_controller.dart';
import '../../../screen.dart';

class ItemManagementPage extends StatefulWidget {
  const ItemManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ItemManagementPage> createState() => _ItemManagementPageState();
}

class _ItemManagementPageState extends State<ItemManagementPage>
    with SingleTickerProviderStateMixin {
  late final String _controllerTag;
  late final ItemManagementController _controller;
  late final TabController _tabController;
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  String _statusFilter = '';
  String _categoryFilter = '';
  Set<int> _selectedItemIds = <int>{};
  bool _filtersVisible = false;

  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All status'),
        AppDropdownItem(value: 'active', label: 'Active'),
        AppDropdownItem(value: 'inactive', label: 'Inactive'),
      ];

  List<AppDropdownItem<String>> _buildCategoryItems(
    ItemManagementController controller,
  ) {
    return <AppDropdownItem<String>>[
      const AppDropdownItem<String>(value: '', label: 'All categories'),
      ...controller.categories.map(
        (category) => AppDropdownItem<String>(
          value: category.categoryName,
          label: category.categoryName,
        ),
      ),
    ];
  }

  List<ItemModel> _visibleItems(ItemManagementController controller) {
    return controller.filteredItems
        .where(
          (item) =>
              _selectedItemIds.isEmpty || _selectedItemIds.contains(item.id),
        )
        .toList(growable: false);
  }

  Widget _buildSharedFilters(ItemManagementController controller) {
    return SharedFilterBar(
      statusItems: _statusItems,
      selectedStatuses: {if (_statusFilter.isNotEmpty) _statusFilter},
      onStatusesChanged: (values) {
        final value = values.isEmpty ? '' : values.first;
        setState(() => _statusFilter = value);
        controller.setListFilters(
          status: value,
          category: _categoryFilter,
          dateFrom: _dateFromController.text,
          dateTo: _dateToController.text,
        );
      },
      categoryItems: _buildCategoryItems(controller),
      selectedCategories: {if (_categoryFilter.isNotEmpty) _categoryFilter},
      onCategoriesChanged: (values) {
        final value = values.isEmpty ? '' : values.first;
        setState(() => _categoryFilter = value);
        controller.setListFilters(
          status: _statusFilter,
          category: value,
          dateFrom: _dateFromController.text,
          dateTo: _dateToController.text,
        );
      },
      itemLabel: 'Product',
      itemItems: controller.items
          .where((item) => item.id != null)
          .map(
            (item) => AppDropdownItem<int>(
              value: item.id!,
              label: '${item.itemName} (${item.itemCode})',
            ),
          )
          .toList(growable: false),
      selectedItemIds: _selectedItemIds,
      onItemsChanged: (values) => setState(() => _selectedItemIds = values),
      showDateFilters: false,
      onClear: () {
        setState(() {
          _statusFilter = '';
          _categoryFilter = '';
          _selectedItemIds = <int>{};
        });
        controller.setListFilters(
          status: '',
          category: '',
          dateFrom: '',
          dateTo: '',
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ItemManagementController',
      scope: <String, Object?>{
        'identity': identityHashCode(this),
        'embedded': widget.embedded,
      },
    );
    _controller = Get.put(ItemManagementController(), tag: _controllerTag);
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _controller.setActiveTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    _tabController.dispose();
    if (Get.isRegistered<ItemManagementController>(tag: _controllerTag)) {
      Get.delete<ItemManagementController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: _filtersVisible,
          ),
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.inventory_2_outlined,
            label: 'New Item',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Items',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ItemManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading items...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load items',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    if (_tabController.index != controller.activeTabIndex) {
      _tabController.index = controller.activeTabIndex;
    }

    // Migrated page/form state now lives in ItemManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Items',
      editorTitle: controller.selectedItem?.toString(),
      scrollController: controller.pageScrollController,
      listOnly: true,
      list: SharedRegisterList<ItemModel>(
        title: 'Items',
        loading: false,
        errorMessage: null,
        onRetry: () => controller.loadData(),
        actions: [
          AdaptiveShellSearchField(
            controller: controller.searchController,
            hintText: 'Search items',
          ),
          AdaptiveShellActionButton(
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: _filtersVisible,
          ),
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.inventory_2_outlined,
            label: 'New Item',
          ),
        ],
        filters: _filtersVisible ? _buildSharedFilters(controller) : null,
        rows: _visibleItems(controller),
        columns: [
          PurchaseRegisterColumn<ItemModel>(
            label: 'Code',
            valueBuilder: (item) => item.itemCode,
          ),
          PurchaseRegisterColumn<ItemModel>(
            label: 'Product',
            flex: 3,
            valueBuilder: (item) => item.itemName,
          ),
          PurchaseRegisterColumn<ItemModel>(
            label: 'Type',
            valueBuilder: (item) => item.itemType ?? '',
          ),
          PurchaseRegisterColumn<ItemModel>(
            label: 'Status',
            valueBuilder: (item) => item.isActive ? 'Active' : 'Inactive',
          ),
        ],
        onRowTap: (item) {
          controller.selectItem(item);
          controller.workspaceController.openEditor();
        },
        emptyMessage: 'No item records found.',
        remoteTotalItems: controller.paginationMeta?.total,
        remoteCurrentPage: controller.paginationMeta?.currentPage,
        remotePerPage: controller.paginationMeta?.perPage,
        onRemotePageChanged: controller.goToPage,
        contentSized: true,
        embedded: true,
      ),
      editorBuilder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            onTap: controller.setActiveTabIndex,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Primary'),
              Tab(text: 'Alternate Items'),
              Tab(text: 'Suppliers'),
              Tab(text: 'Item Prices'),
              Tab(text: 'Opening Stock'),
            ],
          ),
          const SizedBox(height: 20),
          IndexedStack(
            index: controller.activeTabIndex,
            children: [
              _buildPrimaryTab(context, controller),
              _buildAlternateItemsTab(controller),
              _buildSuppliersTab(controller),
              _buildItemPricesTab(controller),
              _buildOpeningStockTab(controller),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryTab(
    BuildContext context,
    ItemManagementController controller,
  ) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.formError != null) ...[
            AppErrorStateView.inline(message: controller.formError!),
            const SizedBox(height: 16),
          ],
          SettingsFormWrap(
            children: [
              AppDropdownField<String>.fromMapped(
                labelText: 'Item Type',
                mappedItems: ItemManagementController.itemTypeItems,
                initialValue: controller.itemType,
                onChanged: controller.setItemType,
              ),
              AppFormTextField(
                labelText: 'Item Code',
                controller: controller.codeController,
                validator: Validators.compose([
                  Validators.required('Item code'),
                  Validators.optionalMaxLength(50, 'Item code'),
                ]),
              ),
              AppFormTextField(
                labelText: 'Item Name',
                controller: controller.nameController,
                validator: Validators.compose([
                  Validators.required('Item name'),
                  Validators.optionalMaxLength(255, 'Item name'),
                ]),
              ),
              AppFormTextField(
                labelText: 'Local Name',
                controller: controller.localNameController,
                validator: Validators.optionalMaxLength(255, 'Local name'),
              ),
              DropdownButtonFormField<int?>(
                key: ValueKey<String>(
                  'item-category-${controller.categoryId}-${controller.categories.length}',
                ),
                initialValue: controller.categoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  suffixIcon: IconButton(
                    tooltip: 'Add Category',
                    onPressed: () =>
                        controller.showCreateCategoryDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...controller.categories.map(
                    (category) => DropdownMenuItem<int?>(
                      value: category.id,
                      child: Text(category.toString()),
                    ),
                  ),
                ],
                onChanged: controller.setCategoryId,
              ),
              DropdownButtonFormField<int?>(
                initialValue: controller.brandId,
                decoration: InputDecoration(
                  labelText: 'Brand',
                  suffixIcon: IconButton(
                    tooltip: 'Add Brand',
                    onPressed: () => controller.showCreateBrandDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...controller.brands.map(
                    (brand) => DropdownMenuItem<int?>(
                      value: brand.id,
                      child: Text(brand.toString()),
                    ),
                  ),
                ],
                onChanged: controller.setBrandId,
              ),
              AppDropdownField<int>.fromMapped(
                labelText: 'Base UOM',
                mappedItems: controller.uoms
                    .where((uom) => uom.id != null)
                    .map(
                      (uom) => AppDropdownItem<int>(
                        value: uom.id!,
                        label: uom.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: controller.baseUomId,
                onChanged: controller.setBaseUomId,
                validator: Validators.requiredSelection('Base UOM'),
              ),
              DropdownButtonFormField<int?>(
                initialValue: controller.purchaseUomId,
                decoration: const InputDecoration(labelText: 'Purchase UOM'),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...controller.uoms.map(
                    (uom) => DropdownMenuItem<int?>(
                      value: uom.id,
                      child: Text(uom.toString()),
                    ),
                  ),
                ],
                onChanged: controller.setPurchaseUomId,
              ),
              DropdownButtonFormField<int?>(
                initialValue: controller.salesUomId,
                decoration: const InputDecoration(labelText: 'Sales UOM'),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...controller.uoms.map(
                    (uom) => DropdownMenuItem<int?>(
                      value: uom.id,
                      child: Text(uom.toString()),
                    ),
                  ),
                ],
                onChanged: controller.setSalesUomId,
              ),
              DropdownButtonFormField<int?>(
                initialValue: controller.taxCodeId,
                decoration: InputDecoration(
                  labelText: 'Tax Code',
                  suffixIcon: IconButton(
                    tooltip: 'Add Tax Code',
                    onPressed: () =>
                        controller.showCreateTaxCodeDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...controller.taxCodes.map(
                    (taxCode) => DropdownMenuItem<int?>(
                      value: taxCode.id,
                      child: Text(taxCode.toString()),
                    ),
                  ),
                ],
                onChanged: controller.setTaxCodeId,
              ),
              AppFormTextField(
                labelText: 'SKU',
                controller: controller.skuController,
                validator: Validators.optionalMaxLength(100, 'SKU'),
              ),
              AppFormTextField(
                labelText: 'Barcode',
                controller: controller.barcodeController,
                validator: Validators.optionalMaxLength(100, 'Barcode'),
              ),
              AppFormTextField(
                labelText: 'HSN / SAC',
                controller: controller.hsnController,
                validator: Validators.optionalMaxLength(20, 'HSN / SAC'),
              ),
              AppFormTextField(
                labelText: 'Standard Cost',
                controller: controller.standardCostController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Standard Cost',
                ),
              ),
              AppFormTextField(
                labelText: 'Standard Selling Price',
                controller: controller.standardSellingPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Standard Selling Price',
                ),
              ),
              AppFormTextField(
                labelText: 'MRP',
                controller: controller.mrpController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber('MRP'),
              ),
              AppFormTextField(
                labelText: 'Minimum Stock Level',
                controller: controller.minStockController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Minimum Stock Level',
                ),
              ),
              AppFormTextField(
                labelText: 'Reorder Level',
                controller: controller.reorderLevelController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Reorder Level',
                ),
              ),
              AppFormTextField(
                labelText: 'Reorder Quantity',
                controller: controller.reorderQtyController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Reorder Quantity',
                ),
              ),
              AppFormTextField(
                labelText: 'Weight',
                controller: controller.weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber('Weight'),
              ),
              AppFormTextField(
                labelText: 'Volume',
                controller: controller.volumeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber('Volume'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          UploadPathField(
            controller: controller.imagePathController,
            labelText: 'Image Path',
            isUploading: controller.uploadingImage,
            onUpload: () => controller.uploadItemImage(context),
            previewUrl: AppConfig.resolvePublicFileUrl(
              controller.imagePathController.text,
            ),
            previewIcon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 16),
          AppFormTextField(
            labelText: 'Description',
            controller: controller.descriptionController,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          AppFormTextField(
            labelText: 'Remarks',
            controller: controller.remarksController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Wrap(
            children: [
              AppToggleChip(
                label: 'Track Inventory',
                value: controller.trackInventory,
                onChanged: controller.setTrackInventory,
              ),
              AppToggleChip(
                label: 'Saleable',
                value: controller.isSaleable,
                onChanged: controller.setIsSaleable,
              ),
              AppToggleChip(
                label: 'Purchaseable',
                value: controller.isPurchaseable,
                onChanged: controller.setIsPurchaseable,
              ),
              AppToggleChip(
                label: 'Manufacturable',
                value: controller.isManufacturable,
                onChanged: controller.setIsManufacturable,
              ),
              AppToggleChip(
                label: 'Jobwork Applicable',
                value: controller.isJobworkApplicable,
                onChanged: controller.setIsJobworkApplicable,
              ),
              AppToggleChip(
                label: 'Batch Enabled',
                value: controller.hasBatch,
                onChanged: controller.setHasBatch,
              ),
              AppToggleChip(
                label: 'Serial Enabled',
                value: controller.hasSerial,
                onChanged: controller.setHasSerial,
              ),
              AppToggleChip(
                label: 'Expiry Enabled',
                value: controller.hasExpiry,
                onChanged: controller.setHasExpiry,
              ),
              AppToggleChip(
                label: 'Active',
                value: controller.isActive,
                onChanged: controller.setIsActive,
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
                label: controller.selectedItem == null
                    ? 'Save Item'
                    : 'Update Item',
                onPressed: controller.save,
                busy: controller.saving,
              ),
              if (controller.selectedItem?.id != null)
                AppActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onPressed: controller.saving ? null : controller.delete,
                  filled: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlternateItemsTab(ItemManagementController controller) {
    final item = controller.selectedItem;
    if (item?.id == null) {
      return _buildPendingItemSelectionState('alternate items');
    }

    return ItemAlternateManagementPage(
      key: ValueKey('alt-${item!.id}'),
      fixedItemId: item.id,
      fixedItemLabel: item.toString(),
    );
  }

  Widget _buildSuppliersTab(ItemManagementController controller) {
    final item = controller.selectedItem;
    if (item?.id == null) {
      return _buildPendingItemSelectionState('suppliers');
    }

    return ItemSupplierMapManagementPage(
      key: ValueKey('sup-${item!.id}'),
      mode: ItemSupplierMapViewMode.itemWise,
      fixedItemId: item.id,
      fixedItem: item,
      fixedItemLabel: item.toString(),
    );
  }

  Widget _buildItemPricesTab(ItemManagementController controller) {
    final item = controller.selectedItem;
    if (item?.id == null) {
      return _buildPendingItemSelectionState('item prices');
    }

    return ItemPriceManagementPage(
      key: ValueKey('price-${item!.id}'),
      fixedItemId: item.id,
      fixedItem: item,
      fixedItemLabel: item.toString(),
    );
  }

  Widget _buildOpeningStockTab(ItemManagementController controller) {
    final item = controller.selectedItem;
    if (item?.id == null) {
      return _buildPendingItemSelectionState('opening stock');
    }

    return OpeningStockPage(
      key: ValueKey('opening-${item!.id}'),
      fixedItemId: item.id,
      fixedItemLabel: item.toString(),
    );
  }

  Widget _buildPendingItemSelectionState(String featureLabel) {
    return SettingsEmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Select Or Save Item',
      message:
          'Use the Primary tab to select an existing item or save this item first before managing $featureLabel.',
    );
  }
}
