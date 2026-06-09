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
    Get.delete<PurchaseInvoiceManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
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
    final taxSummary = controller.invoiceTaxSummary();
    final summaryTotal = taxSummary.total;
    final currency = controller.currencyCodeController.text.trim().isEmpty
        ? 'INR'
        : controller.currencyCodeController.text.trim();
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
                      AppFormTextField(
                        labelText: 'Invoice No',
                        controller: controller.invoiceNoController,
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
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Adjustment Account',
                        mappedItems: controller.accounts
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.adjustmentAccountId,
                        onChanged: controller.setAdjustmentAccountId,
                      ),
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
                        labelText: 'Currency',
                        controller: controller.currencyCodeController,
                      ),
                      AppFormTextField(
                        labelText: 'Exchange Rate',
                        controller: controller.exchangeRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Exchange Rate',
                        ),
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
                  Row(
                    children: [
                      Text(
                        'Lines',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      AppActionButton(
                        icon: Icons.add_outlined,
                        label: 'Add Line',
                        onPressed: controller.isSelectedInvoiceReadOnly
                            ? null
                            : controller.addLine,
                        filled: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  ...List<Widget>.generate(controller.lines.length, (index) {
                    final line = controller.lines[index];
                    return Padding(
                      key: ValueKey<String>(
                        '${line.itemId}_${line.purchaseOrderLineId}_${line.purchaseReceiptLineId}_${line.invoicedQty}_$index',
                      ),
                      padding: const EdgeInsets.only(
                        bottom: AppUiConstants.spacingSm,
                      ),
                      child: PurchaseCompactLineCard(
                        index: index,
                        total: controller.lines.length,
                        removeEnabled: controller.lines.length > 1,
                        onRemove: () => controller.removeLine(index),
                        child: PurchaseCompactFieldGrid(
                          children: [
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
                              onChanged: (value) => controller.updateLine(
                                index,
                                line.copyWith(
                                  itemId: value ?? 0,
                                  uomId:
                                      controller.resolveDefaultUom(
                                        value,
                                        line.uomId,
                                      ) ??
                                      line.uomId,
                                ),
                              ),
                              validator: (_) =>
                                  Validators.requiredSelectionOrPositiveIdField(
                                    line.itemId,
                                    'Item',
                                  ),
                            ),
                            AppDropdownField<int>.fromMapped(
                              labelText: 'Warehouse',
                              mappedItems: controller.warehouses
                                  .where((item) => item.id != null)
                                  .map(
                                    (item) => AppDropdownItem(
                                      value: item.id!,
                                      label: item.toString(),
                                    ),
                                  )
                                  .toList(growable: false),
                              initialValue: line.warehouseId,
                              onChanged: (value) => controller.updateLine(
                                index,
                                line.copyWith(warehouseId: value),
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final options = controller.uomOptionsForItem(
                                  line.itemId,
                                );
                                if (options.length == 1) {
                                  final onlyId = options.first.id;
                                  if (line.uomId != onlyId) {
                                    controller.updateLine(
                                      index,
                                      line.copyWith(uomId: onlyId),
                                    );
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
                                  initialValue: line.uomId == 0
                                      ? null
                                      : line.uomId,
                                  onChanged: (value) => controller.updateLine(
                                    index,
                                    line.copyWith(uomId: value ?? 0),
                                  ),
                                  validator: (_) =>
                                      Validators.requiredSelectionOrPositiveIdField(
                                        line.uomId,
                                        'UOM',
                                      ),
                                );
                              },
                            ),
                            TextFormField(
                              initialValue: line.invoicedQty.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Invoiced Qty',
                              ),
                              inputFormatters: const <TextInputFormatter>[
                                NumericInputFormatter(),
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (value) => controller.updateLine(
                                index,
                                line.copyWith(
                                  invoicedQty:
                                      Validators.parseFlexibleNumber(value) ??
                                      line.invoicedQty,
                                ),
                              ),
                              validator: Validators.compose([
                                Validators.required('Invoiced Qty'),
                                Validators.optionalNonNegativeNumber(
                                  'Invoiced Qty',
                                ),
                              ]),
                            ),
                            TextFormField(
                              initialValue: line.rate.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Rate',
                              ),
                              inputFormatters: const <TextInputFormatter>[
                                NumericInputFormatter(),
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (value) => controller.updateLine(
                                index,
                                line.copyWith(
                                  rate:
                                      Validators.parseFlexibleNumber(value) ??
                                      line.rate,
                                ),
                              ),
                              validator: Validators.compose([
                                Validators.required('Rate'),
                                Validators.optionalNonNegativeNumber('Rate'),
                              ]),
                            ),
                            TextFormField(
                              initialValue: (line.discountPercent ?? 0)
                                  .toString(),
                              decoration: const InputDecoration(
                                labelText: 'Discount %',
                              ),
                              inputFormatters: const <TextInputFormatter>[
                                NumericInputFormatter(),
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (value) => controller.updateLine(
                                index,
                                line.copyWith(
                                  discountPercent: nullIfEmpty(value) == null
                                      ? null
                                      : Validators.parseFlexibleNumber(value),
                                ),
                              ),
                            ),
                            AppDropdownField<int>.fromMapped(
                              labelText: 'Tax Code',
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
                              onChanged: (value) => controller.updateLine(
                                index,
                                line.copyWith(taxCodeId: value),
                              ),
                            ),
                            TextFormField(
                              initialValue: line.description ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              maxLines: 2,
                              onChanged: (value) => controller.updateLine(
                                index,
                                line.copyWith(description: nullIfEmpty(value)),
                              ),
                            ),
                            TextFormField(
                              initialValue: line.remarks ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Remarks',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 2,
                              onChanged: (value) => controller.updateLine(
                                index,
                                line.copyWith(remarks: nullIfEmpty(value)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  GstSummaryCard(
                    taxable: taxSummary.taxable,
                    cgst: taxSummary.cgst,
                    sgst: taxSummary.sgst,
                    igst: taxSummary.igst,
                    cess: 0,
                    total: summaryTotal,
                    currencyCode: currency,
                    subtitle: controller.isSelectedInvoiceReadOnly
                        ? 'Saved invoice totals from the posted document.'
                        : controller.applyRoundOff &&
                              (Validators.parseFlexibleNumber(
                                        controller.roundOffController.text
                                            .trim(),
                                      ) ??
                                      0) !=
                                  0
                        ? 'Live totals for the current purchase invoice lines. Includes round off ${((Validators.parseFlexibleNumber(controller.roundOffController.text.trim()) ?? 0)).toStringAsFixed(2)}${((Validators.parseFlexibleNumber(controller.adjustmentAmountController.text.trim()) ?? 0) != 0) ? ' and adjustment ${((Validators.parseFlexibleNumber(controller.adjustmentAmountController.text.trim()) ?? 0)).toStringAsFixed(2)}' : ''}.'
                        : ((Validators.parseFlexibleNumber(
                                    controller.adjustmentAmountController.text
                                        .trim(),
                                  ) ??
                                  0) !=
                              0)
                        ? 'Live totals for the current purchase invoice lines. Includes adjustment ${((Validators.parseFlexibleNumber(controller.adjustmentAmountController.text.trim()) ?? 0)).toStringAsFixed(2)}.'
                        : 'Live totals for the current purchase invoice lines.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (controller.selectedItem != null &&
                    !const {'draft', 'cancelled'}.contains(
                      (controller.selectedItem?.invoiceStatus ?? '')
                          .toLowerCase(),
                    ))
                  AppActionButton(
                    icon: Icons.print_outlined,
                    label: 'Print',
                    filled: false,
                    onPressed: () => controller.openPrintPreview(context),
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
}
