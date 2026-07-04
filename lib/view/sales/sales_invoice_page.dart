import '../../controller/sales/sales_invoice_management_controller.dart';
import '../../screen.dart';

class SalesInvoicePage extends StatefulWidget {
  const SalesInvoicePage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialQuotationId,
    this.initialOrderId,
    this.initialDeliveryId,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  /// Prefills a **standalone** invoice from a quotation (API has no `sales_quotation_id` on invoices).
  final int? initialQuotationId;
  final int? initialOrderId;
  final int? initialDeliveryId;
  final Map<String, String> queryParameters;

  @override
  State<SalesInvoicePage> createState() => _SalesInvoicePageState();
}

class _SalesInvoicePageState extends State<SalesInvoicePage> {
  late final String _controllerTag;

  SalesInvoiceManagementController get _controller =>
      Get.find<SalesInvoiceManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'SalesInvoiceManagementController',
      scope: <String, Object?>{'identity': identityHashCode(this)},
    );
    Get.put(SalesInvoiceManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _controller.initialize(
          initialId: widget.initialId,
          initialQuotationId: widget.initialQuotationId,
          initialOrderId: widget.initialOrderId,
          initialDeliveryId: widget.initialDeliveryId,
          editorOnly: widget.editorOnly,
        ),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<SalesInvoiceManagementController>(
        tag: _controllerTag,
      )) {
        Get.delete<SalesInvoiceManagementController>(
          tag: _controllerTag,
          force: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesInvoiceManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => _openFilterPanel(context, controller),
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: false,
          ),
          AdaptiveShellActionButton(
            onPressed: () {
              controller.resetForm();
              if (!Responsive.isDesktop(context)) {
                controller.workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New invoice',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Sales Invoices',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    SalesInvoiceManagementController controller,
  ) {
    return openSalesSearchStatusFilterPanel(
      context: context,
      title: 'Filter Sales Invoices',
      searchController: controller.searchController,
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      searchHint: 'Search by number or customer',
      status: controller.statusFilter,
      statusItems: SalesInvoiceManagementController.listStatusFilter,
      onApply: (search, status, dateFrom, dateTo) {
        controller.searchController.text = search;
        controller.dateFromController.text = dateFrom;
        controller.dateToController.text = dateTo;
        controller.statusFilter = status;
        controller.applyFilters();
      },
      onClear: () {
        controller.searchController.clear();
        controller.dateFromController.clear();
        controller.dateToController.clear();
        controller.statusFilter = '';
        controller.applyFilters();
      },
    );
  }

  Widget _buildGridHintCell(
    BuildContext context,
    String text, {
    bool muted = true,
  }) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    return ErpLineItemCellFrame(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: muted ? appTheme.tableMutedText : appTheme.tableCellText,
          ),
        ),
      ),
    );
  }

  Widget buildTaxSummaryCard(
    BuildContext context,
    SalesInvoiceManagementController controller,
  ) {
    final summary = controller.invoiceTaxSummary();
    const currency = 'INR';
    final isInterState = controller.isInterStateForSummary();
    final roundOff = controller.applyRoundOff
        ? (Validators.parseFlexibleNumber(controller.roundOffController.text) ?? 0)
        : 0;
    return GstSummaryCard(
      taxable: summary.taxable,
      cgst: summary.cgst,
      sgst: summary.sgst,
      igst: summary.igst,
      cess: summary.cess,
      total: summary.total,
      currencyCode: currency,
      subtitle: isInterState == null
          ? (roundOff == 0
                ? 'Live totals for the current invoice lines.'
                : 'Live totals for the current invoice lines. Includes round off ${roundOff.toStringAsFixed(2)}.')
          : 'Live totals for the current invoice lines. ${isInterState ? 'Inter-state invoice using IGST.' : 'Intra-state invoice using CGST and SGST.'}${roundOff == 0 ? '' : ' Includes round off ${roundOff.toStringAsFixed(2)}.'}',
    );
  }

  Widget _buildLineItemTable(SalesInvoiceManagementController controller) {
    final itemOptions = controller.itemsLookup
        .where((item) => item.id != null)
        .map(
          (item) => ErpLinkFieldOption<int>(
            value: item.id!,
            label: item.toString(),
            subtitle: item.itemCode,
            searchText: item.pickerSearchText,
          ),
        )
        .toList(growable: false);

    final taxOptions = controller.taxCodes
        .where((item) => item.id != null)
        .map(
          (item) =>
              AppDropdownItem<int>(value: item.id!, label: item.toString()),
        )
        .toList(growable: false);

    final customColumns = <ErpLineItemCustomColumn>[
      if (controller.salesOrderId != null &&
          (controller.orderLinesCache?.isNotEmpty ?? false))
        const ErpLineItemCustomColumn(
          id: 'order_line',
          label: 'Order line',
          width: 190,
          insertAfter: ErpLineItemTableColumn.no,
        ),
      if (controller.salesDeliveryId != null &&
          (controller.deliveryLinesCache?.isNotEmpty ?? false))
        const ErpLineItemCustomColumn(
          id: 'delivery_line',
          label: 'Delivery line',
          width: 190,
          insertAfter: ErpLineItemTableColumn.no,
        ),
      const ErpLineItemCustomColumn(
        id: 'batch',
        label: 'Batch',
        width: 150,
        insertAfter: ErpLineItemTableColumn.warehouse,
      ),
      const ErpLineItemCustomColumn(
        id: 'serials',
        label: 'Serials',
        width: 220,
        insertAfter: ErpLineItemTableColumn.warehouse,
      ),
    ];

    final rows = List<ErpLineItemTableRow>.generate(controller.lines.length, (
      index,
    ) {
      final line = controller.lines[index];
      final amount = controller.taxBreakdownForLine(line)?.total ?? 0.0;
      final uomOptions = controller
          .uomOptionsForItem(line.itemId)
          .where((item) => item.id != null)
          .map(
            (item) =>
                AppDropdownItem<int>(value: item.id!, label: item.toString()),
          )
          .toList(growable: false);

      if (controller.canEdit && uomOptions.length == 1) {
        final onlyId = uomOptions.first.value;
        if (line.uomId != onlyId) {
          line.uomId = onlyId;
        }
      }

      final itemSelection = line.itemId == null
          ? null
          : itemOptions.cast<ErpLinkFieldOption<int>?>().firstWhere(
              (item) => item?.value == line.itemId,
              orElse: () => null,
            );

      final warehouseOptions = controller
          .warehouseOptionsForLine(line)
          .where((item) => item.id != null)
          .map(
            (item) =>
                AppDropdownItem<int>(value: item.id!, label: item.toString()),
          )
          .toList(growable: false);

      return ErpLineItemTableRow(
        rowKey: line,
        itemId: line.itemId,
        itemSelection: itemSelection,
        itemOptions: itemOptions,
        onItemChanged: controller.canEdit
            ? (value) {
                controller.State(() {
                  line.itemId = value;
                  line.salesOrderLineId = null;
                  line.salesDeliveryLineId = null;
                  line.warehouseId = null;
                  line.batchId = null;
                  line.serialId = null;
                  line.serialNumbers = <String>[];
                  line.serialNoController.clear();
                  final item = controller.itemsLookup
                      .cast<ItemModel?>()
                      .firstWhere((e) => e?.id == value, orElse: () => null);
                  applySalesLineDefaultsFromItemMaster(
                    item: item,
                    itemPrices: controller.itemPrices,
                    uoms: controller.uoms,
                    conversions: controller.uomConversions,
                    rateController: line.rateController,
                    qtyController: line.qtyController,
                    setUom: (u) => line.uomId = u,
                    currentUomId: line.uomId,
                    setTaxCodeId: (t) => line.taxCodeId = t,
                    setWarehouseId: (w) => line.warehouseId = w,
                    currentWarehouseId: line.warehouseId,
                    warehouses: controller.warehouses,
                  );
                });
                unawaited(controller.syncWarehouseOptionsForLine(line));
                unawaited(controller.syncBatchOptionsForLine(line));
                unawaited(controller.syncSerialOptionsForLine(line));
              }
            : null,
        itemValidator: (_) => line.itemId == null ? 'Item is required' : null,
        uomId: line.uomId,
        uomOptions: uomOptions,
        onUomChanged: controller.canEdit
            ? (value) {
                controller.State(() => line.uomId = value);
              }
            : null,
        uomValidator: (_) {
          if (line.itemId == null) {
            return 'Select item first';
          }
          return line.uomId == null ? 'UOM is required' : null;
        },
        warehouseId: line.warehouseId,
        warehouseOptions: warehouseOptions,
        onWarehouseChanged: controller.canEdit
            ? (value) {
                controller.State(() {
                  line.warehouseId = value;
                  line.batchId = null;
                  line.serialId = null;
                });
                unawaited(controller.syncBatchOptionsForLine(line));
                unawaited(controller.syncSerialOptionsForLine(line));
              }
            : null,
        qtyController: line.qtyController,
        onQtyChanged: controller.canEdit
            ? (_) => controller.State(() {})
            : null,
        qtyValidator: (_) {
          final text = line.qtyController.text.trim();
          if (text.isEmpty) {
            return 'Qty is required';
          }
          final qtyValue = double.tryParse(text);
          if (qtyValue == null || qtyValue < 0) {
            return 'Qty must be a valid non-negative number';
          }
          if (qtyValue <= 0) {
            return 'Qty must be greater than zero';
          }
          if (controller.isSerialManagedItem(line.itemId)) {
            final serialCount = controller.lineSerialNumbers(line).length;
            if (line.warehouseId == null) {
              return 'Select warehouse first';
            }
            if (serialCount == 0) {
              return 'Add at least one serial number';
            }
            if (qtyValue != serialCount) {
              return 'Qty must match serial count';
            }
          }
          return null;
        },
        rateController: line.rateController,
        onRateChanged: controller.canEdit
            ? (_) => controller.State(() {})
            : null,
        rateValidator: Validators.compose([
          Validators.required('Rate'),
          Validators.optionalNonNegativeNumber('Rate'),
        ]),
        discountController: line.discountController,
        onDiscountChanged: controller.canEdit
            ? (_) => controller.State(() {})
            : null,
        discountValidator: Validators.optionalNonNegativeNumber('Discount %'),
        taxCodeId: line.taxCodeId,
        taxOptions: taxOptions,
        onTaxCodeChanged: controller.canEdit
            ? (value) => controller.State(() => line.taxCodeId = value)
            : null,
        descriptionController: line.descriptionController,
        remarksController: line.remarksController,
        amount: amount,
        deleteEnabled: controller.canEdit && controller.lines.length > 1,
        customCells: <String, Widget>{
          'order_line': ErpLineItemCellFrame(
            child: AppDropdownField<int?>.fromMapped(
              labelText: '',
              hintText: 'Order line',
              fieldPadding: EdgeInsets.zero,
              mappedItems: [
                const AppDropdownItem<int?>(value: null, label: 'None'),
                ...?controller.orderLinesCache
                    ?.map((ol) {
                      final id = intValue(ol, 'id');
                      return AppDropdownItem<int?>(
                        value: id,
                        label: controller.orderLinePickerLabel(ol),
                      );
                    })
                    .where((it) => it.value != null),
              ],
              initialValue: line.salesOrderLineId,
              onChanged: controller.canEdit
                  ? (value) => controller.applyOrderLinePick(line, value)
                  : null,
              enabled: controller.canEdit,
            ),
          ),
          'delivery_line': ErpLineItemCellFrame(
            child: AppDropdownField<int?>.fromMapped(
              labelText: '',
              hintText: 'Delivery line',
              fieldPadding: EdgeInsets.zero,
              mappedItems: [
                const AppDropdownItem<int?>(value: null, label: 'None'),
                ...?controller.deliveryLinesCache
                    ?.map((dl) {
                      final id = intValue(dl, 'id');
                      return AppDropdownItem<int?>(
                        value: id,
                        label: controller.deliveryLinePickerLabel(dl),
                      );
                    })
                    .where((it) => it.value != null),
              ],
              initialValue: line.salesDeliveryLineId,
              onChanged: controller.canEdit
                  ? (value) => controller.applyDeliveryLinePick(line, value)
                  : null,
              enabled: controller.canEdit,
            ),
          ),
          'batch': () {
            if (line.itemId == null) {
              return _buildGridHintCell(context, 'Select item');
            }
            if (!controller.isBatchManagedItem(line.itemId)) {
              return _buildGridHintCell(context, 'Not required');
            }
            if (line.warehouseId == null) {
              return _buildGridHintCell(context, 'Select warehouse');
            }
            final batchItems = controller
                .batchOptionsForLine(line)
                .map(
                  (batch) => AppDropdownItem<int>(
                    value:
                        int.tryParse(batch['batch_id']?.toString() ?? '') ?? 0,
                    label: stringValue(batch, 'batch_no', 'Batch'),
                  ),
                )
                .where((item) => item.value != 0)
                .toList(growable: false);
            if (batchItems.isEmpty) {
              return _buildGridHintCell(context, 'No batches');
            }
            return ErpLineItemCellFrame(
              child: AppDropdownField<int>.fromMapped(
                labelText: '',
                hintText: 'Batch',
                fieldPadding: EdgeInsets.zero,
                mappedItems: batchItems,
                initialValue: line.batchId,
                onChanged: controller.canEdit
                    ? (value) {
                        controller.State(() {
                          line.batchId = value;
                          line.serialId = null;
                        });
                        unawaited(controller.syncSerialOptionsForLine(line));
                      }
                    : null,
                enabled: controller.canEdit,
              ),
            );
          }(),
          'serials': () {
            if (line.itemId == null) {
              return _buildGridHintCell(context, 'Select item');
            }
            if (!controller.isSerialManagedItem(line.itemId)) {
              return _buildGridHintCell(context, 'Not required');
            }
            if (line.warehouseId == null) {
              return _buildGridHintCell(context, 'Select warehouse');
            }
            if (controller.isBatchManagedItem(line.itemId) &&
                line.batchId == null) {
              return _buildGridHintCell(context, 'Select batch');
            }
            return ErpLineItemCellFrame(
              height: null,
              child: AppSerialNumbersField(
                labelText: '',
                emptyText: 'Add serials',
                countSummaryBuilder: (count) => '$count serials',
                values: line.serialNumbers,
                enabled: controller.canEdit,
                canOpen:
                    ((controller.isBatchManagedItem(line.itemId)
                        ? line.batchId != null
                        : line.warehouseId != null) ||
                    line.serialNumbers.isNotEmpty),
                beforeOpen: controller.canEdit
                    ? () => controller.syncSerialOptionsForLine(line)
                    : null,
                validator: (values) {
                  final serialOptions = controller.serialOptionsForLine(line);
                  if (line.warehouseId == null) {
                    return 'Select warehouse first';
                  }
                  if (controller.isBatchManagedItem(line.itemId) &&
                      line.batchId == null) {
                    return 'Select batch first';
                  }
                  if (serialOptions.isEmpty) {
                    return 'No serials found in backend for the selected warehouse.';
                  }
                  final serialLabelSet = controller.serialLabelSetForLine(line);
                  for (final value in values) {
                    if (!serialLabelSet.contains(value.trim().toLowerCase())) {
                      return 'Serial "$value" is not available for the selected warehouse/batch.';
                    }
                  }
                  return null;
                },
                onChanged: (values) {
                  controller.State(() {
                    if (controller.isSerialManagedItem(line.itemId)) {
                      controller.replaceLineWithSerialDrafts(line, values);
                    } else {
                      controller.setLineSerialNumbers(line, values);
                    }
                  });
                },
              ),
            );
          }(),
        },
      );
    });

    return ErpLineItemTable(
      lines: rows,
      onChanged: (_) {},
      onAddLine: controller.canEdit ? controller.addLine : null,
      onDeleteLine: controller.canEdit ? controller.removeLine : null,
      addButtonLabel: 'Add line',
      visibleColumns: const <ErpLineItemTableColumn>{
        ErpLineItemTableColumn.no,
        ErpLineItemTableColumn.item,
        ErpLineItemTableColumn.uom,
        ErpLineItemTableColumn.warehouse,
        ErpLineItemTableColumn.qty,
        ErpLineItemTableColumn.rate,
        ErpLineItemTableColumn.discount,
        ErpLineItemTableColumn.taxCode,
        ErpLineItemTableColumn.amount,
        ErpLineItemTableColumn.action,
      },
      columnLabels: const <ErpLineItemTableColumn, String>{
        ErpLineItemTableColumn.taxCode: 'Tax code',
      },
      customColumns: customColumns,
      footer: buildTaxSummaryCard(context, controller),
      enabled: controller.canEdit,
    );
  }

  Widget _buildContent(
    BuildContext context,
    SalesInvoiceManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading invoices...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load invoices',
        message: controller.pageError!,
        onRetry: controller.reloadLastRequestedPage,
      );
    }

    final liveSummary = controller.invoiceTaxSummary();
    final totalStr = liveSummary.total.toStringAsFixed(2);

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Sales Invoices',
      editorTitle: controller.selectedItem == null
          ? 'New invoice'
          : (controller.selectedItem!.invoiceNo?.trim().isNotEmpty == true
                ? controller.selectedItem!.invoiceNo!
                : 'Invoice #${controller.selectedItem!.id}'),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<SalesInvoiceModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No invoices yet.',
        searchController: controller.searchController,
        searchHint: 'Search by number or customer',
        statusValue: controller.statusFilter,
        statusItems: SalesInvoiceManagementController.listStatusFilter,
        onStatusChanged: (value) {
          controller.statusFilter = value ?? '';
          controller.applyFilters();
        },
        showInlineFilters: false,
        itemBuilder: (item, selected) {
          final data = controller.rowJson(item);
          final st = item.invoiceStatus ?? '';
          const currency = 'INR';
          final total =
              item.totalAmount ??
              double.tryParse(data['total_amount']?.toString() ?? '') ??
              0;
          final bal =
              item.balanceAmount ??
              double.tryParse(data['balance_amount']?.toString() ?? '') ??
              0;
          return SettingsListTile(
            title: (item.invoiceNo?.trim().isNotEmpty == true)
                ? item.invoiceNo!
                : 'Draft #${item.id}',
            subtitle:
                'Date ${displayDate(item.invoiceDate.isEmpty ? null : item.invoiceDate)}',
            detail: salesListDetailWithCancelReason(
              data,
              quotationCustomerLabel(data),
              statusKey: 'invoice_status',
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                salesStatusBadge(context, st, dueDate: item.dueDate),
                const SizedBox(height: AppUiConstants.spacingXxs),
                Text(
                  'Total ${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  currency,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).extension<AppThemeExtension>()!.mutedText,
                  ),
                ),
                if (!const {'draft', 'cancelled'}.contains(st))
                  Text(
                    'Outstanding ${bal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
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
            if (controller.selectedItem != null && !controller.canEdit) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppUiConstants.spacingMd),
                child: Text(
                  'This document is read-only (Posted/Completed/Cancelled documents cannot be edited)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            CrmSalesPipelineBar(
              data: controller.salesChain,
              hideInvoiceChip: true,
            ),
            if (controller.selectedItem != null)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingXs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Total: $totalStr INR',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    salesStatusBadge(
                      context,
                      controller.status,
                      dueDate: controller.dueDateController.text.trim(),
                    ),
                  ],
                ),
              ),
            if (controller.selectedItem != null &&
                !const {'draft', 'cancelled'}.contains(controller.status) &&
                controller.outstandingBalanceForSelectedInvoice() > 0.000001)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Outstanding: ${controller.outstandingBalanceForSelectedInvoice().toStringAsFixed(2)} INR',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    AppActionButton(
                      icon: Icons.payments_outlined,
                      label: 'Receive payment',
                      filled: false,
                      onPressed: () => openModuleShellRoute(
                        context,
                        '/sales/receipts/new?invoice_id=${controller.selectedItem!.id}',
                      ),
                    ),
                  ],
                ),
              ),
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
                  onChanged: (value) {
                    if (!controller.canEdit) {
                      return;
                    }
                    controller.State(() => controller.documentSeriesId = value);
                  },
                ),
                GeneratedDocumentNumberField(
                  labelText: 'Invoice No',
                  controller: controller.invoiceNoController,
                  documentSeries: controller.seriesOptions(),
                  documentSeriesId: controller.documentSeriesId,
                  hintText: 'Leave blank if your series fills this in',
                  enabled: controller.canEdit,
                  validator: Validators.optionalMaxLength(100, 'Invoice No'),
                ),
                AppFormTextField(
                  labelText: 'Invoice Date',
                  controller: controller.invoiceDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: controller.canEdit,
                  validator: Validators.compose([
                    Validators.required('Invoice Date'),
                    Validators.date('Invoice Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Due Date',
                  controller: controller.dueDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: controller.canEdit,
                  validator: Validators.compose([
                    Validators.optionalDate('Due Date'),
                    Validators.optionalDateOnOrAfter(
                      'Due Date',
                      () => controller.invoiceDateController.text.trim(),
                      startFieldName: 'Invoice Date',
                    ),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Customer',
                  doctypeLabel: 'Customer',
                  allowCreate: true,
                  onNavigateToCreateNew: (name) {
                    final uri = Uri(
                      path: '/parties',
                      queryParameters: {
                        'new': '1',
                        'party_context': 'customer',
                        if (name.trim().isNotEmpty) 'party_name': name.trim(),
                      },
                    );
                    openModuleShellRoute(context, uri.toString());
                  },
                  mappedItems: controller.customers
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.customerPartyId,
                  onChanged: (value) {
                    if (!controller.canEdit) {
                      return;
                    }
                    controller.State(() {
                      controller.customerPartyId = value;
                      controller.billingAddressId = null;
                      controller.shippingAddressId = null;
                      controller.pruneSourcesForCustomer();
                    });
                    unawaited(controller.ensureCustomerTaxContext(value));
                  },
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Sales quotation (optional)',
                  mappedItems: [
                    const AppDropdownItem<int?>(value: null, label: 'None'),
                    ...controller.quotationChoices
                        .map((q) => q.toJson())
                        .where((j) => intValue(j, 'id') != null)
                        .map(
                          (j) => AppDropdownItem<int?>(
                            value: intValue(j, 'id'),
                            label: stringValue(j, 'quotation_no', 'Quotation'),
                          ),
                        ),
                  ],
                  initialValue: controller.salesQuotationId,
                  onChanged: (value) => unawaited(
                    controller.onHeaderSalesQuotationChanged(value),
                  ),
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Sales order (optional)',
                  mappedItems: [
                    const AppDropdownItem<int?>(value: null, label: 'None'),
                    ...controller.orderChoices
                        .map((o) => o.toJson())
                        .where((j) => intValue(j, 'id') != null)
                        .map(
                          (j) => AppDropdownItem<int?>(
                            value: intValue(j, 'id'),
                            label: stringValue(j, 'order_no', 'Order'),
                          ),
                        ),
                  ],
                  initialValue: controller.salesOrderId,
                  onChanged: (value) =>
                      unawaited(controller.onHeaderSalesOrderChanged(value)),
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Sales delivery (optional)',
                  mappedItems: [
                    const AppDropdownItem<int?>(value: null, label: 'None'),
                    ...controller.deliveryChoices
                        .map((d) => d.toJson())
                        .where((j) => intValue(j, 'id') != null)
                        .map(
                          (j) => AppDropdownItem<int?>(
                            value: intValue(j, 'id'),
                            label: stringValue(j, 'delivery_no', 'Delivery'),
                          ),
                        ),
                  ],
                  initialValue: controller.salesDeliveryId,
                  onChanged: (value) =>
                      unawaited(controller.onHeaderSalesDeliveryChanged(value)),
                ),
                AppFormTextField(
                  labelText: 'Customer PO / Ref',
                  controller: controller.customerRefNoController,
                  enabled: controller.canEdit,
                  validator: Validators.optionalMaxLength(100, 'Reference'),
                ),
                AppFormTextField(
                  labelText: 'Customer Ref Date',
                  controller: controller.customerRefDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: controller.canEdit,
                  validator: Validators.optionalDate('Customer Ref Date'),
                ),
                AppFormTextField(
                  labelText: 'Round off',
                  controller: controller.roundOffController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  enabled: controller.canEdit && controller.applyRoundOff,
                  onChanged: (_) => controller.State(() {}),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return null;
                    }
                    if (double.tryParse(trimmed) == null) {
                      return 'Round off must be a valid number';
                    }
                    return null;
                  },
                ),
                AppSwitchTile(
                  label: 'Apply round off',
                  value: controller.applyRoundOff,
                  onChanged: controller.canEdit
                      ? controller.setApplyRoundOff
                      : null,
                ),
                AppFormTextField(
                  labelText: 'Adjustment amount',
                  controller: controller.adjustmentAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  enabled: controller.canEdit,
                  onChanged: (_) => controller.State(() {}),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return null;
                    }
                    if (double.tryParse(trimmed) == null) {
                      return 'Adjustment amount must be a valid number';
                    }
                    return null;
                  },
                ),
                // Future option:
                // AppDropdownField<int>.fromMapped(
                //   labelText: 'Adjustment account',
                //   mappedItems: controller.accountOptions
                //       .where((item) => item.id != null)
                //       .map(
                //         (item) => AppDropdownItem(
                //           value: item.id!,
                //           label: item.toString(),
                //         ),
                //       )
                //       .toList(growable: false),
                //   initialValue: controller.adjustmentAccountId,
                //   onChanged: (value) {
                //     if (!controller.canEdit) {
                //       return;
                //     }
                //     controller.State(
                //       () => controller.adjustmentAccountId = value,
                //     );
                //   },
                // ),
                AppFormTextField(
                  labelText: 'Adjustment remarks',
                  controller: controller.adjustmentRemarksController,
                  enabled: controller.canEdit,
                  maxLines: 2,
                ),
                AppFormTextField(
                  labelText: 'Notes (shown to customer)',
                  controller: controller.notesController,
                  maxLines: 3,
                  enabled: controller.canEdit,
                ),
                AppFormTextField(
                  labelText: 'Terms & Conditions',
                  controller: controller.termsController,
                  maxLines: 3,
                  enabled: controller.canEdit,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              value: controller.isActive,
              onChanged: controller.canEdit
                  ? (value) =>
                        controller.State(() => controller.isActive = value)
                  : null,
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            _buildLineItemTable(controller),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (controller.selectedItem != null)
                  AppActionButton(
                    icon: controller.status == 'draft'
                        ? Icons.preview_outlined
                        : Icons.print_outlined,
                    label: controller.status == 'draft' ? 'Preview' : 'Print',
                    filled: false,
                    onPressed: () => controller.openPrintPreview(
                      context,
                      allowPrint: controller.status != 'draft',
                      allowDownload: controller.status != 'draft',
                      allowTemplateEditing: controller.status != 'draft',
                    ),
                  ),
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedItem == null
                      ? 'Save invoice'
                      : 'Update invoice',
                  onPressed: controller.canEdit
                      ? () => controller.save(context)
                      : null,
                  busy: controller.saving,
                ),
                if (controller.selectedItem != null) ...[
                  if (controller.status == 'draft') ...[
                    AppActionButton(
                      icon: Icons.publish_outlined,
                      label: 'Post',
                      filled: false,
                      onPressed: () => controller.docAction(
                        context,
                        () => controller.postInvoice(
                          controller.selectedItem!.id!,
                        ),
                      ),
                    ),
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: () => controller.deleteSelected(context),
                    ),
                    AppActionButton(
                      icon: Icons.block_outlined,
                      label: 'Cancel invoice',
                      filled: false,
                      onPressed: () async {
                        final reason = await promptCancellationReason(
                          context,
                          title: 'Cancel invoice',
                          subjectLabel:
                              controller.selectedItem?.toString() ??
                              'this sales invoice',
                        );
                        if (reason == null || !context.mounted) {
                          return;
                        }
                        await controller.docAction(
                          context,
                          () => controller.cancelInvoice(
                            controller.selectedItem!.id!,
                            reason,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
