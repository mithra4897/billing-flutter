import '../../screen.dart';

class PublicResetPasswordRequestModel extends JsonModel {
  const PublicResetPasswordRequestModel({
    required this.login,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  }) : super(id: null);

  final String login;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  factory PublicResetPasswordRequestModel.fromJson(Map<String, dynamic> json) {
    return PublicResetPasswordRequestModel(
      login: json['login']?.toString() ?? '',
      otp: json['otp']?.toString() ?? '',
      newPassword: json['new_password']?.toString() ?? '',
      confirmPassword: json['confirm_password']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'Public Reset Password Request';

  @override
  Map<String, dynamic> toJson() => {
    'login': login,
    'otp': otp,
    'new_password': newPassword,
    'confirm_password': confirmPassword,
  };
}
