import '../../screen.dart';

class EmailTemplateModel extends JsonModel {
  const EmailTemplateModel({
    super.id,
    this.companyId,
    this.templateCode,
    this.templateName,
    this.module,
    this.documentType,
    this.eventCode,
    this.subjectTemplate,
    this.bodyTemplate,
    this.isHtml,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final String? templateCode;
  final String? templateName;
  final String? module;
  final String? documentType;
  final String? eventCode;
  final String? subjectTemplate;
  final String? bodyTemplate;
  final bool? isHtml;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory EmailTemplateModel.fromJson(Map<String, dynamic> json) {
    return EmailTemplateModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      templateCode: json['template_code']?.toString(),
      templateName: json['template_name']?.toString(),
      module: json['module']?.toString(),
      documentType: json['document_type']?.toString(),
      eventCode: json['event_code']?.toString(),
      subjectTemplate: json['subject_template']?.toString(),
      bodyTemplate: json['body_template']?.toString(),
      isHtml: json['is_html'] == null
          ? null
          : JsonModel.boolOf(json['is_html']),
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
  String toString() => JsonModel.combineValues([
    templateName,
    templateCode,
    eventCode,
  ], defaultValue: 'Email Template');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (templateCode != null) 'template_code': templateCode,
    if (templateName != null) 'template_name': templateName,
    if (module != null) 'module': module,
    if (documentType != null) 'document_type': documentType,
    if (eventCode != null) 'event_code': eventCode,
    if (subjectTemplate != null) 'subject_template': subjectTemplate,
    if (bodyTemplate != null) 'body_template': bodyTemplate,
    if (isHtml != null) 'is_html': isHtml,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
