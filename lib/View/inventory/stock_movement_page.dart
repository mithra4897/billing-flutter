import '../../screen.dart';
import '../../view_model/inventory/stock_movement_view_model.dart';
import '../purchase/purchase_support.dart';

class StockMovementPage extends StatefulWidget {
  const StockMovementPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialItemId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final int? initialItemId;

  @override
  State<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final StockMovementViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StockMovementViewModel(initialItemId: widget.initialItemId)
      ..load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _workspaceController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final content = _buildContent(context);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: _viewModel.loading
                ? null
                : () {
                    _viewModel.resetDraft();
                    if (!Responsive.isDesktop(context)) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New Stock Movement',
          ),
        ];
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Stock Movement',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading stock movements...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load stock movements',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Stock Movement',
      editorTitle: _viewModel.selected?.toString() ?? 'New Stock Movement',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<StockMovementModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search stock movements',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No stock movements found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: stringValue(row.toJson(), 'reference_no', 'Movement'),
          subtitle: [
            displayDate(nullableStringValue(row.toJson(), 'movement_date')),
            stringValue(row.toJson(), 'movement_type'),
            stringValue(row.toJson(), 'stock_effect'),
          ].whereType<String>().where((v) => v.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () async {
            await _viewModel.select(row);
            if (!context.mounted) return;
            if (!Responsive.isDesktop(context)) {
              _workspaceController.openEditor();
            }
          },
        ),
      ),
      editor: _StockMovementEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) return;
          await _viewModel.save();
        },
        onDelete: _viewModel.delete,
      ),
    );
  }
}

class _StockMovementEditor extends StatelessWidget {
  const _StockMovementEditor({
    required this.vm,
    required this.onSave,
    required this.onDelete,
  });

  final StockMovementViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }
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
                  selectedLabel: vm.itemOptions
                      .cast<ItemModel?>()
                      .firstWhere(
                        (item) => item?.id == vm.itemId,
                        orElse: () => null,
                      )
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
                  validator: (_) =>
                      vm.itemId == null ? 'Item is required' : null,
                  onChanged: vm.onItemChanged,
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Warehouse',
                  mappedItems: vm.warehouseOptions
                      .where((x) => x.id != null)
                      .map(
                        (x) => AppDropdownItem<int>(
                          value: x.id!,
                          label: x.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.warehouseId,
                  validator: Validators.requiredSelection('Warehouse'),
                  onChanged: vm.onWarehouseChanged,
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Batch',
                  mappedItems: vm
                      .batchOptions()
                      .map(
                        (x) => AppDropdownItem<int>(
                          value: intValue(x, 'id')!,
                          label: stringValue(x, 'batch_no', 'Batch'),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.batchId,
                  onChanged: vm.onBatchChanged,
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Serial',
                  mappedItems: vm
                      .serialOptions()
                      .map(
                        (x) => AppDropdownItem<int>(
                          value: intValue(x, 'id')!,
                          label: stringValue(x, 'serial_no', 'Serial'),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.serialId,
                  onChanged: vm.onSerialChanged,
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Movement type',
                  mappedItems: stockMovementTypeItems,
                  initialValue: vm.movementType,
                  validator: Validators.requiredSelection('Movement type'),
                  onChanged: vm.onMovementTypeChanged,
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Stock effect',
                  mappedItems: stockEffectItems,
                  initialValue: vm.stockEffect,
                  validator: Validators.requiredSelection('Stock effect'),
                  onChanged: vm.onStockEffectChanged,
                ),
                if (vm.isTransferType)
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Source warehouse',
                    mappedItems: vm.warehouseOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.sourceWarehouseId,
                    validator: Validators.requiredSelection('Source warehouse'),
                    onChanged: vm.onSourceWarehouseChanged,
                  ),
                if (vm.isTransferType)
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Destination warehouse',
                    mappedItems: vm.warehouseOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.destinationWarehouseId,
                    validator: Validators.requiredSelection(
                      'Destination warehouse',
                    ),
                    onChanged: vm.onDestinationWarehouseChanged,
                  ),
                AppFormTextField(
                  labelText: 'Reference type',
                  controller: vm.referenceTypeController,
                  validator: Validators.optionalMaxLength(
                    100,
                    'Reference type',
                  ),
                ),
                AppFormTextField(
                  labelText: 'Reference id',
                  controller: vm.referenceIdController,
                  keyboardType: TextInputType.number,
                  validator: Validators.optionalNonNegativeInteger(
                    'Reference id',
                  ),
                ),
                AppFormTextField(
                  labelText: 'Reference no',
                  controller: vm.referenceNoController,
                  validator: Validators.optionalMaxLength(100, 'Reference no'),
                ),
                AppFormTextField(
                  labelText: 'Voucher date',
                  controller: vm.voucherDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Voucher date'),
                    Validators.date('Voucher date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Qty',
                  controller: vm.qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.requiredPositiveNumber('Qty'),
                ),
                AppFormTextField(
                  labelText: 'Rate',
                  controller: vm.rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber('Rate'),
                ),
                AppFormTextField(
                  labelText: 'Amount',
                  controller: vm.amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber('Amount'),
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: vm.remarksController,
                  maxLines: 2,
                  validator: Validators.optionalMaxLength(1000, 'Remarks'),
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
                  onPressed: () => onSave(formContext),
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
