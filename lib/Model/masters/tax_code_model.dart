class TaxCodeModel {
  const TaxCodeModel({
    required this.id,
    required this.taxCode,
    required this.taxName,
    this.taxPercent,
    this.cessRate,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final String taxCode;
  final String taxName;
  final double? taxPercent;
  final double? cessRate;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory TaxCodeModel.fromJson(Map<String, dynamic> json) {
    return TaxCodeModel(
      id: _parseInt(json['id']),
      taxCode: json['tax_code']?.toString() ?? json['code']?.toString() ?? '',
      taxName: json['tax_name']?.toString() ?? json['name']?.toString() ?? '',
      taxPercent: _parseDouble(json['tax_percent']),
      cessRate: _parseDouble(json['cess_rate']),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static double? _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
