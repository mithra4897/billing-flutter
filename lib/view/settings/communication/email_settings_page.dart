import '../../../controller/settings/communication/email_settings_management_controller.dart';
import '../../../screen.dart';

class EmailSettingsPage extends StatefulWidget {
  const EmailSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmailSettingsPage> createState() => _EmailSettingsPageState();
}

class _EmailSettingsPageState extends State<EmailSettingsPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'EmailSettingsManagementController',
    );
    Get.put(EmailSettingsManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmailSettingsManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewEmailSetting(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_outlined,
            label: 'New Email Setting',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Email Settings',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(EmailSettingsManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading email settings...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load email settings',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Email Settings',
      editorTitle: controller.selectedSetting?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<EmailSettingModel>(
        searchController: controller.searchController,
        searchHint: 'Search email settings',
        items: controller.filteredSettings,
        selectedItem: controller.selectedSetting,
        emptyMessage: 'No email settings found.',
        itemBuilder: (setting, selected) {
          final data = setting.toJson();
          return SettingsListTile(
            title: stringValue(data, 'setting_name', 'Email Setting'),
            subtitle: [
              stringValue(data, 'mail_driver').toUpperCase(),
              stringValue(data, 'from_email'),
            ].where((value) => value.isNotEmpty).join(' • '),
            selected: selected,
            onTap: () => controller.selectSetting(setting),
            trailing: SettingsStatusPill(
              label: boolValue(data, 'is_active', fallback: true)
                  ? 'Active'
                  : 'Inactive',
              active: boolValue(data, 'is_active', fallback: true),
            ),
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
              const SizedBox(height: 16),
            ],
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  labelText: 'Setting Name',
                  controller: controller.settingNameController,
                  validator: Validators.required('Setting name'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Mail Driver',
                  mappedItems: EmailSettingsManagementController.driverItems,
                  initialValue: controller.mailDriver,
                  onChanged: controller.setMailDriver,
                ),
                AppFormTextField(
                  labelText: 'From Name',
                  controller: controller.fromNameController,
                  validator: Validators.required('From name'),
                ),
                AppFormTextField(
                  labelText: 'From Email',
                  controller: controller.fromEmailController,
                  validator: Validators.required('From email'),
                ),
                AppFormTextField(
                  labelText: 'Reply-To Email',
                  controller: controller.replyToEmailController,
                ),
                AppFormTextField(
                  labelText: 'SMTP Host',
                  controller: controller.smtpHostController,
                ),
                AppFormTextField(
                  labelText: 'SMTP Port',
                  controller: controller.smtpPortController,
                  keyboardType: TextInputType.number,
                  numericDisplayKind: AppNumericDisplayKind.quantity,
                  quantityAllowsFraction: false,
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Encryption',
                  mappedItems:
                      EmailSettingsManagementController.encryptionItems,
                  initialValue: controller.smtpEncryption,
                  onChanged: controller.setSmtpEncryption,
                ),
                AppFormTextField(
                  labelText: 'SMTP Username',
                  controller: controller.smtpUsernameController,
                ),
                AppFormTextField(
                  labelText: 'SMTP Password',
                  controller: controller.smtpPasswordController,
                  obscureText: true,
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
                    label: 'Default Setting',
                    value: controller.isDefault,
                    onChanged: controller.setIsDefault,
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
                  label: controller.selectedSetting == null
                      ? 'Save Email Setting'
                      : 'Update Email Setting',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
