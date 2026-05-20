import '../../../controller/settings/accounting/voucher_type_management_controller.dart';
import '../../../screen.dart';

class VoucherTypeManagementPage extends StatefulWidget {
  const VoucherTypeManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<VoucherTypeManagementPage> createState() =>
      _VoucherTypeManagementPageState();
}

class _VoucherTypeManagementPageState extends State<VoucherTypeManagementPage> {
  static const List<AppDropdownItem<String>> _categoryItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'payment', label: 'Payment'),
        AppDropdownItem(value: 'receipt', label: 'Receipt'),
        AppDropdownItem(value: 'journal', label: 'Journal'),
        AppDropdownItem(value: 'contra', label: 'Contra'),
        AppDropdownItem(value: 'sales', label: 'Sales'),
        AppDropdownItem(value: 'purchase', label: 'Purchase'),
        AppDropdownItem(value: 'credit_note', label: 'Credit Note'),
        AppDropdownItem(value: 'debit_note', label: 'Debit Note'),
        AppDropdownItem(value: 'opening', label: 'Opening'),
        AppDropdownItem(value: 'adjustment', label: 'Adjustment'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        persistentControllerTag('VoucherTypeManagementController');
    Get.put(VoucherTypeManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VoucherTypeManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.receipt_outlined,
            label: 'New Type',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Voucher Types',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(VoucherTypeManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading voucher types...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load voucher types',
        message: controller.pageError!,
        onRetry: controller.loadTypes,
      );
    }

    // Migrated page/form state now lives in VoucherTypeManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Voucher Types',
      editorTitle: controller.selectedType?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<VoucherTypeModel>(
        searchController: controller.searchController,
        searchHint: 'Search voucher types',
        items: controller.filteredTypes,
        selectedItem: controller.selectedType,
        emptyMessage: 'No voucher types found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.name ?? '',
          subtitle: [
            item.code ?? '',
            item.voucherCategory ?? '',
            if ((item.documentType ?? '').isNotEmpty) item.documentType!,
          ].join(' · '),
          selected: selected,
          onTap: () => controller.selectType(item),
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
                  labelText: 'Code',
                  controller: controller.codeController,
                  validator: Validators.compose([
                    Validators.required('Code'),
                    Validators.optionalMaxLength(50, 'Code'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Name',
                  controller: controller.nameController,
                  validator: Validators.compose([
                    Validators.required('Name'),
                    Validators.optionalMaxLength(100, 'Name'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Voucher Category',
                  mappedItems: _categoryItems,
                  initialValue: controller.voucherCategory,
                  onChanged: controller.setVoucherCategory,
                  validator: Validators.requiredSelection('Voucher Category'),
                ),
                AppFormTextField(
                  labelText: 'Document Type',
                  controller: controller.documentTypeController,
                  validator: Validators.optionalMaxLength(50, 'Document Type'),
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
                    label: 'Auto Post',
                    value: controller.autoPost,
                    onChanged: controller.setAutoPost,
                  ),
                ),
                SizedBox(
                  width: AppUiConstants.switchFieldWidth,
                  child: AppSwitchTile(
                    label: 'Requires Approval',
                    value: controller.requiresApproval,
                    onChanged: controller.setRequiresApproval,
                  ),
                ),
                SizedBox(
                  width: AppUiConstants.switchFieldWidth,
                  child: AppSwitchTile(
                    label: 'Reference Allocation',
                    value: controller.allowsReferenceAllocation,
                    onChanged: controller.setAllowsReferenceAllocation,
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
                  label: controller.selectedType == null
                      ? 'Save Type'
                      : 'Update Type',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
                if (controller.selectedType?.id != null)
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
