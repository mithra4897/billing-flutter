import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/sales/sales_delivery_model.dart';
import '../../model/sales/sales_invoice_model.dart';
import '../../model/sales/sales_order_model.dart';
import '../../model/sales/sales_quotation_model.dart';
import '../../model/sales/sales_receipt_model.dart';
import '../../model/sales/sales_return_model.dart';
import '../base/erp_module_service.dart';

class SalesService extends ErpModuleService {
  SalesService({super.apiClient});

  Future<PaginatedResponse<SalesQuotationModel>> quotations({
    Map<String, dynamic>? filters,
  }) => paginated<SalesQuotationModel>(
    '/sales/quotations',
    filters: filters,
    fromJson: SalesQuotationModel.fromJson,
  );
  Future<ApiResponse<List<SalesQuotationModel>>> quotationsAll({
    Map<String, dynamic>? filters,
  }) => collection<SalesQuotationModel>(
    '/sales/quotations/all',
    filters: filters,
    fromJson: SalesQuotationModel.fromJson,
  );
  Future<ApiResponse<SalesQuotationModel>> quotation(int id) =>
      object<SalesQuotationModel>(
        '/sales/quotations/$id',
        fromJson: SalesQuotationModel.fromJson,
      );
  Future<ApiResponse<SalesQuotationModel>> createQuotation(
    SalesQuotationModel body,
  ) => createModel<SalesQuotationModel>(
    '/sales/quotations',
    body,
    fromJson: SalesQuotationModel.fromJson,
  );
  Future<ApiResponse<SalesQuotationModel>> updateQuotation(
    int id,
    SalesQuotationModel body,
  ) => updateModel<SalesQuotationModel>(
    '/sales/quotations/$id',
    body,
    fromJson: SalesQuotationModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteQuotation(int id) =>
      destroy('/sales/quotations/$id');
  Future<ApiResponse<SalesQuotationModel>> sendQuotation(
    int id,
    SalesQuotationModel body,
  ) => actionModel<SalesQuotationModel>(
    '/sales/quotations/$id/send',
    body: body,
    fromJson: SalesQuotationModel.fromJson,
  );
  Future<ApiResponse<SalesQuotationModel>> acceptQuotation(
    int id,
    SalesQuotationModel body,
  ) => actionModel<SalesQuotationModel>(
    '/sales/quotations/$id/accept',
    body: body,
    fromJson: SalesQuotationModel.fromJson,
  );
  Future<ApiResponse<SalesQuotationModel>> rejectQuotation(
    int id,
    SalesQuotationModel body,
  ) => actionModel<SalesQuotationModel>(
    '/sales/quotations/$id/reject',
    body: body,
    fromJson: SalesQuotationModel.fromJson,
  );
  Future<ApiResponse<SalesQuotationModel>> expireQuotation(
    int id,
    SalesQuotationModel body,
  ) => actionModel<SalesQuotationModel>(
    '/sales/quotations/$id/expire',
    body: body,
    fromJson: SalesQuotationModel.fromJson,
  );
  Future<ApiResponse<SalesQuotationModel>> cancelQuotation(
    int id,
    SalesQuotationModel body,
  ) => actionModel<SalesQuotationModel>(
    '/sales/quotations/$id/cancel',
    body: body,
    fromJson: SalesQuotationModel.fromJson,
  );

  Future<PaginatedResponse<SalesOrderModel>> orders({
    Map<String, dynamic>? filters,
  }) => paginated<SalesOrderModel>(
    '/sales/orders',
    filters: filters,
    fromJson: SalesOrderModel.fromJson,
  );
  Future<ApiResponse<List<SalesOrderModel>>> ordersAll({
    Map<String, dynamic>? filters,
  }) => collection<SalesOrderModel>(
    '/sales/orders/all',
    filters: filters,
    fromJson: SalesOrderModel.fromJson,
  );
  Future<ApiResponse<SalesOrderModel>> order(int id) => object<SalesOrderModel>(
    '/sales/orders/$id',
    fromJson: SalesOrderModel.fromJson,
  );
  Future<ApiResponse<SalesOrderModel>> createOrder(SalesOrderModel body) =>
      createModel<SalesOrderModel>(
        '/sales/orders',
        body,
        fromJson: SalesOrderModel.fromJson,
      );
  Future<ApiResponse<SalesOrderModel>> updateOrder(
    int id,
    SalesOrderModel body,
  ) => updateModel<SalesOrderModel>(
    '/sales/orders/$id',
    body,
    fromJson: SalesOrderModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteOrder(int id) =>
      destroy('/sales/orders/$id');
  Future<ApiResponse<SalesOrderModel>> confirmOrder(
    int id,
    SalesOrderModel body,
  ) => actionModel<SalesOrderModel>(
    '/sales/orders/$id/confirm',
    body: body,
    fromJson: SalesOrderModel.fromJson,
  );
  Future<ApiResponse<SalesOrderModel>> cancelOrder(
    int id,
    SalesOrderModel body,
  ) => actionModel<SalesOrderModel>(
    '/sales/orders/$id/cancel',
    body: body,
    fromJson: SalesOrderModel.fromJson,
  );
  Future<ApiResponse<SalesOrderModel>> closeOrder(
    int id,
    SalesOrderModel body,
  ) => actionModel<SalesOrderModel>(
    '/sales/orders/$id/close',
    body: body,
    fromJson: SalesOrderModel.fromJson,
  );

  Future<PaginatedResponse<SalesDeliveryModel>> deliveries({
    Map<String, dynamic>? filters,
  }) => paginated<SalesDeliveryModel>(
    '/sales/deliveries',
    filters: filters,
    fromJson: SalesDeliveryModel.fromJson,
  );
  Future<ApiResponse<List<SalesDeliveryModel>>> deliveriesAll({
    Map<String, dynamic>? filters,
  }) => collection<SalesDeliveryModel>(
    '/sales/deliveries/all',
    filters: filters,
    fromJson: SalesDeliveryModel.fromJson,
  );
  Future<ApiResponse<SalesDeliveryModel>> delivery(int id) =>
      object<SalesDeliveryModel>(
        '/sales/deliveries/$id',
        fromJson: SalesDeliveryModel.fromJson,
      );
  Future<ApiResponse<SalesDeliveryModel>> createDelivery(
    SalesDeliveryModel body,
  ) => createModel<SalesDeliveryModel>(
    '/sales/deliveries',
    body,
    fromJson: SalesDeliveryModel.fromJson,
  );
  Future<ApiResponse<SalesDeliveryModel>> updateDelivery(
    int id,
    SalesDeliveryModel body,
  ) => updateModel<SalesDeliveryModel>(
    '/sales/deliveries/$id',
    body,
    fromJson: SalesDeliveryModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteDelivery(int id) =>
      destroy('/sales/deliveries/$id');
  Future<ApiResponse<SalesDeliveryModel>> postDelivery(
    int id,
    SalesDeliveryModel body,
  ) => actionModel<SalesDeliveryModel>(
    '/sales/deliveries/$id/post',
    body: body,
    fromJson: SalesDeliveryModel.fromJson,
  );
  Future<ApiResponse<SalesDeliveryModel>> cancelDelivery(
    int id,
    SalesDeliveryModel body,
  ) => actionModel<SalesDeliveryModel>(
    '/sales/deliveries/$id/cancel',
    body: body,
    fromJson: SalesDeliveryModel.fromJson,
  );

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

  Future<PaginatedResponse<SalesReceiptModel>> receipts({
    Map<String, dynamic>? filters,
  }) => paginated<SalesReceiptModel>(
    '/sales/receipts',
    filters: filters,
    fromJson: SalesReceiptModel.fromJson,
  );
  Future<ApiResponse<List<SalesReceiptModel>>> receiptsAll({
    Map<String, dynamic>? filters,
  }) => collection<SalesReceiptModel>(
    '/sales/receipts/all',
    filters: filters,
    fromJson: SalesReceiptModel.fromJson,
  );
  Future<ApiResponse<SalesReceiptModel>> receipt(int id) =>
      object<SalesReceiptModel>(
        '/sales/receipts/$id',
        fromJson: SalesReceiptModel.fromJson,
      );
  Future<ApiResponse<SalesReceiptModel>> createReceipt(
    SalesReceiptModel body,
  ) => createModel<SalesReceiptModel>(
    '/sales/receipts',
    body,
    fromJson: SalesReceiptModel.fromJson,
  );
  Future<ApiResponse<SalesReceiptModel>> updateReceipt(
    int id,
    SalesReceiptModel body,
  ) => updateModel<SalesReceiptModel>(
    '/sales/receipts/$id',
    body,
    fromJson: SalesReceiptModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteReceipt(int id) =>
      destroy('/sales/receipts/$id');
  Future<ApiResponse<SalesReceiptModel>> postReceipt(
    int id,
    SalesReceiptModel body,
  ) => actionModel<SalesReceiptModel>(
    '/sales/receipts/$id/post',
    body: body,
    fromJson: SalesReceiptModel.fromJson,
  );
  Future<ApiResponse<SalesReceiptModel>> cancelReceipt(
    int id,
    SalesReceiptModel body,
  ) => actionModel<SalesReceiptModel>(
    '/sales/receipts/$id/cancel',
    body: body,
    fromJson: SalesReceiptModel.fromJson,
  );

  Future<PaginatedResponse<SalesReturnModel>> returns({
    Map<String, dynamic>? filters,
  }) => paginated<SalesReturnModel>(
    '/sales/returns',
    filters: filters,
    fromJson: SalesReturnModel.fromJson,
  );
  Future<ApiResponse<List<SalesReturnModel>>> returnsAll({
    Map<String, dynamic>? filters,
  }) => collection<SalesReturnModel>(
    '/sales/returns/all',
    filters: filters,
    fromJson: SalesReturnModel.fromJson,
  );
  Future<ApiResponse<SalesReturnModel>> returnDoc(int id) =>
      object<SalesReturnModel>(
        '/sales/returns/$id',
        fromJson: SalesReturnModel.fromJson,
      );
  Future<ApiResponse<SalesReturnModel>> createReturn(SalesReturnModel body) =>
      createModel<SalesReturnModel>(
        '/sales/returns',
        body,
        fromJson: SalesReturnModel.fromJson,
      );
  Future<ApiResponse<SalesReturnModel>> updateReturn(
    int id,
    SalesReturnModel body,
  ) => updateModel<SalesReturnModel>(
    '/sales/returns/$id',
    body,
    fromJson: SalesReturnModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteReturn(int id) =>
      destroy('/sales/returns/$id');
  Future<ApiResponse<SalesReturnModel>> postReturn(
    int id,
    SalesReturnModel body,
  ) => actionModel<SalesReturnModel>(
    '/sales/returns/$id/post',
    body: body,
    fromJson: SalesReturnModel.fromJson,
  );
  Future<ApiResponse<SalesReturnModel>> cancelReturn(
    int id,
    SalesReturnModel body,
  ) => actionModel<SalesReturnModel>(
    '/sales/returns/$id/cancel',
    body: body,
    fromJson: SalesReturnModel.fromJson,
  );
}
