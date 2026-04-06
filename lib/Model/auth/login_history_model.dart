import '../common/json_model.dart';
import '../common/model_value.dart';

class LoginHistoryModel implements JsonModel {
  const LoginHistoryModel({
    this.id,
    this.userId,
    this.username,
    this.firstName,
    this.lastName,
    this.displayName,
    this.loginAt,
    this.logoutAt,
    this.ipAddress,
    this.hostName,
    this.userAgent,
    this.deviceType,
    this.browser,
    this.os,
    this.status,
    this.remarks,
  });

  final int? id;
  final int? userId;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? loginAt;
  final String? logoutAt;
  final String? ipAddress;
  final String? hostName;
  final String? userAgent;
  final String? deviceType;
  final String? browser;
  final String? os;
  final String? status;
  final String? remarks;

  factory LoginHistoryModel.fromJson(Map<String, dynamic> json) {
    return LoginHistoryModel(
      id: ModelValue.nullableInt(json['id']),
      userId: ModelValue.nullableInt(json['user_id']),
      username: json['username']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      displayName: json['display_name']?.toString(),
      loginAt: json['login_at']?.toString(),
      logoutAt: json['logout_at']?.toString(),
      ipAddress: json['ip_address']?.toString(),
      hostName: json['host_name']?.toString(),
      userAgent: json['user_agent']?.toString(),
      deviceType: json['device_type']?.toString(),
      browser: json['browser']?.toString(),
      os: json['os']?.toString(),
      status: json['login_status']?.toString() ?? json['status']?.toString(),
      remarks:
          json['remarks']?.toString() ?? json['failure_reason']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (displayName != null) 'display_name': displayName,
      if (loginAt != null) 'login_at': loginAt,
      if (logoutAt != null) 'logout_at': logoutAt,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (hostName != null) 'host_name': hostName,
      if (userAgent != null) 'user_agent': userAgent,
      if (deviceType != null) 'device_type': deviceType,
      if (browser != null) 'browser': browser,
      if (os != null) 'os': os,
      if (status != null) 'status': status,
      if (remarks != null) 'remarks': remarks,
    };
  }
}
