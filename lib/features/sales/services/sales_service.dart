import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/paginated_response.dart';
import '../models/sales_invoice_model.dart';

class SalesService {
  SalesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PaginatedResponse<SalesInvoiceModel>> getInvoices({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<SalesInvoiceModel>(
      ApiEndpoints.salesInvoices,
      queryParameters: filters,
      itemFromJson: SalesInvoiceModel.fromJson,
    );
  }

  Future<ApiResponse<SalesInvoiceModel>> getInvoice(int id) {
    return _apiClient.get<SalesInvoiceModel>(
      '${ApiEndpoints.salesInvoices}/$id',
      fromData: (json) =>
          SalesInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<SalesInvoiceModel>> createInvoice(
    SalesInvoiceModel invoice,
  ) {
    return _apiClient.post<SalesInvoiceModel>(
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
    return _apiClient.put<SalesInvoiceModel>(
      '${ApiEndpoints.salesInvoices}/$id',
      body: invoice.toCreateJson(),
      fromData: (json) =>
          SalesInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<SalesInvoiceModel>> postInvoice(int id) {
    return _apiClient.post<SalesInvoiceModel>(
      '${ApiEndpoints.salesInvoices}/$id/post',
      fromData: (json) =>
          SalesInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<SalesInvoiceModel>> cancelInvoice(int id) {
    return _apiClient.post<SalesInvoiceModel>(
      '${ApiEndpoints.salesInvoices}/$id/cancel',
      fromData: (json) =>
          SalesInvoiceModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
