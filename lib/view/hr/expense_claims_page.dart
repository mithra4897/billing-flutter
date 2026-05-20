import '../../controller/hr/expense_claims_management_controller.dart';
import '../../screen.dart';

void _expenseClaimsNeedCompanySnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Choose a company in the header session control before using expense claims.',
      ),
    ),
  );
}

class ExpenseClaimsManagementPage extends StatefulWidget {
  const ExpenseClaimsManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ExpenseClaimsManagementPage> createState() =>
      _ExpenseClaimsManagementPageState();
}

class _ExpenseClaimsManagementPageState
    extends State<ExpenseClaimsManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ExpenseClaimsManagementController',
    );
    Get.put(
      ExpenseClaimsManagementController(),
      tag: _controllerTag,
      permanent: true,
    );
  }

  ExpenseClaimsManagementController get _controller =>
      Get.find<ExpenseClaimsManagementController>(tag: _controllerTag);

  Future<void> _openExpenseFilterPanel() async {
    final controller = _controller;
    final applied = await showHrListFilterDialog(
      context: context,
      title: 'Filter Expense Claims',
      header: controller.companyBanner == null
          ? null
          : Text(
              'Session company: ${controller.companyBanner}. Change via the header '
              'session button.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
      filterFields: [
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.searchController,
            labelText: 'Search',
            hintText: 'Search claims…',
          ),
        ),
        if (controller.canViewAllClaims)
          hrListFilterBox(
            child: AppDropdownField<int?>.fromMapped(
              labelText: 'Employee filter',
              mappedItems: <AppDropdownItem<int?>>[
                const AppDropdownItem<int?>(
                  value: null,
                  label: 'All employees',
                ),
                ...controller.employees
                    .where(
                      (employee) =>
                          employee.companyId == controller.companyId &&
                          employee.id != null,
                    )
                    .map(
                      (employee) => AppDropdownItem<int?>(
                        value: employee.id,
                        label: employee.toString(),
                      ),
                    ),
              ],
              initialValue: controller.filterEmployeeId,
              onChanged: controller.setFilterEmployeeId,
            ),
          ),
        hrListFilterBox(
          child: AppDropdownField<String?>.fromMapped(
            labelText: 'Payment',
            mappedItems: ExpenseClaimsManagementController.paymentFilterItems,
            initialValue: controller.filterPaymentStatus,
            onChanged: controller.setFilterPaymentStatus,
          ),
        ),
        hrListFilterBox(
          child: AppDropdownField<String?>.fromMapped(
            labelText: 'Status',
            mappedItems: ExpenseClaimsManagementController.statusFilterItems,
            initialValue: controller.filterClaimStatus,
            onChanged: controller.setFilterClaimStatus,
          ),
        ),
      ],
      onClear: controller.clearExpenseFilters,
    );
    if (applied == true && mounted) {
      await controller.loadPage();
    }
  }

  Future<void> _submitClaim({
    required ExpenseClaimsManagementController controller,
    required bool applyNow,
  }) async {
    final message = await controller.submitClaim(applyNow: applyNow);
    if (!mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approveClaim(
    ExpenseClaimsManagementController controller,
  ) async {
    final claimId = controller.editingClaimId;
    if (claimId == null) {
      return;
    }
    try {
      final response = await controller.hrService.approveExpenseClaim(
        claimId,
        ExpenseClaimModel.fromJson(<String, dynamic>{}),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(response.message)));
      if (response.success == true) {
        await controller.reloadEditorAndListAfterMutation(claimId: claimId);
      } else {
        controller.formError = response.message;
        controller.update();
      }
    } on ApiException catch (errorValue) {
      if (!mounted) {
        return;
      }
      controller.formError = errorValue.message;
      controller.update();
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(errorValue.displayMessage)));
    }
  }

  Future<void> _openRejectDialog(
    ExpenseClaimsManagementController controller,
  ) async {
    final claimId = controller.editingClaimId;
    if (claimId == null) {
      return;
    }
    await openExpenseClaimRejectDialog(
      context,
      hr: controller.hrService,
      claimId: claimId,
      onChanged: () =>
          controller.reloadEditorAndListAfterMutation(claimId: claimId),
    );
  }

  Future<void> _openCancelDraftDialog(
    ExpenseClaimsManagementController controller,
  ) async {
    final claimId = controller.editingClaimId;
    if (claimId == null) {
      return;
    }
    await openExpenseClaimCancelDialog(
      context,
      hr: controller.hrService,
      claimId: claimId,
      onChanged: controller.loadPage,
    );
  }

  Future<void> _deleteClaim(
    ExpenseClaimsManagementController controller,
    String? status,
  ) async {
    final claimId = controller.editingClaimId;
    if (claimId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete claim'),
        content: Text(
          status == 'applied'
              ? 'Delete this applied expense claim?'
              : 'Delete this draft expense claim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final response = await controller.hrService.deleteExpenseClaim(claimId);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(response.message)));
    if (response.success == true) {
      await controller.loadPage();
    }
  }

  Future<void> _openReimburseDialog(
    ExpenseClaimsManagementController controller,
  ) async {
    final claimId = controller.editingClaimId;
    final companyId = controller.companyId;
    if (claimId == null || companyId == null) {
      return;
    }
    await openExpenseClaimReimburseDialog(
      context,
      hr: controller.hrService,
      accountsService: controller.accountsService,
      companyId: companyId,
      claimId: claimId,
      onChanged: () =>
          controller.reloadEditorAndListAfterMutation(claimId: claimId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExpenseClaimsManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: false,
            onPressed: _openExpenseFilterPanel,
          ),
          if (controller.isSelfServiceUser)
            AdaptiveShellActionButton(
              icon: Icons.add_outlined,
              label: 'New claim',
              onPressed: () async {
                final companyId = await hrResolveCompanyId(context);
                if (!context.mounted) {
                  return;
                }
                if (companyId == null) {
                  _expenseClaimsNeedCompanySnack(context);
                  return;
                }
                controller.startNewClaim(
                  isDesktop: Responsive.isDesktop(context),
                );
              },
            ),
        ];

        final content = _buildContent(controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Expense claims',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(ExpenseClaimsManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading expense claims…');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load expense claims',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Expense claims',
      editorTitle: controller.editorTitle,
      scrollController: controller.pageScrollController,
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hrListAppliedFiltersCard(
            context,
            controller.expenseAppliedFilterChips(),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<ExpenseClaimModel>(
            searchController: controller.searchController,
            searchHint: 'Search claims…',
            showSearchBar: false,
            items: controller.filteredRows,
            selectedItem: controller.selectedListRow,
            emptyMessage: 'No expense claims match the filters.',
            itemBuilder: (ExpenseClaimModel item, bool selected) {
              final data = item.toJson();
              return SettingsListTile(
                title: stringValue(data, 'claim_no').isEmpty
                    ? 'Claim #${stringValue(data, 'id')}'
                    : stringValue(data, 'claim_no'),
                subtitle: <String>[
                  displayDate(nullableStringValue(data, 'claim_date')),
                  nestedExpenseEmployeeName(data),
                  expensePaymentSubtitle(data),
                ].where((value) => value.isNotEmpty).join(' · '),
                selected: selected,
                onTap: () => controller.selectClaim(item),
              );
            },
          ),
        ],
      ),
      editor: controller.editorLoading
          ? const AppLoadingView(message: 'Loading claim…')
          : _buildEditor(controller),
    );
  }

  Widget _buildEditor(ExpenseClaimsManagementController controller) {
    if (controller.companyId == null) {
      return const Text('Select a company to edit expense claims.');
    }

    final status = controller.editorStatus();
    final reimbursementVoucherId = controller.editorSnapshot != null
        ? intValue(controller.editorSnapshot!, 'reimbursement_voucher_id')
        : (controller.selectedListRow == null
              ? null
              : intValue(
                  controller.selectedListRow!.toJson(),
                  'reimbursement_voucher_id',
                ));
    final showReimburse =
        controller.canViewAllClaims &&
        status == 'approved' &&
        reimbursementVoucherId == null;
    final isDraft = status == null || status == 'draft';
    final isApplied = status == 'applied';
    final showSaveDraft =
        controller.isSelfServiceUser && controller.editorEditable && isDraft;
    final showApply =
        controller.isSelfServiceUser && controller.editorEditable && isDraft;
    final showCancelDraft =
        controller.isSelfServiceUser &&
        !controller.isNewClaim &&
        controller.editingClaimId != null &&
        status == 'draft';
    final showDelete =
        controller.canViewAllClaims &&
        !controller.isNewClaim &&
        controller.editingClaimId != null &&
        (status == 'draft' || status == 'applied');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Form(
          key: controller.expenseClaimFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.formError != null) ...[
                AppErrorStateView.inline(message: controller.formError!),
                const SizedBox(height: AppUiConstants.spacingSm),
              ],
              if (status != null && status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: Text(
                    'Status: ${expenseClaimStatusLabel(status)}'
                    '${status == 'approved' && reimbursementVoucherId == null ? ' (unpaid)' : ''}'
                    '${status == 'reimbursed' ? ' (paid)' : ''}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              SettingsFormWrap(
                children: [
                  if (controller.employeeFieldReadOnly)
                    AppFormTextField(
                      key: ValueKey<String>(
                        'emp-readonly-${controller.formGeneration}-${controller.employeeId ?? 0}',
                      ),
                      initialValue: controller.editorEmployeeLabel(),
                      labelText: 'Employee',
                      readOnly: true,
                      validator: Validators.required('Employee'),
                    )
                  else
                    AppDropdownField<int>.fromMapped(
                      key: ValueKey<String>(
                        'emp-${controller.formGeneration}-${controller.employeeId ?? 0}',
                      ),
                      labelText: 'Employee',
                      mappedItems: controller.employeesForEditor
                          .map(
                            (employee) => AppDropdownItem<int>(
                              value: employee.id!,
                              label: employee.toString(),
                            ),
                          )
                          .toList(),
                      initialValue: controller.employeeId,
                      onChanged: controller.editorEditable
                          ? controller.setEmployeeId
                          : (_) {},
                      validator: Validators.requiredSelection('Employee'),
                    ),
                  AppFormTextField(
                    controller: controller.claimNoController,
                    labelText: 'Claim no. (optional)',
                    readOnly: !controller.editorEditable,
                  ),
                  AppFormTextField(
                    controller: controller.claimDateController,
                    labelText: 'Claim date',
                    readOnly: !controller.editorEditable,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.compose([
                      Validators.required('Claim date'),
                      Validators.date('Claim date'),
                    ]),
                  ),
                  AppFormTextField(
                    controller: controller.notesController,
                    labelText: 'Notes (optional)',
                    readOnly: !controller.editorEditable,
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: controller.editorEditable
                      ? controller.addLine
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add line'),
                ),
              ),
              ...List<Widget>.generate(controller.lineEditors.length, (index) {
                final line = controller.lineEditors[index];
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Line ${index + 1}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            if (controller.editorEditable &&
                                controller.lineEditors.length > 1)
                              IconButton(
                                tooltip: 'Remove line',
                                onPressed: () => controller.removeLineAt(index),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                        AppFormTextField(
                          controller: line.expenseDate,
                          labelText: 'Expense date',
                          readOnly: !controller.editorEditable,
                          keyboardType: TextInputType.datetime,
                          inputFormatters: const [DateInputFormatter()],
                          validator: Validators.compose([
                            Validators.required('Expense date'),
                            Validators.date('Expense date'),
                          ]),
                        ),
                        AppFormTextField(
                          controller: line.category,
                          labelText: 'Category',
                          readOnly: !controller.editorEditable,
                          validator: Validators.required('Category'),
                        ),
                        AppFormTextField(
                          controller: line.description,
                          labelText: 'Description',
                          readOnly: !controller.editorEditable,
                          validator: Validators.required('Description'),
                        ),
                        AppFormTextField(
                          controller: line.amount,
                          labelText: 'Amount',
                          readOnly: !controller.editorEditable,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: Validators.compose([
                            Validators.required('Amount'),
                            (String? value) {
                              final text = value?.trim() ?? '';
                              final amount = double.tryParse(text);
                              if (amount == null) {
                                return 'Amount must be a valid number';
                              }
                              if (amount <= 0) {
                                return 'Amount must be greater than zero';
                              }
                              return null;
                            },
                          ]),
                        ),
                        AppFormTextField(
                          controller: line.remarks,
                          labelText: 'Remarks (optional)',
                          readOnly: !controller.editorEditable,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppUiConstants.spacingMd),
            ],
          ),
        ),
        if (showSaveDraft) ...[
          FilledButton(
            onPressed: controller.saving
                ? null
                : () => _submitClaim(controller: controller, applyNow: false),
            child: controller.saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save draft'),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
        ],
        if (showApply) ...[
          FilledButton.tonal(
            onPressed: controller.saving
                ? null
                : () => _submitClaim(controller: controller, applyNow: true),
            child: const Text('Apply'),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
        ],
        if (!controller.isNewClaim && controller.editingClaimId != null)
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              if (controller.canViewAllClaims && isApplied) ...[
                FilledButton.tonal(
                  onPressed: () => _approveClaim(controller),
                  child: const Text('Approve'),
                ),
                FilledButton.tonal(
                  onPressed: () => _openRejectDialog(controller),
                  child: const Text('Reject'),
                ),
              ],
              if (showCancelDraft)
                FilledButton.tonal(
                  onPressed: () => _openCancelDraftDialog(controller),
                  child: const Text('Cancel draft'),
                ),
              if (showDelete)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => _deleteClaim(controller, status),
                  child: const Text('Delete'),
                ),
              if (showReimburse)
                FilledButton(
                  onPressed: () => _openReimburseDialog(controller),
                  child: const Text('Reimburse'),
                ),
            ],
          ),
      ],
    );
  }
}
