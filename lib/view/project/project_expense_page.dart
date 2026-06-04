import '../../controller/project/project_expense_management_controller.dart';
import '../../screen.dart';

class ProjectExpenseManagementPage extends StatefulWidget {
  const ProjectExpenseManagementPage({super.key, this.embedded = false});

  final bool embedded;

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
    );
    Get.put(ProjectExpenseManagementController(), tag: _controllerTag);
  }

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
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
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
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
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
                              controller
                                      .purchaseInvoiceById(item.id)
                                      ?.totalAmount
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
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () => controller.startNewExpense(
                          isDesktop: Responsive.isDesktop(context),
                        ),
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (controller.selectedRow?.expense.id != null)
                  AppActionButton(
                    onPressed: controller.saving
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Expense'),
                                content: const Text(
                                  'Remove this expense entry?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) {
                              return;
                            }
                            final message = await controller.deleteExpense();
                            if (!mounted || message == null) {
                              return;
                            }
                            appScaffoldMessengerKey.currentState
                              ?..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(message)));
                          },
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
