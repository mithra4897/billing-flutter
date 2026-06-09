import '../../controller/sales/sales_receipt_management_controller.dart';
import '../../screen.dart';

class SalesReceiptPage extends StatefulWidget {
  const SalesReceiptPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialSalesInvoiceId,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  final int? initialSalesInvoiceId;
  final Map<String, String> queryParameters;

  @override
  State<SalesReceiptPage> createState() => _SalesReceiptPageState();
}

class _SalesReceiptPageState extends State<SalesReceiptPage> {
  late final String _controllerTag;

  SalesReceiptManagementController get _controller =>
      Get.find<SalesReceiptManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'SalesReceiptManagementController',
      scope: <String, Object?>{'identity': identityHashCode(this)},
    );
    Get.put(SalesReceiptManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _controller.initialize(
          initialId: widget.initialId,
          initialSalesInvoiceId: widget.initialSalesInvoiceId,
          editorOnly: widget.editorOnly,
        ),
      );
    });
  }

  @override
  void dispose() {
    Get.delete<SalesReceiptManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesReceiptManagementController>(
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
            label: 'New Receipt',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Sales Receipts',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    SalesReceiptManagementController controller,
  ) {
    final selectedData = controller.selectedItem?.toJson() ?? const {};
    final status = stringValue(selectedData, 'receipt_status', 'draft');
    final canEdit = controller.selectedItem == null || status == 'draft';
    final canPost = controller.selectedItem != null && status == 'draft';
    final canCancel = controller.selectedItem != null && status == 'draft';
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading sales receipts...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load sales receipts',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Sales Receipts',
      editorTitle: controller.selectedItem == null
          ? 'New Sales Receipt'
          : stringValue(
              controller.selectedItem!.toJson(),
              'receipt_no',
              'Sales Receipt',
            ),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<SalesReceiptModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No sales receipts found.',
        searchController: controller.searchController,
        searchHint: 'Search receipts',
        statusValue: controller.statusFilter,
        statusItems: SalesReceiptManagementController.statusItems,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'receipt_no', 'Draft Receipt'),
            subtitle: [
              displayDate(nullableStringValue(data, 'receipt_date')),
              stringValue(data, 'receipt_status'),
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
              hideReceiptChip: true,
            ),
            IgnorePointer(
              ignoring: !canEdit,
              child: SettingsFormWrap(
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
                    onChanged: canEdit
                        ? controller.setDocumentSeriesId
                        : (_) {},
                  ),
                  AppFormTextField(
                    labelText: 'Receipt No',
                    controller: controller.receiptNoController,
                    hintText: 'Auto-generated on save',
                    enabled: canEdit,
                    validator: Validators.optionalMaxLength(100, 'Receipt No'),
                  ),
                  AppDateField(
                    labelText: 'Receipt Date',
                    controller: controller.receiptDateController,
                    enabled: canEdit,
                    validator: Validators.compose([
                      Validators.required('Receipt Date'),
                      Validators.date('Receipt Date'),
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
                      final navigate = ShellRouteScope.maybeOf(context);
                      if (navigate != null) {
                        navigate(uri.toString());
                      } else {
                        Navigator.of(context).pushNamed(uri.toString());
                      }
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
                    onChanged: canEdit ? controller.setCustomerPartyId : (_) {},
                    validator: Validators.requiredSelection('Customer'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Payment Mode',
                    mappedItems: controller.paymentModeDropdownItems(),
                    initialValue: controller.paymentMode,
                    onChanged: canEdit ? controller.setPaymentMode : (_) {},
                    validator: Validators.requiredSelection('Payment Mode'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Cash / bank ledger',
                    mappedItems: controller.receiptLedgerOptions
                        .where((item) => item.id != null)
                        .map(
                          (item) => AppDropdownItem(
                            value: item.id!,
                            label: item.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: controller.accountId,
                    onChanged: canEdit ? controller.setAccountId : (_) {},
                    validator: Validators.requiredSelection(
                      'Cash / bank ledger',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Payment Reference No',
                    controller: controller.paymentReferenceNoController,
                    enabled: canEdit,
                    validator: Validators.optionalMaxLength(
                      100,
                      'Payment Reference No',
                    ),
                  ),
                  AppDateField(
                    labelText: 'Payment Reference Date',
                    controller: controller.paymentReferenceDateController,
                    enabled: canEdit,
                    validator: Validators.optionalDate(
                      'Payment Reference Date',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Paid Amount',
                    controller: controller.paidAmountController,
                    enabled: canEdit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.compose([
                      Validators.required('Paid Amount'),
                      Validators.optionalNonNegativeNumber('Paid Amount'),
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Notes',
                    controller: controller.notesController,
                    enabled: canEdit,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              subtitle:
                  'Turn off to mark this receipt inactive. Inactive records are kept for audit but excluded from normal lists and day-to-day use.',
              value: controller.isActive,
              onChanged: canEdit ? controller.setIsActive : null,
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            Row(
              children: [
                Text(
                  'Allocations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add Allocation',
                  onPressed: canEdit ? controller.addAllocation : null,
                  filled: false,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            if (controller.allocations.isEmpty)
              const Text(
                'This receipt can stay on-account, or allocate it to one or more sales invoices.',
              )
            else
              ...List<Widget>.generate(controller.allocations.length, (index) {
                final allocation = controller.allocations[index];
                return Padding(
                  key: ObjectKey(allocation),
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: IgnorePointer(
                    ignoring: !canEdit,
                    child: PurchaseCompactLineCard(
                      index: index,
                      total: controller.allocations.length,
                      onRemove: canEdit
                          ? () => controller.removeAllocation(index)
                          : null,
                      child: PurchaseCompactFieldGrid(
                        children: [
                          AppSearchPickerField<int>(
                            labelText: 'Sales Invoice',
                            selectedLabel: controller.invoiceOptions
                                .cast<SalesInvoiceModel?>()
                                .firstWhere(
                                  (item) =>
                                      item?.id == allocation.salesInvoiceId,
                                  orElse: () => null,
                                )
                                ?.invoiceNo,
                            options: controller.invoiceOptions
                                .map(
                                  (item) => AppSearchPickerOption<int>(
                                    value: item.id!,
                                    label: item.invoiceNo ?? 'Invoice',
                                    subtitle: quotationCustomerLabel(
                                      item.toJson(),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) => controller
                                .setAllocationSalesInvoiceId(index, value),
                          ),
                          AppFormTextField(
                            labelText: 'Allocated Amount',
                            controller: allocation.amountController,
                            enabled: canEdit,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.optionalNonNegativeNumber(
                              'Allocated Amount',
                            ),
                          ),
                          AppDropdownField<String>.fromMapped(
                            labelText: 'Allocation Type',
                            mappedItems: const <AppDropdownItem<String>>[
                              AppDropdownItem(
                                value: 'against_invoice',
                                label: 'Against Invoice',
                              ),
                              AppDropdownItem(
                                value: 'advance',
                                label: 'Advance',
                              ),
                              AppDropdownItem(
                                value: 'on_account',
                                label: 'On Account',
                              ),
                              AppDropdownItem(
                                value: 'adjustment',
                                label: 'Adjustment',
                              ),
                            ],
                            initialValue: allocation.allocationType,
                            onChanged: canEdit
                                ? (value) =>
                                      controller.setAllocationType(index, value)
                                : (_) {},
                          ),
                          AppFormTextField(
                            labelText: 'Remarks',
                            controller: allocation.remarksController,
                            enabled: canEdit,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedItem == null
                      ? 'Save Receipt'
                      : 'Update Receipt',
                  onPressed: canEdit ? () => controller.save(context) : null,
                  busy: controller.saving,
                ),
                if (canPost)
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => controller.postSelected(context),
                  ),
                if (canCancel)
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => controller.cancelSelected(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
