import '../../screen.dart';

class InventoryAdjustmentPage extends StatefulWidget {
  const InventoryAdjustmentPage({
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
  State<InventoryAdjustmentPage> createState() =>
      _InventoryAdjustmentPageState();
}

class _InventoryAdjustmentPageState extends State<InventoryAdjustmentPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final InventoryAdjustmentViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('InventoryAdjustmentViewModel');
    _viewModel = Get.put(
      InventoryAdjustmentViewModel(initialItemId: widget.initialItemId)
        ..load(selectId: widget.initialId),
      tag: _controllerTag,
      permanent: true,
    );
  }

  @override
  void dispose() {
    _workspaceController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InventoryAdjustmentViewModel>(
      tag: _controllerTag,
      builder: (_) {
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
            label: 'New Adjustment',
          ),
        ];
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Inventory Adjustment',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  void _showActionSnackBar() {
    final message = _viewModel.consumeActionMessage();
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading inventory adjustments...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load inventory adjustments',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Inventory Adjustment',
      editorTitle: _viewModel.selected?.toString() ?? 'New Adjustment',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<InventoryAdjustmentModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search adjustments',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No inventory adjustments found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: stringValue(row.toJson(), 'adjustment_no', 'Draft'),
          subtitle: [
            displayDate(nullableStringValue(row.toJson(), 'adjustment_date')),
            stringValue(row.toJson(), 'adjustment_status'),
            stringValue(row.toJson(), 'adjustment_type'),
          ].where((v) => v.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () async {
            await _viewModel.selectRow(row);
            if (!context.mounted) return;
            if (!Responsive.isDesktop(context)) {
              _workspaceController.openEditor();
            }
          },
        ),
      ),
      editor: _InventoryAdjustmentEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) return;
          await _viewModel.save();
          _showActionSnackBar();
        },
        onPost: () async {
          await _viewModel.post();
          _showActionSnackBar();
        },
        onCancel: () async {
          await _viewModel.cancel();
          _showActionSnackBar();
        },
        onDelete: () async {
          await _viewModel.delete();
          _showActionSnackBar();
        },
      ),
    );
  }
}

