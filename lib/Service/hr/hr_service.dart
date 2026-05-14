import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/common/erp_record_model.dart';
import '../../model/hr/attendance_record_model.dart';
import '../../model/hr/department_model.dart';
import '../../model/hr/designation_model.dart';
import '../../model/hr/employee_account_model.dart';
import '../../model/hr/employee_model.dart';
import '../../model/hr/employee_salary_structure_model.dart';
import '../../model/hr/expense_claim_model.dart';
import '../../model/hr/leave_request_model.dart';
import '../../model/hr/leave_type_model.dart';
import '../../model/hr/payroll_run_model.dart';
import '../../model/hr/payslip_model.dart';
import '../base/erp_module_service.dart';

class HrService extends ErpModuleService {
  HrService({super.apiClient});

  Future<PaginatedResponse<ErpRecordModel>> statutoryProfiles({
    Map<String, dynamic>? filters,
  }) =>
      paginated<ErpRecordModel>(
        '/hr/statutory-profiles',
        filters: filters,
        fromJson: ErpRecordModel.fromJson,
      );

  Future<ApiResponse<ErpRecordModel>> statutoryProfile(int id) =>
      object<ErpRecordModel>(
        '/hr/statutory-profiles/$id',
        fromJson: ErpRecordModel.fromJson,
      );

  Future<ApiResponse<ErpRecordModel>> createStatutoryProfile(
    Map<String, dynamic> body,
  ) =>
      createModel<ErpRecordModel>(
        '/hr/statutory-profiles',
        body,
        fromJson: ErpRecordModel.fromJson,
      );

  Future<ApiResponse<ErpRecordModel>> updateStatutoryProfile(
    int id,
    Map<String, dynamic> body,
  ) =>
      updateModel<ErpRecordModel>(
        '/hr/statutory-profiles/$id',
        body,
        fromJson: ErpRecordModel.fromJson,
      );

  Future<ApiResponse<dynamic>> deleteStatutoryProfile(int id) =>
      destroy('/hr/statutory-profiles/$id');

  Future<PaginatedResponse<DepartmentModel>> departments({
    Map<String, dynamic>? filters,
  }) => paginated<DepartmentModel>(
    '/hr/departments',
    filters: filters,
    fromJson: DepartmentModel.fromJson,
  );

  Future<ApiResponse<DepartmentModel>> department(int id) =>
      object<DepartmentModel>(
        '/hr/departments/$id',
        fromJson: DepartmentModel.fromJson,
      );

  Future<ApiResponse<DepartmentModel>> createDepartment(DepartmentModel body) =>
      createModel<DepartmentModel>(
        '/hr/departments',
        body,
        fromJson: DepartmentModel.fromJson,
      );

