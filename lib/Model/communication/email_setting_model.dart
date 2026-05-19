import '../../screen.dart';

class EmailSettingModel extends JsonModel {
  const EmailSettingModel({
    super.id,
    this.companyId,
    this.settingName,
    this.mailDriver,
    this.fromName,
    this.fromEmail,
    this.replyToEmail,
    this.smtpHost,
    this.smtpPort,
    this.smtpEncryption,
    this.smtpUsername,
    this.smtpPassword,
    this.autoEmailEnabled,
    this.isDefault,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final String? settingName;
  final String? mailDriver;
  final String? fromName;
  final String? fromEmail;
  final String? replyToEmail;
  final String? smtpHost;
  final int? smtpPort;
  final String? smtpEncryption;
  final String? smtpUsername;
  final String? smtpPassword;
  final bool? autoEmailEnabled;
  final bool? isDefault;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory EmailSettingModel.fromJson(Map<String, dynamic> json) {
    return EmailSettingModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      settingName: json['setting_name']?.toString(),
      mailDriver: json['mail_driver']?.toString(),
      fromName: json['from_name']?.toString(),
      fromEmail: json['from_email']?.toString(),
      replyToEmail: json['reply_to_email']?.toString(),
      smtpHost: json['smtp_host']?.toString(),
      smtpPort: ModelValue.nullableInt(json['smtp_port']),
      smtpEncryption: json['smtp_encryption']?.toString(),
      smtpUsername: json['smtp_username']?.toString(),
      smtpPassword: json['smtp_password']?.toString(),
      autoEmailEnabled: json['auto_email_enabled'] == null
          ? null
          : ModelValue.boolOf(json['auto_email_enabled']),
      isDefault: json['is_default'] == null
          ? null
          : ModelValue.boolOf(json['is_default']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Email Setting';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (settingName != null) 'setting_name': settingName,
    if (mailDriver != null) 'mail_driver': mailDriver,
    if (fromName != null) 'from_name': fromName,
    if (fromEmail != null) 'from_email': fromEmail,
    if (replyToEmail != null) 'reply_to_email': replyToEmail,
    if (smtpHost != null) 'smtp_host': smtpHost,
    if (smtpPort != null) 'smtp_port': smtpPort,
    if (smtpEncryption != null) 'smtp_encryption': smtpEncryption,
    if (smtpUsername != null) 'smtp_username': smtpUsername,
    if (smtpPassword != null) 'smtp_password': smtpPassword,
    if (autoEmailEnabled != null) 'auto_email_enabled': autoEmailEnabled,
    if (isDefault != null) 'is_default': isDefault,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
