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
    Get.delete<SalesQuotationManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesQuotationManagementController>(
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

  Future<void> _openPrintPreview(
    BuildContext context,
    SalesQuotationManagementController controller,
  ) {
    return controller.openPrintPreview(context);
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
    final totalStr = stringValue(selected, 'total_amount');

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
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'quotation_no', 'Draft'),
            subtitle: [
              displayDate(nullableStringValue(data, 'quotation_date')),
              stringValue(data, 'quotation_status'),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: quotationCustomerLabel(data),
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
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            CrmSalesPipelineBar(
              data: controller.salesChain,
              hideQuotationChip: true,
            ),
            if (controller.selectedItem != null && totalStr.isNotEmpty)
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
                  labelText: 'Quotation No',
                  controller: controller.quotationNoController,
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
                  currencyCodeController: controller.currencyCodeController,
                  exchangeRateController: controller.exchangeRateController,
                  notesController: controller.notesController,
                  termsController: controller.termsController,
                  onCurrencyChanged: (_) => controller.refreshComputedState(),
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
                                  AppFormTextField(
                                    labelText: 'Qty',
                                    controller: line.qtyController,
                                    enabled: controller.canEdit,
                                    onChanged: (_) =>
                                        controller.refreshComputedState(),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: Validators.compose([
                                      Validators.required('Qty'),
                                      Validators.optionalNonNegativeNumber(
                                        'Qty',
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
                if (controller.status == 'posted')
                  AppActionButton(
                    icon: Icons.print_outlined,
                    label: 'Print',
                    filled: false,
                    onPressed: () => _openPrintPreview(context, controller),
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
    return GstSummaryCard(
      taxable: summary.taxable,
      cgst: summary.cgst,
      sgst: summary.sgst,
      igst: summary.igst,
      cess: summary.cess,
      total: summary.total,
      currencyCode: controller.currencyCodeForTaxSummary,
    );
  }
}
