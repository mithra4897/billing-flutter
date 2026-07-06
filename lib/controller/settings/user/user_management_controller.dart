import '../../../screen.dart';

class UserManagementController extends GetxController {
  UserManagementController({required this.initialUserId});

  final AuthService _authService = AuthService();
  final HrService _hrService = HrService();
  final MediaService _mediaService = MediaService();
  final MasterService _masterService = MasterService();
  final int? initialUserId;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ScrollController pageScrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController employeeCodeController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController profilePhotoController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool savingProfile = false;
  bool savingPermissions = false;
  bool savingAccessScope = false;
  bool uploadingPhoto = false;
  String? pageError;
  String? formError;
  String? gender;
  String? selectedEmployeeFallbackLabel;
  String? selectedEmployeeFallbackName;
  int? selectedRoleId;
  bool mustChangePassword = true;
  bool isSystemUser = true;
  bool isSuperAdmin = false;
  String status = 'active';
  bool displayNameTouched = false;

  List<UserModel> users = const <UserModel>[];
  List<UserModel> filteredUsers = const <UserModel>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];
  List<RoleModel> roles = const <RoleModel>[];
  List<UserPermissionModel> rolePermissions = const <UserPermissionModel>[];
  List<PermissionModel> permissions = const <PermissionModel>[];
  List<UserPermissionModel> effectivePermissions =
      const <UserPermissionModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  Set<String> expandedPermissionModules = <String>{};
  List<AuditLogModel> auditLogs = const <AuditLogModel>[];
  List<LoginHistoryModel> loginHistory = const <LoginHistoryModel>[];
  Set<int> selectedCompanyIds = <int>{};
  Set<int> selectedBranchIds = <int>{};
  Set<int> selectedLocationIds = <int>{};
  Set<int> selectedWarehouseIds = <int>{};
  int? defaultCompanyAccessId;
  int? defaultBranchAccessId;
  int? defaultLocationAccessId;
  int? defaultWarehouseAccessId;
  Map<int, Map<String, bool>> locationAccessFlags = <int, Map<String, bool>>{};
  Map<int, Map<String, bool>> warehouseAccessFlags = <int, Map<String, bool>>{};

  int? selectedUserId;
  int? selectedEmployeeId;
  int activeTabIndex = 0;

  bool get isNewUser => selectedUserId == null;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(applyUserFilter);
    firstNameController.addListener(syncDisplayNameFromNameParts);
    lastNameController.addListener(syncDisplayNameFromNameParts);
    displayNameController.addListener(handleDisplayNameEdited);
    loadInitial();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    searchController
      ..removeListener(applyUserFilter)
      ..dispose();
    firstNameController.removeListener(syncDisplayNameFromNameParts);
    lastNameController.removeListener(syncDisplayNameFromNameParts);
    displayNameController.removeListener(handleDisplayNameEdited);
    employeeCodeController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    displayNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    dobController.dispose();
    profilePhotoController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadInitial() async {
    initialLoading = true;
    pageError = null;
    update();

    try {
      final usersResponse = await _authService.users(
        filters: const {'per_page': 100},
      );
      final employeesResponse = await _hrService.employees(
        filters: const {'per_page': 200, 'sort_by': 'employee_name'},
      );
      final rolesResponse = await _authService.roles(
        filters: const {'per_page': 100},
      );
      final permissionsResponse = await _authService.permissions(
        filters: const {'per_page': 500},
      );
      final companiesResponse = await _masterService.companies(
        filters: const {'per_page': 500},
      );
      final branchesResponse = await _masterService.branches(
        filters: const {'per_page': 500},
      );
      final locationsResponse = await _masterService.businessLocations(
        filters: const {'per_page': 500},
      );
      final warehousesResponse = await _masterService.warehouses(
        filters: const {'per_page': 500},
      );

      users = usersResponse.data ?? const <UserModel>[];
      filteredUsers = users;
      employees = employeesResponse.data ?? const <EmployeeModel>[];
      roles = rolesResponse.data ?? const <RoleModel>[];
      permissions = permissionsResponse.data ?? const <PermissionModel>[];
      companies = companiesResponse.data ?? const <CompanyModel>[];
      branches = branchesResponse.data ?? const <BranchModel>[];
      locations = locationsResponse.data ?? const <BusinessLocationModel>[];
      warehouses = warehousesResponse.data ?? const <WarehouseModel>[];

      if (initialUserId != null) {
        await loadUser(initialUserId!);
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

  void applyUserFilter() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredUsers = users;
      update();
      return;
    }

    filteredUsers = users
        .where((user) {
          final label = [
            user.employeeCode,
            user.employeeName,
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
    update();
  }

  Future<void> loadUser(int userId) async {
    final response = await _authService.user(userId);
    final user = response.data;
    if (user == null) {
      return;
    }

    selectedUserId = user.id;
    selectedEmployeeId = user.employeeId;
    selectedEmployeeFallbackName = _fallbackEmployeeNameForUser(user);
    selectedEmployeeFallbackLabel = _composeEmployeeLabel(
      user.employeeCode,
      selectedEmployeeFallbackName,
    );
    setEmployeeCode(user.employeeCode ?? '');
    usernameController.text = user.username ?? '';
    passwordController.clear();
    firstNameController.text = user.firstName ?? '';
    lastNameController.text = user.lastName ?? '';
    displayNameController.text = user.displayName ?? '';
    emailController.text = user.email ?? '';
    mobileController.text = user.mobile ?? '';
    dobController.text = normalizeDateValue(user.dateOfBirth);
    profilePhotoController.text = user.profilePhotoPath ?? '';
    remarksController.text = user.remarks ?? '';
    gender = user.gender;
    mustChangePassword = user.mustChangePassword ?? true;
    isSystemUser = user.isSystemUser ?? true;
    isSuperAdmin = user.isSuperAdmin ?? false;
    status = user.status ?? 'active';
    displayNameTouched = (user.displayName ?? '').trim().isNotEmpty;
    final primaryRole = user.userRoles.where(
      (item) => item.isPrimaryRole == true,
    );
    selectedRoleId = primaryRole.isNotEmpty
        ? primaryRole.first.roleId
        : user.userRoles.isNotEmpty
        ? user.userRoles.first.roleId
        : firstOrNull(user.roleIds);

    await ensureSelectedEmployeeLoaded(user);
    resolveSelectedEmployeeFromFallback();
    await loadTabs(userId);
    update();
  }

  Future<void> loadTabs(int userId) async {
    final permissionSummary = await _authService.userPermissions(userId);
    final accessSummary = await _authService.userAccessSummary(userId);
    final auditResponse = await _authService.userAuditLogs(
      userId,
      filters: const {'per_page': 25},
    );
    final loginResponse = await _authService.userLoginHistory(
      userId,
      filters: const {'per_page': 25},
    );

    applyPermissionSummary(permissionSummary.data);
    applyAccessSummary(accessSummary.data);
    auditLogs = auditResponse.data ?? const <AuditLogModel>[];
    loginHistory = loginResponse.data ?? const <LoginHistoryModel>[];
  }

  void applyPermissionSummary(UserPermissionSummaryModel? summary) {
    rolePermissions = mergePermissionSet(summary?.rolePermissions ?? const []);
    effectivePermissions = mergePermissionSet(
      summary?.effectivePermissions ?? const [],
    );
    expandedPermissionModules = <String>{};
  }

  void applyAccessSummary(UserModel? summary) {
    final companyRows =
        summary?.companyAccess ?? const <UserCompanyAccessModel>[];
    final branchRows = summary?.branchAccess ?? const <UserBranchAccessModel>[];
    final locationRows =
        summary?.locationAccess ?? const <UserLocationAccessModel>[];
    final warehouseRows =
        summary?.warehouseAccess ?? const <UserWarehouseAccessModel>[];

    selectedCompanyIds = companyRows
        .where((row) => row.isActive != false && row.companyId != null)
        .map((row) => row.companyId!)
        .toSet();
    selectedBranchIds = branchRows
        .where((row) => row.isActive != false && row.branchId != null)
        .map((row) => row.branchId!)
        .toSet();
    selectedLocationIds = locationRows
        .where((row) => row.isActive != false && row.locationId != null)
        .map((row) => row.locationId!)
        .toSet();
    selectedWarehouseIds = warehouseRows
        .where((row) => row.isActive != false && row.warehouseId != null)
        .map((row) => row.warehouseId!)
        .toSet();

    defaultCompanyAccessId = companyRows
        .firstWhereOrNull((row) => row.isDefault == true)
        ?.companyId;
    defaultBranchAccessId = branchRows
        .firstWhereOrNull((row) => row.isDefault == true)
        ?.branchId;
    defaultLocationAccessId = locationRows
        .firstWhereOrNull((row) => row.isDefault == true)
        ?.locationId;
    defaultWarehouseAccessId = warehouseRows
        .firstWhereOrNull((row) => row.isDefault == true)
        ?.warehouseId;

    locationAccessFlags = {
      for (final row in locationRows)
        if (row.locationId != null)
          row.locationId!: <String, bool>{
            'can_bill': row.canBill ?? true,
            'can_purchase': row.canPurchase ?? true,
            'can_stock_entry': row.canStockEntry ?? true,
            'can_accounts_entry': row.canAccountsEntry ?? true,
            'can_hr_entry': row.canHrEntry ?? true,
          },
    };
    warehouseAccessFlags = {
      for (final row in warehouseRows)
        if (row.warehouseId != null)
          row.warehouseId!: <String, bool>{
            'can_view_stock': row.canViewStock ?? true,
            'can_stock_in': row.canStockIn ?? true,
            'can_stock_out': row.canStockOut ?? true,
            'can_transfer': row.canTransfer ?? true,
            'can_adjust': row.canAdjust ?? true,
          },
    };

    normalizeAccessTree();
  }

  void resetForm({bool notify = true}) {
    selectedUserId = null;
    selectedEmployeeId = null;
    selectedEmployeeFallbackLabel = null;
    selectedEmployeeFallbackName = null;
    setEmployeeCode('');
    usernameController.clear();
    passwordController.clear();
    firstNameController.clear();
    lastNameController.clear();
    displayNameController.clear();
    emailController.clear();
    mobileController.clear();
    dobController.clear();
    profilePhotoController.clear();
    remarksController.clear();
    gender = null;
    selectedRoleId = null;
    mustChangePassword = true;
    isSystemUser = true;
    isSuperAdmin = false;
    status = 'active';
    displayNameTouched = false;
    rolePermissions = mergePermissionSet(const []);
    effectivePermissions = mergePermissionSet(const []);
    expandedPermissionModules = <String>{};
    selectedCompanyIds = <int>{};
    selectedBranchIds = <int>{};
    selectedLocationIds = <int>{};
    selectedWarehouseIds = <int>{};
    defaultCompanyAccessId = null;
    defaultBranchAccessId = null;
    defaultLocationAccessId = null;
    defaultWarehouseAccessId = null;
    locationAccessFlags = <int, Map<String, bool>>{};
    warehouseAccessFlags = <int, Map<String, bool>>{};
    auditLogs = const [];
    loginHistory = const [];
    formError = null;
    activeTabIndex = 0;
    if (notify) {
      update();
    }
  }

  EmployeeModel? get selectedEmployee =>
      employees.cast<EmployeeModel?>().firstWhere(
        (employee) => employee?.id == selectedEmployeeId,
        orElse: () => null,
      );

  List<EmployeeModel> get availableEmployees => employees
      .where(
        (employee) =>
            employee.id == selectedEmployeeId || employee.userId == null,
      )
      .toList(growable: false);

  String? get selectedEmployeeLabel {
    final employee = selectedEmployee;
    if (employee == null) {
      final fallback = (selectedEmployeeFallbackLabel ?? '').trim();
      return fallback.isEmpty ? null : fallback;
    }
    final code = employee.employeeCode?.trim() ?? '';
    final name = (employee.employeeName?.trim().isNotEmpty ?? false)
        ? employee.employeeName!.trim()
        : (selectedEmployeeFallbackName ?? '').trim();
    if (code.isEmpty) {
      return name.isEmpty ? null : name;
    }
    return name.isEmpty ? code : '$code - $name';
  }

  void selectEmployee(int? employeeId) {
    final employee = employees.cast<EmployeeModel?>().firstWhere(
      (item) => item?.id == employeeId,
      orElse: () => null,
    );

    selectedEmployeeId = employee?.id;
    selectedEmployeeFallbackName = employee?.employeeName?.trim();
    selectedEmployeeFallbackLabel = employee == null
        ? null
        : _composeEmployeeLabel(employee.employeeCode, employee.employeeName);
    setEmployeeCode(employee?.employeeCode ?? '');

    if (isNewUser && employee != null) {
      emailController.text = emailController.text.trim().isEmpty
          ? (employee.email ?? '')
          : emailController.text;
      mobileController.text = mobileController.text.trim().isEmpty
          ? (employee.mobile ?? '')
          : mobileController.text;
      profilePhotoController.text = profilePhotoController.text.trim().isEmpty
          ? (employee.profilePhotoPath ?? '')
          : profilePhotoController.text;
    }
    update();
  }

  void setEmployeeCode(String value) {
    employeeCodeController.value = employeeCodeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> ensureSelectedEmployeeLoaded(UserModel user) async {
    final employeeId = user.employeeId;
    if (employeeId == null) {
      return;
    }

    final exists = employees.any((employee) => employee.id == employeeId);
    if (exists) {
      return;
    }

    try {
      final response = await _hrService.employee(employeeId);
      final employee = response.data;
      if (employee == null) {
        return;
      }

      employees = <EmployeeModel>[
        employee,
        ...employees.where((item) => item.id != employee.id),
      ];
    } catch (_) {
      final fallbackHasValue =
          (user.employeeCode ?? '').trim().isNotEmpty ||
          (user.employeeName ?? '').trim().isNotEmpty;
      if (!fallbackHasValue) {
        return;
      }

      employees = <EmployeeModel>[
        EmployeeModel(
          id: employeeId,
          employeeCode: user.employeeCode,
          employeeName: _fallbackEmployeeNameForUser(user),
          userId: user.id,
        ),
        ...employees.where((item) => item.id != employeeId),
      ];
    }
  }

  String? _fallbackEmployeeNameForUser(UserModel user) {
    final displayName = user.employeeName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final userDisplayName = user.displayName?.trim();
    if (userDisplayName != null && userDisplayName.isNotEmpty) {
      return userDisplayName;
    }

    final fullName = [
      user.firstName?.trim(),
      user.lastName?.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final username = user.username?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }

    return null;
  }

  String? _composeEmployeeLabel(String? code, String? name) {
    final normalizedCode = (code ?? '').trim();
    final normalizedName = (name ?? '').trim();
    if (normalizedCode.isEmpty) {
      return normalizedName.isEmpty ? null : normalizedName;
    }
    return normalizedName.isEmpty
        ? normalizedCode
        : '$normalizedCode - $normalizedName';
  }

  void resolveSelectedEmployeeFromFallback() {
    if (selectedEmployeeId != null) {
      return;
    }

    final employeeCode = employeeCodeController.text.trim().toLowerCase();
    final fallbackName = (selectedEmployeeFallbackName ?? '')
        .trim()
        .toLowerCase();

    final matchedEmployee = employees.cast<EmployeeModel?>().firstWhere((
      employee,
    ) {
      if (employee == null) {
        return false;
      }

      final codeMatches =
          employeeCode.isNotEmpty &&
          (employee.employeeCode?.trim().toLowerCase() ?? '') == employeeCode;
      if (codeMatches) {
        return true;
      }

      final nameMatches =
          fallbackName.isNotEmpty &&
          (employee.employeeName?.trim().toLowerCase() ?? '') == fallbackName;
      return nameMatches;
    }, orElse: () => null);

    if (matchedEmployee == null) {
      return;
    }

    selectedEmployeeId = matchedEmployee.id;
    selectedEmployeeFallbackName =
        matchedEmployee.employeeName?.trim().isNotEmpty == true
        ? matchedEmployee.employeeName!.trim()
        : selectedEmployeeFallbackName;
    selectedEmployeeFallbackLabel = _composeEmployeeLabel(
      matchedEmployee.employeeCode,
      selectedEmployeeFallbackName,
    );
    setEmployeeCode(
      matchedEmployee.employeeCode ?? employeeCodeController.text,
    );
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    resolveSelectedEmployeeFromFallback();

    if (selectedRoleId == null) {
      formError = 'Please select a role before saving the user.';
      update();
      return;
    }

    if (selectedEmployeeId == null) {
      formError = 'Please select an employee before saving the user.';
      update();
      return;
    }

    savingProfile = true;
    formError = null;
    update();

    try {
      final password = passwordController.text.trim();
      final model = UserModel(
        id: selectedUserId,
        employeeId: selectedEmployeeId,
        employeeCode: employeeCodeController.text.trim().isEmpty
            ? null
            : employeeCodeController.text.trim(),
        username: usernameController.text.trim(),
        password: isNewUser && password.isNotEmpty ? password : null,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim().isEmpty
            ? null
            : lastNameController.text.trim(),
        displayName: displayNameController.text.trim().isEmpty
            ? null
            : displayNameController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        mobile: mobileController.text.trim().isEmpty
            ? null
            : mobileController.text.trim(),
        gender: gender,
        dateOfBirth: dobController.text.trim().isEmpty
            ? null
            : normalizeDateValue(dobController.text.trim()),
        profilePhotoPath: profilePhotoController.text.trim().isEmpty
            ? null
            : profilePhotoController.text.trim(),
        isSuperAdmin: isSuperAdmin,
        isSystemUser: isSystemUser,
        mustChangePassword: mustChangePassword,
        status: status,
        remarks: remarksController.text.trim().isEmpty
            ? null
            : remarksController.text.trim(),
        roleIds: <int>[selectedRoleId!],
      );

      final response = isNewUser
          ? await _authService.createUser(model)
          : await _authService.updateUser(selectedUserId!, model);

      final saved = response.data;
      if (saved == null || saved.id == null) {
        formError = response.message;
        update();
        return;
      }

      if (!isNewUser && password.isNotEmpty) {
        await _authService.resetUserPassword(
          saved.id!,
          ResetUserPasswordRequestModel(
            newPassword: password,
            mustChangePassword: mustChangePassword,
          ),
        );
      }

      await AppSessionService.instance.refreshUserAccess();
      await loadInitial();
      await loadUser(saved.id!);
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
    if (selectedUserId == null) {
      return;
    }

    savingPermissions = true;
    formError = null;
    update();

    try {
      final toSave = effectivePermissions
          .where((permission) => differsFromRole(permission))
          .toList(growable: false);

      final response = await _authService.syncUserExtraPermissions(
        selectedUserId!,
        toSave,
      );
      applyPermissionSummary(response.data);
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

  Future<void> saveAccessScope() async {
    if (selectedUserId == null) {
      return;
    }

    normalizeAccessTree();

    if (selectedCompanyIds.isEmpty ||
        selectedBranchIds.isEmpty ||
        selectedLocationIds.isEmpty ||
        selectedWarehouseIds.isEmpty) {
      formError =
          'Select at least one company, branch, location, and warehouse before saving access scope.';
      update();
      return;
    }

    savingAccessScope = true;
    formError = null;
    update();

    try {
      final companyIds = selectedCompanyIds.toList(growable: false)..sort();
      final branchIds = selectedBranchIds.toList(growable: false)..sort();
      final locationIds = selectedLocationIds.toList(growable: false)..sort();
      final warehouseIds = selectedWarehouseIds.toList(growable: false)..sort();

      final resolvedDefaultCompanyId = _resolveDefaultId(
        defaultCompanyAccessId,
        companyIds,
      );
      final resolvedDefaultBranchId = _resolveDefaultId(
        defaultBranchAccessId,
        branchIds,
      );
      final resolvedDefaultLocationId = _resolveDefaultId(
        defaultLocationAccessId,
        locationIds,
      );
      final resolvedDefaultWarehouseId = _resolveDefaultId(
        defaultWarehouseAccessId,
        warehouseIds,
      );

      await _authService.syncUserCompanies(
        selectedUserId!,
        UserCompaniesSyncRequestModel(
          companies: companyIds
              .map(
                (id) => <String, dynamic>{
                  'company_id': id,
                  'is_default': id == resolvedDefaultCompanyId,
                  'is_active': true,
                },
              )
              .toList(growable: false),
        ),
      );

      await _authService.syncUserBranches(
        selectedUserId!,
        UserBranchesSyncRequestModel(
          branches: branchIds
              .map(
                (id) => <String, dynamic>{
                  'branch_id': id,
                  'is_default': id == resolvedDefaultBranchId,
                  'is_active': true,
                },
              )
              .toList(growable: false),
        ),
      );

      await _authService.syncUserLocations(
        selectedUserId!,
        UserLocationsSyncRequestModel(
          locations: locationIds
              .map(
                (id) => <String, dynamic>{
                  'location_id': id,
                  'is_default': id == resolvedDefaultLocationId,
                  'is_active': true,
                  ..._locationFlagsFor(id),
                },
              )
              .toList(growable: false),
        ),
      );

      final response = await _authService.syncUserWarehouses(
        selectedUserId!,
        UserWarehousesSyncRequestModel(
          warehouses: warehouseIds
              .map(
                (id) => <String, dynamic>{
                  'warehouse_id': id,
                  'is_default': id == resolvedDefaultWarehouseId,
                  'is_active': true,
                  ..._warehouseFlagsFor(id),
                },
              )
              .toList(growable: false),
        ),
      );

      defaultCompanyAccessId = resolvedDefaultCompanyId;
      defaultBranchAccessId = resolvedDefaultBranchId;
      defaultLocationAccessId = resolvedDefaultLocationId;
      defaultWarehouseAccessId = resolvedDefaultWarehouseId;

      await AppSessionService.instance.refreshUserAccess();
      final accessSummary = await _authService.userAccessSummary(
        selectedUserId!,
      );
      applyAccessSummary(accessSummary.data);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (error) {
      formError = error.toString();
    } finally {
      savingAccessScope = false;
      update();
    }
  }

  Future<void> uploadUserImage(BuildContext context) async {
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      onLoading: (isLoading) {
        uploadingPhoto = isLoading;
        update();
      },
      onSuccess: (filePath) {
        profilePhotoController.text = filePath;
        formError = null;
        update();
      },
      onError: (error) {
        formError = error;
        update();
      },
      module: 'auth',
      documentType: 'users',
      documentId: selectedUserId,
      purpose: 'profile_photo',
      folder: 'users/profile',
      isPublic: true,
    );
  }

  void togglePermission(int index, String field, bool enabled) {
    final current = effectivePermissions[index];
    effectivePermissions = List<UserPermissionModel>.from(effectivePermissions)
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
    UserPermissionModel permission,
    String field,
    bool enabled,
  ) {
    final index = effectivePermissions.indexWhere(
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

  void handleDisplayNameEdited() {
    final generated = generatedDisplayName;
    final current = displayNameController.text.trim();
    if (current.isEmpty || current == generated) {
      displayNameTouched = false;
      return;
    }
    displayNameTouched = true;
  }

  void syncDisplayNameFromNameParts() {
    if (displayNameTouched) {
      return;
    }
    final generated = generatedDisplayName;
    if (displayNameController.text != generated) {
      displayNameController.value = displayNameController.value.copyWith(
        text: generated,
        selection: TextSelection.collapsed(offset: generated.length),
      );
    }
  }

  String get generatedDisplayName => [
    firstNameController.text.trim(),
    lastNameController.text.trim(),
  ].where((value) => value.isNotEmpty).join(' ');

  bool selectedRoleImpliesSuperAdmin() {
    final role = roles.where((item) => item.id == selectedRoleId).firstOrNull;
    final tokens = '${role?.code ?? ''} ${role?.name ?? ''}'.toLowerCase();
    return tokens.contains('superadmin') || tokens.contains('super admin');
  }

  List<UserPermissionModel> mergePermissionSet(
    List<UserPermissionModel> source,
  ) {
    final sourceMap = {for (final item in source) item.permissionId ?? 0: item};

    return permissions
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

  bool differsFromRole(UserPermissionModel permission) {
    final baseline = rolePermissions.firstWhere(
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

  Future<void> resetPermissionsForSelectedRole() async {
    if (selectedRoleId == null) {
      rolePermissions = mergePermissionSet(const []);
      effectivePermissions = mergePermissionSet(const []);
      update();
      return;
    }

    final response = await _authService.rolePermissions(selectedRoleId!);
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

    rolePermissions = mergePermissionSet(permissionRows);
    effectivePermissions = mergePermissionSet(permissionRows);
    expandedPermissionModules = <String>{};
    update();
  }

  Future<void> openCreateRoleDialog(BuildContext context) async {
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

    if (createdRole == null || createdRole.id == null) {
      return;
    }

    final refreshedRoles = await _authService.roles(
      filters: const {'per_page': 100},
    );
    roles = refreshedRoles.data ?? <RoleModel>[createdRole];
    selectedRoleId = createdRole.id;
    if (selectedRoleImpliesSuperAdmin()) {
      isSuperAdmin = true;
    }
    appScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Role created successfully.')),
    );
    update();
  }

  void setGender(String? value) {
    gender = value;
    update();
  }

  void setSelectedRoleId(int? value) {
    selectedRoleId = value;
    if (selectedRoleImpliesSuperAdmin()) {
      isSuperAdmin = true;
    }
    update();
    unawaited(resetPermissionsForSelectedRole());
  }

  void setIsSystemUser(bool value) {
    isSystemUser = value;
    update();
  }

  void setMustChangePassword(bool value) {
    mustChangePassword = value;
    update();
  }

  void setIsSuperAdmin(bool value) {
    isSuperAdmin = value;
    update();
  }

  void setStatus(String? value) {
    status = value ?? 'active';
    update();
  }

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
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

  List<BranchModel> branchesForCompany(int companyId) => branches
      .where((branch) => branch.companyId == companyId)
      .toList(growable: false);

  List<BusinessLocationModel> locationsForBranch(int branchId) => locations
      .where((location) => location.branchId == branchId)
      .toList(growable: false);

  List<WarehouseModel> warehousesForLocation(int locationId) => warehouses
      .where((warehouse) => warehouse.locationId == locationId)
      .toList(growable: false);

  int selectionStateForCompany(int companyId) {
    final companyBranches = branchesForCompany(companyId);
    final warehouseDescendants = companyBranches
        .expand((branch) => locationsForBranch(branch.id ?? 0))
        .expand((location) => warehousesForLocation(location.id ?? 0))
        .where((warehouse) => warehouse.id != null)
        .map((warehouse) => warehouse.id!)
        .toSet();
    return _selectionState(
      warehouseDescendants,
      selectedWarehouseIds,
      explicitSelected: selectedCompanyIds.contains(companyId),
    );
  }

  int selectionStateForBranch(int branchId) {
    final warehouseDescendants = locationsForBranch(branchId)
        .expand((location) => warehousesForLocation(location.id ?? 0))
        .where((warehouse) => warehouse.id != null)
        .map((warehouse) => warehouse.id!)
        .toSet();
    return _selectionState(
      warehouseDescendants,
      selectedWarehouseIds,
      explicitSelected: selectedBranchIds.contains(branchId),
    );
  }

  int selectionStateForLocation(int locationId) {
    final warehouseDescendants = warehousesForLocation(locationId)
        .where((warehouse) => warehouse.id != null)
        .map((warehouse) => warehouse.id!)
        .toSet();
    return _selectionState(
      warehouseDescendants,
      selectedWarehouseIds,
      explicitSelected: selectedLocationIds.contains(locationId),
    );
  }

  int selectionStateForWarehouse(int warehouseId) =>
      selectedWarehouseIds.contains(warehouseId) ? 2 : 0;

  void setCompanySelection(int companyId, bool shouldSelect) {
    final branchIds = branchesForCompany(
      companyId,
    ).where((branch) => branch.id != null).map((branch) => branch.id!).toSet();
    final locationIds = branchIds
        .expand((branchId) => locationsForBranch(branchId))
        .where((location) => location.id != null)
        .map((location) => location.id!)
        .toSet();
    final warehouseIds = locationIds
        .expand((locationId) => warehousesForLocation(locationId))
        .where((warehouse) => warehouse.id != null)
        .map((warehouse) => warehouse.id!)
        .toSet();

    _applySelection(
      shouldSelect: shouldSelect,
      companyIds: <int>{companyId},
      branchIds: branchIds,
      locationIds: locationIds,
      warehouseIds: warehouseIds,
    );
  }

  void toggleCompanySelection(int companyId) {
    setCompanySelection(companyId, selectionStateForCompany(companyId) != 2);
  }

  void setBranchSelection(int branchId, bool shouldSelect) {
    final branch = branches.firstWhereOrNull((item) => item.id == branchId);
    final locationIds = locationsForBranch(branchId)
        .where((location) => location.id != null)
        .map((location) => location.id!)
        .toSet();
    final warehouseIds = locationIds
        .expand((locationId) => warehousesForLocation(locationId))
        .where((warehouse) => warehouse.id != null)
        .map((warehouse) => warehouse.id!)
        .toSet();

    _applySelection(
      shouldSelect: shouldSelect,
      companyIds: branch?.companyId == null
          ? <int>{}
          : <int>{branch!.companyId!},
      branchIds: <int>{branchId},
      locationIds: locationIds,
      warehouseIds: warehouseIds,
    );
  }

  void toggleBranchSelection(int branchId) {
    setBranchSelection(branchId, selectionStateForBranch(branchId) != 2);
  }

  void setLocationSelection(int locationId, bool shouldSelect) {
    final location = locations.firstWhereOrNull(
      (item) => item.id == locationId,
    );
    final warehouseIds = warehousesForLocation(locationId)
        .where((warehouse) => warehouse.id != null)
        .map((warehouse) => warehouse.id!)
        .toSet();

    _applySelection(
      shouldSelect: shouldSelect,
      companyIds: location?.companyId == null
          ? <int>{}
          : <int>{location!.companyId!},
      branchIds: location?.branchId == null
          ? <int>{}
          : <int>{location!.branchId!},
      locationIds: <int>{locationId},
      warehouseIds: warehouseIds,
    );
  }

  void toggleLocationSelection(int locationId) {
    setLocationSelection(
      locationId,
      selectionStateForLocation(locationId) != 2,
    );
  }

  void setWarehouseSelection(int warehouseId, bool shouldSelect) {
    final warehouse = warehouses.firstWhereOrNull(
      (item) => item.id == warehouseId,
    );

    _applySelection(
      shouldSelect: shouldSelect,
      companyIds: warehouse?.companyId == null
          ? <int>{}
          : <int>{warehouse!.companyId!},
      branchIds: warehouse?.branchId == null
          ? <int>{}
          : <int>{warehouse!.branchId!},
      locationIds: warehouse?.locationId == null
          ? <int>{}
          : <int>{warehouse!.locationId!},
      warehouseIds: <int>{warehouseId},
    );
  }

  void toggleWarehouseSelection(int warehouseId) {
    setWarehouseSelection(
      warehouseId,
      !selectedWarehouseIds.contains(warehouseId),
    );
  }

  void setDefaultCompanyAccess(int companyId) {
    defaultCompanyAccessId = companyId;
    update();
  }

  void setDefaultBranchAccess(int branchId) {
    defaultBranchAccessId = branchId;
    update();
  }

  void setDefaultLocationAccess(int locationId) {
    defaultLocationAccessId = locationId;
    update();
  }

  void setDefaultWarehouseAccess(int warehouseId) {
    defaultWarehouseAccessId = warehouseId;
    update();
  }

  void setLocationAccessFlag(int locationId, String key, bool value) {
    locationAccessFlags = Map<int, Map<String, bool>>.from(locationAccessFlags)
      ..[locationId] = <String, bool>{
        ..._locationFlagsFor(locationId),
        key: value,
      };
    update();
  }

  void setWarehouseAccessFlag(int warehouseId, String key, bool value) {
    warehouseAccessFlags =
        Map<int, Map<String, bool>>.from(warehouseAccessFlags)
          ..[warehouseId] = <String, bool>{
            ..._warehouseFlagsFor(warehouseId),
            key: value,
          };
    update();
  }

  void normalizeAccessTree() {
    selectedWarehouseIds = selectedWarehouseIds
        .where(
          (warehouseId) => warehouses.any((item) => item.id == warehouseId),
        )
        .toSet();

    final selectedLocations = <int>{};
    final selectedBranches = <int>{};
    final selectedCompanies = <int>{};

    for (final warehouseId in selectedWarehouseIds) {
      final warehouse = warehouses.firstWhereOrNull(
        (item) => item.id == warehouseId,
      );
      if (warehouse == null) {
        continue;
      }
      if (warehouse.locationId != null) {
        selectedLocations.add(warehouse.locationId!);
      }
      if (warehouse.branchId != null) {
        selectedBranches.add(warehouse.branchId!);
      }
      if (warehouse.companyId != null) {
        selectedCompanies.add(warehouse.companyId!);
      }
    }

    selectedLocationIds =
        selectedLocationIds
            .where((locationId) => selectedLocations.contains(locationId))
            .toSet()
          ..addAll(selectedLocations);
    selectedBranchIds =
        selectedBranchIds
            .where((branchId) => selectedBranches.contains(branchId))
            .toSet()
          ..addAll(selectedBranches);
    selectedCompanyIds =
        selectedCompanyIds
            .where((companyId) => selectedCompanies.contains(companyId))
            .toSet()
          ..addAll(selectedCompanies);

    defaultCompanyAccessId = _resolveDefaultId(
      defaultCompanyAccessId,
      selectedCompanyIds.toList(growable: false),
    );
    defaultBranchAccessId = _resolveDefaultId(
      defaultBranchAccessId,
      selectedBranchIds.toList(growable: false),
    );
    defaultLocationAccessId = _resolveDefaultId(
      defaultLocationAccessId,
      selectedLocationIds.toList(growable: false),
    );
    defaultWarehouseAccessId = _resolveDefaultId(
      defaultWarehouseAccessId,
      selectedWarehouseIds.toList(growable: false),
    );
  }

  int _selectionState(
    Set<int> descendants,
    Set<int> selectedDescendants, {
    required bool explicitSelected,
  }) {
    if (descendants.isEmpty) {
      return explicitSelected ? 2 : 0;
    }

    final selectedCount = descendants
        .where(selectedDescendants.contains)
        .length;
    if (selectedCount == 0) {
      return explicitSelected ? 1 : 0;
    }
    if (selectedCount == descendants.length) {
      return 2;
    }
    return 1;
  }

  void _applySelection({
    required bool shouldSelect,
    required Set<int> companyIds,
    required Set<int> branchIds,
    required Set<int> locationIds,
    required Set<int> warehouseIds,
  }) {
    if (shouldSelect) {
      selectedCompanyIds = Set<int>.from(selectedCompanyIds)
        ..addAll(companyIds);
      selectedBranchIds = Set<int>.from(selectedBranchIds)..addAll(branchIds);
      selectedLocationIds = Set<int>.from(selectedLocationIds)
        ..addAll(locationIds);
      selectedWarehouseIds = Set<int>.from(selectedWarehouseIds)
        ..addAll(warehouseIds);
    } else {
      selectedWarehouseIds = Set<int>.from(selectedWarehouseIds)
        ..removeAll(warehouseIds);
      selectedLocationIds = Set<int>.from(selectedLocationIds)
        ..removeAll(locationIds);
      selectedBranchIds = Set<int>.from(selectedBranchIds)
        ..removeAll(branchIds);
      selectedCompanyIds = Set<int>.from(selectedCompanyIds)
        ..removeAll(companyIds);
    }

    normalizeAccessTree();
    update();
  }

  int? _resolveDefaultId(int? currentId, List<int> ids) {
    if (ids.isEmpty) {
      return null;
    }
    if (currentId != null && ids.contains(currentId)) {
      return currentId;
    }
    final sortedIds = List<int>.from(ids)..sort();
    return sortedIds.first;
  }

  Map<String, bool> _locationFlagsFor(int locationId) {
    return locationAccessFlags[locationId] ??
        const <String, bool>{
          'can_bill': true,
          'can_purchase': true,
          'can_stock_entry': true,
          'can_accounts_entry': true,
          'can_hr_entry': true,
        };
  }

  Map<String, bool> _warehouseFlagsFor(int warehouseId) {
    return warehouseAccessFlags[warehouseId] ??
        const <String, bool>{
          'can_view_stock': true,
          'can_stock_in': true,
          'can_stock_out': true,
          'can_transfer': true,
          'can_adjust': true,
        };
  }

  String permissionRightsSummary(UserPermissionModel permission) {
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

  int? firstOrNull(List<int> values) => values.isEmpty ? null : values.first;
}
