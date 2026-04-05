import '../../features/sales/models/sales_invoice_model.dart';
import '../../features/sales/services/sales_service.dart';
import '../base/erp_module_service.dart';

class SalesModuleService extends ErpModuleService {
  SalesModuleService({super.apiClient})
    : _typed = SalesService(apiClient: apiClient);

  final SalesService _typed;

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

  Future invoices({Map<String, dynamic>? filters}) =>
      _typed.getInvoices(filters: filters);
  Future invoicesAll({Map<String, dynamic>? filters}) =>
      list('/sales/invoices/all', filters: filters);
  Future invoice(int id) => _typed.getInvoice(id);
  Future createInvoice(SalesInvoiceModel invoice) =>
      _typed.createInvoice(invoice);
  Future updateInvoiceModel(int id, SalesInvoiceModel invoice) =>
      _typed.updateInvoice(id, invoice);
  Future deleteInvoice(int id) => destroy('/sales/invoices/$id');
  Future postInvoice(int id) => _typed.postInvoice(id);
  Future cancelInvoice(int id) => _typed.cancelInvoice(id);

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
