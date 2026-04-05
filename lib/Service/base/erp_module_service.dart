import '../../core/api/api_client.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/common/erp_record_model.dart';

class ErpModuleService {
  ErpModuleService({ApiClient? apiClient}) : client = apiClient ?? ApiClient();

  final ApiClient client;

  Future<PaginatedResponse<ErpRecordModel>> index(
    String endpoint, {
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<ErpRecordModel>(
      endpoint,
      queryParameters: filters,
      itemFromJson: ErpRecordModel.fromJson,
    );
  }

  Future<ApiResponse<List<ErpRecordModel>>> list(
    String endpoint, {
    Map<String, dynamic>? filters,
  }) {
    return client.get<List<ErpRecordModel>>(
      endpoint,
      queryParameters: filters,
      fromData: (json) {
        if (json is! List) {
          return <ErpRecordModel>[];
        }

        return json
            .whereType<Map<String, dynamic>>()
            .map(ErpRecordModel.fromJson)
            .toList(growable: false);
      },
    );
  }

  Future<ApiResponse<ErpRecordModel>> show(String endpoint) {
    return client.get<ErpRecordModel>(
      endpoint,
      fromData: (json) => ErpRecordModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ErpRecordModel>> store(
    String endpoint,
    Map<String, dynamic> body,
  ) {
    return client.post<ErpRecordModel>(
      endpoint,
      body: body,
      fromData: (json) => ErpRecordModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ErpRecordModel>> update(
    String endpoint,
    Map<String, dynamic> body,
  ) {
    return client.put<ErpRecordModel>(
      endpoint,
      body: body,
      fromData: (json) => ErpRecordModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ErpRecordModel>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) {
    return client.patch<ErpRecordModel>(
      endpoint,
      body: body,
      fromData: (json) => ErpRecordModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> destroy(String endpoint) {
    return client.delete<dynamic>(endpoint);
  }

  Future<ApiResponse<ErpRecordModel>> action(
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    return client.post<ErpRecordModel>(
      endpoint,
      body: body,
      fromData: (json) => ErpRecordModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> actionDynamic(
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    return client.post<dynamic>(endpoint, body: body);
  }
}
