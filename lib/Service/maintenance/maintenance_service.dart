import '../base/erp_module_service.dart';

class MaintenanceService extends ErpModuleService {
  MaintenanceService({super.apiClient});

  Future plans({Map<String, dynamic>? filters}) =>
      index('/maintenance/plans', filters: filters);
  Future plan(int id) => show('/maintenance/plans/$id');
  Future createPlan(Map<String, dynamic> body) =>
      store('/maintenance/plans', body);
  Future updatePlan(int id, Map<String, dynamic> body) =>
      update('/maintenance/plans/$id', body);
  Future deletePlan(int id) => destroy('/maintenance/plans/$id');

  Future requests({Map<String, dynamic>? filters}) =>
      index('/maintenance/requests', filters: filters);
  Future request(int id) => show('/maintenance/requests/$id');
  Future createRequest(Map<String, dynamic> body) =>
      store('/maintenance/requests', body);
  Future updateRequest(int id, Map<String, dynamic> body) =>
      update('/maintenance/requests/$id', body);
  Future approveRequest(int id, Map<String, dynamic> body) =>
      action('/maintenance/requests/$id/approve', body: body);
  Future cancelRequest(int id, Map<String, dynamic> body) =>
      action('/maintenance/requests/$id/cancel', body: body);
  Future deleteRequest(int id) => destroy('/maintenance/requests/$id');

  Future workOrders({Map<String, dynamic>? filters}) =>
      index('/maintenance/work-orders', filters: filters);
  Future workOrder(int id) => show('/maintenance/work-orders/$id');
  Future createWorkOrder(Map<String, dynamic> body) =>
      store('/maintenance/work-orders', body);
  Future updateWorkOrder(int id, Map<String, dynamic> body) =>
      update('/maintenance/work-orders/$id', body);
  Future approveWorkOrder(int id, Map<String, dynamic> body) =>
      action('/maintenance/work-orders/$id/approve', body: body);
  Future startWorkOrder(int id, Map<String, dynamic> body) =>
      action('/maintenance/work-orders/$id/start', body: body);
  Future completeWorkOrder(int id, Map<String, dynamic> body) =>
      action('/maintenance/work-orders/$id/complete', body: body);
  Future closeWorkOrder(int id, Map<String, dynamic> body) =>
      action('/maintenance/work-orders/$id/close', body: body);
  Future cancelWorkOrder(int id, Map<String, dynamic> body) =>
      action('/maintenance/work-orders/$id/cancel', body: body);
  Future deleteWorkOrder(int id) => destroy('/maintenance/work-orders/$id');

  Future downtimeLogs({Map<String, dynamic>? filters}) =>
      index('/maintenance/downtime-logs', filters: filters);
  Future downtimeLog(int id) => show('/maintenance/downtime-logs/$id');
  Future createDowntimeLog(Map<String, dynamic> body) =>
      store('/maintenance/downtime-logs', body);
  Future updateDowntimeLog(int id, Map<String, dynamic> body) =>
      update('/maintenance/downtime-logs/$id', body);
  Future deleteDowntimeLog(int id) => destroy('/maintenance/downtime-logs/$id');

  Future amcContracts({Map<String, dynamic>? filters}) =>
      index('/maintenance/amc-contracts', filters: filters);
  Future amcContract(int id) => show('/maintenance/amc-contracts/$id');
  Future createAmcContract(Map<String, dynamic> body) =>
      store('/maintenance/amc-contracts', body);
  Future updateAmcContract(int id, Map<String, dynamic> body) =>
      update('/maintenance/amc-contracts/$id', body);
  Future approveAmcContract(int id, Map<String, dynamic> body) =>
      action('/maintenance/amc-contracts/$id/approve', body: body);
  Future terminateAmcContract(int id, Map<String, dynamic> body) =>
      action('/maintenance/amc-contracts/$id/terminate', body: body);
  Future cancelAmcContract(int id, Map<String, dynamic> body) =>
      action('/maintenance/amc-contracts/$id/cancel', body: body);
  Future deleteAmcContract(int id) => destroy('/maintenance/amc-contracts/$id');
}
