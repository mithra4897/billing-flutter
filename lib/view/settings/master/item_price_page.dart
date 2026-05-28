import '../../../controller/settings/master/item_price_management_controller.dart';
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
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ItemPriceManagementController'
      '-${widget.fixedItemId ?? 'all'}',
    );
    Get.put(
      ItemPriceManagementController(
        fixedItemId: widget.fixedItemId,
        fixedItem: widget.fixedItem,
        fixedItemLabel: widget.fixedItemLabel,
      ),
      tag: _controllerTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemPriceManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: controller.selectedItemMaster == null
                ? null
                : () => controller.startNew(
                    isDesktop: Responsive.isDesktop(context),
                  ),
            icon: Icons.price_change_outlined,
            label: 'New Price',
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
          title: 'Item Prices',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: _buildContent(context, controller),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ItemPriceManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading item prices...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load item prices',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    if (widget.fixedItemId != null) {
      return controller.selectedItemMaster == null
          ? const SettingsEmptyState(
              icon: Icons.price_change_outlined,
              title: 'Item Not Found',
              message: 'The selected item is not available.',
            )
          : _buildEditorBody(context, controller);
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Item Prices',
      editorTitle: controller.selectedItemMaster?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<ItemModel>(
        searchController: controller.masterSearchController,
        searchHint: 'Search items',
        items: controller.filteredItems,
        selectedItem: controller.selectedItemMaster,
        emptyMessage: 'No items found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.itemName,
          subtitle: item.itemCode,
          selected: selected,
          onTap: () => controller.selectMasterItem(item),
        ),
      ),
      editor: AppSectionCard(
        child: controller.selectedItemMaster == null
            ? const SettingsEmptyState(
                icon: Icons.price_change_outlined,
                title: 'Select Item',
                message: 'Choose an item from the left to manage price rows.',
              )
            : _buildEditorBody(context, controller),
      ),
    );
  }

  Widget _buildEditorBody(
    BuildContext context,
    ItemPriceManagementController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fixedItemId != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: AppActionButton(
              icon: Icons.price_change_outlined,
              label: 'New Price',
              onPressed: () =>
                  controller.startNew(isDesktop: Responsive.isDesktop(context)),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
        ],
        if (controller.filteredPrices.isEmpty && !controller.showDraftTile)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppUiConstants.spacingMd),
            child: Text('No price rows found for this item.'),
          ),
        if (controller.showDraftTile && controller.selectedPrice == null) ...[
          SettingsExpandableTile(
            key: const ValueKey('price-draft'),
            title: 'New Price',
            subtitle: 'Add a price row for this item.',
            expanded: true,
            highlighted: true,
            leadingIcon: Icons.add_outlined,
            onToggle: controller.hideDraftTile,
            child: _buildPriceForm(context, controller),
          ),
          if (controller.filteredPrices.isNotEmpty)
            const SizedBox(height: AppUiConstants.spacingSm),
        ],
        ...controller.filteredPrices.map((price) {
          final expanded = identical(price, controller.selectedPrice);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: SettingsExpandableTile(
              key: ValueKey('price-${price.id}-$expanded'),
              title:
                  '${price.priceType ?? '-'} · ${price.price?.toString() ?? '0'}',
              subtitle: [
                if ((price.uomName ?? '').isNotEmpty) price.uomName!,
                if ((price.validFrom ?? '').isNotEmpty)
                  'From ${price.validFrom}',
                if ((price.validTo ?? '').isNotEmpty) 'To ${price.validTo}',
                if (price.isDefault) 'Default',
              ].join(' · '),
              expanded: expanded,
              highlighted: expanded,
              onToggle: () {
                if (expanded) {
                  controller.resetForm();
                } else {
                  controller.selectPrice(price);
                }
              },
              child: _buildPriceForm(context, controller),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPriceForm(
    BuildContext context,
    ItemPriceManagementController controller,
  ) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.formError != null) ...[
            AppErrorStateView.inline(message: controller.formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          SettingsFormWrap(
            children: [
              DropdownButtonFormField<String>(
                initialValue: controller.priceType,
                decoration: const InputDecoration(labelText: 'Price Type'),
                items: ItemPriceManagementController.priceTypeItems
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.value,
                        child: Text(item.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.setPriceType,
              ),
              DropdownButtonFormField<int>(
                initialValue: controller.uomId,
                decoration: const InputDecoration(labelText: 'UOM'),
                items: controller.allowedUoms
                    .where((uom) => uom.id != null)
                    .map(
                      (uom) => DropdownMenuItem<int>(
                        value: uom.id,
                        child: Text(uom.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.setUomId,
                validator: Validators.requiredSelection('UOM'),
              ),
              AppFormTextField(
                labelText: 'Price',
                controller: controller.priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.compose([
                  Validators.required('Price'),
                  Validators.optionalNonNegativeNumber('Price'),
                ]),
              ),
              AppDateField(
                labelText: 'Valid From',
                controller: controller.validFromController,
                hintText: 'YYYY-MM-DD',
                validator: Validators.optionalDate('Valid From'),
              ),
              AppDateField(
                labelText: 'Valid To',
                controller: controller.validToController,
                hintText: 'YYYY-MM-DD',
                validator: Validators.optionalDateOnOrAfter(
                  'Valid To',
                  () => controller.validFromController.text,
                  startFieldName: 'Valid From',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingMd,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              SizedBox(
                width: AppUiConstants.switchFieldWidth,
                child: AppSwitchTile(
                  label: 'Default Price',
                  value: controller.isDefault,
                  onChanged: controller.setIsDefault,
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
          const SizedBox(height: AppUiConstants.spacingLg),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.save_outlined,
                label: controller.selectedPrice == null
                    ? 'Save Price'
                    : 'Update Price',
                onPressed: controller.save,
                busy: controller.saving,
              ),
              if (controller.selectedPrice?.id != null)
                AppActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onPressed: controller.saving
                      ? null
                      : controller.deleteSelectedPrice,
                  filled: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
