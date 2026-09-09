import '../../../controller/settings/master/document_term_settings_controller.dart';
import '../../../screen.dart';

class DocumentTermSettingsPage extends StatefulWidget {
  const DocumentTermSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DocumentTermSettingsPage> createState() =>
      _DocumentTermSettingsPageState();
}

class _DocumentTermSettingsPageState extends State<DocumentTermSettingsPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'DocumentTermSettingsController',
      scope: <String, Object?>{
        'identity': identityHashCode(this),
        'embedded': widget.embedded,
      },
    );
    _registerController();
  }

  @override
  void dispose() {
    if (Get.isRegistered<DocumentTermSettingsController>(tag: _controllerTag)) {
      Get.delete<DocumentTermSettingsController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  void _registerController() {
    if (Get.isRegistered<DocumentTermSettingsController>(tag: _controllerTag)) {
      return;
    }
    Get.put(DocumentTermSettingsController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DocumentTermSettingsController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = controller.canCreate
            ? <Widget>[
                AdaptiveShellActionButton(
                  onPressed: () => controller.startNew(
                    isDesktop: Responsive.isDesktop(context),
                  ),
                  icon: Icons.description_outlined,
                  label: 'New Terms',
                ),
              ]
            : const <Widget>[];
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Document Terms',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(DocumentTermSettingsController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading document terms...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load document terms',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Document Terms',
      editorTitle: controller.selectedRecord?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<DocumentTermSettingModel>(
        searchController: controller.searchController,
        searchHint: 'Search document types',
        items: controller.filteredRecords,
        selectedItem: controller.selectedRecord,
        emptyMessage: 'No supported document types found.',
        itemBuilder: (record, selected) => SettingsListTile(
          title: record.documentLabel,
          subtitle: record.documentType,
          selected: selected,
          onTap: () => controller.selectRecord(record),
          trailing: SettingsStatusPill(
            label: record.isActive ? 'Active' : 'Inactive',
            active: record.isActive,
          ),
        ),
      ),
      editorBuilder: (_) => Form(
        child: Builder(
          builder: (formContext) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company: ${controller.companyName}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              Text(
                'Active terms apply to new documents. Financial year and document series only control numbering.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppUiConstants.spacingLg),
              if (controller.formError != null) ...[
                AppErrorStateView.inline(message: controller.formError!),
                const SizedBox(height: AppUiConstants.spacingMd),
              ],
              SettingsFormWrap(
                children: [
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Document Type',
                    mappedItems: controller.documentTypeItems,
                    initialValue: controller.documentType,
                    onChanged: controller.selectedRecord == null
                        ? controller.setDocumentType
                        : null,
                    enabled: controller.selectedRecord == null,
                    isRequired: true,
                    validator: (value) =>
                        value == null ? 'Document Type is required' : null,
                  ),
                  AppFormTextField(
                    labelText: 'Terms & Conditions',
                    controller: controller.termsController,
                    maxLines: 16,
                    inputFormatters: [LengthLimitingTextInputFormatter(20000)],
                    hintText:
                        'Leave blank when this document type should not show terms.',
                  ),
                  AppSwitchTile(
                    label: 'Active',
                    subtitle: 'Automatically apply to new documents.',
                    value: controller.isActive,
                    onChanged: controller.setIsActive,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingLg),
              AppActionButton(
                icon: Icons.save_outlined,
                label: controller.selectedRecord == null
                    ? 'Save Document Terms'
                    : 'Update Document Terms',
                onPressed: () {
                  if (Form.of(formContext).validate()) {
                    controller.save();
                  }
                },
                busy: controller.saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
