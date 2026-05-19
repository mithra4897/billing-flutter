import '../../screen.dart';

class LoginRequestModel extends JsonModel {
  const LoginRequestModel({required this.login, required this.password}) : super(id: null);

  final String login;
  final String password;
  @override
  String toString() => login;

  @override
  Map<String, dynamic> toJson() {
    return {'login': login, 'password': password};
  }
}
