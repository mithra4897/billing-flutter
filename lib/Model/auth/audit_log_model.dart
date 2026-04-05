import '../common/json_model.dart';
import '../common/model_value.dart';

class AuditLogModel implements JsonModel {
  const AuditLogModel({
    this.id,
    this.userId,
    this.module,
    this.tableName,
    this.recordId,
    this.action,
    this.description,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
  });

  final int? id;
  final int? userId;
  final String? module;
  final String? tableName;
  final int? recordId;
  final String? action;
  final String? description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final String? createdAt;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: ModelValue.nullableInt(json['id']),
      userId: ModelValue.nullableInt(json['user_id']),
      module: json['module']?.toString(),
      tableName: json['table_name']?.toString(),
      recordId: ModelValue.nullableInt(json['record_id']),
      action: json['action']?.toString(),
      description: json['description']?.toString(),
      oldValues: _mapOf(json['old_values']),
      newValues: _mapOf(json['new_values']),
      ipAddress: json['ip_address']?.toString(),
      userAgent: json['user_agent']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (module != null) 'module': module,
      if (tableName != null) 'table_name': tableName,
      if (recordId != null) 'record_id': recordId,
      if (action != null) 'action': action,
      if (description != null) 'description': description,
      if (oldValues != null) 'old_values': oldValues,
      if (newValues != null) 'new_values': newValues,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (userAgent != null) 'user_agent': userAgent,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  static Map<String, dynamic>? _mapOf(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return null;
  }
}
