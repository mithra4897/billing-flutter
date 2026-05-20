import '../../../controller/settings/communication/email_rules_management_controller.dart';
import '../../../screen.dart';

class EmailRulesPage extends StatefulWidget {
  const EmailRulesPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmailRulesPage> createState() => _EmailRulesPageState();
}

class _EmailRulesPageState extends State<EmailRulesPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('EmailRulesManagementController');
    Get.put(EmailRulesManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmailRulesManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewRule(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_outlined,
            label: 'New Rule',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Email Rules',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(EmailRulesManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading email rules...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load email rules',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Email Rules',
      editorTitle: controller.selectedRecord?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<EmailRuleModel>(
        searchController: controller.searchController,
        searchHint: 'Search email rules',
        items: controller.filteredRecords,
        selectedItem: controller.selectedRecord,
        emptyMessage: 'No email rules found.',
        itemBuilder: (record, selected) => SettingsListTile(
          title: stringValue(record.toJson(), 'rule_name', 'Rule'),
          subtitle: [
            stringValue(record.toJson(), 'rule_code'),
            stringValue(record.toJson(), 'module'),
            stringValue(record.toJson(), 'event_code'),
          ].where((value) => value.isNotEmpty).join(' • '),
          selected: selected,
          onTap: () => controller.selectRecord(record),
          trailing: SettingsStatusPill(
            label: boolValue(record.toJson(), 'is_active', fallback: true)
                ? 'Active'
                : 'Inactive',
            active: boolValue(record.toJson(), 'is_active', fallback: true),
          ),
        ),
      ),
      editor: Form(
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
                  labelText: 'Rule Code',
                  controller: controller.codeController,
                  validator: Validators.required('Rule code'),
                ),
                AppFormTextField(
                  labelText: 'Rule Name',
                  controller: controller.nameController,
                  validator: Validators.required('Rule name'),
                ),
                AppFormTextField(
                  labelText: 'Module',
                  controller: controller.moduleController,
                  validator: Validators.required('Module'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Document Type',
                  mappedItems: controller.documentTypeItems,
                  initialValue: controller.documentType,
                  onChanged: controller.setDocumentType,
                ),
                AppFormTextField(
                  labelText: 'Event Code',
                  controller: controller.eventCodeController,
                  validator: Validators.required('Event code'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Template',
                  mappedItems: controller.templateItems,
                  initialValue: controller.templateId,
                  onChanged: controller.setTemplateId,
                ),
                AppFormTextField(
                  labelText: 'Recipient Emails',
                  controller: controller.recipientEmailsController,
                ),
                AppFormTextField(
                  labelText: 'CC Emails',
                  controller: controller.ccEmailsController,
                ),
                AppFormTextField(
                  labelText: 'BCC Emails',
                  controller: controller.bccEmailsController,
                ),
                AppFormTextField(
                  labelText: 'Subject Override',
                  controller: controller.subjectOverrideController,
                ),
                AppFormTextField(
                  labelText: 'Body Override',
                  controller: controller.bodyOverrideController,
                  maxLines: 6,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Auto Enabled',
                    value: controller.autoEnabled,
                    onChanged: controller.setAutoEnabled,
                  ),
                ),
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Manual Enabled',
                    value: controller.manualEnabled,
                    onChanged: controller.setManualEnabled,
                  ),
                ),
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Send To Party Email',
                    value: controller.sendToPartyEmail,
                    onChanged: controller.setSendToPartyEmail,
                  ),
                ),
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Send To Contact Email',
                    value: controller.sendToContactEmail,
                    onChanged: controller.setSendToContactEmail,
                  ),
                ),
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Send To Assigned User',
                    value: controller.sendToAssignedUser,
                    onChanged: controller.setSendToAssignedUser,
                  ),
                ),
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Send To Owner User',
                    value: controller.sendToOwnerUser,
                    onChanged: controller.setSendToOwnerUser,
                  ),
                ),
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Active',
                    value: controller.isActive,
                    onChanged: controller.setIsActive,
                  ),
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
                  label: controller.selectedRecord == null
                      ? 'Save Rule'
                      : 'Update Rule',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
                if (intValue(
                      controller.selectedRecord?.toJson() ?? const {},
                      'id',
                    ) !=
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
