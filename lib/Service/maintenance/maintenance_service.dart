import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/maintenance/amc_contract_model.dart';
import '../../model/maintenance/asset_downtime_log_model.dart';
import '../../model/maintenance/maintenance_plan_model.dart';
import '../../model/maintenance/maintenance_request_model.dart';
import '../../model/maintenance/maintenance_work_order_model.dart';
import '../base/erp_module_service.dart';

class MaintenanceService extends ErpModuleService {
  MaintenanceService({super.apiClient});

  Future<PaginatedResponse<MaintenancePlanModel>> plans({
    Map<String, dynamic>? filters,
  }) => paginated<MaintenancePlanModel>(
    '/maintenance/plans',
    filters: filters,
    fromJson: MaintenancePlanModel.fromJson,
  );
  Future<ApiResponse<MaintenancePlanModel>> plan(int id) =>
      object<MaintenancePlanModel>(
        '/maintenance/plans/$id',
        fromJson: MaintenancePlanModel.fromJson,
      );
  Future<ApiResponse<MaintenancePlanModel>> createPlan(
    MaintenancePlanModel body,
  ) => createModel<MaintenancePlanModel>(
    '/maintenance/plans',
    body,
    fromJson: MaintenancePlanModel.fromJson,
  );
  Future<ApiResponse<MaintenancePlanModel>> updatePlan(
    int id,
    MaintenancePlanModel body,
  ) => updateModel<MaintenancePlanModel>(
    '/maintenance/plans/$id',
    body,
    fromJson: MaintenancePlanModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deletePlan(int id) =>
      destroy('/maintenance/plans/$id');

  Future<PaginatedResponse<MaintenanceRequestModel>> requests({
    Map<String, dynamic>? filters,
  }) => paginated<MaintenanceRequestModel>(
    '/maintenance/requests',
    filters: filters,
    fromJson: MaintenanceRequestModel.fromJson,
  );
  Future<ApiResponse<MaintenanceRequestModel>> request(int id) =>
      object<MaintenanceRequestModel>(
        '/maintenance/requests/$id',
        fromJson: MaintenanceRequestModel.fromJson,
      );
  Future<ApiResponse<MaintenanceRequestModel>> createRequest(
    MaintenanceRequestModel body,
  ) => createModel<MaintenanceRequestModel>(
    '/maintenance/requests',
    body,
    fromJson: MaintenanceRequestModel.fromJson,
  );
  Future<ApiResponse<MaintenanceRequestModel>> updateRequest(
    int id,
    MaintenanceRequestModel body,
  ) => updateModel<MaintenanceRequestModel>(
    '/maintenance/requests/$id',
    body,
    fromJson: MaintenanceRequestModel.fromJson,
  );
  Future<ApiResponse<MaintenanceRequestModel>> approveRequest(
    int id,
    MaintenanceRequestModel body,
  ) => actionModel<MaintenanceRequestModel>(
    '/maintenance/requests/$id/approve',
    body: body,
    fromJson: MaintenanceRequestModel.fromJson,
  );
  Future<ApiResponse<MaintenanceRequestModel>> cancelRequest(
    int id,
    MaintenanceRequestModel body,
  ) => actionModel<MaintenanceRequestModel>(
    '/maintenance/requests/$id/cancel',
    body: body,
    fromJson: MaintenanceRequestModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteRequest(int id) =>
      destroy('/maintenance/requests/$id');

  Future<PaginatedResponse<MaintenanceWorkOrderModel>> workOrders({
    Map<String, dynamic>? filters,
  }) => paginated<MaintenanceWorkOrderModel>(
    '/maintenance/work-orders',
    filters: filters,
    fromJson: MaintenanceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<MaintenanceWorkOrderModel>> workOrder(int id) =>
      object<MaintenanceWorkOrderModel>(
        '/maintenance/work-orders/$id',
        fromJson: MaintenanceWorkOrderModel.fromJson,
      );
  Future<ApiResponse<MaintenanceWorkOrderModel>> createWorkOrder(
    MaintenanceWorkOrderModel body,
  ) => createModel<MaintenanceWorkOrderModel>(
    '/maintenance/work-orders',
    body,
    fromJson: MaintenanceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<MaintenanceWorkOrderModel>> updateWorkOrder(
    int id,
    MaintenanceWorkOrderModel body,
  ) => updateModel<MaintenanceWorkOrderModel>(
    '/maintenance/work-orders/$id',
    body,
    fromJson: MaintenanceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<MaintenanceWorkOrderModel>> approveWorkOrder(
    int id,
    MaintenanceWorkOrderModel body,
  ) => actionModel<MaintenanceWorkOrderModel>(
    '/maintenance/work-orders/$id/approve',
    body: body,
    fromJson: MaintenanceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<MaintenanceWorkOrderModel>> startWorkOrder(
    int id,
    MaintenanceWorkOrderModel body,
  ) => actionModel<MaintenanceWorkOrderModel>(
    '/maintenance/work-orders/$id/start',
    body: body,
    fromJson: MaintenanceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<MaintenanceWorkOrderModel>> completeWorkOrder(
    int id,
    MaintenanceWorkOrderModel body,
  ) => actionModel<MaintenanceWorkOrderModel>(
    '/maintenance/work-orders/$id/complete',
    body: body,
    fromJson: MaintenanceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<MaintenanceWorkOrderModel>> closeWorkOrder(
    int id,
    MaintenanceWorkOrderModel body,
  ) => actionModel<MaintenanceWorkOrderModel>(
    '/maintenance/work-orders/$id/close',
    body: body,
    fromJson: MaintenanceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<MaintenanceWorkOrderModel>> cancelWorkOrder(
    int id,
    MaintenanceWorkOrderModel body,
  ) => actionModel<MaintenanceWorkOrderModel>(
    '/maintenance/work-orders/$id/cancel',
    body: body,
    fromJson: MaintenanceWorkOrderModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteWorkOrder(int id) =>
      destroy('/maintenance/work-orders/$id');

  Future<PaginatedResponse<AssetDowntimeLogModel>> downtimeLogs({
    Map<String, dynamic>? filters,
  }) => paginated<AssetDowntimeLogModel>(
    '/maintenance/downtime-logs',
    filters: filters,
    fromJson: AssetDowntimeLogModel.fromJson,
  );
  Future<ApiResponse<AssetDowntimeLogModel>> downtimeLog(int id) =>
      object<AssetDowntimeLogModel>(
        '/maintenance/downtime-logs/$id',
        fromJson: AssetDowntimeLogModel.fromJson,
      );
  Future<ApiResponse<AssetDowntimeLogModel>> createDowntimeLog(
    AssetDowntimeLogModel body,
  ) => createModel<AssetDowntimeLogModel>(
    '/maintenance/downtime-logs',
    body,
    fromJson: AssetDowntimeLogModel.fromJson,
  );
  Future<ApiResponse<AssetDowntimeLogModel>> updateDowntimeLog(
    int id,
    AssetDowntimeLogModel body,
  ) => updateModel<AssetDowntimeLogModel>(
    '/maintenance/downtime-logs/$id',
    body,
    fromJson: AssetDowntimeLogModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteDowntimeLog(int id) =>
      destroy('/maintenance/downtime-logs/$id');

  Future<PaginatedResponse<AmcContractModel>> amcContracts({
    Map<String, dynamic>? filters,
  }) => paginated<AmcContractModel>(
    '/maintenance/amc-contracts',
    filters: filters,
    fromJson: AmcContractModel.fromJson,
  );
  Future<ApiResponse<AmcContractModel>> amcContract(int id) =>
      object<AmcContractModel>(
        '/maintenance/amc-contracts/$id',
        fromJson: AmcContractModel.fromJson,
      );
  Future<ApiResponse<AmcContractModel>> createAmcContract(
    AmcContractModel body,
  ) => createModel<AmcContractModel>(
    '/maintenance/amc-contracts',
    body,
    fromJson: AmcContractModel.fromJson,
  );
  Future<ApiResponse<AmcContractModel>> updateAmcContract(
    int id,
    AmcContractModel body,
  ) => updateModel<AmcContractModel>(
    '/maintenance/amc-contracts/$id',
    body,
    fromJson: AmcContractModel.fromJson,
  );
  Future<ApiResponse<AmcContractModel>> approveAmcContract(
    int id,
    AmcContractModel body,
  ) => actionModel<AmcContractModel>(
    '/maintenance/amc-contracts/$id/approve',
    body: body,
    fromJson: AmcContractModel.fromJson,
  );
  Future<ApiResponse<AmcContractModel>> terminateAmcContract(
    int id,
    AmcContractModel body,
  ) => actionModel<AmcContractModel>(
    '/maintenance/amc-contracts/$id/terminate',
    body: body,
    fromJson: AmcContractModel.fromJson,
  );
  Future<ApiResponse<AmcContractModel>> cancelAmcContract(
    int id,
    AmcContractModel body,
  ) => actionModel<AmcContractModel>(
    '/maintenance/amc-contracts/$id/cancel',
    body: body,
    fromJson: AmcContractModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteAmcContract(int id) =>
      destroy('/maintenance/amc-contracts/$id');
}
