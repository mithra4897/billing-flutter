import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/purchase/purchase_invoice_model.dart';
import '../../model/purchase/purchase_order_model.dart';
import '../../model/purchase/purchase_payment_model.dart';
import '../../model/purchase/purchase_receipt_model.dart';
import '../../model/purchase/purchase_requisition_model.dart';
import '../../model/purchase/purchase_return_model.dart';
import '../base/erp_module_service.dart';

class PurchaseService extends ErpModuleService {
  PurchaseService({super.apiClient});

  Future<PaginatedResponse<PurchaseRequisitionModel>> requisitions({
    Map<String, dynamic>? filters,
  }) => paginated<PurchaseRequisitionModel>(
    ApiEndpoints.purchaseRequisitions,
    filters: filters,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<List<PurchaseRequisitionModel>>> requisitionsAll({
    Map<String, dynamic>? filters,
  }) => collection<PurchaseRequisitionModel>(
    ApiEndpoints.purchaseRequisitionsAll,
    filters: filters,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<PurchaseRequisitionModel>> requisition(int id) =>
      object<PurchaseRequisitionModel>(
        '${ApiEndpoints.purchaseRequisitions}/$id',
        fromJson: PurchaseRequisitionModel.fromJson,
      );
  Future<ApiResponse<PurchaseRequisitionModel>> createRequisition(
    PurchaseRequisitionModel body,
  ) => createModel<PurchaseRequisitionModel>(
    ApiEndpoints.purchaseRequisitions,
    body,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<PurchaseRequisitionModel>> updateRequisition(
    int id,
    PurchaseRequisitionModel body,
  ) => updateModel<PurchaseRequisitionModel>(
    '${ApiEndpoints.purchaseRequisitions}/$id',
    body,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteRequisition(int id) =>
      destroy('${ApiEndpoints.purchaseRequisitions}/$id');
  Future<ApiResponse<PurchaseRequisitionModel>> approveRequisition(
    int id,
    PurchaseRequisitionModel body,
  ) => actionModel<PurchaseRequisitionModel>(
    '${ApiEndpoints.purchaseRequisitions}/$id/approve',
    body: body,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<PurchaseRequisitionModel>> cancelRequisition(
    int id,
    PurchaseRequisitionModel body,
  ) => actionModel<PurchaseRequisitionModel>(
    '${ApiEndpoints.purchaseRequisitions}/$id/cancel',
    body: body,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<PurchaseRequisitionModel>> closeRequisition(
    int id,
    PurchaseRequisitionModel body,
  ) => actionModel<PurchaseRequisitionModel>(
    '${ApiEndpoints.purchaseRequisitions}/$id/close',
    body: body,
    fromJson: PurchaseRequisitionModel.fromJson,
  );

  Future<PaginatedResponse<PurchaseOrderModel>> orders({
    Map<String, dynamic>? filters,
  }) => paginated<PurchaseOrderModel>(
    ApiEndpoints.purchaseOrders,
    filters: filters,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<List<PurchaseOrderModel>>> ordersAll({
    Map<String, dynamic>? filters,
  }) => collection<PurchaseOrderModel>(
    ApiEndpoints.purchaseOrdersAll,
    filters: filters,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<PurchaseOrderModel>> order(int id) =>
      object<PurchaseOrderModel>(
        '${ApiEndpoints.purchaseOrders}/$id',
        fromJson: PurchaseOrderModel.fromJson,
      );
  Future<ApiResponse<PurchaseOrderModel>> createOrder(
    PurchaseOrderModel body,
  ) => createModel<PurchaseOrderModel>(
    ApiEndpoints.purchaseOrders,
    body,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<PurchaseOrderModel>> updateOrder(
    int id,
    PurchaseOrderModel body,
  ) => updateModel<PurchaseOrderModel>(
    '${ApiEndpoints.purchaseOrders}/$id',
    body,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteOrder(int id) =>
      destroy('${ApiEndpoints.purchaseOrders}/$id');
  Future<ApiResponse<PurchaseOrderModel>> postOrder(
    int id,
    PurchaseOrderModel body,
  ) => actionModel<PurchaseOrderModel>(
    '${ApiEndpoints.purchaseOrders}/$id/post',
    body: body,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<PurchaseOrderModel>> cancelOrder(
    int id,
    PurchaseOrderModel body,
  ) => actionModel<PurchaseOrderModel>(
    '${ApiEndpoints.purchaseOrders}/$id/cancel',
    body: body,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<PurchaseOrderModel>> closeOrder(
    int id,
    PurchaseOrderModel body,
  ) => actionModel<PurchaseOrderModel>(
    '${ApiEndpoints.purchaseOrders}/$id/close',
    body: body,
    fromJson: PurchaseOrderModel.fromJson,
  );

  Future<PaginatedResponse<PurchaseReceiptModel>> receipts({
    Map<String, dynamic>? filters,
  }) => paginated<PurchaseReceiptModel>(
    ApiEndpoints.purchaseReceipts,
    filters: filters,
    fromJson: PurchaseReceiptModel.fromJson,
  );
  Future<ApiResponse<List<PurchaseReceiptModel>>> receiptsAll({
    Map<String, dynamic>? filters,
  }) => collection<PurchaseReceiptModel>(
    ApiEndpoints.purchaseReceiptsAll,
    filters: filters,
    fromJson: PurchaseReceiptModel.fromJson,
  );
  Future<ApiResponse<PurchaseReceiptModel>> receipt(int id) =>
      object<PurchaseReceiptModel>(
        '${ApiEndpoints.purchaseReceipts}/$id',
        fromJson: PurchaseReceiptModel.fromJson,
      );
  Future<ApiResponse<PurchaseReceiptModel>> createReceipt(
    PurchaseReceiptModel body,
  ) => createModel<PurchaseReceiptModel>(
    ApiEndpoints.purchaseReceipts,
    body,
    fromJson: PurchaseReceiptModel.fromJson,
  );
  Future<ApiResponse<PurchaseReceiptModel>> updateReceipt(
    int id,
    PurchaseReceiptModel body,
  ) => updateModel<PurchaseReceiptModel>(
    '${ApiEndpoints.purchaseReceipts}/$id',
    body,
    fromJson: PurchaseReceiptModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteReceipt(int id) =>
      destroy('${ApiEndpoints.purchaseReceipts}/$id');
  Future<ApiResponse<PurchaseReceiptModel>> postReceipt(
    int id,
    PurchaseReceiptModel body,
  ) => actionModel<PurchaseReceiptModel>(
    '${ApiEndpoints.purchaseReceipts}/$id/post',
    body: body,
    fromJson: PurchaseReceiptModel.fromJson,
  );
  Future<ApiResponse<PurchaseReceiptModel>> cancelReceipt(
    int id,
    PurchaseReceiptModel body,
  ) => actionModel<PurchaseReceiptModel>(
    '${ApiEndpoints.purchaseReceipts}/$id/cancel',
    body: body,
    fromJson: PurchaseReceiptModel.fromJson,
  );

  Future<PaginatedResponse<PurchaseInvoiceModel>> invoices({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<PurchaseInvoiceModel>(
      ApiEndpoints.purchaseInvoices,
      queryParameters: filters,
      itemFromJson: PurchaseInvoiceModel.fromJson,
    );
  }

  Future<PaginatedResponse<PurchaseInvoiceModel>> getInvoices({
    Map<String, dynamic>? filters,
  }) => invoices(filters: filters);

  Future<ApiResponse<PurchaseInvoiceModel>> invoice(int id) {
    return client.get<PurchaseInvoiceModel>(
      '${ApiEndpoints.purchaseInvoices}/$id',
      fromData: (json) =>
          PurchaseInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PurchaseInvoiceModel>> getInvoice(int id) => invoice(id);

  Future<ApiResponse<PurchaseInvoiceModel>> createInvoice(
    PurchaseInvoiceModel invoice,
  ) {
    return client.post<PurchaseInvoiceModel>(
      ApiEndpoints.purchaseInvoices,
      body: invoice.toCreateJson(),
      fromData: (json) =>
          PurchaseInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PurchaseInvoiceModel>> updateInvoice(
    int id,
    PurchaseInvoiceModel invoice,
  ) {
    return client.put<PurchaseInvoiceModel>(
      '${ApiEndpoints.purchaseInvoices}/$id',
      body: invoice.toCreateJson(),
      fromData: (json) =>
          PurchaseInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> deleteInvoice(int id) =>
      destroy('${ApiEndpoints.purchaseInvoices}/$id');

  Future<ApiResponse<PurchaseInvoiceModel>> postInvoice(int id) {
    return client.post<PurchaseInvoiceModel>(
      '${ApiEndpoints.purchaseInvoices}/$id/post',
      fromData: (json) =>
          PurchaseInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PurchaseInvoiceModel>> cancelInvoice(int id) {
    return client.post<PurchaseInvoiceModel>(
      '${ApiEndpoints.purchaseInvoices}/$id/cancel',
      fromData: (json) =>
          PurchaseInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PaginatedResponse<PurchasePaymentModel>> payments({
    Map<String, dynamic>? filters,
  }) => paginated<PurchasePaymentModel>(
    ApiEndpoints.purchasePayments,
    filters: filters,
    fromJson: PurchasePaymentModel.fromJson,
  );
  Future<ApiResponse<List<PurchasePaymentModel>>> paymentsAll({
    Map<String, dynamic>? filters,
  }) => collection<PurchasePaymentModel>(
    ApiEndpoints.purchasePaymentsAll,
    filters: filters,
    fromJson: PurchasePaymentModel.fromJson,
  );
  Future<ApiResponse<PurchasePaymentModel>> payment(int id) =>
      object<PurchasePaymentModel>(
        '${ApiEndpoints.purchasePayments}/$id',
        fromJson: PurchasePaymentModel.fromJson,
      );
  Future<ApiResponse<PurchasePaymentModel>> createPayment(
    PurchasePaymentModel body,
  ) => createModel<PurchasePaymentModel>(
    ApiEndpoints.purchasePayments,
    body,
    fromJson: PurchasePaymentModel.fromJson,
  );
  Future<ApiResponse<PurchasePaymentModel>> updatePayment(
    int id,
    PurchasePaymentModel body,
  ) => updateModel<PurchasePaymentModel>(
    '${ApiEndpoints.purchasePayments}/$id',
    body,
    fromJson: PurchasePaymentModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deletePayment(int id) =>
      destroy('${ApiEndpoints.purchasePayments}/$id');
  Future<ApiResponse<PurchasePaymentModel>> postPayment(
    int id,
    PurchasePaymentModel body,
  ) => actionModel<PurchasePaymentModel>(
    '${ApiEndpoints.purchasePayments}/$id/post',
    body: body,
    fromJson: PurchasePaymentModel.fromJson,
  );
  Future<ApiResponse<PurchasePaymentModel>> cancelPayment(
    int id,
    PurchasePaymentModel body,
  ) => actionModel<PurchasePaymentModel>(
    '${ApiEndpoints.purchasePayments}/$id/cancel',
    body: body,
    fromJson: PurchasePaymentModel.fromJson,
  );

  Future<PaginatedResponse<PurchaseReturnModel>> returns({
    Map<String, dynamic>? filters,
  }) => paginated<PurchaseReturnModel>(
    ApiEndpoints.purchaseReturns,
    filters: filters,
    fromJson: PurchaseReturnModel.fromJson,
  );
  Future<ApiResponse<List<PurchaseReturnModel>>> returnsAll({
    Map<String, dynamic>? filters,
  }) => collection<PurchaseReturnModel>(
    ApiEndpoints.purchaseReturnsAll,
    filters: filters,
    fromJson: PurchaseReturnModel.fromJson,
  );
  Future<ApiResponse<PurchaseReturnModel>> returnDoc(int id) =>
      object<PurchaseReturnModel>(
        '${ApiEndpoints.purchaseReturns}/$id',
        fromJson: PurchaseReturnModel.fromJson,
      );
  Future<ApiResponse<PurchaseReturnModel>> createReturn(
    PurchaseReturnModel body,
  ) => createModel<PurchaseReturnModel>(
    ApiEndpoints.purchaseReturns,
    body,
    fromJson: PurchaseReturnModel.fromJson,
  );
  Future<ApiResponse<PurchaseReturnModel>> updateReturn(
    int id,
    PurchaseReturnModel body,
  ) => updateModel<PurchaseReturnModel>(
    '${ApiEndpoints.purchaseReturns}/$id',
    body,
    fromJson: PurchaseReturnModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteReturn(int id) =>
      destroy('${ApiEndpoints.purchaseReturns}/$id');
  Future<ApiResponse<PurchaseReturnModel>> postReturn(
    int id,
    PurchaseReturnModel body,
  ) => actionModel<PurchaseReturnModel>(
    '${ApiEndpoints.purchaseReturns}/$id/post',
    body: body,
    fromJson: PurchaseReturnModel.fromJson,
  );
  Future<ApiResponse<PurchaseReturnModel>> cancelReturn(
    int id,
    PurchaseReturnModel body,
  ) => actionModel<PurchaseReturnModel>(
    '${ApiEndpoints.purchaseReturns}/$id/cancel',
    body: body,
    fromJson: PurchaseReturnModel.fromJson,
  );
}
