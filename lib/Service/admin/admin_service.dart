import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/admin/permission_model.dart';
import '../../model/admin/role_model.dart';
import '../../model/admin/user_model.dart';
import '../base/erp_module_service.dart';

class AdminService extends ErpModuleService {
  AdminService({super.apiClient});

  Future<PaginatedResponse<UserModel>> users({Map<String, dynamic>? filters}) {
    return paginated(
      '/admin/users',
      filters: filters,
      fromJson: UserModel.fromJson,
    );
  }

  Future<ApiResponse<UserModel>> user(int id) {
    return object('/admin/users/$id', fromJson: UserModel.fromJson);
  }

  Future<ApiResponse<UserModel>> createUser(UserModel user) {
    return createModel('/admin/users', user, fromJson: UserModel.fromJson);
  }

  Future<ApiResponse<UserModel>> updateUser(int id, UserModel user) {
    return updateModel('/admin/users/$id', user, fromJson: UserModel.fromJson);
  }

  Future<ApiResponse<UserModel>> toggleUserStatus(int id, UserModel body) {
    return patchModel(
      '/admin/users/$id/toggle-status',
      body,
      fromJson: UserModel.fromJson,
    );
  }

  Future<PaginatedResponse<RoleModel>> roles({Map<String, dynamic>? filters}) {
    return paginated(
      '/admin/roles',
      filters: filters,
      fromJson: RoleModel.fromJson,
    );
  }

  Future<ApiResponse<RoleModel>> role(int id) {
    return object('/admin/roles/$id', fromJson: RoleModel.fromJson);
  }

  Future<ApiResponse<RoleModel>> createRole(RoleModel role) {
    return createModel('/admin/roles', role, fromJson: RoleModel.fromJson);
  }

  Future<ApiResponse<RoleModel>> updateRole(int id, RoleModel role) {
    return updateModel('/admin/roles/$id', role, fromJson: RoleModel.fromJson);
  }

  Future<ApiResponse<RoleModel>> assignRolePermissions(int id, RoleModel role) {
    return actionModel(
      '/admin/roles/$id/permissions',
      body: role,
      fromJson: RoleModel.fromJson,
    );
  }

  Future<PaginatedResponse<PermissionModel>> permissions({
    Map<String, dynamic>? filters,
  }) {
    return paginated(
      '/admin/permissions',
      filters: filters,
      fromJson: PermissionModel.fromJson,
    );
  }
}
