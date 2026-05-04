import '../../screen.dart';
import '../../view_model/jobwork/jobwork_charge_view_model.dart';
import '../purchase/purchase_support.dart';

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
  late final JobworkChargeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = JobworkChargeViewModel()..load(selectId: widget.initialId);
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
              displayDate(
                row.chargeDate.isNotEmpty ? row.chargeDate : null,
              ),
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
              ...List<Widget>.generate(vm.lineDrafts.length, (index) {
                final line = vm.lineDrafts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
                  child: PurchaseCompactLineCard(
                    index: index,
                    total: vm.lineDrafts.length,
                    removeEnabled: editLines && vm.lineDrafts.length > 1,
                    onRemove: editLines ? () => vm.removeLine(index) : null,
                    child: PurchaseCompactFieldGrid(
                      children: [
                        AppFormTextField(
                          labelText: 'Service description',
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
                        AppSearchPickerField<int>(
                          labelText: 'Item (optional)',
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
                          onChanged: (int? value) {
                            if (editLines) vm.setLineItemId(index, value);
                          },
                        ),
                        AppFormTextField(
                          labelText: 'Qty',
                          controller: line.qtyController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator:
                              Validators.requiredPositiveNumber('Quantity'),
                        ),
                        AppFormTextField(
                          labelText: 'Rate',
                          controller: line.rateController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Amount',
                          controller: line.amountController,
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
