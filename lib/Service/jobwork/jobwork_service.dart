import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/jobwork/jobwork_charge_model.dart';
import '../../model/jobwork/jobwork_dispatch_model.dart';
import '../../model/jobwork/jobwork_order_model.dart';
import '../../model/jobwork/jobwork_receipt_model.dart';
import '../base/erp_module_service.dart';

class JobworkService extends ErpModuleService {
  JobworkService({super.apiClient});

  Future<PaginatedResponse<JobworkOrderModel>> orders({
    Map<String, dynamic>? filters,
  }) => paginated<JobworkOrderModel>(
    '/jobwork/orders',
    filters: filters,
    fromJson: JobworkOrderModel.fromJson,
  );
  Future<ApiResponse<JobworkOrderModel>> order(int id) =>
      object<JobworkOrderModel>(
        '/jobwork/orders/$id',
        fromJson: JobworkOrderModel.fromJson,
      );
  Future<ApiResponse<JobworkOrderModel>> createOrder(JobworkOrderModel body) =>
      createModel<JobworkOrderModel>(
        '/jobwork/orders',
        body,
        fromJson: JobworkOrderModel.fromJson,
      );
  Future<ApiResponse<JobworkOrderModel>> updateOrder(
    int id,
    dynamic body,
  ) => updateModel<JobworkOrderModel>(
    '/jobwork/orders/$id',
    body,
    fromJson: JobworkOrderModel.fromJson,
  );
  Future<ApiResponse<JobworkOrderModel>> releaseOrder(int id) =>
      actionModel<JobworkOrderModel>(
        '/jobwork/orders/$id/release',
        fromJson: JobworkOrderModel.fromJson,
      );
  Future<ApiResponse<JobworkOrderModel>> closeOrder(int id) =>
      actionModel<JobworkOrderModel>(
        '/jobwork/orders/$id/close',
        fromJson: JobworkOrderModel.fromJson,
      );
  Future<ApiResponse<JobworkOrderModel>> cancelOrder(int id) =>
      actionModel<JobworkOrderModel>(
        '/jobwork/orders/$id/cancel',
        fromJson: JobworkOrderModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteOrder(int id) =>
      destroy('/jobwork/orders/$id');

  Future<PaginatedResponse<JobworkDispatchModel>> dispatches({
    Map<String, dynamic>? filters,
  }) => paginated<JobworkDispatchModel>(
    '/jobwork/dispatches',
    filters: filters,
    fromJson: JobworkDispatchModel.fromJson,
  );
  Future<ApiResponse<JobworkDispatchModel>> dispatch(int id) =>
      object<JobworkDispatchModel>(
        '/jobwork/dispatches/$id',
        fromJson: JobworkDispatchModel.fromJson,
      );
  Future<ApiResponse<JobworkDispatchModel>> createDispatch(
    JobworkDispatchModel body,
  ) => createModel<JobworkDispatchModel>(
    '/jobwork/dispatches',
    body,
    fromJson: JobworkDispatchModel.fromJson,
  );
  Future<ApiResponse<JobworkDispatchModel>> updateDispatch(
    int id,
    dynamic body,
  ) => updateModel<JobworkDispatchModel>(
    '/jobwork/dispatches/$id',
    body,
    fromJson: JobworkDispatchModel.fromJson,
  );
  Future<ApiResponse<JobworkDispatchModel>> postDispatch(int id) =>
      actionModel<JobworkDispatchModel>(
        '/jobwork/dispatches/$id/post',
        fromJson: JobworkDispatchModel.fromJson,
      );
  Future<ApiResponse<JobworkDispatchModel>> cancelDispatch(int id) =>
      actionModel<JobworkDispatchModel>(
        '/jobwork/dispatches/$id/cancel',
        fromJson: JobworkDispatchModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteDispatch(int id) =>
      destroy('/jobwork/dispatches/$id');

  Future<PaginatedResponse<JobworkReceiptModel>> receipts({
    Map<String, dynamic>? filters,
  }) => paginated<JobworkReceiptModel>(
    '/jobwork/receipts',
    filters: filters,
    fromJson: JobworkReceiptModel.fromJson,
  );
  Future<ApiResponse<JobworkReceiptModel>> receipt(int id) =>
      object<JobworkReceiptModel>(
        '/jobwork/receipts/$id',
        fromJson: JobworkReceiptModel.fromJson,
      );
  Future<ApiResponse<JobworkReceiptModel>> createReceipt(
    JobworkReceiptModel body,
  ) => createModel<JobworkReceiptModel>(
    '/jobwork/receipts',
    body,
    fromJson: JobworkReceiptModel.fromJson,
  );
  Future<ApiResponse<JobworkReceiptModel>> updateReceipt(
    int id,
    dynamic body,
  ) => updateModel<JobworkReceiptModel>(
    '/jobwork/receipts/$id',
    body,
    fromJson: JobworkReceiptModel.fromJson,
  );
  Future<ApiResponse<JobworkReceiptModel>> postReceipt(int id) =>
      actionModel<JobworkReceiptModel>(
        '/jobwork/receipts/$id/post',
        fromJson: JobworkReceiptModel.fromJson,
      );
  Future<ApiResponse<JobworkReceiptModel>> cancelReceipt(int id) =>
      actionModel<JobworkReceiptModel>(
        '/jobwork/receipts/$id/cancel',
        fromJson: JobworkReceiptModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteReceipt(int id) =>
      destroy('/jobwork/receipts/$id');

  Future<PaginatedResponse<JobworkChargeModel>> charges({
    Map<String, dynamic>? filters,
  }) => paginated<JobworkChargeModel>(
    '/jobwork/charges',
    filters: filters,
    fromJson: JobworkChargeModel.fromJson,
  );
  Future<ApiResponse<JobworkChargeModel>> charge(int id) =>
      object<JobworkChargeModel>(
        '/jobwork/charges/$id',
        fromJson: JobworkChargeModel.fromJson,
      );
  Future<ApiResponse<JobworkChargeModel>> createCharge(
    JobworkChargeModel body,
  ) => createModel<JobworkChargeModel>(
    '/jobwork/charges',
    body,
    fromJson: JobworkChargeModel.fromJson,
  );
  Future<ApiResponse<JobworkChargeModel>> updateCharge(
    int id,
    dynamic body,
  ) => updateModel<JobworkChargeModel>(
    '/jobwork/charges/$id',
    body,
    fromJson: JobworkChargeModel.fromJson,
  );
  Future<ApiResponse<JobworkChargeModel>> postCharge(int id) =>
      actionModel<JobworkChargeModel>(
        '/jobwork/charges/$id/post',
        fromJson: JobworkChargeModel.fromJson,
      );
  Future<ApiResponse<JobworkChargeModel>> cancelCharge(int id) =>
      actionModel<JobworkChargeModel>(
        '/jobwork/charges/$id/cancel',
        fromJson: JobworkChargeModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteCharge(int id) =>
      destroy('/jobwork/charges/$id');
}
