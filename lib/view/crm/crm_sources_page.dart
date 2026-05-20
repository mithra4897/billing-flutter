import '../../controller/crm/crm_sources_controller.dart';
import '../../screen.dart';

class CrmSourcesPage extends StatefulWidget {
  const CrmSourcesPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.startInNewMode = false,
  });

  final bool embedded;
  final bool editorOnly;
  final bool startInNewMode;

  @override
  State<CrmSourcesPage> createState() => _CrmSourcesPageState();
}

class _CrmSourcesPageState extends State<CrmSourcesPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('CrmSourcesController');
    Get.put(
      CrmSourcesController(startInNewMode: widget.startInNewMode),
      tag: _controllerTag,
    permanent: true,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CrmSourcesController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.add_outlined,
            label: 'New Source',
          ),
        ];

        final content = _buildContent(controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'CRM Sources',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(CrmSourcesController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading CRM sources...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM sources',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    // Migrated page/form state now lives in CrmSourcesController.
    return SettingsWorkspace(
      title: 'CRM Sources',
      scrollController: controller.pageScrollController,
      controller: controller.workspaceController,
      editorOnly: widget.editorOnly,
      editorTitle: controller.selectedItem?.toString() ?? 'New Source',
      list: SettingsListCard<CrmSourceModel>(
        searchController: controller.searchController,
        searchHint: 'Search sources',
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No CRM sources found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.toString(),
          subtitle: boolValue(item.toJson(), 'is_active', fallback: true)
              ? 'Active'
              : 'Inactive',
          selected: selected,
          onTap: () => controller.selectItem(item),
          trailing: SettingsStatusPill(
            label: boolValue(item.toJson(), 'is_active', fallback: true)
                ? 'Active'
                : 'Inactive',
            active: boolValue(item.toJson(), 'is_active', fallback: true),
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
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  controller: controller.nameController,
                  labelText: 'Source Name',
                  validator: Validators.required('Source Name'),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              value: controller.isActive,
              onChanged: controller.setIsActive,
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedItem == null
                      ? 'Save Source'
                      : 'Update Source',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
                if (controller.selectedItem != null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                    onPressed: controller.delete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
