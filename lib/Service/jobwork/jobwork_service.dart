import '../base/erp_module_service.dart';

class JobworkService extends ErpModuleService {
  JobworkService({super.apiClient});

  Future orders({Map<String, dynamic>? filters}) =>
      index('/jobwork/orders', filters: filters);
  Future order(int id) => show('/jobwork/orders/$id');
  Future createOrder(Map<String, dynamic> body) =>
      store('/jobwork/orders', body);
  Future updateOrder(int id, Map<String, dynamic> body) =>
      update('/jobwork/orders/$id', body);
  Future releaseOrder(int id, Map<String, dynamic> body) =>
      action('/jobwork/orders/$id/release', body: body);
  Future closeOrder(int id, Map<String, dynamic> body) =>
      action('/jobwork/orders/$id/close', body: body);
  Future cancelOrder(int id, Map<String, dynamic> body) =>
      action('/jobwork/orders/$id/cancel', body: body);
  Future deleteOrder(int id) => destroy('/jobwork/orders/$id');

  Future dispatches({Map<String, dynamic>? filters}) =>
      index('/jobwork/dispatches', filters: filters);
  Future dispatch(int id) => show('/jobwork/dispatches/$id');
  Future createDispatch(Map<String, dynamic> body) =>
      store('/jobwork/dispatches', body);
  Future updateDispatch(int id, Map<String, dynamic> body) =>
      update('/jobwork/dispatches/$id', body);
  Future postDispatch(int id, Map<String, dynamic> body) =>
      action('/jobwork/dispatches/$id/post', body: body);
  Future cancelDispatch(int id, Map<String, dynamic> body) =>
      action('/jobwork/dispatches/$id/cancel', body: body);
  Future deleteDispatch(int id) => destroy('/jobwork/dispatches/$id');

  Future receipts({Map<String, dynamic>? filters}) =>
      index('/jobwork/receipts', filters: filters);
  Future receipt(int id) => show('/jobwork/receipts/$id');
  Future createReceipt(Map<String, dynamic> body) =>
      store('/jobwork/receipts', body);
  Future updateReceipt(int id, Map<String, dynamic> body) =>
      update('/jobwork/receipts/$id', body);
  Future postReceipt(int id, Map<String, dynamic> body) =>
      action('/jobwork/receipts/$id/post', body: body);
  Future cancelReceipt(int id, Map<String, dynamic> body) =>
      action('/jobwork/receipts/$id/cancel', body: body);
  Future deleteReceipt(int id) => destroy('/jobwork/receipts/$id');

  Future charges({Map<String, dynamic>? filters}) =>
      index('/jobwork/charges', filters: filters);
  Future charge(int id) => show('/jobwork/charges/$id');
  Future createCharge(Map<String, dynamic> body) =>
      store('/jobwork/charges', body);
  Future updateCharge(int id, Map<String, dynamic> body) =>
      update('/jobwork/charges/$id', body);
  Future postCharge(int id, Map<String, dynamic> body) =>
      action('/jobwork/charges/$id/post', body: body);
  Future cancelCharge(int id, Map<String, dynamic> body) =>
      action('/jobwork/charges/$id/cancel', body: body);
  Future deleteCharge(int id) => destroy('/jobwork/charges/$id');
}
