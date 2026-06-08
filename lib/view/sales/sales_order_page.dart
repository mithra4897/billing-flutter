import '../../controller/sales/sales_order_management_controller.dart';
import '../../screen.dart';

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
    Get.delete<SalesOrderManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesOrderManagementController>(
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
        onRetry: controller.loadPage,
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
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'order_no', 'Draft'),
            subtitle: [
              displayDate(nullableStringValue(data, 'order_date')),
              stringValue(data, 'order_status'),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: quotationCustomerLabel(data),
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
                child: Text(
                  'Total: $totalStr ${controller.currencyCodeController.text.trim().isEmpty ? 'INR' : controller.currencyCodeController.text.trim()} · Status: ${controller.status.toUpperCase()}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            SettingsFormWrap(
              children: [
                ...buildSalesDocumentContextFields(
                  documentSeriesItems: controller.documentSeriesDropdownItems,
                  documentSeriesId: controller.documentSeriesId,
                  onDocumentSeriesChanged: controller.setDocumentSeriesId,
                ),
                AppFormTextField(
                  labelText: 'Order No',
                  controller: controller.orderNoController,
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
                  currencyCodeController: controller.currencyCodeController,
                  exchangeRateController: controller.exchangeRateController,
                  notesController: controller.notesController,
                  termsController: controller.termsController,
                  onCurrencyChanged: (_) => controller.refreshComputedState(),
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
              builder: (controller) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SalesDocumentLineSection(
                    title: 'Line items',
                    addLabel: 'Add line',
                    onAdd: controller.canEdit ? controller.addLine : null,
                    footer: _buildTaxSummaryCard(controller),
                    children: List<Widget>.generate(controller.lines.length, (
                      index,
                    ) {
                      final line = controller.lines[index];
                      final breakdown = controller.taxBreakdownForLine(line);
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PurchaseCompactFieldGrid(
                                children: [
                                  if (controller.salesQuotationId != null &&
                                      (controller.quotationLinesCache != null &&
                                          controller
                                              .quotationLinesCache!
                                              .isNotEmpty))
                                    AppDropdownField<int?>.fromMapped(
                                      labelText: 'Quotation line',
                                      mappedItems: [
                                        const AppDropdownItem<int?>(
                                          value: null,
                                          label: 'None',
                                        ),
                                        ...controller.quotationLinesCache!
                                            .map(
                                              (
                                                quotationLine,
                                              ) => AppDropdownItem<int?>(
                                                value: intValue(
                                                  quotationLine,
                                                  'id',
                                                ),
                                                label: controller
                                                    .quotationLinePickerLabel(
                                                      quotationLine,
                                                    ),
                                              ),
                                            )
                                            .where(
                                              (item) => item.value != null,
                                            ),
                                      ],
                                      initialValue: line.salesQuotationLineId,
                                      onChanged: (value) {
                                        if (!controller.canEdit) {
                                          return;
                                        }
                                        controller.applyQuotationLinePick(
                                          line,
                                          value,
                                        );
                                      },
                                    ),
                                  AppSearchPickerField<int>(
                                    labelText: 'Item',
                                    selectedLabel: controller.itemLabelById(
                                      line.itemId,
                                    ),
                                    options: controller.itemPickerOptions,
                                    onChanged: (value) =>
                                        controller.setLineItemId(index, value),
                                    validator: (_) =>
                                        Validators.requiredSelectionField(
                                          line.itemId,
                                          'Item',
                                        ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final options = controller
                                          .uomOptionsForItem(line.itemId);
                                      if (controller.canEdit &&
                                          options.length == 1) {
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
                                        onChanged: (value) => controller
                                            .setLineUomId(index, value),
                                        validator: (_) =>
                                            Validators.dependentSelectionField(
                                              prerequisite: line.itemId,
                                              prerequisiteName: 'item',
                                              value: line.uomId,
                                              fieldName: 'UOM',
                                            ),
                                      );
                                    },
                                  ),
                                  AppDropdownField<int>.fromMapped(
                                    labelText: 'Warehouse',
                                    mappedItems:
                                        controller.warehouseDropdownItems,
                                    initialValue: line.warehouseId,
                                    onChanged: (value) => controller
                                        .setLineWarehouseId(index, value),
                                  ),
                                  AppFormTextField(
                                    labelText: 'Order qty',
                                    controller: line.qtyController,
                                    enabled: controller.canEdit,
                                    onChanged: (_) =>
                                        controller.refreshComputedState(),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: Validators.compose([
                                      Validators.required('Order qty'),
                                      Validators.optionalNonNegativeNumber(
                                        'Order qty',
                                      ),
                                    ]),
                                  ),
                                  AppFormTextField(
                                    labelText: 'Rate',
                                    controller: line.rateController,
                                    enabled: controller.canEdit,
                                    onChanged: (_) =>
                                        controller.refreshComputedState(),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: Validators.compose([
                                      Validators.required('Rate'),
                                      Validators.optionalNonNegativeNumber(
                                        'Rate',
                                      ),
                                    ]),
                                  ),
                                  AppFormTextField(
                                    labelText: 'Discount %',
                                    controller: line.discountController,
                                    enabled: controller.canEdit,
                                    onChanged: (_) =>
                                        controller.refreshComputedState(),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator:
                                        Validators.optionalNonNegativeNumber(
                                          'Discount %',
                                        ),
                                  ),
                                  AppDropdownField<int>.fromMapped(
                                    labelText: 'Tax code',
                                    mappedItems:
                                        controller.taxCodeDropdownItems,
                                    initialValue: line.taxCodeId,
                                    onChanged: (value) => controller
                                        .setLineTaxCodeId(index, value),
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
                              const SizedBox(height: AppUiConstants.spacingSm),
                              GstLineTaxPreview(
                                gross: breakdown.gross,
                                taxable: breakdown.taxable,
                                cgst: breakdown.cgst,
                                sgst: breakdown.sgst,
                                igst: breakdown.igst,
                                cess: breakdown.cess,
                                total: breakdown.total,
                                currencyCode:
                                    controller.currencyCodeForTaxSummary,
                                taxCodeLabel: salesTaxCodeById(
                                  controller.taxCodes,
                                  line.taxCodeId,
                                )?.toString(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
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
