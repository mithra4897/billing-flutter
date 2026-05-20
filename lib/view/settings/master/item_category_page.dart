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

  @override
  void initState() {
    super.initState();
    _controllerTag =
        persistentControllerTag('ItemCategoryManagementController');
    Get.put(ItemCategoryManagementController(), tag: _controllerTag);
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
      list: SettingsListCard<ItemCategoryModel>(
        searchController: controller.searchController,
        searchHint: 'Search item categories',
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No item categories found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.categoryName,
          subtitle: item.categoryCode,
          selected: selected,
          onTap: () => controller.selectItem(item),
        ),
      ),
      editor: Form(
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
