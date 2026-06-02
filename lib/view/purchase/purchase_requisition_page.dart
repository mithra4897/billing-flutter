import '../../controller/purchase/purchase_requisition_management_controller.dart';
import '../../screen.dart';

class PurchaseRequisitionPage extends StatefulWidget {
  const PurchaseRequisitionPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PurchaseRequisitionPage> createState() =>
      _PurchaseRequisitionPageState();
}

class _PurchaseRequisitionPageState extends State<PurchaseRequisitionPage> {
  late final String _controllerTag;

  PurchaseRequisitionManagementController get _controller =>
      Get.find<PurchaseRequisitionManagementController>(tag: _controllerTag);

  String _statusLabel(String? status) {
    final normalized = status?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '';
    }
    return normalized.replaceAll('_', ' ').titleCase;
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'PurchaseRequisitionManagementController',
      scope: <String, Object?>{'identity': identityHashCode(this)},
    );
    Get.put(PurchaseRequisitionManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_controller.initialize(initialId: widget.initialId));
    });
  }

  @override
  void dispose() {
    Get.delete<PurchaseRequisitionManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchaseRequisitionManagementController>(
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
            label: 'New Requisition',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Purchase Requisitions',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PurchaseRequisitionManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading purchase requisitions...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase requisitions',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Purchase Requisitions',
      editorTitle: controller.selectedItem == null
          ? 'New Purchase Requisition'
          : stringValue(
              controller.selectedItem!.toJson(),
              'requisition_no',
              'Purchase Requisition',
            ),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<PurchaseRequisitionModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No purchase requisitions found.',
        searchController: controller.searchController,
        searchHint: 'Search requisitions',
        statusValue: controller.statusFilter,
        statusItems: PurchaseRequisitionManagementController.statusItems,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'requisition_no', 'Draft Requisition'),
            subtitle: [
              displayDate(nullableStringValue(data, 'requisition_date')),
              _statusLabel(nullableStringValue(data, 'requisition_status')),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: stringValue(data, 'purpose'),
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
            if (controller.isSelectedRequisitionReadOnly) ...[
              Text(
                purchaseReadOnlyMessage(
                  'purchase requisition',
                  nullableStringValue(
                    controller.selectedItem?.toJson() ?? const {},
                    'requisition_status',
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            IgnorePointer(
              ignoring: controller.isSelectedRequisitionReadOnly,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsFormWrap(
                    children: [
                      DocumentSeriesSelector<int>(
                        labelText: 'Document Series',
                        mappedItems: controller
                            .documentSeriesForContext()
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
                        labelText: 'Requisition No',
                        controller: controller.requisitionNoController,
                        hintText: 'Auto-generated on save',
                        validator: Validators.optionalMaxLength(
                          100,
                          'Requisition No',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Requisition Date',
                        controller: controller.requisitionDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.compose([
                          Validators.required('Requisition Date'),
                          Validators.date('Requisition Date'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Required Date',
                        controller: controller.requiredDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.compose([
                          Validators.optionalDate('Required Date'),
                          Validators.optionalDateOnOrAfter(
                            'Required Date',
                            () => controller.requisitionDateController.text
                                .trim(),
                            startFieldName: 'Requisition Date',
                          ),
                        ]),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Requested By',
                        mappedItems: controller.users
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.requestedById,
                        onChanged: controller.setRequestedById,
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Department',
                        mappedItems: controller.departmentItems,
                        initialValue: controller.departmentName,
                        onChanged: controller.setDepartmentName,
                      ),
                      AppFormTextField(
                        labelText: 'Purpose',
                        controller: controller.purposeController,
                        validator: Validators.optionalMaxLength(255, 'Purpose'),
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
                        onPressed: controller.isSelectedRequisitionReadOnly
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
                        child: _buildLineFields(context, controller, line),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                Builder(
                  builder: (_) {
                    final selectedData =
                        controller.selectedItem?.toJson() ??
                        const <String, dynamic>{};
                    final status = stringValue(
                      selectedData,
                      'requisition_status',
                    );
                    final canApprove =
                        controller.selectedItem != null && status == 'draft';
                    final canClose =
                        controller.selectedItem != null &&
                        status != 'closed' &&
                        status != 'cancelled';
                    final canCancel =
                        controller.selectedItem != null &&
                        status != 'closed' &&
                        status != 'cancelled';

                    return Wrap(
                      spacing: AppUiConstants.spacingSm,
                      runSpacing: AppUiConstants.spacingSm,
                      children: [
                        if (!controller.isSelectedRequisitionReadOnly)
                          AppActionButton(
                            icon: Icons.save_outlined,
                            label: controller.selectedItem == null
                                ? 'Save Requisition'
                                : 'Update Requisition',
                            onPressed: controller.canEditSelectedRequisition
                                ? () => controller.save(context)
                                : null,
                            busy: controller.saving,
                          ),
                        if (canApprove)
                          AppActionButton(
                            icon: Icons.check_circle_outline,
                            label: 'Approve',
                            onPressed: () => controller.executeAction(
                              context,
                              () => PurchaseService().approveRequisition(
                                intValue(
                                  controller.selectedItem!.toJson(),
                                  'id',
                                )!,
                                PurchaseRequisitionModel.fromJson(
                                  const <String, dynamic>{},
                                ),
                              ),
                            ),
                            filled: false,
                          ),
                        if (canClose)
                          AppActionButton(
                            icon: Icons.task_alt_outlined,
                            label: 'Close',
                            onPressed: () => controller.executeAction(
                              context,
                              () => PurchaseService().closeRequisition(
                                intValue(
                                  controller.selectedItem!.toJson(),
                                  'id',
                                )!,
                                PurchaseRequisitionModel.fromJson(
                                  const <String, dynamic>{},
                                ),
                              ),
                            ),
                            filled: false,
                          ),
                        if (canCancel)
                          AppActionButton(
                            icon: Icons.cancel_outlined,
                            label: 'Cancel',
                            onPressed: () => controller.executeAction(
                              context,
                              () => PurchaseService().cancelRequisition(
                                intValue(
                                  controller.selectedItem!.toJson(),
                                  'id',
                                )!,
                                PurchaseRequisitionModel.fromJson(
                                  const <String, dynamic>{},
                                ),
                              ),
                            ),
                            filled: false,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineFields(
    BuildContext context,
    PurchaseRequisitionManagementController controller,
    PurchaseRequisitionLineDraft line,
  ) {
    final itemPicker = AppSearchPickerField<int>(
      labelText: 'Item',
      selectedLabel: controller.itemsLookup
          .cast<ItemModel?>()
          .firstWhere((item) => item?.id == line.itemId, orElse: () => null)
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
      onChanged: (value) => controller.setLineItemId(line, value),
      validator: (_) => Validators.requiredSelectionField(line.itemId, 'Item'),
    );

    final uomOptions = controller.uomOptionsForItem(line.itemId);
    if (uomOptions.length <= 1) {
      final onlyId = uomOptions.isNotEmpty ? uomOptions.first.id : null;
      if (line.uomId != onlyId) {
        line.uomId = onlyId;
      }
    }

    final Widget uomField = uomOptions.length <= 1
        ? AppFormTextField(
            labelText: 'UOM',
            initialValue: uomOptions.isNotEmpty
                ? uomOptions.first.toString()
                : '',
            readOnly: true,
          )
        : AppDropdownField<int>.fromMapped(
            labelText: 'UOM',
            mappedItems: uomOptions
                .where((item) => item.id != null)
                .map(
                  (item) =>
                      AppDropdownItem(value: item.id!, label: item.toString()),
                )
                .toList(growable: false),
            initialValue: line.uomId,
            onChanged: (value) => controller.setLineUomId(line, value),
            validator: Validators.requiredSelection('UOM'),
          );

    return PurchaseCompactFieldGrid(
      children: [
        itemPicker,
        uomField,
        AppDropdownField<int>.fromMapped(
          labelText: 'Warehouse',
          mappedItems: controller.warehouses
              .where((item) => item.id != null)
              .map(
                (item) =>
                    AppDropdownItem(value: item.id!, label: item.toString()),
              )
              .toList(growable: false),
          initialValue: line.warehouseId,
          onChanged: (value) => controller.setLineWarehouseId(line, value),
        ),
        AppFormTextField(
          labelText: 'Requested Qty',
          controller: line.requestedQtyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: Validators.compose([
            Validators.required('Requested Qty'),
            Validators.optionalNonNegativeNumber('Requested Qty'),
          ]),
        ),
        AppFormTextField(
          labelText: 'Estimated Rate',
          controller: line.estimatedRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: Validators.optionalNonNegativeNumber('Estimated Rate'),
        ),
        AppFormTextField(
          labelText: 'Description',
          controller: line.descriptionController,
          validator: Validators.optionalMaxLength(500, 'Description'),
        ),
        AppFormTextField(
          labelText: 'Remarks',
          controller: line.remarksController,
          maxLines: 2,
          validator: Validators.optionalMaxLength(500, 'Remarks'),
        ),
      ],
    );
  }
}
