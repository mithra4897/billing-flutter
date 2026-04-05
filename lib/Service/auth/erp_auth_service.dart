import '../../core/models/api_response.dart';
import '../../features/auth/models/auth_context_model.dart';
import '../../features/auth/models/auth_user_model.dart';
import '../../features/auth/models/login_request_model.dart';
import '../../features/auth/models/login_response_model.dart';
import '../../features/auth/services/auth_service.dart';
import '../base/erp_module_service.dart';

class ErpAuthService extends ErpModuleService {
  ErpAuthService({super.apiClient})
    : _typed = AuthService(apiClient: apiClient);

  final AuthService _typed;

  Future<ApiResponse<LoginResponseModel>> login(LoginRequestModel request) =>
      _typed.login(request);
  Future<ApiResponse<AuthUserModel>> me() => _typed.getProfile();
  Future<ApiResponse<AuthContextModel>> context() => _typed.getContext();
  Future<ApiResponse<dynamic>> logout() => _typed.logout();

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
