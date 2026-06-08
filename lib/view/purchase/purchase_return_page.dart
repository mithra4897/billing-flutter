import '../../controller/purchase/purchase_return_management_controller.dart';
import '../../screen.dart';

class PurchaseReturnPage extends StatefulWidget {
  const PurchaseReturnPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PurchaseReturnPage> createState() => _PurchaseReturnPageState();
}

class _PurchaseReturnPageState extends State<PurchaseReturnPage> {
  late final String _controllerTag;

  PurchaseReturnManagementController get _controller =>
      Get.find<PurchaseReturnManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'PurchaseReturnManagementController',
      scope: uniqueControllerScope(<String, Object?>{
        'identity': identityHashCode(this),
      }),
    );
    Get.put(PurchaseReturnManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_controller.initialize(initialId: widget.initialId));
    });
  }

  @override
  void dispose() {
    Get.delete<PurchaseReturnManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchaseReturnManagementController>(
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
            label: 'New Return',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Purchase Returns',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PurchaseReturnManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading purchase returns...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase returns',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Purchase Returns',
      editorTitle: controller.selectedItem == null
          ? 'New Purchase Return'
          : stringValue(
              controller.selectedItem!.toJson(),
              'return_no',
              'Purchase Return',
            ),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<PurchaseReturnModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No purchase returns found.',
        searchController: controller.searchController,
        searchHint: 'Search returns',
        statusValue: controller.statusFilter,
        statusItems: PurchaseReturnManagementController.statusItems,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: nullableStringValue(data, 'return_no') ?? 'Draft Return',
            subtitle: [
              displayDate(nullableStringValue(data, 'return_date')),
              purchaseStatusLabel(nullableStringValue(data, 'return_status')),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail:
                nullableStringValue(data, 'purchase_invoice_no') ??
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
            if (controller.isSelectedReturnReadOnly) ...[
              Text(
                purchaseReadOnlyMessage(
                  'purchase return',
                  nullableStringValue(
                    controller.selectedItem?.toJson() ?? const {},
                    'return_status',
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            IgnorePointer(
              ignoring: controller.isSelectedReturnReadOnly,
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
                        labelText: 'Return No',
                        controller: controller.returnNoController,
                        hintText: 'Auto-generated on save',
                        validator: Validators.optionalMaxLength(
                          100,
                          'Return No',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Return Date',
                        controller: controller.returnDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.compose([
                          Validators.required('Return Date'),
                          Validators.date('Return Date'),
                        ]),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Purchase Invoice',
                        mappedItems: controller.invoiceOptions
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.invoiceNo ?? 'Invoice',
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.purchaseInvoiceId,
                        onChanged: controller.handleInvoiceChanged,
                        validator: Validators.requiredSelection(
                          'Purchase Invoice',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Return Reason',
                        controller: controller.returnReasonController,
                      ),
                      AppFormTextField(
                        labelText: 'Round off',
                        controller: controller.roundOffController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        enabled: controller.applyRoundOff,
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) {
                            return null;
                          }
                          return Validators.parseFlexibleNumber(text) == null
                              ? 'Round off must be a valid number'
                              : null;
                        },
                      ),
                      AppSwitchTile(
                        label: 'Apply round off',
                        value: controller.applyRoundOff,
                        onChanged: controller.setApplyRoundOff,
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
                        onPressed: controller.isSelectedReturnReadOnly
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
                              labelText: 'Purchase Invoice Line',
                              selectedLabel: (() {
                                final selected = controller.invoiceLines
                                    .cast<PurchaseInvoiceLineModel?>()
                                    .firstWhere(
                                      (item) =>
                                          item?.id ==
                                          line.purchaseInvoiceLineId,
                                      orElse: () => null,
                                    );
                                if (selected == null) {
                                  return null;
                                }
                                return '${controller.itemName(selected.itemId)} · Qty ${selected.invoicedQty}';
                              })(),
                              options: controller.invoiceLines
                                  .where((item) => item.id != null)
                                  .map(
                                    (item) => AppSearchPickerOption<int>(
                                      value: item.id!,
                                      label:
                                          '${controller.itemName(item.itemId)} · Qty ${item.invoicedQty}',
                                      subtitle:
                                          '${controller.warehouseName(item.warehouseId)} · ${controller.uomName(item.uomId)}',
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) =>
                                  controller.selectInvoiceLine(line, value),
                              validator: (_) =>
                                  Validators.requiredSelectionField(
                                    line.purchaseInvoiceLineId,
                                    'Purchase Invoice Line',
                                  ),
                            ),
                            AppFormTextField(
                              labelText: 'Item',
                              controller: line.itemNameController,
                              readOnly: true,
                            ),
                            AppFormTextField(
                              labelText: 'Warehouse',
                              controller: line.warehouseNameController,
                              readOnly: true,
                            ),
                            AppFormTextField(
                              labelText: 'UOM',
                              controller: line.uomNameController,
                              readOnly: true,
                            ),
                            AppFormTextField(
                              labelText: 'Return Qty',
                              controller: line.returnQtyController,
                              onChanged: (_) =>
                                  controller.refreshComputedState(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: Validators.compose([
                                Validators.required('Return Qty'),
                                Validators.optionalNonNegativeNumber(
                                  'Return Qty',
                                ),
                              ]),
                            ),
                            AppFormTextField(
                              labelText: 'Rate',
                              controller: line.rateController,
                              onChanged: (_) =>
                                  controller.refreshComputedState(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: Validators.optionalNonNegativeNumber(
                                'Rate',
                              ),
                            ),
                            AppFormTextField(
                              labelText: 'Return Reason',
                              controller: line.returnReasonController,
                            ),
                            AppFormTextField(
                              labelText: 'Remarks',
                              controller: line.remarksController,
                            ),
                          ],
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
                final status = stringValue(selectedData, 'return_status');
                final canPost =
                    controller.selectedItem != null && status == 'draft';
                final canCancel =
                    controller.selectedItem != null &&
                    (status == 'draft' || status == 'posted');

                return Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    if (!controller.isSelectedReturnReadOnly)
                      AppActionButton(
                        icon: Icons.save_outlined,
                        label: controller.selectedItem == null
                            ? 'Save Return'
                            : 'Update Return',
                        onPressed: controller.canEditSelectedReturn
                            ? () => controller.save(context)
                            : null,
                        busy: controller.saving,
                      ),
                    if (canPost)
                      AppActionButton(
                        icon: Icons.publish_outlined,
                        label: 'Post',
                        filled: false,
                        onPressed: () => controller.docAction(
                          context,
                          () => PurchaseService().postReturn(
                            intValue(controller.selectedItem!.toJson(), 'id')!,
                            PurchaseReturnModel.fromJson(
                              const <String, dynamic>{},
                            ),
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
                          () => PurchaseService().cancelReturn(
                            intValue(controller.selectedItem!.toJson(), 'id')!,
                            PurchaseReturnModel.fromJson(
                              const <String, dynamic>{},
                            ),
                          ),
                        ),
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