class _InventoryAdjustmentEditor extends StatelessWidget {
  const _InventoryAdjustmentEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
  });

  final InventoryAdjustmentViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onPost;
  final Future<void> Function() onCancel;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }
    final canEdit = vm.status == 'draft';
    final contextLabel = vm.contextLabels.isEmpty
        ? 'No working context selected'
        : vm.contextLabels.join(' / ');
    return Form(
      child: Builder(
        builder: (formContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.formError != null) ...[
              AppErrorStateView.inline(message: vm.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Context'),
              child: Text(contextLabel),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            if (vm.warehouseOptions.isEmpty) ...[
              AppErrorStateView.inline(
                message:
                    'No warehouse found for the selected working context: $contextLabel.',
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
            ],
            SettingsFormWrap(
              children: [
                DocumentSeriesSelector<int>(
                  labelText: 'Document Series',
                  mappedItems: vm.seriesOptions
                      .where((x) => x.id != null)
                      .map(
                        (x) => AppDropdownItem<int>(
                          value: x.id!,
                          label: x.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.documentSeriesId,
                  onChanged: (v) {
                    if (!canEdit) return;
                    vm.onSeriesChanged(v);
                  },
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Adjustment type',
                  mappedItems: inventoryAdjustmentTypeItems,
                  initialValue: vm.adjustmentType,
                  validator: Validators.requiredSelection('Adjustment type'),
                  onChanged: (v) {
                    if (!canEdit) return;
                    vm.onAdjustmentTypeChanged(v);
                  },
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Reason code',
                  mappedItems: inventoryAdjustmentReasonItems,
                  initialValue: vm.reasonCode,
                  validator: Validators.requiredSelection('Reason code'),
                  onChanged: (v) {
                    if (!canEdit) return;
                    vm.onReasonCodeChanged(v);
                  },
                ),
                AppFormTextField(
                  labelText: 'Adjustment No',
                  controller: vm.adjustmentNoController,
                  enabled: canEdit,
                  validator: Validators.optionalMaxLength(100, 'Adjustment No'),
                ),
                AppFormTextField(
                  labelText: 'Adjustment Date',
                  controller: vm.adjustmentDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: canEdit,
                  validator: Validators.compose([
                    Validators.required('Adjustment Date'),
                    Validators.date('Adjustment Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: vm.remarksController,
                  maxLines: 2,
                  enabled: canEdit,
                  validator: Validators.optionalMaxLength(1000, 'Remarks'),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            ErpLineItemTable(
              title: 'Line Items',
              enabled: canEdit,
              onAddLine: canEdit ? vm.addLine : null,
              onDeleteLine: canEdit ? (i) => vm.removeLine(i) : null,
              visibleColumns: const <ErpLineItemTableColumn>{
                ErpLineItemTableColumn.no,
                ErpLineItemTableColumn.item,
                ErpLineItemTableColumn.warehouse,
                ErpLineItemTableColumn.uom,
                ErpLineItemTableColumn.action,
              },
              customColumns: const <ErpLineItemCustomColumn>[
                ErpLineItemCustomColumn(
                  id: 'batch',
                  label: 'Batch',
                  width: 140,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'serial',
                  label: 'Serial',
                  width: 140,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'direction',
                  label: 'Direction',
                  width: 110,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'system_qty',
                  label: 'System Qty',
                  width: 110,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'actual_qty',
                  label: 'Actual Qty',
                  width: 110,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'adj_qty',
                  label: 'Adj Qty',
                  width: 110,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'unit_cost',
                  label: 'Unit Cost',
                  width: 110,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'total_cost',
                  label: 'Total Cost',
                  width: 118,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'remarks',
                  label: 'Remarks',
                  width: 200,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
              ],
              lines: List<ErpLineItemTableRow>.generate(vm.lines.length, (index) {
                final line = vm.lines[index];
                final batches = vm.batchOptions(line.warehouseId, line.itemId);
                final serials = vm.serialOptions(
                  line.warehouseId,
                  line.itemId,
                  line.batchId,
                );
                return ErpLineItemTableRow(
                  rowKey: line,
                  itemId: line.itemId,
                  itemSelection: vm.items
                      .where((x) => x.id == line.itemId)
                      .map((x) => ErpLinkFieldOption<int>(value: x.id!, label: x.toString(), subtitle: x.itemCode))
                      .firstOrNull,
                  itemOptions: vm.items
                      .where((x) => x.id != null)
                      .map((x) => ErpLinkFieldOption<int>(value: x.id!, label: x.toString(), subtitle: x.itemCode))
                      .toList(growable: false),
                  onItemChanged: canEdit ? (v) => vm.onLineItemChanged(index, v) : null,
                  itemValidator: (_) => line.itemId == null ? 'Item is required' : null,
                  warehouseId: line.warehouseId,
                  warehouseOptions: vm.warehouseOptions
                      .where((x) => x.id != null)
                      .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                      .toList(growable: false),
                  onWarehouseChanged: canEdit ? (v) => vm.onLineWarehouseChanged(index, v) : null,
                  uomId: line.uomId,
                  uomOptions: vm.uomOptionsForItem(line.itemId)
                      .where((x) => x.id != null)
                      .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                      .toList(growable: false),
                  onUomChanged: canEdit ? (v) => vm.onLineUomChanged(index, v) : null,
                  uomValidator: Validators.requiredSelection('UOM'),
                  amount: 0,
                  deleteEnabled: canEdit && vm.lines.length > 1,
                  customCells: <String, Widget>{
                    'batch': vm.itemHasBatch(line.itemId)
                        ? ErpLineItemCellFrame(
                            child: AppDropdownField<int>.fromMapped(
                              labelText: '',
                              hintText: 'Batch',
                              fieldPadding: EdgeInsets.zero,
                              mappedItems: batches
                                  .map((x) => AppDropdownItem<int>(
                                        value: intValue(x, 'id')!,
                                        label: stringValue(x, 'batch_no', 'Batch'),
                                      ))
                                  .toList(growable: false),
                              initialValue: line.batchId,
                              onChanged: canEdit ? (v) => vm.onLineBatchChanged(index, v) : null,
                            ),
                          )
                        : const ErpLineItemTextCell(readOnly: true, enabled: false, initialValue: '-'),
                    'serial': vm.itemHasSerial(line.itemId)
                        ? ErpLineItemCellFrame(
                            child: AppDropdownField<int>.fromMapped(
                              labelText: '',
                              hintText: 'Serial',
                              fieldPadding: EdgeInsets.zero,
                              mappedItems: serials
                                  .map((x) => AppDropdownItem<int>(
                                        value: intValue(x, 'id')!,
                                        label: stringValue(x, 'serial_no', 'Serial'),
                                      ))
                                  .toList(growable: false),
                              initialValue: line.serialId,
                              onChanged: canEdit ? (v) => vm.onLineSerialChanged(index, v) : null,
                            ),
                          )
                        : const ErpLineItemTextCell(readOnly: true, enabled: false, initialValue: '-'),
                    'direction': ErpLineItemCellFrame(
                      child: AppDropdownField<String>.fromMapped(
                        labelText: '',
                        hintText: 'Direction',
                        fieldPadding: EdgeInsets.zero,
                        mappedItems: const <AppDropdownItem<String>>[
                          AppDropdownItem<String>(value: 'in', label: 'In'),
                          AppDropdownItem<String>(value: 'out', label: 'Out'),
                        ],
                        initialValue: line.adjustmentDirection,
                        validator: Validators.requiredSelection('Direction'),
                        onChanged: canEdit ? (v) => vm.onLineDirectionChanged(index, v) : null,
                      ),
                    ),
                    'system_qty': ErpLineItemTextCell(
                      controller: line.systemQtyController,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.optionalNonNegativeNumber('System qty'),
                    ),
                    'actual_qty': ErpLineItemTextCell(
                      controller: line.actualQtyController,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.optionalNonNegativeNumber('Actual qty'),
                    ),
                    'adj_qty': ErpLineItemTextCell(
                      controller: line.adjustmentQtyController,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;
                        if (double.tryParse(text) == null) return 'Adjustment qty must be a valid number';
                        return null;
                      },
                    ),
                    'unit_cost': ErpLineItemTextCell(
                      controller: line.unitCostController,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.optionalNonNegativeNumber('Unit cost'),
                    ),
                    'total_cost': ErpLineItemTextCell(
                      controller: line.totalCostController,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;
                        if (double.tryParse(text) == null) return 'Total cost must be a valid number';
                        return null;
                      },
                    ),
                    'remarks': ErpLineItemTextCell(
                      controller: line.remarksController,
                      enabled: canEdit,
                      validator: Validators.optionalMaxLength(500, 'Line remarks'),
                    ),
                  },
                );
              }),
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
                  onPressed: canEdit ? () => onSave(formContext) : null,
                ),
                if (vm.selected != null && vm.status == 'draft') ...[
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: onPost,
                  ),
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                    onPressed: onDelete,
                  ),
                ],
                if (vm.selected != null && vm.status == 'draft')
                  AppActionButton(
                    icon: Icons.block_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: onCancel,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
