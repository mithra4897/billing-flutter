import '../../controller/purchase/purchase_invoice_management_controller.dart';
import '../../screen.dart';

class PurchaseInvoicePage extends StatefulWidget {
  const PurchaseInvoicePage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PurchaseInvoicePage> createState() => _PurchaseInvoicePageState();
}

class _PurchaseInvoicePageState extends State<PurchaseInvoicePage> {
  late final String _controllerTag;

  PurchaseInvoiceManagementController get _controller =>
      Get.find<PurchaseInvoiceManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'PurchaseInvoiceManagementController',
      scope: uniqueControllerScope(<String, Object?>{
        'identity': identityHashCode(this),
      }),
    );
    Get.put(PurchaseInvoiceManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_controller.initialize(initialId: widget.initialId));
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<PurchaseInvoiceManagementController>(
        tag: _controllerTag,
      )) {
        Get.delete<PurchaseInvoiceManagementController>(
          tag: _controllerTag,
          force: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchaseInvoiceManagementController>(
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
            label: 'New Invoice',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Purchase Invoices',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildLineItemTable(PurchaseInvoiceManagementController controller) {
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

    final warehouseOptions = controller.warehouses
        .where((item) => item.id != null)
        .map(
          (item) =>
              AppDropdownItem<int>(value: item.id!, label: item.toString()),
        )
        .toList(growable: false);

    final taxOptions = controller.taxCodes
        .where((item) => item.id != null)
        .map(
          (item) =>
              AppDropdownItem<int>(value: item.id!, label: item.toString()),
        )
        .toList(growable: false);

    final rows = List<ErpLineItemTableRow>.generate(controller.lines.length, (
      index,
    ) {
      final line = controller.lines[index];
      final amount = controller.taxBreakdownForLine(line).total;
      final uomOptions = controller
          .uomOptionsForItem(line.itemId)
          .where((item) => item.id != null)
          .map(
            (item) =>
                AppDropdownItem<int>(value: item.id!, label: item.toString()),
          )
          .toList(growable: false);

      if (uomOptions.length == 1) {
        final onlyId = uomOptions.first.value;
        if (line.uomId != onlyId) {
          controller.updateLine(index, line.copyWith(uomId: onlyId));
        }
      }

      final itemSelection = line.itemId == 0
          ? null
          : itemOptions.cast<ErpLinkFieldOption<int>?>().firstWhere(
              (item) => item?.value == line.itemId,
              orElse: () => null,
            );

      return ErpLineItemTableRow(
        rowKey: ValueKey<String>(
          '${line.itemId}_${line.purchaseOrderLineId}_${line.purchaseReceiptLineId}_${line.invoicedQty}_$index',
        ),
        itemId: line.itemId == 0 ? null : line.itemId,
        itemSelection: itemSelection,
        itemOptions: itemOptions,
        onItemChanged: controller.isSelectedInvoiceReadOnly
            ? null
            : (value) => controller.updateLine(
                index,
                line.copyWith(
                  itemId: value ?? 0,
                  uomId:
                      controller.resolveDefaultUom(value, line.uomId) ??
                      line.uomId,
                ),
              ),
        itemValidator: (_) =>
            Validators.requiredSelectionOrPositiveIdField(line.itemId, 'Item'),
        warehouseId: line.warehouseId,
        warehouseOptions: warehouseOptions,
        onWarehouseChanged: controller.isSelectedInvoiceReadOnly
            ? null
            : (value) => controller.updateLine(
                index,
                line.copyWith(warehouseId: value),
              ),
        uomId: line.uomId == 0 ? null : line.uomId,
        uomOptions: uomOptions,
        onUomChanged: controller.isSelectedInvoiceReadOnly
            ? null
            : (value) => controller.updateLine(
                index,
                line.copyWith(uomId: value ?? 0),
              ),
        uomValidator: (_) =>
            Validators.requiredSelectionOrPositiveIdField(line.uomId, 'UOM'),
        taxCodeId: line.taxCodeId,
        taxOptions: taxOptions,
        onTaxCodeChanged: controller.isSelectedInvoiceReadOnly
            ? null
            : (value) =>
                  controller.updateLine(index, line.copyWith(taxCodeId: value)),
        amount: amount,
        deleteEnabled:
            !controller.isSelectedInvoiceReadOnly &&
            controller.lines.length > 1,
        cellWidgets: <ErpLineItemTableColumn, Widget>{
          ErpLineItemTableColumn.qty: ErpLineItemTextCell(
            key: ValueKey('purchase-invoice-qty-$index'),
            initialValue: line.invoicedQty.toString(),
            hintText: 'Invoiced Qty',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => controller.updateLine(
              index,
              line.copyWith(
                invoicedQty:
                    Validators.parseFlexibleNumber(value) ?? line.invoicedQty,
              ),
            ),
            validator: (value) {
              final parsed = Validators.parseFlexibleNumber(value);
              if ((parsed == null || parsed <= 0) &&
                  controller.lineAllowsBlankQty(line.itemId)) {
                return null;
              }
              return Validators.compose([
                Validators.required('Invoiced Qty'),
                Validators.optionalNonNegativeNumber('Invoiced Qty'),
              ])(value);
            },
          ),
          ErpLineItemTableColumn.rate: ErpLineItemTextCell(
            key: ValueKey('purchase-invoice-rate-$index'),
            initialValue: line.rate.toString(),
            hintText: 'Rate',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => controller.updateLine(
              index,
              line.copyWith(
                rate: Validators.parseFlexibleNumber(value) ?? line.rate,
              ),
            ),
            validator: Validators.compose([
              Validators.required('Rate'),
              Validators.optionalNonNegativeNumber('Rate'),
            ]),
          ),
          ErpLineItemTableColumn.discount: ErpLineItemTextCell(
            key: ValueKey('purchase-invoice-discount-$index'),
            initialValue: (line.discountPercent ?? 0).toString(),
            hintText: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => controller.updateLine(
              index,
              line.copyWith(
                discountPercent: nullIfEmpty(value) == null
                    ? null
                    : Validators.parseFlexibleNumber(value),
              ),
            ),
          ),
        },
      );
    });

    final taxSummary = controller.invoiceTaxSummary();
    final summaryTotal = taxSummary.total;

    return ErpLineItemTable(
      title: 'Lines',
      lines: rows,
      onAddLine: controller.isSelectedInvoiceReadOnly
          ? null
          : controller.addLine,
      onDeleteLine: controller.isSelectedInvoiceReadOnly
          ? null
          : controller.removeLine,
      addButtonLabel: 'Add Line',
      visibleColumns: const <ErpLineItemTableColumn>{
        ErpLineItemTableColumn.no,
        ErpLineItemTableColumn.item,
        ErpLineItemTableColumn.warehouse,
        ErpLineItemTableColumn.uom,
        ErpLineItemTableColumn.qty,
        ErpLineItemTableColumn.rate,
        ErpLineItemTableColumn.discount,
        ErpLineItemTableColumn.taxCode,
        ErpLineItemTableColumn.amount,
        ErpLineItemTableColumn.action,
      },
      columnLabels: const <ErpLineItemTableColumn, String>{
        ErpLineItemTableColumn.qty: 'Invoiced Qty',
        ErpLineItemTableColumn.taxCode: 'Tax Code',
      },
      enabled: !controller.isSelectedInvoiceReadOnly,
      footer: GstSummaryCard(
        taxable: taxSummary.taxable,
        cgst: taxSummary.cgst,
        sgst: taxSummary.sgst,
        igst: taxSummary.igst,
        cess: taxSummary.cess,
        total: summaryTotal,
        currencyCode: 'INR',
        subtitle: controller.isSelectedInvoiceReadOnly
            ? 'Saved invoice totals from the posted document.'
            : controller.applyRoundOff &&
                  (Validators.parseFlexibleNumber(
                            controller.roundOffController.text.trim(),
                          ) ??
                          0) !=
                      0
            ? 'Live totals for the current purchase invoice lines. Includes round off ${((Validators.parseFlexibleNumber(controller.roundOffController.text.trim()) ?? 0)).toStringAsFixed(2)}${((Validators.parseFlexibleNumber(controller.adjustmentAmountController.text.trim()) ?? 0) != 0) ? ' and adjustment ${((Validators.parseFlexibleNumber(controller.adjustmentAmountController.text.trim()) ?? 0)).toStringAsFixed(2)}' : ''}.'
            : ((Validators.parseFlexibleNumber(
                        controller.adjustmentAmountController.text.trim(),
                      ) ??
                      0) !=
                  0)
            ? 'Live totals for the current purchase invoice lines. Includes adjustment ${((Validators.parseFlexibleNumber(controller.adjustmentAmountController.text.trim()) ?? 0)).toStringAsFixed(2)}.'
            : 'Live totals for the current purchase invoice lines.',
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PurchaseInvoiceManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading purchase invoices...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase invoices',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Purchase Invoices',
      editorTitle: controller.selectedItem == null
          ? 'New Purchase Invoice'
          : (controller.selectedItem!.invoiceNo ?? 'Purchase Invoice'),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<PurchaseInvoiceModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No purchase invoices found.',
        searchController: controller.searchController,
        searchHint: 'Search invoices',
        statusValue: controller.statusFilter,
        statusItems: PurchaseInvoiceManagementController.statusItems,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        headerActions: [
          IconButton(
            onPressed: () => _openFilterPanel(context, controller),
            icon: Icon(
              Icons.filter_alt_outlined,
              color:
                  controller.filterSupplierId != null ||
                      controller.filterOverdue
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: 'Advanced Filters',
          ),
        ],
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: nullableStringValue(data, 'invoice_no') ?? 'Draft Invoice',
            subtitle: [
              displayDate(nullableStringValue(data, 'invoice_date')),
              purchaseStatusLabel(nullableStringValue(data, 'invoice_status')),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail:
                nullableStringValue(data, 'purchase_receipt_no') ??
                nullableStringValue(data, 'purchase_order_no') ??
                stringValue(data, 'supplier_name'),
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
            if (controller.isSelectedInvoiceReadOnly) ...[
              Text(
                purchaseReadOnlyMessage(
                  'purchase invoice',
                  controller.selectedItem?.invoiceStatus,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            IgnorePointer(
              ignoring: controller.isSelectedInvoiceReadOnly,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        labelText: 'Invoice No',
                        controller: controller.invoiceNoController,
                        documentSeries: controller.seriesOptions(),
                        documentSeriesId: controller.documentSeriesId,
                        hintText: 'Auto-generated on save',
                        validator: Validators.optionalMaxLength(
                          100,
                          'Invoice No',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Invoice Date',
                        controller: controller.invoiceDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
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
                        labelText: 'Supplier',
                        doctypeLabel: 'Supplier',
                        allowCreate: true,
                        onNavigateToCreateNew: (name) {
                          final uri = Uri(
                            path: '/parties',
                            queryParameters: {
                              'new': '1',
                              'party_context': 'supplier',
                              if (name.trim().isNotEmpty)
                                'party_name': name.trim(),
                            },
                          );
                          openModuleShellRoute(context, uri.toString());
                        },
                        mappedItems: controller.suppliers
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.supplierPartyId,
                        onChanged: controller.setSupplierPartyId,
                        validator: Validators.requiredSelection('Supplier'),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Purchase Order',
                        mappedItems: controller
                            .invoiceOrderOptions()
                            .where(
                              (item) => intValue(item.toJson(), 'id') != null,
                            )
                            .map(
                              (item) => AppDropdownItem(
                                value: intValue(item.toJson(), 'id')!,
                                label: stringValue(
                                  item.toJson(),
                                  'order_no',
                                  'Order',
                                ),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.purchaseOrderId,
                        onChanged: controller.handlePurchaseOrderChanged,
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Purchase Receipt',
                        mappedItems: controller
                            .invoiceReceiptOptions()
                            .where(
                              (item) => intValue(item.toJson(), 'id') != null,
                            )
                            .map(
                              (item) => AppDropdownItem(
                                value: intValue(item.toJson(), 'id')!,
                                label: stringValue(
                                  item.toJson(),
                                  'receipt_no',
                                  'Receipt',
                                ),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.purchaseReceiptId,
                        onChanged: controller.handlePurchaseReceiptChanged,
                      ),
                      // Future option:
                      // AppDropdownField<int>.fromMapped(
                      //   labelText: 'Adjustment Account',
                      //   mappedItems: controller.accounts
                      //       .where((item) => item.id != null)
                      //       .map(
                      //         (item) => AppDropdownItem(
                      //           value: item.id!,
                      //           label: item.toString(),
                      //         ),
                      //       )
                      //       .toList(growable: false),
                      //   initialValue: controller.adjustmentAccountId,
                      //   onChanged: controller.setAdjustmentAccountId,
                      // ),
                      AppFormTextField(
                        labelText: 'Supplier Ref No',
                        controller: controller.supplierReferenceNoController,
                      ),
                      AppFormTextField(
                        labelText: 'Supplier Ref Date',
                        controller: controller.supplierReferenceDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.optionalDate('Supplier Ref Date'),
                      ),
                      AppFormTextField(
                        labelText: 'Round off',
                        controller: controller.roundOffController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        enabled: controller.applyRoundOff,
                        onChanged: (_) => controller.refreshComputedState(),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return null;
                          }
                          if (Validators.parseFlexibleNumber(trimmed) == null) {
                            return 'Round off must be a valid number';
                          }
                          return null;
                        },
                      ),
                      AppSwitchTile(
                        label: 'Apply round off',
                        value: controller.applyRoundOff,
                        onChanged: controller.setApplyRoundOff,
                      ),
                      AppFormTextField(
                        labelText: 'Adjustment amount',
                        controller: controller.adjustmentAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        onChanged: (_) => controller.refreshComputedState(),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return null;
                          }
                          if (Validators.parseFlexibleNumber(trimmed) == null) {
                            return 'Adjustment amount must be a valid number';
                          }
                          return null;
                        },
                      ),
                      AppFormTextField(
                        labelText: 'Adjustment remarks',
                        controller: controller.adjustmentRemarksController,
                        maxLines: 2,
                      ),
                      AppFormTextField(
                        labelText: 'Notes',
                        controller: controller.notesController,
                        maxLines: 3,
                      ),
                      AppFormTextField(
                        labelText: 'Terms & Conditions',
                        controller: controller.termsController,
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
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (controller.selectedItem != null &&
                    !const {'cancelled'}.contains(
                      (controller.selectedItem?.invoiceStatus ?? '')
                          .toLowerCase(),
                    ))
                  AppActionButton(
                    icon:
                        (controller.selectedItem?.invoiceStatus ?? '')
                                .toLowerCase() ==
                            'draft'
                        ? Icons.preview_outlined
                        : Icons.print_outlined,
                    label:
                        (controller.selectedItem?.invoiceStatus ?? '')
                                .toLowerCase() ==
                            'draft'
                        ? 'Preview'
                        : 'Print',
                    filled: false,
                    onPressed: () => controller.openPrintPreview(
                      context,
                      allowPrint:
                          (controller.selectedItem?.invoiceStatus ?? '')
                              .toLowerCase() !=
                          'draft',
                      allowDownload:
                          (controller.selectedItem?.invoiceStatus ?? '')
                              .toLowerCase() !=
                          'draft',
                      allowTemplateEditing:
                          (controller.selectedItem?.invoiceStatus ?? '')
                              .toLowerCase() !=
                          'draft',
                    ),
                  ),
                if (!controller.isSelectedInvoiceReadOnly)
                  AppActionButton(
                    icon: Icons.save_outlined,
                    label: controller.selectedItem == null
                        ? 'Save Invoice'
                        : 'Update Invoice',
                    onPressed: controller.canEditSelectedInvoice
                        ? () => controller.save(context)
                        : null,
                    busy: controller.saving,
                  ),
                Builder(
                  builder: (_) {
                    final status =
                        (controller.selectedItem?.invoiceStatus ?? '')
                            .toLowerCase();
                    final balance = controller.selectedItem?.balanceAmount ?? 0;
                    final canMakePayment =
                        controller.selectedItem != null &&
                        status != 'draft' &&
                        status != 'cancelled' &&
                        balance > 0;
                    final canPost =
                        controller.selectedItem != null && status == 'draft';
                    final canCancel =
                        controller.selectedItem != null &&
                        (status == 'draft' || status == 'posted');

                    return Wrap(
                      spacing: AppUiConstants.spacingSm,
                      runSpacing: AppUiConstants.spacingSm,
                      children: [
                        if (canMakePayment)
                          AppActionButton(
                            icon: Icons.payments_outlined,
                            label: 'Make payment',
                            filled: false,
                            onPressed: () {
                              final navigate = ShellRouteScope.maybeOf(context);
                              final route =
                                  '/purchase/payments/new?invoice_id=${controller.selectedItem!.id}';
                              if (navigate != null) {
                                navigate(route);
                                return;
                              }
                              Navigator.of(context).pushNamed(route);
                            },
                          ),
                        if (canPost)
                          AppActionButton(
                            icon: Icons.publish_outlined,
                            label: 'Post',
                            filled: false,
                            onPressed: () => controller.docAction(
                              context,
                              () => PurchaseService().postInvoice(
                                controller.selectedItem!.id!,
                              ),
                            ),
                          ),
                        if (canCancel)
                          AppActionButton(
                            icon: Icons.cancel_outlined,
                            label: 'Cancel',
                            filled: false,
                            onPressed: () => controller.docAction(
                              context,
                              () => PurchaseService().cancelInvoice(
                                controller.selectedItem!.id!,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    PurchaseInvoiceManagementController controller,
  ) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600
        ? 16.0
        : screenWidth > 800
        ? (screenWidth - 760) / 2
        : 24.0;
    final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;

    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                dialogPadding,
                dialogPadding,
                dialogPadding,
                MediaQuery.of(dialogContext).viewInsets.bottom + dialogPadding,
              ),
              child: GetBuilder<PurchaseInvoiceManagementController>(
                tag: _controllerTag,
                builder: (dialogController) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filter Invoices',
                            style: Theme.of(dialogContext).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          tooltip: 'Close',
                          icon: const Icon(Icons.close),
                          color: appTheme.mutedText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SettingsFormWrap(
                      children: [
                        AppDropdownField<int?>.fromMapped(
                          labelText: 'Supplier',
                          mappedItems: [
                            const AppDropdownItem<int?>(
                              value: null,
                              label: 'All Suppliers',
                            ),
                            ...dialogController.suppliers.map(
                              (s) => AppDropdownItem<int?>(
                                value: s.id,
                                label: s.partyName ?? '',
                              ),
                            ),
                          ],
                          initialValue: dialogController.filterSupplierId,
                          onChanged: dialogController.setFilterSupplierId,
                        ),
                        AppSwitchTile(
                          label: 'Overdue Invoices Only',
                          subtitle:
                              'Show posted/partially paid invoices past their due date',
                          value: dialogController.filterOverdue,
                          onChanged: dialogController.setFilterOverdue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Apply Filter'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            dialogController.clearFilters();
                            Navigator.of(dialogContext).pop(true);
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
