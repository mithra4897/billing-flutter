import '../../screen.dart';
import '../../view_model/jobwork/jobwork_dispatch_view_model.dart';
import '../purchase/purchase_support.dart';

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
  late final JobworkDispatchViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = JobworkDispatchViewModel()..load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
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
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
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
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Financial year',
                    mappedItems: vm.financialYears
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.financialYearId,
                    onChanged: (int? v) {
                      if (!locked) vm.setFinancialYearId(v);
                    },
                    validator: Validators.requiredSelection('Financial year'),
                  ),
                  AppDropdownField<int>.fromMapped(
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
              ...List<Widget>.generate(vm.lineDrafts.length, (index) {
                final line = vm.lineDrafts[index];
                final matItems = <AppDropdownItem<int?>>[
                  const AppDropdownItem<int?>(value: null, label: '—'),
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
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: PurchaseCompactLineCard(
                    index: index,
                    total: vm.lineDrafts.length,
                    removeEnabled: editLines && vm.lineDrafts.length > 1,
                    onRemove: editLines ? () => vm.removeLine(index) : null,
                    child: PurchaseCompactFieldGrid(
                      children: [
                        AppDropdownField<int?>.fromMapped(
                          labelText: 'Order material',
                          mappedItems: matItems,
                          initialValue: line.jobworkOrderMaterialId,
                          onChanged: (int? v) {
                            if (editLines) vm.applyMaterialLink(index, v);
                          },
                        ),
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
                          onChanged: (int? value) {
                            if (editLines) vm.setLineItemId(index, value);
                          },
                        ),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'UOM',
                          mappedItems: vm
                              .uomOptionsForItem(line.itemId)
                              .where((item) => item.id != null)
                              .map(
                                (item) => AppDropdownItem<int>(
                                  value: item.id!,
                                  label: item.toString(),
                                ),
                              )
                              .toList(growable: false),
                          initialValue: line.uomId,
                          onChanged: (int? value) {
                            if (editLines) vm.setLineUomId(index, value);
                          },
                          validator: Validators.requiredSelection('UOM'),
                        ),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Line warehouse',
                          mappedItems: vm.warehouseOptions
                              .where((x) => x.id != null)
                              .map(
                                (x) => AppDropdownItem<int>(
                                  value: x.id!,
                                  label: x.toString(),
                                ),
                              )
                              .toList(growable: false),
                          initialValue: line.warehouseId ?? vm.warehouseId,
                          onChanged: (int? value) {
                            if (editLines) vm.setLineWarehouseId(index, value);
                          },
                        ),
                        AppFormTextField(
                          labelText: 'Qty',
                          controller: line.qtyController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: Validators.requiredPositiveNumber(
                            'Quantity',
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Unit cost',
                          controller: line.unitCostController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Remarks',
                          controller: line.remarksController,
                          enabled: editLines,
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
