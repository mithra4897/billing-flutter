import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/storage/session_storage.dart';
import '../../model/auth/auth_context_model.dart';
import '../../model/auth/auth_user_model.dart';
import '../../model/auth/login_request_model.dart';
import '../../model/auth/login_response_model.dart';
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
  Future<ApiResponse<dynamic>> changePassword(Map<String, dynamic> body) =>
      actionDynamic('/auth/change-password', body: body);
  Future loginHistory({Map<String, dynamic>? filters}) =>
      index('/auth/login-history', filters: filters);

  Future roles({Map<String, dynamic>? filters}) =>
      index('/auth/roles', filters: filters);
  Future role(int id) => show('/auth/roles/$id');
  Future createRole(Map<String, dynamic> body) => store('/auth/roles', body);
  Future updateRole(int id, Map<String, dynamic> body) =>
      update('/auth/roles/$id', body);
  Future changeRoleStatus(int id, Map<String, dynamic> body) =>
      patch('/auth/roles/$id/status', body);
  Future rolePermissions(int roleId) => show('/auth/roles/$roleId/permissions');
  Future syncRolePermissions(int roleId, Map<String, dynamic> body) =>
      action('/auth/roles/$roleId/permissions/sync', body: body);

  Future permissions({Map<String, dynamic>? filters}) =>
      index('/auth/permissions', filters: filters);
  Future permission(int id) => show('/auth/permissions/$id');
  Future createPermission(Map<String, dynamic> body) =>
      store('/auth/permissions', body);
  Future updatePermission(int id, Map<String, dynamic> body) =>
      update('/auth/permissions/$id', body);
  Future changePermissionStatus(int id, Map<String, dynamic> body) =>
      patch('/auth/permissions/$id/status', body);

  Future users({Map<String, dynamic>? filters}) =>
      index('/users', filters: filters);
  Future user(int id) => show('/users/$id');
  Future createUser(Map<String, dynamic> body) => store('/users', body);
  Future updateUser(int id, Map<String, dynamic> body) =>
      update('/users/$id', body);
  Future changeUserStatus(int id, Map<String, dynamic> body) =>
      patch('/users/$id/status', body);
  Future resetUserPassword(int id, Map<String, dynamic> body) =>
      action('/users/$id/reset-password', body: body);
  Future userAccessSummary(int id) => show('/users/$id/access-summary');
  Future syncUserRoles(int id, Map<String, dynamic> body) =>
      action('/users/$id/roles/sync', body: body);
  Future syncUserCompanies(int id, Map<String, dynamic> body) =>
      action('/users/$id/companies/sync', body: body);
  Future syncUserBranches(int id, Map<String, dynamic> body) =>
      action('/users/$id/branches/sync', body: body);
  Future syncUserLocations(int id, Map<String, dynamic> body) =>
      action('/users/$id/locations/sync', body: body);
  Future syncUserWarehouses(int id, Map<String, dynamic> body) =>
      action('/users/$id/warehouses/sync', body: body);
}
