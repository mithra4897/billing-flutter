import '../../screen.dart';
import '../../view_model/manufacturing/production_receipt_view_model.dart';
import '../purchase/purchase_support.dart';

class ProductionReceiptPage extends StatefulWidget {
  const ProductionReceiptPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<ProductionReceiptPage> createState() => _ProductionReceiptPageState();
}

class _ProductionReceiptPageState extends State<ProductionReceiptPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final ProductionReceiptViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductionReceiptViewModel()..load(selectId: widget.initialId);
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
              _openRoute('/manufacturing/production-receipts/new');
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New Production Receipt',
          ),
        ];
        final content = _buildContent();
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Production Receipts',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent() {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading production receipts...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load production receipts',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Production Receipts',
      editorTitle: _viewModel.selected == null
          ? 'New Production Receipt'
          : stringValue(_viewModel.selected!.toJson(), 'receipt_no', 'Receipt'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<ProductionReceiptModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search receipts',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No production receipts found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'receipt_no', 'Draft'),
            subtitle: [
              displayDate(nullableStringValue(data, 'receipt_date')),
              stringValue(data, 'receipt_status'),
            ].where((v) => v.trim().isNotEmpty).join(' · '),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await _viewModel.select(item);
              if (!mounted) return;
              final id = intValue(data, 'id');
              if (id != null) _openRoute('/manufacturing/production-receipts/$id');
              if (!isDesktop) _workspaceController.openEditor();
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading receipt...')
          : _ProductionReceiptEditor(
              vm: _viewModel,
              onSave: () async {
                await _viewModel.save();
                _snack();
              },
              onPost: () async {
                await _viewModel.post();
                _snack();
              },
              onCancel: () async {
                await _viewModel.cancel();
                _snack();
              },
              onDelete: () async {
                await _viewModel.delete();
                _snack();
                _openRoute('/manufacturing/production-receipts');
              },
            ),
    );
  }
}

class _ProductionReceiptEditor extends StatelessWidget {
  const _ProductionReceiptEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
  });

  final ProductionReceiptViewModel vm;
  final Future<void> Function() onSave;
  final Future<void> Function() onPost;
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
                  labelText: 'Production Order',
                  mappedItems: vm.productionOrders
                      .where((x) => intValue(x.toJson(), 'id') != null)
                      .map(
                        (x) => AppDropdownItem<int>(
                          value: intValue(x.toJson(), 'id')!,
                          label: stringValue(x.toJson(), 'production_no', 'Order'),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.productionOrderId,
                  onChanged: vm.setProductionOrderId,
                  validator: Validators.requiredSelection('Production Order'),
                ),
                AppFormTextField(
                  labelText: 'Receipt No',
                  controller: vm.receiptNoController,
                  enabled: vm.isDraft || vm.selected == null,
                ),
                AppFormTextField(
                  labelText: 'Receipt Date',
                  controller: vm.receiptDateController,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: vm.isDraft || vm.selected == null,
                  validator: Validators.compose([
                    Validators.required('Receipt Date'),
                    Validators.date('Receipt Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: vm.remarksController,
                  maxLines: 2,
                  enabled: vm.isDraft || vm.selected == null,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Row(
              children: [
                Text(
                  'Lines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add line',
                  filled: false,
                  onPressed: vm.isDraft || vm.selected == null ? vm.addLine : null,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            ...List<Widget>.generate(vm.lines.length, (index) {
              final line = vm.lines[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
                child: PurchaseCompactLineCard(
                  index: index,
                  total: vm.lines.length,
                  removeEnabled: (vm.isDraft || vm.selected == null) &&
                      vm.lines.length > 1,
                  onRemove: (vm.isDraft || vm.selected == null)
                      ? () => vm.removeLine(index)
                      : null,
                  child: PurchaseCompactFieldGrid(
                    children: [
                      AppSearchPickerField<int>(
                        labelText: 'Item',
                        selectedLabel: vm.items
                            .cast<ItemModel?>()
                            .firstWhere(
                              (x) => x?.id == line.itemId,
                              orElse: () => null,
                            )
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
                        validator: (_) =>
                            line.itemId == null ? 'Item is required' : null,
                        onChanged: (value) => vm.setLineItemId(index, value),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'UOM',
                        mappedItems: vm.uomOptionsForItem(line.itemId)
                            .where((x) => x.id != null)
                            .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                            .toList(growable: false),
                        initialValue: line.uomId,
                        onChanged: (value) => vm.setLineUomId(index, value),
                        validator: Validators.requiredSelection('UOM'),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Warehouse',
                        mappedItems: vm.warehouses
                            .where((x) => x.id != null)
                            .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                            .toList(growable: false),
                        initialValue: line.warehouseId,
                        onChanged: (value) => vm.setLineWarehouseId(index, value),
                        validator: Validators.requiredSelection('Warehouse'),
                      ),
                      AppFormTextField(
                        labelText: 'Receipt Qty',
                        controller: line.receiptQtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        enabled: vm.isDraft || vm.selected == null,
                        validator: Validators.requiredPositiveNumber('Receipt Qty'),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
                if (vm.selected != null && vm.isDraft)
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: onPost,
                  ),
                if (vm.selected != null && vm.isDraft)
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: onCancel,
                  ),
                if (vm.selected != null && vm.isDraft)
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
