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

  Widget buildTaxSummaryCard(
    BuildContext context,
    SalesInvoiceManagementController controller,
  ) {
    final summary = controller.invoiceTaxSummary();
    const currency = 'INR';
    final isInterState = controller.isInterStateForSummary();
    final roundOff = controller.applyRoundOff
        ? (double.tryParse(controller.roundOffController.text.trim()) ?? 0)
        : 0;
    return GstSummaryCard(
      taxable: summary.taxable,
      cgst: summary.cgst,
      sgst: summary.sgst,
      igst: summary.igst,
      cess: 0,
      total: summary.total,
      currencyCode: currency,
      subtitle: isInterState == null
          ? (roundOff == 0
                ? 'Live totals for the current invoice lines.'
                : 'Live totals for the current invoice lines. Includes round off ${roundOff.toStringAsFixed(2)}.')
          : 'Live totals for the current invoice lines. ${isInterState ? 'Inter-state invoice using IGST.' : 'Intra-state invoice using CGST and SGST.'}${roundOff == 0 ? '' : ' Includes round off ${roundOff.toStringAsFixed(2)}.'}',
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
            subtitle: [
              'Date ${displayDate(item.invoiceDate.isEmpty ? null : item.invoiceDate)}',
              if (st.isNotEmpty) 'Status ${st.toUpperCase()}',
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: quotationCustomerLabel(data),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                child: Text(
                  'Total: $totalStr INR · Status: ${controller.status.toUpperCase()}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                AppFormTextField(
                  labelText: 'Invoice No',
                  controller: controller.invoiceNoController,
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
                  validator: Validators.requiredSelection('Customer'),
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Adjustment account',
                  mappedItems: controller.accountOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.adjustmentAccountId,
                  onChanged: (value) {
                    if (!controller.canEdit) {
                      return;
                    }
                    controller.State(
                      () => controller.adjustmentAccountId = value,
                    );
                  },
                ),
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
            Row(
              children: [
                Text(
                  'Line items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add line',
                  onPressed: controller.canEdit ? controller.addLine : null,
                  filled: false,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            ...List<Widget>.generate(controller.lines.length, (index) {
              final line = controller.lines[index];
              return Padding(
                key: ObjectKey(line),
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: PurchaseCompactLineCard(
                  index: index,
                  total: controller.lines.length,
                  removeEnabled:
                      controller.canEdit && controller.lines.length > 1,
                  onRemove: controller.canEdit
                      ? () => controller.removeLine(index)
                      : null,
                  child: PurchaseCompactFieldGrid(
                    children: [
                      if (controller.salesOrderId != null &&
                          (controller.orderLinesCache != null &&
                              controller.orderLinesCache!.isNotEmpty))
                        AppDropdownField<int?>.fromMapped(
                          labelText: 'Order line',
                          mappedItems: [
                            const AppDropdownItem<int?>(
                              value: null,
                              label: 'None',
                            ),
                            ...controller.orderLinesCache!
                                .map((ol) {
                                  final id = intValue(ol, 'id');
                                  return AppDropdownItem<int?>(
                                    value: id,
                                    label: controller.orderLinePickerLabel(ol),
                                  );
                                })
                                .where((it) => it.value != null),
                          ],
                          initialValue: line.salesOrderLineId,
                          onChanged: (value) {
                            if (!controller.canEdit) {
                              return;
                            }
                            controller.applyOrderLinePick(line, value);
                          },
                        ),
                      if (controller.salesDeliveryId != null &&
                          (controller.deliveryLinesCache != null &&
                              controller.deliveryLinesCache!.isNotEmpty))
                        AppDropdownField<int?>.fromMapped(
                          labelText: 'Delivery line',
                          mappedItems: [
                            const AppDropdownItem<int?>(
                              value: null,
                              label: 'None',
                            ),
                            ...controller.deliveryLinesCache!
                                .map((dl) {
                                  final id = intValue(dl, 'id');
                                  return AppDropdownItem<int?>(
                                    value: id,
                                    label: controller.deliveryLinePickerLabel(
                                      dl,
                                    ),
                                  );
                                })
                                .where((it) => it.value != null),
                          ],
                          initialValue: line.salesDeliveryLineId,
                          onChanged: (value) {
                            if (!controller.canEdit) {
                              return;
                            }
                            controller.applyDeliveryLinePick(line, value);
                          },
                        ),
                      AppSearchPickerField<int>(
                        labelText: 'Item',
                        selectedLabel: controller.itemsLookup
                            .cast<ItemModel?>()
                            .firstWhere(
                              (item) => item?.id == line.itemId,
                              orElse: () => null,
                            )
                            ?.toString(),
                        options: controller.itemsLookup
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppSearchPickerOption<int>(
                                value: item.id!,
                                label: item.toString(),
                                subtitle: item.itemCode,
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (!controller.canEdit) {
                            return;
                          }
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
                                .firstWhere(
                                  (e) => e?.id == value,
                                  orElse: () => null,
                                );
                            applySalesLineDefaultsFromItemMaster(
                              item: item,
                              itemPrices: controller.itemPrices,
                              uoms: controller.uoms,
                              conversions: controller.uomConversions,
                              rateController: line.rateController,
                              descriptionController: line.descriptionController,
                              qtyController: line.qtyController,
                              setUom: (u) => line.uomId = u,
                              currentUomId: line.uomId,
                              setTaxCodeId: (t) => line.taxCodeId = t,
                              setWarehouseId: (w) => line.warehouseId = w,
                              currentWarehouseId: line.warehouseId,
                              warehouses: controller.warehouses,
                            );
                          });
                          unawaited(
                            controller.syncWarehouseOptionsForLine(line),
                          );
                          unawaited(controller.syncBatchOptionsForLine(line));
                          unawaited(controller.syncSerialOptionsForLine(line));
                        },
                        validator: (_) =>
                            line.itemId == null ? 'Item is required' : null,
                      ),
                      Builder(
                        builder: (context) {
                          final options = controller.uomOptionsForItem(
                            line.itemId,
                          );
                          if (controller.canEdit && options.length == 1) {
                            final onlyId = options.first.id;
                            if (line.uomId != onlyId) {
                              line.uomId = onlyId;
                            }
                          }
                          return AppDropdownField<int>.fromMapped(
                            labelText: 'UOM',
                            mappedItems: options
                                .where((item) => item.id != null)
                                .map(
                                  (item) => AppDropdownItem(
                                    value: item.id!,
                                    label: item.toString(),
                                  ),
                                )
                                .toList(growable: false),
                            initialValue: line.uomId,
                            onChanged: (value) {
                              if (!controller.canEdit) {
                                return;
                              }
                              controller.State(() => line.uomId = value);
                            },
                            validator: (_) {
                              if (line.itemId == null) {
                                return 'Select item first';
                              }
                              return line.uomId == null
                                  ? 'UOM is required'
                                  : null;
                            },
                          );
                        },
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Warehouse',
                        mappedItems: controller
                            .warehouseOptionsForLine(line)
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.warehouseId,
                        onChanged: (value) {
                          if (!controller.canEdit) {
                            return;
                          }
                          controller.State(() {
                            line.warehouseId = value;
                            line.batchId = null;
                            line.serialId = null;
                          });
                          unawaited(controller.syncBatchOptionsForLine(line));
                          unawaited(controller.syncSerialOptionsForLine(line));
                        },
                        validator: (_) {
                          if (line.itemId == null) {
                            return 'Select item first';
                          }
                          if (!controller.isStockTrackedItem(line.itemId)) {
                            return null;
                          }
                          if (controller
                              .warehouseOptionsForLine(line)
                              .isEmpty) {
                            return 'No valid warehouse available for this item';
                          }
                          return line.warehouseId == null
                              ? 'Warehouse is required'
                              : null;
                        },
                      ),
                      if (controller.isBatchManagedItem(line.itemId))
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Batch',
                          mappedItems: controller
                              .batchOptionsForLine(line)
                              .map(
                                (batch) => AppDropdownItem<int>(
                                  value:
                                      int.tryParse(
                                        batch['batch_id']?.toString() ?? '',
                                      ) ??
                                      0,
                                  label: stringValue(
                                    batch,
                                    'batch_no',
                                    'Batch',
                                  ),
                                ),
                              )
                              .where((item) => item.value != 0)
                              .toList(growable: false),
                          initialValue: line.batchId,
                          onChanged: (value) {
                            if (!controller.canEdit) {
                              return;
                            }
                            controller.State(() {
                              line.batchId = value;
                              line.serialId = null;
                            });
                            unawaited(
                              controller.syncSerialOptionsForLine(line),
                            );
                          },
                          validator: (_) {
                            if (!controller.isBatchManagedItem(line.itemId)) {
                              return null;
                            }
                            if (line.warehouseId == null) {
                              return 'Select warehouse first';
                            }
                            final batches = controller.batchOptionsForLine(
                              line,
                            );
                            if (batches.isEmpty) {
                              return 'No batches found for the selected warehouse';
                            }
                            return line.batchId == null
                                ? 'Batch is required'
                                : null;
                          },
                        ),
                      if (controller.isSerialManagedItem(line.itemId))
                        AppSerialNumbersField(
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
                            final serialOptions = controller
                                .serialOptionsForLine(line);
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
                            final serialLabelSet = controller
                                .serialLabelSetForLine(line);
                            for (final value in values) {
                              if (!serialLabelSet.contains(
                                value.trim().toLowerCase(),
                              )) {
                                return 'Serial "$value" is not available for the selected warehouse/batch.';
                              }
                            }
                            return null;
                          },
                          onChanged: (values) {
                            controller.State(() {
                              if (controller.isSerialManagedItem(line.itemId)) {
                                controller.replaceLineWithSerialDrafts(
                                  line,
                                  values,
                                );
                              } else {
                                controller.setLineSerialNumbers(line, values);
                              }
                            });
                          },
                        ),
                      AppFormTextField(
                        labelText: 'Qty',
                        controller: line.qtyController,
                        enabled:
                            controller.canEdit &&
                            !controller.isSerialManagedItem(line.itemId),
                        onChanged: (_) => controller.State(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (_) {
                          final text = line.qtyController.text.trim();
                          if (text.isEmpty) {
                            return 'Qty is required';
                          }
                          final qty = double.tryParse(text);
                          if (qty == null || qty < 0) {
                            return 'Qty must be a valid non-negative number';
                          }
                          if (qty <= 0) {
                            return 'Qty must be greater than zero';
                          }
                          if (controller.isSerialManagedItem(line.itemId)) {
                            final serialCount = controller
                                .lineSerialNumbers(line)
                                .length;
                            if (line.warehouseId == null) {
                              return 'Select warehouse first';
                            }
                            if (serialCount == 0) {
                              return 'Add at least one serial number';
                            }
                            if (qty != serialCount) {
                              return 'Qty must match serial count';
                            }
                          }
                          return null;
                        },
                      ),
                      AppFormTextField(
                        labelText: 'Rate',
                        controller: line.rateController,
                        enabled: controller.canEdit,
                        onChanged: (_) => controller.State(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Rate'),
                          Validators.optionalNonNegativeNumber('Rate'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Discount %',
                        controller: line.discountController,
                        enabled: controller.canEdit,
                        onChanged: (_) => controller.State(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Discount %',
                        ),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Tax code',
                        mappedItems: controller.taxCodes
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.taxCodeId,
                        onChanged: (value) {
                          if (!controller.canEdit) {
                            return;
                          }
                          controller.State(() => line.taxCodeId = value);
                        },
                      ),
                      AppFormTextField(
                        labelText: 'Description',
                        controller: line.descriptionController,
                        enabled: controller.canEdit,
                      ),
                      AppFormTextField(
                        labelText: 'Remarks',
                        controller: line.remarksController,
                        enabled: controller.canEdit,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppUiConstants.spacingMd),
            buildTaxSummaryCard(context, controller),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (controller.selectedItem != null &&
                    !const {'draft', 'cancelled'}.contains(controller.status))
                  AppActionButton(
                    icon: Icons.print_outlined,
                    label: 'Print',
                    filled: false,
                    onPressed: () => controller.openPrintPreview(context),
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
                      onPressed: () => controller.docAction(
                        context,
                        () => controller.cancelInvoice(
                          controller.selectedItem!.id!,
                        ),
                      ),
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
