import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/media/media_file_model.dart';

class MediaService {
  MediaService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PaginatedResponse<MediaFileModel>> getFiles({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<MediaFileModel>(
      ApiEndpoints.mediaFiles,
      queryParameters: filters,
      itemFromJson: MediaFileModel.fromJson,
    );
  }

  Future<ApiResponse<MediaFileModel>> getFile(int id) {
    return _apiClient.get<MediaFileModel>(
      '${ApiEndpoints.mediaFiles}/$id',
      fromData: (json) => MediaFileModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<MediaFileModel>> uploadFile({
    required String filePath,
    int? companyId,
    String? module,
    String? documentType,
    int? documentId,
    String? purpose,
    String? folder,
    bool isPublic = false,
  }) {
    return _apiClient.upload<MediaFileModel>(
      ApiEndpoints.mediaFiles,
      fileField: 'file',
      filePath: filePath,
      fields: {
        if (companyId != null) 'company_id': companyId.toString(),
        if (module case final String value) 'module': value,
        if (documentType case final String value) 'document_type': value,
        if (documentId != null) 'document_id': documentId.toString(),
        if (purpose case final String value) 'purpose': value,
        if (folder case final String value) 'folder': value,
        'is_public': isPublic ? '1' : '0',
      },
      fromData: (json) => MediaFileModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> deleteFile(int id) {
    return _apiClient.delete<dynamic>('${ApiEndpoints.mediaFiles}/$id');
  }
}
