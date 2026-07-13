import '../../screen.dart';

class ForgotPasswordRequestModel extends JsonModel {
  const ForgotPasswordRequestModel({required this.login, this.resetUrl})
    : super(id: null);

  final String login;
  final String? resetUrl;

  factory ForgotPasswordRequestModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordRequestModel(
      login: json['login']?.toString().trim() ?? '',
      resetUrl: json['reset_url']?.toString(),
    );
  }

  @override
  String toString() => 'Forgot Password Request';

  @override
  Map<String, dynamic> toJson() => {
    'login': login.trim(),
    if (resetUrl != null && resetUrl!.trim().isNotEmpty)
      'reset_url': resetUrl!.trim(),
  };
}
