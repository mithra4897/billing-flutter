import '../../controller/sales/sales_order_management_controller.dart';
import '../../screen.dart';
import '../../core/files/pdf_web_actions.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialQuotationId,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final int? initialQuotationId;
  final Map<String, String> queryParameters;

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  late final String _controllerTag;

  SalesOrderManagementController get _controller =>
      Get.find<SalesOrderManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'SalesOrderManagementController',
      scope: <String, Object?>{'identity': identityHashCode(this)},
    );
    Get.put(SalesOrderManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _controller.initialize(
          initialId: widget.initialId,
          initialQuotationId: widget.initialQuotationId,
          editorOnly: widget.editorOnly,
        ),
      );
      _applyDashboardFilters(_controller);
    });
  }

  void _applyDashboardFilters(SalesOrderManagementController controller) {
    controller.applyDashboardFilter(
      (widget.queryParameters['dashboard_filter'] ?? '').trim(),
    );
  }

  Widget _buildNotesImagePreview(
    BuildContext context,
    SalesOrderManagementController controller,
  ) {
    final imageUrls = controller.notesImageUrls;
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: imageUrls
              .map((url) => _buildNotesImageTile(context, url))
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildNotesImageTile(BuildContext context, String url) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => unawaited(_openNotesImage(context, url)),
          borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
            child: Image.network(
              url,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: appTheme.subtleFill,
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.fieldRadius,
                  ),
                ),
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppUiConstants.spacingXs),
        TextButton.icon(
          onPressed: () => unawaited(_openNotesImage(context, url)),
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text('View'),
        ),
      ],
    );
  }

  Future<void> _openNotesImage(BuildContext context, String url) async {
    final opened = await openWebUrl(url, title: 'Sales order note image');
    if (opened || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image preview is supported in the web app browser.'),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SalesOrderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !Get.isRegistered<SalesOrderManagementController>(
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
      if (Get.isRegistered<SalesOrderManagementController>(
        tag: _controllerTag,
      )) {
        Get.delete<SalesOrderManagementController>(
          tag: _controllerTag,
          force: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesOrderManagementController>(
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
            label: 'New order',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Sales Orders',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    SalesOrderManagementController controller,
  ) {
    return openSalesSearchStatusFilterPanel(
      context: context,
      title: 'Filter Sales Orders',
      searchController: controller.searchController,
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      searchHint: 'Search by number or customer',
      status: controller.statusFilter,
      statusItems: SalesOrderManagementController.listStatusFilter,
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

  Widget _buildTaxSummaryCard(SalesOrderManagementController controller) {
    final roundOff = controller.applyRoundOff
        ? (Validators.parseFlexibleNumber(
                controller.roundOffController.text.trim(),
              ) ??
              0)
        : 0;
    final subtitle = roundOff == 0
        ? null
        : 'Live GST totals for the current lines in ${controller.currencyCodeForTaxSummary} · includes round off ${roundOff.toStringAsFixed(2)}';
    final summary = controller.taxSummary();
    return GstSummaryCard(
      taxable: summary.taxable,
      cgst: summary.cgst,
      sgst: summary.sgst,
      igst: summary.igst,
      cess: summary.cess,
      total: summary.total,
      currencyCode: controller.currencyCodeForTaxSummary,
      subtitle: subtitle,
    );
  }

  Widget _buildLineItemTable(SalesOrderManagementController controller) {
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

    final sourceOptions = [
      const AppDropdownItem<int?>(value: null, label: 'None'),
      ...?controller.quotationLinesCache
          ?.map(
            (quotationLine) => AppDropdownItem<int?>(
              value: intValue(quotationLine, 'id'),
              label: controller.quotationLinePickerLabel(quotationLine),
            ),
          )
          .where((item) => item.value != null),
    ];

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
        sourceLineId: line.salesQuotationLineId,
        sourceLineOptions: sourceOptions,
        onSourceLineChanged: controller.canEdit
            ? (value) => controller.applyQuotationLinePick(line, value)
            : null,
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
        warehouseId: line.warehouseId,
        warehouseOptions: controller.warehouseDropdownItems,
        onWarehouseChanged: controller.canEdit
            ? (value) => controller.setLineWarehouseId(index, value)
            : null,
        qtyController: line.qtyController,
        onQtyChanged: controller.canEdit
            ? (_) => controller.refreshComputedState()
            : null,
        qtyValidator: Validators.compose([
          Validators.required('Order qty'),
          Validators.optionalNonNegativeNumber('Order qty'),
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
        ErpLineItemTableColumn.warehouse,
        ErpLineItemTableColumn.qty,
        ErpLineItemTableColumn.rate,
        ErpLineItemTableColumn.discount,
        ErpLineItemTableColumn.taxCode,
        ErpLineItemTableColumn.amount,
        ErpLineItemTableColumn.action,
      },
      columnLabels: const <ErpLineItemTableColumn, String>{
        ErpLineItemTableColumn.qty: 'Order qty',
      },
      footer: _buildTaxSummaryCard(controller),
      enabled: controller.canEdit,
    );
  }

  Widget _buildContent(
    BuildContext context,
    SalesOrderManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading orders...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load orders',
        message: controller.pageError!,
        onRetry: controller.reloadLastRequestedPage,
      );
    }

    final selected = controller.selectedItem?.toJson() ?? const {};
    final totalStr = controller.taxSummary().total.toStringAsFixed(2);
    final hasExistingDelivery =
        ((controller.salesChain?['deliveries'] as List?) ?? const [])
            .isNotEmpty;

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Sales Orders',
      editorTitle: controller.selectedItem == null
          ? 'New order'
          : stringValue(selected, 'order_no', 'Order'),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<SalesOrderModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No sales orders yet.',
        searchController: controller.searchController,
        searchHint: 'Search by number or customer',
        statusValue: controller.statusFilter,
        statusItems: SalesOrderManagementController.listStatusFilter,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        showInlineFilters: false,
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'order_no', 'Draft'),
            subtitle: displayDate(nullableStringValue(data, 'order_date')),
            detail: salesListDetailWithCancelReason(
              data,
              quotationCustomerLabel(data),
              statusKey: 'order_status',
            ),
            trailing: salesStatusBadge(
              context,
              stringValue(data, 'order_status'),
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
              hideOrderChip: true,
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
                  labelText: 'Order No',
                  controller: controller.orderNoController,
                  documentSeries: controller.seriesOptions(),
                  documentSeriesId: controller.documentSeriesId,
                  hintText: 'Leave blank if your series fills this in',
                  enabled: controller.canEdit,
                  validator: Validators.optionalMaxLength(100, 'Order No'),
                ),
                AppFormTextField(
                  labelText: 'Order Date',
                  controller: controller.orderDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: controller.canEdit,
                  validator: Validators.compose([
                    Validators.required('Order Date'),
                    Validators.date('Order Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Expected delivery',
                  controller: controller.expectedDeliveryController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: controller.canEdit,
                  validator: Validators.compose([
                    Validators.optionalDate('Expected delivery'),
                    Validators.optionalDateOnOrAfter(
                      'Expected delivery',
                      () => controller.orderDateController.text.trim(),
                      startFieldName: 'Order Date',
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
                  notesSuffixIcon: controller.canEdit
                      ? (controller.uploadingNotesImage
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Upload image',
                                onPressed: () => unawaited(
                                  controller.uploadNotesImage(context),
                                ),
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                ),
                              ))
                      : null,
                  notesExtraFields: <Widget>[
                    _buildNotesImagePreview(context, controller),
                  ],
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'From quotation (optional)',
                  mappedItems: controller.quotationChoiceDropdownItems,
                  initialValue: controller.salesQuotationId,
                  onChanged: (value) =>
                      unawaited(controller.onHeaderQuotationChanged(value)),
                ),
                AppFormTextField(
                  labelText: 'Round off',
                  controller: controller.roundOffController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  enabled: controller.canEdit && controller.applyRoundOff,
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
            GetBuilder<SalesOrderManagementController>(
              tag: _controllerTag,
              id: SalesOrderManagementController.lineItemsSectionId,
              builder: (controller) => _buildLineItemTable(controller),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SalesDocumentActionRow(
              actions: [
                if (controller.selectedItem != null &&
                    !hasExistingDelivery &&
                    const {
                      'confirmed',
                      'partially_delivered',
                      'partially_invoiced',
                    }.contains(controller.status))
                  AppActionButton(
                    icon: Icons.local_shipping_outlined,
                    label: 'Create delivery',
                    filled: false,
                    onPressed: () {
                      final orderId = intValue(
                        controller.selectedItem?.toJson() ?? const {},
                        'id',
                      );
                      if (orderId == null) {
                        return;
                      }
                      openModuleShellRoute(
                        context,
                        '/sales/deliveries/new?order_id=$orderId',
                      );
                    },
                  ),
                if (controller.selectedItem != null &&
                    !const {'cancelled'}.contains(controller.status))
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
                      ? 'Save order'
                      : 'Update order',
                  onPressed: controller.canEdit
                      ? () => controller.save(context)
                      : null,
                  busy: controller.saving,
                ),
                if (controller.selectedItem != null) ...[
                  if (controller.status == 'draft') ...[
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Confirm order',
                      filled: false,
                      onPressed: () => controller.confirmSelected(context),
                    ),
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: () => controller.deleteSelected(context),
                    ),
                  ],
                  if (const {
                    'draft',
                    'confirmed',
                    'partially_delivered',
                    'partially_invoiced',
                  }.contains(controller.status))
                    AppActionButton(
                      icon: Icons.block_outlined,
                      label: 'Cancel order',
                      filled: false,
                      onPressed: () => controller.cancelSelected(context),
                    ),
                  if (const {
                    'confirmed',
                    'partially_delivered',
                    'partially_invoiced',
                  }.contains(controller.status))
                    AppActionButton(
                      icon: Icons.lock_outline,
                      label: 'Close order',
                      filled: false,
                      onPressed: () => controller.closeSelected(context),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
