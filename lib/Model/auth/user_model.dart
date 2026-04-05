class UserModel {
  UserModel({
    required this.id,
    required this.employeeCode,
    required this.username,
    required this.displayName,
    required this.email,
    required this.mobile,
    required this.isSuperAdmin,
    required this.mustChangePassword,
    required this.status,
  });

  final int? id;
  final String employeeCode;
  final String username;
  final String displayName;
  final String email;
  final String mobile;
  final bool isSuperAdmin;
  final bool mustChangePassword;
  final String status;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      employeeCode: json['employee_code']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      isSuperAdmin: json['is_super_admin'] == true,
      mustChangePassword: json['must_change_password'] == true,
      status: json['status']?.toString() ?? '',
    );
  }
}
