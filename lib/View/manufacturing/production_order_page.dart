import '../../screen.dart';
import '../../view_model/manufacturing/production_order_view_model.dart';
import '../purchase/purchase_support.dart';

class ProductionOrderPage extends StatefulWidget {
  const ProductionOrderPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<ProductionOrderPage> createState() => _ProductionOrderPageState();
}

class _ProductionOrderPageState extends State<ProductionOrderPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final ProductionOrderViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductionOrderViewModel()..load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
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
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              _viewModel.resetDraft();
              _openRoute('/manufacturing/production-orders/new');
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New Production Order',
          ),
        ];
        final content = _buildContent();
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Production Orders',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent() {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading production orders...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load production orders',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Production Orders',
      editorTitle: _viewModel.selected == null
          ? 'New Production Order'
          : stringValue(_viewModel.selected!.toJson(), 'production_no', 'Order'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<ProductionOrderModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search production orders',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No production orders found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'production_no', 'Draft'),
            subtitle: [
              displayDate(nullableStringValue(data, 'production_date')),
              stringValue(data, 'production_status'),
            ].map((v) => v.toString()).where((v) => v.trim().isNotEmpty).join(' · '),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await _viewModel.select(item);
              if (!mounted) return;
              final id = intValue(data, 'id');
              if (id != null) _openRoute('/manufacturing/production-orders/$id');
              if (!isDesktop) _workspaceController.openEditor();
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading production order...')
          : _ProductionOrderEditor(
              vm: _viewModel,
              onSave: () async {
                await _viewModel.save();
                _snack();
              },
              onRelease: () async {
                await _viewModel.release();
                _snack();
              },
              onClose: () async {
                await _viewModel.close();
                _snack();
              },
              onCancel: () async {
                await _viewModel.cancel();
                _snack();
              },
              onDelete: () async {
                await _viewModel.delete();
                _snack();
                _openRoute('/manufacturing/production-orders');
              },
            ),
    );
  }
}

class _ProductionOrderEditor extends StatelessWidget {
  const _ProductionOrderEditor({
    required this.vm,
    required this.onSave,
    required this.onRelease,
    required this.onClose,
    required this.onCancel,
    required this.onDelete,
  });

  final ProductionOrderViewModel vm;
  final Future<void> Function() onSave;
  final Future<void> Function() onRelease;
  final Future<void> Function() onClose;
  final Future<void> Function() onCancel;
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Company',
                  mappedItems: vm.companies
                      .where((x) => x.id != null)
                      .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                      .toList(growable: false),
                  initialValue: vm.companyId,
                  onChanged: vm.onCompanyChanged,
                  validator: Validators.requiredSelection('Company'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Branch',
                  mappedItems: vm.branchOptions
                      .where((x) => x.id != null)
                      .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                      .toList(growable: false),
                  initialValue: vm.branchId,
                  onChanged: vm.onBranchChanged,
                  validator: Validators.requiredSelection('Branch'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Location',
                  mappedItems: vm.locationOptions
                      .where((x) => x.id != null)
                      .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                      .toList(growable: false),
                  initialValue: vm.locationId,
                  onChanged: vm.onLocationChanged,
                  validator: Validators.requiredSelection('Location'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'BOM',
                  mappedItems: vm.bomOptions
                      .where((b) => intValue(b.toJson(), 'id') != null)
                      .map(
                        (b) => AppDropdownItem<int>(
                          value: intValue(b.toJson(), 'id')!,
                          label: stringValue(b.toJson(), 'bom_code', 'BOM'),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.bomId,
                  onChanged: vm.onBomChanged,
                  validator: Validators.requiredSelection('BOM'),
                ),
                AppSearchPickerField<int>(
                  labelText: 'Output Item',
                  selectedLabel: vm.items
                      .cast<ItemModel?>()
                      .firstWhere((x) => x?.id == vm.outputItemId, orElse: () => null)
                      ?.toString(),
                  options: vm.items
                      .where((x) => x.id != null)
                      .map(
                        (x) => AppSearchPickerOption<int>(
                          value: x.id!,
                          label: x.toString(),
                          subtitle: x.itemCode,
                        ),
                      )
                      .toList(growable: false),
                  onChanged: vm.setOutputItemId,
                  validator: (_) =>
                      vm.outputItemId == null ? 'Output Item is required' : null,
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Output UOM',
                  mappedItems: vm.uomOptionsForOutputItem()
                      .where((x) => x.id != null)
                      .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                      .toList(growable: false),
                  initialValue: vm.outputUomId,
                  onChanged: vm.setOutputUomId,
                  validator: Validators.requiredSelection('Output UOM'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Warehouse',
                  mappedItems: vm.warehouseOptions
                      .where((x) => x.id != null)
                      .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                      .toList(growable: false),
                  initialValue: vm.warehouseId,
                  onChanged: vm.setWarehouseId,
                  validator: Validators.requiredSelection('Warehouse'),
                ),
                AppFormTextField(
                  labelText: 'Production No',
                  controller: vm.productionNoController,
                  enabled: !vm.isLocked,
                ),
                AppFormTextField(
                  labelText: 'Production Date',
                  controller: vm.productionDateController,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: !vm.isLocked,
                  validator: Validators.compose([
                    Validators.required('Production Date'),
                    Validators.date('Production Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Planned Qty',
                  controller: vm.plannedQtyController,
                  enabled: !vm.isLocked,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.requiredPositiveNumber('Planned Qty'),
                ),
                AppFormTextField(
                  labelText: 'Notes',
                  controller: vm.notesController,
                  enabled: !vm.isLocked,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
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
                if (vm.selected != null && stringValue(vm.selected!.toJson(), 'production_status') == 'draft')
                  AppActionButton(
                    icon: Icons.play_arrow_outlined,
                    label: 'Release',
                    filled: false,
                    onPressed: onRelease,
                  ),
                if (vm.selected != null)
                  AppActionButton(
                    icon: Icons.task_alt_outlined,
                    label: 'Close',
                    filled: false,
                    onPressed: onClose,
                  ),
                if (vm.selected != null)
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: onCancel,
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
