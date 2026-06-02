import '../../../controller/settings/communication/email_module_settings_management_controller.dart';
import '../../../screen.dart';

class EmailModuleSettingsPage extends StatefulWidget {
  const EmailModuleSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmailModuleSettingsPage> createState() =>
      _EmailModuleSettingsPageState();
}

class _EmailModuleSettingsPageState extends State<EmailModuleSettingsPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'EmailModuleSettingsManagementController',
    );
    Get.put(EmailModuleSettingsManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmailModuleSettingsManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewModuleSetting(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_outlined,
            label: 'New Module Setting',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Module Settings',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(EmailModuleSettingsManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading email module settings...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load module settings',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Module Settings',
      editorTitle: controller.selectedRecord?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<EmailModuleSettingModel>(
        searchController: controller.searchController,
        searchHint: 'Search module settings',
        items: controller.filteredRecords,
        selectedItem: controller.selectedRecord,
        emptyMessage: 'No module settings found.',
        itemBuilder: (record, selected) => SettingsListTile(
          title: stringValue(record.toJson(), 'module', 'Module'),
          subtitle: stringValue(
            record.toJson(),
            'document_type',
            'All documents',
          ),
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
                  labelText: 'Remarks',
                  controller: controller.remarksController,
                  maxLines: 3,
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
                    label: 'Auto Email Enabled',
                    value: controller.autoEmailEnabled,
                    onChanged: controller.setAutoEmailEnabled,
                  ),
                ),
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Manual Email Enabled',
                    value: controller.manualEmailEnabled,
                    onChanged: controller.setManualEmailEnabled,
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
            AppActionButton(
              icon: Icons.save_outlined,
              label: controller.selectedRecord == null
                  ? 'Save Module Setting'
                  : 'Update Module Setting',
              onPressed: controller.save,
              busy: controller.saving,
            ),
          ],
        ),
      ),
    );
  }
}
