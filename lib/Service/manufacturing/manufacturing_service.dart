import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/manufacturing/bom_model.dart';
import '../../model/manufacturing/production_material_issue_model.dart';
import '../../model/manufacturing/production_order_model.dart';
import '../../model/manufacturing/production_receipt_model.dart';
import '../base/erp_module_service.dart';

class ManufacturingService extends ErpModuleService {
  ManufacturingService({super.apiClient});

  Future<PaginatedResponse<BomModel>> boms({Map<String, dynamic>? filters}) =>
      paginated<BomModel>(
        '/manufacturing/boms',
        filters: filters,
        fromJson: BomModel.fromJson,
      );
  Future<ApiResponse<BomModel>> bom(int id) =>
      object<BomModel>('/manufacturing/boms/$id', fromJson: BomModel.fromJson);
  Future<ApiResponse<BomModel>> createBom(BomModel body) =>
      createModel<BomModel>(
        '/manufacturing/boms',
        body,
        fromJson: BomModel.fromJson,
      );
  Future<ApiResponse<BomModel>> updateBom(int id, BomModel body) =>
      updateModel<BomModel>(
        '/manufacturing/boms/$id',
        body,
        fromJson: BomModel.fromJson,
      );
  Future<ApiResponse<BomModel>> approveBom(int id, BomModel body) =>
      actionModel<BomModel>(
        '/manufacturing/boms/$id/approve',
        body: body,
        fromJson: BomModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteBom(int id) =>
      destroy('/manufacturing/boms/$id');

  Future<PaginatedResponse<ProductionOrderModel>> productionOrders({
    Map<String, dynamic>? filters,
  }) => paginated<ProductionOrderModel>(
    '/manufacturing/production-orders',
    filters: filters,
    fromJson: ProductionOrderModel.fromJson,
  );
  Future<ApiResponse<ProductionOrderModel>> productionOrder(int id) =>
      object<ProductionOrderModel>(
        '/manufacturing/production-orders/$id',
        fromJson: ProductionOrderModel.fromJson,
      );
  Future<ApiResponse<ProductionOrderModel>> createProductionOrder(
    ProductionOrderModel body,
  ) {
    return createModel<ProductionOrderModel>(
      '/manufacturing/production-orders',
      body,
      fromJson: ProductionOrderModel.fromJson,
    );
  }

  Future<ApiResponse<ProductionOrderModel>> updateProductionOrder(
    int id,
    ProductionOrderModel body,
  ) => updateModel<ProductionOrderModel>(
    '/manufacturing/production-orders/$id',
    body,
    fromJson: ProductionOrderModel.fromJson,
  );
  Future<ApiResponse<ProductionOrderModel>> releaseProductionOrder(
    int id,
    ProductionOrderModel body,
  ) => actionModel<ProductionOrderModel>(
    '/manufacturing/production-orders/$id/release',
    body: body,
    fromJson: ProductionOrderModel.fromJson,
  );
  Future<ApiResponse<ProductionOrderModel>> closeProductionOrder(
    int id,
    ProductionOrderModel body,
  ) => actionModel<ProductionOrderModel>(
    '/manufacturing/production-orders/$id/close',
    body: body,
    fromJson: ProductionOrderModel.fromJson,
  );
  Future<ApiResponse<ProductionOrderModel>> cancelProductionOrder(
    int id,
    ProductionOrderModel body,
  ) => actionModel<ProductionOrderModel>(
    '/manufacturing/production-orders/$id/cancel',
    body: body,
    fromJson: ProductionOrderModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteProductionOrder(int id) =>
      destroy('/manufacturing/production-orders/$id');

  Future<PaginatedResponse<ProductionMaterialIssueModel>>
  productionMaterialIssues({Map<String, dynamic>? filters}) =>
      paginated<ProductionMaterialIssueModel>(
        '/manufacturing/production-material-issues',
        filters: filters,
        fromJson: ProductionMaterialIssueModel.fromJson,
      );
  Future<ApiResponse<ProductionMaterialIssueModel>> productionMaterialIssue(
    int id,
  ) => object<ProductionMaterialIssueModel>(
    '/manufacturing/production-material-issues/$id',
    fromJson: ProductionMaterialIssueModel.fromJson,
  );
  Future<ApiResponse<List<Map<String, dynamic>>>>
  productionMaterialIssueAuditTrail(int id) {
    return client.get<List<Map<String, dynamic>>>(
      '/manufacturing/production-material-issues/$id/audit-trail',
      fromData: (dynamic json) {
        if (json is! List) {
          return <Map<String, dynamic>>[];
        }
        return json
            .map((dynamic e) {
              if (e is Map<String, dynamic>) {
                return e;
              }
              if (e is Map) {
                return Map<String, dynamic>.from(e);
              }
              return <String, dynamic>{};
            })
            .where((m) => m.isNotEmpty)
            .toList();
      },
    );
  }

  Future<ApiResponse<ProductionMaterialIssueModel>>
  createProductionMaterialIssue(ProductionMaterialIssueModel body) =>
      createModel<ProductionMaterialIssueModel>(
        '/manufacturing/production-material-issues',
        body,
        fromJson: ProductionMaterialIssueModel.fromJson,
      );
  Future<ApiResponse<ProductionMaterialIssueModel>>
  updateProductionMaterialIssue(int id, ProductionMaterialIssueModel body) =>
      updateModel<ProductionMaterialIssueModel>(
        '/manufacturing/production-material-issues/$id',
        body,
        fromJson: ProductionMaterialIssueModel.fromJson,
      );
  Future<ApiResponse<ProductionMaterialIssueModel>> postProductionMaterialIssue(
    int id,
    ProductionMaterialIssueModel body,
  ) => actionModel<ProductionMaterialIssueModel>(
    '/manufacturing/production-material-issues/$id/post',
    body: body,
    fromJson: ProductionMaterialIssueModel.fromJson,
  );
  Future<ApiResponse<ProductionMaterialIssueModel>>
  cancelProductionMaterialIssue(int id, ProductionMaterialIssueModel body) =>
      actionModel<ProductionMaterialIssueModel>(
        '/manufacturing/production-material-issues/$id/cancel',
        body: body,
        fromJson: ProductionMaterialIssueModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteProductionMaterialIssue(int id) =>
      destroy('/manufacturing/production-material-issues/$id');

  Future<PaginatedResponse<ProductionReceiptModel>> productionReceipts({
    Map<String, dynamic>? filters,
  }) => paginated<ProductionReceiptModel>(
    '/manufacturing/production-receipts',
    filters: filters,
    fromJson: ProductionReceiptModel.fromJson,
  );
  Future<ApiResponse<ProductionReceiptModel>> productionReceipt(int id) =>
      object<ProductionReceiptModel>(
        '/manufacturing/production-receipts/$id',
        fromJson: ProductionReceiptModel.fromJson,
      );
  Future<ApiResponse<ProductionReceiptModel>> createProductionReceipt(
    ProductionReceiptModel body,
  ) => createModel<ProductionReceiptModel>(
    '/manufacturing/production-receipts',
    body,
    fromJson: ProductionReceiptModel.fromJson,
  );
  Future<ApiResponse<ProductionReceiptModel>> updateProductionReceipt(
    int id,
    ProductionReceiptModel body,
  ) => updateModel<ProductionReceiptModel>(
    '/manufacturing/production-receipts/$id',
    body,
    fromJson: ProductionReceiptModel.fromJson,
  );
  Future<ApiResponse<ProductionReceiptModel>> postProductionReceipt(
    int id,
    ProductionReceiptModel body,
  ) => actionModel<ProductionReceiptModel>(
    '/manufacturing/production-receipts/$id/post',
    body: body,
    fromJson: ProductionReceiptModel.fromJson,
  );
  Future<ApiResponse<ProductionReceiptModel>> cancelProductionReceipt(
    int id,
    ProductionReceiptModel body,
  ) => actionModel<ProductionReceiptModel>(
    '/manufacturing/production-receipts/$id/cancel',
    body: body,
    fromJson: ProductionReceiptModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteProductionReceipt(int id) =>
      destroy('/manufacturing/production-receipts/$id');
}
