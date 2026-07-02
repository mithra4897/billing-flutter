import '../../screen.dart';

class AuditLogModel extends JsonModel {
  const AuditLogModel({
    super.id,
    this.userId,
    this.module,
    this.entityName,
    this.entityId,
    this.action,
    this.description,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.hostName,
    this.userAgent,
    this.createdAt,
  });
  final int? userId;
  final String? module;
  final String? entityName;
  final String? entityId;
  final String? action;
  final String? description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? hostName;
  final String? userAgent;
  final String? createdAt;

  String? get tableName => entityName;

  int? get recordId => JsonModel.nullableInt(entityId);

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: JsonModel.nullableInt(json['id']),
      userId: JsonModel.nullableInt(json['user_id']),
      module: json['module']?.toString(),
      entityName: (json['entity_name'] ?? json['table_name'])?.toString(),
      entityId: (json['entity_id'] ?? json['record_id'])?.toString(),
      action: json['action']?.toString(),
      description: json['description']?.toString(),
      oldValues: _mapOf(json['old_values']),
      newValues: _mapOf(json['new_values']),
      ipAddress: json['ip_address']?.toString(),
      hostName: json['host_name']?.toString(),
      userAgent: json['user_agent']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    entityName,
  ], defaultValue: 'Audit Log');


  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (module != null) 'module': module,
      if (entityName != null) 'entity_name': entityName,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (description != null) 'description': description,
      if (oldValues != null) 'old_values': oldValues,
      if (newValues != null) 'new_values': newValues,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (hostName != null) 'host_name': hostName,
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
