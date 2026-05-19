import '../../screen.dart';

class ChangePasswordRequestModel extends JsonModel {
  const ChangePasswordRequestModel({
    this.currentPassword,
    this.newPassword,
    this.confirmPassword,
  }) : super(id: null);

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
  String toString() => 'Change Password Request';


  @override
  Map<String, dynamic> toJson() => {
    if (currentPassword != null) 'current_password': currentPassword,
    if (newPassword != null) 'new_password': newPassword,
    if (confirmPassword != null) 'confirm_password': confirmPassword,
  };
}
