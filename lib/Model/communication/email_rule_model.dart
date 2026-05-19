import '../../screen.dart';

class EmailRuleModel extends JsonModel {
  const EmailRuleModel({
    super.id,
    this.companyId,
    this.ruleCode,
    this.ruleName,
    this.module,
    this.documentType,
    this.eventCode,
    this.templateId,
    this.autoEnabled,
    this.manualEnabled,
    this.sendToPartyEmail,
    this.sendToContactEmail,
    this.sendToAssignedUser,
    this.sendToOwnerUser,
    this.recipientEmails,
    this.ccEmails,
    this.bccEmails,
    this.subjectOverride,
    this.bodyOverride,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final String? ruleCode;
  final String? ruleName;
  final String? module;
  final String? documentType;
  final String? eventCode;
  final int? templateId;
  final bool? autoEnabled;
  final bool? manualEnabled;
  final bool? sendToPartyEmail;
  final bool? sendToContactEmail;
  final bool? sendToAssignedUser;
  final bool? sendToOwnerUser;
  final String? recipientEmails;
  final String? ccEmails;
  final String? bccEmails;
  final String? subjectOverride;
  final String? bodyOverride;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory EmailRuleModel.fromJson(Map<String, dynamic> json) {
    return EmailRuleModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      ruleCode: json['rule_code']?.toString(),
      ruleName: json['rule_name']?.toString(),
      module: json['module']?.toString(),
      documentType: json['document_type']?.toString(),
      eventCode: json['event_code']?.toString(),
      templateId: JsonModel.nullableInt(json['template_id']),
      autoEnabled: json['auto_enabled'] == null
          ? null
          : JsonModel.boolOf(json['auto_enabled']),
      manualEnabled: json['manual_enabled'] == null
          ? null
          : JsonModel.boolOf(json['manual_enabled']),
      sendToPartyEmail: json['send_to_party_email'] == null
          ? null
          : JsonModel.boolOf(json['send_to_party_email']),
      sendToContactEmail: json['send_to_contact_email'] == null
          ? null
          : JsonModel.boolOf(json['send_to_contact_email']),
      sendToAssignedUser: json['send_to_assigned_user'] == null
          ? null
          : JsonModel.boolOf(json['send_to_assigned_user']),
      sendToOwnerUser: json['send_to_owner_user'] == null
          ? null
          : JsonModel.boolOf(json['send_to_owner_user']),
      recipientEmails: json['recipient_emails']?.toString(),
      ccEmails: json['cc_emails']?.toString(),
      bccEmails: json['bcc_emails']?.toString(),
      subjectOverride: json['subject_override']?.toString(),
      bodyOverride: json['body_override']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Email Rule';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (ruleCode != null) 'rule_code': ruleCode,
    if (ruleName != null) 'rule_name': ruleName,
    if (module != null) 'module': module,
    if (documentType != null) 'document_type': documentType,
    if (eventCode != null) 'event_code': eventCode,
    if (templateId != null) 'template_id': templateId,
    if (autoEnabled != null) 'auto_enabled': autoEnabled,
    if (manualEnabled != null) 'manual_enabled': manualEnabled,
    if (sendToPartyEmail != null) 'send_to_party_email': sendToPartyEmail,
    if (sendToContactEmail != null) 'send_to_contact_email': sendToContactEmail,
    if (sendToAssignedUser != null) 'send_to_assigned_user': sendToAssignedUser,
    if (sendToOwnerUser != null) 'send_to_owner_user': sendToOwnerUser,
    if (recipientEmails != null) 'recipient_emails': recipientEmails,
    if (ccEmails != null) 'cc_emails': ccEmails,
    if (bccEmails != null) 'bcc_emails': bccEmails,
    if (subjectOverride != null) 'subject_override': subjectOverride,
    if (bodyOverride != null) 'body_override': bodyOverride,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
