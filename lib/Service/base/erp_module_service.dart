import '../../core/api/api_client.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/common/json_model.dart';
import '../../model/common/erp_record_model.dart';

class ErpModuleService {
  ErpModuleService({ApiClient? apiClient}) : client = apiClient ?? ApiClient();

  final ApiClient client;

  Future<PaginatedResponse<T>> paginated<T>(
    String endpoint, {
    Map<String, dynamic>? filters,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return client.getPaginated<T>(
      endpoint,
      queryParameters: filters,
      itemFromJson: fromJson,
    );
  }

  Future<ApiResponse<List<T>>> collection<T>(
    String endpoint, {
    Map<String, dynamic>? filters,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return client.get<List<T>>(
      endpoint,
      queryParameters: filters,
      fromData: (json) {
        if (json is! List) {
          return <T>[];
        }

        return json
            .whereType<Map<String, dynamic>>()
            .map(fromJson)
            .toList(growable: false);
      },
    );
  }

  Future<ApiResponse<T>> object<T>(
    String endpoint, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return client.get<T>(
      endpoint,
      fromData: (json) => fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<T>> createModel<T>(
    String endpoint,
    dynamic body, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return client.post<T>(
      endpoint,
      body: _mapBody(body),
      fromData: (json) => fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<T>> updateModel<T>(
    String endpoint,
    dynamic body, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return client.put<T>(
      endpoint,
      body: _mapBody(body),
      fromData: (json) => fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<T>> patchModel<T>(
    String endpoint,
    dynamic body, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return client.patch<T>(
      endpoint,
      body: _mapBody(body),
      fromData: (json) => fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<T>> actionModel<T>(
    String endpoint, {
    dynamic body,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return client.post<T>(
      endpoint,
      body: body == null ? null : _mapBody(body),
      fromData: (json) => fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PaginatedResponse<ErpRecordModel>> index(
    String endpoint, {
    Map<String, dynamic>? filters,
  }) {
    return paginated<ErpRecordModel>(
      endpoint,
      filters: filters,
      fromJson: ErpRecordModel.fromJson,
    );
  }

  Future<ApiResponse<List<ErpRecordModel>>> list(
    String endpoint, {
    Map<String, dynamic>? filters,
  }) {
    return collection<ErpRecordModel>(
      endpoint,
      filters: filters,
      fromJson: ErpRecordModel.fromJson,
    );
  }

  Future<ApiResponse<ErpRecordModel>> show(String endpoint) {
    return object<ErpRecordModel>(endpoint, fromJson: ErpRecordModel.fromJson);
  }

  Map<String, dynamic> _mapBody(dynamic body) {
    if (body is JsonModel) {
      return body.toJson();
    }

    if (body != null) {
      try {
        final dynamic json = body.toJson();
        if (json is Map<String, dynamic>) {
          return json;
        }
      } catch (_) {}
    }

    if (body is Map<String, dynamic>) {
      return body;
    }

    return <String, dynamic>{};
  }

  Future<ApiResponse<ErpRecordModel>> store(String endpoint, dynamic body) {
    return client.post<ErpRecordModel>(
      endpoint,
      body: _mapBody(body),
      fromData: (json) => ErpRecordModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ErpRecordModel>> update(String endpoint, dynamic body) {
    return client.put<ErpRecordModel>(
      endpoint,
      body: _mapBody(body),
      fromData: (json) => ErpRecordModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ErpRecordModel>> patch(String endpoint, dynamic body) {
    return client.patch<ErpRecordModel>(
      endpoint,
      body: _mapBody(body),
      fromData: (json) => ErpRecordModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> destroy(String endpoint) {
    return client.delete<dynamic>(endpoint);
  }

  Future<ApiResponse<ErpRecordModel>> action(String endpoint, {dynamic body}) {
    return client.post<ErpRecordModel>(
      endpoint,
      body: body == null ? null : _mapBody(body),
      fromData: (json) => ErpRecordModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> actionDynamic(String endpoint, {dynamic body}) {
    return client.post<dynamic>(
      endpoint,
      body: body == null ? null : _mapBody(body),
    );
  }
}
