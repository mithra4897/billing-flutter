import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../core/storage/session_storage.dart';
import '../../model/admin/permission_model.dart';
import '../../model/admin/role_model.dart';
import '../../model/admin/user_model.dart';
import '../../model/auth/auth_context_model.dart';
import '../../model/auth/auth_user_model.dart';
import '../../model/auth/change_password_request_model.dart';
import '../../model/auth/login_history_model.dart';
import '../../model/auth/login_request_model.dart';
import '../../model/auth/login_response_model.dart';
import '../../model/auth/role_permission_summary_model.dart';
import '../../model/auth/role_permission_sync_request_model.dart';
import '../../model/auth/user_branches_sync_request_model.dart';
import '../../model/auth/user_companies_sync_request_model.dart';
import '../../model/auth/user_locations_sync_request_model.dart';
import '../../model/auth/user_roles_sync_request_model.dart';
import '../../model/auth/user_warehouses_sync_request_model.dart';
import '../base/erp_module_service.dart';

class AuthService extends ErpModuleService {
  AuthService({super.apiClient});

  Future<ApiResponse<LoginResponseModel>> login(
    LoginRequestModel request,
  ) async {
    final response = await client.post<LoginResponseModel>(
      ApiEndpoints.login,
      body: request.toJson(),
      fromData: (json) =>
          LoginResponseModel.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await SessionStorage.saveSession(
        token: response.data!.accessToken,
        tokenType: response.data!.tokenType,
        expiresIn: response.data!.expiresIn,
      );
    }

    return response;
  }

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

  Future<ApiResponse<dynamic>> logout() async {
    final response = await client.post<dynamic>(ApiEndpoints.logout);
    await SessionStorage.clear();
    return response;
  }

  Future<ApiResponse<dynamic>> refresh() => actionDynamic('/auth/refresh');
  Future<ApiResponse<dynamic>> changePassword(
    ChangePasswordRequestModel body,
  ) => actionDynamic('/auth/change-password', body: body);
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
  Future<ApiResponse<UserModel>> resetUserPassword(int id, UserModel body) =>
      actionModel(
        '/users/$id/reset-password',
        body: body,
        fromJson: UserModel.fromJson,
      );
  Future<ApiResponse<UserModel>> userAccessSummary(int id) =>
      object('/users/$id/access-summary', fromJson: UserModel.fromJson);
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
