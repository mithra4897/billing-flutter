import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/sales/sales_invoice_model.dart';
import '../base/erp_module_service.dart';

class SalesService extends ErpModuleService {
  SalesService({super.apiClient});

  Future quotations({Map<String, dynamic>? filters}) =>
      index('/sales/quotations', filters: filters);
  Future quotationsAll({Map<String, dynamic>? filters}) =>
      list('/sales/quotations/all', filters: filters);
  Future quotation(int id) => show('/sales/quotations/$id');
  Future createQuotation(Map<String, dynamic> body) =>
      store('/sales/quotations', body);
  Future updateQuotation(int id, Map<String, dynamic> body) =>
      update('/sales/quotations/$id', body);
  Future deleteQuotation(int id) => destroy('/sales/quotations/$id');
  Future sendQuotation(int id, Map<String, dynamic> body) =>
      action('/sales/quotations/$id/send', body: body);
  Future acceptQuotation(int id, Map<String, dynamic> body) =>
      action('/sales/quotations/$id/accept', body: body);
  Future rejectQuotation(int id, Map<String, dynamic> body) =>
      action('/sales/quotations/$id/reject', body: body);
  Future expireQuotation(int id, Map<String, dynamic> body) =>
      action('/sales/quotations/$id/expire', body: body);
  Future cancelQuotation(int id, Map<String, dynamic> body) =>
      action('/sales/quotations/$id/cancel', body: body);

  Future orders({Map<String, dynamic>? filters}) =>
      index('/sales/orders', filters: filters);
  Future ordersAll({Map<String, dynamic>? filters}) =>
      list('/sales/orders/all', filters: filters);
  Future order(int id) => show('/sales/orders/$id');
  Future createOrder(Map<String, dynamic> body) => store('/sales/orders', body);
  Future updateOrder(int id, Map<String, dynamic> body) =>
      update('/sales/orders/$id', body);
  Future deleteOrder(int id) => destroy('/sales/orders/$id');
  Future confirmOrder(int id, Map<String, dynamic> body) =>
      action('/sales/orders/$id/confirm', body: body);
  Future cancelOrder(int id, Map<String, dynamic> body) =>
      action('/sales/orders/$id/cancel', body: body);
  Future closeOrder(int id, Map<String, dynamic> body) =>
      action('/sales/orders/$id/close', body: body);

  Future deliveries({Map<String, dynamic>? filters}) =>
      index('/sales/deliveries', filters: filters);
  Future deliveriesAll({Map<String, dynamic>? filters}) =>
      list('/sales/deliveries/all', filters: filters);
  Future delivery(int id) => show('/sales/deliveries/$id');
  Future createDelivery(Map<String, dynamic> body) =>
      store('/sales/deliveries', body);
  Future updateDelivery(int id, Map<String, dynamic> body) =>
      update('/sales/deliveries/$id', body);
  Future deleteDelivery(int id) => destroy('/sales/deliveries/$id');
  Future postDelivery(int id, Map<String, dynamic> body) =>
      action('/sales/deliveries/$id/post', body: body);
  Future cancelDelivery(int id, Map<String, dynamic> body) =>
      action('/sales/deliveries/$id/cancel', body: body);

  Future<PaginatedResponse<SalesInvoiceModel>> invoices({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<SalesInvoiceModel>(
      ApiEndpoints.salesInvoices,
      queryParameters: filters,
      itemFromJson: SalesInvoiceModel.fromJson,
    );
  }

  Future<PaginatedResponse<SalesInvoiceModel>> getInvoices({
    Map<String, dynamic>? filters,
  }) => invoices(filters: filters);

  Future<ApiResponse<SalesInvoiceModel>> invoice(int id) {
    return client.get<SalesInvoiceModel>(
      '${ApiEndpoints.salesInvoices}/$id',
      fromData: (json) =>
          SalesInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<SalesInvoiceModel>> getInvoice(int id) => invoice(id);

  Future<ApiResponse<SalesInvoiceModel>> createInvoice(
    SalesInvoiceModel invoice,
  ) {
    return client.post<SalesInvoiceModel>(
      ApiEndpoints.salesInvoices,
      body: invoice.toCreateJson(),
      fromData: (json) =>
          SalesInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<SalesInvoiceModel>> updateInvoice(
    int id,
    SalesInvoiceModel invoice,
  ) {
    return client.put<SalesInvoiceModel>(
      '${ApiEndpoints.salesInvoices}/$id',
      body: invoice.toCreateJson(),
      fromData: (json) =>
          SalesInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> deleteInvoice(int id) =>
      destroy('/sales/invoices/$id');

  Future<ApiResponse<SalesInvoiceModel>> postInvoice(int id) {
    return client.post<SalesInvoiceModel>(
      '${ApiEndpoints.salesInvoices}/$id/post',
      fromData: (json) =>
          SalesInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<SalesInvoiceModel>> cancelInvoice(int id) {
    return client.post<SalesInvoiceModel>(
      '${ApiEndpoints.salesInvoices}/$id/cancel',
      fromData: (json) =>
          SalesInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future receipts({Map<String, dynamic>? filters}) =>
      index('/sales/receipts', filters: filters);
  Future receiptsAll({Map<String, dynamic>? filters}) =>
      list('/sales/receipts/all', filters: filters);
  Future receipt(int id) => show('/sales/receipts/$id');
  Future createReceipt(Map<String, dynamic> body) =>
      store('/sales/receipts', body);
  Future updateReceipt(int id, Map<String, dynamic> body) =>
      update('/sales/receipts/$id', body);
  Future deleteReceipt(int id) => destroy('/sales/receipts/$id');
  Future postReceipt(int id, Map<String, dynamic> body) =>
      action('/sales/receipts/$id/post', body: body);
  Future cancelReceipt(int id, Map<String, dynamic> body) =>
      action('/sales/receipts/$id/cancel', body: body);

  Future returns({Map<String, dynamic>? filters}) =>
      index('/sales/returns', filters: filters);
  Future returnsAll({Map<String, dynamic>? filters}) =>
      list('/sales/returns/all', filters: filters);
  Future returnDoc(int id) => show('/sales/returns/$id');
  Future createReturn(Map<String, dynamic> body) =>
      store('/sales/returns', body);
  Future updateReturn(int id, Map<String, dynamic> body) =>
      update('/sales/returns/$id', body);
  Future deleteReturn(int id) => destroy('/sales/returns/$id');
  Future postReturn(int id, Map<String, dynamic> body) =>
      action('/sales/returns/$id/post', body: body);
  Future cancelReturn(int id, Map<String, dynamic> body) =>
      action('/sales/returns/$id/cancel', body: body);
}
