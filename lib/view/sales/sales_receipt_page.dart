import '../../controller/sales/sales_receipt_management_controller.dart';
import '../../screen.dart';

class SalesReceiptPage extends StatefulWidget {
  const SalesReceiptPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialSalesInvoiceId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  final int? initialSalesInvoiceId;

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
    );
    if (!Get.isRegistered<SalesReceiptManagementController>(
      tag: _controllerTag,
    )) {
      Get.put(SalesReceiptManagementController(), tag: _controllerTag);
    }
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
      editor: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
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
                  labelText: 'Receipt No',
                  controller: controller.receiptNoController,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Receipt No'),
                ),
                AppDateField(
                  labelText: 'Receipt Date',
                  controller: controller.receiptDateController,
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
                  onChanged: controller.setCustomerPartyId,
                  validator: Validators.requiredSelection('Customer'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Payment Mode',
                  mappedItems: controller.paymentModeDropdownItems(),
                  initialValue: controller.paymentMode,
                  onChanged: controller.setPaymentMode,
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
                  onChanged: controller.setAccountId,
                  validator: Validators.requiredSelection('Cash / bank ledger'),
                ),
                AppFormTextField(
                  labelText: 'Payment Reference No',
                  controller: controller.paymentReferenceNoController,
                  validator: Validators.optionalMaxLength(
                    100,
                    'Payment Reference No',
                  ),
                ),
                AppDateField(
                  labelText: 'Payment Reference Date',
                  controller: controller.paymentReferenceDateController,
                  validator: Validators.optionalDate('Payment Reference Date'),
                ),
                AppFormTextField(
                  labelText: 'Paid Amount',
                  controller: controller.paidAmountController,
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
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              subtitle:
                  'Turn off to mark this receipt inactive. Inactive records are kept for audit but excluded from normal lists and day-to-day use.',
              value: controller.isActive,
              onChanged: controller.setIsActive,
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
                  onPressed: controller.addAllocation,
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
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: PurchaseCompactLineCard(
                    index: index,
                    total: controller.allocations.length,
                    onRemove: () => controller.removeAllocation(index),
                    child: PurchaseCompactFieldGrid(
                      children: [
                        AppSearchPickerField<int>(
                          labelText: 'Sales Invoice',
                          selectedLabel: controller.invoiceOptions
                              .cast<SalesInvoiceModel?>()
                              .firstWhere(
                                (item) => item?.id == allocation.salesInvoiceId,
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
                            AppDropdownItem(value: 'advance', label: 'Advance'),
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
                          onChanged: (value) =>
                              controller.setAllocationType(index, value),
                        ),
                        AppFormTextField(
                          labelText: 'Remarks',
                          controller: allocation.remarksController,
                        ),
                      ],
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
                  onPressed: () => controller.save(context),
                  busy: controller.saving,
                ),
                if (controller.selectedItem != null) ...[
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => controller.postSelected(context),
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
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
    );
  }
}
