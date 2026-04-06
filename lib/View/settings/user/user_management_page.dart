import 'package:flutter/material.dart';

import '../../../app/constants/app_config.dart';
import '../../../app/constants/app_ui_constants.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../components/adaptive_shell.dart';
import '../../../components/app_loading_view.dart';
import '../../../components/date_input_formatter.dart';
import '../../../components/inline_field_action.dart';
import '../../../components/upload_path_field.dart';
import '../../../core/storage/session_storage.dart';
import '../../../model/admin/permission_model.dart';
import '../../../model/admin/role_model.dart';
import '../../../model/admin/user_model.dart';
import '../../../model/app/public_branding_model.dart';
import '../../../model/auth/audit_log_model.dart';
import '../../../model/auth/login_history_model.dart';
import '../../../model/auth/user_permission_model.dart';
import '../../../model/auth/user_permission_summary_model.dart';
import '../../../service/app/app_session_service.dart';
import '../../../service/auth/auth_service.dart';
import '../../../service/media/media_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key, this.initialUserId});

  final int? initialUserId;

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final MediaService _mediaService = MediaService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _pageScrollController = ScrollController();

  late final TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _employeeCodeController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _profilePhotoController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _savingProfile = false;
  bool _savingPermissions = false;
  bool _uploadingPhoto = false;
  String? _pageError;
  String? _formError;
  String? _gender;
  int? _selectedRoleId;
  bool _mustChangePassword = true;
  bool _isSystemUser = true;
  bool _isSuperAdmin = false;
  String _status = 'active';
  bool _displayNameTouched = false;

  List<UserModel> _users = const <UserModel>[];
  List<UserModel> _filteredUsers = const <UserModel>[];
  List<RoleModel> _roles = const <RoleModel>[];
  List<UserPermissionModel> _rolePermissions = const <UserPermissionModel>[];
  List<PermissionModel> _permissions = const <PermissionModel>[];
  List<UserPermissionModel> _effectivePermissions =
      const <UserPermissionModel>[];
  List<AuditLogModel> _auditLogs = const <AuditLogModel>[];
  List<LoginHistoryModel> _loginHistory = const <LoginHistoryModel>[];

  int? _selectedUserId;

  bool get _isNewUser => _selectedUserId == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _searchController.addListener(_applyUserFilter);
    _firstNameController.addListener(_syncDisplayNameFromNameParts);
    _lastNameController.addListener(_syncDisplayNameFromNameParts);
    _displayNameController.addListener(_handleDisplayNameEdited);
    _loadInitial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageScrollController.dispose();
    _searchController.dispose();
    _employeeCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _profilePhotoController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _pageError = null;
    });

    try {
      final usersResponse = await _authService.users(
        filters: const {'per_page': 100},
      );
      final rolesResponse = await _authService.roles(
        filters: const {'per_page': 100},
      );
      final permissionsResponse = await _authService.permissions(
        filters: const {'per_page': 500},
      );

      _users = usersResponse.data ?? const <UserModel>[];
      _filteredUsers = _users;
      _roles = rolesResponse.data ?? const <RoleModel>[];
      _permissions = permissionsResponse.data ?? const <PermissionModel>[];

      if (widget.initialUserId != null) {
        await _loadUser(widget.initialUserId!);
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

  void _applyUserFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    setState(() {
      _filteredUsers = _users
          .where((user) {
            final label = [
              user.username,
              user.firstName,
              user.lastName,
              user.displayName,
              user.email,
              user.mobile,
            ].whereType<String>().join(' ').toLowerCase();
            return label.contains(query);
          })
          .toList(growable: false);
    });
  }

  Future<void> _loadUser(int userId) async {
    final response = await _authService.user(userId);
    final user = response.data;
    if (user == null) {
      return;
    }

    _selectedUserId = user.id;
    _employeeCodeController.text = user.employeeCode ?? '';
    _usernameController.text = user.username ?? '';
    _passwordController.clear();
    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _displayNameController.text = user.displayName ?? '';
    _emailController.text = user.email ?? '';
    _mobileController.text = user.mobile ?? '';
    _dobController.text = _normalizeDate(user.dateOfBirth);
    _profilePhotoController.text = user.profilePhotoPath ?? '';
    _remarksController.text = user.remarks ?? '';
    _gender = user.gender;
    _mustChangePassword = user.mustChangePassword ?? true;
    _isSystemUser = user.isSystemUser ?? true;
    _isSuperAdmin = user.isSuperAdmin ?? false;
    _status = user.status ?? 'active';
    _displayNameTouched = (user.displayName ?? '').trim().isNotEmpty;
    final primaryRole = user.userRoles.where(
      (item) => item.isPrimaryRole == true,
    );
    _selectedRoleId = primaryRole.isNotEmpty
        ? primaryRole.first.roleId
        : user.userRoles.isNotEmpty
        ? user.userRoles.first.roleId
        : user.roleIds.firstOrNull;

    await _loadTabs(userId);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTabs(int userId) async {
    final permissionSummary = await _authService.userPermissions(userId);
    final auditResponse = await _authService.userAuditLogs(
      userId,
      filters: const {'per_page': 25},
    );
    final loginResponse = await _authService.userLoginHistory(
      userId,
      filters: const {'per_page': 25},
    );

    _applyPermissionSummary(permissionSummary.data);
    _auditLogs = auditResponse.data ?? const <AuditLogModel>[];
    _loginHistory = loginResponse.data ?? const <LoginHistoryModel>[];
  }

  void _applyPermissionSummary(UserPermissionSummaryModel? summary) {
    _rolePermissions = _mergePermissionSet(
      summary?.rolePermissions ?? const [],
    );
    _effectivePermissions = _mergePermissionSet(
      summary?.effectivePermissions ?? const [],
    );
  }

  void _resetForm() {
    _selectedUserId = null;
    _employeeCodeController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _displayNameController.clear();
    _emailController.clear();
    _mobileController.clear();
    _dobController.clear();
    _profilePhotoController.clear();
    _remarksController.clear();
    _gender = null;
    _selectedRoleId = null;
    _mustChangePassword = true;
    _isSystemUser = true;
    _isSuperAdmin = false;
    _status = 'active';
    _displayNameTouched = false;
    _rolePermissions = _mergePermissionSet(const []);
    _effectivePermissions = _mergePermissionSet(const []);
    _auditLogs = const [];
    _loginHistory = const [];
    _formError = null;
    _tabController.index = 0;
    setState(() {});
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoleId == null) {
      setState(() {
        _formError = 'Please select a role before saving the user.';
      });
      return;
    }

    setState(() {
      _savingProfile = true;
      _formError = null;
    });

    try {
      final model = UserModel(
        id: _selectedUserId,
        employeeCode: _employeeCodeController.text.trim().isEmpty
            ? null
            : _employeeCodeController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim().isEmpty
            ? null
            : _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        mobile: _mobileController.text.trim().isEmpty
            ? null
            : _mobileController.text.trim(),
        gender: _gender,
        dateOfBirth: _dobController.text.trim().isEmpty
            ? null
            : _normalizeDate(_dobController.text.trim()),
        profilePhotoPath: _profilePhotoController.text.trim().isEmpty
            ? null
            : _profilePhotoController.text.trim(),
        isSuperAdmin: _isSuperAdmin,
        isSystemUser: _isSystemUser,
        mustChangePassword: _mustChangePassword,
        status: _status,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        roleIds: <int>[_selectedRoleId!],
      );

      final response = _isNewUser
          ? await _authService.createUser(model)
          : await _authService.updateUser(_selectedUserId!, model);

      final saved = response.data;
      if (saved == null || saved.id == null) {
        setState(() {
          _formError = response.message;
        });
        return;
      }

      await _loadInitial();
      await _loadUser(saved.id!);
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
    if (_selectedUserId == null) {
      return;
    }

    setState(() {
      _savingPermissions = true;
    });

    try {
      final toSave = _effectivePermissions
          .where((permission) => _differsFromRole(permission))
          .toList(growable: false);

      final response = await _authService.syncUserExtraPermissions(
        _selectedUserId!,
        toSave,
      );
      _applyPermissionSummary(response.data);

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

  Future<void> _uploadUserImage() async {
    final pathController = TextEditingController();

    final selectedPath = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Upload User Image'),
          content: TextField(
            controller: pathController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Local File Path',
              hintText: '/Users/name/Pictures/user.png',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(pathController.text.trim()),
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );

    if (!mounted || selectedPath == null || selectedPath.isEmpty) {
      return;
    }

    setState(() {
      _uploadingPhoto = true;
      _formError = null;
    });

    try {
      final response = await _mediaService.uploadFile(
        filePath: selectedPath,
        module: 'auth',
        documentType: 'users',
        documentId: _selectedUserId,
        purpose: 'profile_photo',
        folder: 'users/profile',
        isPublic: true,
      );

      final uploaded = response.data;
      if (uploaded == null) {
        setState(() {
          _formError = response.message;
        });
        return;
      }

      _profilePhotoController.text = uploaded.filePath;
      setState(() {});
    } catch (error) {
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  void _togglePermission(int index, String field, bool enabled) {
    final current = _effectivePermissions[index];
    setState(() {
      _effectivePermissions =
          List<UserPermissionModel>.from(_effectivePermissions)
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

  void _handleDisplayNameEdited() {
    final generated = _generatedDisplayName;
    final current = _displayNameController.text.trim();
    if (current.isEmpty || current == generated) {
      _displayNameTouched = false;
      return;
    }

    _displayNameTouched = true;
  }

  void _syncDisplayNameFromNameParts() {
    if (_displayNameTouched) {
      return;
    }

    final generated = _generatedDisplayName;
    if (_displayNameController.text != generated) {
      _displayNameController.value = _displayNameController.value.copyWith(
        text: generated,
        selection: TextSelection.collapsed(offset: generated.length),
      );
    }
  }

  String get _generatedDisplayName {
    return [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
  }

  String _normalizeDate(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return '';
    }

    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  bool _selectedRoleImpliesSuperAdmin() {
    final role = _roles.where((item) => item.id == _selectedRoleId).firstOrNull;
    final tokens = '${role?.code ?? ''} ${role?.name ?? ''}'.toLowerCase();
    return tokens.contains('superadmin') || tokens.contains('super admin');
  }

  List<UserPermissionModel> _mergePermissionSet(
    List<UserPermissionModel> source,
  ) {
    final sourceMap = {for (final item in source) item.permissionId ?? 0: item};

    return _permissions
        .map((permission) {
          final item =
              sourceMap[permission.id] ??
              UserPermissionModel(
                permissionId: permission.id,
                module: permission.module,
                code: permission.code,
                name: permission.name,
                description: permission.description,
                allowView: false,
                allowCreate: false,
                allowUpdate: false,
                allowDelete: false,
                allowApprove: false,
                allowPrint: false,
                allowExport: false,
                isActive: true,
                permission: permission,
              );

          return item.copyWith(
            permissionId: permission.id,
            module: permission.module,
            code: permission.code,
            name: permission.name,
            description: permission.description,
            permission: permission,
          );
        })
        .toList(growable: false);
  }

  bool _differsFromRole(UserPermissionModel permission) {
    final baseline = _rolePermissions.firstWhere(
      (item) => item.permissionId == permission.permissionId,
      orElse: () => UserPermissionModel(permissionId: permission.permissionId),
    );

    for (final field in [
      permission.allowView != baseline.allowView,
      permission.allowCreate != baseline.allowCreate,
      permission.allowUpdate != baseline.allowUpdate,
      permission.allowDelete != baseline.allowDelete,
      permission.allowApprove != baseline.allowApprove,
      permission.allowPrint != baseline.allowPrint,
      permission.allowExport != baseline.allowExport,
    ]) {
      if (field) {
        return true;
      }
    }

    return false;
  }

  Future<void> _resetPermissionsForSelectedRole() async {
    if (_selectedRoleId == null) {
      setState(() {
        _rolePermissions = _mergePermissionSet(const []);
        _effectivePermissions = _mergePermissionSet(const []);
      });
      return;
    }

    final response = await _authService.rolePermissions(_selectedRoleId!);
    final permissionRows = (response.data?.permissions ?? const [])
        .map(
          (item) => UserPermissionModel(
            permissionId: item.permissionId,
            module: item.module,
            code: item.code,
            name: item.name,
            description: item.description,
            allowView: item.allowView,
            allowCreate: item.allowCreate,
            allowUpdate: item.allowUpdate,
            allowDelete: item.allowDelete,
            allowApprove: item.allowApprove,
            allowPrint: item.allowPrint,
            allowExport: item.allowExport,
            isActive: item.rolePermissionIsActive,
            permission: item.permission,
          ),
        )
        .toList(growable: false);

    if (!mounted) {
      return;
    }

    setState(() {
      _rolePermissions = _mergePermissionSet(permissionRows);
      _effectivePermissions = _mergePermissionSet(permissionRows);
    });
  }

  Future<void> _openCreateRoleDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    var saving = false;
    String? errorText;

    String generateCode(String value) {
      final cleaned = value
          .trim()
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      return cleaned.length > 50 ? cleaned.substring(0, 50) : cleaned;
    }

    nameController.addListener(() {
      if (codeController.text.trim().isEmpty) {
        codeController.text = generateCode(nameController.text);
      }
    });

    final createdRole = await showDialog<RoleModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final name = nameController.text.trim();
              final code = codeController.text.trim().isEmpty
                  ? generateCode(name)
                  : codeController.text.trim().toUpperCase();

              if (name.isEmpty || code.isEmpty) {
                setDialogState(() {
                  errorText = 'Role name and code are required.';
                });
                return;
              }

              setDialogState(() {
                saving = true;
                errorText = null;
              });

              try {
                final response = await _authService.createRole(
                  RoleModel(
                    code: code,
                    name: name,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    isActive: true,
                    isSystemRole: false,
                  ),
                );

                if (!dialogContext.mounted) {
                  return;
                }

                final role = response.data;
                if (role == null || role.id == null) {
                  setDialogState(() {
                    saving = false;
                    errorText = response.message;
                  });
                  return;
                }

                Navigator.of(dialogContext).pop(role);
              } catch (error) {
                setDialogState(() {
                  saving = false;
                  errorText = error.toString();
                });
              }
            }

            return AlertDialog(
              title: const Text('Create Role'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Role Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Role Code'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    if (errorText != null && errorText!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : submit,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(saving ? 'Creating...' : 'Create Role'),
                ),
              ],
            );
          },
        );
      },
    );

    if (createdRole == null || createdRole.id == null || !mounted) {
      return;
    }

    final refreshedRoles = await _authService.roles(
      filters: const {'per_page': 100},
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _roles = refreshedRoles.data ?? <RoleModel>[createdRole];
      _selectedRoleId = createdRole.id;
      if (_selectedRoleImpliesSuperAdmin()) {
        _isSuperAdmin = true;
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Role created successfully.')));
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
          title: 'Users',
          branding: branding,
          scrollController: _pageScrollController,
          actions: [
            AdaptiveShellActionButton(
              onPressed: _resetForm,
              icon: Icons.add,
              label: 'New User',
            ),
          ],
          onLogout: () => _logout(context),
          child: _initialLoading
              ? const AppLoadingView(message: 'Loading users...')
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
                                  child: _buildUserList(context),
                                ),
                                const SizedBox(width: 24),
                                Expanded(child: _buildEditor(context)),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildUserList(context),
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

  Widget _buildUserList(BuildContext context) {
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
                hintText: 'Search users',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredUsers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                final selected = user.id == _selectedUserId;

                return InkWell(
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.buttonRadius,
                  ),
                  onTap: () {
                    if (user.id != null) {
                      _loadUser(user.id!);
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
                          user.displayName ??
                              '${user.firstName ?? ''} ${user.lastName ?? ''}'
                                  .trim()
                                  .ifEmpty(user.username ?? 'User'),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.username ?? '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: appTheme.mutedText),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.status ?? 'active',
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
    final showDetailTabs = !_isNewUser && _selectedUserId != null;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isNewUser
                            ? 'Fill the complete user profile first. After saving, the permission, audit, and login tabs become active.'
                            : 'Role gives the base access, and direct permissions can be added in the next tab.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: appTheme.mutedText,
                        ),
                      ),
                    ],
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
                Tab(text: 'Audit Log'),
                Tab(text: 'Login History'),
              ],
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: showDetailTabs
                ? [
                    _buildProfileTab(context),
                    _buildPermissionsTab(context),
                    _buildAuditTab(context),
                    _buildLoginHistoryTab(context),
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
                    controller: _employeeCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Employee Code',
                    ),
                  ),
                ),
                _inputBox(
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Username is required'
                        : null,
                  ),
                ),
                _inputBox(
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _isNewUser
                          ? 'Password'
                          : 'Password (leave blank to keep)',
                    ),
                    validator: (value) {
                      if (_isNewUser &&
                          (value == null || value.trim().length < 6)) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                _inputBox(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'First name is required'
                        : null,
                  ),
                ),
                _inputBox(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                ),
                _inputBox(
                  child: TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                    ),
                    onChanged: (_) => _handleDisplayNameEdited(),
                  ),
                ),
                _inputBox(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ),
                _inputBox(
                  child: TextFormField(
                    controller: _mobileController,
                    decoration: const InputDecoration(labelText: 'Mobile'),
                  ),
                ),
                _inputBox(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                      DropdownMenuItem(
                        value: 'prefer_not_to_say',
                        child: Text('Prefer not to say'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                ),
                _inputBox(
                  child: TextFormField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                    ),
                    keyboardType: TextInputType.datetime,
                    inputFormatters: const [DateInputFormatter()],
                  ),
                ),
                _inputBox(
                  width: 324,
                  child: InlineFieldAction(
                    actionTooltip: 'Create role',
                    onAddNew: _openCreateRoleDialog,
                    field: DropdownButtonFormField<int>(
                      initialValue: _selectedRoleId,
                      decoration: const InputDecoration(
                        labelText: 'Primary Role',
                      ),
                      items: [
                        ..._roles.map(
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
                          _openCreateRoleDialog();
                          return;
                        }

                        setState(() {
                          _selectedRoleId = value;
                          if (_selectedRoleImpliesSuperAdmin()) {
                            _isSuperAdmin = true;
                          }
                        });
                        _resetPermissionsForSelectedRole();
                      },
                    ),
                  ),
                ),
                _inputBox(
                  width: 560,
                  child: UploadPathField(
                    controller: _profilePhotoController,
                    labelText: 'Profile Photo Path',
                    isUploading: _uploadingPhoto,
                    onUpload: _uploadUserImage,
                    previewUrl: AppConfig.resolvePublicFileUrl(
                      _profilePhotoController.text,
                    ),
                    previewIcon: Icons.person_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _boolSwitch(
                  context,
                  'System User',
                  _isSystemUser,
                  (value) => setState(() => _isSystemUser = value),
                ),
                _boolSwitch(
                  context,
                  'Must Change Password',
                  _mustChangePassword,
                  (value) => setState(() => _mustChangePassword = value),
                ),
                _boolSwitch(
                  context,
                  _selectedRoleImpliesSuperAdmin()
                      ? 'Super Admin via Role'
                      : 'Super Admin Override',
                  _isSuperAdmin,
                  _selectedRoleImpliesSuperAdmin()
                      ? null
                      : (value) => setState(() => _isSuperAdmin = value),
                ),
              ],
            ),
            if (_selectedRoleImpliesSuperAdmin()) ...[
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
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(
                    value: 'suspended',
                    child: Text('Suspended'),
                  ),
                  DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'active'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Remarks'),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _savingProfile ? null : _saveProfile,
                  icon: _savingProfile
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_savingProfile ? 'Saving...' : 'Save User'),
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
    if (_isNewUser) {
      return _emptyStateCard(
        context,
        icon: Icons.verified_user_outlined,
        title: 'Permissions Will Appear After Save',
        message:
            'Create the user first, then we can show role-based access and user-specific permission overrides here.',
      );
    }

    final grouped = <String, List<UserPermissionModel>>{};
    for (final permission in _effectivePermissions) {
      final key = permission.module ?? 'general';
      grouped.putIfAbsent(key, () => <UserPermissionModel>[]).add(permission);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Role gives the baseline access. You can add or remove rights here for this user only. Changing the role resets these custom overrides to the new role baseline.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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
          children: grouped.entries
              .map((entry) {
                return Card(
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(entry.key.toUpperCase()),
                    children: entry.value
                        .map((permission) {
                          final index = _effectivePermissions.indexOf(
                            permission,
                          );
                          final effective = _effectivePermissions.firstWhere(
                            (item) =>
                                item.permissionId == permission.permissionId,
                            orElse: () => permission,
                          );
                          final baseline = _rolePermissions.firstWhere(
                            (item) =>
                                item.permissionId == permission.permissionId,
                            orElse: () => permission,
                          );

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
                                      effective.allowView ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'view',
                                        value,
                                      ),
                                    ),
                                    _permCheck(
                                      'Create',
                                      effective.allowCreate ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'create',
                                        value,
                                      ),
                                    ),
                                    _permCheck(
                                      'Update',
                                      effective.allowUpdate ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'update',
                                        value,
                                      ),
                                    ),
                                    _permCheck(
                                      'Delete',
                                      effective.allowDelete ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'delete',
                                        value,
                                      ),
                                    ),
                                    _permCheck(
                                      'Approve',
                                      effective.allowApprove ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'approve',
                                        value,
                                      ),
                                    ),
                                    _permCheck(
                                      'Print',
                                      effective.allowPrint ?? false,
                                      (value) => _togglePermission(
                                        index,
                                        'print',
                                        value,
                                      ),
                                    ),
                                    _permCheck(
                                      'Export',
                                      effective.allowExport ?? false,
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
                                  'Role baseline: ${_rightsLabel(baseline)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Effective access: ${_rightsLabel(effective)}',
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

  Widget _buildAuditTab(BuildContext context) {
    if (_isNewUser) {
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
      items: _auditLogs,
      titleBuilder: (log) => log.description ?? log.action ?? 'Audit entry',
      subtitleBuilder: (log) =>
          '${log.module ?? '-'} • ${log.createdAt ?? ''}'.trim(),
      trailingBuilder: (log) => log.action ?? '',
    );
  }

  Widget _buildLoginHistoryTab(BuildContext context) {
    if (_isNewUser) {
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
      items: _loginHistory,
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

  Widget _boolSwitch(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }

  Widget _permCheck(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
    );
  }

  String _rightsLabel(UserPermissionModel permission) {
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

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

extension on List<int> {
  int? get firstOrNull => isEmpty ? null : first;
}
