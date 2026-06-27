import '../../screen.dart';

class StockIssuePage extends StatefulWidget {
  const StockIssuePage({
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
  State<StockIssuePage> createState() => _StockIssuePageState();
}

class _StockIssuePageState extends State<StockIssuePage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final StockIssueViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('StockIssueViewModel');
    _viewModel = Get.put(
      StockIssueViewModel(initialItemId: widget.initialItemId)
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
    return GetBuilder<StockIssueViewModel>(
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
            label: 'New Stock Issue',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Stock Issue',
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
      return const AppLoadingView(message: 'Loading stock issues...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load stock issues',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Stock Issue',
      editorTitle: _viewModel.selected?.toString() ?? 'New Stock Issue',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<StockIssueModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search stock issues',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No stock issues found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: stringValue(row.toJson(), 'issue_no', 'Draft'),
          subtitle: [
            displayDate(nullableStringValue(row.toJson(), 'issue_date')),
            stringValue(row.toJson(), 'issue_status'),
            stringValue(row.toJson(), 'issue_purpose'),
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
      editor: _StockIssueEditor(
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

class _StockIssueEditor extends StatelessWidget {
  const _StockIssueEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
  });

  final StockIssueViewModel vm;
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
                  key: ValueKey<Object>(
                    Object.hashAll(<Object?>[
                      vm.companyId,
                      vm.branchId,
                      vm.locationId,
                      vm.financialYearId,
                      vm.documentSeriesId,
                      vm.seriesOptions.map((e) => e.id).join(','),
                    ]),
                  ),
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
                  labelText: 'Issue purpose',
                  mappedItems: stockIssuePurposeItems,
                  initialValue: vm.issuePurpose,
                  validator: Validators.requiredSelection('Issue purpose'),
                  onChanged: (value) {
                    if (!canEdit) {
                      return;
                    }
                    vm.onIssuePurposeChanged(value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Issue No',
                  controller: vm.issueNoController,
                  hintText: 'Leave blank if series auto-generates',
                  enabled: canEdit,
                  validator: Validators.optionalMaxLength(100, 'Issue No'),
                ),
                AppFormTextField(
                  labelText: 'Issue Date',
                  controller: vm.issueDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: canEdit,
                  validator: Validators.compose([
                    Validators.required('Issue Date'),
                    Validators.date('Issue Date'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Department',
                  mappedItems: vm.departments
                      .where((d) => (d.departmentName ?? '').trim().isNotEmpty)
                      .map(
                        (d) => AppDropdownItem<String>(
                          value: d.departmentName!.trim(),
                          label: d.departmentName!.trim(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.departmentNameController.text.trim().isEmpty
                      ? null
                      : vm.departmentNameController.text.trim(),
                  onChanged: (value) {
                    if (!canEdit) {
                      return;
                    }
                    vm.onDepartmentChanged(value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Issued to',
                  controller: vm.issuedToController,
                  enabled: canEdit,
                  validator: Validators.optionalMaxLength(255, 'Issued to'),
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
                  id: 'issue_qty',
                  label: 'Issue Qty',
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
                final batches = vm.batchOptions(line.itemId);
                final serials = vm.serialOptions(line.itemId, line.batchId);
                final showBatch = vm.itemHasBatch(line.itemId);
                final showSerial = vm.itemHasSerial(line.itemId);
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
                    'batch': showBatch
                        ? ErpLineItemCellFrame(
                            child: AppDropdownField<int>.fromMapped(
                              labelText: '',
                              hintText: 'Batch',
                              fieldPadding: EdgeInsets.zero,
                              mappedItems: batches
                                  .map(
                                    (x) => AppDropdownItem<int>(
                                      value: intValue(x, 'id')!,
                                      label: stringValue(
                                        x,
                                        'batch_no',
                                        'Batch',
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                              initialValue: line.batchId,
                              onChanged: canEdit
                                  ? (v) => vm.onLineBatchChanged(index, v)
                                  : null,
                            ),
                          )
                        : const ErpLineItemTextCell(
                            readOnly: true,
                            enabled: false,
                            initialValue: '-',
                          ),
                    'serial': showSerial
                        ? ErpLineItemCellFrame(
                            height: null,
                            child: AppSerialNumbersField(
                              values: vm
                                  .lineSerialIds(line)
                                  .map((id) {
                                    final serial = serials
                                        .cast<Map<String, dynamic>?>()
                                        .firstWhere(
                                          (e) =>
                                              e != null &&
                                              intValue(e, 'id') == id,
                                          orElse: () => null,
                                        );
                                    return serial == null
                                        ? ''
                                        : stringValue(serial, 'serial_no');
                                  })
                                  .where((v) => v.trim().isNotEmpty)
                                  .toList(growable: false),
                              enabled: canEdit,
                              emptyText: 'No serials added',
                              countSummaryBuilder: (count) =>
                                  '$count serial(s) added',
                              validator: (values) {
                                final byLabel = <String, int>{
                                  for (final s in serials)
                                    stringValue(
                                          s,
                                          'serial_no',
                                        ).trim().toLowerCase():
                                        intValue(s, 'id') ?? 0,
                                };
                                for (final label in values) {
                                  if (!byLabel.containsKey(
                                    label.toLowerCase(),
                                  )) {
                                    return 'Serial "$label" is not available for this item/batch.';
                                  }
                                }
                                return null;
                              },
                              onChanged: (values) {
                                final byLabel = <String, int>{
                                  for (final s in serials)
                                    stringValue(
                                          s,
                                          'serial_no',
                                        ).trim().toLowerCase():
                                        intValue(s, 'id') ?? 0,
                                };
                                vm.setLineSerialIds(
                                  index,
                                  values
                                      .map((v) => byLabel[v.toLowerCase()]!)
                                      .toList(growable: false),
                                );
                              },
                            ),
                          )
                        : const ErpLineItemTextCell(
                            readOnly: true,
                            enabled: false,
                            initialValue: '-',
                          ),
                    'issue_qty': ErpLineItemTextCell(
                      controller: line.qtyController,
                      enabled: canEdit && !showSerial,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.requiredPositiveNumber('Issue qty'),
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
