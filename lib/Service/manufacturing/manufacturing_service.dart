import '../base/erp_module_service.dart';

class ManufacturingService extends ErpModuleService {
  ManufacturingService({super.apiClient});

  Future boms({Map<String, dynamic>? filters}) =>
      index('/manufacturing/boms', filters: filters);
  Future bom(int id) => show('/manufacturing/boms/$id');
  Future createBom(Map<String, dynamic> body) =>
      store('/manufacturing/boms', body);
  Future updateBom(int id, Map<String, dynamic> body) =>
      update('/manufacturing/boms/$id', body);
  Future approveBom(int id, Map<String, dynamic> body) =>
      action('/manufacturing/boms/$id/approve', body: body);
  Future deleteBom(int id) => destroy('/manufacturing/boms/$id');

  Future productionOrders({Map<String, dynamic>? filters}) =>
      index('/manufacturing/production-orders', filters: filters);
  Future productionOrder(int id) =>
      show('/manufacturing/production-orders/$id');
  Future createProductionOrder(Map<String, dynamic> body) =>
      store('/manufacturing/production-orders', body);
  Future updateProductionOrder(int id, Map<String, dynamic> body) =>
      update('/manufacturing/production-orders/$id', body);
  Future releaseProductionOrder(int id, Map<String, dynamic> body) =>
      action('/manufacturing/production-orders/$id/release', body: body);
  Future closeProductionOrder(int id, Map<String, dynamic> body) =>
      action('/manufacturing/production-orders/$id/close', body: body);
  Future cancelProductionOrder(int id, Map<String, dynamic> body) =>
      action('/manufacturing/production-orders/$id/cancel', body: body);
  Future deleteProductionOrder(int id) =>
      destroy('/manufacturing/production-orders/$id');

  Future productionMaterialIssues({Map<String, dynamic>? filters}) =>
      index('/manufacturing/production-material-issues', filters: filters);
  Future productionMaterialIssue(int id) =>
      show('/manufacturing/production-material-issues/$id');
  Future createProductionMaterialIssue(Map<String, dynamic> body) =>
      store('/manufacturing/production-material-issues', body);
  Future updateProductionMaterialIssue(int id, Map<String, dynamic> body) =>
      update('/manufacturing/production-material-issues/$id', body);
  Future postProductionMaterialIssue(int id, Map<String, dynamic> body) =>
      action('/manufacturing/production-material-issues/$id/post', body: body);
  Future cancelProductionMaterialIssue(int id, Map<String, dynamic> body) =>
      action(
        '/manufacturing/production-material-issues/$id/cancel',
        body: body,
      );
  Future deleteProductionMaterialIssue(int id) =>
      destroy('/manufacturing/production-material-issues/$id');

  Future productionReceipts({Map<String, dynamic>? filters}) =>
      index('/manufacturing/production-receipts', filters: filters);
  Future productionReceipt(int id) =>
      show('/manufacturing/production-receipts/$id');
  Future createProductionReceipt(Map<String, dynamic> body) =>
      store('/manufacturing/production-receipts', body);
  Future updateProductionReceipt(int id, Map<String, dynamic> body) =>
      update('/manufacturing/production-receipts/$id', body);
  Future postProductionReceipt(int id, Map<String, dynamic> body) =>
      action('/manufacturing/production-receipts/$id/post', body: body);
  Future cancelProductionReceipt(int id, Map<String, dynamic> body) =>
      action('/manufacturing/production-receipts/$id/cancel', body: body);
  Future deleteProductionReceipt(int id) =>
      destroy('/manufacturing/production-receipts/$id');
}
