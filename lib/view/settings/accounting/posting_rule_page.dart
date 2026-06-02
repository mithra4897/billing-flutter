import '../../../controller/settings/accounting/posting_rule_management_controller.dart';
import '../../../screen.dart';

class PostingRuleManagementPage extends StatefulWidget {
  const PostingRuleManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PostingRuleManagementPage> createState() =>
      _PostingRuleManagementPageState();
}

class _PostingRuleManagementPageState extends State<PostingRuleManagementPage> {
  static const List<AppDropdownItem<String>> _entrySideItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'debit', label: 'Debit'),
        AppDropdownItem(value: 'credit', label: 'Credit'),
      ];

  static const List<AppDropdownItem<String>>
  _accountSourceItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: 'fixed_account', label: 'Fixed account'),
    AppDropdownItem(
      value: 'customer_control_account',
      label: 'Customer control',
    ),
    AppDropdownItem(
      value: 'supplier_control_account',
      label: 'Supplier control',
    ),
    AppDropdownItem(value: 'item_sales_account', label: 'Item sales'),
    AppDropdownItem(value: 'item_purchase_account', label: 'Item purchase'),
    AppDropdownItem(value: 'tax_output_cgst_account', label: 'Tax output CGST'),
    AppDropdownItem(value: 'tax_output_sgst_account', label: 'Tax output SGST'),
    AppDropdownItem(value: 'tax_output_igst_account', label: 'Tax output IGST'),
    AppDropdownItem(value: 'tax_input_cgst_account', label: 'Tax input CGST'),
    AppDropdownItem(value: 'tax_input_sgst_account', label: 'Tax input SGST'),
    AppDropdownItem(value: 'tax_input_igst_account', label: 'Tax input IGST'),
    AppDropdownItem(value: 'cash_bank_account', label: 'Cash / bank'),
    AppDropdownItem(value: 'round_off_account', label: 'Round off'),
    AppDropdownItem(value: 'discount_account', label: 'Discount'),
    AppDropdownItem(value: 'returns_account', label: 'Returns'),
    AppDropdownItem(value: 'stock_account', label: 'Stock'),
    AppDropdownItem(value: 'cogs_account', label: 'COGS'),
  ];

  static const List<AppDropdownItem<String>> _amountSourceItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'subtotal', label: 'Subtotal'),
        AppDropdownItem(value: 'discount_amount', label: 'Discount'),
        AppDropdownItem(value: 'taxable_amount', label: 'Taxable'),
        AppDropdownItem(value: 'cgst_amount', label: 'CGST'),
        AppDropdownItem(value: 'sgst_amount', label: 'SGST'),
        AppDropdownItem(value: 'igst_amount', label: 'IGST'),
        AppDropdownItem(value: 'cess_amount', label: 'Cess'),
        AppDropdownItem(value: 'round_off_amount', label: 'Round off'),
        AppDropdownItem(value: 'total_amount', label: 'Total'),
        AppDropdownItem(value: 'paid_amount', label: 'Paid'),
        AppDropdownItem(value: 'balance_amount', label: 'Balance'),
        AppDropdownItem(value: 'stock_value', label: 'Stock value'),
        AppDropdownItem(value: 'cogs_value', label: 'COGS value'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        persistentControllerTag('PostingRuleManagementController');
    Get.put(PostingRuleManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostingRuleManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.rule_folder_outlined,
            label: 'New Rule',
          ),
        ];
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Posting Rules',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(PostingRuleManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading posting rules...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load',
        message: controller.pageError!,
        onRetry: controller.load,
      );
    }

    // Migrated page/form state now lives in PostingRuleManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Posting Rules',
      editorTitle: intValue(controller.json(controller.selected), 'id') == null
          ? null
          : 'Line ${controller.lineNoController.text}',
      scrollController: controller.pageScrollController,
      list: SettingsListCard<PostingRuleModel>(
        searchController: controller.searchController,
        searchHint: 'Search rules',
        items: controller.filtered,
        selectedItem: controller.selected,
        emptyMessage: 'No posting rules.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title:
                'L${stringValue(data, 'line_no')} · ${stringValue(data, 'entry_side')} · ${stringValue(data, 'amount_source')}',
            subtitle: stringValue(data, 'account_source_type'),
            selected: selected,
            onTap: () => controller.applySelection(item),
          );
        },
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
                  labelText: 'Rule group',
                  mappedItems: controller.groups
                      .map(
                        (group) => AppDropdownItem<int>(
                          value: intValue(group.toJson(), 'id') ?? 0,
                          label:
                              stringValue(group.toJson(), 'group_name').isEmpty
                              ? stringValue(group.toJson(), 'group_code')
                              : stringValue(group.toJson(), 'group_name'),
                        ),
                      )
                      .where((item) => item.value != 0)
                      .toList(growable: false),
                  initialValue: controller.groupId,
                  onChanged: controller.setGroupId,
                  validator: Validators.requiredSelection('Rule group'),
                ),
                AppFormTextField(
                  labelText: 'Line no.',
                  controller: controller.lineNoController,
                  keyboardType: TextInputType.number,
                  validator: Validators.compose([
                    Validators.required('Line no.'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Entry side',
                  mappedItems: _entrySideItems,
                  initialValue: controller.entrySide,
                  onChanged: controller.setEntrySide,
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Account source',
                  mappedItems: _accountSourceItems,
                  initialValue: controller.accountSourceType,
                  onChanged: controller.setAccountSourceType,
                ),
                if (controller.accountSourceType == 'fixed_account')
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Fixed ledger',
                    mappedItems: controller.accounts
                        .where((account) => account.id != null)
                        .map(
                          (account) => AppDropdownItem<int>(
                            value: account.id!,
                            label: account.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: controller.fixedAccountId,
                    onChanged: controller.setFixedAccountId,
                    validator: controller.accountSourceType == 'fixed_account'
                        ? Validators.requiredSelection('Fixed ledger')
                        : null,
                  ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Amount source',
                  mappedItems: _amountSourceItems,
                  initialValue: controller.amountSource,
                  onChanged: controller.setAmountSource,
                ),
                AppFormTextField(
                  labelText: 'Narration template',
                  controller: controller.narrationTemplateController,
                  maxLines: 2,
                  validator: Validators.optionalMaxLength(500, 'Narration'),
                ),
                AppFormTextField(
                  labelText: 'Priority',
                  controller: controller.priorityController,
                  keyboardType: TextInputType.number,
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
                  label:
                      intValue(controller.json(controller.selected), 'id') ==
                          null
                      ? 'Save'
                      : 'Update',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
                if (intValue(controller.json(controller.selected), 'id') !=
                    null)
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
