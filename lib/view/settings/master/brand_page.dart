import '../../../controller/settings/master/brand_management_controller.dart';
import '../../../screen.dart';

class BrandManagementPage extends StatefulWidget {
  const BrandManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BrandManagementPage> createState() => _BrandManagementPageState();
}

class _BrandManagementPageState extends State<BrandManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('BrandManagementController');
    Get.put(BrandManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BrandManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.sell_outlined,
            label: 'New Brand',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Brands',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BrandManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading brands...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load brands',
        message: controller.pageError!,
        onRetry: controller.loadBrands,
      );
    }

    // Migrated page/form state now lives in BrandManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Brands',
      editorTitle: controller.selectedBrand?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<BrandModel>(
        searchController: controller.searchController,
        searchHint: 'Search brands',
        items: controller.filteredBrands,
        selectedItem: controller.selectedBrand,
        emptyMessage: 'No brand records found.',
        itemBuilder: (brand, selected) => SettingsListTile(
          title: brand.brandName ?? '-',
          subtitle: brand.brandCode ?? '',
          selected: selected,
          onTap: () => controller.selectBrand(brand),
          trailing: SettingsStatusPill(
            label: brand.isActive ? 'Active' : 'Inactive',
            active: brand.isActive,
          ),
        ),
      ),
      editorBuilder: (_) => Form(
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
                AppFormTextField(
                  labelText: 'Brand Code',
                  controller: controller.codeController,
                  validator: Validators.compose([
                    Validators.required('Brand code'),
                    Validators.optionalMaxLength(50, 'Brand code'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Brand Name',
                  controller: controller.nameController,
                  validator: Validators.compose([
                    Validators.required('Brand name'),
                    Validators.optionalMaxLength(150, 'Brand name'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: controller.remarksController,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSwitchTile(
              label: 'Active',
              subtitle: 'Inactive brands stay hidden from normal selection.',
              value: controller.isActive,
              onChanged: controller.setIsActive,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedBrand == null
                      ? 'Save Brand'
                      : 'Update Brand',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
                if (controller.selectedBrand?.id != null)
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
      ),
    );
  }
}
