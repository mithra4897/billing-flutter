import '../../screen.dart';

class EmailMessageModel extends JsonModel {
  const EmailMessageModel({
    super.id,
    this.companyId,
    this.emailSettingId,
    this.emailTemplateId,
    this.emailRuleId,
    this.module,
    this.documentType,
    this.documentId,
    this.eventCode,
    this.triggerMode,
    this.recipientTo,
    this.recipientCc,
    this.recipientBcc,
    this.subject,
    this.body,
    this.isHtml,
    this.status,
    this.errorMessage,
    this.sentAt,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? emailSettingId;
  final int? emailTemplateId;
  final int? emailRuleId;
  final String? module;
  final String? documentType;
  final int? documentId;
  final String? eventCode;
  final String? triggerMode;
  final String? recipientTo;
  final String? recipientCc;
  final String? recipientBcc;
  final String? subject;
  final String? body;
  final bool? isHtml;
  final String? status;
  final String? errorMessage;
  final String? sentAt;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  factory EmailMessageModel.fromJson(Map<String, dynamic> json) {
    return EmailMessageModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      emailSettingId: JsonModel.nullableInt(json['email_setting_id']),
      emailTemplateId: JsonModel.nullableInt(json['email_template_id']),
      emailRuleId: JsonModel.nullableInt(json['email_rule_id']),
      module: json['module']?.toString(),
      documentType: json['document_type']?.toString(),
      documentId: JsonModel.nullableInt(json['document_id']),
      eventCode: json['event_code']?.toString(),
      triggerMode: json['trigger_mode']?.toString(),
      recipientTo: json['recipient_to']?.toString(),
      recipientCc: json['recipient_cc']?.toString(),
      recipientBcc: json['recipient_bcc']?.toString(),
      subject: json['subject']?.toString(),
      body: json['body']?.toString(),
      isHtml: json['is_html'] == null
          ? null
          : JsonModel.boolOf(json['is_html']),
      status: json['status']?.toString(),
      errorMessage: json['error_message']?.toString(),
      sentAt: json['sent_at']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Email Message';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (emailSettingId != null) 'email_setting_id': emailSettingId,
    if (emailTemplateId != null) 'email_template_id': emailTemplateId,
    if (emailRuleId != null) 'email_rule_id': emailRuleId,
    if (module != null) 'module': module,
    if (documentType != null) 'document_type': documentType,
    if (documentId != null) 'document_id': documentId,
    if (eventCode != null) 'event_code': eventCode,
    if (triggerMode != null) 'trigger_mode': triggerMode,
    if (recipientTo != null) 'recipient_to': recipientTo,
    if (recipientCc != null) 'recipient_cc': recipientCc,
    if (recipientBcc != null) 'recipient_bcc': recipientBcc,
    if (subject != null) 'subject': subject,
    if (body != null) 'body': body,
    if (isHtml != null) 'is_html': isHtml,
    if (status != null) 'status': status,
    if (errorMessage != null) 'error_message': errorMessage,
    if (sentAt != null) 'sent_at': sentAt,
    if (createdBy != null) 'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
