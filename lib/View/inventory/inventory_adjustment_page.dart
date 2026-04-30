import '../../screen.dart';
import '../../view_model/inventory/inventory_adjustment_view_model.dart';
import '../purchase/purchase_support.dart';

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
  State<InventoryAdjustmentPage> createState() => _InventoryAdjustmentPageState();
}

class _InventoryAdjustmentPageState extends State<InventoryAdjustmentPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController = SettingsWorkspaceController();
  late final InventoryAdjustmentViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = InventoryAdjustmentViewModel(initialItemId: widget.initialItemId)
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
                  mappedItems: vm.companies.where((x) => x.id != null).map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString())).toList(growable: false),
                  initialValue: vm.companyId,
                  validator: Validators.requiredSelection('Company'),
                  onChanged: (v) {
                    if (!canEdit) return;
                    vm.onCompanyChanged(v);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Branch',
                  mappedItems: vm.branchOptions.where((x) => x.id != null).map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString())).toList(growable: false),
                  initialValue: vm.branchId,
                  validator: Validators.requiredSelection('Branch'),
                  onChanged: (v) {
                    if (!canEdit) return;
                    vm.onBranchChanged(v);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Location',
                  mappedItems: vm.locationOptions.where((x) => x.id != null).map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString())).toList(growable: false),
                  initialValue: vm.locationId,
                  validator: Validators.requiredSelection('Location'),
                  onChanged: (v) {
                    if (!canEdit) return;
                    vm.onLocationChanged(v);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Financial Year',
                  mappedItems: vm.financialYears.where((x) => x.id != null).map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString())).toList(growable: false),
                  initialValue: vm.financialYearId,
                  validator: Validators.requiredSelection('Financial Year'),
                  onChanged: (v) {
                    if (!canEdit) return;
                    vm.onFinancialYearChanged(v);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Document Series',
                  mappedItems: vm.seriesOptions.where((x) => x.id != null).map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString())).toList(growable: false),
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
                  validator: Validators.compose([Validators.required('Adjustment Date'), Validators.date('Adjustment Date')]),
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
            Row(
              children: [
                Text('Line Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                AppActionButton(icon: Icons.add_outlined, label: 'Add line', filled: false, onPressed: canEdit ? vm.addLine : null),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            if (vm.lines.isEmpty)
              const Text('No line items added.')
            else
              ...List<Widget>.generate(vm.lines.length, (index) {
                final line = vm.lines[index];
                final batches = vm.batchOptions(line.warehouseId, line.itemId);
                final serials = vm.serialOptions(line.warehouseId, line.itemId, line.batchId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
                  child: PurchaseCompactLineCard(
                    index: index,
                    total: vm.lines.length,
                    removeEnabled: canEdit && vm.lines.length > 1,
                    onRemove: canEdit ? () => vm.removeLine(index) : null,
                    child: PurchaseCompactFieldGrid(
                      children: [
                        AppSearchPickerField<int>(
                          labelText: 'Item',
                          selectedLabel: vm.items
                              .cast<ItemModel?>()
                              .firstWhere(
                                (item) => item?.id == line.itemId,
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
                          onChanged: (v) {
                            if (!canEdit) return;
                            vm.onLineItemChanged(index, v);
                          },
                        ),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Warehouse',
                          mappedItems: vm.warehouseOptions.where((x) => x.id != null).map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString())).toList(growable: false),
                          initialValue: line.warehouseId,
                          validator: Validators.requiredSelection('Warehouse'),
                          onChanged: (v) {
                            if (!canEdit) return;
                            vm.onLineWarehouseChanged(index, v);
                          },
                        ),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'UOM',
                          mappedItems: vm.uomOptionsForItem(line.itemId)
                              .where((x) => x.id != null)
                              .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                              .toList(growable: false),
                          initialValue: line.uomId,
                          validator: Validators.requiredSelection('UOM'),
                          onChanged: (v) {
                            if (!canEdit) return;
                            vm.onLineUomChanged(index, v);
                          },
                        ),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Batch',
                          mappedItems: batches.map((x) => AppDropdownItem<int>(value: intValue(x, 'id')!, label: stringValue(x, 'batch_no', 'Batch'))).toList(growable: false),
                          initialValue: line.batchId,
                          onChanged: (v) {
                            if (!canEdit) return;
                            vm.onLineBatchChanged(index, v);
                          },
                        ),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Serial',
                          mappedItems: serials.map((x) => AppDropdownItem<int>(value: intValue(x, 'id')!, label: stringValue(x, 'serial_no', 'Serial'))).toList(growable: false),
                          initialValue: line.serialId,
                          onChanged: (v) {
                            if (!canEdit) return;
                            vm.onLineSerialChanged(index, v);
                          },
                        ),
                        AppDropdownField<String>.fromMapped(
                          labelText: 'Direction',
                          mappedItems: const <AppDropdownItem<String>>[
                            AppDropdownItem<String>(value: 'in', label: 'In'),
                            AppDropdownItem<String>(value: 'out', label: 'Out'),
                          ],
                          initialValue: line.adjustmentDirection,
                          validator: Validators.requiredSelection('Direction'),
                          onChanged: (v) {
                            if (!canEdit) return;
                            vm.onLineDirectionChanged(index, v);
                          },
                        ),
                        AppFormTextField(labelText: 'System qty', controller: line.systemQtyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), enabled: canEdit, validator: Validators.optionalNonNegativeNumber('System qty')),
                        AppFormTextField(labelText: 'Actual qty', controller: line.actualQtyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), enabled: canEdit, validator: Validators.optionalNonNegativeNumber('Actual qty')),
                        AppFormTextField(
                          labelText: 'Adjustment qty',
                          controller: line.adjustmentQtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: canEdit,
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.isEmpty) return null;
                            if (double.tryParse(text) == null) return 'Adjustment qty must be a valid number';
                            return null;
                          },
                        ),
                        AppFormTextField(labelText: 'Unit cost', controller: line.unitCostController, keyboardType: const TextInputType.numberWithOptions(decimal: true), enabled: canEdit, validator: Validators.optionalNonNegativeNumber('Unit cost')),
                        AppFormTextField(
                          labelText: 'Total cost',
                          controller: line.totalCostController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: canEdit,
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.isEmpty) return null;
                            if (double.tryParse(text) == null) return 'Total cost must be a valid number';
                            return null;
                          },
                        ),
                        AppFormTextField(labelText: 'Remarks', controller: line.remarksController, enabled: canEdit, validator: Validators.optionalMaxLength(500, 'Line remarks')),
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
                AppActionButton(icon: Icons.save_outlined, label: vm.selected == null ? 'Save' : 'Update', busy: vm.saving, onPressed: canEdit ? () => onSave(formContext) : null),
                if (vm.selected != null && vm.status == 'draft') ...[
                  AppActionButton(icon: Icons.publish_outlined, label: 'Post', filled: false, onPressed: onPost),
                  AppActionButton(icon: Icons.delete_outline, label: 'Delete', filled: false, onPressed: onDelete),
                ],
                if (vm.selected != null && vm.status == 'draft')
                  AppActionButton(icon: Icons.block_outlined, label: 'Cancel', filled: false, onPressed: onCancel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
