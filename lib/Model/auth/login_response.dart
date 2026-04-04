import 'token_model.dart';
import 'user_model.dart';

class LoginResponse {
  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.user,
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final UserModel? user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = TokenModel.fromJson(json);
    return LoginResponse(
      accessToken: token.accessToken,
      tokenType: token.tokenType,
      expiresIn: token.expiresIn,
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
