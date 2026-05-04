import '../../screen.dart';
import '../../view_model/jobwork/jobwork_receipt_view_model.dart';
import '../purchase/purchase_support.dart';

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
  late final JobworkReceiptViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = JobworkReceiptViewModel()..load(selectId: widget.initialId);
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
              displayDate(
                row.receiptDate.isNotEmpty ? row.receiptDate : null,
              ),
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
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Company',
                    mappedItems: vm.companies
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.companyId,
                    onChanged: (int? v) {
                      if (!locked) vm.onCompanyChanged(v);
                    },
                    validator: Validators.requiredSelection('Company'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Branch',
                    mappedItems: vm.branchOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.branchId,
                    onChanged: (int? v) {
                      if (!locked) vm.onBranchChanged(v);
                    },
                    validator: Validators.requiredSelection('Branch'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Location',
                    mappedItems: vm.locationOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.locationId,
                    onChanged: (int? v) {
                      if (!locked) vm.onLocationChanged(v);
                    },
                    validator: Validators.requiredSelection('Location'),
                  ),
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
                final outItems = <AppDropdownItem<int?>>[
                  const AppDropdownItem<int?>(value: null, label: '—'),
                  ...vm.orderOutputOptions
                      .where((o) => o.id != null)
                      .map(
                        (o) => AppDropdownItem<int?>(
                          value: o.id,
                          label: 'Out line ${o.lineNo} · planned ${o.plannedQty}',
                        ),
                      ),
                ];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
                  child: PurchaseCompactLineCard(
                    index: index,
                    total: vm.lineDrafts.length,
                    removeEnabled: editLines && vm.lineDrafts.length > 1,
                    onRemove: editLines ? () => vm.removeLine(index) : null,
                    child: PurchaseCompactFieldGrid(
                      children: [
                        AppDropdownField<int?>.fromMapped(
                          labelText: 'Order output',
                          mappedItems: outItems,
                          initialValue: line.jobworkOrderOutputId,
                          onChanged: (int? v) {
                            if (editLines) vm.applyOutputLink(index, v);
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
                        AppDropdownField<String>.fromMapped(
                          labelText: 'Output type',
                          mappedItems: _lineOutputTypeItems,
                          initialValue: line.outputType,
                          onChanged: (String? v) {
                            if (editLines) {
                              vm.setOutputTypeLine(
                                index,
                                v ?? 'processed_material',
                              );
                            }
                          },
                        ),
                        AppFormTextField(
                          labelText: 'Receipt qty',
                          controller: line.receiptQtyController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: Validators.requiredPositiveNumber(
                            'Receipt qty',
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Accepted qty',
                          controller: line.acceptedQtyController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Rejected qty',
                          controller: line.rejectedQtyController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
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
