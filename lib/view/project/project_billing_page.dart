import '../../controller/project/project_billing_management_controller.dart';
import '../../screen.dart';

class ProjectBillingManagementPage extends StatefulWidget {
  const ProjectBillingManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectBillingManagementPage> createState() =>
      _ProjectBillingManagementPageState();
}

class _ProjectBillingManagementPageState
    extends State<ProjectBillingManagementPage> {
  static const List<AppDropdownItem<String>> _basisItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'milestone', label: 'Milestone'),
        AppDropdownItem(value: 'timesheet', label: 'Timesheet'),
        AppDropdownItem(value: 'fixed', label: 'Fixed'),
        AppDropdownItem(value: 'cost_plus', label: 'Cost Plus'),
      ];

  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'invoiced', label: 'Invoiced'),
        AppDropdownItem(value: 'paid', label: 'Paid'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ProjectBillingManagementController',
    );
    Get.put(ProjectBillingManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectBillingManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewBilling(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.request_quote_outlined,
            label: 'New Billing',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Project Billings',
          actions: actions,
          scrollController: controller.pageScrollController,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectBillingManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading project billings...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project billings',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    final selectedRow = controller.selectedRow;
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Project Billings',
      editorTitle: selectedRow?.project.projectName,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<ProjectBillingRow>(
        searchController: controller.searchController,
        searchHint: 'Search billings',
        items: controller.filteredRows,
        selectedItem: controller.selectedRow,
        emptyMessage: 'No billings found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.project.projectName ?? 'Billing',
          subtitle: [
            row.billing.billingDate ?? '',
            row.billing.billingBasis ?? '',
            row.billing.billingStatus ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          onTap: () => controller.selectRow(row),
        ),
      ),
      editor: Form(
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
                  initialValue: controller.milestoneId,
                  labelText: 'Milestone',
                  mappedItems: controller.milestoneItems,
                  onChanged: controller.setMilestoneId,
                ),
                AppFormTextField(
                  controller: controller.billingDateController,
                  labelText: 'Billing Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Billing Date'),
                    Validators.optionalDate('Billing Date'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.basis,
                  labelText: 'Billing Basis',
                  mappedItems: _basisItems,
                  onChanged: (value) =>
                      controller.setBasis(value ?? controller.basis),
                ),
                AppFormTextField(
                  controller: controller.amountController,
                  labelText: 'Billing Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Billing Amount'),
                    Validators.optionalNonNegativeNumber('Billing Amount'),
                  ]),
                ),
                InlineFieldAction(
                  actionTooltip: 'Open sales invoices',
                  onAddNew: () => controller.openSalesInvoicePage(context),
                  field: AppSearchPickerField<int>(
                    labelText: 'Sales Invoice',
                    selectedLabel: controller.salesInvoiceLabel(
                      controller.salesInvoiceId,
                    ),
                    options: controller.salesInvoices
                        .where((invoice) => invoice.id != null)
                        .map(
                          (invoice) => AppSearchPickerOption<int>(
                            value: invoice.id!,
                            label:
                                controller.salesInvoiceLabel(invoice.id) ??
                                'Invoice #${invoice.id}',
                            subtitle: [
                              invoice.invoiceDate,
                              if (invoice.totalAmount != null)
                                'Amount ${controller.decimalText(invoice.totalAmount)}',
                            ].where((item) => item.isNotEmpty).join(' • '),
                            searchText: [
                              invoice.invoiceNo ?? '',
                              invoice.invoiceDate,
                              invoice.customerPartyId.toString(),
                              invoice.totalAmount?.toString() ?? '',
                            ].join(' '),
                          ),
                        )
                        .toList(growable: false),
                    hintText: 'Search sales invoice',
                    onChanged: controller.applySalesInvoice,
                  ),
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.status,
                  labelText: 'Billing Status',
                  mappedItems: _statusItems,
                  onChanged: (value) =>
                      controller.setStatus(value ?? controller.status),
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
              Text(
                controller.formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
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
                          final message = await controller.saveBilling();
                          if (!mounted || message == null) return;
                          appScaffoldMessengerKey.currentState
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(message)));
                        },
                  icon: controller.selectedRow?.billing.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: controller.saving ? 'Saving...' : 'Save Billing',
                  busy: controller.saving,
                ),
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () => controller.startNewBilling(
                          isDesktop: Responsive.isDesktop(context),
                        ),
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (controller.selectedRow?.billing.id != null)
                  AppActionButton(
                    onPressed: controller.saving
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Billing'),
                                content: const Text(
                                  'Remove this billing entry?',
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
                            if (confirmed != true) return;
                            final message = await controller.deleteBilling();
                            if (!mounted || message == null) return;
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
