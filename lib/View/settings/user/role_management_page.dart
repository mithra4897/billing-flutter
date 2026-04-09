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
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _pageScrollController = ScrollController();

  late final TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _initialLoading = true;
  bool _loadingRoleDetails = false;
  bool _loadingPermissions = false;
  bool _savingProfile = false;
  bool _savingPermissions = false;
  bool _codeTouched = false;
  String? _pageError;
  String? _formError;
  bool _isActive = true;
  bool _isSystemRole = false;

  List<RoleModel> _roles = const <RoleModel>[];
  List<RoleModel> _filteredRoles = const <RoleModel>[];
  List<RolePermissionModel> _rolePermissions = const <RolePermissionModel>[];
  Set<String> _expandedPermissionModules = <String>{};

  int? _selectedRoleId;
  int? _permissionsLoadedForRoleId;
  int _roleLoadToken = 0;

  bool get _isNewRole => _selectedRoleId == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _searchController.addListener(_applyRoleFilter);
    _nameController.addListener(_syncCodeFromName);
    _codeController.addListener(_handleCodeEdited);
    _loadInitial();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _pageScrollController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _pageError = null;
    });

    try {
      final rolesResponse = await _authService.roles(
        filters: const {'per_page': 100},
      );
      _roles = rolesResponse.data ?? const <RoleModel>[];
      _filteredRoles = _roles;

      if (widget.initialRoleId != null) {
        await _loadRole(widget.initialRoleId!);
      } else {
        _resetForm();
      }

      if (mounted) {
        setState(() {
          _initialLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _pageError = error.toString();
          _initialLoading = false;
        });
      }
    }
  }

  void _applyRoleFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredRoles = _roles;
      });
      return;
    }

    setState(() {
      _filteredRoles = _roles
          .where((role) {
            final label = [
              role.code,
              role.name,
              role.description,
            ].whereType<String>().join(' ').toLowerCase();
            return label.contains(query);
          })
          .toList(growable: false);
    });
  }

  Future<void> _loadRole(int roleId, {bool resetTab = false}) async {
    final token = ++_roleLoadToken;

    if (mounted) {
      setState(() {
        _selectedRoleId = roleId;
        _loadingRoleDetails = true;
        _formError = null;
        _rolePermissions = const <RolePermissionModel>[];
        _permissionsLoadedForRoleId = null;
        if (resetTab) {
          _tabController.index = 0;
        }
      });
    }

    try {
      final roleResponse = await _authService.role(roleId);

      if (!mounted || token != _roleLoadToken) {
        return;
      }

      final role = roleResponse.data;
      if (role == null) {
        setState(() {
          _formError = 'Role not found.';
          _loadingRoleDetails = false;
        });
        return;
      }

      _codeController.text = role.code ?? '';
      _nameController.text = role.name ?? '';
      _descriptionController.text = role.description ?? '';

      setState(() {
        _selectedRoleId = role.id;
        _isActive = role.isActive ?? true;
        _isSystemRole = role.isSystemRole ?? false;
        _codeTouched = (role.code ?? '').trim().isNotEmpty;
        _loadingRoleDetails = false;
      });

      if (_tabController.index == 1 && role.id != null) {
        await _loadRolePermissions(role.id!, force: true);
      }
    } catch (error) {
      if (!mounted || token != _roleLoadToken) {
        return;
      }
      setState(() {
        _formError = error.toString();
        _loadingRoleDetails = false;
      });
    }
  }

  Future<void> _loadRolePermissions(int roleId, {bool force = false}) async {
    if (!force &&
        !_loadingPermissions &&
        _permissionsLoadedForRoleId == roleId &&
        _rolePermissions.isNotEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _loadingPermissions = true;
        _formError = null;
      });
    }

    try {
      final response = await _authService.rolePermissions(roleId);
      if (!mounted || _selectedRoleId != roleId) {
        return;
      }

      setState(() {
        _rolePermissions =
            response.data?.permissions ?? const <RolePermissionModel>[];
        _expandedPermissionModules = <String>{};
        _permissionsLoadedForRoleId = roleId;
        _loadingPermissions = false;
      });
    } catch (error) {
      if (!mounted || _selectedRoleId != roleId) {
        return;
      }

      setState(() {
        _formError = error.toString();
        _loadingPermissions = false;
      });
    }
  }

  void _resetForm() {
    _selectedRoleId = null;
    _codeController.clear();
    _nameController.clear();
    _descriptionController.clear();
    _isActive = true;
    _isSystemRole = false;
    _codeTouched = false;
    _rolePermissions = const <RolePermissionModel>[];
    _expandedPermissionModules = <String>{};
    _permissionsLoadedForRoleId = null;
    _formError = null;
    _tabController.index = 0;
    _loadingRoleDetails = false;
    _loadingPermissions = false;
    setState(() {});
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _savingProfile = true;
      _formError = null;
    });

    try {
      final model = RoleModel(
        id: _selectedRoleId,
        code: _codeController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isActive: _isActive,
        isSystemRole: _isSystemRole,
      );

      final response = _isNewRole
          ? await _authService.createRole(model)
          : await _authService.updateRole(_selectedRoleId!, model);

      final saved = response.data;
      if (saved == null || saved.id == null) {
        setState(() {
          _formError = response.message;
        });
        return;
      }

      await _loadInitial();
      await _loadRole(saved.id!);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (error) {
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingProfile = false;
        });
      }
    }
  }

  Future<void> _savePermissions() async {
    if (_selectedRoleId == null) {
      return;
    }

    setState(() {
      _savingPermissions = true;
      _formError = null;
    });

    try {
      final response = await _authService.syncRolePermissions(
        _selectedRoleId!,
        RolePermissionSyncRequestModel(permissions: _rolePermissions),
      );

      await _loadRolePermissions(_selectedRoleId!, force: true);
      await AppSessionService.instance.refreshUserAccess();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (error) {
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingPermissions = false;
        });
      }
    }
  }

  void _togglePermission(int index, String field, bool enabled) {
    final current = _rolePermissions[index];
    setState(() {
      _rolePermissions = List<RolePermissionModel>.from(_rolePermissions)
        ..[index] = current.copyWith(
          allowView: field == 'view' ? enabled : current.allowView,
          allowCreate: field == 'create' ? enabled : current.allowCreate,
          allowUpdate: field == 'update' ? enabled : current.allowUpdate,
          allowDelete: field == 'delete' ? enabled : current.allowDelete,
          allowApprove: field == 'approve' ? enabled : current.allowApprove,
          allowPrint: field == 'print' ? enabled : current.allowPrint,
          allowExport: field == 'export' ? enabled : current.allowExport,
        );
    });
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    if (_tabController.index == 1 && _selectedRoleId != null) {
      _loadRolePermissions(_selectedRoleId!);
    }

    setState(() {});
  }

  void _syncCodeFromName() {
    if (_codeTouched) {
      return;
    }

    final generated = _generateCode(_nameController.text);
    if (_codeController.text != generated) {
      _codeController.value = _codeController.value.copyWith(
        text: generated,
        selection: TextSelection.collapsed(offset: generated.length),
      );
    }
  }

  void _handleCodeEdited() {
    final generated = _generateCode(_nameController.text);
    final current = _codeController.text.trim();
    if (current.isEmpty || current == generated) {
      _codeTouched = false;
      return;
    }

    _codeTouched = true;
  }

  String _generateCode(String value) {
    final cleaned = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.length > 50 ? cleaned.substring(0, 50) : cleaned;
  }

  Future<void> _logout(BuildContext context) async {
    await AppSessionService.instance.clearSession();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _initialLoading
        ? const AppLoadingView(message: 'Loading roles...')
        : _pageError != null
        ? Center(child: Text(_pageError!))
        : LayoutBuilder(
            builder: (context, constraints) {
              final showSideList = constraints.maxWidth >= 1100;

              return SingleChildScrollView(
                controller: _pageScrollController,
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
                            child: _buildRoleList(context),
                          ),
                          const SizedBox(width: AppUiConstants.spacingXl),
                          Expanded(child: _buildEditor(context)),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRoleList(context),
                          const SizedBox(height: AppUiConstants.spacingLg),
                          _buildEditor(context),
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
            onPressed: _resetForm,
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
          scrollController: _pageScrollController,
          actions: [
            AdaptiveShellActionButton(
              onPressed: _resetForm,
              icon: Icons.add,
              label: 'New Role',
            ),
          ],
          onLogout: () => _logout(context),
          child: content,
        );
      },
    );
  }

  Widget _buildRoleList(BuildContext context) {
    return SettingsListCard<RoleModel>(
      searchController: _searchController,
      searchHint: 'Search roles',
      items: _filteredRoles,
      selectedItem: _filteredRoles.cast<RoleModel?>().firstWhere(
        (role) => role?.id == _selectedRoleId,
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
            _loadRole(role.id!, resetTab: true);
          }
        },
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final showDetailTabs = !_isNewRole && _selectedRoleId != null;

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const SizedBox(height: AppUiConstants.spacingSm),
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return Column(
                children: [
                  if (showDetailTabs)
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Profile'),
                        Tab(text: 'Permissions'),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppUiConstants.spacing2xl,
                    ),
                    child: showDetailTabs
                        ? [
                            _buildProfileTab(context),
                            _buildPermissionsTab(context),
                          ][_tabController.index]
                        : _buildProfileTab(context),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    if (_loadingRoleDetails) {
      return const Padding(
        padding: EdgeInsets.all(AppUiConstants.cardPadding),
        child: AppLoadingView(message: 'Loading role details...'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppUiConstants.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  controller: _nameController,
                  labelText: 'Role Name',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Role name is required'
                      : null,
                ),
                AppFormTextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  labelText: 'Role Code',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Role code is required'
                      : null,
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: _isActive ? 'active' : 'inactive',
                  labelText: 'Status',
                  mappedItems: const [
                    AppDropdownItem(value: 'active', label: 'Active'),
                    AppDropdownItem(value: 'inactive', label: 'Inactive'),
                  ],
                  onChanged: (value) => setState(() {
                    _isActive = value == 'active';
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppFormTextField(
              controller: _descriptionController,
              maxLines: 3,
              labelText: 'Description',
            ),
            const SizedBox(height: 16),
            if (_isSystemRole)
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
                  onPressed: _savingProfile ? null : _saveProfile,
                  icon: Icons.save_outlined,
                  label: _savingProfile ? 'Saving...' : 'Save Role',
                  busy: _savingProfile,
                ),
              ],
            ),
            if (_formError != null && _formError!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                _formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsTab(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    if (_isNewRole) {
      return _emptyStateCard(
        context,
        icon: Icons.verified_user_outlined,
        title: 'Permissions Will Appear After Save',
        message:
            'Create the role first, then we can configure its default access rights here.',
      );
    }

    if (_loadingPermissions) {
      return const Padding(
        padding: EdgeInsets.all(AppUiConstants.cardPadding),
        child: AppLoadingView(message: 'Loading permissions...'),
      );
    }

    if (_rolePermissions.isEmpty) {
      return _emptyStateCard(
        context,
        icon: Icons.lock_outline,
        title: 'No Permissions Loaded',
        message:
            'This role does not have a permission matrix loaded yet. Try refreshing the role again.',
      );
    }

    final grouped = <String, List<RolePermissionModel>>{};
    for (final permission in _rolePermissions) {
      final key = permission.module ?? 'general';
      grouped.putIfAbsent(key, () => <RolePermissionModel>[]).add(permission);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Row(
            children: [
              const Spacer(),
              FilledButton.icon(
                onPressed: _savingPermissions ? null : _savePermissions,
                icon: _savingPermissions
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: Text(
                  _savingPermissions ? 'Saving...' : 'Save Permissions',
                ),
              ),
            ],
          ),
        ),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppUiConstants.cardPadding),
          children: _rolePermissions
              .map((permission) {
                final permissionKey =
                    '${permission.permissionId ?? permission.code ?? permission.name ?? 'permission'}';
                final index = _rolePermissions.indexOf(permission);
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
                    onExpansionChanged: (expanded) {
                      setState(() {
                        if (expanded) {
                          _expandedPermissionModules.add(permissionKey);
                        } else {
                          _expandedPermissionModules.remove(permissionKey);
                        }
                      });
                    },
                    title: Text(
                      permission.name ?? permission.code ?? 'Permission',
                    ),
                    trailing: _permissionGroupTrailing(
                      context,
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
                                      _togglePermission(index, 'view', value),
                                ),
                                _permCheck(
                                  'Create',
                                  permission.allowCreate ?? false,
                                  (value) =>
                                      _togglePermission(index, 'create', value),
                                ),
                                _permCheck(
                                  'Update',
                                  permission.allowUpdate ?? false,
                                  (value) =>
                                      _togglePermission(index, 'update', value),
                                ),
                                _permCheck(
                                  'Delete',
                                  permission.allowDelete ?? false,
                                  (value) =>
                                      _togglePermission(index, 'delete', value),
                                ),
                                _permCheck(
                                  'Approve',
                                  permission.allowApprove ?? false,
                                  (value) => _togglePermission(
                                    index,
                                    'approve',
                                    value,
                                  ),
                                ),
                                _permCheck(
                                  'Print',
                                  permission.allowPrint ?? false,
                                  (value) =>
                                      _togglePermission(index, 'print', value),
                                ),
                                _permCheck(
                                  'Export',
                                  permission.allowExport ?? false,
                                  (value) =>
                                      _togglePermission(index, 'export', value),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
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
    String permissionKey,
    RolePermissionModel permission,
  ) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final isExpanded = _expandedPermissionModules.contains(permissionKey);
    final summary = _permissionRightsSummary(permission);

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

  String _permissionRightsSummary(RolePermissionModel permission) {
    final letters = <String>[];
    if (permission.allowView == true) letters.add('V');
    if (permission.allowCreate == true) letters.add('C');
    if (permission.allowUpdate == true) letters.add('U');
    if (permission.allowDelete == true) letters.add('D');
    if (permission.allowApprove == true) letters.add('A');
    if (permission.allowPrint == true) letters.add('P');
    if (permission.allowExport == true) letters.add('E');
    return letters.join(' ');
  }
}
