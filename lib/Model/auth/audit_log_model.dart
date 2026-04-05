import '../common/json_model.dart';

class AuditLogModel implements JsonModel {
  const AuditLogModel(this.data);

  final Map<String, dynamic> data;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
