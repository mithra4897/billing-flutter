import '../../controller/sales/sales_quotation_management_controller.dart';
import '../../screen.dart';

class SalesQuotationPage extends StatefulWidget {
  const SalesQuotationPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialCrmOpportunityId,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final int? initialCrmOpportunityId;
  final Map<String, String> queryParameters;

  @override
  State<SalesQuotationPage> createState() => _SalesQuotationPageState();
}

class _SalesQuotationPageState extends State<SalesQuotationPage> {
  late final String _controllerTag;

  SalesQuotationManagementController get _controller =>
      Get.find<SalesQuotationManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'SalesQuotationManagementController',
      scope: <String, Object?>{'identity': identityHashCode(this)},
    );
    Get.put(SalesQuotationManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _controller.initialize(
          initialId: widget.initialId,
          initialCrmOpportunityId: widget.initialCrmOpportunityId,
          editorOnly: widget.editorOnly,
        ),
      );
      _applyDashboardFilters(_controller);
    });
  }

  void _applyDashboardFilters(SalesQuotationManagementController controller) {
    controller.applyDashboardFilter(
      (widget.queryParameters['dashboard_filter'] ?? '').trim(),
    );
  }

  @override
  void didUpdateWidget(covariant SalesQuotationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !Get.isRegistered<SalesQuotationManagementController>(
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
      if (Get.isRegistered<SalesQuotationManagementController>(
        tag: _controllerTag,
      )) {
        Get.delete<SalesQuotationManagementController>(
          tag: _controllerTag,
          force: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesQuotationManagementController>(
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
            label: 'New Quote',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Sales Quotations',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    SalesQuotationManagementController controller,
  ) {
    return openSalesSearchStatusFilterPanel(
      context: context,
      title: 'Filter Sales Quotations',
      searchController: controller.searchController,
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      searchHint: 'Search by number or customer',
      status: controller.statusFilter,
      statusItems: SalesQuotationManagementController.listStatusFilter,
      onApply: (search, status, dateFrom, dateTo) {
        controller.searchController.text = search;
        controller.dateFromController.text = dateFrom;
        controller.dateToController.text = dateTo;
        controller.setStatusFilter(status);
      },
      onClear: () {
        controller.searchController.clear();
        controller.dateFromController.clear();
        controller.dateToController.clear();
        controller.setStatusFilter('');
      },
    );
  }

  Widget _buildLineItemTable(SalesQuotationManagementController controller) {
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
        onDiscountChanged: controller.canEdit
            ? (_) => controller.refreshComputedState()
            : null,
        discountValidator: Validators.optionalNonNegativeNumber('Discount %'),
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
      visibleColumns: const <ErpLineItemTableColumn>{
        ErpLineItemTableColumn.no,
        ErpLineItemTableColumn.item,
        ErpLineItemTableColumn.uom,
        ErpLineItemTableColumn.qty,
        ErpLineItemTableColumn.rate,
        ErpLineItemTableColumn.discount,
        ErpLineItemTableColumn.taxCode,
        ErpLineItemTableColumn.amount,
        ErpLineItemTableColumn.action,
      },
      footer: _buildTaxSummaryCard(controller),
      enabled: controller.canEdit,
    );
  }

  Widget _buildContent(
    BuildContext context,
    SalesQuotationManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading quotations...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load quotations',
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
    final selectedQuotationId = intValue(selected, 'id');
    final chainOrders =
        ((controller.salesChain?['orders'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
    final hasExistingOrder = selectedQuotationId == null
        ? chainOrders.isNotEmpty
        : chainOrders.any(
            (order) =>
                intValue(order, 'sales_quotation_id') == selectedQuotationId,
          );

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Sales Quotations',
      editorTitle: controller.selectedItem == null
          ? 'New Quotation'
          : stringValue(selected, 'quotation_no', 'Quotation'),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<SalesQuotationModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No quotations yet.',
        searchController: controller.searchController,
        searchHint: 'Search by number or customer',
        statusValue: controller.statusFilter,
        statusItems: SalesQuotationManagementController.listStatusFilter,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        showInlineFilters: false,
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'quotation_no', 'Draft'),
            subtitle: displayDate(nullableStringValue(data, 'quotation_date')),
            detail: salesListDetailWithCancelReason(
              data,
              quotationCustomerLabel(data),
              statusKey: 'quotation_status',
            ),
            trailing: salesStatusBadge(
              context,
              stringValue(data, 'quotation_status'),
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
              hideQuotationChip: true,
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
                ...buildSalesDocumentContextFields(
                  documentSeriesItems: controller.documentSeriesDropdownItems,
                  documentSeriesId: controller.documentSeriesId,
                  onDocumentSeriesChanged: controller.setDocumentSeriesId,
                ),
                GeneratedDocumentNumberField(
                  labelText: 'Quotation No',
                  controller: controller.quotationNoController,
                  documentSeries: controller.seriesOptions(),
                  documentSeriesId: controller.documentSeriesId,
                  hintText: 'Leave blank if your series fills this in',
                  enabled: controller.canEdit,
                  validator: Validators.optionalMaxLength(100, 'Quotation No'),
                ),
                AppFormTextField(
                  labelText: 'Quotation Date',
                  controller: controller.quotationDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: controller.canEdit,
                  validator: Validators.compose([
                    Validators.required('Quotation Date'),
                    Validators.date('Quotation Date'),
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
                      () => controller.quotationDateController.text.trim(),
                      startFieldName: 'Quotation Date',
                    ),
                  ]),
                ),
                ...buildSalesCustomerCommercialFields(
                  context: context,
                  canEdit: controller.canEdit,
                  customerItems: controller.customerDropdownItems,
                  customerPartyId: controller.customerPartyId,
                  onCustomerChanged: controller.setCustomerPartyId,
                  customerRefNoController: controller.customerRefNoController,
                  customerRefDateController:
                      controller.customerRefDateController,
                  notesController: controller.notesController,
                  termsController: controller.termsController,
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
            GetBuilder<SalesQuotationManagementController>(
              tag: _controllerTag,
              id: SalesQuotationManagementController.lineItemsSectionId,
              builder: (controller) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildLineItemTable(controller)],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SalesDocumentActionRow(
              actions: [
                if (controller.selectedItem != null &&
                    !hasExistingOrder &&
                    const {
                      'posted',
                      'sent',
                      'accepted',
                    }.contains(controller.status))
                  AppActionButton(
                    icon: Icons.shopping_cart_checkout_outlined,
                    label: 'Create order',
                    filled: false,
                    onPressed: () {
                      final quotationId = intValue(
                        controller.selectedItem?.toJson() ?? const {},
                        'id',
                      );
                      if (quotationId == null) {
                        return;
                      }
                      openModuleShellRoute(
                        context,
                        '/sales/orders/new?quotation_id=$quotationId',
                      );
                    },
                  ),
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
                      allowTemplateEditing: controller.status != 'draft',
                    ),
                  ),
                if (controller.selectedItem != null &&
                    controller.status != 'cancelled')
                  AppActionButton(
                    icon: Icons.edit_note_outlined,
                    label: 'Revise quote',
                    filled: false,
                    onPressed: () => controller.reviseSelected(context),
                  ),
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedItem == null
                      ? 'Save quote'
                      : 'Update quote',
                  onPressed: controller.canEdit
                      ? () => controller.save(context)
                      : null,
                  busy: controller.saving,
                ),
                if (controller.selectedItem != null &&
                    !const {
                      'rejected',
                      'expired',
                      'cancelled',
                    }.contains(controller.status)) ...[
                  if (controller.status == 'draft')
                    AppActionButton(
                      icon: Icons.publish_outlined,
                      label: 'Post',
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
                  if (controller.status == 'posted')
                    AppActionButton(
                      icon: Icons.send_outlined,
                      label: 'Send to customer',
                      filled: false,
                      onPressed: () => controller.sendSelected(context),
                    ),
                  if (controller.status == 'sent') ...[
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Mark accepted',
                      filled: false,
                      onPressed: () => controller.acceptSelected(context),
                    ),
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Reject',
                      filled: false,
                      onPressed: () => controller.rejectSelected(context),
                    ),
                    AppActionButton(
                      icon: Icons.timer_off_outlined,
                      label: 'Expire',
                      filled: false,
                      onPressed: () => controller.expireSelected(context),
                    ),
                  ],
                  if (const {
                    'draft',
                    'posted',
                    'sent',
                  }.contains(controller.status))
                    AppActionButton(
                      icon: Icons.block_outlined,
                      label: 'Cancel quote',
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

  Widget _buildTaxSummaryCard(SalesQuotationManagementController controller) {
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
