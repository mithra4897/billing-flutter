import '../../../controller/settings/master/item_category_management_controller.dart';
import '../../../screen.dart';

class ItemCategoryManagementPage extends StatefulWidget {
  const ItemCategoryManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ItemCategoryManagementPage> createState() =>
      _ItemCategoryManagementPageState();
}

class _ItemCategoryManagementPageState
    extends State<ItemCategoryManagementPage> {
  late final String _controllerTag;
  bool _filtersVisible = false;
  Set<int> _selectedItemIds = <int>{};

  List<AppDropdownItem<int>> get _itemFilterItems => MasterDataCache
      .to
      .activeItems
      .where((item) => item.id != null)
      .map(
        (item) => AppDropdownItem<int>(
          value: item.id!,
          label: '${item.itemName} (${item.itemCode})',
        ),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ItemCategoryManagementController',
    );
    Get.put(ItemCategoryManagementController(), tag: _controllerTag);
    unawaited(
      MasterDataCache.to.ensureLoaded().then((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemCategoryManagementController>(
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
            icon: Icons.category_outlined,
            label: 'New Category',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Item Categories',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ItemCategoryManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading item categories...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load item categories',
        message: controller.pageError!,
        onRetry: controller.loadItems,
      );
    }

    // Migrated page/form state now lives in ItemCategoryManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Item Categories',
      editorTitle: controller.selectedItem?.toString(),
      scrollController: controller.pageScrollController,
      listOnly: true,
      list: SharedRegisterList<ItemCategoryModel>(
        title: 'Item Categories',
        loading: false,
        errorMessage: null,
        onRetry: () => controller.loadItems(),
        actions: [
          AdaptiveShellSearchField(
            controller: controller.searchController,
            hintText: 'Search item categories',
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
            icon: Icons.category_outlined,
            label: 'New Category',
          ),
        ],
        filters: _filtersVisible
            ? SharedFilterBar(
                itemLabel: 'Product',
                itemItems: _itemFilterItems,
                selectedItemIds: _selectedItemIds,
                onItemsChanged: (values) =>
                    setState(() => _selectedItemIds = values),
                showDateFilters: false,
                onClear: () => setState(() => _selectedItemIds = <int>{}),
              )
            : null,
        rows: controller.filteredItems
            .where((category) {
              if (_selectedItemIds.isEmpty) return true;
              final categoryIds = MasterDataCache.to.activeItems
                  .where((item) => _selectedItemIds.contains(item.id))
                  .map((item) => item.categoryId)
                  .whereType<int>()
                  .toSet();
              return categoryIds.contains(category.id);
            })
            .toList(growable: false),
        columns: [
          PurchaseRegisterColumn<ItemCategoryModel>(
            label: 'Code',
            valueBuilder: (item) => item.categoryCode,
          ),
          PurchaseRegisterColumn<ItemCategoryModel>(
            label: 'Category',
            flex: 3,
            valueBuilder: (item) => item.categoryName,
          ),
        ],
        onRowTap: (item) {
          controller.selectItem(item);
          controller.workspaceController.openEditor();
        },
        emptyMessage: 'No item categories found.',
        contentSized: true,
        embedded: true,
      ),
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.formError != null) ...[
              Text(
                controller.formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: controller.codeController,
              decoration: const InputDecoration(labelText: 'Category Code'),
              validator: Validators.compose([
                Validators.required('Category Code'),
                Validators.optionalMaxLength(50, 'Category Code'),
              ]),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
              validator: Validators.compose([
                Validators.required('Category Name'),
                Validators.optionalMaxLength(150, 'Category Name'),
              ]),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: controller.parentCategoryId,
              decoration: const InputDecoration(labelText: 'Parent Category'),
              items: <DropdownMenuItem<int?>>[
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                ...controller.parentOptions.map(
                  (item) => DropdownMenuItem<int?>(
                    value: item.id,
                    child: Text(item.categoryName),
                  ),
                ),
              ],
              onChanged: controller.setParentCategoryId,
            ),
            const SizedBox(height: 12),
            UploadPathField(
              controller: controller.imagePathController,
              labelText: 'Image Path',
              isUploading: controller.uploadingImage,
              onUpload: () => controller.uploadCategoryImage(context),
              previewUrl: AppConfig.resolvePublicFileUrl(
                controller.imagePathController.text,
              ),
              previewIcon: Icons.category_outlined,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: controller.isActive,
              onChanged: controller.setIsActive,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (controller.selectedItem?.id != null)
                  TextButton(
                    onPressed: controller.saving ? null : controller.delete,
                    child: const Text('Delete'),
                  ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: controller.saving ? null : controller.save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(controller.saving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
