import '../../screen.dart';
import '../../view_model/inventory/stock_batch_view_model.dart';
import '../purchase/purchase_support.dart';

class StockBatchPage extends StatefulWidget {
  const StockBatchPage({
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
  State<StockBatchPage> createState() => _StockBatchPageState();
}

class _StockBatchPageState extends State<StockBatchPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final StockBatchViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StockBatchViewModel(initialItemId: widget.initialItemId)
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
            label: 'New Stock Batch',
          ),
        ];
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Stock Batch',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading stock batches...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load stock batches',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Stock Batch',
      editorTitle: _viewModel.selected?.toString() ?? 'New Stock Batch',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<StockBatchModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search batches',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No stock batches found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: stringValue(row.toJson(), 'batch_no', 'Batch'),
          subtitle: [
            stringValue(row.toJson(), 'item_name'),
            displayDate(nullableStringValue(row.toJson(), 'expiry_date')),
            stringValue(row.toJson(), 'balance_qty'),
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
      editor: _StockBatchEditor(
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

class _StockBatchEditor extends StatelessWidget {
  const _StockBatchEditor({
    required this.vm,
    required this.onSave,
    required this.onDelete,
  });

  final StockBatchViewModel vm;
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
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppSearchPickerOption<int>(
                          value: item.id!,
                          label: item.toString(),
                          subtitle: item.itemCode,
                        ),
                      )
                      .toList(growable: false),
                  validator: (_) =>
                      vm.itemId == null ? 'Item is required' : null,
                  onChanged: (value) {
                    vm.onItemChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Warehouse',
                  mappedItems: vm.warehouseOptions
                      .where((item) => item.id != null)
                      .map((item) => AppDropdownItem<int>(value: item.id!, label: item.toString()))
                      .toList(growable: false),
                  initialValue: vm.warehouseId,
                  validator: Validators.requiredSelection('Warehouse'),
                  onChanged: (value) {
                    vm.onWarehouseChanged(value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Batch no',
                  controller: vm.batchNoController,
                  validator: Validators.compose([
                    Validators.required('Batch no'),
                    Validators.optionalMaxLength(100, 'Batch no'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Mfg date',
                  controller: vm.mfgDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Mfg date'),
                ),
                AppFormTextField(
                  labelText: 'Expiry date',
                  controller: vm.expiryDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Expiry date'),
                ),
                AppFormTextField(
                  labelText: 'Inward qty',
                  controller: vm.inwardQtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.optionalNonNegativeNumber('Inward qty'),
                ),
                AppFormTextField(
                  labelText: 'Outward qty',
                  controller: vm.outwardQtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.optionalNonNegativeNumber('Outward qty'),
                ),
                AppFormTextField(
                  labelText: 'Balance qty',
                  controller: vm.balanceQtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.optionalNonNegativeNumber('Balance qty'),
                ),
                AppFormTextField(
                  labelText: 'Purchase rate',
                  controller: vm.purchaseRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.optionalNonNegativeNumber('Purchase rate'),
                ),
                AppFormTextField(
                  labelText: 'Sales rate',
                  controller: vm.salesRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.optionalNonNegativeNumber('Sales rate'),
                ),
                AppFormTextField(
                  labelText: 'MRP',
                  controller: vm.mrpController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.optionalNonNegativeNumber('MRP'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Active',
                  mappedItems: const <AppDropdownItem<String>>[
                    AppDropdownItem<String>(value: '1', label: 'Yes'),
                    AppDropdownItem<String>(value: '0', label: 'No'),
                  ],
                  initialValue: vm.isActive ? '1' : '0',
                  onChanged: (value) {
                    vm.isActive = value != '0';
                  },
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
