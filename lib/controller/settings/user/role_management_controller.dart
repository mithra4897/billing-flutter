import '../../../screen.dart';

class RoleManagementController extends GetxController {
  RoleManagementController({required this.initialRoleId});

  final AuthService _authService = AuthService();
  final int? initialRoleId;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ScrollController pageScrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool initialLoading = true;
  bool loadingRoleDetails = false;
  bool loadingPermissions = false;
  bool savingProfile = false;
  bool savingPermissions = false;
  bool codeTouched = false;
  String? pageError;
  String? formError;
  bool isActive = true;
  bool isSystemRole = false;

  List<RoleModel> roles = const <RoleModel>[];
  List<RoleModel> filteredRoles = const <RoleModel>[];
  List<RolePermissionModel> rolePermissions = const <RolePermissionModel>[];
  Set<String> expandedPermissionModules = <String>{};

  int? selectedRoleId;
  int? permissionsLoadedForRoleId;
  int roleLoadToken = 0;
  int activeTabIndex = 0;

  bool get isNewRole => selectedRoleId == null;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(applyRoleFilter);
    nameController.addListener(syncCodeFromName);
    codeController.addListener(handleCodeEdited);
    loadInitial();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    searchController
      ..removeListener(applyRoleFilter)
      ..dispose();
    nameController.removeListener(syncCodeFromName);
    codeController.removeListener(handleCodeEdited);
    codeController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> loadInitial() async {
    initialLoading = true;
    pageError = null;
    update();

    try {
      final rolesResponse = await _authService.roles(
        filters: const {'per_page': 100},
      );
      roles = rolesResponse.data ?? const <RoleModel>[];
      filteredRoles = roles;

      if (initialRoleId != null) {
        await loadRole(initialRoleId!);
      } else {
        resetForm(notify: false);
      }

      initialLoading = false;
    } catch (error) {
      pageError = error.toString();
      initialLoading = false;
    }

    update();
  }

