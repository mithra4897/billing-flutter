import '../../screen.dart';

const List<AppDropdownItem<String>> _processTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'cutting', label: 'Cutting'),
      AppDropdownItem(value: 'stitching', label: 'Stitching'),
      AppDropdownItem(value: 'polishing', label: 'Polishing'),
      AppDropdownItem(value: 'coating', label: 'Coating'),
      AppDropdownItem(value: 'printing', label: 'Printing'),
      AppDropdownItem(value: 'assembly', label: 'Assembly'),
      AppDropdownItem(value: 'machining', label: 'Machining'),
      AppDropdownItem(value: 'packing', label: 'Packing'),
      AppDropdownItem(value: 'finishing', label: 'Finishing'),
      AppDropdownItem(value: 'other', label: 'Other'),
    ];

const List<AppDropdownItem<String>> _sourceTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'manual', label: 'Manual'),
      AppDropdownItem(value: 'production_order', label: 'Production order'),
      AppDropdownItem(value: 'sales_order', label: 'Sales order'),
      AppDropdownItem(value: 'rework', label: 'Rework'),
      AppDropdownItem(value: 'other', label: 'Other'),
    ];

const List<AppDropdownItem<String>> _materialLineTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'raw_material', label: 'Raw material'),
      AppDropdownItem(value: 'semi_finished', label: 'Semi finished'),
      AppDropdownItem(value: 'packing_material', label: 'Packing material'),
      AppDropdownItem(value: 'consumable', label: 'Consumable'),
    ];

const List<AppDropdownItem<String>> _outputTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'processed_material', label: 'Processed material'),
      AppDropdownItem(value: 'semi_finished', label: 'Semi finished'),
      AppDropdownItem(value: 'finished_goods', label: 'Finished goods'),
      AppDropdownItem(value: 'by_product', label: 'By-product'),
      AppDropdownItem(value: 'scrap', label: 'Scrap'),
    ];

class JobworkOrderPage extends StatefulWidget {
  const JobworkOrderPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<JobworkOrderPage> createState() => _JobworkOrderPageState();
}

