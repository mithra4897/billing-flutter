import '../../screen.dart';

class PublicBrandingService {
  PublicBrandingService({ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  Future<ApiResponse<PublicBrandingModel>> fetchBranding() async {
    final response = await _client.get<PublicBrandingModel>(
      AppConfig.publicBrandingEndpoint,
      fromData: (json) =>
          PublicBrandingModel.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await SessionStorage.saveBranding(response.data!);
    }

    return response;
  }
}
