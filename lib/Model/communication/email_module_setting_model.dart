import '../../screen.dart';

class EmailModuleSettingModel extends JsonModel {
  const EmailModuleSettingModel({
    super.id,
    this.companyId,
    this.module,
    this.documentType,
    this.autoEmailEnabled,
    this.manualEmailEnabled,
    this.isActive,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final String? module;
  final String? documentType;
  final bool? autoEmailEnabled;
  final bool? manualEmailEnabled;
  final bool? isActive;
  final String? remarks;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory EmailModuleSettingModel.fromJson(Map<String, dynamic> json) {
    return EmailModuleSettingModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      module: json['module']?.toString(),
      documentType: json['document_type']?.toString(),
      autoEmailEnabled: json['auto_email_enabled'] == null
          ? null
          : ModelValue.boolOf(json['auto_email_enabled']),
      manualEmailEnabled: json['manual_email_enabled'] == null
          ? null
          : ModelValue.boolOf(json['manual_email_enabled']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      remarks: json['remarks']?.toString(),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Email Module Setting';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (module != null) 'module': module,
    if (documentType != null) 'document_type': documentType,
    if (autoEmailEnabled != null) 'auto_email_enabled': autoEmailEnabled,
    if (manualEmailEnabled != null) 'manual_email_enabled': manualEmailEnabled,
    if (isActive != null) 'is_active': isActive,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
