import '../../../controller/settings/tax/state_management_controller.dart';
import '../../../screen.dart';

class StateManagementPage extends StatefulWidget {
  const StateManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StateManagementPage> createState() => _StateManagementPageState();
}

class _StateManagementPageState extends State<StateManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('StateManagementController');
    Get.put(StateManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StateManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.map_outlined,
            label: 'New State',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'States',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(StateManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading states...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load states',
        message: controller.pageError!,
        onRetry: controller.loadStates,
      );
    }

    // Migrated page/form state now lives in StateManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'States',
      editorTitle: controller.selectedState?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<StateModel>(
        searchController: controller.searchController,
        searchHint: 'Search states',
        items: controller.filteredStates,
        selectedItem: controller.selectedState,
        emptyMessage: 'No states found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.stateName,
          subtitle: [
            item.countryCode,
            item.stateCode,
            if (item.gstStateCode.isNotEmpty) item.gstStateCode,
          ].join(' · '),
          selected: selected,
          onTap: () => controller.selectState(item),
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
              controller: controller.countryCodeController,
              labelText: 'Country Code',
              validator: Validators.compose([
                Validators.required('Country Code'),
                Validators.optionalMaxLength(10, 'Country Code'),
              ]),
            ),
            AppFormTextField(
              controller: controller.stateCodeController,
              labelText: 'State Code',
              validator: Validators.compose([
                Validators.required('State Code'),
                Validators.optionalMaxLength(10, 'State Code'),
              ]),
            ),
            AppFormTextField(
              controller: controller.stateNameController,
              labelText: 'State Name',
              validator: Validators.compose([
                Validators.required('State Name'),
                Validators.optionalMaxLength(100, 'State Name'),
              ]),
            ),
            AppFormTextField(
              controller: controller.gstStateCodeController,
              labelText: 'GST State Code',
              validator: Validators.optionalMaxLength(10, 'GST State Code'),
            ),
            AppSwitchTile(
              contentPadding: EdgeInsets.zero,
              label: 'Union Territory',
              value: controller.isUnionTerritory,
              onChanged: controller.setIsUnionTerritory,
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
                if (controller.selectedState?.id != null)
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
