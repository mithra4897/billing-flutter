import '../../controller/sales/sales_quotation_management_controller.dart';
import '../../screen.dart';

void _openSalesShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class SalesQuotationPage extends StatefulWidget {
  const SalesQuotationPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialCrmOpportunityId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final int? initialCrmOpportunityId;

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
    );
    if (!Get.isRegistered<SalesQuotationManagementController>(
      tag: _controllerTag,
    )) {
      Get.put(SalesQuotationManagementController(), tag: _controllerTag);
    }
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
    });
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Financial Year',
                  mappedItems: controller.financialYears
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.financialYearId,
                  onChanged: controller.setFinancialYearId,
                  validator: Validators.requiredSelection('Financial Year'),
                ),
                AppDropdownField<int>.fromMapped(
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Customer',
                  doctypeLabel: 'Customer',
                  allowCreate: true,
                  onNavigateToCreateNew: (name) {
                    final uri = Uri(
                      path: '/parties',
                      queryParameters: {
                        'new': '1',
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
                  onChanged: controller.setCustomerPartyId,
                  validator: Validators.requiredSelection('Customer'),
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
                  labelText: 'Currency',
                  controller: controller.currencyCodeController,
                  enabled: controller.canEdit,
                  onChanged: (_) => controller.refreshComputedState(),
                  validator: Validators.optionalMaxLength(10, 'Currency'),
                ),
                AppFormTextField(
                  labelText: 'Exchange Rate',
                  controller: controller.exchangeRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: controller.canEdit,
                  validator: Validators.optionalNonNegativeNumber(
                    'Exchange Rate',
                  ),
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
              onChanged: controller.canEdit ? controller.setIsActive : null,
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
                            onChanged: (value) =>
                                controller.setLineItemId(index, value),
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
                                onChanged: (value) =>
                                    controller.setLineUomId(index, value),
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
                          AppFormTextField(
                            labelText: 'Qty',
                            controller: line.qtyController,
                            enabled: controller.canEdit,
                            onChanged: (_) => controller.refreshComputedState(),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.compose([
                              Validators.required('Qty'),
                              Validators.optionalNonNegativeNumber('Qty'),
                            ]),
                          ),
                          AppFormTextField(
                            labelText: 'Rate',
                            controller: line.rateController,
                            enabled: controller.canEdit,
                            onChanged: (_) => controller.refreshComputedState(),
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
                            onChanged: (_) => controller.refreshComputedState(),
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
                            onChanged: (value) =>
                                controller.setLineTaxCodeId(index, value),
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
                        currencyCode: controller.currencyCodeForTaxSummary,
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
            const SizedBox(height: AppUiConstants.spacingMd),
            _buildTaxSummaryCard(controller),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
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
                  if (const {
                    'posted',
                    'sent',
                    'accepted',
                  }.contains(controller.status))
                    AppActionButton(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Sales order',
                      filled: false,
                      onPressed: () {
                        final id = intValue(
                          controller.selectedItem!.toJson(),
                          'id',
                        );
                        if (id == null) return;
                        _openSalesShellRoute(
                          context,
                          '/sales/orders/new?quotation_id=$id',
                        );
                      },
                    ),
                  if (const {
                    'posted',
                    'sent',
                    'accepted',
                  }.contains(controller.status))
                    AppActionButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'Invoice',
                      filled: false,
                      onPressed: () {
                        final id = intValue(
                          controller.selectedItem!.toJson(),
                          'id',
                        );
                        if (id == null) return;
                        _openSalesShellRoute(
                          context,
                          '/sales/invoices/new?quotation_id=$id',
                        );
                      },
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
