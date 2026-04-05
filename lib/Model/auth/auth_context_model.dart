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
    this.raw,
  });

  final List<CompanyModel> companies;
  final List<BranchModel> branches;
  final List<BusinessLocationModel> locations;
  final List<WarehouseModel> warehouses;
  final List<FinancialYearModel> financialYears;
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
      raw: json,
    );
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
}
