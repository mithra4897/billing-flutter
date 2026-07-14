import '../../screen.dart';

class AuthService extends ErpModuleService {
  AuthService({super.apiClient});

  Future<ApiResponse<LoginResponseModel>> login(
    LoginRequestModel request,
  ) async {
    return client.post<LoginResponseModel>(
      ApiEndpoints.login,
      body: request.toJson(),
      fromData: (json) =>
          LoginResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> forgotPassword(
    ForgotPasswordRequestModel request,
  ) => actionDynamic(ApiEndpoints.forgotPassword, body: request);

  Future<ApiResponse<dynamic>> resetPassword(
    PublicResetPasswordRequestModel request,
  ) => actionDynamic(ApiEndpoints.resetPassword, body: request);

  Future<ApiResponse<AuthUserModel>> me() {
    return client.get<AuthUserModel>(
      ApiEndpoints.me,
      fromData: (json) => AuthUserModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AuthContextModel>> context() {
    return client.get<AuthContextModel>(
      ApiEndpoints.authContext,
      fromData: (json) =>
          AuthContextModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<UserModel>> profile() =>
      object('/auth/profile', fromJson: UserModel.fromJson);

  Future<ApiResponse<UserModel>> updateProfile(UserModel body) =>
      updateModel('/auth/profile', body, fromJson: UserModel.fromJson);

  Future<ApiResponse<dynamic>> logout() async {
    return client.post<dynamic>(ApiEndpoints.logout);
  }

  Future<ApiResponse<LoginResponseModel>> refresh() {
    return client.post<LoginResponseModel>(
      ApiEndpoints.refresh,
      fromData: (json) =>
          LoginResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> changePassword(
    ChangePasswordRequestModel body,
  ) => actionDynamic('/auth/change-password', body: body);

  Future<String?> nextEmployeeCode({String prefix = 'EMP'}) async {
    final response = await client.get<Map<String, dynamic>>(
      '/auth/users/next-employee-code',
      queryParameters: prefix.trim().isEmpty
          ? null
          : <String, dynamic>{'prefix': prefix.trim()},
      fromData: (json) =>
          json is Map<String, dynamic> ? json : <String, dynamic>{},
    );

    return response.data?['employee_code']?.toString();
  }

  Future<PaginatedResponse<ModuleModel>> modules({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/auth/modules',
    filters: filters,
    fromJson: ModuleModel.fromJson,
  );

  Future<ApiResponse<ModuleModel>> module(int id) =>
      object('/auth/modules/$id', fromJson: ModuleModel.fromJson);

  Future<ApiResponse<ModuleModel>> createModule(ModuleModel body) =>
      createModel('/auth/modules', body, fromJson: ModuleModel.fromJson);

  Future<ApiResponse<ModuleModel>> updateModule(int id, ModuleModel body) =>
      updateModel('/auth/modules/$id', body, fromJson: ModuleModel.fromJson);

  Future<ApiResponse<ModuleModel>> changeModuleStatus(
    int id,
    ModuleModel body,
  ) => patchModel(
    '/auth/modules/$id/status',
    body,
    fromJson: ModuleModel.fromJson,
  );

  Future<ApiResponse<List<ModuleModel>>> menuPreferences() =>
      collection('/auth/menu-preferences', fromJson: ModuleModel.fromJson);

  Future<ApiResponse<List<ModuleModel>>> syncMenuPreferences(
    List<ModuleModel> modules,
  ) => client.post<List<ModuleModel>>(
    '/auth/menu-preferences/sync',
    body: {
      'modules': modules.map((item) => item.toJson()).toList(growable: false),
    },
    fromData: (json) {
      if (json is! List) {
        return <ModuleModel>[];
      }

      return json
          .whereType<Map<String, dynamic>>()
          .map(ModuleModel.fromJson)
          .toList(growable: false);
    },
  );

  Future<PaginatedResponse<LoginHistoryModel>> loginHistory({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/auth/login-history',
    filters: filters,
    fromJson: LoginHistoryModel.fromJson,
  );

  Future<PaginatedResponse<RoleModel>> roles({Map<String, dynamic>? filters}) =>
      paginated('/auth/roles', filters: filters, fromJson: RoleModel.fromJson);

  Future<ApiResponse<RoleModel>> role(int id) =>
      object('/auth/roles/$id', fromJson: RoleModel.fromJson);

  Future<ApiResponse<RoleModel>> createRole(RoleModel body) =>
      createModel('/auth/roles', body, fromJson: RoleModel.fromJson);

  Future<ApiResponse<RoleModel>> updateRole(int id, RoleModel body) =>
      updateModel('/auth/roles/$id', body, fromJson: RoleModel.fromJson);

  Future<ApiResponse<RoleModel>> changeRoleStatus(int id, RoleModel body) =>
      patchModel('/auth/roles/$id/status', body, fromJson: RoleModel.fromJson);

  Future<ApiResponse<RolePermissionSummaryModel>> rolePermissions(int roleId) =>
      object(
        '/auth/roles/$roleId/permissions',
        fromJson: RolePermissionSummaryModel.fromJson,
      );

  Future<ApiResponse<dynamic>> syncRolePermissions(
    int roleId,
    RolePermissionSyncRequestModel body,
  ) => actionDynamic('/auth/roles/$roleId/permissions/sync', body: body);

  Future<PaginatedResponse<PermissionModel>> permissions({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/auth/permissions',
    filters: filters,
    fromJson: PermissionModel.fromJson,
  );

  Future<ApiResponse<PermissionModel>> permission(int id) =>
      object('/auth/permissions/$id', fromJson: PermissionModel.fromJson);

  Future<ApiResponse<PermissionModel>> createPermission(PermissionModel body) =>
      createModel(
        '/auth/permissions',
        body,
        fromJson: PermissionModel.fromJson,
      );

  Future<ApiResponse<PermissionModel>> updatePermission(
    int id,
    PermissionModel body,
  ) => updateModel(
    '/auth/permissions/$id',
    body,
    fromJson: PermissionModel.fromJson,
  );

  Future<ApiResponse<PermissionModel>> changePermissionStatus(
    int id,
    PermissionModel body,
  ) => patchModel(
    '/auth/permissions/$id/status',
    body,
    fromJson: PermissionModel.fromJson,
  );

  Future<PaginatedResponse<UserModel>> users({Map<String, dynamic>? filters}) =>
      paginated('/users', filters: filters, fromJson: UserModel.fromJson);

  Future<ApiResponse<UserModel>> user(int id) =>
      object('/users/$id', fromJson: UserModel.fromJson);

  Future<ApiResponse<UserModel>> createUser(UserModel body) =>
      createModel('/users', body, fromJson: UserModel.fromJson);

  Future<ApiResponse<UserModel>> updateUser(int id, UserModel body) =>
      updateModel('/users/$id', body, fromJson: UserModel.fromJson);

  Future<ApiResponse<UserModel>> changeUserStatus(int id, UserModel body) =>
      patchModel('/users/$id/status', body, fromJson: UserModel.fromJson);

  Future<ApiResponse<dynamic>> resetUserPassword(
    int id,
    ResetUserPasswordRequestModel body,
  ) => actionDynamic('/users/$id/reset-password', body: body);

  Future<ApiResponse<UserModel>> userAccessSummary(int id) =>
      object('/users/$id/access-summary', fromJson: UserModel.fromJson);

  Future<ApiResponse<UserPermissionSummaryModel>> userPermissions(int id) =>
      object(
        '/users/$id/permissions',
        fromJson: UserPermissionSummaryModel.fromJson,
      );

  Future<ApiResponse<UserPermissionSummaryModel>> syncUserExtraPermissions(
    int id,
    List<UserPermissionModel> permissions,
  ) => client.post<UserPermissionSummaryModel>(
    '/users/$id/permissions/sync',
    body: {
      'extra_permissions': permissions
          .map((item) => item.toJson())
          .toList(growable: false),
    },
    fromData: (json) =>
        UserPermissionSummaryModel.fromJson(json as Map<String, dynamic>),
  );

  Future<PaginatedResponse<AuditLogModel>> userAuditLogs(
    int id, {
    Map<String, dynamic>? filters,
  }) => paginated(
    '/users/$id/audit-logs',
    filters: filters,
    fromJson: AuditLogModel.fromJson,
  );

  Future<PaginatedResponse<LoginHistoryModel>> userLoginHistory(
    int id, {
    Map<String, dynamic>? filters,
  }) => paginated(
    '/users/$id/login-history',
    filters: filters,
    fromJson: LoginHistoryModel.fromJson,
  );

  Future<ApiResponse<dynamic>> syncUserRoles(
    int id,
    UserRolesSyncRequestModel body,
  ) => actionDynamic('/users/$id/roles/sync', body: body);

  Future<ApiResponse<dynamic>> syncUserCompanies(
    int id,
    UserCompaniesSyncRequestModel body,
  ) => actionDynamic('/users/$id/companies/sync', body: body);

  Future<ApiResponse<dynamic>> syncUserBranches(
    int id,
    UserBranchesSyncRequestModel body,
  ) => actionDynamic('/users/$id/branches/sync', body: body);

  Future<ApiResponse<dynamic>> syncUserLocations(
    int id,
    UserLocationsSyncRequestModel body,
  ) => actionDynamic('/users/$id/locations/sync', body: body);

  Future<ApiResponse<dynamic>> syncUserWarehouses(
    int id,
    UserWarehousesSyncRequestModel body,
  ) => actionDynamic('/users/$id/warehouses/sync', body: body);
}
