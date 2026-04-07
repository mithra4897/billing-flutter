import '../common/json_model.dart';

class DocumentSeriesModel implements JsonModel {
  const DocumentSeriesModel({
    this.id,
    this.companyId,
    this.financialYearId,
    this.seriesCode,
    this.seriesName,
    this.documentType,
    this.prefix,
    this.suffix,
    this.nextNumber,
    this.numberLength,
    this.isDefault = false,
    this.isActive = true,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final int? financialYearId;
  final String? seriesCode;
  final String? seriesName;
  final String? documentType;
  final String? prefix;
  final String? suffix;
  final int? nextNumber;
  final int? numberLength;
  final bool isDefault;
  final bool isActive;
  final String? remarks;
  final Map<String, dynamic>? raw;

  @override
  String toString() => seriesName ?? seriesCode ?? 'New Document Series';

  factory DocumentSeriesModel.fromJson(Map<String, dynamic> json) {
    return DocumentSeriesModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      financialYearId: _parseInt(json['financial_year_id']),
      seriesCode: json['series_code']?.toString() ?? '',
      seriesName: json['series_name']?.toString() ?? '',
      documentType: json['document_type']?.toString(),
      prefix: json['prefix']?.toString(),
      suffix: json['suffix']?.toString(),
      nextNumber: _parseInt(json['next_number']),
      numberLength: _parseInt(json['number_length']),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (financialYearId != null) 'financial_year_id': financialYearId,
      if (seriesCode != null) 'series_code': seriesCode,
      if (seriesName != null) 'series_name': seriesName,
      if (documentType != null) 'document_type': documentType,
      if (prefix != null) 'prefix': prefix,
      if (suffix != null) 'suffix': suffix,
      if (nextNumber != null) 'next_number': nextNumber,
      if (numberLength != null) 'number_length': numberLength,
      'is_default': isDefault,
      'is_active': isActive,
      if (remarks != null) 'remarks': remarks,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return int.tryParse(value.toString());
  }
}
