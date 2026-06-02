import '../../../controller/settings/tax/gst_tax_rule_management_controller.dart';
import '../../../screen.dart';

class GstTaxRuleManagementPage extends StatefulWidget {
  const GstTaxRuleManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<GstTaxRuleManagementPage> createState() =>
      _GstTaxRuleManagementPageState();
}

class _GstTaxRuleManagementPageState extends State<GstTaxRuleManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        persistentControllerTag('GstTaxRuleManagementController');
    Get.put(GstTaxRuleManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GstTaxRuleManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.rule_outlined,
            label: 'New Tax Rule',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'GST Tax Rules',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    GstTaxRuleManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading GST tax rules...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load GST tax rules',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    // Migrated page/form state now lives in GstTaxRuleManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'GST Tax Rules',
      editorTitle: controller.selectedItem?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<GstTaxRuleModel>(
        searchController: controller.searchController,
        searchHint: 'Search GST tax rules',
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No GST tax rules found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.ruleName,
          subtitle: [
            item.ruleCode,
            item.transactionType,
            item.taxApplication,
          ].join(' · '),
          selected: selected,
          onTap: () => controller.selectItem(item),
        ),
      ),
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: SettingsFormWrap(
          children: [
            if (controller.formError != null) ...[
              Text(
                controller.formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            AppFormTextField(
              controller: controller.codeController,
              labelText: 'Rule Code',
              validator: Validators.compose([
                Validators.required('Rule Code'),
                Validators.optionalMaxLength(50, 'Rule Code'),
              ]),
            ),
            const SizedBox(height: 12),
            AppFormTextField(
              controller: controller.nameController,
              labelText: 'Rule Name',
              validator: Validators.compose([
                Validators.required('Rule Name'),
                Validators.optionalMaxLength(150, 'Rule Name'),
              ]),
            ),
            const SizedBox(height: 12),
            AppDropdownField<String>(
              initialValue: controller.transactionType,
              labelText: 'Transaction Type',
              items: GstTaxRuleManagementController.transactionTypes,
              onChanged: controller.setTransactionType,
            ),
            const SizedBox(height: 12),
            AppDropdownField<String>(
              initialValue: controller.itemType,
              labelText: 'Item Type',
              items: GstTaxRuleManagementController.itemTypes,
              onChanged: controller.setItemType,
            ),
            const SizedBox(height: 12),
            AppDropdownField<int>(
              initialValue: controller.taxCodeId,
              labelText: 'Tax Code',
              items: controller.taxCodes
                  .map(
                    (taxCode) => DropdownMenuItem<int>(
                      value: taxCode.id,
                      child: Text(taxCode.toString()),
                    ),
                  )
                  .toList(growable: false),
              onChanged: controller.setTaxCodeId,
              validator: (value) =>
                  Validators.requiredSelectionField(value, 'Tax Code'),
            ),
            const SizedBox(height: 12),
            AppDropdownField<String>(
              initialValue: controller.placeResult,
              labelText: 'Place Of Supply Result',
              items: GstTaxRuleManagementController.placeResults,
              onChanged: controller.setPlaceResult,
            ),
            const SizedBox(height: 12),
            AppDropdownField<String>(
              initialValue: controller.taxApplication,
              labelText: 'Tax Application',
              items: GstTaxRuleManagementController.taxApplications,
              onChanged: controller.setTaxApplication,
            ),
            const SizedBox(height: 12),
            AppFormTextField(
              controller: controller.priorityController,
              labelText: 'Priority Order',
              keyboardType: TextInputType.number,
              validator: Validators.optionalNonNegativeInteger(
                'Priority Order',
              ),
            ),
            const SizedBox(height: 12),
            AppFormTextField(
              controller: controller.remarksController,
              labelText: 'Remarks',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            AppSwitchTile(
              contentPadding: EdgeInsets.zero,
              label: 'Reverse Charge Applicable',
              value: controller.reverseCharge,
              onChanged: controller.setReverseCharge,
            ),
            AppSwitchTile(
              contentPadding: EdgeInsets.zero,
              label: 'Input Tax Credit Allowed',
              value: controller.itcAllowed,
              onChanged: controller.setItcAllowed,
            ),
            AppSwitchTile(
              contentPadding: EdgeInsets.zero,
              label: 'Active',
              value: controller.isActive,
              onChanged: controller.setIsActive,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (controller.selectedItem?.id != null)
                  TextButton(
                    onPressed: controller.saving ? null : controller.delete,
                    child: const Text('Delete'),
                  ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: controller.saving ? null : controller.save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(controller.saving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
