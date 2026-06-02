import '../../../controller/settings/accounting/posting_rule_group_management_controller.dart';
import '../../../screen.dart';

class PostingRuleGroupManagementPage extends StatefulWidget {
  const PostingRuleGroupManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PostingRuleGroupManagementPage> createState() =>
      _PostingRuleGroupManagementPageState();
}

class _PostingRuleGroupManagementPageState
    extends State<PostingRuleGroupManagementPage> {
  static const List<AppDropdownItem<String>> _triggerItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'on_save', label: 'On save'),
        AppDropdownItem(value: 'on_approve', label: 'On approve'),
        AppDropdownItem(value: 'on_post', label: 'On post'),
        AppDropdownItem(value: 'on_cancel', label: 'On cancel'),
        AppDropdownItem(value: 'on_reverse', label: 'On reverse'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'PostingRuleGroupManagementController',
    );
    Get.put(PostingRuleGroupManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostingRuleGroupManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.folder_special_outlined,
            label: 'New Group',
          ),
        ];
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Posting Rule Groups',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(PostingRuleGroupManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading posting rule groups...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load',
        message: controller.pageError!,
        onRetry: controller.load,
      );
    }

    // Migrated page/form state now lives in PostingRuleGroupManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Posting Rule Groups',
      editorTitle:
          stringValue(
            controller.json(controller.selected),
            'group_name',
          ).isEmpty
          ? null
          : stringValue(controller.json(controller.selected), 'group_name'),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<PostingRuleGroupModel>(
        searchController: controller.searchController,
        searchHint: 'Search groups',
        items: controller.filtered,
        selectedItem: controller.selected,
        emptyMessage: 'No posting rule groups.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'group_name'),
            subtitle: [
              stringValue(data, 'group_code'),
              stringValue(data, 'document_type'),
              stringValue(data, 'trigger_event'),
            ].join(' · '),
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
                AppFormTextField(
                  labelText: 'Group code',
                  controller: controller.codeController,
                  validator: Validators.compose([
                    Validators.required('Group code'),
                    Validators.optionalMaxLength(50, 'Group code'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Group name',
                  controller: controller.nameController,
                  validator: Validators.compose([
                    Validators.required('Group name'),
                    Validators.optionalMaxLength(150, 'Group name'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Document type',
                  mappedItems: controller.documentTypeItems,
                  initialValue: controller.documentType,
                  onChanged: controller.setDocumentType,
                  validator: Validators.requiredSelection('Document type'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Trigger event',
                  mappedItems: _triggerItems,
                  initialValue: controller.triggerEvent,
                  onChanged: controller.setTriggerEvent,
                ),
                AppFormTextField(
                  labelText: 'Description',
                  controller: controller.descriptionController,
                  maxLines: 3,
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
