import '../../../controller/settings/communication/email_templates_management_controller.dart';
import '../../../screen.dart';

class EmailTemplatesPage extends StatefulWidget {
  const EmailTemplatesPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmailTemplatesPage> createState() => _EmailTemplatesPageState();
}

class _EmailTemplatesPageState extends State<EmailTemplatesPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'EmailTemplatesManagementController',
    );
    Get.put(EmailTemplatesManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmailTemplatesManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewTemplate(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_outlined,
            label: 'New Template',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Email Templates',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(EmailTemplatesManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading email templates...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load email templates',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Email Templates',
      editorTitle: controller.selectedRecord?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<EmailTemplateModel>(
        searchController: controller.searchController,
        searchHint: 'Search email templates',
        items: controller.filteredRecords,
        selectedItem: controller.selectedRecord,
        emptyMessage: 'No email templates found.',
        itemBuilder: (record, selected) => SettingsListTile(
          title: stringValue(record.toJson(), 'template_name', 'Template'),
          subtitle: [
            stringValue(record.toJson(), 'template_code'),
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
                  labelText: 'Template Code',
                  controller: controller.codeController,
                  validator: Validators.required('Template code'),
                ),
                AppFormTextField(
                  labelText: 'Template Name',
                  controller: controller.nameController,
                  validator: Validators.required('Template name'),
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
                ),
                AppFormTextField(
                  labelText: 'Subject Template',
                  controller: controller.subjectController,
                  validator: Validators.required('Subject template'),
                ),
                AppFormTextField(
                  labelText: 'Body Template',
                  controller: controller.bodyController,
                  maxLines: 10,
                  validator: Validators.required('Body template'),
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
                    label: 'HTML Template',
                    value: controller.isHtml,
                    onChanged: controller.setIsHtml,
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
                      ? 'Save Template'
                      : 'Update Template',
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
