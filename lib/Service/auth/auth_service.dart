import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../core/storage/session_storage.dart';
import '../../model/admin/permission_model.dart';
import '../../model/admin/role_model.dart';
import '../../model/admin/user_model.dart';
import '../../model/auth/auth_context_model.dart';
import '../../model/auth/auth_user_model.dart';
import '../../model/auth/login_request_model.dart';
import '../../model/auth/login_response_model.dart';
import '../../model/common/erp_record_model.dart';
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
  Future<ApiResponse<dynamic>> changePassword(ErpRecordModel body) =>
      actionDynamic('/auth/change-password', body: body);
  Future<PaginatedResponse<ErpRecordModel>> loginHistory({
    Map<String, dynamic>? filters,
  }) => index('/auth/login-history', filters: filters);

  Future<PaginatedResponse<RoleModel>> roles({Map<String, dynamic>? filters}) =>
      paginated('/auth/roles', filters: filters, fromJson: RoleModel.fromJson);
  Future<ApiResponse<RoleModel>> role(int id) =>
      object('/auth/roles/$id', fromJson: RoleModel.fromJson);
  Future<ApiResponse<RoleModel>> createRole(RoleModel body) =>
      createModel('/auth/roles', body, fromJson: RoleModel.fromJson);
  Future<ApiResponse<RoleModel>> updateRole(int id, RoleModel body) =>
      updateModel('/auth/roles/$id', body, fromJson: RoleModel.fromJson);
  Future<ApiResponse<RoleModel>> changeRoleStatus(
    int id,
    ErpRecordModel body,
  ) => patchModel('/auth/roles/$id/status', body, fromJson: RoleModel.fromJson);
  Future<ApiResponse<ErpRecordModel>> rolePermissions(int roleId) =>
      show('/auth/roles/$roleId/permissions');
  Future<ApiResponse<RoleModel>> syncRolePermissions(
    int roleId,
    RoleModel body,
  ) => actionModel(
    '/auth/roles/$roleId/permissions/sync',
    body: body,
    fromJson: RoleModel.fromJson,
  );

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
    ErpRecordModel body,
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
  Future<ApiResponse<UserModel>> changeUserStatus(
    int id,
    ErpRecordModel body,
  ) => patchModel('/users/$id/status', body, fromJson: UserModel.fromJson);
  Future<ApiResponse<UserModel>> resetUserPassword(
    int id,
    ErpRecordModel body,
  ) => actionModel(
    '/users/$id/reset-password',
    body: body,
    fromJson: UserModel.fromJson,
  );
  Future<ApiResponse<ErpRecordModel>> userAccessSummary(int id) =>
      show('/users/$id/access-summary');
  Future<ApiResponse<UserModel>> syncUserRoles(int id, ErpRecordModel body) =>
      actionModel(
        '/users/$id/roles/sync',
        body: body,
        fromJson: UserModel.fromJson,
      );
  Future<ApiResponse<UserModel>> syncUserCompanies(
    int id,
    ErpRecordModel body,
  ) => actionModel(
    '/users/$id/companies/sync',
    body: body,
    fromJson: UserModel.fromJson,
  );
  Future<ApiResponse<UserModel>> syncUserBranches(
    int id,
    ErpRecordModel body,
  ) => actionModel(
    '/users/$id/branches/sync',
    body: body,
    fromJson: UserModel.fromJson,
  );
  Future<ApiResponse<UserModel>> syncUserLocations(
    int id,
    ErpRecordModel body,
  ) => actionModel(
    '/users/$id/locations/sync',
    body: body,
    fromJson: UserModel.fromJson,
  );
  Future<ApiResponse<UserModel>> syncUserWarehouses(
    int id,
    ErpRecordModel body,
  ) => actionModel(
    '/users/$id/warehouses/sync',
    body: body,
    fromJson: UserModel.fromJson,
  );
}
