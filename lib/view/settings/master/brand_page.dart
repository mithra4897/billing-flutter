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
    _controllerTag = persistentControllerTag('BrandManagementController');
    Get.put(BrandManagementController(), tag: _controllerTag);
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
    return GetBuilder<BrandManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
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
      listOnly: true,
      list: SharedRegisterList<BrandModel>(
        title: 'Brands',
        loading: false,
        errorMessage: null,
        onRetry: () => controller.loadBrands(),
        actions: [
          AdaptiveShellSearchField(
            controller: controller.searchController,
            hintText: 'Search brands',
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
            icon: Icons.sell_outlined,
            label: 'New Brand',
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
        rows: controller.filteredBrands
            .where((brand) {
              if (_selectedItemIds.isEmpty) return true;
              final brandIds = MasterDataCache.to.activeItems
                  .where((item) => _selectedItemIds.contains(item.id))
                  .map((item) => item.brandId)
                  .whereType<int>()
                  .toSet();
              return brandIds.contains(brand.id);
            })
            .toList(growable: false),
        columns: [
          PurchaseRegisterColumn<BrandModel>(
            label: 'Code',
            valueBuilder: (brand) => brand.brandCode ?? '',
          ),
          PurchaseRegisterColumn<BrandModel>(
            label: 'Brand',
            flex: 3,
            valueBuilder: (brand) => brand.brandName ?? '-',
          ),
          PurchaseRegisterColumn<BrandModel>(
            label: 'Status',
            valueBuilder: (brand) => brand.isActive ? 'Active' : 'Inactive',
            widgetBuilder: (context, brand) => purchaseStatusBadge(
              context,
              brand.isActive ? 'active' : 'inactive',
            ),
          ),
        ],
        onRowTap: (brand) {
          controller.selectBrand(brand);
          controller.workspaceController.openEditor();
        },
        emptyMessage: 'No brand records found.',
        contentSized: true,
        embedded: true,
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
