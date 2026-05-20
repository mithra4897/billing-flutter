import '../../../controller/settings/accounting/voucher_management_controller.dart';
import '../../../screen.dart';

class VoucherManagementPage extends StatefulWidget {
  const VoucherManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<VoucherManagementPage> createState() => _VoucherManagementPageState();
}

class _VoucherManagementPageState extends State<VoucherManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('VoucherManagementController');
    Get.put(VoucherManagementController(), tag: _controllerTag);
  }

  Future<void> _confirmDelete(VoucherManagementController controller) async {
    final id = controller.selectedVoucher?.id;
    if (id == null || !controller.canDeleteSelectedVoucher) {
      return;
    }
    final code = controller.selectedVoucher?.voucherNo ?? '$id';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete voucher'),
        content: Text(
          'Permanently remove voucher $code? This cannot be undone. Only users with accounts delete permission see this action.',
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
      await controller.deleteSelectedVoucher();
    }
  }

  Future<void> _openVoucherAuditLog(
    VoucherManagementController controller,
  ) async {
    final id = controller.selectedVoucher?.id;
    if (id == null) {
      return;
    }
    try {
      final rows = await controller.fetchVoucherAuditLog();
      if (!mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (dialogContext) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.45,
            minChildSize: 0.28,
            maxChildSize: 0.92,
            builder: (sheetContext, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppUiConstants.spacingMd,
                    ),
                    child: Text(
                      'Activity - ${controller.selectedVoucher?.voucherNo ?? '$id'}',
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Expanded(
                    child: rows.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppUiConstants.spacingLg),
                              child: Text(
                                'No logged actions yet for this voucher.',
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppUiConstants.spacingMd,
                            ),
                            itemCount: rows.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              final action = row['action']?.toString() ?? '';
                              final description =
                                  row['description']?.toString() ?? '';
                              final who = row['user_display']?.toString() ?? '';
                              final when = row['created_at']?.toString() ?? '';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  description.isNotEmpty ? description : action,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  [who, when]
                                      .where((value) => value.isNotEmpty)
                                      .join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (errorValue) {
      final message = errorValue is ApiException
          ? errorValue.displayMessage
          : errorValue.toString();
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: appScaffoldMessengerKey.currentContext == null
              ? null
              : Theme.of(
                  appScaffoldMessengerKey.currentContext!,
                ).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VoucherManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewEntry(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_outlined,
            label: 'New Entry',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Vouchers',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    VoucherManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading vouchers...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load vouchers',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Vouchers',
      editorTitle: controller.selectedVoucher?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<VoucherModel>(
        searchController: controller.searchController,
        searchHint: 'Search vouchers',
        items: controller.filteredVouchers,
        selectedItem: controller.selectedVoucher,
        emptyMessage: 'No vouchers found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.voucherNo ?? '',
          subtitle: [
            item.voucherDate ?? '',
            item.voucherTypeName ?? '',
            item.postingStatus ?? '',
          ].where((value) => value.isNotEmpty).join(' · '),
          detail: item.narration ?? '',
          selected: selected,
          onTap: () => controller.selectVoucher(item),
        ),
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
            AppSwitchTile(
              label: 'Simple entry (recommended)',
              subtitle:
                  'Fewer fields - use full options for references, parties, approvals.',
              value: controller.simpleEntryMode,
              onChanged: controller.setSimpleEntryMode,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            SettingsFormWrap(
              children: [
                _buildVoucherModeField(context, controller),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Voucher Type',
                  mappedItems: controller.voucherTypesForMode
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.voucherTypeId,
                  onChanged: controller.setVoucherTypeId,
                  validator: Validators.requiredSelection('Voucher Type'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Document Series',
                  mappedItems: controller.filteredDocumentSeriesOptions
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
                  validator: (value) {
                    final voucherNo = controller.voucherNoController.text
                        .trim();
                    if (voucherNo.isEmpty && value == null) {
                      return 'Document Series is required';
                    }
                    return null;
                  },
                ),
                AppFormTextField(
                  labelText: 'Voucher No',
                  controller: controller.voucherNoController,
                  hintText: 'Auto-generated',
                  readOnly: true,
                  validator: Validators.optionalMaxLength(100, 'Voucher No'),
                ),
                AppFormTextField(
                  labelText: 'Voucher Date',
                  controller: controller.voucherDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Voucher Date'),
                    Validators.date('Voucher Date'),
                  ]),
                ),
                if (!controller.simpleEntryMode) ...[
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
                    validator: Validators.optionalDate('Reference Date'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Approval Status',
                    mappedItems:
                        VoucherManagementController.approvalStatusItems,
                    initialValue: controller.approvalStatus,
                    onChanged: controller.setApprovalStatus,
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Posting Status',
                    mappedItems: VoucherManagementController.postingStatusItems,
                    initialValue: controller.postingStatus,
                    onChanged: controller.setPostingStatus,
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Adjustment Account',
                    mappedItems: controller.accountsScoped
                        .where((item) => item.id != null)
                        .map(
                          (item) => AppDropdownItem(
                            value: item.id!,
                            label: item.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: controller.adjustmentAccountId,
                    onChanged: controller.setAdjustmentAccountId,
                  ),
                  AppFormTextField(
                    labelText: 'Adjustment Remarks',
                    controller: controller.adjustmentRemarksController,
                    validator: Validators.optionalMaxLength(
                      500,
                      'Adjustment Remarks',
                    ),
                  ),
                ],
                AppFormTextField(
                  labelText: 'Narration',
                  controller: controller.narrationController,
                  maxLines: 3,
                  validator: Validators.optionalMaxLength(1000, 'Narration'),
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
            _buildEntryBody(context, controller),
            if (controller.selectedVoucher != null) ...[
              if ((controller.selectedVoucher!.postingStatus ?? '')
                      .toLowerCase() ==
                  'cancelled') ...[
                Text(
                  'Cancelled vouchers cannot be edited or deleted here.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ] else if (controller.selectedVoucher!.isSystemGenerated &&
                  !controller.isSuperAdmin) ...[
                Text(
                  'This voucher was created by the system from another module. It cannot be edited or deleted on this screen unless you are a super admin.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ] else if (controller.selectedVoucher!.isSystemGenerated &&
                  controller.isSuperAdmin) ...[
                Text(
                  'Super admin: you may edit or delete this system-generated voucher. Source documents may no longer match the books.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ] else if (controller.hasAccountsUpdate) ...[
                Text(
                  'Manual vouchers remain editable after posting when you have accounts update (or super admin). Review books after changes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppActionButton(
                    icon: Icons.save_outlined,
                    label: controller.selectedVoucher == null
                        ? 'Save Voucher'
                        : 'Update Voucher',
                    onPressed:
                        (controller.selectedVoucher == null ||
                            controller.canEditSelectedVoucher)
                        ? controller.saveVoucher
                        : null,
                    busy: controller.saving,
                  ),
                ),
                if (controller.canDeleteSelectedVoucher) ...[
                  const SizedBox(width: AppUiConstants.spacingSm),
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                    onPressed: controller.deleting
                        ? null
                        : () => _confirmDelete(controller),
                    busy: controller.deleting,
                  ),
                ],
              ],
            ),
            if (controller.selectedVoucher?.id != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppUiConstants.spacingSm,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                  onPressed: controller.auditLogLoading
                      ? null
                      : () => _openVoucherAuditLog(controller),
                  child: controller.auditLogLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Activity log',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherModeField(
    BuildContext context,
    VoucherManagementController controller,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entry Mode', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppUiConstants.spacingXs),
            Wrap(
              spacing: AppUiConstants.spacingXs,
              runSpacing: AppUiConstants.spacingXs,
              children: VoucherManagementController.voucherModeOptions
                  .map((option) {
                    final chip = FilterChip(
                      selected: controller.voucherMode == option.category,
                      label: Text(option.label),
                      avatar: Icon(option.icon, size: 18),
                      onSelected: (_) =>
                          controller.setVoucherMode(option.category),
                    );
                    if (option.subtitle == null || option.subtitle!.isEmpty) {
                      return chip;
                    }
                    return Tooltip(message: option.subtitle, child: chip);
                  })
                  .toList(growable: false),
            ),
            if (width > 0) const SizedBox.shrink(),
          ],
        );
      },
    );
  }

  Widget _buildEntryBody(
    BuildContext context,
    VoucherManagementController controller,
  ) {
    final totals = controller.usesQuickEntry
        ? <String, double>{
            'debit':
                double.tryParse(controller.amountController.text.trim()) ?? 0,
            'credit':
                double.tryParse(controller.amountController.text.trim()) ?? 0,
          }
        : <String, double>{
            'debit': controller.totalDebit,
            'credit': controller.totalCredit,
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Debit: ${totals['debit']!.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Text(
                  'Credit: ${totals['credit']!.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        if (controller.usesQuickEntry)
          _buildQuickEntrySection(context, controller)
        else
          _buildJournalLines(context, controller),
        _buildSettlementsReadOnly(context, controller),
      ],
    );
  }

  Widget _buildSettlementsReadOnly(
    BuildContext context,
    VoucherManagementController controller,
  ) {
    final voucher = controller.selectedVoucher;
    if (voucher == null) {
      return const SizedBox.shrink();
    }
    final tiles = <Widget>[];
    for (final line in voucher.lines) {
      if (line.allocations.isEmpty) {
        continue;
      }
      for (final allocation in line.allocations) {
        final map = allocation.toJson();
        tiles.add(
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Line ${line.lineNo ?? '?'} · ${map['reference_no'] ?? ''} (${map['allocation_type'] ?? ''})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              'Amount: ${map['allocation_amount'] ?? ''} · Against voucher #${map['against_voucher_id'] ?? '-'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      }
    }
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const SizedBox(height: AppUiConstants.spacingMd),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bill settlements',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              ...tiles,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickEntrySection(
    BuildContext context,
    VoucherManagementController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.voucherMode == 'payment'
              ? 'Record spend: expense ledger is debited, cash or bank is credited.'
              : controller.voucherMode == 'receipt'
              ? 'Miscellaneous receipt: bank/cash is debited, indirect income is credited (customer receipts stay in Sales).'
              : 'Transfer only between cash and bank ledgers - same amount on both sides.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (controller.voucherMode == 'payment' &&
            controller.expenseLedgerOptions.isEmpty) ...[
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            'No expense ledgers match your chart (group nature “expense” or categories direct/indirect expense). Until those exist, all non-cash/bank ledgers are listed below.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
        if (controller.voucherMode == 'receipt' &&
            controller.indirectIncomeLedgerOptions.isEmpty) ...[
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            'No “indirect income” group found - showing all income ledgers. Tag account groups as indirect income for a tighter list.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
        if (controller.voucherMode == 'contra' &&
            controller.cashBankAccounts.length < 2) ...[
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            'You need at least two active cash/bank ledgers for transfers.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppUiConstants.spacingSm),
        SettingsFormWrap(
          children: [
            AppDropdownField<int>.fromMapped(
              labelText: controller.debitAccountLabel,
              mappedItems: controller.debitAccountOptions
                  .where((item) => item.id != null)
                  .map(
                    (item) => AppDropdownItem(
                      value: item.id!,
                      label: item.toString(),
                    ),
                  )
                  .toList(growable: false),
              initialValue: controller.debitAccountId,
              onChanged: controller.setDebitAccountId,
              validator: Validators.requiredSelection(
                controller.debitAccountLabel,
              ),
            ),
            AppDropdownField<int>.fromMapped(
              labelText: controller.creditAccountLabel,
              mappedItems: controller.creditAccountOptions
                  .where((item) => item.id != null)
                  .map(
                    (item) => AppDropdownItem(
                      value: item.id!,
                      label: item.toString(),
                    ),
                  )
                  .toList(growable: false),
              initialValue: controller.creditAccountId,
              onChanged: controller.setCreditAccountId,
              validator: Validators.requiredSelection(
                controller.creditAccountLabel,
              ),
            ),
            if (!controller.simpleEntryMode) ...[
              AppDropdownField<int>.fromMapped(
                labelText: controller.debitPartyLabel,
                mappedItems: controller.parties
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: controller.debitPartyId,
                onChanged: controller.setDebitPartyId,
              ),
              AppDropdownField<int>.fromMapped(
                labelText: controller.creditPartyLabel,
                mappedItems: controller.parties
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: controller.creditPartyId,
                onChanged: controller.setCreditPartyId,
              ),
            ],
            AppFormTextField(
              labelText: 'Amount',
              controller: controller.amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: Validators.compose([
                Validators.required('Amount'),
                Validators.optionalNonNegativeNumber('Amount'),
                (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ]),
            ),
            if (!controller.simpleEntryMode) ...[
              AppDropdownField<String>.fromMapped(
                labelText: 'Cost Center',
                mappedItems: controller.costCenterItems(
                  controller.costCenterController.text,
                ),
                initialValue: nullIfEmpty(controller.costCenterController.text),
                onChanged: controller.setCostCenter,
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Department',
                mappedItems: controller.departmentItems(
                  controller.departmentController.text,
                ),
                initialValue: nullIfEmpty(controller.departmentController.text),
                onChanged: controller.setDepartment,
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Project',
                mappedItems: controller.projectItems(
                  controller.projectController.text,
                ),
                initialValue: nullIfEmpty(controller.projectController.text),
                onChanged: controller.setProject,
              ),
              AppFormTextField(
                labelText: 'Line Narration',
                controller: controller.lineNarrationController,
                maxLines: 2,
                validator: Validators.optionalMaxLength(500, 'Line Narration'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildJournalLines(
    BuildContext context,
    VoucherManagementController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Journal Lines',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Line',
              onPressed: controller.addLine,
              filled: false,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        ...List<Widget>.generate(controller.lines.length, (index) {
          final line = controller.lines[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppSectionCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Line ${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: controller.lines.length == 1
                            ? null
                            : () => controller.removeLine(index),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  SettingsFormWrap(
                    children: [
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Account',
                        mappedItems: controller.accountsScoped
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.accountId,
                        onChanged: (value) =>
                            controller.setLineAccountId(index, value),
                        validator: Validators.requiredSelection('Account'),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Party',
                        mappedItems: controller.parties
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.partyId,
                        onChanged: (value) =>
                            controller.setLinePartyId(index, value),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Entry Type',
                        mappedItems: VoucherManagementController.entryTypeItems,
                        initialValue: line.entryType,
                        onChanged: (value) =>
                            controller.setLineEntryType(index, value),
                        validator: Validators.requiredSelection('Entry Type'),
                      ),
                      AppFormTextField(
                        labelText: 'Amount',
                        initialValue: line.amountText,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) =>
                            controller.setLineAmountText(index, value),
                        validator: Validators.compose([
                          Validators.required('Amount'),
                          Validators.optionalNonNegativeNumber('Amount'),
                          (value) {
                            final parsed = double.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Amount must be greater than zero';
                            }
                            return null;
                          },
                        ]),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Cost Center',
                        mappedItems: controller.costCenterItems(
                          line.costCenter,
                        ),
                        initialValue: nullIfEmpty(line.costCenter),
                        onChanged: (value) =>
                            controller.setLineCostCenter(index, value),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Department',
                        mappedItems: controller.departmentItems(
                          line.department,
                        ),
                        initialValue: nullIfEmpty(line.department),
                        onChanged: (value) =>
                            controller.setLineDepartment(index, value),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Project',
                        mappedItems: controller.projectItems(line.project),
                        initialValue: nullIfEmpty(line.project),
                        onChanged: (value) =>
                            controller.setLineProject(index, value),
                      ),
                      AppFormTextField(
                        labelText: 'Line Narration',
                        initialValue: line.narration,
                        onChanged: (value) =>
                            controller.setLineNarration(index, value),
                        validator: Validators.optionalMaxLength(
                          500,
                          'Line Narration',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
