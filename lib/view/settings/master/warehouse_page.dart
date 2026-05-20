import '../../../controller/settings/master/warehouse_management_controller.dart';
import '../../../screen.dart';

class WarehouseManagementPage extends StatefulWidget {
  const WarehouseManagementPage({
    super.key,
    this.embedded = false,
    this.fixedCompanyId,
    this.fixedBranchId,
  });

  final bool embedded;
  final int? fixedCompanyId;
  final int? fixedBranchId;

  @override
  State<WarehouseManagementPage> createState() =>
      _WarehouseManagementPageState();
}

class _WarehouseManagementPageState extends State<WarehouseManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'WarehouseManagementController'
      '-${widget.fixedCompanyId ?? 'all'}-${widget.fixedBranchId ?? 'all'}',
    );
    Get.put(
      WarehouseManagementController(
        fixedCompanyId: widget.fixedCompanyId,
        fixedBranchId: widget.fixedBranchId,
      ),
      tag: _controllerTag,
    );
  }

  @override
  void didUpdateWidget(covariant WarehouseManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixedCompanyId != widget.fixedCompanyId ||
        oldWidget.fixedBranchId != widget.fixedBranchId) {
      Get.find<WarehouseManagementController>(
        tag: _controllerTag,
      ).reloadForScope();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WarehouseManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewWarehouse(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_home_work_outlined,
            label: 'New Warehouse',
          ),
        ];

        if (widget.embedded) {
          return _buildEmbeddedContent(context, controller);
        }

        return AppStandaloneShell(
          title: 'Warehouses',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: _buildContent(context, controller),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WarehouseManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading warehouses...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load warehouses',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Warehouses',
      editorTitle: controller.selectedWarehouse?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<WarehouseModel>(
        searchController: controller.searchController,
        searchHint: 'Search warehouses',
        items: controller.filteredWarehouses,
        selectedItem: controller.selectedWarehouse,
        emptyMessage: 'No warehouses found.',
        itemBuilder: (warehouse, selected) => SettingsListTile(
          title: warehouse.name ?? '',
          subtitle: [
            warehouse.code ?? '',
            locationNameById(controller.locations, warehouse.locationId),
            warehouse.warehouseType?.replaceAll('_', ' ') ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: SettingsStatusPill(
            label: warehouse.isActive ? 'Active' : 'Inactive',
            active: warehouse.isActive,
          ),
          onTap: () => controller.selectWarehouse(warehouse),
        ),
      ),
      editor: _buildEditor(context, controller),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    WarehouseManagementController controller,
  ) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsFormWrap(
            children: [
              if (widget.fixedCompanyId == null)
                AppDropdownField<int>(
                  initialValue: controller.companyId,
                  labelText: 'Company',
                  items: controller.companies
                      .map(
                        (company) => DropdownMenuItem<int>(
                          value: company.id,
                          child: Text(company.legalName ?? ''),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.setCompanyId,
                  validator: (value) =>
                      value == null ? 'Company is required' : null,
                ),
              if (widget.fixedBranchId == null)
                AppDropdownField<int>(
                  initialValue: controller.branchId,
                  labelText: 'Branch',
                  items: controller.scopedBranches
                      .map(
                        (branch) => DropdownMenuItem<int>(
                          value: branch.id,
                          child: Text(branch.name ?? ''),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.setBranchId,
                  validator: (value) =>
                      value == null ? 'Branch is required' : null,
                ),
              AppDropdownField<int>(
                initialValue: controller.locationId,
                labelText: 'Business Location',
                items: controller.scopedLocations
                    .map(
                      (location) => DropdownMenuItem<int>(
                        value: location.id,
                        child: Text(location.name ?? ''),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.setLocationId,
                validator: (value) =>
                    value == null ? 'Location is required' : null,
              ),
              AppFormTextField(
                controller: controller.codeController,
                labelText: 'Code',
                readOnly: true,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Code is required'
                    : null,
              ),
              AppFormTextField(
                controller: controller.nameController,
                labelText: 'Name',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              AppDropdownField<String>.fromMapped(
                initialValue: controller.warehouseType,
                labelText: 'Warehouse Type',
                mappedItems: const [
                  AppDropdownItem(value: 'main', label: 'Main'),
                  AppDropdownItem(value: 'raw_material', label: 'Raw Material'),
                  AppDropdownItem(
                    value: 'finished_goods',
                    label: 'Finished Goods',
                  ),
                  AppDropdownItem(value: 'wip', label: 'WIP'),
                  AppDropdownItem(value: 'damage', label: 'Damage'),
                  AppDropdownItem(value: 'returns', label: 'Returns'),
                  AppDropdownItem(value: 'transit', label: 'Transit'),
                  AppDropdownItem(value: 'jobwork', label: 'Jobwork'),
                  AppDropdownItem(value: 'other', label: 'Other'),
                ],
                onChanged: controller.setWarehouseType,
              ),
              AppDropdownField<int?>.fromMapped(
                initialValue: controller.parentWarehouseId,
                labelText: 'Parent Warehouse',
                mappedItems: [
                  const AppDropdownItem<int?>(value: null, label: 'None'),
                  ...controller.parentOptions.map(
                    (warehouse) => AppDropdownItem<int?>(
                      value: warehouse.id,
                      label: warehouse.name ?? '',
                    ),
                  ),
                ],
                onChanged: controller.setParentWarehouseId,
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppToggleChip(
                label: 'Allow Negative',
                value: controller.allowNegativeStock,
                onChanged: controller.setAllowNegativeStock,
              ),
              AppToggleChip(
                label: 'Sellable',
                value: controller.isSellableStock,
                onChanged: controller.setIsSellableStock,
              ),
              AppToggleChip(
                label: 'Reserved Only',
                value: controller.isReservedOnly,
                onChanged: controller.setIsReservedOnly,
              ),
            ],
          ),
          AppSwitchTile(
            label: 'Default Warehouse',
            value: controller.isDefault,
            onChanged: controller.setIsDefault,
          ),
          AppSwitchTile(
            label: 'Active',
            value: controller.isActive,
            onChanged: controller.setIsActive,
          ),
          AppFormTextField(
            controller: controller.remarksController,
            maxLines: 3,
            labelText: 'Remarks',
          ),
          if ((controller.formError ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              controller.formError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              AppActionButton(
                onPressed: controller.saving ? null : controller.save,
                icon: controller.selectedWarehouse == null
                    ? Icons.add
                    : Icons.save,
                label: controller.saving ? 'Saving...' : 'Save Warehouse',
                busy: controller.saving,
              ),
              AppActionButton(
                onPressed: controller.saving ? null : controller.resetForm,
                icon: Icons.refresh,
                label: 'Reset',
                filled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedContent(
    BuildContext context,
    WarehouseManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading warehouses...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView.inline(message: controller.pageError!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppActionButton(
              onPressed: controller.saving
                  ? null
                  : () => controller.startNewWarehouse(isDesktop: false),
              icon: Icons.add_home_work_outlined,
              label: 'New Warehouse',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (controller.filteredWarehouses.isEmpty &&
            !controller.showDraftTile &&
            controller.selectedWarehouse == null)
          const SettingsEmptyState(
            icon: Icons.home_work_outlined,
            title: 'No Warehouses',
            message: 'No branch warehouses found.',
            minHeight: 160,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.showDraftTile &&
                  controller.selectedWarehouse == null) ...[
                SettingsExpandableTile(
                  key: const ValueKey('warehouse-draft'),
                  title: 'New Warehouse',
                  subtitle: 'Create a warehouse under this branch.',
                  expanded: true,
                  highlighted: true,
                  leadingIcon: Icons.add_outlined,
                  onToggle: controller.hideDraftTile,
                  child: _buildEditor(context, controller),
                ),
                if (controller.filteredWarehouses.isNotEmpty)
                  const SizedBox(height: AppUiConstants.spacingSm),
              ],
              ...controller.filteredWarehouses.map((item) {
                final expanded = identical(item, controller.selectedWarehouse);
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: SettingsExpandableTile(
                    key: ValueKey('warehouse-${item.id}-$expanded'),
                    title: item.name ?? '-',
                    subtitle: [
                      item.code ?? '',
                      locationNameById(controller.locations, item.locationId),
                      item.warehouseType?.replaceAll('_', ' ') ?? '',
                    ].where((value) => value.isNotEmpty).join(' • '),
                    detail: [
                      if (item.isDefault) 'Default',
                      if (item.isActive) 'Active',
                    ].join(' • '),
                    expanded: expanded,
                    highlighted: expanded,
                    onToggle: () {
                      if (expanded) {
                        controller.resetForm();
                      } else {
                        controller.selectWarehouse(item);
                      }
                    },
                    child: expanded
                        ? _buildEditor(context, controller)
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }
}
