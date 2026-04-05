class DocumentSeriesModel {
  const DocumentSeriesModel({
    required this.id,
    required this.companyId,
    required this.seriesCode,
    required this.seriesName,
    this.documentType,
    this.prefix,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final int companyId;
  final String seriesCode;
  final String seriesName;
  final String? documentType;
  final String? prefix;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory DocumentSeriesModel.fromJson(Map<String, dynamic> json) {
    return DocumentSeriesModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      seriesCode: json['series_code']?.toString() ?? '',
      seriesName: json['series_name']?.toString() ?? '',
      documentType: json['document_type']?.toString(),
      prefix: json['prefix']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
