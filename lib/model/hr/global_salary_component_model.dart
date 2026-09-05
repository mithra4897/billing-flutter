import '../../screen.dart';

class GlobalSalaryComponentModel extends JsonModel {
  const GlobalSalaryComponentModel({
    super.id,
    this.companyId,
    this.componentName,
    this.componentType,
    this.componentRole,
    this.calculationBasis,
    this.percentValue,
    this.amount,
    this.contributionRole,
    this.sortOrder,
    this.isActive = true,
  });

  final int? companyId;
  final String? componentName;

  final String? componentType;
  final String? componentRole;
  final String? calculationBasis;
  final double? percentValue;
  final double? amount;
  final String? contributionRole;
  final int? sortOrder;
  final bool isActive;

  @override
  String toString() => componentName ?? 'Salary Component';

  factory GlobalSalaryComponentModel.fromJson(Map<String, dynamic> json) {
    return GlobalSalaryComponentModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      componentName: json['component_name']?.toString(),
      componentType: json['component_type']?.toString(),
      componentRole: json['component_role']?.toString(),
      calculationBasis: json['calculation_basis']?.toString(),
      percentValue: JsonModel.nullableDouble(json['percent_value']),
      amount: JsonModel.nullableDouble(json['amount']),
      contributionRole: json['contribution_role']?.toString(),
      sortOrder: JsonModel.nullableInt(json['sort_order']),
      isActive: _bool(json['is_active'], fallback: true),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (componentName != null) 'component_name': componentName,
      if (componentType != null) 'component_type': componentType,
      if (componentRole != null) 'component_role': componentRole,
      if (calculationBasis != null) 'calculation_basis': calculationBasis,
      if (percentValue != null) 'percent_value': percentValue,
      if (amount != null) 'amount': amount,
      if (contributionRole != null) 'contribution_role': contributionRole,
      if (sortOrder != null) 'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  GlobalSalaryComponentModel copyWith({
    int? id,
    int? companyId,
    String? componentName,
    String? componentType,
    String? componentRole,
    String? calculationBasis,
    double? percentValue,
    double? amount,
    String? contributionRole,
    int? sortOrder,
    bool? isActive,
  }) {
    return GlobalSalaryComponentModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      componentName: componentName ?? this.componentName,
      componentType: componentType ?? this.componentType,
      componentRole: componentRole ?? this.componentRole,
      calculationBasis: calculationBasis ?? this.calculationBasis,
      percentValue: percentValue ?? this.percentValue,
      amount: amount ?? this.amount,
      contributionRole: contributionRole ?? this.contributionRole,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    return value == true || value == 1 || value.toString() == '1';
  }
}
