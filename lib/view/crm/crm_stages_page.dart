import '../../controller/crm/crm_stages_controller.dart';
import '../../screen.dart';

class CrmStagesPage extends StatefulWidget {
  const CrmStagesPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.startInNewMode = false,
  });

  final bool embedded;
  final bool editorOnly;
  final bool startInNewMode;

  @override
  State<CrmStagesPage> createState() => _CrmStagesPageState();
}

class _CrmStagesPageState extends State<CrmStagesPage> {
  static const List<AppDropdownItem<String>> _stageTypes =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'lead', label: 'Lead'),
        AppDropdownItem(value: 'enquiry', label: 'Open'),
        AppDropdownItem(value: 'opportunity', label: 'In Progress'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('CrmStagesController');
    Get.put(
      CrmStagesController(startInNewMode: widget.startInNewMode),
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
    return GetBuilder<CrmStagesController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.add_outlined,
            label: 'New Stage',
          ),
        ];

        final content = _buildContent(controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'CRM Stages',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(CrmStagesController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading CRM stages...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM stages',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    // Migrated page/form state now lives in CrmStagesController.
    return SettingsWorkspace(
      title: 'CRM Stages',
      scrollController: controller.pageScrollController,
      controller: controller.workspaceController,
      editorOnly: widget.editorOnly,
      editorTitle: controller.selectedItem?.toString() ?? 'New Stage',
      list: SettingsListCard<CrmStageModel>(
        searchController: controller.searchController,
        searchHint: 'Search stages',
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No CRM stages found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: item.toString(),
            subtitle: [
              stringValue(data, 'stage_type'),
              'Seq ${stringValue(data, 'sequence_no')}',
            ].join(' • '),
            selected: selected,
            onTap: () => controller.selectItem(item),
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
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  controller: controller.nameController,
                  labelText: 'Stage Name',
                  validator: Validators.required('Stage Name'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Stage Type',
                  mappedItems: _stageTypes,
                  initialValue: controller.stageType,
                  onChanged: controller.setStageType,
                ),
                AppFormTextField(
                  controller: controller.sequenceController,
                  labelText: 'Sequence No',
                  keyboardType: TextInputType.number,
                  validator: Validators.compose([
                    Validators.required('Sequence No'),
                    Validators.optionalNonNegativeNumber('Sequence No'),
                  ]),
                ),
                AppFormTextField(
                  controller: controller.probabilityController,
                  labelText: 'Probability %',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Probability %',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Default Stage',
              value: controller.isDefault,
              onChanged: controller.setIsDefault,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
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
                      ? 'Save Stage'
                      : 'Update Stage',
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