  void applyRoleFilter() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredRoles = roles;
      update();
      return;
    }

    filteredRoles = roles
        .where((role) {
          final label = [
            role.code,
            role.name,
            role.description,
          ].whereType<String>().join(' ').toLowerCase();
          return label.contains(query);
        })
        .toList(growable: false);
    update();
  }

  Future<void> loadRole(int roleId, {bool resetTab = false}) async {
    final token = ++roleLoadToken;

    selectedRoleId = roleId;
    loadingRoleDetails = true;
    formError = null;
    rolePermissions = const <RolePermissionModel>[];
    permissionsLoadedForRoleId = null;
    if (resetTab) {
      activeTabIndex = 0;
    }
    update();

    try {
      final roleResponse = await _authService.role(roleId);
      if (token != roleLoadToken) {
        return;
      }

      final role = roleResponse.data;
      if (role == null) {
        formError = 'Role not found.';
        loadingRoleDetails = false;
        update();
        return;
      }

      codeController.text = role.code ?? '';
      nameController.text = role.name ?? '';
      descriptionController.text = role.description ?? '';

      selectedRoleId = role.id;
      isActive = role.isActive ?? true;
      isSystemRole = role.isSystemRole ?? false;
      codeTouched = (role.code ?? '').trim().isNotEmpty;
      loadingRoleDetails = false;
      update();

      if (activeTabIndex == 1 && role.id != null) {
        await loadRolePermissions(role.id!, force: true);
      }
    } catch (error) {
      if (token != roleLoadToken) {
        return;
      }
      formError = error.toString();
      loadingRoleDetails = false;
      update();
    }
  }

  Future<void> loadRolePermissions(int roleId, {bool force = false}) async {
    if (!force &&
        !loadingPermissions &&
        permissionsLoadedForRoleId == roleId &&
        rolePermissions.isNotEmpty) {
      return;
    }

    loadingPermissions = true;
    formError = null;
    update();

    try {
      final response = await _authService.rolePermissions(roleId);
      if (selectedRoleId != roleId) {
        return;
      }

      rolePermissions =
          response.data?.permissions ?? const <RolePermissionModel>[];
      expandedPermissionModules = <String>{};
      permissionsLoadedForRoleId = roleId;
      loadingPermissions = false;
    } catch (error) {
      if (selectedRoleId != roleId) {
        return;
      }
      formError = error.toString();
      loadingPermissions = false;
    }

    update();
  }

  void resetForm({bool notify = true}) {
    selectedRoleId = null;
    codeController.clear();
    nameController.clear();
    descriptionController.clear();
    isActive = true;
    isSystemRole = false;
    codeTouched = false;
    rolePermissions = const <RolePermissionModel>[];
    expandedPermissionModules = <String>{};
    permissionsLoadedForRoleId = null;
    formError = null;
    activeTabIndex = 0;
    loadingRoleDetails = false;
    loadingPermissions = false;
    if (notify) {
      update();
    }
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    savingProfile = true;
    formError = null;
    update();

    try {
      final model = RoleModel(
        id: selectedRoleId,
        code: codeController.text.trim().toUpperCase(),
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        isActive: isActive,
        isSystemRole: isSystemRole,
      );

      final response = isNewRole
          ? await _authService.createRole(model)
          : await _authService.updateRole(selectedRoleId!, model);

      final saved = response.data;
      if (saved == null || saved.id == null) {
        formError = response.message;
        update();
        return;
      }

      await loadInitial();
      await loadRole(saved.id!);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      savingProfile = false;
      update();
    }
  }

  Future<void> savePermissions() async {
    if (selectedRoleId == null) {
      return;
    }

    savingPermissions = true;
    formError = null;
    update();

    try {
      final response = await _authService.syncRolePermissions(
        selectedRoleId!,
        RolePermissionSyncRequestModel(permissions: rolePermissions),
      );

      await loadRolePermissions(selectedRoleId!, force: true);
      await AppSessionService.instance.refreshUserAccess();
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      savingPermissions = false;
      update();
    }
  }

  void togglePermission(int index, String field, bool enabled) {
    final current = rolePermissions[index];
    rolePermissions = List<RolePermissionModel>.from(rolePermissions)
      ..[index] = current.copyWith(
        allowView: field == 'view' ? enabled : current.allowView,
        allowCreate: field == 'create' ? enabled : current.allowCreate,
        allowUpdate: field == 'update' ? enabled : current.allowUpdate,
        allowDelete: field == 'delete' ? enabled : current.allowDelete,
        allowApprove: field == 'approve' ? enabled : current.allowApprove,
        allowPrint: field == 'print' ? enabled : current.allowPrint,
        allowExport: field == 'export' ? enabled : current.allowExport,
      );
    update();
  }

  void togglePermissionByIdentity(
    RolePermissionModel permission,
    String field,
    bool enabled,
  ) {
    final index = rolePermissions.indexWhere(
      (item) =>
          item.permissionId == permission.permissionId &&
          item.code == permission.code &&
          item.name == permission.name,
    );
    if (index == -1) {
      return;
    }
    togglePermission(index, field, enabled);
  }

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
    if (index == 1 && selectedRoleId != null) {
      unawaited(loadRolePermissions(selectedRoleId!));
    }
    update();
  }

  void syncCodeFromName() {
    if (codeTouched) {
      return;
    }

    final generated = generateCode(nameController.text);
    if (codeController.text != generated) {
      codeController.value = codeController.value.copyWith(
        text: generated,
        selection: TextSelection.collapsed(offset: generated.length),
      );
    }
  }

  void handleCodeEdited() {
    final generated = generateCode(nameController.text);
    final current = codeController.text.trim();
    if (current.isEmpty || current == generated) {
      codeTouched = false;
      return;
    }

    codeTouched = true;
  }

  String generateCode(String value) {
    final cleaned = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.length > 50 ? cleaned.substring(0, 50) : cleaned;
  }

  void setIsActiveFromStatus(String? value) {
    isActive = value == 'active';
    update();
  }

  void togglePermissionModule(String permissionKey, bool expanded) {
    final next = Set<String>.from(expandedPermissionModules);
    if (expanded) {
      next.add(permissionKey);
    } else {
      next.remove(permissionKey);
    }
    expandedPermissionModules = next;
    update();
  }

  String permissionRightsSummary(RolePermissionModel permission) {
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
