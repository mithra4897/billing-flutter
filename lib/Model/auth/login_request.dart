class LoginRequest {
  const LoginRequest({
    required this.login,
    required this.password,
  });

  final String login;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'login': login,
      'password': password,
    };
  }
}
