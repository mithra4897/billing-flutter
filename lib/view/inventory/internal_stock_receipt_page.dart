import '../../screen.dart';

class InternalStockReceiptPage extends StatefulWidget {
  const InternalStockReceiptPage({
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
  State<InternalStockReceiptPage> createState() =>
      _InternalStockReceiptPageState();
}

class _InternalStockReceiptPageState extends State<InternalStockReceiptPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final InternalStockReceiptViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('InternalStockReceiptViewModel');
    _viewModel = Get.put(
      InternalStockReceiptViewModel(initialItemId: widget.initialItemId)
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
    return GetBuilder<InternalStockReceiptViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final content = _buildContent(context);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => _openFilterPanel(context),
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: false,
          ),
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
            label: 'New Internal Receipt',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Internal Stock Receipt',
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

  Future<void> _openFilterPanel(BuildContext context) {
    return openInventorySearchStatusCategoryFilterPanel(
      context: context,
      title: 'Filter Internal Stock Receipts',
      searchController: _viewModel.searchController,
      dateFromController: _viewModel.dateFromController,
      dateToController: _viewModel.dateToController,
      searchHint: 'Search by receipt no, source, status',
      status: _viewModel.statusFilter,
      statusItems: InternalStockReceiptViewModel.listStatusFilter,
      category: _viewModel.categoryFilter,
      categoryItems: _viewModel.categoryItems,
      onApply: (search, status, dateFrom, dateTo, category) {
        _viewModel.searchController.text = search;
        _viewModel.dateFromController.text = dateFrom;
        _viewModel.dateToController.text = dateTo;
        _viewModel.statusFilter = status;
        _viewModel.categoryFilter = category;
        _viewModel.applyFilters();
      },
      onClear: () {
        _viewModel.searchController.clear();
        _viewModel.dateFromController.clear();
        _viewModel.dateToController.clear();
        _viewModel.statusFilter = '';
        _viewModel.categoryFilter = '';
        _viewModel.applyFilters();
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading internal receipts...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load internal receipts',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Internal Stock Receipt',
      editorTitle: _viewModel.selected?.toString() ?? 'New Internal Receipt',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<InternalStockReceiptModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search internal receipts',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No internal receipts found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: stringValue(row.toJson(), 'receipt_no', 'Draft'),
          subtitle: [
            displayDate(nullableStringValue(row.toJson(), 'receipt_date')),
            stringValue(row.toJson(), 'receipt_status'),
            stringValue(row.toJson(), 'receipt_source'),
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
      editor: _InternalStockReceiptEditor(
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

class _InternalStockReceiptEditor extends StatelessWidget {
  const _InternalStockReceiptEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
  });

  final InternalStockReceiptViewModel vm;
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
                    if (!canEdit) {
                      return;
                    }
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
                    if (!canEdit) {
                      return;
                    }
                    vm.onWarehouseChanged(value);
                  },
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Receipt source',
                  mappedItems: internalStockReceiptSourceItems,
                  initialValue: vm.receiptSource,
                  validator: Validators.requiredSelection('Receipt source'),
                  onChanged: (value) {
                    if (!canEdit) {
                      return;
                    }
                    vm.onReceiptSourceChanged(value);
                  },
                ),
                GeneratedDocumentNumberField(
                  labelText: 'Receipt No',
                  controller: vm.receiptNoController,
                  documentSeries: vm.seriesOptions,
                  documentSeriesId: vm.documentSeriesId,
                  hintText: 'Leave blank if series auto-generates',
                  enabled: canEdit,
                  validator: Validators.optionalMaxLength(100, 'Receipt No'),
                ),
                AppFormTextField(
                  labelText: 'Receipt Date',
                  controller: vm.receiptDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: canEdit,
                  validator: Validators.compose([
                    Validators.required('Receipt Date'),
                    Validators.date('Receipt Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Received from',
                  controller: vm.receivedFromController,
                  enabled: canEdit,
                  validator: Validators.optionalMaxLength(255, 'Received from'),
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
                  label: 'Serials',
                  width: 240,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'receipt_qty',
                  label: 'Receipt Qty',
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
              ],
              lines: List<ErpLineItemTableRow>.generate(vm.lines.length, (
                index,
              ) {
                final line = vm.lines[index];
                return ErpLineItemTableRow(
                  rowKey: line,
                  itemId: line.itemId,
                  itemSelection: vm.items
                      .where((x) => x.id == line.itemId)
                      .map(
                        (x) => ErpLinkFieldOption<int>(
                          value: x.id!,
                          label: x.toString(),
                          subtitle: x.itemCode,
                        ),
                      )
                      .firstOrNull,
                  itemOptions: vm.items
                      .where((x) => x.id != null)
                      .map(
                        (x) => ErpLinkFieldOption<int>(
                          value: x.id!,
                          label: x.toString(),
                          subtitle: x.itemCode,
                        ),
                      )
                      .toList(growable: false),
                  onItemChanged: canEdit
                      ? (v) => vm.onLineItemChanged(index, v)
                      : null,
                  itemValidator: (_) =>
                      line.itemId == null ? 'Item is required' : null,
                  uomId: line.uomId,
                  uomOptions: vm
                      .uomOptionsForItem(line.itemId)
                      .where((u) => u.id != null)
                      .map(
                        (u) => AppDropdownItem<int>(
                          value: u.id!,
                          label: u.toString(),
                        ),
                      )
                      .toList(growable: false),
                  onUomChanged: canEdit
                      ? (v) => vm.onLineUomChanged(index, v)
                      : null,
                  uomValidator: Validators.requiredSelection('UOM'),
                  amount: 0,
                  deleteEnabled: canEdit && vm.lines.length > 1,
                  customCells: <String, Widget>{
                    'batch': vm.itemHasBatch(line.itemId)
                        ? ErpLineItemTextCell(
                            controller: line.batchNoController,
                            enabled: canEdit,
                            validator: (value) {
                              if (!vm.itemHasBatch(line.itemId)) {
                                return null;
                              }
                              if ((value ?? '').trim().isEmpty) {
                                return 'Batch is required';
                              }
                              return null;
                            },
                            onChanged: canEdit
                                ? (v) => vm.onLineBatchInputChanged(index, v)
                                : null,
                          )
                        : const ErpLineItemTextCell(
                            readOnly: true,
                            enabled: false,
                            initialValue: '-',
                          ),
                    'serial': vm.itemHasSerial(line.itemId)
                        ? ErpLineItemCellFrame(
                            height: null,
                            child: AppSerialNumbersField(
                              values: line.serialNumbers,
                              enabled: canEdit,
                              emptyText: 'No serials added',
                              countSummaryBuilder: (count) =>
                                  '$count serial(s) added',
                              onChanged: (values) =>
                                  vm.setLineSerialNumbers(index, values),
                            ),
                          )
                        : const ErpLineItemTextCell(
                            readOnly: true,
                            enabled: false,
                            initialValue: '-',
                          ),
                    'receipt_qty': ErpLineItemTextCell(
                      controller: line.qtyController,
                      enabled: canEdit && !vm.itemHasSerial(line.itemId),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.requiredPositiveNumber(
                        'Receipt qty',
                      ),
                    ),
                    'unit_cost': ErpLineItemTextCell(
                      controller: line.unitCostController,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.optionalNonNegativeNumber(
                        'Unit Cost',
                      ),
                    ),
                    'total_cost': ErpLineItemTextCell(
                      controller: line.totalCostController,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.optionalNonNegativeNumber(
                        'Total Cost',
                      ),
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
