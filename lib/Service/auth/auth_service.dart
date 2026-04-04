import '../../Helper/api_helper.dart';
import '../../Helper/api_response.dart';
import '../../Helper/app_constants.dart';
import '../../Helper/storage_helper.dart';
import '../../Model/auth/login_request.dart';
import '../../Model/auth/login_response.dart';

class AuthService {
  AuthService({ApiHelper? apiHelper}) : _apiHelper = apiHelper ?? ApiHelper();

  final ApiHelper _apiHelper;

  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await _apiHelper.post<LoginResponse>(
        AppConstants.loginEndpoint,
        body: request.toJson(),
        fromData: (json) {
          if (json is Map<String, dynamic>) {
            return LoginResponse.fromJson(json);
          }

          return LoginResponse(
            accessToken: '',
            tokenType: 'bearer',
            expiresIn: 0,
          );
        },
      );

      if (response.success && response.data != null) {
        await StorageHelper.saveAuthToken(
          accessToken: response.data!.accessToken,
          tokenType: response.data!.tokenType,
          expiresIn: response.data!.expiresIn,
        );
      }

      return response;
    } catch (error) {
      return ApiResponse<LoginResponse>(
        success: false,
        message: error.toString(),
      );
    }
  }
}
