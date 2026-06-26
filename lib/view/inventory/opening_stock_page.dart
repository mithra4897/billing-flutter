import '../../controller/inventory/opening_stock_page_controller.dart';
import '../../screen.dart';

class OpeningStockPage extends StatefulWidget {
  const OpeningStockPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialItemId,
    this.fixedItemId,
    this.fixedItemLabel,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final int? initialItemId;
  final int? fixedItemId;
  final String? fixedItemLabel;

  @override
  State<OpeningStockPage> createState() => _OpeningStockPageState();
}

class _OpeningStockPageState extends State<OpeningStockPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final String _pageControllerTag;
  late final OpeningStockViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final scope = <String, Object?>{
      'fixedItemId': widget.fixedItemId,
      'initialId': widget.initialId,
      'initialItemId': widget.initialItemId,
      'embedded': widget.embedded,
      'editorOnly': widget.editorOnly,
      'identity': identityHashCode(widget),
    };
    _controllerTag = persistentControllerTag(
      'OpeningStockViewModel',
      scope: scope,
    );
    _pageControllerTag = persistentControllerTag(
      'OpeningStockPageController',
      scope: scope,
    );
    Get.put(OpeningStockPageController(), tag: _pageControllerTag);
    _viewModel = Get.put(
      OpeningStockViewModel(
        initialItemId: widget.fixedItemId ?? widget.initialItemId,
        filterItemId: widget.fixedItemId,
      )..load(selectId: widget.initialId),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<OpeningStockViewModel>(tag: _controllerTag)) {
      Get.delete<OpeningStockViewModel>(tag: _controllerTag, force: true);
    }
    if (Get.isRegistered<OpeningStockPageController>(tag: _pageControllerTag)) {
      Get.delete<OpeningStockPageController>(
        tag: _pageControllerTag,
        force: true,
      );
    }
    _workspaceController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OpeningStockViewModel>(
      tag: _controllerTag,
      builder: (_) {
        return GetBuilder<OpeningStockPageController>(
          tag: _pageControllerTag,
          builder: (_) {
            final content = _buildContent(context);
            final actions = <Widget>[
              AdaptiveShellActionButton(
                onPressed: _viewModel.loading
                    ? null
                    : () {
                        if (widget.fixedItemId != null) {
                          _startNew();
                          return;
                        }
                        _viewModel.resetDraft();
                        if (!Responsive.isDesktop(context)) {
                          _workspaceController.openEditor();
                        }
                      },
                icon: Icons.add_outlined,
                label: 'New Opening Stock',
              ),
            ];

            if (widget.fixedItemId != null) {
              return content;
            }

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

  void _startNew() {
    _pageController.setShowDraftTile(true);
    _viewModel.resetDraft();
  }

  OpeningStockPageController get _pageController =>
      Get.find<OpeningStockPageController>(tag: _pageControllerTag);

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

    if (widget.fixedItemId == null) {
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
          fixedItemId: widget.fixedItemId,
          fixedItemLabel: widget.fixedItemLabel,
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

    return _buildOpeningStockCardsContent(
      context,
      fixedItemMode: widget.fixedItemId != null,
    );
  }

  Widget _buildOpeningStockCardsContent(
    BuildContext context, {
    required bool fixedItemMode,
  }) {
    if (fixedItemMode &&
        _viewModel.itemOptions
            .where((item) => item.id == widget.fixedItemId)
            .isEmpty) {
      return const SettingsEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Item Not Found',
        message: 'The selected item is not available for opening stock.',
      );
    }

    final rows = _viewModel.filteredRows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!fixedItemMode) ...[
          AppSectionCard(
            padding: const EdgeInsets.all(AppUiConstants.spacingMd),
            child: AppFormTextField(
              labelText: 'Search opening stock',
              controller: _viewModel.searchController,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
        ],
        if (fixedItemMode) ...[
          Align(
            alignment: Alignment.centerRight,
            child: AppActionButton(
              icon: Icons.add_outlined,
              label: 'New Opening Stock',
              onPressed: _startNew,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
        ],
        if (rows.isEmpty && !_pageController.showDraftTile)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppUiConstants.spacingMd),
            child: Text('No opening stock documents found.'),
          ),
        if (_pageController.showDraftTile && _viewModel.selected == null) ...[
          SettingsExpandableTile(
            key: const ValueKey('opening-draft'),
            title: 'New Opening Stock',
            subtitle: fixedItemMode
                ? 'Add opening stock for this item.'
                : 'Create a new opening stock document.',
            expanded: true,
            highlighted: true,
            leadingIcon: Icons.add_outlined,
            onToggle: () {
              _pageController.setShowDraftTile(false);
              _viewModel.resetDraft();
            },
            child: _OpeningStockEditor(
              vm: _viewModel,
              fixedItemId: widget.fixedItemId,
              fixedItemLabel: widget.fixedItemLabel,
              onSave: (formContext) async {
                if (!Form.of(formContext).validate()) {
                  return;
                }
                await _viewModel.save();
                if (mounted) {
                  _pageController.setShowDraftTile(false);
                }
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
                if (mounted) {
                  _pageController.setShowDraftTile(false);
                }
                _showActionSnackBar();
              },
            ),
          ),
          if (rows.isNotEmpty) const SizedBox(height: AppUiConstants.spacingSm),
        ],
        ...rows.map((row) {
          final expanded = row == _viewModel.selected;
          final data = row.toJson();
          return Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: SettingsExpandableTile(
              key: ValueKey(
                'opening-${intValue(data, 'id') ?? 'draft'}-$expanded',
              ),
              title: stringValue(data, 'opening_no', 'Draft'),
              subtitle: [
                displayDate(nullableStringValue(data, 'opening_date')),
                stringValue(data, 'opening_status'),
                stringValue(data, 'remarks'),
              ].where((value) => value.trim().isNotEmpty).join(' · '),
              expanded: expanded,
              highlighted: expanded,
              onToggle: () async {
                if (expanded) {
                  _pageController.setShowDraftTile(false);
                  _viewModel.resetDraft();
                  return;
                }
                _pageController.setShowDraftTile(false);
                await _viewModel.select(row);
              },
              child: _OpeningStockEditor(
                vm: _viewModel,
                fixedItemId: widget.fixedItemId,
                fixedItemLabel: widget.fixedItemLabel,
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
            ),
          );
        }),
      ],
    );
  }
}

class _OpeningStockEditor extends StatelessWidget {
  const _OpeningStockEditor({
    required this.vm,
    this.fixedItemId,
    this.fixedItemLabel,
    required this.onSave,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
  });

  final OpeningStockViewModel vm;
  final int? fixedItemId;
  final String? fixedItemLabel;
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
    final contextDisplay = buildWorkingContextDisplay(
      companies: vm.companies,
      branches: vm.branches,
      locations: vm.locations,
      financialYears: vm.financialYears,
      companyId: vm.companyId,
      branchId: vm.branchId,
      locationId: vm.locationId,
      financialYearId: vm.financialYearId,
    );
    final contextLabel = contextDisplay.fullSummary.trim().isEmpty
        ? 'No working context selected'
        : contextDisplay.fullSummary;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contextDisplay.primarySummary.trim().isEmpty
                        ? 'No working context selected'
                        : contextDisplay.primarySummary,
                  ),
                  if (contextDisplay.financialYearSummary != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      contextDisplay.financialYearSummary!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
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
            if (vm.warehouseOptions.isEmpty) ...[
              AppErrorStateView.inline(
                message:
                    'No warehouse found for the selected working context: $contextLabel.',
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
            ],
            ErpLineItemTable(
              title: 'Line Items',
              enabled: canEdit,
              onAddLine: canEdit ? vm.addLine : null,
              onDeleteLine: canEdit ? (i) => vm.removeLine(i) : null,
              visibleColumns: const <ErpLineItemTableColumn>{
                ErpLineItemTableColumn.no,
                ErpLineItemTableColumn.item,
                ErpLineItemTableColumn.warehouse,
                ErpLineItemTableColumn.uom,
                ErpLineItemTableColumn.action,
              },
              customColumns: const <ErpLineItemCustomColumn>[
                ErpLineItemCustomColumn(
                  id: 'batch',
                  label: 'Batch',
                  width: 200,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'serial',
                  label: 'Serials',
                  width: 240,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
                ErpLineItemCustomColumn(
                  id: 'qty',
                  label: 'Quantity',
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
                ErpLineItemCustomColumn(
                  id: 'remarks',
                  label: 'Remarks',
                  width: 200,
                  insertAfter: ErpLineItemTableColumn.uom,
                ),
              ],
              lines: List<ErpLineItemTableRow>.generate(vm.lines.length, (index) {
                final line = vm.lines[index];
                final effectiveItemId = fixedItemId ?? line.itemId;
                return ErpLineItemTableRow(
                  rowKey: line,
                  itemId: effectiveItemId,
                  itemSelection: fixedItemId != null
                      ? vm.itemOptions.where((x) => x.id == fixedItemId).map((x) => ErpLinkFieldOption<int>(value: x.id!, label: x.toString(), subtitle: x.itemCode)).firstOrNull
                      : vm.itemOptions.where((x) => x.id == line.itemId).map((x) => ErpLinkFieldOption<int>(value: x.id!, label: x.toString(), subtitle: x.itemCode)).firstOrNull,
                  itemOptions: fixedItemId != null
                      ? vm.itemOptions.where((x) => x.id == fixedItemId).map((x) => ErpLinkFieldOption<int>(value: x.id!, label: fixedItemLabel ?? x.toString(), subtitle: x.itemCode)).toList(growable: false)
                      : vm.itemOptions.where((x) => x.id != null).map((x) => ErpLinkFieldOption<int>(value: x.id!, label: x.toString(), subtitle: x.itemCode)).toList(growable: false),
                  onItemChanged: (canEdit && fixedItemId == null) ? (v) => vm.onLineItemChanged(index, v) : null,
                  itemValidator: (_) => effectiveItemId == null ? 'Item is required' : null,
                  warehouseId: line.warehouseId,
                  warehouseOptions: vm.warehouseOptions
                      .where((x) => x.id != null)
                      .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                      .toList(growable: false),
                  onWarehouseChanged: canEdit ? (v) => vm.onLineWarehouseChanged(index, v) : null,
                  uomId: line.uomId,
                  uomOptions: vm.uomOptionsForItem(effectiveItemId)
                      .where((u) => u.id != null)
                      .map((u) => AppDropdownItem<int>(value: u.id!, label: u.toString()))
                      .toList(growable: false),
                  onUomChanged: canEdit ? (v) => vm.onLineUomChanged(index, v) : null,
                  uomValidator: Validators.requiredSelection('UOM'),
                  amount: 0,
                  deleteEnabled: canEdit && vm.lines.length > 1,
                  customCells: <String, Widget>{
                    'batch': vm.isBatchManagedItem(effectiveItemId)
                        ? ErpLineItemCellFrame(
                            height: null,
                            child: ErpLinkField<int>(
                              labelText: 'Batch',
                              doctypeLabel: 'batch',
                              enabled: canEdit,
                              initialSelection: vm.selectedBatchOption(line),
                              options: vm.batchFieldOptions(effectiveItemId, line.warehouseId),
                              allowCreate: canEdit,
                              validator: (_) {
                                if (!vm.isBatchManagedItem(effectiveItemId)) return null;
                                final hasBatchNo = line.batchNoController.text.trim().isNotEmpty;
                                if (!hasBatchNo) return 'Batch is required';
                                return null;
                              },
                              onChanged: canEdit ? (v) => vm.onLineBatchChanged(index, v) : (_) {},
                              onCreateNew: canEdit ? (query) => vm.createBatchForLine(index, query) : null,
                              createNewLabelBuilder: (query, _) => 'Create batch "$query"',
                              emptyMessageBuilder: (_, _) => 'No batches found for the selected item and warehouse',
                            ),
                          )
                        : const ErpLineItemTextCell(readOnly: true, enabled: false, initialValue: '-'),
                    'serial': vm.isSerialManagedItem(effectiveItemId)
                        ? ErpLineItemCellFrame(
                            height: null,
                            child: AppSerialNumbersField(
                              values: line.serialNumbers,
                              enabled: canEdit,
                              validator: (values) => vm.validateLineSerialNumbers(index, values),
                              onChanged: (values) => vm.setLineSerialNumbers(index, values),
                            ),
                          )
                        : const ErpLineItemTextCell(readOnly: true, enabled: false, initialValue: '-'),
                    'qty': ErpLineItemTextCell(
                      controller: line.qtyController,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => vm.onLineQtyChanged(index, line.qtyController.text),
                      validator: Validators.requiredPositiveNumber('Quantity'),
                    ),
                    'unit_cost': ErpLineItemTextCell(
                      controller: line.unitCostController,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => vm.onLineUnitCostChanged(index, line.unitCostController.text),
                      validator: Validators.optionalNonNegativeNumber('Unit Cost'),
                    ),
                    'total_cost': ErpLineItemTextCell(
                      controller: line.totalCostController,
                      readOnly: true,
                      enabled: canEdit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.optionalNonNegativeNumber('Total Cost'),
                    ),
                    'remarks': ErpLineItemTextCell(
                      controller: line.remarksController,
                      enabled: canEdit,
                      validator: Validators.optionalMaxLength(500, 'Line Remarks'),
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
