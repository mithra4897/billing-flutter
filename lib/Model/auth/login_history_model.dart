import '../common/json_model.dart';
import '../common/model_value.dart';

class LoginHistoryModel implements JsonModel {
  const LoginHistoryModel({
    this.id,
    this.userId,
    this.loginAt,
    this.logoutAt,
    this.ipAddress,
    this.userAgent,
    this.status,
    this.failureReason,
  });

  final int? id;
  final int? userId;
  final String? loginAt;
  final String? logoutAt;
  final String? ipAddress;
  final String? userAgent;
  final String? status;
  final String? failureReason;

  factory LoginHistoryModel.fromJson(Map<String, dynamic> json) {
    return LoginHistoryModel(
      id: ModelValue.nullableInt(json['id']),
      userId: ModelValue.nullableInt(json['user_id']),
      loginAt: json['login_at']?.toString(),
      logoutAt: json['logout_at']?.toString(),
      ipAddress: json['ip_address']?.toString(),
      userAgent: json['user_agent']?.toString(),
      status: json['status']?.toString(),
      failureReason: json['failure_reason']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (loginAt != null) 'login_at': loginAt,
      if (logoutAt != null) 'logout_at': logoutAt,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (userAgent != null) 'user_agent': userAgent,
      if (status != null) 'status': status,
      if (failureReason != null) 'failure_reason': failureReason,
    };
  }
}
