class WarehouseModel {
  const WarehouseModel({
    required this.id,
    required this.companyId,
    required this.code,
    required this.name,
    this.branchId,
    this.locationId,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final int companyId;
  final String code;
  final String name;
  final int? branchId;
  final int? locationId;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branchId: _nullableInt(json['branch_id']),
      locationId: _nullableInt(json['location_id']),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed == null || parsed == 0 ? null : parsed;
  }
}
