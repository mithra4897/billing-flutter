import '../../controller/purchase/purchase_payment_management_controller.dart';
import '../../screen.dart';
import 'purchase_pipeline_bar.dart';

class PurchasePaymentPage extends StatefulWidget {
  const PurchasePaymentPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialPurchaseInvoiceId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final int? initialPurchaseInvoiceId;

  @override
  State<PurchasePaymentPage> createState() => _PurchasePaymentPageState();
}

class _PurchasePaymentPageState extends State<PurchasePaymentPage> {
  late final String _controllerTag;
  bool _filtersVisible = false;

  PurchasePaymentManagementController get _controller =>
      Get.find<PurchasePaymentManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'PurchasePaymentManagementController',
      scope: uniqueControllerScope(<String, Object?>{
        'identity': identityHashCode(this),
      }),
    );
    Get.put(PurchasePaymentManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _controller.initialize(
          initialId: widget.initialId,
          initialPurchaseInvoiceId: widget.initialPurchaseInvoiceId,
        ),
      );
    });
  }

  @override
  void dispose() {
    Get.delete<PurchasePaymentManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PurchasePaymentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialId != widget.initialId ||
        oldWidget.initialPurchaseInvoiceId != widget.initialPurchaseInvoiceId ||
        oldWidget.editorOnly != widget.editorOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(
          _controller.initialize(
            initialId: widget.initialId,
            initialPurchaseInvoiceId: widget.initialPurchaseInvoiceId,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchasePaymentManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellSearchField(
            controller: controller.searchController,
            hintText: 'Search payments',
          ),
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
            label: 'New Payment',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Purchase Payments',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PurchasePaymentManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading purchase payments...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase payments',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Purchase Payments',
      editorTitle: controller.selectedItem == null
          ? 'New Purchase Payment'
          : stringValue(
              controller.selectedItem!.toJson(),
              'payment_no',
              'Purchase Payment',
            ),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<PurchasePaymentModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No purchase payments found.',
        searchController: controller.searchController,
        searchHint: 'Search payments',
        showInlineFilters: _filtersVisible,
        showInlineSearch: false,
        statusValue: controller.statusFilter,
        statusItems: PurchasePaymentManagementController.statusItems,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: nullableStringValue(data, 'payment_no') ?? 'Draft Payment',
            subtitle: displayDate(nullableStringValue(data, 'payment_date')),
            detail: purchaseListDetailWithCancelReason(
              data,
              nullableStringValue(data, 'reference_no') ??
                  stringValue(data, 'supplier_name'),
              statusKey: 'payment_status',
            ),
            trailing: purchaseStatusBadge(
              context,
              nullableStringValue(data, 'payment_status'),
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
            if (controller.isSelectedPaymentReadOnly) ...[
              Text(
                purchaseReadOnlyMessage(
                  'purchase payment',
                  nullableStringValue(
                    controller.selectedItem?.toJson() ?? const {},
                    'payment_status',
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            if (controller.selectedItem != null)
              PurchasePipelineBar(
                data: controller.purchaseChain,
                hidePaymentChip: true,
              ),
            IgnorePointer(
              ignoring:
                  controller.isSelectedPaymentReadOnly &&
                  !controller.canAllocateRemainingAdvance,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IgnorePointer(
                    ignoring: controller.isSelectedPaymentReadOnly,
                    child: Column(
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
                              enabled: !controller.isSelectedPaymentReadOnly,
                              onChanged: controller.setDocumentSeriesId,
                            ),
                            GeneratedDocumentNumberField(
                              labelText: 'Payment No',
                              controller: controller.paymentNoController,
                              documentSeries: controller.seriesOptions(),
                              documentSeriesId: controller.documentSeriesId,
                              hintText: 'Auto-generated on save',
                              validator: Validators.optionalMaxLength(
                                100,
                                'Payment No',
                              ),
                            ),
                            AppFormTextField(
                              labelText: 'Payment Date',
                              controller: controller.paymentDateController,
                              keyboardType: TextInputType.datetime,
                              inputFormatters: const [DateInputFormatter()],
                              validator: Validators.compose([
                                Validators.required('Payment Date'),
                                Validators.date('Payment Date'),
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
                              search: controller.searchSupplierOptions,
                              enabled: !controller.isSelectedPaymentReadOnly,
                              onChanged: controller.setSupplierPartyId,
                              validator: Validators.requiredSelection(
                                'Supplier',
                              ),
                            ),
                            AppDropdownField<String>.fromMapped(
                              labelText: 'Payment Mode',
                              mappedItems: PurchasePaymentManagementController
                                  .paymentModeItems,
                              initialValue: controller.paymentMode,
                              enabled: !controller.isSelectedPaymentReadOnly,
                              onChanged: (value) =>
                                  controller.setPaymentMode(value ?? 'bank'),
                              validator: Validators.requiredSelection(
                                'Payment Mode',
                              ),
                            ),
                            AppDropdownField<int>.fromMapped(
                              labelText: 'Account',
                              mappedItems: controller.accounts
                                  .where((item) => item.id != null)
                                  .map(
                                    (item) => AppDropdownItem(
                                      value: item.id!,
                                      label: item.toString(),
                                    ),
                                  )
                                  .toList(growable: false),
                              initialValue: controller.accountId,
                              enabled: !controller.isSelectedPaymentReadOnly,
                              onChanged: controller.setAccountId,
                              validator: Validators.requiredSelection(
                                'Account',
                              ),
                            ),
                            AppFormTextField(
                              labelText: 'Reference No',
                              controller: controller.referenceNoController,
                              validator: Validators.optionalMaxLength(
                                100,
                                'Reference No',
                              ),
                            ),
                            AppFormTextField(
                              labelText: 'Reference Date',
                              controller: controller.referenceDateController,
                              keyboardType: TextInputType.datetime,
                              inputFormatters: const [DateInputFormatter()],
                              validator: Validators.optionalDate(
                                'Reference Date',
                              ),
                            ),
                            AppFormTextField(
                              labelText: 'Paid Amount',
                              controller: controller.paidAmountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) =>
                                  controller.handlePaidAmountChanged(),
                              validator: Validators.compose([
                                Validators.required('Paid Amount'),
                                Validators.optionalNonNegativeNumber(
                                  'Paid Amount',
                                ),
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
                          value: controller.isActive,
                          onChanged: controller.setIsActive,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingLg),
                  if (controller.canAllocateRemainingAdvance) ...[
                    Text(
                      'Available supplier advance: ₹${formatAmount(controller.remainingUnallocatedAmount)}. Add invoice lines up to this amount.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppUiConstants.spacingSm),
                  ],
                  Row(
                    children: [
                      Text(
                        'Allocations',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      AppActionButton(
                        icon: Icons.auto_fix_high_outlined,
                        label: controller.autoAllocating
                            ? 'Allocating...'
                            : 'Auto Allocate',
                        onPressed:
                            controller.isSelectedPaymentReadOnly ||
                                controller.autoAllocating
                            ? null
                            : controller.autoAllocateOldestInvoices,
                        filled: false,
                      ),
                      const SizedBox(width: AppUiConstants.spacingSm),
                      AppActionButton(
                        icon: Icons.add_outlined,
                        label: 'Add Allocation',
                        onPressed:
                            controller.isSelectedPaymentReadOnly &&
                                !controller.canAllocateRemainingAdvance
                            ? null
                            : controller.addAllocation,
                        filled: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  if (controller.allocations.isEmpty)
                    const Text(
                      'This payment can stay on-account, or allocate it to one or more purchase invoices.',
                    )
                  else
                    ...List<Widget>.generate(controller.allocations.length, (
                      index,
                    ) {
                      final allocation = controller.allocations[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppUiConstants.spacingSm,
                        ),
                        child: IgnorePointer(
                          ignoring: controller.isPersistedAllocation(index),
                          child: PurchaseCompactLineCard(
                            index: index,
                            total: controller.allocations.length,
                            removeEnabled: !controller.isPersistedAllocation(
                              index,
                            ),
                            onRemove: () => controller.removeAllocation(index),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (allocation.isAutoAllocated) ...[
                                  Text(
                                    'Automatically allocated${allocation.sourcePaymentNo?.trim().isNotEmpty == true ? ' while posting ${allocation.sourcePaymentNo}' : ''}${allocation.allocatedByName?.trim().isNotEmpty == true ? ' by ${allocation.allocatedByName}' : ''}${allocation.allocatedAt?.trim().isNotEmpty == true ? ' · ${displayDateTime(allocation.allocatedAt)}' : ''}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(
                                    height: AppUiConstants.spacingSm,
                                  ),
                                ],
                                PurchaseCompactFieldGrid(
                                  children: [
                                    AppSearchPickerField<int>(
                                      labelText: 'Purchase Invoice',
                                      selectedLabel:
                                          controller
                                              .invoiceOptionsForAllocation(
                                                index,
                                              )
                                              .cast<PurchaseInvoiceModel?>()
                                              .firstWhere(
                                                (item) =>
                                                    item?.id ==
                                                    allocation
                                                        .purchaseInvoiceId,
                                                orElse: () => null,
                                              )
                                              ?.invoiceNo ??
                                          allocation.purchaseInvoiceNo,
                                      options: controller
                                          .invoiceOptionsForAllocation(index)
                                          .where((item) => item.id != null)
                                          .map(
                                            (
                                              item,
                                            ) => AppSearchPickerOption<int>(
                                              value: item.id!,
                                              label:
                                                  item.invoiceNo ?? 'Invoice',
                                              subtitle: controller
                                                  .nestedInvoiceSubtitle(item),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (value) async {
                                        await controller
                                            .handleAllocationInvoiceChanged(
                                              index,
                                              value,
                                            );
                                      },
                                    ),
                                    AppFormTextField(
                                      labelText: 'Allocated Amount',
                                      controller: allocation.amountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator:
                                          Validators.requiredPositiveNumber(
                                            'Allocated Amount',
                                          ),
                                      onChanged: (_) => controller
                                          .syncPaidAmountFromAllocations(),
                                    ),
                                    AppDropdownField<String>.fromMapped(
                                      labelText: 'Allocation Type',
                                      enabled:
                                          !controller
                                              .isSelectedPaymentReadOnly ||
                                          controller
                                              .canAllocateRemainingAdvance,
                                      mappedItems:
                                          controller.canAllocateRemainingAdvance
                                          ? const <AppDropdownItem<String>>[
                                              AppDropdownItem(
                                                value: 'against_invoice',
                                                label: 'Against Invoice',
                                              ),
                                            ]
                                          : const <AppDropdownItem<String>>[
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
                                      onChanged: (value) =>
                                          controller.setAllocationType(
                                            allocation,
                                            value ?? 'against_invoice',
                                          ),
                                    ),
                                    AppFormTextField(
                                      labelText: 'Remarks',
                                      controller: allocation.remarksController,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Builder(
              builder: (_) {
                final selectedData =
                    controller.selectedItem?.toJson() ??
                    const <String, dynamic>{};
                final status = stringValue(selectedData, 'payment_status');
                final canPost =
                    controller.selectedItem != null && status == 'draft';
                final canCancel =
                    controller.selectedItem != null &&
                    purchasePaymentCanCancel(status);

                return Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    if (controller.canAllocateRemainingAdvance)
                      AppActionButton(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Allocate Remaining Advance',
                        onPressed: controller.newRemainingAllocations.isEmpty
                            ? null
                            : () =>
                                  controller.saveRemainingAllocations(context),
                        busy: controller.saving,
                      ),
                    if (!controller.isSelectedPaymentReadOnly)
                      AppActionButton(
                        icon: Icons.save_outlined,
                        label: controller.selectedItem == null
                            ? 'Save Payment'
                            : 'Update Payment',
                        onPressed: controller.canEditSelectedPayment
                            ? () => controller.save(context)
                            : null,
                        busy: controller.saving,
                      ),
                    if (canPost)
                      AppActionButton(
                        icon: Icons.publish_outlined,
                        label: 'Submit',
                        filled: false,
                        onPressed: () async {
                          await controller.docAction(
                            context,
                            () => PurchaseService().postPayment(
                              intValue(
                                controller.selectedItem!.toJson(),
                                'id',
                              )!,
                              PurchasePaymentModel.fromJson(
                                const <String, dynamic>{},
                              ),
                            ),
                          );
                        },
                      ),
                    if (canCancel)
                      AppActionButton(
                        icon: Icons.cancel_outlined,
                        label: 'Cancel',
                        filled: false,
                        onPressed: () async {
                          final reason = await promptCancellationReason(
                            context,
                            title: 'Cancel payment',
                            subjectLabel:
                                controller.selectedItem?.toString() ??
                                'this purchase payment',
                          );
                          if (reason == null || !context.mounted) {
                            return;
                          }
                          await controller.docAction(
                            context,
                            () => PurchaseService().cancelPayment(
                              intValue(
                                controller.selectedItem!.toJson(),
                                'id',
                              )!,
                              <String, dynamic>{'cancel_reason': reason},
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
