import '../../screen.dart';

class DocumentTermSettingModel extends JsonModel {
  const DocumentTermSettingModel({
    super.id,
    this.companyId,
    required this.documentType,
    required this.documentLabel,
    required this.termsConditions,
    this.isActive = true,
    this.isCompanyOverride = false,
    this.updatedAt,
  });

  final int? companyId;
  final String documentType;
  final String documentLabel;
  final String termsConditions;
  final bool isActive;
  final bool isCompanyOverride;
  final String? updatedAt;

  factory DocumentTermSettingModel.fromJson(Map<String, dynamic> json) {
    return DocumentTermSettingModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      documentType: json['document_type']?.toString() ?? '',
      documentLabel: json['document_label']?.toString() ?? '',
      termsConditions: json['terms_conditions']?.toString() ?? '',
      isActive: json['is_active'] == null
          ? true
          : JsonModel.boolOf(json['is_active']),
      isCompanyOverride: JsonModel.boolOf(json['is_company_override']),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  String toString() => documentLabel.isEmpty ? documentType : documentLabel;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    'document_type': documentType,
    'document_label': documentLabel,
    'terms_conditions': termsConditions,
    'is_active': isActive,
    'is_company_override': isCompanyOverride,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
