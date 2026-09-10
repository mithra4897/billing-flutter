import '../../../controller/settings/accounting/account_management_controller.dart';
import '../../../screen.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'AccountManagementController',
      scope: <String, Object?>{
        'identity': identityHashCode(this),
        'embedded': widget.embedded,
        'editorOnly': widget.editorOnly,
        'initialId': widget.initialId,
      },
    );
    _registerController();
  }

  @override
  void didUpdateWidget(covariant AccountManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialId != widget.initialId) {
      if (Get.isRegistered<AccountManagementController>(tag: _controllerTag)) {
        final c = Get.find<AccountManagementController>(tag: _controllerTag);
        if (widget.initialId != null) {
          unawaited(c.loadPage(selectId: widget.initialId));
        } else {
          c.startNew(isDesktop: Responsive.isDesktop(context));
        }
      }
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<AccountManagementController>(tag: _controllerTag)) {
      Get.delete<AccountManagementController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  void _registerController() {
    if (Get.isRegistered<AccountManagementController>(tag: _controllerTag)) {
      return;
    }
    Get.put(
      AccountManagementController(initialId: widget.initialId),
      tag: _controllerTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          if (!widget.editorOnly)
            AdaptiveShellActionButton(
              onPressed: () =>
                  controller.startNew(isDesktop: Responsive.isDesktop(context)),
              icon: Icons.account_balance_outlined,
              label: 'New Account',
            ),
          if (widget.editorOnly)
            AdaptiveShellActionButton(
              onPressed: () => Get.back(),
              icon: Icons.arrow_back,
              label: 'Back to Register',
              filled: false,
            ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Accounts',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AccountManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading accounts...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load accounts',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    // Migrated page/form state now lives in AccountManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Accounts',
      editorTitle: controller.selectedAccount?.toString(),
      scrollController: controller.pageScrollController,
      editorOnly: widget.editorOnly,
      list: SettingsListCard<AccountModel>(
        searchController: controller.searchController,
        searchHint: 'Search accounts',
        items: controller.filteredAccounts,
        selectedItem: controller.selectedAccount,
        emptyMessage: 'No accounts found.',
        paginationMeta: controller.paginationMeta,
        onPageChanged: controller.setPage,
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.accountName ?? '',
          subtitle: [
            item.accountCode ?? '',
            item.accountType ?? '',
            if ((item.accountGroupName ?? '').isNotEmpty)
              item.accountGroupName!,
          ].join(' · '),
          detail: item.companyName ?? '',
          selected: selected,
          onTap: () => controller.selectAccount(item),
        ),
      ),
      editorBuilder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
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
                    AppFormTextField(
                      labelText: 'Account Code',
                      controller: controller.accountCodeController,
                      validator: Validators.compose([
                        Validators.required('Account Code'),
                        Validators.optionalMaxLength(50, 'Account Code'),
                      ]),
                    ),
                    AppFormTextField(
                      labelText: 'Account Name',
                      controller: controller.accountNameController,
                      validator: Validators.compose([
                        Validators.required('Account Name'),
                        Validators.optionalMaxLength(255, 'Account Name'),
                      ]),
                    ),
                    AppDropdownField<int>.fromMapped(
                      labelText: 'Account Group',
                      mappedItems: controller.groups
                          .where((item) => item.id != null)
                          .map(
                            (item) => AppDropdownItem<int>(
                              value: item.id!,
                              label: item.toString(),
                            ),
                          )
                          .toList(growable: false),
                      initialValue: controller.accountGroupId,
                      onChanged: controller.setAccountGroupId,
                      validator: Validators.requiredSelection('Account Group'),
                    ),
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Account Type',
                      mappedItems: AccountManagementController.accountTypeItems,
                      initialValue: controller.accountType,
                      onChanged: controller.setAccountType,
                      validator: Validators.requiredSelection('Account Type'),
                    ),
                    AppFormTextField(
                      labelText: 'Opening Balance',
                      controller: controller.openingBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.optionalNonNegativeNumber(
                        'Opening Balance',
                      ),
                    ),
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Opening Balance Type',
                      mappedItems:
                          AccountManagementController.openingBalanceTypeItems,
                      initialValue: controller.openingBalanceType,
                      onChanged: controller.setOpeningBalanceType,
                    ),
                    AppFormTextField(
                      labelText: 'Currency Code',
                      controller: controller.currencyCodeController,
                      validator: Validators.compose([
                        Validators.required('Currency Code'),
                        Validators.optionalMaxLength(10, 'Currency Code'),
                      ]),
                    ),
                    AppFormTextField(
                      labelText: 'Remarks',
                      controller: controller.remarksController,
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                Wrap(
                  spacing: AppUiConstants.spacingMd,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    SizedBox(
                      width: AppUiConstants.switchFieldWidth,
                      child: AppSwitchTile(
                        label: 'Allow Manual Entries',
                        value: controller.allowManualEntries,
                        onChanged: controller.setAllowManualEntries,
                      ),
                    ),
                    SizedBox(
                      width: AppUiConstants.switchFieldWidth,
                      child: AppSwitchTile(
                        label: 'Allow Reconciliation',
                        value: controller.allowReconciliation,
                        onChanged: controller.setAllowReconciliation,
                      ),
                    ),
                    SizedBox(
                      width: AppUiConstants.switchFieldWidth,
                      child: AppSwitchTile(
                        label: 'Control Account',
                        value: controller.isControlAccount,
                        onChanged: controller.setIsControlAccount,
                      ),
                    ),
                    SizedBox(
                      width: AppUiConstants.switchFieldWidth,
                      child: AppSwitchTile(
                        label: 'Active',
                        value: controller.isActive,
                        onChanged: controller.setIsActive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppUiConstants.spacingLg),
                Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    AppActionButton(
                      icon: Icons.save_outlined,
                      label: controller.selectedAccount == null
                          ? 'Save Account'
                          : 'Update Account',
                      onPressed: controller.save,
                      busy: controller.saving,
                    ),
                    if (controller.selectedAccount?.id != null)
                      AppActionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onPressed: controller.saving ? null : controller.delete,
                        filled: false,
                      ),
                    if (widget.editorOnly)
                      AppActionButton(
                        icon: Icons.close_outlined,
                        label: 'Cancel',
                        onPressed: () => Get.back(),
                        filled: false,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
