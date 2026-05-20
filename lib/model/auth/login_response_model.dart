import '../../screen.dart';

class LoginResponseModel extends JsonModel {
  const LoginResponseModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.user,
  }) : super(id: null);

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final AuthUserModel? user;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      expiresIn: _parseInt(json['expires_in']),
      user: json['user'] is Map<String, dynamic>
          ? AuthUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
  @override
  String toString() => user?.toString() ?? 'Login Response';

  @override
  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'token_type': tokenType,
    'expires_in': expiresIn,
    if (user != null) 'user': user!.toJson(),
  };

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
