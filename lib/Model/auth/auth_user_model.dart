class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.username,
    this.displayName,
    this.email,
    this.mobile,
    this.profilePhotoPath,
    this.isActive = true,
    this.isSuperAdmin = false,
    this.raw,
  });

  final int id;
  final String username;
  final String? displayName;
  final String? email;
  final String? mobile;
  final String? profilePhotoPath;
  final bool isActive;
  final bool isSuperAdmin;
  final Map<String, dynamic>? raw;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: _parseInt(json['id']),
      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      profilePhotoPath: json['profile_photo_path']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      isSuperAdmin:
          json['is_super_admin'] == true || json['is_super_admin'] == 1,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'email': email,
      'mobile': mobile,
      'profile_photo_path': profilePhotoPath,
      'is_active': isActive,
      'is_super_admin': isSuperAdmin,
      if (raw != null) ...raw!,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
