import '../../screen.dart';

class ItemPlanningPolicyPage extends StatefulWidget {
  const ItemPlanningPolicyPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<ItemPlanningPolicyPage> createState() => _ItemPlanningPolicyPageState();
}

class _ItemPlanningPolicyPageState extends State<ItemPlanningPolicyPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final ItemPlanningPolicyViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('ItemPlanningPolicyViewModel');
    _viewModel = Get.put(
      ItemPlanningPolicyViewModel()..load(selectId: widget.initialId),
      tag: _controllerTag,
      permanent: true,
    );
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  void _openRoute(String route) {
    final navigate = ShellRouteScope.maybeOf(context);
    if (navigate != null) {
      navigate(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  void _snack() {
    final msg = _viewModel.consumeActionMessage();
    if (!mounted || msg == null || msg.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemPlanningPolicyViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final isDesktop = Responsive.isDesktop(context);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              _viewModel.resetDraft();
              if (widget.editorOnly || !isDesktop) {
                _openRoute('/planning/item-policies/new');
              }
              if (!isDesktop) _workspaceController.openEditor();
            },
            icon: Icons.add_outlined,
            label: 'New Item Policy',
          ),
        ];
        final content = _buildContent();
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Item Planning Policies',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent() {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading item policies...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load item policies',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Item Planning Policies',
      editorTitle: _viewModel.selected == null
          ? 'New Item Policy'
          : 'Policy #${intValue(_viewModel.selected!.toJson(), 'id') ?? ''}',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<ItemPlanningPolicyModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search item policies',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No item policies found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          final itemMap = data['item'] is Map<String, dynamic>
              ? data['item'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final warehouseMap = data['warehouse'] is Map<String, dynamic>
              ? data['warehouse'] as Map<String, dynamic>
              : const <String, dynamic>{};
          return SettingsListTile(
            title: [
              stringValue(itemMap, 'item_code'),
              stringValue(itemMap, 'item_name', 'Item Policy'),
            ].where((value) => value.trim().isNotEmpty).join(' · '),
            subtitle: [
              stringValue(
                warehouseMap,
                'name',
                data['warehouse_id'] == null ? 'All Warehouses' : '',
              ),
              stringValue(data, 'planning_method'),
              stringValue(data, 'procurement_type'),
            ].where((value) => value.trim().isNotEmpty).join(' · '),
            detail: [
              if (nullableStringValue(data, 'reorder_level_qty') != null)
                'Level ${stringValue(data, 'reorder_level_qty')}',
              if (nullableStringValue(data, 'reorder_qty') != null)
                'Qty ${stringValue(data, 'reorder_qty')}',
              if (boolValue(data, 'is_mrp_enabled', fallback: false)) 'MRP',
              if (boolValue(data, 'is_reorder_enabled', fallback: false))
                'Reorder',
              if (!boolValue(data, 'is_active', fallback: true)) 'Inactive',
            ].join(' · '),
            selected: selected,
            onTap: () async {
              final id = intValue(data, 'id');
              final isDesktop = Responsive.isDesktop(context);
              await _viewModel.select(item);
              if (!mounted || id == null) return;
              if (widget.editorOnly || !isDesktop) {
                _openRoute('/planning/item-policies/$id');
              }
              if (!isDesktop) _workspaceController.openEditor();
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading item policy...')
          : _ItemPolicyEditor(
              vm: _viewModel,
              onSave: () async {
                await _viewModel.save();
                _snack();
              },
              onDelete: () async {
                final shouldNavigateBack =
                    widget.editorOnly || !Responsive.isDesktop(context);
                await _viewModel.delete();
                _snack();
                if (shouldNavigateBack) {
                  _openRoute('/planning/item-policies');
                }
              },
            ),
    );
  }
}

class _ItemPolicyEditor extends StatelessWidget {
  const _ItemPolicyEditor({
    required this.vm,
    required this.onSave,
    required this.onDelete,
  });

  final ItemPlanningPolicyViewModel vm;
  final Future<void> Function() onSave;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Builder(
        builder: (formContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.formError != null) ...[
              AppErrorStateView.inline(message: vm.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppSearchPickerField<int>(
                  labelText: 'Item',
                  selectedLabel: vm.items
                      .cast<ItemModel?>()
                      .firstWhere((x) => x?.id == vm.itemId, orElse: () => null)
                      ?.toString(),
                  options: vm.itemOptions
                      .where((x) => x.id != null)
                      .map(
                        (x) => AppSearchPickerOption<int>(
                          value: x.id!,
                          label: x.toString(),
                          subtitle: x.itemCode,
                        ),
                      )
                      .toList(growable: false),
                  onChanged: vm.setItemId,
                  validator: (_) =>
                      vm.itemId == null ? 'Item is required' : null,
                ),
                AppSearchPickerField<int>(
                  labelText: 'Warehouse',
                  selectedLabel: vm.warehouseId == null
                      ? 'All Warehouses'
                      : vm.warehouseOptions
                            .cast<WarehouseModel?>()
                            .firstWhere(
                              (x) => x?.id == vm.warehouseId,
                              orElse: () => null,
                            )
                            ?.toString(),
                  options: <AppSearchPickerOption<int>>[
                    const AppSearchPickerOption<int>(
                      value: 0,
                      label: 'All Warehouses',
                      subtitle: 'Company-level policy',
                    ),
                    ...vm.warehouseOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppSearchPickerOption<int>(
                            value: x.id!,
                            label: x.toString(),
                            subtitle: x.code,
                          ),
                        ),
                  ],
                  onChanged: vm.setWarehouseId,
                ),
                AppFormTextField(
                  labelText: 'Planning Method',
                  controller: vm.planningMethodController,
                ),
                AppFormTextField(
                  labelText: 'Procurement Type',
                  controller: vm.procurementTypeController,
                ),
                AppFormTextField(
                  labelText: 'Lead Time (days)',
                  controller: vm.leadTimeDaysController,
                  keyboardType: TextInputType.number,
                ),
                AppFormTextField(
                  labelText: 'Safety Stock Qty',
                  controller: vm.safetyStockQtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppFormTextField(
                  labelText: 'Reorder Level Qty',
                  controller: vm.reorderLevelQtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppFormTextField(
                  labelText: 'Reorder Qty',
                  controller: vm.reorderQtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppFormTextField(
                  labelText: 'Minimum Order Qty',
                  controller: vm.minimumOrderQtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppFormTextField(
                  labelText: 'Maximum Order Qty',
                  controller: vm.maxOrderQtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppFormTextField(
                  labelText: 'Order Multiple Qty',
                  controller: vm.orderMultipleQtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppFormTextField(
                  labelText: 'Planning Fence (days)',
                  controller: vm.planningFenceDaysController,
                  keyboardType: TextInputType.number,
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Preferred Supplier',
                  mappedItems: <AppDropdownItem<int?>>[
                    const AppDropdownItem<int?>(value: null, label: 'None'),
                    ...vm.supplierOptions
                        .where((supplier) => supplier.id != null)
                        .map(
                          (supplier) => AppDropdownItem<int?>(
                            value: supplier.id,
                            label: supplier.toString(),
                          ),
                        ),
                  ],
                  initialValue: vm.preferredSupplierPartyId,
                  onChanged: vm.setPreferredSupplierPartyId,
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Preferred BOM',
                  mappedItems: <AppDropdownItem<int?>>[
                    const AppDropdownItem<int?>(value: null, label: 'None'),
                    ...vm.bomOptions
                        .where((bom) => bom.id != null)
                        .map(
                          (bom) => AppDropdownItem<int?>(
                            value: bom.id,
                            label: bom.toString(),
                          ),
                        ),
                  ],
                  initialValue: vm.preferredBomId,
                  onChanged: vm.setPreferredBomId,
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Preferred Source Warehouse',
                  mappedItems: <AppDropdownItem<int?>>[
                    const AppDropdownItem<int?>(value: null, label: 'None'),
                    ...vm.preferredWarehouseOptions
                        .where((warehouse) => warehouse.id != null)
                        .map(
                          (warehouse) => AppDropdownItem<int?>(
                            value: warehouse.id,
                            label: warehouse.toString(),
                          ),
                        ),
                  ],
                  initialValue: vm.preferredWarehouseId,
                  onChanged: vm.setPreferredWarehouseId,
                ),
                AppSwitchTile(
                  label: 'MRP Enabled',
                  value: vm.isMrpEnabled,
                  onChanged: vm.setIsMrpEnabled,
                ),
                AppSwitchTile(
                  label: 'Reorder Enabled',
                  value: vm.isReorderEnabled,
                  onChanged: vm.setIsReorderEnabled,
                ),
                AppSwitchTile(
                  label: 'Active',
                  value: vm.isActive,
                  onChanged: vm.setIsActive,
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: vm.remarksController,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: vm.selected == null ? 'Save' : 'Update',
                  busy: vm.saving,
                  onPressed: () async {
                    if (!Form.of(formContext).validate()) return;
                    await onSave();
                  },
                ),
                if (vm.selected != null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
