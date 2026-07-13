import '../../screen.dart';

class PublicResetPasswordRequestModel extends JsonModel {
  const PublicResetPasswordRequestModel({
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  }) : super(id: null);

  final String token;
  final String newPassword;
  final String confirmPassword;

  factory PublicResetPasswordRequestModel.fromJson(Map<String, dynamic> json) {
    return PublicResetPasswordRequestModel(
      token: json['token']?.toString() ?? '',
      newPassword: json['new_password']?.toString() ?? '',
      confirmPassword: json['confirm_password']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'Public Reset Password Request';

  @override
  Map<String, dynamic> toJson() => {
    'token': token,
    'new_password': newPassword,
    'confirm_password': confirmPassword,
  };
}
