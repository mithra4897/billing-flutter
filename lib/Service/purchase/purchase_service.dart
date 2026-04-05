import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/purchase/purchase_invoice_model.dart';
import '../base/erp_module_service.dart';

class PurchaseService extends ErpModuleService {
  PurchaseService({super.apiClient});

  Future requisitions({Map<String, dynamic>? filters}) =>
      index('/purchase/requisitions', filters: filters);
  Future requisitionsAll({Map<String, dynamic>? filters}) =>
      list('/purchase/requisitions/all', filters: filters);
  Future requisition(int id) => show('/purchase/requisitions/$id');
  Future createRequisition(Map<String, dynamic> body) =>
      store('/purchase/requisitions', body);
  Future updateRequisition(int id, Map<String, dynamic> body) =>
      update('/purchase/requisitions/$id', body);
  Future deleteRequisition(int id) => destroy('/purchase/requisitions/$id');
  Future approveRequisition(int id, Map<String, dynamic> body) =>
      action('/purchase/requisitions/$id/approve', body: body);
  Future cancelRequisition(int id, Map<String, dynamic> body) =>
      action('/purchase/requisitions/$id/cancel', body: body);
  Future closeRequisition(int id, Map<String, dynamic> body) =>
      action('/purchase/requisitions/$id/close', body: body);

  Future orders({Map<String, dynamic>? filters}) =>
      index('/purchase/orders', filters: filters);
  Future ordersAll({Map<String, dynamic>? filters}) =>
      list('/purchase/orders/all', filters: filters);
  Future order(int id) => show('/purchase/orders/$id');
  Future createOrder(Map<String, dynamic> body) =>
      store('/purchase/orders', body);
  Future updateOrder(int id, Map<String, dynamic> body) =>
      update('/purchase/orders/$id', body);
  Future deleteOrder(int id) => destroy('/purchase/orders/$id');
  Future postOrder(int id, Map<String, dynamic> body) =>
      action('/purchase/orders/$id/post', body: body);
  Future cancelOrder(int id, Map<String, dynamic> body) =>
      action('/purchase/orders/$id/cancel', body: body);
  Future closeOrder(int id, Map<String, dynamic> body) =>
      action('/purchase/orders/$id/close', body: body);

  Future receipts({Map<String, dynamic>? filters}) =>
      index('/purchase/receipts', filters: filters);
  Future receiptsAll({Map<String, dynamic>? filters}) =>
      list('/purchase/receipts/all', filters: filters);
  Future receipt(int id) => show('/purchase/receipts/$id');
  Future createReceipt(Map<String, dynamic> body) =>
      store('/purchase/receipts', body);
  Future updateReceipt(int id, Map<String, dynamic> body) =>
      update('/purchase/receipts/$id', body);
  Future deleteReceipt(int id) => destroy('/purchase/receipts/$id');
  Future postReceipt(int id, Map<String, dynamic> body) =>
      action('/purchase/receipts/$id/post', body: body);
  Future cancelReceipt(int id, Map<String, dynamic> body) =>
      action('/purchase/receipts/$id/cancel', body: body);

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

  Future payments({Map<String, dynamic>? filters}) =>
      index('/purchase/payments', filters: filters);
  Future paymentsAll({Map<String, dynamic>? filters}) =>
      list('/purchase/payments/all', filters: filters);
  Future payment(int id) => show('/purchase/payments/$id');
  Future createPayment(Map<String, dynamic> body) =>
      store('/purchase/payments', body);
  Future updatePayment(int id, Map<String, dynamic> body) =>
      update('/purchase/payments/$id', body);
  Future deletePayment(int id) => destroy('/purchase/payments/$id');
  Future postPayment(int id, Map<String, dynamic> body) =>
      action('/purchase/payments/$id/post', body: body);
  Future cancelPayment(int id, Map<String, dynamic> body) =>
      action('/purchase/payments/$id/cancel', body: body);

  Future returns({Map<String, dynamic>? filters}) =>
      index('/purchase/returns', filters: filters);
  Future returnsAll({Map<String, dynamic>? filters}) =>
      list('/purchase/returns/all', filters: filters);
  Future returnDoc(int id) => show('/purchase/returns/$id');
  Future createReturn(Map<String, dynamic> body) =>
      store('/purchase/returns', body);
  Future updateReturn(int id, Map<String, dynamic> body) =>
      update('/purchase/returns/$id', body);
  Future deleteReturn(int id) => destroy('/purchase/returns/$id');
  Future postReturn(int id, Map<String, dynamic> body) =>
      action('/purchase/returns/$id/post', body: body);
  Future cancelReturn(int id, Map<String, dynamic> body) =>
      action('/purchase/returns/$id/cancel', body: body);
}
