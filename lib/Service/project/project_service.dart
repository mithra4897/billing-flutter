import '../base/erp_module_service.dart';

class ProjectService extends ErpModuleService {
  ProjectService({super.apiClient});

  Future projects({Map<String, dynamic>? filters}) =>
      index('/projects', filters: filters);
  Future project(int id) => show('/projects/$id');
  Future createProject(Map<String, dynamic> body) => store('/projects', body);
  Future updateProject(int id, Map<String, dynamic> body) =>
      update('/projects/$id', body);
  Future deleteProject(int id) => destroy('/projects/$id');
  Future projectDashboard(int id) => show('/projects/$id/dashboard');

  Future createTask(int projectId, Map<String, dynamic> body) =>
      store('/projects/$projectId/tasks', body);
  Future updateTask(int id, Map<String, dynamic> body) =>
      update('/projects/tasks/$id', body);
  Future deleteTask(int id) => destroy('/projects/tasks/$id');

  Future createMilestone(int projectId, Map<String, dynamic> body) =>
      store('/projects/$projectId/milestones', body);
  Future updateMilestone(int id, Map<String, dynamic> body) =>
      update('/projects/milestones/$id', body);
  Future deleteMilestone(int id) => destroy('/projects/milestones/$id');

  Future createTimesheet(int projectId, Map<String, dynamic> body) =>
      store('/projects/$projectId/timesheets', body);
  Future updateTimesheet(int id, Map<String, dynamic> body) =>
      update('/projects/timesheets/$id', body);
  Future deleteTimesheet(int id) => destroy('/projects/timesheets/$id');

  Future createExpense(int projectId, Map<String, dynamic> body) =>
      store('/projects/$projectId/expenses', body);
  Future updateExpense(int id, Map<String, dynamic> body) =>
      update('/projects/expenses/$id', body);
  Future deleteExpense(int id) => destroy('/projects/expenses/$id');

  Future createResourceUsage(int projectId, Map<String, dynamic> body) =>
      store('/projects/$projectId/resources', body);
  Future updateResourceUsage(int id, Map<String, dynamic> body) =>
      update('/projects/resources/$id', body);
  Future deleteResourceUsage(int id) => destroy('/projects/resources/$id');

  Future createVendorWork(int projectId, Map<String, dynamic> body) =>
      store('/projects/$projectId/vendor-works', body);
  Future updateVendorWork(int id, Map<String, dynamic> body) =>
      update('/projects/vendor-works/$id', body);
  Future deleteVendorWork(int id) => destroy('/projects/vendor-works/$id');

  Future createBilling(int projectId, Map<String, dynamic> body) =>
      store('/projects/$projectId/billings', body);
  Future updateBilling(int id, Map<String, dynamic> body) =>
      update('/projects/billings/$id', body);
  Future deleteBilling(int id) => destroy('/projects/billings/$id');
}
