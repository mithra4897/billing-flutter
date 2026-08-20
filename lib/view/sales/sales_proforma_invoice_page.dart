import '../../screen.dart';

class SalesProformaInvoicePage extends StatefulWidget {
  const SalesProformaInvoicePage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialSalesQuotationId,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final int? initialSalesQuotationId;
  final Map<String, String> queryParameters;

  @override
  State<SalesProformaInvoicePage> createState() =>
      _SalesProformaInvoicePageState();
}

class _SalesProformaInvoicePageState extends State<SalesProformaInvoicePage> {
  late final String _controllerTag;
  bool _filtersVisible = false;

  SalesProformaInvoiceManagementController get _controller =>
      Get.find<SalesProformaInvoiceManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'SalesProformaInvoiceManagementController',
      scope: <String, Object?>{'identity': identityHashCode(this)},
    );
    Get.put(SalesProformaInvoiceManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _controller.initialize(
          initialId: widget.initialId,
          initialSalesQuotationId: widget.initialSalesQuotationId,
          editorOnly: widget.editorOnly,
        ),
      );
      _applyDashboardFilters(_controller);
    });
  }

  void _applyDashboardFilters(
    SalesProformaInvoiceManagementController controller,
  ) {
    controller.applyDashboardFilter(
      (widget.queryParameters['dashboard_filter'] ?? '').trim(),
    );
  }

  @override
  void didUpdateWidget(covariant SalesProformaInvoicePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !Get.isRegistered<SalesProformaInvoiceManagementController>(
              tag: _controllerTag,
            )) {
          return;
        }
        _applyDashboardFilters(_controller);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<SalesProformaInvoiceManagementController>(
        tag: _controllerTag,
      )) {
        Get.delete<SalesProformaInvoiceManagementController>(
          tag: _controllerTag,
          force: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesProformaInvoiceManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              setState(() {
                _filtersVisible = !_filtersVisible;
              });
            },
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: _filtersVisible,
          ),
          AdaptiveShellActionButton(
            onPressed: () {
              controller.resetForm();
              if (!Responsive.isDesktop(context)) {
                controller.workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New proforma invoice',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Sales Proforma Invoices',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildLineItemTable(
    SalesProformaInvoiceManagementController controller,
  ) {
    final itemOptions = controller.itemPickerOptions
        .map(
          (option) => ErpLinkFieldOption<int>(
            value: option.value,
            label: option.label,
            subtitle: option.subtitle,
            searchText: option.searchText ?? option.subtitle,
          ),
        )
        .toList(growable: false);

    final rows = List<ErpLineItemTableRow>.generate(controller.lines.length, (
      index,
    ) {
      final line = controller.lines[index];
      final amount = controller.taxBreakdownForLine(line).total;
      final availableUoms = controller.uomOptionsForItem(line.itemId);
      final uomOptions = availableUoms
          .where((item) => item.id != null)
          .map(
            (item) =>
                AppDropdownItem<int>(value: item.id!, label: item.toString()),
          )
          .toList(growable: false);
      final quantityAllowsFraction =
          availableUoms
              .cast<UomModel?>()
              .firstWhere((item) => item?.id == line.uomId, orElse: () => null)
              ?.isFractionAllowed ??
          true;
      if (controller.canEdit && uomOptions.length == 1) {
        final onlyId = uomOptions.first.value;
        if (line.uomId != onlyId) {
          line.uomId = onlyId;
        }
      }

      final itemSelection = line.itemId == null
          ? null
          : itemOptions.cast<ErpLinkFieldOption<int>?>().firstWhere(
              (option) => option?.value == line.itemId,
              orElse: () => null,
            );

      return ErpLineItemTableRow(
        rowKey: line,
        itemId: line.itemId,
        itemSelection: itemSelection,
        itemOptions: itemOptions,
        onItemChanged: controller.canEdit
            ? (value) => controller.setLineItemId(index, value)
            : null,
        itemValidator: (_) =>
            Validators.requiredSelectionField(line.itemId, 'Item'),
        uomId: line.uomId,
        uomOptions: uomOptions,
        onUomChanged: controller.canEdit
            ? (value) => controller.setLineUomId(index, value)
            : null,
        uomValidator: (_) => Validators.dependentSelectionField(
          prerequisite: line.itemId,
          prerequisiteName: 'item',
          value: line.uomId,
          fieldName: 'UOM',
        ),
        quantityAllowsFraction: quantityAllowsFraction,
        qtyController: line.qtyController,
        onQtyChanged: controller.canEdit
            ? (_) => controller.refreshComputedState()
            : null,
        qtyValidator: Validators.compose([
          Validators.required('Qty'),
          Validators.optionalNonNegativeNumber('Qty'),
        ]),
        rateController: line.rateController,
        onRateChanged: controller.canEdit
            ? (_) => controller.refreshComputedState()
            : null,
        rateValidator: Validators.compose([
          Validators.required('Rate'),
          Validators.optionalNonNegativeNumber('Rate'),
        ]),
        discountController: line.discountController,
        discountMode: line.discountMode,
        onDiscountModeChanged: controller.canEdit
            ? (value) {
                line.discountMode = value;
                controller.refreshComputedState();
              }
            : null,
        onDiscountChanged: controller.canEdit
            ? (_) => controller.refreshComputedState()
            : null,
        discountValidator: (value) => validateErpLineDiscount(
          value,
          mode: line.discountMode,
          gross:
              (Validators.parseFlexibleNumber(line.qtyController.text) ?? 0) *
              (Validators.parseFlexibleNumber(line.rateController.text) ?? 0),
        ),
        taxCodeId: line.taxCodeId,
        taxOptions: controller.taxCodeDropdownItems,
        onTaxCodeChanged: controller.canEdit
            ? (value) => controller.setLineTaxCodeId(index, value)
            : null,
        descriptionController: line.descriptionController,
        onDescriptionChanged: controller.canEdit ? (_) {} : null,
        remarksController: line.remarksController,
        onRemarksChanged: controller.canEdit ? (_) {} : null,
        amount: amount,
        deleteEnabled: controller.canEdit && controller.lines.length > 1,
      );
    });

    return ErpLineItemTable(
      lines: rows,
      onChanged: (_) {},
      onAddLine: controller.canEdit ? controller.addLine : null,
      onDeleteLine: controller.canEdit ? controller.removeLine : null,
      addButtonLabel: 'Add Line',
      visibleColumns: <ErpLineItemTableColumn>{
        ErpLineItemTableColumn.no,
        ErpLineItemTableColumn.item,
        ErpLineItemTableColumn.uom,
        ErpLineItemTableColumn.qty,
        ErpLineItemTableColumn.rate,
        ErpLineItemTableColumn.discount,
        ErpLineItemTableColumn.taxCode,
        ErpLineItemTableColumn.amount,
        if (controller.canEdit) ErpLineItemTableColumn.action,
      },
      footer: _buildTaxSummaryCard(controller),
      enabled: controller.canEdit,
    );
  }

  Widget _buildContent(
    BuildContext context,
    SalesProformaInvoiceManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading proforma invoices...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load proforma invoices',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    final selected = controller.selectedItem?.toJson() ?? const {};
    final double roundOff = controller.applyRoundOff
        ? (Validators.parseFlexibleNumber(
                    controller.roundOffController.text.trim(),
                  ) ??
                  0)
              .toDouble()
        : 0.0;
    final totalStr = formatAmount(controller.taxSummary().total + roundOff);
    final hasActiveSalesInvoice =
        ((controller.salesChain?['invoices'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .any(
              (item) =>
                  stringValue(item, 'invoice_status').trim().toLowerCase() !=
                  'cancelled',
            );
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Sales Proforma Invoices',
      editorTitle: controller.selectedItem == null
          ? 'New Proforma Invoice'
          : stringValue(selected, 'proforma_no', 'Proforma Invoice'),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<SalesProformaInvoiceModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No proforma invoices yet.',
        searchController: controller.searchController,
        searchHint: 'Search by number or customer',
        filterFields: [
          AppFormTextField(
            labelText: 'Search',
            controller: controller.searchController,
            hintText: 'Proforma invoice no or customer name',
          ),
          AppFormTextField(
            labelText: 'Date From',
            controller: controller.dateFromController,
            hintText: dateFormatHint(),
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
            validator: Validators.optionalDate('Date From'),
          ),
          AppFormTextField(
            labelText: 'Date To',
            controller: controller.dateToController,
            hintText: dateFormatHint(),
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
            validator: Validators.optionalDate('Date To'),
          ),
          AppActionButton(
            icon: Icons.clear_outlined,
            label: 'Clear',
            filled: false,
            onPressed: () {
              controller.searchController.clear();
              controller.dateFromController.clear();
              controller.dateToController.clear();
              controller.setStatusFilter('');
            },
          ),
        ],
        statusValue: controller.statusFilter,
        statusItems: SalesProformaInvoiceManagementController.listStatusFilter,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        showInlineFilters: _filtersVisible,
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'proforma_no', 'Draft'),
            subtitle: displayDate(nullableStringValue(data, 'proforma_date')),
            detail: salesListDetailWithCancelReason(
              data,
              quotationCustomerLabel(data),
              statusKey: 'proforma_status',
            ),
            trailing: salesStatusBadge(
              context,
              stringValue(data, 'proforma_status'),
            ),
            selected: selected,
            onTap: () => controller.selectDocument(item),
          );
        },
      ),
      editorBuilder: (context) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.selectedItem != null && !controller.canEdit) ...[
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingMd,
                ),
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
              hideProformaInvoiceChip: true,
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
                    salesStatusBadge(context, controller.status),
                  ],
                ),
              ),
            SettingsFormWrap(
              children: [
                AppDropdownField<int>.fromMapped(
                  labelText: 'Source Quotation',
                  initialValue: controller.salesQuotationId,
                  mappedItems: controller.quotationDropdownItems,
                  enabled:
                      controller.canEdit && controller.selectedItem == null,
                  onChanged: controller.setSalesQuotationId,
                  validator: (_) => controller.salesQuotationId == null
                      ? 'Source Quotation is required'
                      : null,
                ),
                ...buildSalesDocumentContextFields(
                  documentSeriesItems: controller.documentSeriesDropdownItems,
                  documentSeriesId: controller.documentSeriesId,
                  onDocumentSeriesChanged: controller.setDocumentSeriesId,
                ),
                GeneratedDocumentNumberField(
                  labelText: 'Proforma Invoice No',
                  controller: controller.proformaInvoiceNoController,
                  documentSeries: controller.seriesOptions(),
                  documentSeriesId: controller.documentSeriesId,
                  hintText: 'Leave blank if your series fills this in',
                  enabled: controller.canEdit,
                  validator: Validators.optionalMaxLength(
                    100,
                    'Proforma Invoice No',
                  ),
                ),
                AppFormTextField(
                  labelText: 'Proforma Invoice Date',
                  controller: controller.proformaInvoiceDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: controller.canEdit,
                  validator: Validators.compose([
                    Validators.required('Proforma Invoice Date'),
                    Validators.date('Proforma Invoice Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Valid Until',
                  controller: controller.validUntilController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: controller.canEdit,
                  validator: Validators.compose([
                    Validators.optionalDate('Valid Until'),
                    Validators.optionalDateOnOrAfter(
                      'Valid Until',
                      () =>
                          controller.proformaInvoiceDateController.text.trim(),
                      startFieldName: 'Proforma Invoice Date',
                    ),
                  ]),
                ),
                AppSwitchTile(
                  label: 'Direct Customer',
                  value: controller.isDirectCustomer,
                  onChanged: controller.canEdit
                      ? controller.setDirectCustomer
                      : null,
                ),
                if (controller.isDirectCustomer)
                  AppFormTextField(
                    labelText: 'Direct Customer Details',
                    controller: controller.directCustomerDetailsController,
                    enabled: controller.canEdit,
                    maxLines: 4,
                    validator: (value) {
                      if (!controller.isDirectCustomer) {
                        return null;
                      }
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Direct customer details are required';
                      }
                      return null;
                    },
                  )
                else
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
                    mappedItems: controller.customerDropdownItems,
                    initialValue: controller.customerPartyId,
                    onChanged: controller.setCustomerPartyId,
                    validator: (value) {
                      if (controller.isDirectCustomer) {
                        return null;
                      }
                      return Validators.requiredSelection('Customer')(value);
                    },
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
                AppFormTextField(
                  labelText: 'Round off',
                  controller: controller.roundOffController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  enabled: controller.canEdit && controller.applyRoundOff,
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) {
                      return null;
                    }
                    return Validators.parseFlexibleNumber(text) == null
                        ? 'Round off must be a valid number'
                        : null;
                  },
                  onChanged: (_) => controller.refreshComputedState(),
                ),
                AppSwitchTile(
                  label: 'Apply round off',
                  value: controller.applyRoundOff,
                  onChanged: controller.canEdit
                      ? controller.setApplyRoundOff
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              value: controller.isActive,
              onChanged: controller.canEdit ? controller.setIsActive : null,
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            GetBuilder<SalesProformaInvoiceManagementController>(
              tag: _controllerTag,
              id: SalesProformaInvoiceManagementController.lineItemsSectionId,
              builder: (controller) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildLineItemTable(controller)],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SalesDocumentActionRow(
              actions: [
                if (controller.selectedItem != null &&
                    controller.status != 'cancelled')
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
                      allowTemplateEditing: true,
                    ),
                  ),
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedItem == null
                      ? 'Save Proforma Invoice'
                      : 'Update Proforma Invoice',
                  onPressed:
                      controller.canEdit && !controller.prefillingQuotation
                      ? () => controller.save(context)
                      : null,
                  busy: controller.saving,
                ),
                if (controller.selectedItem != null &&
                    controller.status == 'draft') ...[
                  if (controller.status == 'draft')
                    AppActionButton(
                      icon: Icons.publish_outlined,
                      label: 'Submit',
                      filled: false,
                      onPressed: () => controller.postSelected(context),
                    ),
                ],
                if (controller.selectedItem != null) ...[
                  if (controller.status == 'draft')
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: () => controller.deleteSelected(context),
                    ),
                  if (controller.status == 'posted' &&
                      controller.selectedItem?.convertedSalesInvoiceId ==
                          null &&
                      !hasActiveSalesInvoice)
                    AppActionButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'Create Invoice',
                      filled: false,
                      onPressed: () => controller.convertSelected(context),
                    ),
                  if (controller.status == 'posted' &&
                      controller.selectedItem?.convertedSalesInvoiceId ==
                          null &&
                      !hasActiveSalesInvoice)
                    AppActionButton(
                      icon: Icons.block_outlined,
                      label: 'Cancel',
                      filled: false,
                      onPressed: () => controller.cancelSelected(context),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
      editor: const SizedBox.shrink(),
    );
  }

  Widget _buildTaxSummaryCard(
    SalesProformaInvoiceManagementController controller,
  ) {
    final summary = controller.taxSummary();
    final double roundOff = controller.applyRoundOff
        ? (Validators.parseFlexibleNumber(
                    controller.roundOffController.text.trim(),
                  ) ??
                  0)
              .toDouble()
        : 0.0;
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
          : 'Includes round off ${formatAmount(roundOff)}',
    );
  }
}
