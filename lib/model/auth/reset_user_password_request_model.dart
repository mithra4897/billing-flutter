import '../../screen.dart';

class ResetUserPasswordRequestModel extends JsonModel {
  const ResetUserPasswordRequestModel({
    this.newPassword,
    this.mustChangePassword,
  }) : super(id: null);

  final String? newPassword;
  final bool? mustChangePassword;

  factory ResetUserPasswordRequestModel.fromJson(Map<String, dynamic> json) {
    return ResetUserPasswordRequestModel(
      newPassword: json['new_password']?.toString(),
      mustChangePassword: json['must_change_password'] == null
          ? null
          : JsonModel.boolOf(json['must_change_password']),
    );
  }

  @override
  String toString() => 'Reset User Password Request';

  @override
  Map<String, dynamic> toJson() => {
    if (newPassword != null) 'new_password': newPassword,
    if (mustChangePassword != null)
      'must_change_password': mustChangePassword,
  };
}
