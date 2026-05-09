import '../../screen.dart';
import '../../view_model/inventory/stock_transfer_view_model.dart';
import '../purchase/purchase_support.dart';

class StockTransferPage extends StatefulWidget {
  const StockTransferPage({
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
  State<StockTransferPage> createState() => _StockTransferPageState();
}

class _StockTransferPageState extends State<StockTransferPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final StockTransferViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StockTransferViewModel(initialItemId: widget.initialItemId)
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
            label: 'New Stock Transfer',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Stock Transfer',
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
      return const AppLoadingView(message: 'Loading stock transfers...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load stock transfers',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Stock Transfer',
      editorTitle: _viewModel.selected?.toString() ?? 'New Stock Transfer',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<StockTransferModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search stock transfers',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No stock transfers found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: stringValue(row.toJson(), 'transfer_no', 'Draft'),
          subtitle: [
            displayDate(nullableStringValue(row.toJson(), 'transfer_date')),
            stringValue(row.toJson(), 'transfer_status'),
          ].where((v) => v.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () async {
            await _viewModel.select(row);
            if (!context.mounted) {
              return;
            }
            if (!Responsive.isDesktop(context)) {
              _workspaceController.openEditor();
            }
          },
        ),
      ),
      editor: _StockTransferEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
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

class _StockTransferEditor extends StatelessWidget {
  const _StockTransferEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
  });

