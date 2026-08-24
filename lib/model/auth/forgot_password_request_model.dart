import '../../screen.dart';

class ForgotPasswordRequestModel extends JsonModel {
  const ForgotPasswordRequestModel({required this.login}) : super(id: null);

  final String login;

  factory ForgotPasswordRequestModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordRequestModel(
      login: json['login']?.toString().trim() ?? '',
    );
  }

  @override
  String toString() => 'Forgot Password Request';

  @override
  Map<String, dynamic> toJson() => {'login': login.trim()};
}
