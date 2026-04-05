import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/common/erp_record_model.dart';
import '../../model/project/project_billing_model.dart';
import '../../model/project/project_expense_model.dart';
import '../../model/project/project_milestone_model.dart';
import '../../model/project/project_model.dart';
import '../../model/project/project_resource_usage_model.dart';
import '../../model/project/project_task_model.dart';
import '../../model/project/project_timesheet_model.dart';
import '../../model/project/project_vendor_work_model.dart';
import '../base/erp_module_service.dart';

class ProjectService extends ErpModuleService {
  ProjectService({super.apiClient});

  Future<PaginatedResponse<ProjectModel>> projects({
    Map<String, dynamic>? filters,
  }) {
    return paginated(
      '/projects',
      filters: filters,
      fromJson: ProjectModel.fromJson,
    );
  }

  Future<ApiResponse<ProjectModel>> project(int id) {
    return object('/projects/$id', fromJson: ProjectModel.fromJson);
  }

  Future<ApiResponse<ProjectModel>> createProject(ProjectModel project) {
    return createModel('/projects', project, fromJson: ProjectModel.fromJson);
  }

  Future<ApiResponse<ProjectModel>> updateProject(
    int id,
    ProjectModel project,
  ) {
    return updateModel(
      '/projects/$id',
      project,
      fromJson: ProjectModel.fromJson,
    );
  }

  Future<ApiResponse<dynamic>> deleteProject(int id) =>
      destroy('/projects/$id');

  Future<ApiResponse<ErpRecordModel>> projectDashboard(int id) {
    return show('/projects/$id/dashboard');
  }

  Future<ApiResponse<ProjectTaskModel>> createTask(
    int projectId,
    ProjectTaskModel task,
  ) {
    return createModel(
      '/projects/$projectId/tasks',
      task,
      fromJson: ProjectTaskModel.fromJson,
    );
  }

  Future<ApiResponse<ProjectTaskModel>> updateTask(
    int id,
    ProjectTaskModel task,
  ) {
    return updateModel(
      '/projects/tasks/$id',
      task,
      fromJson: ProjectTaskModel.fromJson,
    );
  }

  Future<ApiResponse<dynamic>> deleteTask(int id) =>
      destroy('/projects/tasks/$id');

  Future<ApiResponse<ProjectMilestoneModel>> createMilestone(
    int projectId,
    ProjectMilestoneModel milestone,
  ) {
    return createModel(
      '/projects/$projectId/milestones',
      milestone,
      fromJson: ProjectMilestoneModel.fromJson,
    );
  }

  Future<ApiResponse<ProjectMilestoneModel>> updateMilestone(
    int id,
    ProjectMilestoneModel milestone,
  ) {
    return updateModel(
      '/projects/milestones/$id',
      milestone,
      fromJson: ProjectMilestoneModel.fromJson,
    );
  }

  Future<ApiResponse<dynamic>> deleteMilestone(int id) =>
      destroy('/projects/milestones/$id');

  Future<ApiResponse<ProjectTimesheetModel>> createTimesheet(
    int projectId,
    ProjectTimesheetModel timesheet,
  ) {
    return createModel(
      '/projects/$projectId/timesheets',
      timesheet,
      fromJson: ProjectTimesheetModel.fromJson,
    );
  }

  Future<ApiResponse<ProjectTimesheetModel>> updateTimesheet(
    int id,
    ProjectTimesheetModel timesheet,
  ) {
    return updateModel(
      '/projects/timesheets/$id',
      timesheet,
      fromJson: ProjectTimesheetModel.fromJson,
    );
  }

  Future<ApiResponse<dynamic>> deleteTimesheet(int id) =>
      destroy('/projects/timesheets/$id');

  Future<ApiResponse<ProjectExpenseModel>> createExpense(
    int projectId,
    ProjectExpenseModel expense,
  ) {
    return createModel(
      '/projects/$projectId/expenses',
      expense,
      fromJson: ProjectExpenseModel.fromJson,
    );
  }

  Future<ApiResponse<ProjectExpenseModel>> updateExpense(
    int id,
    ProjectExpenseModel expense,
  ) {
    return updateModel(
      '/projects/expenses/$id',
      expense,
      fromJson: ProjectExpenseModel.fromJson,
    );
  }

  Future<ApiResponse<dynamic>> deleteExpense(int id) =>
      destroy('/projects/expenses/$id');

  Future<ApiResponse<ProjectResourceUsageModel>> createResourceUsage(
    int projectId,
    ProjectResourceUsageModel usage,
  ) {
    return createModel(
      '/projects/$projectId/resources',
      usage,
      fromJson: ProjectResourceUsageModel.fromJson,
    );
  }

  Future<ApiResponse<ProjectResourceUsageModel>> updateResourceUsage(
    int id,
    ProjectResourceUsageModel usage,
  ) {
    return updateModel(
      '/projects/resources/$id',
      usage,
      fromJson: ProjectResourceUsageModel.fromJson,
    );
  }

  Future<ApiResponse<dynamic>> deleteResourceUsage(int id) =>
      destroy('/projects/resources/$id');

  Future<ApiResponse<ProjectVendorWorkModel>> createVendorWork(
    int projectId,
    ProjectVendorWorkModel vendorWork,
  ) {
    return createModel(
      '/projects/$projectId/vendor-works',
      vendorWork,
      fromJson: ProjectVendorWorkModel.fromJson,
    );
  }

  Future<ApiResponse<ProjectVendorWorkModel>> updateVendorWork(
    int id,
    ProjectVendorWorkModel vendorWork,
  ) {
    return updateModel(
      '/projects/vendor-works/$id',
      vendorWork,
      fromJson: ProjectVendorWorkModel.fromJson,
    );
  }

  Future<ApiResponse<dynamic>> deleteVendorWork(int id) =>
      destroy('/projects/vendor-works/$id');

  Future<ApiResponse<ProjectBillingModel>> createBilling(
    int projectId,
    ProjectBillingModel billing,
  ) {
    return createModel(
      '/projects/$projectId/billings',
      billing,
      fromJson: ProjectBillingModel.fromJson,
    );
  }

  Future<ApiResponse<ProjectBillingModel>> updateBilling(
    int id,
    ProjectBillingModel billing,
  ) {
    return updateModel(
      '/projects/billings/$id',
      billing,
      fromJson: ProjectBillingModel.fromJson,
    );
  }

  Future<ApiResponse<dynamic>> deleteBilling(int id) =>
      destroy('/projects/billings/$id');
}
