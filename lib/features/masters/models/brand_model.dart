class BrandModel {
  const BrandModel({
    required this.id,
    required this.brandCode,
    required this.brandName,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final String brandCode;
  final String brandName;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: _parseInt(json['id']),
      brandCode: json['brand_code']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? '',
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
