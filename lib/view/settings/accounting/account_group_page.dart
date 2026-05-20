import '../../../controller/settings/accounting/account_group_management_controller.dart';
import '../../../screen.dart';

class AccountGroupManagementPage extends StatefulWidget {
  const AccountGroupManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AccountGroupManagementPage> createState() =>
      _AccountGroupManagementPageState();
}

class _AccountGroupManagementPageState
    extends State<AccountGroupManagementPage> {
  static const List<AppDropdownItem<String>> _natureItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'asset', label: 'Asset'),
        AppDropdownItem(value: 'liability', label: 'Liability'),
        AppDropdownItem(value: 'income', label: 'Income'),
        AppDropdownItem(value: 'expense', label: 'Expense'),
        AppDropdownItem(value: 'equity', label: 'Equity'),
      ];

  static const List<AppDropdownItem<String>> _categoryItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'cash_bank', label: 'Cash / Bank'),
        AppDropdownItem(value: 'receivable', label: 'Receivable'),
        AppDropdownItem(value: 'payable', label: 'Payable'),
        AppDropdownItem(value: 'stock', label: 'Stock'),
        AppDropdownItem(value: 'tax', label: 'Tax'),
        AppDropdownItem(value: 'sales', label: 'Sales'),
        AppDropdownItem(value: 'purchase', label: 'Purchase'),
        AppDropdownItem(value: 'direct_income', label: 'Direct Income'),
        AppDropdownItem(value: 'direct_expense', label: 'Direct Expense'),
        AppDropdownItem(value: 'indirect_income', label: 'Indirect Income'),
        AppDropdownItem(value: 'indirect_expense', label: 'Indirect Expense'),
        AppDropdownItem(value: 'fixed_asset', label: 'Fixed Asset'),
        AppDropdownItem(value: 'current_asset', label: 'Current Asset'),
        AppDropdownItem(value: 'current_liability', label: 'Current Liability'),
        AppDropdownItem(
          value: 'long_term_liability',
          label: 'Long Term Liability',
        ),
        AppDropdownItem(value: 'equity', label: 'Equity'),
        AppDropdownItem(value: 'other', label: 'Other'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        persistentControllerTag('AccountGroupManagementController');
    Get.put(AccountGroupManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountGroupManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.account_tree_outlined,
            label: 'New Group',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Account Groups',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(AccountGroupManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading account groups...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load account groups',
        message: controller.pageError!,
        onRetry: controller.loadGroups,
      );
    }

    // Migrated page/form state now lives in AccountGroupManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Account Groups',
      editorTitle: controller.selectedGroup?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<AccountGroupModel>(
        searchController: controller.searchController,
        searchHint: 'Search account groups',
        items: controller.filteredGroups,
        selectedItem: controller.selectedGroup,
        emptyMessage: 'No account groups found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.groupName ?? '',
          subtitle: [
            item.groupCode ?? '',
            item.groupNature ?? '',
            if ((item.groupCategory ?? '').isNotEmpty) item.groupCategory!,
          ].join(' · '),
          selected: selected,
          onTap: () => controller.selectGroup(item),
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
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  labelText: 'Group Code',
                  controller: controller.groupCodeController,
                  validator: Validators.compose([
                    Validators.required('Group Code'),
                    Validators.optionalMaxLength(50, 'Group Code'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Group Name',
                  controller: controller.groupNameController,
                  validator: Validators.compose([
                    Validators.required('Group Name'),
                    Validators.optionalMaxLength(150, 'Group Name'),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Parent Group',
                  mappedItems: controller.parentOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.parentGroupId,
                  onChanged: controller.setParentGroupId,
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Group Nature',
                  mappedItems: _natureItems,
                  initialValue: controller.groupNature,
                  onChanged: controller.setGroupNature,
                  validator: Validators.requiredSelection('Group Nature'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Group Category',
                  mappedItems: _categoryItems,
                  initialValue: controller.groupCategory,
                  onChanged: controller.setGroupCategory,
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
                    label: 'Affects P&L',
                    value: controller.affectsProfitLoss,
                    onChanged: controller.setAffectsProfitLoss,
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
                  label: controller.selectedGroup == null
                      ? 'Save Group'
                      : 'Update Group',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
                if (controller.selectedGroup?.id != null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: controller.saving ? null : controller.delete,
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
