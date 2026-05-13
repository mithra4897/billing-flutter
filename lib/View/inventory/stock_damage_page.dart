import '../../screen.dart';
import '../../view_model/inventory/stock_damage_view_model.dart';
import '../purchase/purchase_support.dart';

class StockDamagePage extends StatefulWidget {
  const StockDamagePage({
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
  State<StockDamagePage> createState() => _StockDamagePageState();
}

class _StockDamagePageState extends State<StockDamagePage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final StockDamageViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StockDamageViewModel(initialItemId: widget.initialItemId)
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
            label: 'New Stock Damage',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Stock Damage',
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
      return const AppLoadingView(message: 'Loading stock damage entries...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load stock damage entries',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Stock Damage',
      editorTitle: _viewModel.selected?.toString() ?? 'New Stock Damage',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<StockDamageEntryModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search stock damage entries',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No stock damage entries found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: stringValue(row.toJson(), 'damage_no', 'Draft'),
          subtitle: [
            displayDate(nullableStringValue(row.toJson(), 'damage_date')),
            stringValue(row.toJson(), 'damage_status'),
            stringValue(row.toJson(), 'damage_type'),
          ].where((v) => v.trim().isNotEmpty).join(' · '),
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
      editor: _StockDamageEditor(
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

class _StockDamageEditor extends StatelessWidget {
  const _StockDamageEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
  });

  final StockDamageViewModel vm;
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Financial Year',
                  mappedItems: vm.financialYears
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
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
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.documentSeriesId,
                  onChanged: (value) {
                    if (!canEdit) return;
                    vm.onSeriesChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Warehouse',
                  mappedItems: vm.warehouseOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.warehouseId,
                  validator: Validators.requiredSelection('Warehouse'),
                  onChanged: (value) {
                    if (!canEdit) return;
                    vm.onWarehouseChanged(value);
                  },
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Damage type',
                  mappedItems: stockDamageTypeItems,
                  initialValue: vm.damageType,
                  validator: Validators.requiredSelection('Damage type'),
                  onChanged: (value) {
                    if (!canEdit) return;
                    vm.onDamageTypeChanged(value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Damage No',
                  controller: vm.damageNoController,
                  hintText: 'Leave blank if series auto-generates',
                  enabled: canEdit,
                  validator: Validators.optionalMaxLength(100, 'Damage No'),
                ),
                AppFormTextField(
                  labelText: 'Damage Date',
                  controller: vm.damageDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: canEdit,
                  validator: Validators.compose([
                    Validators.required('Damage Date'),
                    Validators.date('Damage Date'),
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
                final batches = vm.batchOptions(line.itemId);
                final serials = vm.serialOptions(line.itemId, line.batchId);
                final showBatch = vm.itemHasBatch(line.itemId);
                final showSerial = vm.itemHasSerial(line.itemId);
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
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
                          mappedItems: vm
                              .uomOptionsForItem(line.itemId)
                              .where((u) => u.id != null)
                              .map(
                                (u) => AppDropdownItem<int>(
                                  value: u.id!,
                                  label: u.toString(),
                                ),
                              )
                              .toList(growable: false),
                          initialValue: line.uomId,
                          validator: Validators.requiredSelection('UOM'),
                          onChanged: (value) {
                            if (!canEdit) return;
                            vm.onLineUomChanged(index, value);
                          },
                        ),
                        if (showBatch)
                          AppDropdownField<int>.fromMapped(
                            labelText: 'Batch',
                            mappedItems: batches
                                .map(
                                  (item) => AppDropdownItem<int>(
                                    value: intValue(item, 'id')!,
                                    label: stringValue(
                                      item,
                                      'batch_no',
                                      'Batch',
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            initialValue: line.batchId,
                            onChanged: (value) {
                              if (!canEdit) return;
                              vm.onLineBatchChanged(index, value);
                            },
                          ),
                        if (showSerial)
                          AppSerialNumbersField(
                            values: vm
                                .lineSerialIds(line)
                                .map((id) {
                                  final serial = serials
                                      .cast<Map<String, dynamic>?>()
                                      .firstWhere(
                                        (entry) =>
                                            entry != null &&
                                            intValue(entry, 'id') == id,
                                        orElse: () => null,
                                      );
                                  return serial == null
                                      ? ''
                                      : stringValue(serial, 'serial_no');
                                })
                                .where((value) => value.trim().isNotEmpty)
                                .toList(growable: false),
                            enabled: canEdit,
                            emptyText: 'No serials added',
                            countSummaryBuilder: (count) =>
                                '$count serial(s) added',
                            validator: (values) {
                              final serialIdByLabel = <String, int>{
                                for (final serial in serials)
                                  stringValue(
                                        serial,
                                        'serial_no',
                                      ).trim().toLowerCase():
                                      intValue(serial, 'id') ?? 0,
                              };
                              for (final label in values) {
                                if (!serialIdByLabel.containsKey(
                                  label.toLowerCase(),
                                )) {
                                  return 'Serial "$label" is not available for this item/batch.';
                                }
                              }
                              return null;
                            },
                            onChanged: (values) {
                              final serialIdByLabel = <String, int>{
                                for (final serial in serials)
                                  stringValue(
                                        serial,
                                        'serial_no',
                                      ).trim().toLowerCase():
                                      intValue(serial, 'id') ?? 0,
                              };
                              final resolvedIds = values
                                  .map(
                                    (value) =>
                                        serialIdByLabel[value.toLowerCase()]!,
                                  )
                                  .toList(growable: false);
                              vm.setLineSerialIds(index, resolvedIds);
                            },
                          ),
                        AppFormTextField(
                          labelText: 'Damage qty',
                          controller: line.qtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: canEdit && !showSerial,
                          validator: Validators.requiredPositiveNumber(
                            'Damage qty',
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Unit Cost',
                          controller: line.unitCostController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: canEdit,
                          validator: Validators.optionalNonNegativeNumber(
                            'Unit Cost',
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Total Cost',
                          controller: line.totalCostController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: canEdit,
                          validator: Validators.optionalNonNegativeNumber(
                            'Total Cost',
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Reason',
                          controller: line.reasonController,
                          enabled: canEdit,
                          validator: Validators.optionalMaxLength(
                            255,
                            'Reason',
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Remarks',
                          controller: line.remarksController,
                          enabled: canEdit,
                          validator: Validators.optionalMaxLength(
                            500,
                            'Line Remarks',
                          ),
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
