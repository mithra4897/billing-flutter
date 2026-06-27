import '../../screen.dart';

class JobworkDispatchPage extends StatefulWidget {
  const JobworkDispatchPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<JobworkDispatchPage> createState() => _JobworkDispatchPageState();
}

class _JobworkDispatchPageState extends State<JobworkDispatchPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final JobworkDispatchViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('JobworkDispatchViewModel');
    _viewModel = Get.put(
      JobworkDispatchViewModel()..load(selectId: widget.initialId),
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
    return GetBuilder<JobworkDispatchViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              _viewModel.resetDraft();
              _openRoute('/jobwork/dispatches/new');
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New dispatch',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Jobwork dispatches',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading dispatches...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load dispatches',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Jobwork dispatches',
      editorTitle: _viewModel.selected == null
          ? 'New dispatch'
          : _viewModel.selected!.toString(),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<JobworkDispatchModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search dispatches',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No dispatches found.',
        itemBuilder: (item, selected) {
          final row = item;
          return SettingsListTile(
            title: row.dispatchNo.isNotEmpty ? row.dispatchNo : 'Draft',
            subtitle: [
              displayDate(
                row.dispatchDate.isNotEmpty ? row.dispatchDate : null,
              ),
              row.dispatchStatus,
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
                _openRoute('/jobwork/dispatches/$id');
              }
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading dispatch...')
          : _JobworkDispatchEditor(
              vm: _viewModel,
              onSave: () async {
                await _viewModel.save();
                _snack();
              },
              onPost: () async {
                await _viewModel.postDispatch();
                _snack();
              },
              onCancelDoc: () async {
                await _viewModel.cancelDispatchDoc();
                _snack();
              },
              onDelete: () async {
                await _viewModel.deleteDispatch();
                _snack();
                _openRoute('/jobwork/dispatches');
              },
            ),
    );
  }
}

class _JobworkDispatchEditor extends StatelessWidget {
  const _JobworkDispatchEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancelDoc,
    required this.onDelete,
  });

  final JobworkDispatchViewModel vm;
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
                    labelText: 'Dispatch no. (optional)',
                    controller: vm.dispatchNoController,
                    enabled: !locked && editLines,
                  ),
                  AppFormTextField(
                    labelText: 'Dispatch date',
                    controller: vm.dispatchDateController,
                    enabled: !locked && editLines,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.compose([
                      Validators.required('Dispatch date'),
                      Validators.date('Dispatch date'),
                    ]),
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
                    labelText: 'DC no.',
                    controller: vm.dcNoController,
                    enabled: !locked && editLines,
                  ),
                  AppFormTextField(
                    labelText: 'DC date',
                    controller: vm.dcDateController,
                    enabled: !locked && editLines,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.optionalDate('DC date'),
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
                  ErpLineItemCustomColumn(
                    id: 'order_material',
                    label: 'Order Material',
                    width: 180,
                    insertAfter: ErpLineItemTableColumn.no,
                  ),
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
                    id: 'qty',
                    label: 'Qty',
                    width: 110,
                    insertAfter: ErpLineItemTableColumn.uom,
                  ),
                  ErpLineItemCustomColumn(
                    id: 'unit_cost',
                    label: 'Unit Cost',
                    width: 110,
                    insertAfter: ErpLineItemTableColumn.uom,
                  ),
                ],
                lines: List<ErpLineItemTableRow>.generate(vm.lineDrafts.length, (
                  index,
                ) {
                  final line = vm.lineDrafts[index];
                  final batchOptions = vm.batchOptions(
                    line.itemId,
                    line.warehouseId ?? vm.warehouseId,
                  );
                  final serialOptions = vm.serialOptions(
                    line.itemId,
                    line.warehouseId ?? vm.warehouseId,
                    line.batchId,
                  );
                  final matItems = <AppDropdownItem<int?>>[
                    const AppDropdownItem<int?>(value: null, label: '-'),
                    ...vm.orderMaterialOptions
                        .where((m) => m.id != null)
                        .map(
                          (m) => AppDropdownItem<int?>(
                            value: m.id,
                            label:
                                'Mat line ${m.lineNo} · planned ${m.plannedQty}',
                          ),
                        ),
                  ];
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
                        ? (v) => vm.setLineItemId(index, v)
                        : null,
                    itemValidator: (_) =>
                        line.itemId == null ? 'Item is required' : null,
                    warehouseId: line.warehouseId ?? vm.warehouseId,
                    warehouseOptions: vm.warehouseOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    onWarehouseChanged: editLines
                        ? (v) => vm.setLineWarehouseId(index, v)
                        : null,
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
                        ? (v) => vm.setLineUomId(index, v)
                        : null,
                    uomValidator: Validators.requiredSelection('UOM'),
                    amount: 0,
                    deleteEnabled: editLines && vm.lineDrafts.length > 1,
                    customCells: <String, Widget>{
                      'order_material': ErpLineItemCellFrame(
                        child: AppDropdownField<int?>.fromMapped(
                          labelText: '',
                          hintText: 'Order Material',
                          fieldPadding: EdgeInsets.zero,
                          mappedItems: matItems,
                          initialValue: line.jobworkOrderMaterialId,
                          onChanged: editLines
                              ? (v) => vm.applyMaterialLink(index, v)
                              : null,
                        ),
                      ),
                      'batch': vm.itemHasBatch(line.itemId)
                          ? ErpLineItemCellFrame(
                              child: AppDropdownField<int>.fromMapped(
                                labelText: '',
                                hintText: 'Batch',
                                fieldPadding: EdgeInsets.zero,
                                mappedItems: batchOptions
                                    .where((x) => x.id != null)
                                    .map(
                                      (x) => AppDropdownItem<int>(
                                        value: x.id!,
                                        label:
                                            (x.batchNo ?? '').trim().isNotEmpty
                                            ? x.batchNo!
                                            : x.toString(),
                                      ),
                                    )
                                    .toList(growable: false),
                                initialValue: line.batchId,
                                onChanged: editLines
                                    ? (v) => vm.setLineBatchId(index, v)
                                    : null,
                              ),
                            )
                          : const ErpLineItemTextCell(
                              readOnly: true,
                              enabled: false,
                              initialValue: '-',
                            ),
                      'serial': vm.itemHasSerial(line.itemId)
                          ? ErpLineItemCellFrame(
                              child: AppDropdownField<int>.fromMapped(
                                labelText: '',
                                hintText: 'Serial',
                                fieldPadding: EdgeInsets.zero,
                                mappedItems: serialOptions
                                    .where((x) => x.id != null)
                                    .map(
                                      (x) => AppDropdownItem<int>(
                                        value: x.id!,
                                        label:
                                            (x.serialNo ?? '').trim().isNotEmpty
                                            ? x.serialNo!
                                            : x.toString(),
                                      ),
                                    )
                                    .toList(growable: false),
                                initialValue: line.serialId,
                                onChanged: editLines
                                    ? (v) => vm.setLineSerialId(index, v)
                                    : null,
                              ),
                            )
                          : const ErpLineItemTextCell(
                              readOnly: true,
                              enabled: false,
                              initialValue: '-',
                            ),
                      'qty': ErpLineItemTextCell(
                        controller: line.qtyController,
                        enabled: editLines,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.requiredPositiveNumber(
                          'Quantity',
                        ),
                      ),
                      'unit_cost': ErpLineItemTextCell(
                        controller: line.unitCostController,
                        enabled: editLines,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
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
                  if (vm.canCancelDispatch)
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
