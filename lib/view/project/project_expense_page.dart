import '../../controller/project/project_expense_management_controller.dart';
import '../../screen.dart';
import 'widgets/project_subtab_expandable_section.dart';

class ProjectExpenseManagementPage extends StatefulWidget {
  const ProjectExpenseManagementPage({
    super.key,
    this.embedded = false,
    this.constrainedProjectId,
    this.controllerScope = const <String, Object?>{},
    this.useShellActions = true,
  });

  final bool embedded;
  final int? constrainedProjectId;
  final Map<String, Object?> controllerScope;
  final bool useShellActions;

  @override
  State<ProjectExpenseManagementPage> createState() =>
      _ProjectExpenseManagementPageState();
}

class _ProjectExpenseManagementPageState
    extends State<ProjectExpenseManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'booked', label: 'Booked'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ProjectExpenseManagementController',
      scope: widget.controllerScope,
    );
    if (!Get.isRegistered<ProjectExpenseManagementController>(
      tag: _controllerTag,
    )) {
      Get.put(
        ProjectExpenseManagementController(
          constrainedProjectId: widget.constrainedProjectId,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProjectExpenseManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constrainedProjectId != widget.constrainedProjectId) {
      unawaited(_controller.applyProjectConstraint(widget.constrainedProjectId));
    }
  }

  ProjectExpenseManagementController get _controller =>
      Get.find<ProjectExpenseManagementController>(tag: _controllerTag);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectExpenseManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewExpense(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.receipt_long_outlined,
            label: 'New Expense',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded && widget.useShellActions) {
          return ShellPageActions(actions: actions, child: content);
        }
        if (widget.embedded) {
          return content;
        }
        return AppStandaloneShell(
          title: 'Project Expenses',
          actions: actions,
          scrollController: controller.pageScrollController,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectExpenseManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading project expenses...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project expenses',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    if (controller.isProjectConstrained) {
      return _buildConstrainedContent(context, controller);
    }

    final selectedRow = controller.selectedRow;
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Project Expenses',
      editorTitle: selectedRow?.expense.expenseCategory,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<ProjectExpenseRow>(
        searchController: controller.searchController,
        searchHint: 'Search expenses',
        items: controller.filteredRows,
        selectedItem: controller.selectedRow,
        emptyMessage: 'No expenses found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.expense.expenseCategory ?? 'Expense',
          subtitle: [
            row.project.projectName ?? '',
            row.expense.expenseDate ?? '',
            row.expense.expenseStatus ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          onTap: () => controller.selectRow(row),
        ),
      ),
      editorBuilder: (_) => _buildEditorForm(context, controller),
    );
  }

  Widget _buildConstrainedContent(
    BuildContext context,
    ProjectExpenseManagementController controller,
  ) {
    return ProjectSubtabExpandableSection(
      title: 'Project Expenses',
      description:
          'Manage project expense entries, vendors, invoices, and booked values for the selected project.',
      addLabel: 'Add Expense',
      addIcon: Icons.receipt_long_outlined,
      onAdd: controller.saving
          ? null
          : () => controller.startNewExpense(
                isDesktop: Responsive.isDesktop(context),
              ),
      addEnabled: !controller.saving,
      emptyMessage: 'No expenses found.',
      showDraftTile:
          controller.showDraftTile && controller.selectedRow == null,
      draftTitle: 'New Expense',
      draftSubtitle: 'Add an expense entry for this project.',
      onDraftToggle: controller.hideDraftTile,
      draftChild: _buildEditorForm(context, controller),

      recordTiles: controller.filteredRows.map((row) {
        final expanded = controller.selectedRow?.expense.id == row.expense.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
          child: SettingsExpandableTile(
            key: ValueKey<String>('project-expense-${row.expense.id}-$expanded'),
            title: row.expense.expenseCategory ?? 'Expense',
            subtitle: [
              row.expense.expenseDate ?? '',
              row.expense.expenseStatus ?? '',
            ].where((item) => item.isNotEmpty).join(' | '),
            detail: [
              controller.purchaseInvoiceLabel(row.expense.purchaseInvoiceId) ?? '',
              row.expense.amount?.toString() ?? '',
            ].where((item) => item.isNotEmpty).join(' | '),
            expanded: expanded,
            highlighted: expanded,
            leadingIcon: Icons.receipt_long_outlined,
            trailing: IconButton(
              tooltip: 'Delete expense',
              onPressed: controller.saving
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete Expense'),
                          content: const Text('Remove this expense entry?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => Navigator.of(dialogContext).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) {
                        return;
                      }
                      controller.selectRow(row);
                      final message = await controller.deleteExpense();
                      if (!mounted || message == null) {
                        return;
                      }
                      appScaffoldMessengerKey.currentState
                        ?..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(message)));
                    },
              icon: const Icon(Icons.remove_circle_outline),
            ),
            onToggle: () {
              if (expanded) {
                controller.resetForm();
              } else {
                controller.selectRow(row);
              }
            },
            child: expanded ? _buildEditorForm(context, controller) : const SizedBox.shrink(),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildEditorForm(
    BuildContext context,
    ProjectExpenseManagementController controller,
  ) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsFormWrap(
            children: [
              if (!controller.isProjectConstrained)
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.projectId,
                  labelText: 'Project',
                  mappedItems: controller.projectItems,
                  onChanged: controller.setProjectId,
                  validator: Validators.requiredSelection('Project'),
                ),
              AppDropdownField<int>.fromMapped(
                initialValue: controller.taskId,
                labelText: 'Task',
                mappedItems: controller.taskItems,
                onChanged: controller.setTaskId,
              ),
              AppFormTextField(
                controller: controller.expenseDateController,
                labelText: 'Expense Date',
                keyboardType: TextInputType.datetime,
                inputFormatters: const [DateInputFormatter()],
                validator: Validators.compose([
                  Validators.required('Expense Date'),
                  Validators.optionalDate('Expense Date'),
                ]),
              ),
              AppFormTextField(
                controller: controller.categoryController,
                labelText: 'Expense Category',
                validator: Validators.compose([
                  Validators.required('Expense Category'),
                  Validators.optionalMaxLength(100, 'Expense Category'),
                ]),
              ),
              AppDropdownField<int>.fromMapped(
                initialValue: controller.supplierPartyId,
                labelText: 'Supplier',
                mappedItems: controller.partyItems,
                onChanged: controller.setSupplierPartyId,
              ),
              AppSearchPickerField<int>(
                labelText: 'Purchase Invoice',
                selectedLabel: controller.purchaseInvoiceLabel(
                  controller.purchaseInvoiceId,
                ),
                options: controller.purchaseInvoices
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppSearchPickerOption<int>(
                        value: item.id!,
                        label: item.invoiceNo?.trim().isNotEmpty == true
                            ? item.invoiceNo!
                            : 'Invoice #${item.id}',
                        subtitle: [
                          if (item.invoiceDate.trim().isNotEmpty)
                            item.invoiceDate,
                          if (item.totalAmount != null)
                            controller.purchaseInvoiceById(item.id)?.totalAmount
                                    ?.toString() ??
                                '',
                        ].where((item) => item.isNotEmpty).join(' • '),
                        searchText: [
                          item.invoiceNo ?? '',
                          item.invoiceDate,
                          item.id.toString(),
                        ].join(' '),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.applyPurchaseInvoice,
              ),
              AppDropdownField<String>.fromMapped(
                initialValue: controller.status,
                labelText: 'Status',
                mappedItems: _statusItems,
                onChanged: (value) =>
                    controller.setStatus(value ?? controller.status),
              ),
              AppFormTextField(
                controller: controller.amountController,
                labelText: 'Amount',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.compose([
                  Validators.required('Amount'),
                  Validators.optionalNonNegativeNumber('Amount'),
                ]),
              ),
              AppFormTextField(
                controller: controller.voucherIdController,
                labelText: 'Voucher ID',
                readOnly: true,
              ),
              AppFormTextField(
                controller: controller.descriptionController,
                labelText: 'Description',
                maxLines: 3,
                validator: Validators.compose([
                  Validators.required('Description'),
                  Validators.optionalMaxLength(500, 'Description'),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppFormTextField(
            controller: controller.remarksController,
            labelText: 'Remarks',
            maxLines: 3,
            validator: Validators.optionalMaxLength(500, 'Remarks'),
          ),
          if ((controller.formError ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            AppErrorStateView.inline(message: controller.formError!),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppActionButton(
                onPressed: controller.saving
                    ? null
                    : () async {
                        final message = await controller.saveExpense();
                        if (!mounted || message == null) {
                          return;
                        }
                        appScaffoldMessengerKey.currentState
                          ?..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(message)));
                      },
                icon: controller.selectedRow?.expense.id == null
                    ? Icons.add
                    : Icons.save_outlined,
                label: controller.saving ? 'Saving...' : 'Save Expense',
                busy: controller.saving,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
