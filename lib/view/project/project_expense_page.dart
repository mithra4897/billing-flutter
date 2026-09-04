import '../../components/app_progress_bar.dart';
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
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final int? constrainedProjectId;
  final Map<String, Object?> controllerScope;
  final bool useShellActions;
  final bool editorOnly;
  final int? initialId;

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

  bool _filtersVisible = false;

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
          initialRecordId: widget.initialId,
          startWithNewRecord: widget.editorOnly && widget.initialId == null,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProjectExpenseManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constrainedProjectId != widget.constrainedProjectId) {
      unawaited(
        _controller.applyProjectConstraint(widget.constrainedProjectId),
      );
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
          AdaptiveShellSearchField(
            controller: controller.searchController,
            hintText: 'Search expenses',
          ),
          AdaptiveShellActionButton(
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
            icon: Icons.filter_list_outlined,
            label: 'Filter',
          ),
          AdaptiveShellActionButton(
            onPressed: () {
              controller.resetForm();
              _openEditor(context, controller);
            },
            icon: Icons.receipt_long_outlined,
            label: 'New Expense',
          ),
        ];

        if (widget.editorOnly) {
          final content = _buildEditorRouteContent(context, controller);
          return widget.embedded
              ? ShellPageActions(actions: const <Widget>[], child: content)
              : AppStandaloneShell(
                  title: 'Project Expense',
                  scrollController: controller.pageScrollController,
                  actions: const <Widget>[],
                  child: content,
                );
        }
        return _buildContent(
          context,
          controller,
          widget.useShellActions ? actions : const <Widget>[],
        );
      },
    );
  }

  Widget _buildEditorRouteContent(
    BuildContext context,
    ProjectExpenseManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading project expense...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project expense',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }
    return SingleChildScrollView(
      controller: controller.pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: AppSectionCard(child: _buildEditorForm(context, controller)),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectExpenseManagementController controller,
    List<Widget> actions,
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

    final columns = <PurchaseRegisterColumn<ProjectExpenseRow>>[
      PurchaseRegisterColumn(
        label: 'Project',
        flex: 3,
        valueBuilder: (row) => row.project.projectName ?? '',
      ),
      PurchaseRegisterColumn(
        label: 'Category',
        flex: 2,
        valueBuilder: (row) => row.expense.expenseCategory ?? '',
      ),
      PurchaseRegisterColumn(
        label: 'Date',
        flex: 2,
        valueBuilder: (row) => normalizeDateValue(row.expense.expenseDate),
      ),
      PurchaseRegisterColumn(
        label: 'Description',
        flex: 3,
        valueBuilder: (row) => row.expense.description ?? '',
      ),
      PurchaseRegisterColumn<ProjectExpenseRow>(
        label: 'Status',
        flex: 3,
        padding: const EdgeInsets.only(left: AppUiConstants.spacingMd),
        valueBuilder: (row) => row.expense.expenseStatus ?? '',
        widgetBuilder: (context, row) {
          final status = row.expense.expenseStatus ?? '';
          final trimmed = status.trim().toLowerCase();
          final error = trimmed == 'rejected';
          final progress = trimmed == 'approved'
              ? 1.0
              : trimmed == 'rejected'
              ? 0.0
              : 0.2;
          final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
          final color = error
              ? Theme.of(context).colorScheme.error
              : progress >= 1.0
              ? appTheme.success
              : progress > 0
              ? appTheme.info
              : appTheme.warning;

          return AppProgressBar(
            label: status.isEmpty
                ? '-'
                : status[0].toUpperCase() +
                      status.substring(1).replaceAll('_', ' '),
            progress: error ? 0.0 : progress,
            color: color,
          );
        },
      ),
      PurchaseRegisterColumn(
        label: 'Amount',
        flex: 2,
        alignRight: true,
        valueBuilder: (row) => formatAmount(row.expense.amount),
      ),
    ];

    return PurchaseRegisterPage<ProjectExpenseRow>(
      title: 'Project Expenses',
      loading: false,
      errorMessage: null,
      onRetry: controller.loadData,
      embedded: widget.embedded,
      fullPageStyle: true,
      emphasizeRows: false,
      emptyMessage: 'No expenses found.',
      actions: actions,
      rows: controller.filteredRows,
      columns: columns,
      onRowTap: (row) {
        controller.selectRow(row);
        _openEditor(context, controller);
      },
      filters: _filtersVisible ? _buildFilterPanel(controller) : null,
    );
  }

  Widget _buildFilterPanel(ProjectExpenseManagementController controller) {
    return AppRegisterFilters(
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      statusItems: _statusItems,
      selectedStatuses: controller.selectedStatuses,
      onStatusesChanged: controller.setStatuses,
      onClear: controller.clearFilters,
    );
  }

  void _openEditor(
    BuildContext context,
    ProjectExpenseManagementController controller,
  ) {
    if (widget.embedded && !controller.isProjectConstrained) {
      openShellRoute(
        context,
        '/projects/expenses/${controller.selectedRow?.expense.id ?? 'new'}',
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GetBuilder<ProjectExpenseManagementController>(
          tag: _controllerTag,
          builder: (ctrl) => AppStandaloneShell(
            title: ctrl.selectedRow == null
                ? 'New Project Expense'
                : 'Edit Project Expense',
            scrollController: ScrollController(),
            actions: const <Widget>[],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppUiConstants.pagePadding),
              child: AppSectionCard(child: _buildEditorForm(context, ctrl)),
            ),
          ),
        ),
      ),
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
      showDraftTile: controller.showDraftTile && controller.selectedRow == null,
      draftTitle: 'New Expense',
      draftSubtitle: 'Add an expense entry for this project.',
      onDraftToggle: controller.hideDraftTile,
      draftChild: _buildEditorForm(context, controller),

      recordTiles: controller.filteredRows
          .map((row) {
            final expanded =
                controller.selectedRow?.expense.id == row.expense.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                key: ValueKey<String>(
                  'project-expense-${row.expense.id}-$expanded',
                ),
                title: row.expense.expenseCategory ?? 'Expense',
                subtitle: [
                  normalizeDateValue(row.expense.expenseDate),
                  row.expense.expenseStatus ?? '',
                ].where((item) => item.isNotEmpty).join(' | '),
                detail: [
                  controller.purchaseInvoiceLabel(
                        row.expense.purchaseInvoiceId,
                      ) ??
                      '',
                  formatAmount(row.expense.amount),
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
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
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
                child: expanded
                    ? _buildEditorForm(context, controller)
                    : const SizedBox.shrink(),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildEditorForm(
    BuildContext context,
    ProjectExpenseManagementController controller,
  ) {
    return Form(
      child: Builder(
        builder: (formContext) => Column(
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
                  textAlign: TextAlign.right,
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
            const SizedBox(height: AppUiConstants.spacingXs),
            AppFormTextField(
              controller: controller.remarksController,
              labelText: 'Remarks',
              maxLines: 3,
              validator: Validators.optionalMaxLength(500, 'Remarks'),
            ),
            if ((controller.formError ?? '').isNotEmpty) ...[
              const SizedBox(height: AppUiConstants.spacingSm),
              AppErrorStateView.inline(message: controller.formError!),
            ],
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () async {
                          if (!Form.of(formContext).validate()) {
                            return;
                          }
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
      ),
    );
  }
}
