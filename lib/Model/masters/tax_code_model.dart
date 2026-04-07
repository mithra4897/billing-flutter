import '../common/json_model.dart';

class TaxCodeModel implements JsonModel {
  const TaxCodeModel({
    this.id,
    this.taxCode,
    this.taxName,
    this.taxType,
    this.taxRate,
    this.cessRate,
    this.hsnSacCode,
    this.remarks,
    this.isActive = true,
    this.raw,
  });

  final int? id;
  final String? taxCode;
  final String? taxName;
  final String? taxType;
  final double? taxRate;
  final double? cessRate;
  final String? hsnSacCode;
  final String? remarks;
  final bool isActive;
  final Map<String, dynamic>? raw;

  @override
  String toString() => taxName ?? taxCode ?? 'New Tax Category';

  factory TaxCodeModel.fromJson(Map<String, dynamic> json) {
    return TaxCodeModel(
      id: _parseInt(json['id']),
      taxCode: json['tax_code']?.toString() ?? json['code']?.toString() ?? '',
      taxName: json['tax_name']?.toString() ?? json['name']?.toString() ?? '',
      taxType: json['tax_type']?.toString(),
      taxRate: _parseDouble(json['tax_rate'] ?? json['tax_percent']),
      cessRate: _parseDouble(json['cess_rate']),
      hsnSacCode: json['hsn_sac_code']?.toString(),
      remarks: json['remarks']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (taxCode != null) 'tax_code': taxCode,
      if (taxName != null) 'tax_name': taxName,
      if (taxType != null) 'tax_type': taxType,
      if (taxRate != null) 'tax_rate': taxRate,
      if (cessRate != null) 'cess_rate': cessRate,
      if (hsnSacCode != null) 'hsn_sac_code': hsnSacCode,
      if (remarks != null) 'remarks': remarks,
      'is_active': isActive,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
