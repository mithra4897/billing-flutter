import '../../../controller/settings/master/item_supplier_map_management_controller.dart';
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
  late final String _controllerTag;
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  String _statusFilter = '';
  String _categoryFilter = '';

  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All status'),
      ];

  Future<void> _openFilterPanel(
    BuildContext context,
    ItemSupplierMapManagementController controller,
  ) {
    return openInventorySearchStatusCategoryFilterPanel(
      context: context,
      title: 'Filter ${controller.pageTitle}',
      searchController: controller.masterSearchController,
      dateFromController: _dateFromController,
      dateToController: _dateToController,
      searchHint: controller.isItemWise
          ? 'Item code or item name'
          : 'Supplier code or supplier name',
      status: _statusFilter,
      statusItems: _statusItems,
      category: _categoryFilter,
      categoryItems: _buildCategoryItems(controller),
      onApply: (search, status, dateFrom, dateTo, category) {
        setState(() {
          controller.masterSearchController.text = search;
          _dateFromController.text = dateFrom;
          _dateToController.text = dateTo;
          _statusFilter = status;
          _categoryFilter = category;
        });
      },
      onClear: () {
        setState(() {
          controller.masterSearchController.clear();
          _dateFromController.clear();
          _dateToController.clear();
          _statusFilter = '';
          _categoryFilter = '';
        });
      },
    );
  }

  List<AppDropdownItem<String>> _buildCategoryItems(
    ItemSupplierMapManagementController controller,
  ) {
    final seen = <String>{};
    final values = controller.allItems
        .map((item) => (item.categoryName ?? item.categoryCode ?? '').trim())
        .where((value) => value.isNotEmpty && seen.add(value))
        .toList(growable: false);
    return <AppDropdownItem<String>>[
      const AppDropdownItem<String>(value: '', label: 'All categories'),
      ...values.map(
        (value) => AppDropdownItem<String>(value: value, label: value),
      ),
    ];
  }

  List<dynamic> _visibleMasters(
    ItemSupplierMapManagementController controller,
  ) {
    if (!controller.isItemWise) {
      return controller.filteredMasterSuppliers;
    }
    return controller.filteredMastersItems
        .where((item) {
          return _categoryFilter.isEmpty ||
              (item.categoryName ?? item.categoryCode ?? '').trim() ==
                  _categoryFilter;
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ItemSupplierMapManagementController'
      '-${widget.mode.name}-${widget.fixedItemId ?? 'all'}',
    );
    Get.put(
      ItemSupplierMapManagementController(
        mode: widget.mode,
        fixedItemId: widget.fixedItemId,
        fixedItem: widget.fixedItem,
        fixedItemLabel: widget.fixedItemLabel,
      ),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ItemSupplierMapManagementController controller,
    ItemSupplierMapModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final label = controller.isItemWise
            ? (item.supplierName.isNotEmpty
                  ? item.supplierName
                  : item.supplierCode)
            : (item.itemName.isNotEmpty ? item.itemName : item.itemCode);
        return AlertDialog(
          title: Text(
            controller.isItemWise ? 'Remove Supplier' : 'Remove Item',
          ),
          content: Text(
            controller.isItemWise
                ? 'Remove $label from this item suppliers list?'
                : 'Remove $label from this supplier items list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await controller.deleteSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemSupplierMapManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => _openFilterPanel(context, controller),
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: false,
          ),
          AdaptiveShellActionButton(
            onPressed: controller.selectedMasterId == null
                ? null
                : () => controller.startNew(
                    isDesktop: Responsive.isDesktop(context),
                  ),
            icon: controller.isItemWise
                ? Icons.local_shipping_outlined
                : Icons.inventory_2_outlined,
            label: controller.isItemWise ? 'Add Supplier' : 'Add Item',
          ),
        ];

        if (widget.fixedItemId != null) {
          return _buildContent(context, controller);
        }

        if (widget.embedded) {
          return ShellPageActions(
            actions: actions,
            child: _buildContent(context, controller),
          );
        }

        return AppStandaloneShell(
          title: controller.pageTitle,
          scrollController: controller.pageScrollController,
          actions: actions,
          child: _buildContent(context, controller),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ItemSupplierMapManagementController controller,
  ) {
    if (controller.initialLoading) {
      return AppLoadingView(
        message: 'Loading ${controller.pageTitle.toLowerCase()}...',
      );
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load ${controller.pageTitle.toLowerCase()}',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    if (widget.fixedItemId != null) {
      return controller.selectedMasterId == null
          ? const SettingsEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Item Not Found',
              message: 'The selected item is not available.',
            )
          : _buildEditorBody(context, controller);
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: controller.pageTitle,
      editorTitle: controller.selectedMasterTitle,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<dynamic>(
        searchController: controller.masterSearchController,
        searchHint: 'Search ${controller.masterLabel}',
        items: _visibleMasters(controller),
        selectedItem: controller.isItemWise
            ? controller.allItems.cast<ItemModel?>().firstWhere(
                (item) => item?.id == controller.selectedMasterId,
                orElse: () => null,
              )
            : controller.allSuppliers.cast<PartyModel?>().firstWhere(
                (party) => party?.id == controller.selectedMasterId,
                orElse: () => null,
              ),
        emptyMessage: 'No ${controller.masterLabel} records found.',
        itemBuilder: (entry, selected) {
          if (controller.isItemWise) {
            final item = entry as ItemModel;
            return SettingsListTile(
              title: item.itemName,
              subtitle: item.itemCode,
              selected: selected,
              onTap: () => controller.selectMaster(item.id),
            );
          }
          final supplier = entry as PartyModel;
          return SettingsListTile(
            title: supplier.displayName ?? supplier.partyName ?? '-',
            subtitle: supplier.partyCode ?? '',
            selected: selected,
            onTap: () => controller.selectMaster(supplier.id),
          );
        },
      ),
      editorBuilder: (_) => AppSectionCard(
        child: controller.selectedMasterId == null
            ? SettingsEmptyState(
                icon: controller.isItemWise
                    ? Icons.inventory_2_outlined
                    : Icons.local_shipping_outlined,
                title: 'Select ${controller.masterLabel}',
                message:
                    'Choose a ${controller.masterLabel} from the left to manage ${controller.counterpartyLabel.toLowerCase()} mappings.',
              )
            : _buildEditorBody(context, controller),
      ),
    );
  }

  Widget _buildEditorBody(
    BuildContext context,
    ItemSupplierMapManagementController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fixedItemId != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: AppActionButton(
              icon: Icons.local_shipping_outlined,
              label: 'Add Supplier',
              onPressed: controller.selectedMasterId == null
                  ? null
                  : () => controller.startNew(
                      isDesktop: Responsive.isDesktop(context),
                    ),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
        ],
        if (controller.filteredItems.isEmpty && !controller.showDraftTile)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppUiConstants.spacingMd,
            ),
            child: Text(
              controller.isItemWise
                  ? 'No suppliers mapped for this item.'
                  : 'No items mapped for this supplier.',
            ),
          ),
        if (controller.showDraftTile && controller.selectedItem == null) ...[
          SettingsExpandableTile(
            key: const ValueKey('supplier-map-draft'),
            title: controller.selectedDraftCounterpartyLabel,
            subtitle: controller.isItemWise
                ? 'Add a supplier for this item.'
                : 'Add an item for this supplier.',
            expanded: true,
            highlighted: true,
            leadingIcon: Icons.add_outlined,
            onToggle: controller.hideDraftTile,
            child: _buildMappingForm(context, controller),
          ),
          if (controller.filteredItems.isNotEmpty)
            const SizedBox(height: AppUiConstants.spacingSm),
        ],
        ...controller.filteredItems.map((item) {
          final expanded = identical(item, controller.selectedItem);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: SettingsExpandableTile(
              key: ValueKey('supplier-map-${item.id}-$expanded'),
              title: controller.isItemWise
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
                tooltip: controller.isItemWise
                    ? 'Remove supplier'
                    : 'Remove item',
                onPressed: controller.saving
                    ? null
                    : () => _confirmDelete(context, controller, item),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              onToggle: () {
                if (expanded) {
                  controller.resetForm();
                } else {
                  controller.selectMapping(item);
                }
              },
              child: _buildMappingForm(context, controller),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMappingForm(
    BuildContext context,
    ItemSupplierMapManagementController controller,
  ) {
    final selectedCounterparty = controller.selectedCounterparty;

    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.formError != null) ...[
            AppErrorStateView.inline(message: controller.formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          if (widget.fixedItemId != null && controller.selectedItem == null)
            AppSearchPickerField<int>(
              labelText: controller.counterpartyLabel,
              selectedLabel: selectedCounterparty == null
                  ? null
                  : (controller.isItemWise
                        ? controller.supplierLabel(
                            selectedCounterparty as PartyModel,
                          )
                        : controller.itemLabel(
                            selectedCounterparty as ItemModel,
                          )),
              hintText: controller.isItemWise
                  ? 'Search supplier to add to this item'
                  : 'Search item to add for this supplier',
              options: controller.availableCounterpartyOptions
                  .where((entry) => entry.id != null)
                  .map(
                    (entry) => AppSearchPickerOption<int>(
                      value: entry.id as int,
                      label: controller.isItemWise
                          ? controller.supplierLabel(entry as PartyModel)
                          : controller.itemLabel(entry as ItemModel),
                      subtitle: controller.isItemWise
                          ? controller.supplierSubtitle(entry as PartyModel)
                          : controller.itemSubtitle(entry as ItemModel),
                      searchText: controller.isItemWise
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
              onChanged: controller.setCounterpartyId,
              validator: (_) => controller.counterpartyId == null
                  ? '${controller.counterpartyLabel} is required'
                  : null,
            )
          else if (widget.fixedItemId != null && selectedCounterparty != null)
            Text(
              controller.isItemWise
                  ? controller.supplierLabel(selectedCounterparty as PartyModel)
                  : controller.itemLabel(selectedCounterparty as ItemModel),
              style: Theme.of(context).textTheme.titleMedium,
            )
          else
            DropdownButtonFormField<int>(
              initialValue: controller.counterpartyId,
              decoration: InputDecoration(
                labelText: controller.counterpartyLabel,
              ),
              items: controller.dropdownCounterpartyOptions
                  .where((entry) => entry.id != null)
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.id as int,
                      child: Text(
                        controller.isItemWise
                            ? controller.supplierLabel(entry as PartyModel)
                            : controller.itemLabel(entry as ItemModel),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: controller.setCounterpartyId,
              validator: (value) => Validators.requiredSelectionField(
                value,
                controller.counterpartyLabel,
              ),
            ),
          const SizedBox(height: 12),
          SettingsFormWrap(
            children: [
              AppFormTextField(
                labelText: 'Supplier Item Code',
                controller: controller.supplierItemCodeController,
                validator: Validators.optionalMaxLength(
                  100,
                  'Supplier Item Code',
                ),
              ),
              AppFormTextField(
                labelText: 'Supplier Item Name',
                controller: controller.supplierItemNameController,
                validator: Validators.optionalMaxLength(
                  255,
                  'Supplier Item Name',
                ),
              ),
              DropdownButtonFormField<int>(
                initialValue: controller.purchaseUomId,
                decoration: const InputDecoration(labelText: 'Purchase UOM'),
                items: controller.allowedPurchaseUoms
                    .where((uom) => uom.id != null)
                    .map(
                      (uom) => DropdownMenuItem<int>(
                        value: uom.id,
                        child: Text(uom.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.setPurchaseUomId,
              ),
              AppFormTextField(
                labelText: 'Supplier Rate',
                controller: controller.supplierRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Supplier Rate',
                ),
              ),
              AppFormTextField(
                labelText: 'Lead Time Days',
                controller: controller.leadTimeDaysController,
                keyboardType: TextInputType.number,
                validator: Validators.optionalNonNegativeInteger(
                  'Lead Time Days',
                ),
              ),
              AppFormTextField(
                labelText: 'Minimum Order Quantity',
                controller: controller.minOrderQtyController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Minimum Order Quantity',
                ),
              ),
              AppFormTextField(
                labelText: 'Remarks',
                controller: controller.remarksController,
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
                  value: controller.isPrimarySupplier,
                  onChanged: controller.setIsPrimarySupplier,
                ),
              ),
              SizedBox(
                width: AppUiConstants.switchFieldWidth,
                child: AppSwitchTile(
                  label: 'Active',
                  value: controller.isActive,
                  onChanged: controller.setIsActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (controller.selectedItem?.id != null)
                TextButton(
                  onPressed: controller.saving
                      ? null
                      : controller.deleteSelected,
                  child: const Text('Delete'),
                ),
              const SizedBox(width: AppUiConstants.spacingSm),
              FilledButton.icon(
                onPressed: controller.saving ? null : controller.save,
                icon: const Icon(Icons.save_outlined),
                label: Text(controller.saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
