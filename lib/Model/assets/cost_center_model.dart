import '../common/json_model.dart';

class CostCenterModel implements JsonModel {
  const CostCenterModel({
    this.id,
    this.companyId,
    this.costCenterCode,
    this.costCenterName,
    this.isActive = true,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final String? costCenterCode;
  final String? costCenterName;
  final bool isActive;
  final Map<String, dynamic>? raw;

  @override
  String toString() => costCenterName ?? costCenterCode ?? 'Cost Center';

  factory CostCenterModel.fromJson(Map<String, dynamic> json) {
    return CostCenterModel(
      id: _nullableInt(json['id']),
      companyId: _nullableInt(json['company_id']),
      costCenterCode: json['cost_center_code']?.toString(),
      costCenterName: json['cost_center_name']?.toString(),
      isActive: _bool(json['is_active'], fallback: true),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (costCenterCode != null) 'cost_center_code': costCenterCode,
      if (costCenterName != null) 'cost_center_name': costCenterName,
      'is_active': isActive,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    return value == true || value == 1 || value.toString() == '1';
  }
}
