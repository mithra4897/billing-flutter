import '../../screen.dart';

class JobworkChargePage extends StatefulWidget {
  const JobworkChargePage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<JobworkChargePage> createState() => _JobworkChargePageState();
}

class _JobworkChargePageState extends State<JobworkChargePage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final JobworkChargeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('JobworkChargeViewModel');
    _viewModel = Get.put(
      JobworkChargeViewModel()..load(selectId: widget.initialId),
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
    return GetBuilder<JobworkChargeViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              _viewModel.resetDraft();
              _openRoute('/jobwork/charges/new');
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New charge',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Jobwork charges',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading charges...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load charges',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Jobwork charges',
      editorTitle: _viewModel.selected == null
          ? 'New charge'
          : _viewModel.selected!.toString(),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<JobworkChargeModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search charges',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No charges found.',
        itemBuilder: (item, selected) {
          final row = item;
          return SettingsListTile(
            title: row.chargeNo.isNotEmpty ? row.chargeNo : 'Draft',
            subtitle: [
              displayDate(row.chargeDate.isNotEmpty ? row.chargeDate : null),
              row.chargeStatus,
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
                _openRoute('/jobwork/charges/$id');
              }
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading charge...')
          : _JobworkChargeEditor(
              vm: _viewModel,
              onSave: () async {
                await _viewModel.save();
                _snack();
              },
              onPost: () async {
                await _viewModel.postChargeDoc();
                _snack();
              },
              onCancelDoc: () async {
                await _viewModel.cancelChargeDoc();
                _snack();
              },
              onDelete: () async {
                await _viewModel.deleteCharge();
                _snack();
                _openRoute('/jobwork/charges');
              },
            ),
    );
  }
}

class _JobworkChargeEditor extends StatelessWidget {
  const _JobworkChargeEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancelDoc,
    required this.onDelete,
  });

  final JobworkChargeViewModel vm;
  final Future<void> Function() onSave;
  final Future<void> Function() onPost;
  final Future<void> Function() onCancelDoc;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final locked = vm.isLocked;
    final editLines = vm.canEditLines;
    final sel = vm.selected;
    final theme = Theme.of(context);

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
              if (sel != null) ...[
                Text(
                  'Status: ${sel.chargeStatus} · Total: ${sel.totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                    labelText: 'Charge no. (optional)',
                    controller: vm.chargeNoController,
                    enabled: !locked && editLines,
                  ),
                  AppFormTextField(
                    labelText: 'Charge date',
                    controller: vm.chargeDateController,
                    enabled: !locked && editLines,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.compose([
                      Validators.required('Charge date'),
                      Validators.date('Charge date'),
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
                  AppFormTextField(
                    labelText: 'Purchase invoice id (optional)',
                    controller: vm.purchaseInvoiceIdController,
                    enabled: !locked && editLines,
                    keyboardType: TextInputType.number,
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
                    onPressed: editLines ? vm.addLine : null,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              ErpLineItemTable(
                title: 'Lines',
                enabled: editLines,
                onAddLine: editLines ? vm.addLine : null,
                onDeleteLine: editLines ? (i) => vm.removeLine(i) : null,
                visibleColumns: const <ErpLineItemTableColumn>{
                  ErpLineItemTableColumn.no,
                  ErpLineItemTableColumn.description,
                  ErpLineItemTableColumn.item,
                  ErpLineItemTableColumn.qty,
                  ErpLineItemTableColumn.rate,
                  ErpLineItemTableColumn.amount,
                  ErpLineItemTableColumn.taxCode,
                  ErpLineItemTableColumn.action,
                },
                columnLabels: const <ErpLineItemTableColumn, String>{
                  ErpLineItemTableColumn.description: 'Service Description',
                  ErpLineItemTableColumn.item: 'Item (optional)',
                },
                customColumns: const <ErpLineItemCustomColumn>[
                  ErpLineItemCustomColumn(
                    id: 'output_item',
                    label: 'Output Item (optional)',
                    width: 180,
                    insertAfter: ErpLineItemTableColumn.item,
                  ),
                  ErpLineItemCustomColumn(
                    id: 'tax_breakdown',
                    label: 'Tax Breakdown',
                    width: 240,
                    insertAfter: ErpLineItemTableColumn.taxCode,
                  ),
                ],
                lines: List<ErpLineItemTableRow>.generate(vm.lineDrafts.length, (
                  index,
                ) {
                  final line = vm.lineDrafts[index];
                  final breakdown = vm.lineTaxBreakdown(line);
                  final outItems = vm.outputItemOptions
                      .where((x) => x.id != null)
                      .map(
                        (x) => AppSearchPickerOption<int>(
                          value: x.id!,
                          label: x.toString(),
                          subtitle: x.itemCode,
                        ),
                      )
                      .toList(growable: false);
                  return ErpLineItemTableRow(
                    rowKey: line,
                    descriptionController: line.serviceDescriptionController,
                    onDescriptionChanged: null,
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
                    itemValidator: (_) => null, // Item is optional
                    qtyController: line.qtyController,
                    onQtyChanged: (_) => vm.update(),
                    qtyValidator: Validators.requiredPositiveNumber('Quantity'),
                    rateController: line.rateController,
                    onRateChanged: (_) => vm.update(),
                    amount: 0,
                    cellWidgets: <ErpLineItemTableColumn, Widget>{
                      ErpLineItemTableColumn.amount: ErpLineItemTextCell(
                        controller: line.amountController,
                        enabled: editLines,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => vm.update(),
                      ),
                      ErpLineItemTableColumn.description: ErpLineItemTextCell(
                        controller: line.serviceDescriptionController,
                        enabled: editLines,
                        validator: Validators.compose([
                          Validators.required('Service description'),
                          Validators.optionalMaxLength(
                            500,
                            'Service description',
                          ),
                        ]),
                      ),
                    },
                    taxCodeId: line.taxCodeId,
                    taxOptions: vm.taxCodes
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    onTaxCodeChanged: editLines
                        ? (v) => vm.setLineTaxCodeId(index, v)
                        : null,
                    remarksController: line.remarksController,
                    deleteEnabled: editLines && vm.lineDrafts.length > 1,
                    customCells: <String, Widget>{
                      'output_item': ErpLineItemCellFrame(
                        child: AppSearchPickerField<int>(
                          labelText: '',
                          hintText: 'Output item',
                          selectedLabel: vm.outputItemOptions
                              .cast<ItemModel?>()
                              .firstWhere(
                                (x) => x?.id == line.outputItemId,
                                orElse: () => null,
                              )
                              ?.toString(),
                          options: outItems,
                          onChanged: editLines
                              ? (v) => vm.setLineOutputItemId(index, v)
                              : (_) {},
                        ),
                      ),
                      'tax_breakdown': ErpLineItemCellFrame(
                        child: Center(
                          child: Text(
                            'Taxable ${breakdown.taxable.toStringAsFixed(2)} · CGST ${breakdown.cgst.toStringAsFixed(2)} · SGST ${breakdown.sgst.toStringAsFixed(2)} · IGST ${breakdown.igst.toStringAsFixed(2)} · Total ${breakdown.total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                  if (vm.canCancelCharge)
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
