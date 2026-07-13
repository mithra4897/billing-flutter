import '../../../controller/settings/user/module_preferences_management_controller.dart';
import '../../../screen.dart';

class ModulePreferencesPage extends StatefulWidget {
  const ModulePreferencesPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ModulePreferencesPage> createState() => _ModulePreferencesPageState();
}

class _ModulePreferencesPageState extends State<ModulePreferencesPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ModulePreferencesManagementController',
    );
    Get.put(ModulePreferencesManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ModulePreferencesManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: const <Widget>[], child: content);
        }

        return AppStandaloneShell(
          title: 'Module Preferences',
          scrollController: controller.pageScrollController,
          actions: const <Widget>[],
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ModulePreferencesManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading module preferences...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load module preferences',
        message: controller.pageError!,
        onRetry: controller.loadModules,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.isSuperAdmin) ...[
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache Controls',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use this admin panel to enable or disable shared master-data caching and clear cached data immediately.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                AppSwitchTile(
                  label: 'Enable Master Data Cache',
                  subtitle: controller.cacheEnabled
                      ? 'Shared master data stays loaded across screens until cleared or invalidated.'
                      : 'Every screen reloads master data instead of reusing the shared cache.',
                  value: controller.cacheEnabled,
                  onChanged: controller.cacheToggleSaving
                      ? null
                      : controller.setCacheEnabled,
                ),
                const SizedBox(height: 8),
                Text(
                  'Last loaded: ${controller.cacheLastLoadedLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppActionButton(
                      icon: Icons.delete_sweep_outlined,
                      label: controller.cacheClearing
                          ? 'Clearing...'
                          : 'Clear Cache',
                      onPressed: controller.cacheClearing
                          ? null
                          : controller.clearCache,
                      busy: controller.cacheClearing,
                      filled: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: SettingsWorkspace(
            controller: controller.workspaceController,
            title: 'Module Preferences',
            editorTitle: controller.selectedModule?.toString(),
            scrollController: controller.pageScrollController,
            list: SettingsListCard<ModuleModel>(
              searchController: controller.searchController,
              searchHint: 'Search modules',
              items: controller.filteredModules,
              selectedItem: controller.selectedModule,
              emptyMessage: 'No modules found.',
              itemBuilder: (item, selected) => SettingsListTile(
                title: item.moduleName ?? '',
                subtitle: [
                  item.moduleCode ?? '',
                  item.moduleGroup ?? '',
                  if (item.isHidden == true) 'Hidden',
                ].where((part) => part.trim().isNotEmpty).join(' · '),
                selected: selected,
                onTap: () => controller.selectModule(item),
              ),
            ),
            editor: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.selectedModule == null)
                  const Text('Select a module to manage its menu preference.')
                else ...[
                  if (controller.formError != null) ...[
                    AppErrorStateView.inline(message: controller.formError!),
                    const SizedBox(height: 16),
                  ],
                  SettingsFormWrap(
                    children: [
                      AppFormTextField(
                        labelText: 'Module',
                        controller: TextEditingController(
                          text: controller.selectedModule?.moduleName ?? '',
                        ),
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Code',
                        controller: TextEditingController(
                          text: controller.selectedModule?.moduleCode ?? '',
                        ),
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Group',
                        controller: TextEditingController(
                          text: controller.selectedModule?.moduleGroup ?? '',
                        ),
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Route',
                        controller: TextEditingController(
                          text: controller.selectedModule?.routePath ?? '',
                        ),
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Menu Sort Order',
                        controller: controller.sortOrderController,
                        keyboardType: TextInputType.number,
                        validator: Validators.optionalNonNegativeInteger(
                          'Menu Sort Order',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppSwitchTile(
                    label: 'Hide This Module In Menu',
                    subtitle: controller.isHidden
                        ? 'This module will stay hidden from the main menu.'
                        : 'This module will stay visible in the main menu.',
                    value: controller.isHidden,
                    onChanged: controller.setIsHidden,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppActionButton(
                      icon: Icons.save_outlined,
                      label: 'Save Preferences',
                      onPressed: controller.save,
                      busy: controller.saving,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
