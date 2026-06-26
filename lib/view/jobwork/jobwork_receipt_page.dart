import '../../screen.dart';

const List<AppDropdownItem<String>> _receiptModeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'processed_receipt', label: 'Processed receipt'),
      AppDropdownItem(value: 'material_return', label: 'Material return'),
      AppDropdownItem(value: 'scrap_receipt', label: 'Scrap receipt'),
    ];

const List<AppDropdownItem<String>> _lineOutputTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'processed_material', label: 'Processed material'),
      AppDropdownItem(value: 'semi_finished', label: 'Semi finished'),
      AppDropdownItem(value: 'finished_goods', label: 'Finished goods'),
      AppDropdownItem(value: 'by_product', label: 'By-product'),
      AppDropdownItem(value: 'scrap', label: 'Scrap'),
    ];

class JobworkReceiptPage extends StatefulWidget {
  const JobworkReceiptPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<JobworkReceiptPage> createState() => _JobworkReceiptPageState();
}

class _JobworkReceiptPageState extends State<JobworkReceiptPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final JobworkReceiptViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('JobworkReceiptViewModel');
    _viewModel = Get.put(
      JobworkReceiptViewModel()..load(selectId: widget.initialId),
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
    return GetBuilder<JobworkReceiptViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              _viewModel.resetDraft();
              _openRoute('/jobwork/receipts/new');
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New receipt',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Jobwork receipts',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading receipts...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load receipts',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Jobwork receipts',
      editorTitle: _viewModel.selected == null
          ? 'New receipt'
          : _viewModel.selected!.toString(),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<JobworkReceiptModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search receipts',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No receipts found.',
        itemBuilder: (item, selected) {
          final row = item;
          return SettingsListTile(
            title: row.receiptNo.isNotEmpty ? row.receiptNo : 'Draft',
            subtitle: [
              displayDate(row.receiptDate.isNotEmpty ? row.receiptDate : null),
              row.receiptStatus,
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
                _openRoute('/jobwork/receipts/$id');
              }
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading receipt...')
          : _JobworkReceiptEditor(
              vm: _viewModel,
              onSave: () async {
                await _viewModel.save();
                _snack();
              },
              onPost: () async {
                await _viewModel.postReceiptDoc();
                _snack();
              },
              onCancelDoc: () async {
                await _viewModel.cancelReceiptDoc();
                _snack();
              },
              onDelete: () async {
                await _viewModel.deleteReceipt();
                _snack();
                _openRoute('/jobwork/receipts');
              },
            ),
    );
  }
}

