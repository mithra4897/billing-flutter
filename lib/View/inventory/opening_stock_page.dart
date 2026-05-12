import '../../screen.dart';
import '../../view_model/inventory/opening_stock_view_model.dart';
import '../purchase/purchase_support.dart';

class OpeningStockPage extends StatefulWidget {
  const OpeningStockPage({
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
  State<OpeningStockPage> createState() => _OpeningStockPageState();
}

class _OpeningStockPageState extends State<OpeningStockPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final OpeningStockViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OpeningStockViewModel(initialItemId: widget.initialItemId)
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
            label: 'New Opening Stock',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Opening Stock',
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
      return const AppLoadingView(message: 'Loading opening stock...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load opening stock',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Opening Stock',
      editorTitle: _viewModel.selected?.toString() ?? 'New Opening Stock',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<OpeningStockModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search opening stock',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No opening stock documents found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: stringValue(row.toJson(), 'opening_no', 'Draft'),
          subtitle: [
            displayDate(nullableStringValue(row.toJson(), 'opening_date')),
            stringValue(row.toJson(), 'opening_status'),
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
      editor: _OpeningStockEditor(
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

class _OpeningStockEditor extends StatelessWidget {
  const _OpeningStockEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
  });

  final OpeningStockViewModel vm;
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
    return Form(
      child: Builder(
        builder: (formContext) => Column(
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
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.companyId,
                  validator: Validators.requiredSelection('Company'),
                  onChanged: (value) {
                    if (!canEdit) {
                      return;
                    }
                    vm.onCompanyChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Branch',
                  mappedItems: vm.branchOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.branchId,
                  validator: Validators.requiredSelection('Branch'),
                  onChanged: (value) {
                    if (!canEdit) {
                      return;
                    }
                    vm.onBranchChanged(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Location',
                  mappedItems: vm.locationOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.locationId,
                  validator: Validators.requiredSelection('Location'),
                  onChanged: (value) {
                    if (!canEdit) {
                      return;
                    }
                    vm.onLocationChanged(value);
                  },
                ),
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
                    if (!canEdit) {
                      return;
                    }
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
                    if (!canEdit) {
                      return;
                    }
                    vm.onSeriesChanged(value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Opening No',
                  controller: vm.openingNoController,
                  hintText: 'Leave blank if series auto-generates',
                  enabled: canEdit,
                  validator: Validators.optionalMaxLength(100, 'Opening No'),
                ),
                AppFormTextField(
                  labelText: 'Opening Date',
                  controller: vm.openingDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: canEdit,
                  validator: Validators.compose([
                    Validators.required('Opening Date'),
                    Validators.date('Opening Date'),
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
                          selectedLabel: vm.itemOptions
                              .cast<ItemModel?>()
                              .firstWhere(
                                (item) => item?.id == line.itemId,
                                orElse: () => null,
                              )
                              ?.toString(),
                          options: vm.itemOptions
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
                            if (!canEdit) {
                              return;
                            }
                            vm.onLineItemChanged(index, value);
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
                          initialValue: line.warehouseId,
                          validator: Validators.requiredSelection('Warehouse'),
                          onChanged: (value) {
                            if (!canEdit) {
                              return;
                            }
                            vm.onLineWarehouseChanged(index, value);
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
                            if (!canEdit) {
                              return;
                            }
                            vm.onLineUomChanged(index, value);
                          },
                        ),
                        if (vm.isBatchManagedItem(line.itemId))
                          AppFormTextField(
                            labelText: 'Batch',
                            controller: line.batchNoController,
                            enabled: canEdit,
                            validator: (value) {
                              if (!vm.isBatchManagedItem(line.itemId)) {
                                return null;
                              }
                              if ((value ?? '').trim().isEmpty) {
                                return 'Batch is required';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (!canEdit) {
                                return;
                              }
                              vm.onLineBatchInputChanged(index, value);
                            },
                          ),
                        if (vm.isSerialManagedItem(line.itemId))
                          AppSerialNumbersField(
                            values: line.serialNumbers,
                            enabled: canEdit,
                            validator: (values) =>
                                vm.validateLineSerialNumbers(index, values),
                            onChanged: (values) =>
                                vm.setLineSerialNumbers(index, values),
                          ),
                        AppFormTextField(
                          labelText: 'Quantity',
                          controller: line.qtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: canEdit,
                          validator: Validators.requiredPositiveNumber(
                            'Quantity',
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
