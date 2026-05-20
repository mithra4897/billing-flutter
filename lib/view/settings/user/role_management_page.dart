import '../../../controller/settings/user/role_management_controller.dart';
import '../../../screen.dart';

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({
    super.key,
    this.initialRoleId,
    this.embedded = false,
  });

  final int? initialRoleId;
  final bool embedded;

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage>
    with SingleTickerProviderStateMixin {
  late final String _controllerTag;
  late final RoleManagementController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('RoleManagementController');
    _controller = Get.put(
      RoleManagementController(initialRoleId: widget.initialRoleId),
      tag: _controllerTag,
    permanent: true,
    );
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _controller.setActiveTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RoleManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = controller.initialLoading
            ? const AppLoadingView(message: 'Loading roles...')
            : controller.pageError != null
            ? AppErrorStateView(
                title: 'Unable to load roles',
                message: controller.pageError!,
                onRetry: controller.loadInitial,
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final showSideList = constraints.maxWidth >= 1100;

                  return SingleChildScrollView(
                    controller: controller.pageScrollController,
                    padding: const EdgeInsets.all(AppUiConstants.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showSideList)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: AppUiConstants.settingsSidebarWidth,
                                child: _buildRoleList(context, controller),
                              ),
                              const SizedBox(width: AppUiConstants.spacingXl),
                              Expanded(
                                child: _buildEditor(context, controller),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildRoleList(context, controller),
                              const SizedBox(height: AppUiConstants.spacingLg),
                              _buildEditor(context, controller),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              );

        if (widget.embedded) {
          return ShellPageActions(
            actions: [
              AdaptiveShellActionButton(
                onPressed: controller.resetForm,
                icon: Icons.add,
                label: 'New Role',
              ),
            ],
            child: content,
          );
        }

        return FutureBuilder<PublicBrandingModel?>(
          future: SessionStorage.getBranding(),
          builder: (context, snapshot) {
            final branding =
                snapshot.data ??
                const PublicBrandingModel(companyName: 'Billing ERP');

            return AdaptiveShell(
              title: 'Roles',
              branding: branding,
              scrollController: controller.pageScrollController,
              actions: [
                AdaptiveShellActionButton(
                  onPressed: controller.resetForm,
                  icon: Icons.add,
                  label: 'New Role',
                ),
              ],
              child: content,
            );
          },
        );
      },
    );
  }

  Widget _buildRoleList(
    BuildContext context,
    RoleManagementController controller,
  ) {
    return SettingsListCard<RoleModel>(
      searchController: controller.searchController,
      searchHint: 'Search roles',
      items: controller.filteredRoles,
      selectedItem: controller.filteredRoles.cast<RoleModel?>().firstWhere(
        (role) => role?.id == controller.selectedRoleId,
        orElse: () => null,
      ),
      emptyMessage: 'No roles found.',
      itemBuilder: (role, selected) => SettingsListTile(
        title: role.name ?? role.code ?? 'Role',
        subtitle: role.code ?? '',
        detail: role.isSystemRole == true
            ? 'System Role'
            : (role.isActive == true ? 'Active' : 'Inactive'),
        selected: selected,
        onTap: () {
          if (role.id != null) {
            controller.loadRole(role.id!, resetTab: true);
          }
        },
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    RoleManagementController controller,
  ) {
    final showDetailTabs = !controller.isNewRole && controller.selectedRoleId != null;
    if (showDetailTabs) {
      _syncTabController(controller.activeTabIndex);
    }

    // Migrated page/form state now lives in RoleManagementController.
    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const SizedBox(height: AppUiConstants.spacingSm),
          Column(
            children: [
              if (showDetailTabs)
                TabBar(
                  controller: _tabController,
                  onTap: controller.setActiveTabIndex,
                  isScrollable: true,
                  tabs: const [Tab(text: 'Profile'), Tab(text: 'Permissions')],
                ),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacing2xl,
                ),
                child: showDetailTabs
                    ? [
                        _buildProfileTab(context, controller),
                        _buildPermissionsTab(context, controller),
                      ][controller.activeTabIndex]
                    : _buildProfileTab(context, controller),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _syncTabController(int nextIndex) {
    if (!mounted) {
      return;
    }
    final clampedIndex = nextIndex.clamp(0, _tabController.length - 1);
    if (_tabController.index == clampedIndex || _tabController.indexIsChanging) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabController.index == clampedIndex) {
        return;
      }
      _tabController.animateTo(clampedIndex);
    });
  }

  Widget _buildProfileTab(
    BuildContext context,
    RoleManagementController controller,
  ) {
    if (controller.loadingRoleDetails) {
      return const Padding(
        padding: EdgeInsets.all(AppUiConstants.cardPadding),
        child: AppLoadingView(message: 'Loading role details...'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppUiConstants.cardPadding),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  controller: controller.nameController,
                  labelText: 'Role Name',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Role name is required'
                      : null,
                ),
                AppFormTextField(
                  controller: controller.codeController,
                  textCapitalization: TextCapitalization.characters,
                  labelText: 'Role Code',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Role code is required'
                      : null,
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.isActive ? 'active' : 'inactive',
                  labelText: 'Status',
                  mappedItems: const [
                    AppDropdownItem(value: 'active', label: 'Active'),
                    AppDropdownItem(value: 'inactive', label: 'Inactive'),
                  ],
                  onChanged: controller.setIsActiveFromStatus,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppFormTextField(
              controller: controller.descriptionController,
              maxLines: 3,
              labelText: 'Description',
            ),
            const SizedBox(height: 16),
            if (controller.isSystemRole)
              Text(
                'This is a system role. Changes should be made carefully.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).extension<AppThemeExtension>()!.mutedText,
                ),
              ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  onPressed: controller.savingProfile
                      ? null
                      : controller.saveProfile,
                  icon: Icons.save_outlined,
                  label: controller.savingProfile ? 'Saving...' : 'Save Role',
                  busy: controller.savingProfile,
                ),
              ],
            ),
            if (controller.formError != null &&
                controller.formError!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                controller.formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsTab(
    BuildContext context,
    RoleManagementController controller,
  ) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    if (controller.isNewRole) {
      return _emptyStateCard(
        context,
        icon: Icons.verified_user_outlined,
        title: 'Permissions Will Appear After Save',
        message:
            'Create the role first, then we can configure its default access rights here.',
      );
    }

    if (controller.loadingPermissions) {
      return const Padding(
        padding: EdgeInsets.all(AppUiConstants.cardPadding),
        child: AppLoadingView(message: 'Loading permissions...'),
      );
    }

    if (controller.rolePermissions.isEmpty) {
      return _emptyStateCard(
        context,
        icon: Icons.lock_outline,
        title: 'No Permissions Loaded',
        message:
            'This role does not have a permission matrix loaded yet. Try refreshing the role again.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Row(
            children: [
              const Spacer(),
              FilledButton.icon(
                onPressed: controller.savingPermissions
                    ? null
                    : controller.savePermissions,
                icon: controller.savingPermissions
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: Text(
                  controller.savingPermissions
                      ? 'Saving...'
                      : 'Save Permissions',
                ),
              ),
            ],
          ),
        ),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppUiConstants.cardPadding),
          children: controller.rolePermissions.map((permission) {
            final permissionKey =
                '${permission.permissionId ?? permission.code ?? permission.name ?? 'permission'}';
            final index = controller.rolePermissions.indexOf(permission);
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              color: appTheme.subtleFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppUiConstants.buttonRadius,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                initiallyExpanded: false,
                onExpansionChanged: (expanded) =>
                    controller.togglePermissionModule(permissionKey, expanded),
                title: Text(permission.name ?? permission.code ?? 'Permission'),
                trailing: _permissionGroupTrailing(
                  context,
                  controller,
                  permissionKey,
                  permission,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((permission.description ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(permission.description!),
                          ),
                        if ((permission.module ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              permission.module!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: appTheme.mutedText),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _permCheck(
                              'View',
                              permission.allowView ?? false,
                              (value) =>
                                  controller.togglePermission(index, 'view', value),
                            ),
                            _permCheck(
                              'Create',
                              permission.allowCreate ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'create',
                                value,
                              ),
                            ),
                            _permCheck(
                              'Update',
                              permission.allowUpdate ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'update',
                                value,
                              ),
                            ),
                            _permCheck(
                              'Delete',
                              permission.allowDelete ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'delete',
                                value,
                              ),
                            ),
                            _permCheck(
                              'Approve',
                              permission.allowApprove ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'approve',
                                value,
                              ),
                            ),
                            _permCheck(
                              'Print',
                              permission.allowPrint ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'print',
                                value,
                              ),
                            ),
                            _permCheck(
                              'Export',
                              permission.allowExport ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'export',
                                value,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _emptyStateCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.all(AppUiConstants.cardPadding),
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: appTheme.subtleFill,
          borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: appTheme.mutedText),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appTheme.mutedText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permCheck(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
    );
  }

  Widget _permissionGroupTrailing(
    BuildContext context,
    RoleManagementController controller,
    String permissionKey,
    RolePermissionModel permission,
  ) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final isExpanded = controller.expandedPermissionModules.contains(
      permissionKey,
    );
    final summary = controller.permissionRightsSummary(permission);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (summary.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              summary,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        const SizedBox(width: 10),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: appTheme.cardBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: appTheme.mutedText,
          ),
        ),
      ],
    );
  }
}
