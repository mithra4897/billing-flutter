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
    '/purchase/requisitions',
    filters: filters,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<List<PurchaseRequisitionModel>>> requisitionsAll({
    Map<String, dynamic>? filters,
  }) => collection<PurchaseRequisitionModel>(
    '/purchase/requisitions/all',
    filters: filters,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<PurchaseRequisitionModel>> requisition(int id) =>
      object<PurchaseRequisitionModel>(
        '/purchase/requisitions/$id',
        fromJson: PurchaseRequisitionModel.fromJson,
      );
  Future<ApiResponse<PurchaseRequisitionModel>> createRequisition(
    PurchaseRequisitionModel body,
  ) => createModel<PurchaseRequisitionModel>(
    '/purchase/requisitions',
    body,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<PurchaseRequisitionModel>> updateRequisition(
    int id,
    PurchaseRequisitionModel body,
  ) => updateModel<PurchaseRequisitionModel>(
    '/purchase/requisitions/$id',
    body,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteRequisition(int id) =>
      destroy('/purchase/requisitions/$id');
  Future<ApiResponse<PurchaseRequisitionModel>> approveRequisition(
    int id,
    PurchaseRequisitionModel body,
  ) => actionModel<PurchaseRequisitionModel>(
    '/purchase/requisitions/$id/approve',
    body: body,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<PurchaseRequisitionModel>> cancelRequisition(
    int id,
    PurchaseRequisitionModel body,
  ) => actionModel<PurchaseRequisitionModel>(
    '/purchase/requisitions/$id/cancel',
    body: body,
    fromJson: PurchaseRequisitionModel.fromJson,
  );
  Future<ApiResponse<PurchaseRequisitionModel>> closeRequisition(
    int id,
    PurchaseRequisitionModel body,
  ) => actionModel<PurchaseRequisitionModel>(
    '/purchase/requisitions/$id/close',
    body: body,
    fromJson: PurchaseRequisitionModel.fromJson,
  );

  Future<PaginatedResponse<PurchaseOrderModel>> orders({
    Map<String, dynamic>? filters,
  }) => paginated<PurchaseOrderModel>(
    '/purchase/orders',
    filters: filters,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<List<PurchaseOrderModel>>> ordersAll({
    Map<String, dynamic>? filters,
  }) => collection<PurchaseOrderModel>(
    '/purchase/orders/all',
    filters: filters,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<PurchaseOrderModel>> order(int id) =>
      object<PurchaseOrderModel>(
        '/purchase/orders/$id',
        fromJson: PurchaseOrderModel.fromJson,
      );
  Future<ApiResponse<PurchaseOrderModel>> createOrder(
    PurchaseOrderModel body,
  ) => createModel<PurchaseOrderModel>(
    '/purchase/orders',
    body,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<PurchaseOrderModel>> updateOrder(
    int id,
    PurchaseOrderModel body,
  ) => updateModel<PurchaseOrderModel>(
    '/purchase/orders/$id',
    body,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteOrder(int id) =>
      destroy('/purchase/orders/$id');
  Future<ApiResponse<PurchaseOrderModel>> postOrder(
    int id,
    PurchaseOrderModel body,
  ) => actionModel<PurchaseOrderModel>(
    '/purchase/orders/$id/post',
    body: body,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<PurchaseOrderModel>> cancelOrder(
    int id,
    PurchaseOrderModel body,
  ) => actionModel<PurchaseOrderModel>(
    '/purchase/orders/$id/cancel',
    body: body,
    fromJson: PurchaseOrderModel.fromJson,
  );
  Future<ApiResponse<PurchaseOrderModel>> closeOrder(
    int id,
    PurchaseOrderModel body,
  ) => actionModel<PurchaseOrderModel>(
    '/purchase/orders/$id/close',
    body: body,
    fromJson: PurchaseOrderModel.fromJson,
  );

  Future<PaginatedResponse<PurchaseReceiptModel>> receipts({
    Map<String, dynamic>? filters,
  }) => paginated<PurchaseReceiptModel>(
    '/purchase/receipts',
    filters: filters,
    fromJson: PurchaseReceiptModel.fromJson,
  );
  Future<ApiResponse<List<PurchaseReceiptModel>>> receiptsAll({
    Map<String, dynamic>? filters,
  }) => collection<PurchaseReceiptModel>(
    '/purchase/receipts/all',
    filters: filters,
    fromJson: PurchaseReceiptModel.fromJson,
  );
  Future<ApiResponse<PurchaseReceiptModel>> receipt(int id) =>
      object<PurchaseReceiptModel>(
        '/purchase/receipts/$id',
        fromJson: PurchaseReceiptModel.fromJson,
      );
  Future<ApiResponse<PurchaseReceiptModel>> createReceipt(
    PurchaseReceiptModel body,
  ) => createModel<PurchaseReceiptModel>(
    '/purchase/receipts',
    body,
    fromJson: PurchaseReceiptModel.fromJson,
  );
  Future<ApiResponse<PurchaseReceiptModel>> updateReceipt(
    int id,
    PurchaseReceiptModel body,
  ) => updateModel<PurchaseReceiptModel>(
    '/purchase/receipts/$id',
    body,
    fromJson: PurchaseReceiptModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteReceipt(int id) =>
      destroy('/purchase/receipts/$id');
  Future<ApiResponse<PurchaseReceiptModel>> postReceipt(
    int id,
    PurchaseReceiptModel body,
  ) => actionModel<PurchaseReceiptModel>(
    '/purchase/receipts/$id/post',
    body: body,
    fromJson: PurchaseReceiptModel.fromJson,
  );
  Future<ApiResponse<PurchaseReceiptModel>> cancelReceipt(
    int id,
    PurchaseReceiptModel body,
  ) => actionModel<PurchaseReceiptModel>(
    '/purchase/receipts/$id/cancel',
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
      destroy('/purchase/invoices/$id');

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
    '/purchase/payments',
    filters: filters,
    fromJson: PurchasePaymentModel.fromJson,
  );
  Future<ApiResponse<List<PurchasePaymentModel>>> paymentsAll({
    Map<String, dynamic>? filters,
  }) => collection<PurchasePaymentModel>(
    '/purchase/payments/all',
    filters: filters,
    fromJson: PurchasePaymentModel.fromJson,
  );
  Future<ApiResponse<PurchasePaymentModel>> payment(int id) =>
      object<PurchasePaymentModel>(
        '/purchase/payments/$id',
        fromJson: PurchasePaymentModel.fromJson,
      );
  Future<ApiResponse<PurchasePaymentModel>> createPayment(
    PurchasePaymentModel body,
  ) => createModel<PurchasePaymentModel>(
    '/purchase/payments',
    body,
    fromJson: PurchasePaymentModel.fromJson,
  );
  Future<ApiResponse<PurchasePaymentModel>> updatePayment(
    int id,
    PurchasePaymentModel body,
  ) => updateModel<PurchasePaymentModel>(
    '/purchase/payments/$id',
    body,
    fromJson: PurchasePaymentModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deletePayment(int id) =>
      destroy('/purchase/payments/$id');
  Future<ApiResponse<PurchasePaymentModel>> postPayment(
    int id,
    PurchasePaymentModel body,
  ) => actionModel<PurchasePaymentModel>(
    '/purchase/payments/$id/post',
    body: body,
    fromJson: PurchasePaymentModel.fromJson,
  );
  Future<ApiResponse<PurchasePaymentModel>> cancelPayment(
    int id,
    PurchasePaymentModel body,
  ) => actionModel<PurchasePaymentModel>(
    '/purchase/payments/$id/cancel',
    body: body,
    fromJson: PurchasePaymentModel.fromJson,
  );

  Future<PaginatedResponse<PurchaseReturnModel>> returns({
    Map<String, dynamic>? filters,
  }) => paginated<PurchaseReturnModel>(
    '/purchase/returns',
    filters: filters,
    fromJson: PurchaseReturnModel.fromJson,
  );
  Future<ApiResponse<List<PurchaseReturnModel>>> returnsAll({
    Map<String, dynamic>? filters,
  }) => collection<PurchaseReturnModel>(
    '/purchase/returns/all',
    filters: filters,
    fromJson: PurchaseReturnModel.fromJson,
  );
  Future<ApiResponse<PurchaseReturnModel>> returnDoc(int id) =>
      object<PurchaseReturnModel>(
        '/purchase/returns/$id',
        fromJson: PurchaseReturnModel.fromJson,
      );
  Future<ApiResponse<PurchaseReturnModel>> createReturn(
    PurchaseReturnModel body,
  ) => createModel<PurchaseReturnModel>(
    '/purchase/returns',
    body,
    fromJson: PurchaseReturnModel.fromJson,
  );
  Future<ApiResponse<PurchaseReturnModel>> updateReturn(
    int id,
    PurchaseReturnModel body,
  ) => updateModel<PurchaseReturnModel>(
    '/purchase/returns/$id',
    body,
    fromJson: PurchaseReturnModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteReturn(int id) =>
      destroy('/purchase/returns/$id');
  Future<ApiResponse<PurchaseReturnModel>> postReturn(
    int id,
    PurchaseReturnModel body,
  ) => actionModel<PurchaseReturnModel>(
    '/purchase/returns/$id/post',
    body: body,
    fromJson: PurchaseReturnModel.fromJson,
  );
  Future<ApiResponse<PurchaseReturnModel>> cancelReturn(
    int id,
    PurchaseReturnModel body,
  ) => actionModel<PurchaseReturnModel>(
    '/purchase/returns/$id/cancel',
    body: body,
    fromJson: PurchaseReturnModel.fromJson,
  );
}
