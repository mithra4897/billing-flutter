import '../../controller/sales/sales_return_management_controller.dart';
import '../../screen.dart';

class SalesReturnPage extends StatefulWidget {
  const SalesReturnPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final Map<String, String> queryParameters;

  @override
  State<SalesReturnPage> createState() => _SalesReturnPageState();
}

class _SalesReturnPageState extends State<SalesReturnPage> {
  late final String _controllerTag;

  SalesReturnManagementController get _controller =>
      Get.find<SalesReturnManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'SalesReturnManagementController',
      scope: <String, Object?>{'identity': identityHashCode(this)},
    );
    Get.put(SalesReturnManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_controller.initialize(initialId: widget.initialId));
    });
  }

  @override
  void dispose() {
    Get.delete<SalesReturnManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesReturnManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              controller.resetForm();
              if (!Responsive.isDesktop(context)) {
                controller.workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New Return',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Sales Returns',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildLineItemTable(SalesReturnManagementController controller) {
    final rows = List<ErpLineItemTableRow>.generate(controller.lines.length, (
      index,
    ) {
      final line = controller.lines[index];
      final breakdown = controller.taxBreakdownForLine(line);
      return ErpLineItemTableRow(
        rowKey: line,
        rateController: line.rateController,
        onRateChanged: (_) => controller.refreshLineState(),
        rateValidator: Validators.optionalNonNegativeNumber('Rate'),
        qtyController: line.returnQtyController,
        onQtyChanged: (_) => controller.refreshLineState(),
        qtyValidator: Validators.compose([
          Validators.required('Return Qty'),
          Validators.optionalNonNegativeNumber('Return Qty'),
        ]),
        remarksController: line.remarksController,
        amount: breakdown.taxable,
        deleteEnabled: controller.lines.length > 1,
        cellWidgets: <ErpLineItemTableColumn, Widget>{
          ErpLineItemTableColumn.item: ErpLineItemTextCell(
            controller: line.itemNameController,
            readOnly: true,
          ),
          ErpLineItemTableColumn.warehouse: ErpLineItemTextCell(
            controller: line.warehouseNameController,
            readOnly: true,
          ),
          ErpLineItemTableColumn.uom: ErpLineItemTextCell(
            controller: line.uomNameController,
            readOnly: true,
          ),
        },
        customCells: <String, Widget>{
          'invoice_line': ErpLineItemCellFrame(
            child: AppSearchPickerField<int>(
              labelText: '',
              selectedLabel: (() {
                final selected = controller.invoiceLineOptions
                    .cast<SalesInvoiceLineModel?>()
                    .firstWhere(
                      (item) => item?.id == line.salesInvoiceLineId,
                      orElse: () => null,
                    );
                if (selected == null) {
                  return null;
                }
                return '${controller.itemName(selected.itemId)} · Qty ${selected.invoicedQty}';
              })(),
              options: controller.invoiceLineOptions
                  .where((item) => item.id != null)
                  .map(
                    (item) => AppSearchPickerOption<int>(
                      value: item.id!,
                      label:
                          '${controller.itemName(item.itemId)} · Qty ${item.invoicedQty}',
                      subtitle:
                          '${controller.warehouseName(item.warehouseId)} · ${controller.uomName(item.uomId)}',
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => controller.handleLineSelected(index, value),
              validator: (_) => Validators.requiredSelectionField(
                line.salesInvoiceLineId,
                'Sales invoice line',
              ),
            ),
          ),
          'batch': controller.isBatchManagedItem(line.itemId)
              ? ErpLineItemTextCell(
                  controller: line.batchNoController,
                  readOnly: true,
                )
              : const ErpLineItemTextCell(
                  readOnly: true,
                  enabled: false,
                  initialValue: '-',
                ),
          'serial': controller.isSerialManagedItem(line.itemId)
              ? ErpLineItemTextCell(
                  controller: line.serialNoController,
                  readOnly: true,
                )
              : const ErpLineItemTextCell(
                  readOnly: true,
                  enabled: false,
                  initialValue: '-',
                ),
        },
      );
    });

    return ErpLineItemTable(
      title: 'Lines',
      lines: rows,
      onAddLine: controller.addLine,
      onDeleteLine: controller.removeLine,
      visibleColumns: const <ErpLineItemTableColumn>{
        ErpLineItemTableColumn.no,
        ErpLineItemTableColumn.item,
        ErpLineItemTableColumn.warehouse,
        ErpLineItemTableColumn.uom,
        ErpLineItemTableColumn.qty,
        ErpLineItemTableColumn.rate,
        ErpLineItemTableColumn.amount,
        ErpLineItemTableColumn.action,
      },
      columnLabels: const <ErpLineItemTableColumn, String>{
        ErpLineItemTableColumn.qty: 'Return Qty',
      },
      customColumns: const <ErpLineItemCustomColumn>[
        ErpLineItemCustomColumn(
          id: 'invoice_line',
          label: 'Sales Invoice Line',
          width: 240,
          insertAfter: ErpLineItemTableColumn.no,
        ),
        ErpLineItemCustomColumn(
          id: 'batch',
          label: 'Batch',
          width: 150,
          insertAfter: ErpLineItemTableColumn.warehouse,
        ),
        ErpLineItemCustomColumn(
          id: 'serial',
          label: 'Serial Number',
          width: 170,
          insertAfter: ErpLineItemTableColumn.warehouse,
        ),
      ],
      footer: _buildTaxSummaryCard(controller),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SalesReturnManagementController controller,
  ) {
    final selectedData = controller.selectedItem?.toJson() ?? const {};
    final status = stringValue(selectedData, 'return_status', 'draft');
    final canEdit = controller.selectedItem == null || status == 'draft';
    final canPost = controller.selectedItem != null && status == 'draft';
    final canCancel = controller.selectedItem != null && status == 'draft';
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading sales returns...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load sales returns',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Sales Returns',
      editorTitle: controller.selectedItem == null
          ? 'New Sales Return'
          : stringValue(
              controller.selectedItem!.toJson(),
              'return_no',
              'Sales Return',
            ),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<SalesReturnModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No sales returns found.',
        searchController: controller.searchController,
        searchHint: 'Search returns',
        statusValue: controller.statusFilter,
        statusItems: SalesReturnManagementController.statusItems,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'return_no', 'Draft Return'),
            subtitle: [
              displayDate(nullableStringValue(data, 'return_date')),
              stringValue(data, 'return_status'),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: salesListDetailWithCancelReason(
              data,
              quotationCustomerLabel(data),
              statusKey: 'return_status',
            ),
            selected: selected,
            onTap: () => controller.selectDocument(item),
          );
        },
      ),
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                DocumentSeriesSelector<int>(
                  labelText: 'Document Series',
                  mappedItems: controller
                      .seriesOptions()
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.documentSeriesId,
                  onChanged: controller.setDocumentSeriesId,
                ),
                GeneratedDocumentNumberField(
                  labelText: 'Return No',
                  controller: controller.returnNoController,
                  documentSeries: controller.seriesOptions(),
                  documentSeriesId: controller.documentSeriesId,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Return No'),
                ),
                AppFormTextField(
                  labelText: 'Return Date',
                  controller: controller.returnDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Return Date'),
                    Validators.date('Return Date'),
                  ]),
                ),
                AppSearchPickerField<int>(
                  labelText: 'Sales Invoice',
                  selectedLabel: controller.selectedInvoice?.invoiceNo,
                  options: controller.invoiceOptions
                      .map(
                        (item) => AppSearchPickerOption<int>(
                          value: item.id!,
                          label: item.invoiceNo ?? 'Invoice',
                          subtitle: [
                            displayDate(
                              item.invoiceDate.isEmpty
                                  ? null
                                  : item.invoiceDate,
                            ),
                            item.invoiceStatus ?? '',
                            item.totalAmount == null
                                ? ''
                                : item.totalAmount!.toStringAsFixed(2),
                          ].where((part) => part.isNotEmpty).join(' · '),
                          searchText: [
                            item.invoiceNo ?? '',
                            item.invoiceStatus ?? '',
                            item.totalAmount?.toString() ?? '',
                          ].join(' '),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.handleInvoiceChanged,
                  validator: Validators.required('Sales Invoice'),
                ),
                AppFormTextField(
                  labelText: 'Reason',
                  controller: controller.reasonController,
                ),
                AppFormTextField(
                  labelText: 'Round off',
                  controller: controller.roundOffController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  enabled: controller.applyRoundOff,
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) {
                      return null;
                    }
                    return Validators.parseFlexibleNumber(text) == null
                        ? 'Round off must be a valid number'
                        : null;
                  },
                ),
                AppSwitchTile(
                  label: 'Apply round off',
                  value: controller.applyRoundOff,
                  onChanged: controller.setApplyRoundOff,
                ),
                AppFormTextField(
                  labelText: 'Notes',
                  controller: controller.notesController,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              value: controller.isActive,
              onChanged: controller.setIsActive,
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            _buildLineItemTable(controller),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedItem == null
                      ? 'Save Return'
                      : 'Update Return',
                  onPressed: canEdit ? () => controller.save(context) : null,
                  busy: controller.saving,
                ),
                if (canPost)
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => controller.postSelected(context),
                  ),
                if (canCancel)
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => controller.cancelSelected(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxSummaryCard(SalesReturnManagementController controller) {
    final summary = controller.taxSummary();
    final roundOff = controller.applyRoundOff
        ? (Validators.parseFlexibleNumber(
                controller.roundOffController.text.trim(),
              ) ??
              0)
        : 0;
    return GstSummaryCard(
      taxable: summary.taxable,
      cgst: summary.cgst,
      sgst: summary.sgst,
      igst: summary.igst,
      cess: summary.cess,
      total: summary.total + roundOff,
      currencyCode: controller.currencyCodeForTaxSummary,
      subtitle: roundOff == 0
          ? null
          : 'Includes round off ${roundOff.toStringAsFixed(2)}',
    );
  }
}
