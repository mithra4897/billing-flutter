import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/paginated_response.dart';
import '../models/purchase_invoice_model.dart';

class PurchaseService {
  PurchaseService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PaginatedResponse<PurchaseInvoiceModel>> getInvoices({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<PurchaseInvoiceModel>(
      ApiEndpoints.purchaseInvoices,
      queryParameters: filters,
      itemFromJson: PurchaseInvoiceModel.fromJson,
    );
  }

  Future<ApiResponse<PurchaseInvoiceModel>> getInvoice(int id) {
    return _apiClient.get<PurchaseInvoiceModel>(
      '${ApiEndpoints.purchaseInvoices}/$id',
      fromData: (json) =>
          PurchaseInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PurchaseInvoiceModel>> createInvoice(
    PurchaseInvoiceModel invoice,
  ) {
    return _apiClient.post<PurchaseInvoiceModel>(
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
    return _apiClient.put<PurchaseInvoiceModel>(
      '${ApiEndpoints.purchaseInvoices}/$id',
      body: invoice.toCreateJson(),
      fromData: (json) =>
          PurchaseInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PurchaseInvoiceModel>> postInvoice(int id) {
    return _apiClient.post<PurchaseInvoiceModel>(
      '${ApiEndpoints.purchaseInvoices}/$id/post',
      fromData: (json) =>
          PurchaseInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PurchaseInvoiceModel>> cancelInvoice(int id) {
    return _apiClient.post<PurchaseInvoiceModel>(
      '${ApiEndpoints.purchaseInvoices}/$id/cancel',
      fromData: (json) =>
          PurchaseInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