  final StockTransferViewModel vm;
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
                  mappedItems: vm.companies
                      .where((item) => item.id != null)
                      .map((item) => AppDropdownItem<int>(value: item.id!, label: item.toString()))
                      .toList(growable: false),
                  initialValue: vm.companyId,
                  validator: Validators.requiredSelection('Company'),
                  onChanged: (value) {
                    if (!canEdit) return;
                    vm.onCompanyChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Branch',
                  mappedItems: vm.branchOptions
                      .where((item) => item.id != null)
                      .map((item) => AppDropdownItem<int>(value: item.id!, label: item.toString()))
                      .toList(growable: false),
                  initialValue: vm.branchId,
                  validator: Validators.requiredSelection('Branch'),
                  onChanged: (value) {
                    if (!canEdit) return;
                    vm.onBranchChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Location',
                  mappedItems: vm.locationOptions
                      .where((item) => item.id != null)
                      .map((item) => AppDropdownItem<int>(value: item.id!, label: item.toString()))
                      .toList(growable: false),
                  initialValue: vm.locationId,
                  validator: Validators.requiredSelection('Location'),
                  onChanged: (value) {
                    if (!canEdit) return;
                    vm.onLocationChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Financial Year',
                  mappedItems: vm.financialYears
                      .where((item) => item.id != null)
                      .map((item) => AppDropdownItem<int>(value: item.id!, label: item.toString()))
                      .toList(growable: false),
                  initialValue: vm.financialYearId,
                  validator: Validators.requiredSelection('Financial Year'),
                  onChanged: (value) {
                    if (!canEdit) return;
                    vm.onFinancialYearChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Document Series',
                  mappedItems: vm.seriesOptions
                      .where((item) => item.id != null)
                      .map((item) => AppDropdownItem<int>(value: item.id!, label: item.toString()))
                      .toList(growable: false),
                  initialValue: vm.documentSeriesId,
                  onChanged: (value) {
                    if (!canEdit) return;
                    vm.onSeriesChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'From warehouse',
                  mappedItems: vm.warehouseOptions
                      .where((item) => item.id != null)
                      .map((item) => AppDropdownItem<int>(value: item.id!, label: item.toString()))
                      .toList(growable: false),
                  initialValue: vm.fromWarehouseId,
                  validator: Validators.requiredSelection('From warehouse'),
                  onChanged: (value) {
                    if (!canEdit) return;
                    vm.onFromWarehouseChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'To warehouse',
                  mappedItems: vm.warehouseOptions
                      .where((item) => item.id != null)
                      .map((item) => AppDropdownItem<int>(value: item.id!, label: item.toString()))
                      .toList(growable: false),
                  initialValue: vm.toWarehouseId,
                  validator: Validators.requiredSelection('To warehouse'),
                  onChanged: (value) {
                    if (!canEdit) return;
                    vm.onToWarehouseChanged(value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Transfer No',
                  controller: vm.transferNoController,
                  hintText: 'Leave blank if series auto-generates',
                  enabled: canEdit,
                  validator: Validators.optionalMaxLength(100, 'Transfer No'),
                ),
                AppFormTextField(
                  labelText: 'Transfer Date',
                  controller: vm.transferDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: canEdit,
                  validator: Validators.compose([
                    Validators.required('Transfer Date'),
                    Validators.date('Transfer Date'),
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
            Row(
              children: [
                Text(
                  'Line Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add line',
                  filled: false,
                  onPressed: canEdit ? vm.addLine : null,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            if (vm.lines.isEmpty)
              const Text('No line items added.')
            else
              ...List<Widget>.generate(vm.lines.length, (index) {
                final line = vm.lines[index];
                final fromBatches = vm.batchOptionsForWarehouse(vm.fromWarehouseId, line.itemId);
                final fromSerials = vm.serialOptionsForWarehouse(
                  vm.fromWarehouseId,
                  line.itemId,
                  line.fromBatchId,
                );
                final toBatches = vm.batchOptionsForWarehouse(vm.toWarehouseId, line.itemId);
                final toSerials = vm.serialOptionsForWarehouse(
                  vm.toWarehouseId,
                  line.itemId,
                  line.toBatchId,
                );
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
                              line.itemId == null ? 'Item is required' : null,
                          onChanged: (value) {
                            if (!canEdit) return;
                            vm.onLineItemChanged(index, value);
                          },
                        ),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'UOM',
                          mappedItems: vm.uomOptionsForItem(line.itemId)
                              .where((u) => u.id != null)
                              .map((u) => AppDropdownItem<int>(value: u.id!, label: u.toString()))
                              .toList(growable: false),
                          initialValue: line.uomId,
                          validator: Validators.requiredSelection('UOM'),
                          onChanged: (value) {
                            if (!canEdit) return;
                            vm.onLineUomChanged(index, value);
                          },
                        ),
                        if (vm.itemHasBatch(line.itemId))
                          AppDropdownField<int>.fromMapped(
                            labelText: 'From batch',
                            mappedItems: fromBatches
                                .map((item) => AppDropdownItem<int>(
                                      value: intValue(item, 'id')!,
                                      label: stringValue(
                                        item,
                                        'batch_no',
                                        'Batch',
                                      ),
                                    ))
                                .toList(growable: false),
                            initialValue: line.fromBatchId,
                            onChanged: (value) {
                              if (!canEdit) return;
                              vm.onLineFromBatchChanged(index, value);
                            },
                          ),
                        if (vm.itemHasSerial(line.itemId))
                          AppDropdownField<int>.fromMapped(
                            labelText: 'From serial',
                            mappedItems: fromSerials
                                .map((item) => AppDropdownItem<int>(
                                      value: intValue(item, 'id')!,
                                      label: stringValue(
                                        item,
                                        'serial_no',
                                        'Serial',
                                      ),
                                    ))
                                .toList(growable: false),
                            initialValue: line.fromSerialId,
                            onChanged: (value) {
                              if (!canEdit) return;
                              vm.onLineFromSerialChanged(index, value);
                            },
                          ),
                        if (vm.itemHasBatch(line.itemId))
                          AppDropdownField<int>.fromMapped(
                            labelText: 'To batch',
                            mappedItems: toBatches
                                .map((item) => AppDropdownItem<int>(
                                      value: intValue(item, 'id')!,
                                      label: stringValue(
                                        item,
                                        'batch_no',
                                        'Batch',
                                      ),
                                    ))
                                .toList(growable: false),
                            initialValue: line.toBatchId,
                            onChanged: (value) {
                              if (!canEdit) return;
                              vm.onLineToBatchChanged(index, value);
                            },
                          ),
                        if (vm.itemHasSerial(line.itemId))
                          AppDropdownField<int>.fromMapped(
                            labelText: 'To serial',
                            mappedItems: toSerials
                                .map((item) => AppDropdownItem<int>(
                                      value: intValue(item, 'id')!,
                                      label: stringValue(
                                        item,
                                        'serial_no',
                                        'Serial',
                                      ),
                                    ))
                                .toList(growable: false),
                            initialValue: line.toSerialId,
                            onChanged: (value) {
                              if (!canEdit) return;
                              vm.onLineToSerialChanged(index, value);
                            },
                          ),
                        AppFormTextField(
                          labelText: 'Transfer qty',
                          controller: line.qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: canEdit,
                          validator: Validators.requiredPositiveNumber('Transfer qty'),
                        ),
                        AppFormTextField(
                          labelText: 'Unit Cost',
                          controller: line.unitCostController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: canEdit,
                          validator: Validators.optionalNonNegativeNumber('Unit Cost'),
                        ),
                        AppFormTextField(
                          labelText: 'Total Cost',
                          controller: line.totalCostController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: canEdit,
                          validator: Validators.optionalNonNegativeNumber('Total Cost'),
                        ),
                        AppFormTextField(
                          labelText: 'Remarks',
                          controller: line.remarksController,
                          enabled: canEdit,
                          validator: Validators.optionalMaxLength(500, 'Line Remarks'),
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