class _JobworkOrderPageState extends State<JobworkOrderPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final JobworkOrderViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('JobworkOrderViewModel');
    _viewModel = Get.put(
      JobworkOrderViewModel()..load(selectId: widget.initialId),
      tag: _controllerTag,
      permanent: true,
    );
  }

  @override
  void dispose() {
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
    if (!mounted || msg == null || msg.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<JobworkOrderViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              _viewModel.resetDraft();
              _openRoute('/jobwork/orders/new');
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New Jobwork Order',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Jobwork Orders',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading jobwork orders...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load jobwork orders',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Jobwork Orders',
      editorTitle: _viewModel.selected == null
          ? 'New Jobwork Order'
          : _viewModel.selected!.toString(),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<JobworkOrderModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search jobwork orders',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No jobwork orders found.',
        itemBuilder: (item, selected) {
          final row = item;
          return SettingsListTile(
            title: row.jobworkNo.isNotEmpty ? row.jobworkNo : 'Draft',
            subtitle: [
              displayDate(row.jobworkDate.isNotEmpty ? row.jobworkDate : null),
              row.jobworkStatus,
            ].where((v) => v.trim().isNotEmpty).join(' · '),
            detail: row.supplierLabel,
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await _viewModel.select(item);
              if (!mounted) {
                return;
              }
              final id = row.id;
              if (id != null) {
                _openRoute('/jobwork/orders/$id');
              }
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading jobwork order...')
          : _JobworkOrderEditor(
              vm: _viewModel,
              materialLineTypes: _materialLineTypeItems,
              outputTypes: _outputTypeItems,
              onSave: () async {
                await _viewModel.save();
                _snack();
              },
              onRelease: () async {
                await _viewModel.release();
                _snack();
              },
              onCloseOrder: () async {
                await _viewModel.closeOrder();
                _snack();
              },
              onCancelOrder: () async {
                await _viewModel.cancelOrder();
                _snack();
              },
              onDelete: () async {
                await _viewModel.deleteOrder();
                _snack();
                _openRoute('/jobwork/orders');
              },
            ),
    );
  }
}

class _JobworkOrderEditor extends StatelessWidget {
  const _JobworkOrderEditor({
    required this.vm,
    required this.materialLineTypes,
    required this.outputTypes,
    required this.onSave,
    required this.onRelease,
    required this.onCloseOrder,
    required this.onCancelOrder,
    required this.onDelete,
  });

  final JobworkOrderViewModel vm;
  final List<AppDropdownItem<String>> materialLineTypes;
  final List<AppDropdownItem<String>> outputTypes;
  final Future<void> Function() onSave;
  final Future<void> Function() onRelease;
  final Future<void> Function() onCloseOrder;
  final Future<void> Function() onCancelOrder;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final locked = vm.isLocked;
    final editLines = vm.canEditLines;

    return Form(
      child: Builder(
        builder: (formContext) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vm.formError != null) ...[
                AppErrorStateView.inline(message: vm.formError!),
                const SizedBox(height: AppUiConstants.spacingSm),
              ],
              SettingsFormWrap(
                children: [
                  DocumentSeriesSelector<int>(
                    labelText: 'Document series',
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
                    onChanged: (int? v) {
                      if (!locked) vm.setDocumentSeriesId(v);
                    },
                  ),
                  GeneratedDocumentNumberField(
                    labelText: 'Jobwork no. (optional)',
                    controller: vm.jobworkNoController,
                    documentSeries: vm.seriesOptions,
                    documentSeriesId: vm.documentSeriesId,
                    enabled: !locked && editLines,
                  ),
                  AppFormTextField(
                    labelText: 'Jobwork date',
                    controller: vm.jobworkDateController,
                    enabled: !locked && editLines,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.compose([
                      Validators.required('Jobwork date'),
                      Validators.date('Jobwork date'),
                    ]),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Supplier',
                    mappedItems: vm.supplierOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.supplierPartyId,
                    onChanged: (int? v) {
                      if (!locked) vm.setSupplierPartyId(v);
                    },
                    validator: Validators.requiredSelection('Supplier'),
                  ),
                  AppFormTextField(
                    labelText: 'Process name',
                    controller: vm.processNameController,
                    enabled: !locked && editLines,
                    validator: Validators.compose([
                      Validators.required('Process name'),
                      Validators.optionalMaxLength(255, 'Process name'),
                    ]),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Process type',
                    mappedItems: _processTypeItems,
                    initialValue: vm.processType,
                    onChanged: (String? v) {
                      if (!locked && editLines) {
                        vm.setProcessType(v ?? 'other');
                      }
                    },
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Source type',
                    mappedItems: _sourceTypeItems,
                    initialValue: vm.sourceType,
                    onChanged: (String? v) {
                      if (!locked && editLines) {
                        vm.setSourceType(v ?? 'manual');
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Source document type',
                    controller: vm.sourceDocumentTypeController,
                    enabled: !locked && editLines,
                  ),
                  AppFormTextField(
                    labelText: 'Source document id',
                    controller: vm.sourceDocumentIdController,
                    enabled: !locked && editLines,
                    keyboardType: TextInputType.number,
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Issue warehouse',
                    mappedItems: vm.warehouseOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.issueWarehouseId,
                    onChanged: (int? v) {
                      if (!locked) vm.setIssueWarehouseId(v);
                    },
                    validator: Validators.requiredSelection('Issue warehouse'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Receipt warehouse',
                    mappedItems: vm.warehouseOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.receiptWarehouseId,
                    onChanged: (int? v) {
                      if (!locked) vm.setReceiptWarehouseId(v);
                    },
                    validator: Validators.requiredSelection(
                      'Receipt warehouse',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Expected return date',
                    controller: vm.expectedReturnDateController,
                    enabled: !locked && editLines,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.optionalDate('Expected return date'),
                  ),
                  AppFormTextField(
                    labelText: 'Notes',
                    controller: vm.notesController,
                    enabled: !locked,
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              ErpLineItemTable(
                title: 'Materials sent',
                enabled: editLines,
                onAddLine: editLines ? vm.addMaterialLine : null,
                onDeleteLine: editLines
                    ? (i) => vm.removeMaterialLine(i)
                    : null,
                visibleColumns: const <ErpLineItemTableColumn>{
                  ErpLineItemTableColumn.no,
                  ErpLineItemTableColumn.item,
                  ErpLineItemTableColumn.uom,
                  ErpLineItemTableColumn.action,
                },
                customColumns: const <ErpLineItemCustomColumn>[
                  ErpLineItemCustomColumn(
                    id: 'line_type',
                    label: 'Line Type',
                    width: 160,
                    insertAfter: ErpLineItemTableColumn.uom,
                  ),
                  ErpLineItemCustomColumn(
                    id: 'planned_qty',
                    label: 'Planned Qty',
                    width: 120,
                    insertAfter: ErpLineItemTableColumn.uom,
                  ),
                ],
                lines: List<ErpLineItemTableRow>.generate(
                  vm.materialDrafts.length,
                  (index) {
                    final line = vm.materialDrafts[index];
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
                      onItemChanged: editLines
                          ? (v) => vm.setMaterialItemId(index, v)
                          : null,
                      itemValidator: (_) =>
                          line.itemId == null ? 'Item is required' : null,
                      uomId: line.uomId,
                      uomOptions: vm
                          .uomOptionsForItem(line.itemId)
                          .where((x) => x.id != null)
                          .map(
                            (x) => AppDropdownItem<int>(
                              value: x.id!,
                              label: x.toString(),
                            ),
                          )
                          .toList(growable: false),
                      onUomChanged: editLines
                          ? (v) => vm.setMaterialUomId(index, v)
                          : null,
                      uomValidator: Validators.requiredSelection('UOM'),
                      amount: 0,
                      deleteEnabled: editLines && vm.materialDrafts.length > 1,
                      customCells: <String, Widget>{
                        'line_type': ErpLineItemCellFrame(
                          child: AppDropdownField<String>.fromMapped(
                            labelText: '',
                            hintText: 'Line type',
                            fieldPadding: EdgeInsets.zero,
                            mappedItems: materialLineTypes,
                            initialValue: line.lineType,
                            onChanged: editLines
                                ? (v) => vm.setMaterialLineType(
                                    index,
                                    v ?? 'raw_material',
                                  )
                                : null,
                          ),
                        ),
                        'planned_qty': ErpLineItemTextCell(
                          controller: line.plannedQtyController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: Validators.requiredPositiveNumber(
                            'Planned qty',
                          ),
                        ),
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              ErpLineItemTable(
                title: 'Outputs expected',
                enabled: editLines,
                onAddLine: editLines ? vm.addOutputLine : null,
                onDeleteLine: editLines ? (i) => vm.removeOutputLine(i) : null,
                visibleColumns: const <ErpLineItemTableColumn>{
                  ErpLineItemTableColumn.no,
                  ErpLineItemTableColumn.item,
                  ErpLineItemTableColumn.uom,
                  ErpLineItemTableColumn.action,
                },
                customColumns: const <ErpLineItemCustomColumn>[
                  ErpLineItemCustomColumn(
                    id: 'output_type',
                    label: 'Output Type',
                    width: 160,
                    insertAfter: ErpLineItemTableColumn.uom,
                  ),
                  ErpLineItemCustomColumn(
                    id: 'planned_qty',
                    label: 'Planned Qty',
                    width: 120,
                    insertAfter: ErpLineItemTableColumn.uom,
                  ),
                ],
                lines: List<ErpLineItemTableRow>.generate(
                  vm.outputDrafts.length,
                  (index) {
                    final line = vm.outputDrafts[index];
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
                      onItemChanged: editLines
                          ? (v) => vm.setOutputItemId(index, v)
                          : null,
                      itemValidator: (_) =>
                          line.itemId == null ? 'Item is required' : null,
                      uomId: line.uomId,
                      uomOptions: vm
                          .uomOptionsForItem(line.itemId)
                          .where((x) => x.id != null)
                          .map(
                            (x) => AppDropdownItem<int>(
                              value: x.id!,
                              label: x.toString(),
                            ),
                          )
                          .toList(growable: false),
                      onUomChanged: editLines
                          ? (v) => vm.setOutputUomId(index, v)
                          : null,
                      uomValidator: Validators.requiredSelection('UOM'),
                      amount: 0,
                      deleteEnabled: editLines && vm.outputDrafts.length > 1,
                      customCells: <String, Widget>{
                        'output_type': ErpLineItemCellFrame(
                          child: AppDropdownField<String>.fromMapped(
                            labelText: '',
                            hintText: 'Output type',
                            fieldPadding: EdgeInsets.zero,
                            mappedItems: outputTypes,
                            initialValue: line.outputType,
                            onChanged: editLines
                                ? (v) => vm.setOutputType(
                                    index,
                                    v ?? 'processed_material',
                                  )
                                : null,
                          ),
                        ),
                        'planned_qty': ErpLineItemTextCell(
                          controller: line.plannedQtyController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: Validators.requiredPositiveNumber(
                            'Planned qty',
                          ),
                        ),
                      },
                    );
                  },
                ),
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
                    onPressed: locked
                        ? null
                        : () async {
                            if (!Form.of(formContext).validate()) {
                              return;
                            }
                            await onSave();
                          },
                  ),
                  if (vm.canRelease)
                    AppActionButton(
                      icon: Icons.play_arrow_outlined,
                      label: 'Release',
                      filled: false,
                      onPressed: onRelease,
                    ),
                  if (vm.canClose)
                    AppActionButton(
                      icon: Icons.task_alt_outlined,
                      label: 'Close',
                      filled: false,
                      onPressed: onCloseOrder,
                    ),
                  if (vm.canCancel)
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel order',
                      filled: false,
                      onPressed: onCancelOrder,
                    ),
                  if (vm.canDelete)
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
      ),
    );
  }
}
