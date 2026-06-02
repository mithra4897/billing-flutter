import '../../../controller/settings/accounting/bank_reconciliation_management_controller.dart';
import '../../../screen.dart';

class BankReconciliationManagementPage extends StatefulWidget {
  const BankReconciliationManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BankReconciliationManagementPage> createState() =>
      _BankReconciliationManagementPageState();
}

class _BankReconciliationManagementPageState
    extends State<BankReconciliationManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        persistentControllerTag('BankReconciliationManagementController');
    Get.put(BankReconciliationManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BankReconciliationManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNew(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.compare_arrows_outlined,
            label: 'New Reconciliation',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Bank Reconciliation',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    BankReconciliationManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading bank reconciliation...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load bank reconciliation',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    // Migrated page/form state now lives in BankReconciliationManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Bank Reconciliation',
      editorTitle: controller.selectedRecord?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<BankReconciliationModel>(
        searchController: controller.searchController,
        searchHint: 'Search reconciliation records',
        items: controller.filteredRecords,
        selectedItem: controller.selectedRecord,
        emptyMessage: 'No reconciliation records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.accountName ?? item.accountCode ?? '',
          subtitle: [
            item.voucherNo ?? '',
            item.reconciliationStatus ?? '',
            item.bankDate ?? '',
          ].where((value) => value.isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => controller.selectRecord(item),
        ),
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
            SettingsFormWrap(
              children: [
                AppDropdownField<int>.fromMapped(
                  labelText: 'Bank Account',
                  mappedItems: controller.bankAccounts
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.accountId,
                  onChanged: controller.setAccountId,
                  validator: Validators.requiredSelection('Bank Account'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Voucher',
                  mappedItems: controller.vouchers
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.voucherId,
                  onChanged: controller.setVoucherId,
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Voucher Line',
                  mappedItems: controller.voucherLineOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label:
                              '${item.entryType?.toUpperCase() ?? ''} · ${item.amount ?? 0} · ${item.accountName ?? item.accountCode ?? ''}',
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.voucherLineId,
                  onChanged: controller.setVoucherLineId,
                  validator: Validators.requiredSelection('Voucher Line'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Status',
                  mappedItems:
                      BankReconciliationManagementController.statusItems,
                  initialValue: controller.status,
                  onChanged: controller.setStatus,
                ),
                if (controller.status == 'bounced' ||
                    controller.status == 'cancelled') ...[
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Text(
                    'Bounced/cancelled here only updates this reconciliation row. '
                    'It does not reverse GL vouchers or change sales/purchase payment status-post dishonour/reversal entries and update source documents separately.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
                AppFormTextField(
                  labelText: 'Bank Date',
                  controller: controller.bankDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Bank Date'),
                ),
                AppFormTextField(
                  labelText: 'Cleared Date',
                  controller: controller.clearedDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Cleared Date'),
                ),
                AppFormTextField(
                  labelText: 'Bank Reference No',
                  controller: controller.bankReferenceController,
                  validator: Validators.optionalMaxLength(
                    100,
                    'Bank Reference No',
                  ),
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: controller.remarksController,
                  maxLines: 3,
                  validator: (value) {
                    if (controller.status == 'bounced' ||
                        controller.status == 'cancelled') {
                      if (value == null || value.trim().isEmpty) {
                        return 'Remarks required for bounced or cancelled';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            AppActionButton(
              icon: Icons.save_outlined,
              label: controller.selectedRecord == null
                  ? 'Save Reconciliation'
                  : 'Update Reconciliation',
              onPressed: controller.save,
              busy: controller.saving,
            ),
          ],
        ),
      ),
    );
  }
}
