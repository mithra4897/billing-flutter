import '../../features/purchase/models/purchase_invoice_model.dart';
import '../../features/purchase/services/purchase_service.dart';
import '../base/erp_module_service.dart';

class PurchaseModuleService extends ErpModuleService {
  PurchaseModuleService({super.apiClient})
    : _typed = PurchaseService(apiClient: apiClient);

  final PurchaseService _typed;

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

  Future invoices({Map<String, dynamic>? filters}) =>
      _typed.getInvoices(filters: filters);
  Future invoicesAll({Map<String, dynamic>? filters}) =>
      list('/purchase/invoices/all', filters: filters);
  Future invoice(int id) => _typed.getInvoice(id);
  Future createInvoice(PurchaseInvoiceModel invoice) =>
      _typed.createInvoice(invoice);
  Future updateInvoiceModel(int id, PurchaseInvoiceModel invoice) =>
      _typed.updateInvoice(id, invoice);
  Future deleteInvoice(int id) => destroy('/purchase/invoices/$id');
  Future postInvoice(int id) => _typed.postInvoice(id);
  Future cancelInvoice(int id) => _typed.cancelInvoice(id);

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
