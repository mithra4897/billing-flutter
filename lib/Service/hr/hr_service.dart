import '../base/erp_module_service.dart';

class HrService extends ErpModuleService {
  HrService({super.apiClient});

  Future departments({Map<String, dynamic>? filters}) =>
      index('/hr/departments', filters: filters);
  Future department(int id) => show('/hr/departments/$id');
  Future createDepartment(Map<String, dynamic> body) =>
      store('/hr/departments', body);
  Future updateDepartment(int id, Map<String, dynamic> body) =>
      update('/hr/departments/$id', body);
  Future deleteDepartment(int id) => destroy('/hr/departments/$id');

  Future designations({Map<String, dynamic>? filters}) =>
      index('/hr/designations', filters: filters);
  Future designation(int id) => show('/hr/designations/$id');
  Future createDesignation(Map<String, dynamic> body) =>
      store('/hr/designations', body);
  Future updateDesignation(int id, Map<String, dynamic> body) =>
      update('/hr/designations/$id', body);
  Future deleteDesignation(int id) => destroy('/hr/designations/$id');

  Future employees({Map<String, dynamic>? filters}) =>
      index('/hr/employees', filters: filters);
  Future employee(int id) => show('/hr/employees/$id');
  Future employeeAccounts(int id) => show('/hr/employees/$id/accounts');
  Future employeeSalaryStructures(int id) =>
      show('/hr/employees/$id/salary-structures');
  Future createEmployee(Map<String, dynamic> body) =>
      store('/hr/employees', body);
  Future updateEmployee(int id, Map<String, dynamic> body) =>
      update('/hr/employees/$id', body);
  Future deleteEmployee(int id) => destroy('/hr/employees/$id');

  Future attendance({Map<String, dynamic>? filters}) =>
      index('/hr/attendance', filters: filters);
  Future attendanceRecord(int id) => show('/hr/attendance/$id');
  Future createAttendance(Map<String, dynamic> body) =>
      store('/hr/attendance', body);
  Future updateAttendance(int id, Map<String, dynamic> body) =>
      update('/hr/attendance/$id', body);
  Future deleteAttendance(int id) => destroy('/hr/attendance/$id');

  Future leaveTypes({Map<String, dynamic>? filters}) =>
      index('/hr/leave-types', filters: filters);
  Future leaveType(int id) => show('/hr/leave-types/$id');
  Future createLeaveType(Map<String, dynamic> body) =>
      store('/hr/leave-types', body);
  Future updateLeaveType(int id, Map<String, dynamic> body) =>
      update('/hr/leave-types/$id', body);
  Future deleteLeaveType(int id) => destroy('/hr/leave-types/$id');

  Future leaveRequests({Map<String, dynamic>? filters}) =>
      index('/hr/leave-requests', filters: filters);
  Future leaveRequest(int id) => show('/hr/leave-requests/$id');
  Future createLeaveRequest(Map<String, dynamic> body) =>
      store('/hr/leave-requests', body);
  Future updateLeaveRequest(int id, Map<String, dynamic> body) =>
      update('/hr/leave-requests/$id', body);
  Future approveLeaveRequest(int id, Map<String, dynamic> body) =>
      action('/hr/leave-requests/$id/approve', body: body);
  Future rejectLeaveRequest(int id, Map<String, dynamic> body) =>
      action('/hr/leave-requests/$id/reject', body: body);
  Future deleteLeaveRequest(int id) => destroy('/hr/leave-requests/$id');

  Future payrollRuns({Map<String, dynamic>? filters}) =>
      index('/hr/payroll-runs', filters: filters);
  Future payrollRun(int id) => show('/hr/payroll-runs/$id');
  Future createPayrollRun(Map<String, dynamic> body) =>
      store('/hr/payroll-runs', body);
  Future updatePayrollRun(int id, Map<String, dynamic> body) =>
      update('/hr/payroll-runs/$id', body);
  Future processPayrollRun(int id, Map<String, dynamic> body) =>
      action('/hr/payroll-runs/$id/process', body: body);
  Future postPayrollRun(int id, Map<String, dynamic> body) =>
      action('/hr/payroll-runs/$id/post', body: body);
  Future deletePayrollRun(int id) => destroy('/hr/payroll-runs/$id');

  Future payslips({Map<String, dynamic>? filters}) =>
      index('/hr/payslips', filters: filters);
  Future payslip(int id) => show('/hr/payslips/$id');

  Future expenseClaims({Map<String, dynamic>? filters}) =>
      index('/hr/expense-claims', filters: filters);
  Future expenseClaim(int id) => show('/hr/expense-claims/$id');
  Future createExpenseClaim(Map<String, dynamic> body) =>
      store('/hr/expense-claims', body);
  Future updateExpenseClaim(int id, Map<String, dynamic> body) =>
      update('/hr/expense-claims/$id', body);
  Future approveExpenseClaim(int id, Map<String, dynamic> body) =>
      action('/hr/expense-claims/$id/approve', body: body);
  Future reimburseExpenseClaim(int id, Map<String, dynamic> body) =>
      action('/hr/expense-claims/$id/reimburse', body: body);
  Future deleteExpenseClaim(int id) => destroy('/hr/expense-claims/$id');
}
