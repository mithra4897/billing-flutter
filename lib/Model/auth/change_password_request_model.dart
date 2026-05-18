import '../../screen.dart';

class ChangePasswordRequestModel implements JsonModel {
  const ChangePasswordRequestModel({
    this.currentPassword,
    this.newPassword,
    this.confirmPassword,
  });

  final String? currentPassword;
  final String? newPassword;
  final String? confirmPassword;

  factory ChangePasswordRequestModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordRequestModel(
      currentPassword: json['current_password']?.toString(),
      newPassword: json['new_password']?.toString(),
      confirmPassword: json['confirm_password']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (currentPassword != null) 'current_password': currentPassword,
    if (newPassword != null) 'new_password': newPassword,
    if (confirmPassword != null) 'confirm_password': confirmPassword,
  };
}
