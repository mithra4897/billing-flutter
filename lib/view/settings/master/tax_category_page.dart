import '../../../controller/settings/master/tax_category_management_controller.dart';
import '../../../screen.dart';

class TaxCategoryManagementPage extends StatefulWidget {
  const TaxCategoryManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TaxCategoryManagementPage> createState() =>
      _TaxCategoryManagementPageState();
}

class _TaxCategoryManagementPageState extends State<TaxCategoryManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        persistentControllerTag('TaxCategoryManagementController');
    Get.put(TaxCategoryManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxCategoryManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.add_chart_outlined,
            label: 'New Tax Code',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Tax Codes',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    TaxCategoryManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading tax codes...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load tax codes',
        message: controller.pageError!,
        onRetry: controller.loadTaxCodes,
      );
    }

    // Migrated page/form state now lives in TaxCategoryManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Tax Codes',
      editorTitle: controller.selectedTaxCode?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<TaxCodeModel>(
        searchController: controller.searchController,
        searchHint: 'Search tax codes',
        items: controller.filteredTaxCodes,
        selectedItem: controller.selectedTaxCode,
        emptyMessage: 'No tax codes found.',
        itemBuilder: (taxCode, selected) => SettingsListTile(
          title: taxCode.taxName ?? '-',
          subtitle: [
            taxCode.taxCode ?? '',
            taxCode.taxType?.toUpperCase() ?? '',
            if (taxCode.taxRate != null) '${taxCode.taxRate}%',
          ].where((value) => value.isNotEmpty).join(' • '),
          selected: selected,
          onTap: () => controller.selectTaxCode(taxCode),
          trailing: SettingsStatusPill(
            label: taxCode.isActive ? 'Active' : 'Inactive',
            active: taxCode.isActive,
          ),
        ),
      ),
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: 16),
            ],
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  labelText: 'Tax Code',
                  controller: controller.codeController,
                  validator: Validators.required('Tax Code'),
                ),
                AppFormTextField(
                  labelText: 'Tax Name',
                  controller: controller.nameController,
                  validator: Validators.required('Tax name'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Tax Type',
                  mappedItems: TaxCategoryManagementController.taxTypeItems,
                  initialValue: controller.taxType,
                  onChanged: controller.setTaxType,
                ),
                AppFormTextField(
                  labelText: 'Tax Rate (%)',
                  controller: controller.rateController,
                  keyboardType: TextInputType.number,
                  validator: Validators.required('Tax rate'),
                ),
                AppFormTextField(
                  labelText: 'CESS Rate (%)',
                  controller: controller.cessRateController,
                  keyboardType: TextInputType.number,
                ),
                AppFormTextField(
                  labelText: 'HSN / SAC',
                  controller: controller.hsnSacController,
                ),
                AppSwitchTile(
                  label: 'Active',
                  value: controller.isActive,
                  onChanged: controller.setIsActive,
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: controller.remarksController,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedTaxCode == null
                      ? 'Save Tax Category'
                      : 'Update Tax Category',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
                if (controller.selectedTaxCode?.id != null)
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
