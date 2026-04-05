import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/common/erp_record_model.dart';
import '../base/erp_module_service.dart';

class HrService extends ErpModuleService {
  HrService({super.apiClient});

  Future<PaginatedResponse<ErpRecordModel>> departments({
    Map<String, dynamic>? filters,
  }) => index('/hr/departments', filters: filters);
  Future<ApiResponse<ErpRecordModel>> department(int id) =>
      show('/hr/departments/$id');
  Future<ApiResponse<ErpRecordModel>> createDepartment(ErpRecordModel body) =>
      store('/hr/departments', body);
  Future<ApiResponse<ErpRecordModel>> updateDepartment(
    int id,
    ErpRecordModel body,
  ) => update('/hr/departments/$id', body);
  Future<ApiResponse<dynamic>> deleteDepartment(int id) =>
      destroy('/hr/departments/$id');

  Future<PaginatedResponse<ErpRecordModel>> designations({
    Map<String, dynamic>? filters,
  }) => index('/hr/designations', filters: filters);
  Future<ApiResponse<ErpRecordModel>> designation(int id) =>
      show('/hr/designations/$id');
  Future<ApiResponse<ErpRecordModel>> createDesignation(ErpRecordModel body) =>
      store('/hr/designations', body);
  Future<ApiResponse<ErpRecordModel>> updateDesignation(
    int id,
    ErpRecordModel body,
  ) => update('/hr/designations/$id', body);
  Future<ApiResponse<dynamic>> deleteDesignation(int id) =>
      destroy('/hr/designations/$id');

  Future<PaginatedResponse<ErpRecordModel>> employees({
    Map<String, dynamic>? filters,
  }) => index('/hr/employees', filters: filters);
  Future<ApiResponse<ErpRecordModel>> employee(int id) =>
      show('/hr/employees/$id');
  Future<ApiResponse<ErpRecordModel>> employeeAccounts(int id) =>
      show('/hr/employees/$id/accounts');
  Future<ApiResponse<ErpRecordModel>> employeeSalaryStructures(int id) =>
      show('/hr/employees/$id/salary-structures');
  Future<ApiResponse<ErpRecordModel>> createEmployee(ErpRecordModel body) =>
      store('/hr/employees', body);
  Future<ApiResponse<ErpRecordModel>> updateEmployee(
    int id,
    ErpRecordModel body,
  ) => update('/hr/employees/$id', body);
  Future<ApiResponse<dynamic>> deleteEmployee(int id) =>
      destroy('/hr/employees/$id');

  Future<PaginatedResponse<ErpRecordModel>> attendance({
    Map<String, dynamic>? filters,
  }) => index('/hr/attendance', filters: filters);
  Future<ApiResponse<ErpRecordModel>> attendanceRecord(int id) =>
      show('/hr/attendance/$id');
  Future<ApiResponse<ErpRecordModel>> createAttendance(ErpRecordModel body) =>
      store('/hr/attendance', body);
  Future<ApiResponse<ErpRecordModel>> updateAttendance(
    int id,
    ErpRecordModel body,
  ) => update('/hr/attendance/$id', body);
  Future<ApiResponse<dynamic>> deleteAttendance(int id) =>
      destroy('/hr/attendance/$id');

  Future<PaginatedResponse<ErpRecordModel>> leaveTypes({
    Map<String, dynamic>? filters,
  }) => index('/hr/leave-types', filters: filters);
  Future<ApiResponse<ErpRecordModel>> leaveType(int id) =>
      show('/hr/leave-types/$id');
  Future<ApiResponse<ErpRecordModel>> createLeaveType(ErpRecordModel body) =>
      store('/hr/leave-types', body);
  Future<ApiResponse<ErpRecordModel>> updateLeaveType(
    int id,
    ErpRecordModel body,
  ) => update('/hr/leave-types/$id', body);
  Future<ApiResponse<dynamic>> deleteLeaveType(int id) =>
      destroy('/hr/leave-types/$id');

  Future<PaginatedResponse<ErpRecordModel>> leaveRequests({
    Map<String, dynamic>? filters,
  }) => index('/hr/leave-requests', filters: filters);
  Future<ApiResponse<ErpRecordModel>> leaveRequest(int id) =>
      show('/hr/leave-requests/$id');
  Future<ApiResponse<ErpRecordModel>> createLeaveRequest(ErpRecordModel body) =>
      store('/hr/leave-requests', body);
  Future<ApiResponse<ErpRecordModel>> updateLeaveRequest(
    int id,
    ErpRecordModel body,
  ) => update('/hr/leave-requests/$id', body);
  Future<ApiResponse<ErpRecordModel>> approveLeaveRequest(
    int id,
    ErpRecordModel body,
  ) => action('/hr/leave-requests/$id/approve', body: body);
  Future<ApiResponse<ErpRecordModel>> rejectLeaveRequest(
    int id,
    ErpRecordModel body,
  ) => action('/hr/leave-requests/$id/reject', body: body);
  Future<ApiResponse<dynamic>> deleteLeaveRequest(int id) =>
      destroy('/hr/leave-requests/$id');

  Future<PaginatedResponse<ErpRecordModel>> payrollRuns({
    Map<String, dynamic>? filters,
  }) => index('/hr/payroll-runs', filters: filters);
  Future<ApiResponse<ErpRecordModel>> payrollRun(int id) =>
      show('/hr/payroll-runs/$id');
  Future<ApiResponse<ErpRecordModel>> createPayrollRun(ErpRecordModel body) =>
      store('/hr/payroll-runs', body);
  Future<ApiResponse<ErpRecordModel>> updatePayrollRun(
    int id,
    ErpRecordModel body,
  ) => update('/hr/payroll-runs/$id', body);
  Future<ApiResponse<ErpRecordModel>> processPayrollRun(
    int id,
    ErpRecordModel body,
  ) => action('/hr/payroll-runs/$id/process', body: body);
  Future<ApiResponse<ErpRecordModel>> postPayrollRun(
    int id,
    ErpRecordModel body,
  ) => action('/hr/payroll-runs/$id/post', body: body);
  Future<ApiResponse<dynamic>> deletePayrollRun(int id) =>
      destroy('/hr/payroll-runs/$id');

  Future<PaginatedResponse<ErpRecordModel>> payslips({
    Map<String, dynamic>? filters,
  }) => index('/hr/payslips', filters: filters);
  Future<ApiResponse<ErpRecordModel>> payslip(int id) =>
      show('/hr/payslips/$id');

  Future<PaginatedResponse<ErpRecordModel>> expenseClaims({
    Map<String, dynamic>? filters,
  }) => index('/hr/expense-claims', filters: filters);
  Future<ApiResponse<ErpRecordModel>> expenseClaim(int id) =>
      show('/hr/expense-claims/$id');
  Future<ApiResponse<ErpRecordModel>> createExpenseClaim(ErpRecordModel body) =>
      store('/hr/expense-claims', body);
  Future<ApiResponse<ErpRecordModel>> updateExpenseClaim(
    int id,
    ErpRecordModel body,
  ) => update('/hr/expense-claims/$id', body);
  Future<ApiResponse<ErpRecordModel>> approveExpenseClaim(
    int id,
    ErpRecordModel body,
  ) => action('/hr/expense-claims/$id/approve', body: body);
  Future<ApiResponse<ErpRecordModel>> reimburseExpenseClaim(
    int id,
    ErpRecordModel body,
  ) => action('/hr/expense-claims/$id/reimburse', body: body);
  Future<ApiResponse<dynamic>> deleteExpenseClaim(int id) =>
      destroy('/hr/expense-claims/$id');
}
