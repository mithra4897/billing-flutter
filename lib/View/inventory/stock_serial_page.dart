import '../../screen.dart';
import '../../view_model/inventory/stock_serial_view_model.dart';

class StockSerialPage extends StatefulWidget {
  const StockSerialPage({
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
  State<StockSerialPage> createState() => _StockSerialPageState();
}

class _StockSerialPageState extends State<StockSerialPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final StockSerialViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StockSerialViewModel(initialItemId: widget.initialItemId)
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
            label: 'New Stock Serial',
          ),
        ];
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Stock Serial',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading stock serials...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load stock serials',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Stock Serial',
      editorTitle: _viewModel.selected?.toString() ?? 'New Stock Serial',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<StockSerialModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search serials',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No stock serials found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: stringValue(row.toJson(), 'serial_no', 'Serial'),
          subtitle: [
            stringValue(row.toJson(), 'status'),
            stringValue(row.toJson(), 'warehouse_id'),
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
      editor: _StockSerialEditor(
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

class _StockSerialEditor extends StatelessWidget {
  const _StockSerialEditor({
    required this.vm,
    required this.onSave,
    required this.onDelete,
  });

  final StockSerialViewModel vm;
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
                AppDropdownField<int>.fromMapped(
                  key: ValueKey<int?>(vm.batchId),
                  labelText: 'Batch',
                  mappedItems: vm.batchOptions
                      .map(
                        (x) => AppDropdownItem<int>(
                          value: intValue(x.toJson(), 'id')!,
                          label: x.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.batchId,
                  onChanged: (value) {
                    vm.onBatchChanged(value);
                  },
                ),
                AppSearchPickerField<int>(
                  key: ValueKey<int?>(vm.itemId),
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
                  onChanged: (value) {
                    vm.onItemChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  key: ValueKey<String>('wh-${vm.warehouseId}-${vm.batchId}'),
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
                  onChanged: (value) {
                    vm.onWarehouseChanged(value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Serial no',
                  controller: vm.serialNoController,
                  validator: Validators.compose([
                    Validators.required('Serial no'),
                    Validators.optionalMaxLength(150, 'Serial no'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Status',
                  mappedItems: stockSerialStatusItems,
                  initialValue: vm.status,
                  validator: Validators.requiredSelection('Status'),
                  onChanged: (value) {
                    vm.onStatusChanged(value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Inward date',
                  controller: vm.inwardDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Inward date'),
                ),
                AppFormTextField(
                  labelText: 'Outward date',
                  controller: vm.outwardDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Outward date'),
                ),
                AppFormTextField(
                  labelText: 'Purchase rate',
                  controller: vm.purchaseRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Purchase rate',
                  ),
                ),
                AppFormTextField(
                  labelText: 'Sales rate',
                  controller: vm.salesRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber('Sales rate'),
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
