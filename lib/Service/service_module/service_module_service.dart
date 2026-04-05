import '../base/erp_module_service.dart';

class ServiceModuleService extends ErpModuleService {
  ServiceModuleService({super.apiClient});

  Future contracts({Map<String, dynamic>? filters}) =>
      index('/service/contracts', filters: filters);
  Future contract(int id) => show('/service/contracts/$id');
  Future createContract(Map<String, dynamic> body) =>
      store('/service/contracts', body);
  Future updateContract(int id, Map<String, dynamic> body) =>
      update('/service/contracts/$id', body);
  Future approveContract(int id, Map<String, dynamic> body) =>
      action('/service/contracts/$id/approve', body: body);
  Future terminateContract(int id, Map<String, dynamic> body) =>
      action('/service/contracts/$id/terminate', body: body);
  Future cancelContract(int id, Map<String, dynamic> body) =>
      action('/service/contracts/$id/cancel', body: body);
  Future deleteContract(int id) => destroy('/service/contracts/$id');

  Future tickets({Map<String, dynamic>? filters}) =>
      index('/service/tickets', filters: filters);
  Future ticket(int id) => show('/service/tickets/$id');
  Future createTicket(Map<String, dynamic> body) =>
      store('/service/tickets', body);
  Future updateTicket(int id, Map<String, dynamic> body) =>
      update('/service/tickets/$id', body);
  Future assignTicket(int id, Map<String, dynamic> body) =>
      action('/service/tickets/$id/assign', body: body);
  Future resolveTicket(int id, Map<String, dynamic> body) =>
      action('/service/tickets/$id/resolve', body: body);
  Future closeTicket(int id, Map<String, dynamic> body) =>
      action('/service/tickets/$id/close', body: body);
  Future cancelTicket(int id, Map<String, dynamic> body) =>
      action('/service/tickets/$id/cancel', body: body);
  Future deleteTicket(int id) => destroy('/service/tickets/$id');

  Future workOrders({Map<String, dynamic>? filters}) =>
      index('/service/work-orders', filters: filters);
  Future workOrder(int id) => show('/service/work-orders/$id');
  Future createWorkOrder(Map<String, dynamic> body) =>
      store('/service/work-orders', body);
  Future updateWorkOrder(int id, Map<String, dynamic> body) =>
      update('/service/work-orders/$id', body);
  Future startWorkOrder(int id, Map<String, dynamic> body) =>
      action('/service/work-orders/$id/start', body: body);
  Future completeWorkOrder(int id, Map<String, dynamic> body) =>
      action('/service/work-orders/$id/complete', body: body);
  Future closeWorkOrder(int id, Map<String, dynamic> body) =>
      action('/service/work-orders/$id/close', body: body);
  Future cancelWorkOrder(int id, Map<String, dynamic> body) =>
      action('/service/work-orders/$id/cancel', body: body);
  Future deleteWorkOrder(int id) => destroy('/service/work-orders/$id');

  Future feedbacks({Map<String, dynamic>? filters}) =>
      index('/service/feedbacks', filters: filters);
  Future feedback(int id) => show('/service/feedbacks/$id');
  Future createFeedback(Map<String, dynamic> body) =>
      store('/service/feedbacks', body);
  Future updateFeedback(int id, Map<String, dynamic> body) =>
      update('/service/feedbacks/$id', body);
  Future deleteFeedback(int id) => destroy('/service/feedbacks/$id');
}
