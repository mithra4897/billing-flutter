import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/service/service_contract_model.dart';
import '../../model/service/service_feedback_model.dart';
import '../../model/service/service_ticket_model.dart';
import '../../model/service/service_work_order_model.dart';
import '../base/erp_module_service.dart';

class ServiceModuleService extends ErpModuleService {
  ServiceModuleService({super.apiClient});

  Future<PaginatedResponse<ServiceContractModel>> contracts({
    Map<String, dynamic>? filters,
  }) => paginated<ServiceContractModel>(
    '/service/contracts',
    filters: filters,
    fromJson: ServiceContractModel.fromJson,
  );
  Future<ApiResponse<ServiceContractModel>> contract(int id) =>
      object<ServiceContractModel>(
        '/service/contracts/$id',
        fromJson: ServiceContractModel.fromJson,
      );
  Future<ApiResponse<ServiceContractModel>> createContract(
    ServiceContractModel body,
  ) => createModel<ServiceContractModel>(
    '/service/contracts',
    body,
    fromJson: ServiceContractModel.fromJson,
  );
  Future<ApiResponse<ServiceContractModel>> updateContract(
    int id,
    ServiceContractModel body,
  ) => updateModel<ServiceContractModel>(
    '/service/contracts/$id',
    body,
    fromJson: ServiceContractModel.fromJson,
  );
  Future<ApiResponse<ServiceContractModel>> approveContract(int id) =>
      actionModel<ServiceContractModel>(
        '/service/contracts/$id/approve',
        fromJson: ServiceContractModel.fromJson,
      );
  Future<ApiResponse<ServiceContractModel>> terminateContract(int id) =>
      actionModel<ServiceContractModel>(
        '/service/contracts/$id/terminate',
        fromJson: ServiceContractModel.fromJson,
      );
  Future<ApiResponse<ServiceContractModel>> cancelContract(int id) =>
      actionModel<ServiceContractModel>(
        '/service/contracts/$id/cancel',
        fromJson: ServiceContractModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteContract(int id) =>
      destroy('/service/contracts/$id');

  Future<PaginatedResponse<ServiceTicketModel>> tickets({
    Map<String, dynamic>? filters,
  }) => paginated<ServiceTicketModel>(
    '/service/tickets',
    filters: filters,
    fromJson: ServiceTicketModel.fromJson,
  );
  Future<ApiResponse<ServiceTicketModel>> ticket(int id) =>
      object<ServiceTicketModel>(
        '/service/tickets/$id',
        fromJson: ServiceTicketModel.fromJson,
      );
  Future<ApiResponse<ServiceTicketModel>> createTicket(
    ServiceTicketModel body,
  ) => createModel<ServiceTicketModel>(
    '/service/tickets',
    body,
    fromJson: ServiceTicketModel.fromJson,
  );
  Future<ApiResponse<ServiceTicketModel>> updateTicket(
    int id,
    ServiceTicketModel body,
  ) => updateModel<ServiceTicketModel>(
    '/service/tickets/$id',
    body,
    fromJson: ServiceTicketModel.fromJson,
  );

  /// [assignedToUserId] null = assign to current user (API default).
  Future<ApiResponse<ServiceTicketModel>> assignTicket(
    int id, {
    int? assignedToUserId,
  }) => actionModel<ServiceTicketModel>(
    '/service/tickets/$id/assign',
    body: assignedToUserId != null
        ? <String, dynamic>{'assigned_to_user_id': assignedToUserId}
        : null,
    fromJson: ServiceTicketModel.fromJson,
  );

  Future<ApiResponse<ServiceTicketModel>> resolveTicket(int id) =>
      actionModel<ServiceTicketModel>(
        '/service/tickets/$id/resolve',
        fromJson: ServiceTicketModel.fromJson,
      );
  Future<ApiResponse<ServiceTicketModel>> closeTicket(int id) =>
      actionModel<ServiceTicketModel>(
        '/service/tickets/$id/close',
        fromJson: ServiceTicketModel.fromJson,
      );
  Future<ApiResponse<ServiceTicketModel>> cancelTicket(int id) =>
      actionModel<ServiceTicketModel>(
        '/service/tickets/$id/cancel',
        fromJson: ServiceTicketModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteTicket(int id) =>
      destroy('/service/tickets/$id');

  Future<PaginatedResponse<ServiceWorkOrderModel>> workOrders({
    Map<String, dynamic>? filters,
  }) => paginated<ServiceWorkOrderModel>(
    '/service/work-orders',
    filters: filters,
    fromJson: ServiceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<ServiceWorkOrderModel>> workOrder(int id) =>
      object<ServiceWorkOrderModel>(
        '/service/work-orders/$id',
        fromJson: ServiceWorkOrderModel.fromJson,
      );
  Future<ApiResponse<ServiceWorkOrderModel>> createWorkOrder(
    ServiceWorkOrderModel body,
  ) => createModel<ServiceWorkOrderModel>(
    '/service/work-orders',
    body,
    fromJson: ServiceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<ServiceWorkOrderModel>> updateWorkOrder(
    int id,
    ServiceWorkOrderModel body,
  ) => updateModel<ServiceWorkOrderModel>(
    '/service/work-orders/$id',
    body,
    fromJson: ServiceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<ServiceWorkOrderModel>> startWorkOrder(int id) =>
      actionModel<ServiceWorkOrderModel>(
        '/service/work-orders/$id/start',
        fromJson: ServiceWorkOrderModel.fromJson,
      );
  Future<ApiResponse<ServiceWorkOrderModel>> completeWorkOrder(int id) =>
      actionModel<ServiceWorkOrderModel>(
        '/service/work-orders/$id/complete',
        fromJson: ServiceWorkOrderModel.fromJson,
      );
  Future<ApiResponse<ServiceWorkOrderModel>> closeWorkOrder(int id) =>
      actionModel<ServiceWorkOrderModel>(
        '/service/work-orders/$id/close',
        fromJson: ServiceWorkOrderModel.fromJson,
      );
  Future<ApiResponse<ServiceWorkOrderModel>> cancelWorkOrder(int id) =>
      actionModel<ServiceWorkOrderModel>(
        '/service/work-orders/$id/cancel',
        fromJson: ServiceWorkOrderModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteWorkOrder(int id) =>
      destroy('/service/work-orders/$id');

  Future<PaginatedResponse<ServiceFeedbackModel>> feedbacks({
    Map<String, dynamic>? filters,
  }) => paginated<ServiceFeedbackModel>(
    '/service/feedbacks',
    filters: filters,
    fromJson: ServiceFeedbackModel.fromJson,
  );
  Future<ApiResponse<ServiceFeedbackModel>> feedback(int id) =>
      object<ServiceFeedbackModel>(
        '/service/feedbacks/$id',
        fromJson: ServiceFeedbackModel.fromJson,
      );
  Future<ApiResponse<ServiceFeedbackModel>> createFeedback(
    ServiceFeedbackModel body,
  ) => createModel<ServiceFeedbackModel>(
    '/service/feedbacks',
    body,
    fromJson: ServiceFeedbackModel.fromJson,
  );
  Future<ApiResponse<ServiceFeedbackModel>> updateFeedback(
    int id,
    ServiceFeedbackModel body,
  ) => updateModel<ServiceFeedbackModel>(
    '/service/feedbacks/$id',
    body,
    fromJson: ServiceFeedbackModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteFeedback(int id) =>
      destroy('/service/feedbacks/$id');

  Future<PaginatedResponse<ServiceTicketModel>> warrantyClaims({
    Map<String, dynamic>? filters,
  }) => paginated<ServiceTicketModel>(
    '/service/warranty-claims',
    filters: filters,
    fromJson: ServiceTicketModel.fromJson,
  );
  Future<ApiResponse<ServiceTicketModel>> warrantyClaim(int id) =>
      object<ServiceTicketModel>(
        '/service/warranty-claims/$id',
        fromJson: ServiceTicketModel.fromJson,
      );
  Future<ApiResponse<ServiceTicketModel>> createWarrantyClaim(
    ServiceTicketModel body,
  ) => createModel<ServiceTicketModel>(
    '/service/warranty-claims',
    body,
    fromJson: ServiceTicketModel.fromJson,
  );
  Future<ApiResponse<ServiceTicketModel>> updateWarrantyClaim(
    int id,
    ServiceTicketModel body,
  ) => updateModel<ServiceTicketModel>(
    '/service/warranty-claims/$id',
    body,
    fromJson: ServiceTicketModel.fromJson,
  );

  Future<ApiResponse<ServiceTicketModel>> assignWarrantyClaim(
    int id, {
    int? assignedToUserId,
  }) => actionModel<ServiceTicketModel>(
    '/service/warranty-claims/$id/assign',
    body: assignedToUserId != null
        ? <String, dynamic>{'assigned_to_user_id': assignedToUserId}
        : null,
    fromJson: ServiceTicketModel.fromJson,
  );

  Future<ApiResponse<dynamic>> createWorkOrderFromWarrantyClaim(
    int id, {
    Map<String, dynamic>? body,
  }) => actionDynamic(
    '/service/warranty-claims/$id/create-work-order',
    body: body ?? const <String, dynamic>{},
  );

  Future<ApiResponse<ServiceTicketModel>> resolveWarrantyClaim(int id) =>
      actionModel<ServiceTicketModel>(
        '/service/warranty-claims/$id/resolve',
        fromJson: ServiceTicketModel.fromJson,
      );
  Future<ApiResponse<ServiceTicketModel>> closeWarrantyClaim(int id) =>
      actionModel<ServiceTicketModel>(
        '/service/warranty-claims/$id/close',
        fromJson: ServiceTicketModel.fromJson,
      );
  Future<ApiResponse<ServiceTicketModel>> cancelWarrantyClaim(int id) =>
      actionModel<ServiceTicketModel>(
        '/service/warranty-claims/$id/cancel',
        fromJson: ServiceTicketModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteWarrantyClaim(int id) =>
      destroy('/service/warranty-claims/$id');
}
