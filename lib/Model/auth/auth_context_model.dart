import '../masters/branch_model.dart';
import '../masters/business_location_model.dart';
import '../masters/company_model.dart';
import '../masters/financial_year_model.dart';
import '../masters/warehouse_model.dart';

class AuthContextModel {
  const AuthContextModel({
    required this.companies,
    required this.branches,
    required this.locations,
    required this.warehouses,
    required this.financialYears,
    this.permissionCodes = const [],
    this.raw,
  });

  final List<CompanyModel> companies;
  final List<BranchModel> branches;
  final List<BusinessLocationModel> locations;
  final List<WarehouseModel> warehouses;
  final List<FinancialYearModel> financialYears;
  final List<String> permissionCodes;
  final Map<String, dynamic>? raw;

  factory AuthContextModel.fromJson(Map<String, dynamic> json) {
    return AuthContextModel(
      companies: _mapList(
        json['companies'],
        (item) => CompanyModel.fromJson(item),
      ),
      branches: _mapList(
        json['branches'],
        (item) => BranchModel.fromJson(item),
      ),
      locations: _mapList(
        json['locations'],
        (item) => BusinessLocationModel.fromJson(item),
      ),
      warehouses: _mapList(
        json['warehouses'],
        (item) => WarehouseModel.fromJson(item),
      ),
      financialYears: _mapList(
        json['financial_years'],
        (item) => FinancialYearModel.fromJson(item),
      ),
      permissionCodes: _stringList(json['permission_codes']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() {
    if (raw != null) {
      return raw!;
    }

    return {
      'companies': const <Map<String, dynamic>>[],
      'branches': const <Map<String, dynamic>>[],
      'locations': const <Map<String, dynamic>>[],
      'warehouses': const <Map<String, dynamic>>[],
      'financial_years': const <Map<String, dynamic>>[],
      'permission_codes': permissionCodes,
    };
  }

  static List<T> _mapList<T>(
    dynamic value,
    T Function(Map<String, dynamic> json) mapper,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(mapper)
        .toList(growable: false);
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value.map((item) => item.toString()).toList(growable: false);
  }
}
