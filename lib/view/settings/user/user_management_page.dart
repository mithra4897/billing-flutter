import '../../../controller/settings/user/user_management_controller.dart';
import '../../../screen.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({
    super.key,
    this.initialUserId,
    this.embedded = false,
  });

  final int? initialUserId;
  final bool embedded;

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage>
    with SingleTickerProviderStateMixin {
  late final String _controllerTag;
  late final UserManagementController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('UserManagementController');
    _controller = Get.put(
      UserManagementController(initialUserId: widget.initialUserId),
      tag: _controllerTag,
    permanent: true,
    );
    _tabController = TabController(length: 4, vsync: this);
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
    return GetBuilder<UserManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = controller.initialLoading
            ? const AppLoadingView(message: 'Loading users...')
            : controller.pageError != null
                ? AppErrorStateView(
                    title: 'Unable to load users',
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
                                    child: _buildUserList(context, controller),
                                  ),
                                  const SizedBox(
                                    width: AppUiConstants.spacingXl,
                                  ),
                                  Expanded(
                                    child: _buildEditor(context, controller),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildUserList(context, controller),
                                  const SizedBox(
                                    height: AppUiConstants.spacingLg,
                                  ),
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
                label: 'New User',
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
              title: 'Users',
              branding: branding,
              scrollController: controller.pageScrollController,
              actions: [
                AdaptiveShellActionButton(
                  onPressed: controller.resetForm,
                  icon: Icons.add,
                  label: 'New User',
                ),
              ],
              child: content,
            );
          },
        );
      },
    );
  }

  Widget _buildUserList(
    BuildContext context,
    UserManagementController controller,
  ) {
    return SettingsListCard<UserModel>(
      searchController: controller.searchController,
      searchHint: 'Search users',
      items: controller.filteredUsers,
      selectedItem: controller.filteredUsers.cast<UserModel?>().firstWhere(
        (user) => user?.id == controller.selectedUserId,
        orElse: () => null,
      ),
      emptyMessage: 'No users found.',
      itemBuilder: (user, selected) => SettingsListTile(
        title: user.displayName ??
            '${user.firstName ?? ''} ${user.lastName ?? ''}'
                .trim()
                .ifEmpty(user.username ?? 'User'),
        subtitle: user.username ?? '',
        detail: user.status ?? 'active',
        selected: selected,
        onTap: () {
          if (user.id != null) {
            controller.loadUser(user.id!);
          }
        },
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    UserManagementController controller,
  ) {
    final showDetailTabs = !controller.isNewUser && controller.selectedUserId != null;
    if (showDetailTabs) {
      _syncTabController(controller.activeTabIndex);
    }

    // Migrated page/form state now lives in UserManagementController.
    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppUiConstants.spacing2xl,
              AppUiConstants.pagePadding,
              AppUiConstants.spacing2xl,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isNewUser
                            ? 'Fill the complete user profile first. After saving, the permission, audit, and login tabs become active.'
                            : 'Role gives the base access, and direct permissions can be added in the next tab.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).extension<AppThemeExtension>()!.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (showDetailTabs)
                TabBar(
                  controller: _tabController,
                  onTap: controller.setActiveTabIndex,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Permissions'),
                    Tab(text: 'Audit Log'),
                    Tab(text: 'Login History'),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacing2xl,
                ),
                child: showDetailTabs
                    ? [
                        _buildProfileTab(context, controller),
                        _buildPermissionsTab(context, controller),
                        _buildAuditTab(context, controller),
                        _buildLoginHistoryTab(context, controller),
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
    UserManagementController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppUiConstants.cardPadding),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
                AppSearchPickerField<int>(
                  labelText: 'Employee',
                  selectedLabel: controller.selectedEmployeeLabel,
                  options: controller.availableEmployees
                      .where((employee) => employee.id != null)
                      .map(
                        (employee) => AppSearchPickerOption<int>(
                          value: employee.id!,
                          label: employee.employeeName ??
                              employee.employeeCode ??
                              'Employee',
                          subtitle: [
                            employee.employeeCode,
                            employee.email,
                            employee.mobile,
                          ]
                              .whereType<String>()
                              .where((value) => value.trim().isNotEmpty)
                              .join(' | '),
                          searchText: [
                            employee.employeeCode,
                            employee.employeeName,
                            employee.email,
                            employee.mobile,
                          ].whereType<String>().join(' '),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.selectEmployee,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Employee is required'
                      : null,
                ),
                AppFormTextField(
                  controller: controller.employeeCodeController,
                  labelText: 'Employee Code',
                  readOnly: true,
                ),
                AppFormTextField(
                  controller: controller.usernameController,
                  labelText: 'Username',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Username is required'
                      : null,
                ),
                AppFormTextField(
                  controller: controller.passwordController,
                  obscureText: true,
                  labelText: controller.isNewUser
                      ? 'Password'
                      : 'Password (leave blank to keep)',
                  validator: (value) {
                    if (controller.isNewUser &&
                        (value == null || value.trim().length < 6)) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                AppFormTextField(
                  controller: controller.firstNameController,
                  labelText: 'First Name',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'First name is required'
                      : null,
                ),
                AppFormTextField(
                  controller: controller.lastNameController,
                  labelText: 'Last Name',
                ),
                AppFormTextField(
                  controller: controller.displayNameController,
                  labelText: 'Display Name',
                ),
                AppFormTextField(
                  controller: controller.emailController,
                  labelText: 'Email',
                ),
                AppFormTextField(
                  controller: controller.mobileController,
                  labelText: 'Mobile',
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.gender,
                  labelText: 'Gender',
                  mappedItems: const [
                    AppDropdownItem(value: 'male', label: 'Male'),
                    AppDropdownItem(value: 'female', label: 'Female'),
                    AppDropdownItem(value: 'other', label: 'Other'),
                    AppDropdownItem(
                      value: 'prefer_not_to_say',
                      label: 'Prefer not to say',
                    ),
                  ],
                  onChanged: controller.setGender,
                ),
                AppFormTextField(
                  controller: controller.dobController,
                  labelText: 'Date of Birth',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                ),
                InlineFieldAction(
                  actionTooltip: 'Create role',
                  onAddNew: () => controller.openCreateRoleDialog(context),
                  field: AppDropdownField<int>(
                    initialValue: controller.selectedRoleId,
                    labelText: 'Primary Role',
                    items: [
                      ...controller.roles.map(
                        (role) => DropdownMenuItem<int>(
                          value: role.id,
                          child: Text(role.name ?? role.code ?? 'Role'),
                        ),
                      ),
                      const DropdownMenuItem<int>(
                        value: -1,
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 8),
                            Text('Create New Role'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == -1) {
                        controller.openCreateRoleDialog(context);
                        return;
                      }
                      controller.setSelectedRoleId(value);
                    },
                  ),
                ),
                UploadPathField(
                  controller: controller.profilePhotoController,
                  labelText: 'Profile Photo Path',
                  isUploading: controller.uploadingPhoto,
                  onUpload: () => controller.uploadUserImage(context),
                  previewUrl: AppConfig.resolvePublicFileUrl(
                    controller.profilePhotoController.text,
                  ),
                  previewIcon: Icons.person_outline,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsFormWrap(
              children: [
                AppSwitchTile(
                  label: 'System User',
                  value: controller.isSystemUser,
                  onChanged: controller.setIsSystemUser,
                ),
                AppSwitchTile(
                  label: 'Must Change Password',
                  value: controller.mustChangePassword,
                  onChanged: controller.setMustChangePassword,
                ),
                AppSwitchTile(
                  label: controller.selectedRoleImpliesSuperAdmin()
                      ? 'Super Admin via Role'
                      : 'Super Admin Override',
                  value: controller.isSuperAdmin,
                  onChanged: controller.selectedRoleImpliesSuperAdmin()
                      ? null
                      : controller.setIsSuperAdmin,
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.status,
                  labelText: 'Status',
                  mappedItems: const [
                    AppDropdownItem(value: 'active', label: 'Active'),
                    AppDropdownItem(value: 'inactive', label: 'Inactive'),
                    AppDropdownItem(value: 'suspended', label: 'Suspended'),
                    AppDropdownItem(value: 'blocked', label: 'Blocked'),
                  ],
                  onChanged: controller.setStatus,
                ),
              ],
            ),
            if (controller.selectedRoleImpliesSuperAdmin()) ...[
              const SizedBox(height: 8),
              Text(
                'The selected role already grants super admin access.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).extension<AppThemeExtension>()!.mutedText,
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppFormTextField(
              controller: controller.remarksController,
              maxLines: 3,
              labelText: 'Remarks',
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
                  label: controller.savingProfile ? 'Saving...' : 'Save User',
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
    UserManagementController controller,
  ) {
    if (controller.isNewUser) {
      return _emptyStateCard(
        context,
        icon: Icons.verified_user_outlined,
        title: 'Permissions Will Appear After Save',
        message:
            'Create the user first, then we can show role-based access and user-specific permission overrides here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Row(
            children: [
              const Spacer(),
              AppActionButton(
                onPressed: controller.savingPermissions
                    ? null
                    : controller.savePermissions,
                icon: Icons.verified_user_outlined,
                label: controller.savingPermissions
                    ? 'Saving...'
                    : 'Save Permissions',
                busy: controller.savingPermissions,
              ),
            ],
          ),
        ),
        if (controller.formError != null &&
            controller.formError!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
            child: Text(
              controller.formError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppUiConstants.cardPadding),
          children: controller.effectivePermissions.map((permission) {
            final permissionKey =
                '${permission.permissionId ?? permission.code ?? permission.name ?? 'permission'}';
            final index = controller.effectivePermissions.indexOf(permission);
            final effective = controller.effectivePermissions.firstWhere(
              (item) => item.permissionId == permission.permissionId,
              orElse: () => permission,
            );

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              color: Theme.of(context).extension<AppThemeExtension>()!.subtleFill,
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
                  effective,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((permission.description ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(permission.description!),
                          ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _permCheck(
                              'View',
                              effective.allowView ?? false,
                              (value) =>
                                  controller.togglePermission(index, 'view', value),
                            ),
                            _permCheck(
                              'Create',
                              effective.allowCreate ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'create',
                                value,
                              ),
                            ),
                            _permCheck(
                              'Update',
                              effective.allowUpdate ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'update',
                                value,
                              ),
                            ),
                            _permCheck(
                              'Delete',
                              effective.allowDelete ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'delete',
                                value,
                              ),
                            ),
                            _permCheck(
                              'Approve',
                              effective.allowApprove ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'approve',
                                value,
                              ),
                            ),
                            _permCheck(
                              'Print',
                              effective.allowPrint ?? false,
                              (value) => controller.togglePermission(
                                index,
                                'print',
                                value,
                              ),
                            ),
                            _permCheck(
                              'Export',
                              effective.allowExport ?? false,
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

  Widget _buildAuditTab(
    BuildContext context,
    UserManagementController controller,
  ) {
    if (controller.isNewUser) {
      return _emptyStateCard(
        context,
        icon: Icons.history_outlined,
        title: 'Audit History Will Appear After Save',
        message:
            'Once the user record exists, audit events like updates, status changes, and permission changes will show here.',
      );
    }

    return _historyList<AuditLogModel>(
      context,
      items: controller.auditLogs,
      titleBuilder: (log) => log.description ?? log.action ?? 'Audit entry',
      subtitleBuilder: (log) =>
          '${log.module ?? '-'} • ${log.createdAt ?? ''}'.trim(),
      trailingBuilder: (log) => log.action ?? '',
    );
  }

  Widget _buildLoginHistoryTab(
    BuildContext context,
    UserManagementController controller,
  ) {
    if (controller.isNewUser) {
      return _emptyStateCard(
        context,
        icon: Icons.login_outlined,
        title: 'Login History Will Appear After Save',
        message:
            'After the user is created and starts signing in, the login history timeline will be available here.',
      );
    }

    return _historyList<LoginHistoryModel>(
      context,
      items: controller.loginHistory,
      titleBuilder: (entry) => entry.status ?? 'login',
      subtitleBuilder: (entry) =>
          '${entry.loginAt ?? ''} • ${entry.ipAddress ?? ''}'.trim(),
      trailingBuilder: (entry) => entry.remarks ?? '',
    );
  }

  Widget _historyList<T>(
    BuildContext context, {
    required List<T> items,
    required String Function(T item) titleBuilder,
    required String Function(T item) subtitleBuilder,
    required String Function(T item) trailingBuilder,
  }) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    if (items.isEmpty) {
      return _emptyStateCard(
        context,
        icon: Icons.inbox_outlined,
        title: 'No Records Found',
        message: 'There are no entries to show for this section yet.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppUiConstants.cardPadding),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appTheme.subtleFill,
            borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.history),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleBuilder(item),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleBuilder(item),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                trailingBuilder(item),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: appTheme.mutedText),
              ),
            ],
          ),
        );
      },
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
    UserManagementController controller,
    String permissionKey,
    UserPermissionModel permission,
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

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
