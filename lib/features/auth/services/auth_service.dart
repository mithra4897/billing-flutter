import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/storage/session_storage.dart';
import '../models/auth_context_model.dart';
import '../models/auth_user_model.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ApiResponse<LoginResponseModel>> login(
    LoginRequestModel request,
  ) async {
    final response = await _apiClient.post<LoginResponseModel>(
      ApiEndpoints.login,
      body: request.toJson(),
      fromData: (json) =>
          LoginResponseModel.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await SessionStorage.saveSession(
        token: response.data!.accessToken,
        tokenType: response.data!.tokenType,
        expiresIn: response.data!.expiresIn,
      );
    }

    return response;
  }

  Future<ApiResponse<AuthUserModel>> getProfile() {
    return _apiClient.get<AuthUserModel>(
      ApiEndpoints.me,
      fromData: (json) => AuthUserModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AuthContextModel>> getContext() {
    return _apiClient.get<AuthContextModel>(
      ApiEndpoints.authContext,
      fromData: (json) =>
          AuthContextModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> logout() async {
    final response = await _apiClient.post<dynamic>(ApiEndpoints.logout);
    await SessionStorage.clear();
    return response;
  }
}
