import '../base/erp_module_service.dart';

class AdminService extends ErpModuleService {
  AdminService({super.apiClient});

  Future users({Map<String, dynamic>? filters}) =>
      index('/admin/users', filters: filters);
  Future user(int id) => show('/admin/users/$id');
  Future createUser(Map<String, dynamic> body) => store('/admin/users', body);
  Future updateUser(int id, Map<String, dynamic> body) =>
      update('/admin/users/$id', body);
  Future toggleUserStatus(int id, Map<String, dynamic> body) =>
      patch('/admin/users/$id/toggle-status', body);

  Future roles({Map<String, dynamic>? filters}) =>
      index('/admin/roles', filters: filters);
  Future role(int id) => show('/admin/roles/$id');
  Future createRole(Map<String, dynamic> body) => store('/admin/roles', body);
  Future updateRole(int id, Map<String, dynamic> body) =>
      update('/admin/roles/$id', body);
  Future assignRolePermissions(int id, Map<String, dynamic> body) =>
      action('/admin/roles/$id/permissions', body: body);

  Future permissions({Map<String, dynamic>? filters}) =>
      index('/admin/permissions', filters: filters);
}
