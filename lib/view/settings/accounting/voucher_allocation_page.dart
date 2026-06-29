import '../../../controller/settings/accounting/voucher_allocation_management_controller.dart';
import '../../../screen.dart';

class VoucherAllocationManagementPage extends StatefulWidget {
  const VoucherAllocationManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<VoucherAllocationManagementPage> createState() =>
      _VoucherAllocationManagementPageState();
}

class _VoucherAllocationManagementPageState
    extends State<VoucherAllocationManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'VoucherAllocationManagementController',
      scope: <String, Object?>{
        'identity': identityHashCode(this),
        'embedded': widget.embedded,
      },
    );
    _registerController();
  }

  @override
  void dispose() {
    if (Get.isRegistered<VoucherAllocationManagementController>(
      tag: _controllerTag,
    )) {
      Get.delete<VoucherAllocationManagementController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  void _registerController() {
    if (Get.isRegistered<VoucherAllocationManagementController>(
      tag: _controllerTag,
    )) {
      return;
    }
    Get.put(VoucherAllocationManagementController(), tag: _controllerTag);
  }

  Future<void> _confirmDelete(
    VoucherAllocationManagementController controller,
  ) async {
    final id = controller.editing?.id;
    if (id == null || !controller.canDelete) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete allocation'),
        content: Text(
          'Remove allocation ${controller.editing?.referenceNo ?? '#$id'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.deleteAllocation();
    }
  }

  List<Widget> _buildShellActions(
    VoucherAllocationManagementController controller,
  ) {
    return [
      AdaptiveShellActionButton(
        onPressed: controller.saving ? null : controller.startNewAllocation,
        icon: Icons.add_outlined,
        label: 'New allocation',
        filled: false,
      ),
      AdaptiveShellActionButton(
        onPressed: controller.loading ? null : controller.fetch,
        icon: Icons.refresh_outlined,
        label: 'Refresh',
        filled: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VoucherAllocationManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(
            actions: _buildShellActions(controller),
            child: content,
          );
        }
        return AppStandaloneShell(
          title: 'Voucher Allocations',
          scrollController: controller.pageScrollController,
          actions: _buildShellActions(controller),
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    VoucherAllocationManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading voucher allocations...');
    }
    if (controller.pageError != null &&
        controller.rows.isEmpty &&
        controller.sourceVoucherId == null) {
      return AppErrorStateView(
        title: 'Unable to load voucher allocations',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    final sourceVoucherItems = controller.sourceVoucherItems;
    final sourceLineItems = controller.sourceLineItems;
    final againstVoucherItems = controller.againstVoucherItems;
    final againstLineItems = controller.againstLineItems;

    return SingleChildScrollView(
      controller: controller.pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.pageError != null) ...[
            AppErrorStateView.inline(message: controller.pageError!),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Source voucher line',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Text(
                  'Allocations are maintained against one voucher line at a time. Pick the source voucher first, then its ledger line.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final columnCount = availableWidth >= 980
                        ? 3
                        : availableWidth >= 680
                        ? 2
                        : 1;
                    final fieldWidth =
                        (availableWidth -
                            (columnCount - 1) * AppUiConstants.spacingMd) /
                        columnCount;

                    Widget fieldBox(Widget child) =>
                        SizedBox(width: fieldWidth, child: child);

                    return Wrap(
                      spacing: AppUiConstants.spacingMd,
                      runSpacing: AppUiConstants.spacingSm,
                      children: [
                        fieldBox(
                          AppDropdownField<int>.fromMapped(
                            labelText: 'Source voucher',
                            mappedItems: sourceVoucherItems,
                            initialValue: controller.sourceVoucherId,
                            onChanged: controller.setSourceVoucherId,
                            validator: Validators.requiredSelection(
                              'Source voucher',
                            ),
                          ),
                        ),
                        fieldBox(
                          AppDropdownField<int>.fromMapped(
                            labelText: 'Source line',
                            mappedItems: sourceLineItems,
                            initialValue: controller.sourceLineId,
                            onChanged: controller.setSourceLineId,
                            validator: Validators.requiredSelection(
                              'Source line',
                            ),
                          ),
                        ),
                        fieldBox(
                          AppFormTextField(
                            labelText: 'Search allocations',
                            controller: controller.searchController,
                            hintText: 'Reference, type, amount',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (controller.sourceLineSummary().isNotEmpty) ...[
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Text(
                    controller.sourceLineSummary(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.editing == null
                      ? 'New allocation'
                      : 'Edit allocation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (controller.formError != null) ...[
                  const SizedBox(height: AppUiConstants.spacingMd),
                  AppErrorStateView.inline(message: controller.formError!),
                ],
                const SizedBox(height: AppUiConstants.spacingMd),
                if (controller.sourceLineId == null)
                  const Text('Select a source line to create allocations.')
                else if (!controller.canEdit)
                  const Text(
                    'You do not have permission to create or update allocations.',
                  )
                else
                  Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final columnCount = availableWidth >= 980
                                ? 3
                                : availableWidth >= 680
                                ? 2
                                : 1;
                            final fieldWidth =
                                (availableWidth -
                                    (columnCount - 1) *
                                        AppUiConstants.spacingMd) /
                                columnCount;

                            Widget fieldBox(Widget child) =>
                                SizedBox(width: fieldWidth, child: child);

                            return Wrap(
                              spacing: AppUiConstants.spacingMd,
                              runSpacing: AppUiConstants.spacingSm,
                              children: [
                                fieldBox(
                                  AppDropdownField<String>.fromMapped(
                                    labelText: 'Allocation type',
                                    mappedItems:
                                        VoucherAllocationManagementController
                                            .allocationTypeItems,
                                    initialValue: controller.allocationType,
                                    onChanged: controller.setAllocationType,
                                    validator: Validators.requiredSelection(
                                      'Allocation type',
                                    ),
                                  ),
                                ),
                                fieldBox(
                                  AppFormTextField(
                                    labelText: 'Reference no.',
                                    controller:
                                        controller.referenceNoController,
                                    validator: Validators.compose([
                                      Validators.required('Reference no.'),
                                      Validators.optionalMaxLength(
                                        100,
                                        'Reference no.',
                                      ),
                                    ]),
                                  ),
                                ),
                                fieldBox(
                                  AppDateField(
                                    labelText: 'Reference date',
                                    controller:
                                        controller.referenceDateController,
                                    validator: Validators.optionalDate(
                                      'Reference date',
                                    ),
                                  ),
                                ),
                                fieldBox(
                                  AppFormTextField(
                                    labelText: 'Allocation amount',
                                    controller:
                                        controller.allocationAmountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator:
                                        Validators.requiredPositiveNumber(
                                          'Allocation amount',
                                        ),
                                  ),
                                ),
                                fieldBox(
                                  AppDropdownField<int?>.fromMapped(
                                    labelText: 'Against voucher',
                                    mappedItems: <AppDropdownItem<int?>>[
                                      const AppDropdownItem<int?>(
                                        value: null,
                                        label: 'None',
                                      ),
                                      ...againstVoucherItems.map(
                                        (item) => AppDropdownItem<int?>(
                                          value: item.value,
                                          label: item.label,
                                        ),
                                      ),
                                    ],
                                    initialValue: controller.againstVoucherId,
                                    onChanged: controller.setAgainstVoucherId,
                                  ),
                                ),
                                fieldBox(
                                  AppDropdownField<int?>.fromMapped(
                                    labelText: 'Against voucher line',
                                    mappedItems: <AppDropdownItem<int?>>[
                                      const AppDropdownItem<int?>(
                                        value: null,
                                        label: 'None',
                                      ),
                                      ...againstLineItems.map(
                                        (item) => AppDropdownItem<int?>(
                                          value: item.value,
                                          label: item.label,
                                        ),
                                      ),
                                    ],
                                    initialValue:
                                        controller.againstVoucherLineId,
                                    onChanged:
                                        controller.setAgainstVoucherLineId,
                                  ),
                                ),
                                fieldBox(
                                  AppFormTextField(
                                    labelText: 'Remarks',
                                    controller: controller.remarksController,
                                    maxLines: 1,
                                    validator: Validators.optionalMaxLength(
                                      1000,
                                      'Remarks',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppUiConstants.spacingLg),
                        Row(
                          children: [
                            if (controller.editing?.id != null &&
                                controller.canDelete)
                              TextButton(
                                onPressed: controller.saving
                                    ? null
                                    : () => _confirmDelete(controller),
                                child: const Text('Delete'),
                              ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed:
                                  (controller.saving || !controller.canEdit)
                                  ? null
                                  : controller.saveAllocation,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                controller.saving ? 'Saving...' : 'Save',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          AppSectionCard(
            child: controller.loading && controller.rows.isEmpty
                ? const AppLoadingView(message: 'Loading allocations...')
                : controller.sourceLineId == null
                ? const SettingsEmptyState(
                    icon: Icons.call_split_outlined,
                    title: 'Pick a source line',
                    message:
                        'Choose a voucher and line above to review or edit allocations.',
                  )
                : controller.filteredRows.isEmpty
                ? const SettingsEmptyState(
                    icon: Icons.call_split_outlined,
                    title: 'No allocations',
                    message:
                        'No allocations exist for this voucher line yet. Add one with the form above.',
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowHeight: 40,
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 64,
                            columns: const [
                              DataColumn(label: Text('Reference')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Amount')),
                              DataColumn(label: Text('Remarks')),
                              DataColumn(label: Text('')),
                            ],
                            rows: controller.filteredRows
                                .map((row) {
                                  final selected =
                                      controller.editing?.id == row.id;
                                  return DataRow(
                                    selected: selected,
                                    cells: [
                                      DataCell(Text(row.referenceNo ?? '-')),
                                      DataCell(Text(row.referenceDate ?? '-')),
                                      DataCell(Text(row.allocationType ?? '-')),
                                      DataCell(
                                        Text(
                                          row.allocationAmount?.toStringAsFixed(
                                                2,
                                              ) ??
                                              '-',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          row.remarks?.isNotEmpty == true
                                              ? row.remarks!
                                              : '-',
                                        ),
                                      ),
                                      DataCell(
                                        IconButton(
                                          tooltip: 'Edit',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () =>
                                              controller.editRow(row),
                                        ),
                                      ),
                                    ],
                                  );
                                })
                                .toList(growable: false),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