class _JobworkReceiptEditor extends StatelessWidget {
  const _JobworkReceiptEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancelDoc,
    required this.onDelete,
  });

  final JobworkReceiptViewModel vm;
  final Future<void> Function() onSave;
  final Future<void> Function() onPost;
  final Future<void> Function() onCancelDoc;
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
                  AppFormTextField(
                    labelText: 'Receipt no. (optional)',
                    controller: vm.receiptNoController,
                    enabled: !locked && editLines,
                  ),
                  AppFormTextField(
                    labelText: 'Receipt date',
                    controller: vm.receiptDateController,
                    enabled: !locked && editLines,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.compose([
                      Validators.required('Receipt date'),
                      Validators.date('Receipt date'),
                    ]),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Receipt mode',
                    mappedItems: _receiptModeItems,
                    initialValue: vm.receiptMode,
                    onChanged: (String? v) {
                      if (!locked && editLines) {
                        vm.setReceiptMode(v ?? 'processed_receipt');
                      }
                    },
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Jobwork order',
                    mappedItems: vm.jobworkOrderOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.jobworkNo.isNotEmpty
                                ? x.jobworkNo
                                : 'Order #${x.id}',
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.jobworkOrderId,
                    onChanged: (int? v) {
                      if (!locked) vm.setJobworkOrderId(v);
                    },
                    validator: Validators.requiredSelection('Jobwork order'),
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
                  AppDropdownField<int>.fromMapped(
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
                    onChanged: (int? v) {
                      if (!locked) vm.setWarehouseId(v);
                    },
                    validator: Validators.requiredSelection('Warehouse'),
                  ),
                  AppFormTextField(
                    labelText: 'Supplier DC no.',
                    controller: vm.supplierDcNoController,
                    enabled: !locked && editLines,
                  ),
                  AppFormTextField(
                    labelText: 'Supplier DC date',
                    controller: vm.supplierDcDateController,
                    enabled: !locked && editLines,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.optionalDate('Supplier DC date'),
                  ),
                  AppFormTextField(
                    labelText: 'Vehicle no.',
                    controller: vm.vehicleNoController,
                    enabled: !locked && editLines,
                  ),
                  AppSearchPickerField<int>(
                    labelText: 'Transporter',
                    selectedLabel: vm.parties
                        .cast<PartyModel?>()
                        .firstWhere(
                          (p) => p?.id == vm.transporterPartyId,
                          orElse: () => null,
                        )
                        ?.toString(),
                    options: vm.parties
                        .where((p) => p.id != null)
                        .map(
                          (p) => AppSearchPickerOption<int>(
                            value: p.id!,
                            label: p.toString(),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (int? v) {
                      if (!locked) vm.setTransporterPartyId(v);
                    },
                  ),
                  AppFormTextField(
                    labelText: 'LR no.',
                    controller: vm.lrNoController,
                    enabled: !locked && editLines,
                  ),
                  AppFormTextField(
                    labelText: 'LR date',
                    controller: vm.lrDateController,
                    enabled: !locked && editLines,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.optionalDate('LR date'),
                  ),
                  AppFormTextField(
                    labelText: 'Remarks',
                    controller: vm.remarksController,
                    enabled: !locked,
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              ErpLineItemTable(
                title: 'Lines',
                enabled: editLines,
                onAddLine: editLines ? vm.addLine : null,
                onDeleteLine: editLines ? (i) => vm.removeLine(i) : null,
                visibleColumns: const <ErpLineItemTableColumn>{
                  ErpLineItemTableColumn.no,
                  ErpLineItemTableColumn.item,
                  ErpLineItemTableColumn.warehouse,
                  ErpLineItemTableColumn.uom,
                  ErpLineItemTableColumn.action,
                },
                customColumns: const <ErpLineItemCustomColumn>[
                  ErpLineItemCustomColumn(id: 'order_output', label: 'Order Output', width: 180, insertAfter: ErpLineItemTableColumn.no),
                  ErpLineItemCustomColumn(id: 'batch', label: 'Batch', width: 140, insertAfter: ErpLineItemTableColumn.uom),
                  ErpLineItemCustomColumn(id: 'serial', label: 'Serial', width: 140, insertAfter: ErpLineItemTableColumn.uom),
                  ErpLineItemCustomColumn(id: 'output_type', label: 'Output Type', width: 140, insertAfter: ErpLineItemTableColumn.uom),
                  ErpLineItemCustomColumn(id: 'receipt_qty', label: 'Receipt Qty', width: 110, insertAfter: ErpLineItemTableColumn.uom),
                  ErpLineItemCustomColumn(id: 'accepted_qty', label: 'Accepted Qty', width: 110, insertAfter: ErpLineItemTableColumn.uom),
                  ErpLineItemCustomColumn(id: 'rejected_qty', label: 'Rejected Qty', width: 110, insertAfter: ErpLineItemTableColumn.uom),
                  ErpLineItemCustomColumn(id: 'unit_cost', label: 'Unit Cost', width: 110, insertAfter: ErpLineItemTableColumn.uom),
                  ErpLineItemCustomColumn(id: 'remarks', label: 'Remarks', width: 160, insertAfter: ErpLineItemTableColumn.uom),
                ],
                lines: List<ErpLineItemTableRow>.generate(vm.lineDrafts.length, (index) {
                  final line = vm.lineDrafts[index];
                  final batchOptions = vm.batchOptions(line.itemId, line.warehouseId ?? vm.warehouseId);
                  final serialOptions = vm.serialOptions(line.itemId, line.warehouseId ?? vm.warehouseId, line.batchId);
                  final outItems = <AppDropdownItem<int?>>[
                    const AppDropdownItem<int?>(value: null, label: '-'),
                    ...vm.orderOutputOptions.where((o) => o.id != null).map((o) => AppDropdownItem<int?>(value: o.id, label: 'Out line ${o.lineNo} · planned ${o.plannedQty}')),
                  ];
                  return ErpLineItemTableRow(
                    rowKey: line,
                    itemId: line.itemId,
                    itemSelection: vm.items.where((x) => x.id == line.itemId).map((x) => ErpLinkFieldOption<int>(value: x.id!, label: x.toString(), subtitle: x.itemCode)).firstOrNull,
                    itemOptions: vm.items.where((x) => x.id != null).map((x) => ErpLinkFieldOption<int>(value: x.id!, label: x.toString(), subtitle: x.itemCode)).toList(growable: false),
                    onItemChanged: editLines ? (v) => vm.setLineItemId(index, v) : null,
                    itemValidator: (_) => line.itemId == null ? 'Item is required' : null,
                    warehouseId: line.warehouseId ?? vm.warehouseId,
                    warehouseOptions: vm.warehouseOptions.where((x) => x.id != null).map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString())).toList(growable: false),
                    onWarehouseChanged: editLines ? (v) => vm.setLineWarehouseId(index, v) : null,
                    uomId: line.uomId,
                    uomOptions: vm.uomOptionsForItem(line.itemId).where((x) => x.id != null).map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString())).toList(growable: false),
                    onUomChanged: editLines ? (v) => vm.setLineUomId(index, v) : null,
                    uomValidator: Validators.requiredSelection('UOM'),
                    amount: 0,
                    deleteEnabled: editLines && vm.lineDrafts.length > 1,
                    customCells: <String, Widget>{
                      'order_output': ErpLineItemCellFrame(
                        child: AppDropdownField<int?>.fromMapped(
                          labelText: '', hintText: 'Order Output', fieldPadding: EdgeInsets.zero,
                          mappedItems: outItems,
                          initialValue: line.jobworkOrderOutputId,
                          onChanged: editLines ? (v) => vm.applyOutputLink(index, v) : null,
                        ),
                      ),
                      'batch': vm.itemHasBatch(line.itemId)
                          ? ErpLineItemCellFrame(
                              child: AppDropdownField<int>.fromMapped(
                                labelText: '', hintText: 'Batch', fieldPadding: EdgeInsets.zero,
                                mappedItems: batchOptions.where((x) => x.id != null).map((x) => AppDropdownItem<int>(value: x.id!, label: (x.batchNo ?? '').trim().isNotEmpty ? x.batchNo! : x.toString())).toList(growable: false),
                                initialValue: line.batchId,
                                onChanged: editLines ? (v) => vm.setLineBatchId(index, v) : null,
                              ),
                            )
                          : const ErpLineItemTextCell(readOnly: true, enabled: false, initialValue: '-'),
                      'serial': vm.itemHasSerial(line.itemId)
                          ? ErpLineItemCellFrame(
                              child: AppDropdownField<int>.fromMapped(
                                labelText: '', hintText: 'Serial', fieldPadding: EdgeInsets.zero,
                                mappedItems: serialOptions.where((x) => x.id != null).map((x) => AppDropdownItem<int>(value: x.id!, label: (x.serialNo ?? '').trim().isNotEmpty ? x.serialNo! : x.toString())).toList(growable: false),
                                initialValue: line.serialId,
                                onChanged: editLines ? (v) => vm.setLineSerialId(index, v) : null,
                              ),
                            )
                          : const ErpLineItemTextCell(readOnly: true, enabled: false, initialValue: '-'),
                      'output_type': ErpLineItemCellFrame(
                        child: AppDropdownField<String>.fromMapped(
                          labelText: '', hintText: 'Output Type', fieldPadding: EdgeInsets.zero,
                          mappedItems: _lineOutputTypeItems,
                          initialValue: line.outputType,
                          onChanged: editLines ? (v) => vm.setOutputTypeLine(index, v ?? 'processed_material') : null,
                        ),
                      ),
                      'receipt_qty': ErpLineItemTextCell(
                        controller: line.receiptQtyController,
                        enabled: editLines,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: Validators.requiredPositiveNumber('Receipt qty'),
                      ),
                      'accepted_qty': ErpLineItemTextCell(
                        controller: line.acceptedQtyController,
                        enabled: editLines,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      'rejected_qty': ErpLineItemTextCell(
                        controller: line.rejectedQtyController,
                        enabled: editLines,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      'unit_cost': ErpLineItemTextCell(
                        controller: line.unitCostController,
                        enabled: editLines,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      'remarks': ErpLineItemTextCell(
                        controller: line.remarksController,
                        enabled: editLines,
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
                    onPressed: locked
                        ? null
                        : () async {
                            if (!Form.of(formContext).validate()) {
                              return;
                            }
                            await onSave();
                          },
                  ),
                  if (vm.canPost)
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Post',
                      filled: false,
                      onPressed: onPost,
                    ),
                  if (vm.canCancelReceipt)
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel doc',
                      filled: false,
                      onPressed: onCancelDoc,
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
