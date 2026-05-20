import '../../../controller/settings/master/item_alternate_management_controller.dart';
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
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ItemAlternateManagementController'
      '-${widget.fixedItemId ?? 'all'}',
    );
    Get.put(
      ItemAlternateManagementController(
        fixedItemId: widget.fixedItemId,
        fixedItemLabel: widget.fixedItemLabel,
      ),
      tag: _controllerTag,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ItemAlternateManagementController controller,
    ItemAlternateModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Alternate'),
          content: Text(
            'Remove ${controller.counterpartyLabelFor(item)} from this item alternates list?',
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
      await controller.confirmDelete(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemAlternateManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: controller.selectedMasterId == null
                ? null
                : () => controller.startNew(
                    isDesktop: Responsive.isDesktop(context),
                  ),
            icon: Icons.compare_arrows_outlined,
            label: 'Add Alternate',
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
          title: ItemAlternateManagementController.pageTitle,
          scrollController: controller.pageScrollController,
          actions: actions,
          child: _buildContent(context, controller),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ItemAlternateManagementController controller,
  ) {
    if (controller.initialLoading) {
      return AppLoadingView(
        message:
            'Loading ${ItemAlternateManagementController.pageTitle.toLowerCase()}...',
      );
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title:
            'Unable to load ${ItemAlternateManagementController.pageTitle.toLowerCase()}',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    if (widget.fixedItemId != null) {
      return controller.selectedMasterId == null
          ? const SettingsEmptyState(
              icon: Icons.compare_arrows_outlined,
              title: 'Item Not Found',
              message: 'The selected item is not available.',
            )
          : _buildEditorBody(context, controller);
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: ItemAlternateManagementController.pageTitle,
      editorTitle: controller.selectedMasterTitle,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<ItemModel>(
        searchController: controller.masterSearchController,
        searchHint: 'Search ${ItemAlternateManagementController.masterLabel}',
        items: controller.filteredMasterItems,
        selectedItem: controller.selectedMasterItem,
        emptyMessage:
            'No ${ItemAlternateManagementController.masterLabel} records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.itemName,
          subtitle: item.itemCode,
          selected: selected,
          onTap: () => controller.selectMaster(item.id!),
        ),
      ),
      editor: AppSectionCard(
        child: controller.selectedMasterId == null
            ? const SettingsEmptyState(
                icon: Icons.compare_arrows_outlined,
                title: 'Select Item',
                message: 'Choose an Item from the left to manage alternates.',
              )
            : _buildEditorBody(context, controller),
      ),
    );
  }

  Widget _buildEditorBody(
    BuildContext context,
    ItemAlternateManagementController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fixedItemId != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: AppActionButton(
              icon: Icons.compare_arrows_outlined,
              label: 'Add Alternate',
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppUiConstants.spacingMd),
            child: Text('No alternates mapped for this item.'),
          ),
        if (controller.showDraftTile && controller.selectedItem == null) ...[
          SettingsExpandableTile(
            key: const ValueKey('alt-draft'),
            title: controller.selectedCounterpartyItem == null
                ? 'New Alternate Item'
                : controller.itemLabel(controller.selectedCounterpartyItem!),
            subtitle: 'Add an alternate item for this product.',
            expanded: true,
            highlighted: true,
            leadingIcon: Icons.add_outlined,
            onToggle: controller.hideDraftTile,
            child: _buildAlternateForm(context, controller),
          ),
          if (controller.filteredItems.isNotEmpty)
            const SizedBox(height: AppUiConstants.spacingSm),
        ],
        ...controller.filteredItems.map((item) {
          final expanded = identical(item, controller.selectedItem);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: SettingsExpandableTile(
              key: ValueKey('alt-${item.id}-$expanded'),
              title: controller.counterpartyLabelFor(item),
              subtitle: [
                if (item.priorityOrder != null)
                  'Priority ${item.priorityOrder}',
                if (item.isActive) 'Active',
              ].join(' · '),
              expanded: expanded,
              highlighted: expanded,
              trailing: IconButton(
                tooltip: 'Remove alternate',
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
              child: _buildAlternateForm(context, controller),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAlternateForm(
    BuildContext context,
    ItemAlternateManagementController controller,
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
          if (widget.fixedItemId == null) ...[
            DropdownButtonFormField<int>(
              initialValue: controller.counterpartyId,
              decoration: const InputDecoration(
                labelText: ItemAlternateManagementController.counterpartyLabel,
              ),
              items: controller.allItems
                  .where(
                    (item) => controller.dropdownCounterpartyOptions.any(
                      (option) => option.id == item.id,
                    ),
                  )
                  .map(
                    (item) => DropdownMenuItem<int>(
                      value: item.id,
                      child: Text(controller.itemLabel(item)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: controller.setCounterpartyId,
              validator: Validators.requiredSelection(
                ItemAlternateManagementController.counterpartyLabel,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
          ] else if (controller.selectedItem == null) ...[
            AppSearchPickerField<int>(
              labelText: ItemAlternateManagementController.counterpartyLabel,
              selectedLabel: controller.selectedCounterpartyItem == null
                  ? null
                  : controller.itemLabel(controller.selectedCounterpartyItem!),
              hintText: 'Search alternate item to add',
              options: controller.availableCounterpartyOptions
                  .where((item) => item.id != null)
                  .map(
                    (item) => AppSearchPickerOption<int>(
                      value: item.id!,
                      label: controller.itemLabel(item),
                      subtitle: controller.itemSubtitle(item),
                      searchText: [
                        item.sku ?? '',
                        item.hsnSacCode ?? '',
                        item.brandName ?? item.brandCode ?? '',
                      ].join(' '),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  controller.setCounterpartyId(value);
                }
              },
              validator: (_) => controller.counterpartyId == null
                  ? 'Alternate Item is required'
                  : null,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
          ] else if (controller.selectedCounterpartyItem != null) ...[
            Text(
              controller.itemLabel(controller.selectedCounterpartyItem!),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          SettingsFormWrap(
            children: [
              AppFormTextField(
                labelText: 'Priority',
                controller: controller.priorityController,
                keyboardType: TextInputType.number,
                validator: Validators.compose([
                  Validators.required('Priority'),
                  Validators.optionalMinimumInteger(1, 'Priority'),
                ]),
              ),
              AppFormTextField(
                labelText: 'Reason',
                controller: controller.remarksController,
                maxLines: 3,
                validator: Validators.optionalMaxLength(255, 'Reason'),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          SizedBox(
            width: AppUiConstants.switchFieldWidth,
            child: AppSwitchTile(
              label: 'Active',
              value: controller.isActive,
              onChanged: controller.setIsActive,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.save_outlined,
                label: controller.selectedItem == null
                    ? 'Save Mapping'
                    : 'Update Mapping',
                onPressed: controller.save,
                busy: controller.saving,
              ),
              if (controller.selectedItem?.id != null)
                AppActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onPressed: controller.saving
                      ? null
                      : controller.deleteSelected,
                  filled: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
