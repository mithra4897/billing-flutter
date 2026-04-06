import 'package:flutter/material.dart';

import '../../../app/constants/app_ui_constants.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../components/adaptive_shell.dart';
import '../../../components/app_loading_view.dart';
import '../../../core/storage/session_storage.dart';
import '../../../model/admin/role_model.dart';
import '../../../model/app/public_branding_model.dart';
import '../../../model/auth/role_permission_model.dart';
import '../../../model/auth/role_permission_summary_model.dart';
import '../../../model/auth/role_permission_sync_request_model.dart';
import '../../../service/app/app_session_service.dart';
import '../../../service/auth/auth_service.dart';

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key, this.initialRoleId});

  final int? initialRoleId;

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

  int? _selectedRoleId;

  bool get _isNewRole => _selectedRoleId == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_applyRoleFilter);
    _nameController.addListener(_syncCodeFromName);
    _codeController.addListener(_handleCodeEdited);
    _loadInitial();
  }

  @override
  void dispose() {
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

  Future<void> _loadRole(int roleId) async {
    final roleResponse = await _authService.role(roleId);
    final permissionResponse = await _authService.rolePermissions(roleId);
    final role = roleResponse.data;
    if (role == null) {
      return;
    }

    _selectedRoleId = role.id;
    _codeController.text = role.code ?? '';
    _nameController.text = role.name ?? '';
    _descriptionController.text = role.description ?? '';
    _isActive = role.isActive ?? true;
    _isSystemRole = role.isSystemRole ?? false;
    _codeTouched = (role.code ?? '').trim().isNotEmpty;
    _applyPermissionSummary(permissionResponse.data);

    if (mounted) {
      setState(() {});
    }
  }

  void _applyPermissionSummary(RolePermissionSummaryModel? summary) {
    _rolePermissions = summary?.permissions ?? const <RolePermissionModel>[];
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
    _formError = null;
    _tabController.index = 0;
    setState(() {});
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSystemRole && !_isNewRole) {
      setState(() {
        _formError = 'System role cannot be modified.';
      });
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
    if (_selectedRoleId == null || _isSystemRole) {
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

      final refreshed = await _authService.rolePermissions(_selectedRoleId!);
      _applyPermissionSummary(refreshed.data);

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
          child: _initialLoading
              ? const AppLoadingView(message: 'Loading roles...')
              : _pageError != null
              ? Center(child: Text(_pageError!))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final showSideList = constraints.maxWidth >= 1100;

                    return SingleChildScrollView(
                      controller: _pageScrollController,
                      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
                      child: showSideList
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 320,
                                  child: _buildRoleList(context),
                                ),
                                const SizedBox(width: 24),
                                Expanded(child: _buildEditor(context)),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildRoleList(context),
                                const SizedBox(height: 20),
                                _buildEditor(context),
                              ],
                            ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildRoleList(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search roles',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredRoles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final role = _filteredRoles[index];
                final selected = role.id == _selectedRoleId;

                return InkWell(
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.buttonRadius,
                  ),
                  onTap: () {
                    if (role.id != null) {
                      _loadRole(role.id!);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12)
                          : appTheme.subtleFill,
                      borderRadius: BorderRadius.circular(
                        AppUiConstants.buttonRadius,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.name ?? role.code ?? 'Role',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role.code ?? '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: appTheme.mutedText),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          role.isSystemRole == true
                              ? 'System Role'
                              : (role.isActive == true ? 'Active' : 'Inactive'),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: appTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final showDetailTabs = !_isNewRole && _selectedRoleId != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isNewRole
                        ? 'Create the role details first. After saving, the permission tab becomes active.'
                        : 'Role permissions define the default access baseline for users assigned to this role.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
                  ),
                ),
              ],
            ),
          ),
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
            padding: const EdgeInsets.only(bottom: 28),
            child: showDetailTabs
                ? [
                    _buildProfileTab(context),
                    _buildPermissionsTab(context),
                  ][_tabController.index]
                : _buildProfileTab(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppUiConstants.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _inputBox(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Role Name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Role name is required'
                        : null,
                    enabled: !_isSystemRole,
                  ),
                ),
                _inputBox(
                  child: TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Role Code'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Role code is required'
                        : null,
                    enabled: !_isSystemRole,
                  ),
                ),
                _inputBox(
                  width: 260,
                  child: DropdownButtonFormField<String>(
                    initialValue: _isActive ? 'active' : 'inactive',
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: _isSystemRole
                        ? null
                        : (value) => setState(() {
                            _isActive = value == 'active';
                          }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              enabled: !_isSystemRole,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            if (_isSystemRole)
              Text(
                'This is a system role. You can review its setup, but changes are restricted.',
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
                FilledButton.icon(
                  onPressed: (_savingProfile || _isSystemRole)
                      ? null
                      : _saveProfile,
                  icon: _savingProfile
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_savingProfile ? 'Saving...' : 'Save Role'),
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
    if (_isNewRole) {
      return _emptyStateCard(
        context,
        icon: Icons.verified_user_outlined,
        title: 'Permissions Will Appear After Save',
        message:
            'Create the role first, then we can configure its default access rights here.',
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
              Expanded(
                child: Text(
                  _isSystemRole
                      ? 'System role permissions are view-only.'
                      : 'These rights become the default access baseline for every user assigned to this role.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: (_savingPermissions || _isSystemRole)
                    ? null
                    : _savePermissions,
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
          children: grouped.entries
              .map((entry) {
                return Card(
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(entry.key.toUpperCase()),
                    children: entry.value
                        .map((permission) {
                          final index = _rolePermissions.indexOf(permission);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  permission.name ??
                                      permission.code ??
                                      'Permission',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if ((permission.description ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(permission.description!),
                                  ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    _permCheck(
                                      'View',
                                      permission.allowView ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'view',
                                        value,
                                      ),
                                    ),
                                    _permCheck(
                                      'Create',
                                      permission.allowCreate ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'create',
                                        value,
                                      ),
                                    ),
                                    _permCheck(
                                      'Update',
                                      permission.allowUpdate ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'update',
                                        value,
                                      ),
                                    ),
                                    _permCheck(
                                      'Delete',
                                      permission.allowDelete ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'delete',
                                        value,
                                      ),
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
                                      (value) => _togglePermission(
                                        index,
                                        'print',
                                        value,
                                      ),
                                    ),
                                    _permCheck(
                                      'Export',
                                      permission.allowExport ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'export',
                                        value,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Current rights: ${_rightsLabel(permission)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _inputBox({required Widget child, double width = 260}) {
    return SizedBox(width: width, child: child);
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
      onSelected: _isSystemRole ? null : onChanged,
    );
  }

  String _rightsLabel(RolePermissionModel permission) {
    final labels = <String>[];
    if (permission.allowView == true) labels.add('view');
    if (permission.allowCreate == true) labels.add('create');
    if (permission.allowUpdate == true) labels.add('update');
    if (permission.allowDelete == true) labels.add('delete');
    if (permission.allowApprove == true) labels.add('approve');
    if (permission.allowPrint == true) labels.add('print');
    if (permission.allowExport == true) labels.add('export');
    return labels.isEmpty ? 'none' : labels.join(', ');
  }
}
