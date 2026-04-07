import '../common/json_model.dart';

class BrandModel implements JsonModel {
  const BrandModel({
    this.id,
    this.brandCode,
    this.brandName,
    this.isActive = true,
    this.remarks,
    this.raw,
  });

  final int? id;
  final String? brandCode;
  final String? brandName;
  final bool isActive;
  final String? remarks;
  final Map<String, dynamic>? raw;

  @override
  String toString() => brandName ?? brandCode ?? 'New Brand';

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: _parseInt(json['id']),
      brandCode: json['brand_code']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? '',
      isActive: json['is_active'] != false && json['is_active'] != 0,
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (brandCode != null) 'brand_code': brandCode,
      if (brandName != null) 'brand_name': brandName,
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
}