  Future<ApiResponse<DepartmentModel>> updateDepartment(
    int id,
    DepartmentModel body,
  ) => updateModel<DepartmentModel>(
    '/hr/departments/$id',
    body,
    fromJson: DepartmentModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteDepartment(int id) =>
      destroy('/hr/departments/$id');

  Future<PaginatedResponse<DesignationModel>> designations({
    Map<String, dynamic>? filters,
  }) => paginated<DesignationModel>(
    '/hr/designations',
    filters: filters,
    fromJson: DesignationModel.fromJson,
  );

  Future<ApiResponse<DesignationModel>> designation(int id) =>
      object<DesignationModel>(
        '/hr/designations/$id',
        fromJson: DesignationModel.fromJson,
      );

  Future<ApiResponse<DesignationModel>> createDesignation(
    DesignationModel body,
  ) => createModel<DesignationModel>(
    '/hr/designations',
    body,
    fromJson: DesignationModel.fromJson,
  );

  Future<ApiResponse<DesignationModel>> updateDesignation(
    int id,
    DesignationModel body,
  ) => updateModel<DesignationModel>(
    '/hr/designations/$id',
    body,
    fromJson: DesignationModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteDesignation(int id) =>
      destroy('/hr/designations/$id');

  Future<PaginatedResponse<EmployeeModel>> employees({
    Map<String, dynamic>? filters,
  }) => paginated<EmployeeModel>(
    '/hr/employees',
    filters: filters,
    fromJson: EmployeeModel.fromJson,
  );

  Future<ApiResponse<EmployeeModel>> employee(int id) => object<EmployeeModel>(
    '/hr/employees/$id',
    fromJson: EmployeeModel.fromJson,
  );

  Future<ApiResponse<List<EmployeeAccountModel>>> employeeAccounts(int id) =>
      collection<EmployeeAccountModel>(
        '/hr/employees/$id/accounts',
        fromJson: EmployeeAccountModel.fromJson,
      );

  Future<ApiResponse<List<EmployeeSalaryStructureModel>>>
  employeeSalaryStructures(int id) => collection<EmployeeSalaryStructureModel>(
    '/hr/employees/$id/salary-structures',
    fromJson: EmployeeSalaryStructureModel.fromJson,
  );

  Future<ApiResponse<EmployeeModel>> createEmployee(EmployeeModel body) =>
      createModel<EmployeeModel>(
        '/hr/employees',
        body,
        fromJson: EmployeeModel.fromJson,
      );

  Future<ApiResponse<EmployeeModel>> updateEmployee(
    int id,
    EmployeeModel body,
  ) => updateModel<EmployeeModel>(
    '/hr/employees/$id',
    body,
    fromJson: EmployeeModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteEmployee(int id) =>
      destroy('/hr/employees/$id');

  Future<PaginatedResponse<AttendanceRecordModel>> attendance({
    Map<String, dynamic>? filters,
  }) => paginated<AttendanceRecordModel>(
    '/hr/attendance',
    filters: filters,
    fromJson: AttendanceRecordModel.fromJson,
  );

  Future<ApiResponse<AttendanceRecordModel>> attendanceRecord(int id) =>
      object<AttendanceRecordModel>(
        '/hr/attendance/$id',
        fromJson: AttendanceRecordModel.fromJson,
      );

  Future<ApiResponse<AttendanceRecordModel>> createAttendance(
    AttendanceRecordModel body,
  ) => createModel<AttendanceRecordModel>(
    '/hr/attendance',
    body,
    fromJson: AttendanceRecordModel.fromJson,
  );

  Future<ApiResponse<AttendanceRecordModel>> updateAttendance(
    int id,
    AttendanceRecordModel body,
  ) => updateModel<AttendanceRecordModel>(
    '/hr/attendance/$id',
    body,
    fromJson: AttendanceRecordModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteAttendance(int id) =>
      destroy('/hr/attendance/$id');

  Future<PaginatedResponse<LeaveTypeModel>> leaveTypes({
    Map<String, dynamic>? filters,
  }) => paginated<LeaveTypeModel>(
    '/hr/leave-types',
    filters: filters,
    fromJson: LeaveTypeModel.fromJson,
  );

  Future<ApiResponse<LeaveTypeModel>> leaveType(int id) =>
      object<LeaveTypeModel>(
        '/hr/leave-types/$id',
        fromJson: LeaveTypeModel.fromJson,
      );

  Future<ApiResponse<LeaveTypeModel>> createLeaveType(LeaveTypeModel body) =>
      createModel<LeaveTypeModel>(
        '/hr/leave-types',
        body,
        fromJson: LeaveTypeModel.fromJson,
      );

  Future<ApiResponse<LeaveTypeModel>> updateLeaveType(
    int id,
    LeaveTypeModel body,
  ) => updateModel<LeaveTypeModel>(
    '/hr/leave-types/$id',
    body,
    fromJson: LeaveTypeModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteLeaveType(int id) =>
      destroy('/hr/leave-types/$id');

  Future<PaginatedResponse<LeaveRequestModel>> leaveRequests({
    Map<String, dynamic>? filters,
  }) => paginated<LeaveRequestModel>(
    '/hr/leave-requests',
    filters: filters,
    fromJson: LeaveRequestModel.fromJson,
  );

  Future<ApiResponse<LeaveRequestModel>> leaveRequest(int id) =>
      object<LeaveRequestModel>(
        '/hr/leave-requests/$id',
        fromJson: LeaveRequestModel.fromJson,
      );

  Future<ApiResponse<LeaveRequestModel>> createLeaveRequest(
    LeaveRequestModel body,
  ) => createModel<LeaveRequestModel>(
    '/hr/leave-requests',
    body,
    fromJson: LeaveRequestModel.fromJson,
  );

  Future<ApiResponse<LeaveRequestModel>> updateLeaveRequest(
    int id,
    LeaveRequestModel body,
  ) => updateModel<LeaveRequestModel>(
    '/hr/leave-requests/$id',
    body,
    fromJson: LeaveRequestModel.fromJson,
  );

  Future<ApiResponse<LeaveRequestModel>> approveLeaveRequest(
    int id,
    LeaveRequestModel body,
  ) => actionModel<LeaveRequestModel>(
    '/hr/leave-requests/$id/approve',
    body: body,
    fromJson: LeaveRequestModel.fromJson,
  );

  Future<ApiResponse<LeaveRequestModel>> rejectLeaveRequest(
    int id,
    LeaveRequestModel body,
  ) => actionModel<LeaveRequestModel>(
    '/hr/leave-requests/$id/reject',
    body: body,
    fromJson: LeaveRequestModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteLeaveRequest(int id) =>
      destroy('/hr/leave-requests/$id');

  Future<PaginatedResponse<PayrollRunModel>> payrollRuns({
    Map<String, dynamic>? filters,
  }) => paginated<PayrollRunModel>(
    '/hr/payroll-runs',
    filters: filters,
    fromJson: PayrollRunModel.fromJson,
  );

  Future<ApiResponse<PayrollRunModel>> payrollRun(int id) =>
      object<PayrollRunModel>(
        '/hr/payroll-runs/$id',
        fromJson: PayrollRunModel.fromJson,
      );

  Future<ApiResponse<PayrollRunModel>> createPayrollRun(PayrollRunModel body) =>
      createModel<PayrollRunModel>(
        '/hr/payroll-runs',
        body,
        fromJson: PayrollRunModel.fromJson,
      );

  Future<ApiResponse<PayrollRunModel>> updatePayrollRun(
    int id,
    PayrollRunModel body,
  ) => updateModel<PayrollRunModel>(
    '/hr/payroll-runs/$id',
    body,
    fromJson: PayrollRunModel.fromJson,
  );

  Future<ApiResponse<PayrollRunModel>> processPayrollRun(
    int id,
    PayrollRunModel body,
  ) => actionModel<PayrollRunModel>(
    '/hr/payroll-runs/$id/process',
    body: body,
    fromJson: PayrollRunModel.fromJson,
  );

  Future<ApiResponse<PayrollRunModel>> postPayrollRun(
    int id,
    PayrollRunModel body,
  ) => actionModel<PayrollRunModel>(
    '/hr/payroll-runs/$id/post',
    body: body,
    fromJson: PayrollRunModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deletePayrollRun(int id) =>
      destroy('/hr/payroll-runs/$id');

  Future<PaginatedResponse<PayslipModel>> payslips({
    Map<String, dynamic>? filters,
  }) => paginated<PayslipModel>(
    '/hr/payslips',
    filters: filters,
    fromJson: PayslipModel.fromJson,
  );

  Future<ApiResponse<PayslipModel>> payslip(int id) =>
      object<PayslipModel>('/hr/payslips/$id', fromJson: PayslipModel.fromJson);

  Future<PaginatedResponse<ExpenseClaimModel>> expenseClaims({
    Map<String, dynamic>? filters,
  }) => paginated<ExpenseClaimModel>(
    '/hr/expense-claims',
    filters: filters,
    fromJson: ExpenseClaimModel.fromJson,
  );

  Future<ApiResponse<Map<String, dynamic>>> expenseClaimsLinkedEmployee({
    required int companyId,
  }) =>
      client.get<Map<String, dynamic>>(
        '/hr/linked-employee',
        queryParameters: <String, dynamic>{'company_id': companyId},
        fromData: (dynamic json) {
          if (json is Map<String, dynamic>) {
            return json;
          }
          if (json is Map) {
            return Map<String, dynamic>.from(json);
          }
          return <String, dynamic>{};
        },
      );

  Future<ApiResponse<ExpenseClaimModel>> expenseClaim(int id) =>
      object<ExpenseClaimModel>(
        '/hr/expense-claims/$id',
        fromJson: ExpenseClaimModel.fromJson,
      );

  Future<ApiResponse<ExpenseClaimModel>> createExpenseClaim(
    ExpenseClaimModel body,
  ) => createModel<ExpenseClaimModel>(
    '/hr/expense-claims',
    body,
    fromJson: ExpenseClaimModel.fromJson,
  );

  Future<ApiResponse<ExpenseClaimModel>> updateExpenseClaim(
    int id,
    ExpenseClaimModel body,
  ) => updateModel<ExpenseClaimModel>(
    '/hr/expense-claims/$id',
    body,
    fromJson: ExpenseClaimModel.fromJson,
  );

  Future<ApiResponse<ExpenseClaimModel>> applyExpenseClaim(
    int id,
    ExpenseClaimModel body,
  ) => actionModel<ExpenseClaimModel>(
    '/hr/expense-claims/$id/apply',
    body: body,
    fromJson: ExpenseClaimModel.fromJson,
  );

  Future<ApiResponse<ExpenseClaimModel>> approveExpenseClaim(
    int id,
    ExpenseClaimModel body,
  ) => actionModel<ExpenseClaimModel>(
    '/hr/expense-claims/$id/approve',
    body: body,
    fromJson: ExpenseClaimModel.fromJson,
  );

  Future<ApiResponse<ExpenseClaimModel>> rejectExpenseClaim(
    int id,
    ExpenseClaimModel body,
  ) => actionModel<ExpenseClaimModel>(
    '/hr/expense-claims/$id/reject',
    body: body,
    fromJson: ExpenseClaimModel.fromJson,
  );

  Future<ApiResponse<ExpenseClaimModel>> cancelExpenseClaim(
    int id,
    ExpenseClaimModel body,
  ) => actionModel<ExpenseClaimModel>(
    '/hr/expense-claims/$id/cancel',
    body: body,
    fromJson: ExpenseClaimModel.fromJson,
  );

  Future<ApiResponse<ExpenseClaimModel>> reimburseExpenseClaim(
    int id,
    ExpenseClaimModel body,
  ) => actionModel<ExpenseClaimModel>(
    '/hr/expense-claims/$id/reimburse',
    body: body,
    fromJson: ExpenseClaimModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteExpenseClaim(int id) =>
      destroy('/hr/expense-claims/$id');
}
