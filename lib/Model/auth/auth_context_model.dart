import '../../screen.dart';

class AuthContextModel {
  const AuthContextModel({
    required this.companies,
    required this.branches,
    required this.locations,
    required this.warehouses,
    required this.financialYears,
    this.permissionCodes = const [],
    this.menuModules = const [],
  });

  final List<CompanyModel> companies;
  final List<BranchModel> branches;
  final List<BusinessLocationModel> locations;
  final List<WarehouseModel> warehouses;
  final List<FinancialYearModel> financialYears;
  final List<String> permissionCodes;
  final List<ModuleModel> menuModules;

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
      menuModules: _mapList(
        json['menu_modules'],
        (item) => ModuleModel.fromJson(item),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companies': companies.map((item) => item.toJson()).toList(growable: false),
      'branches': branches.map((item) => item.toJson()).toList(growable: false),
      'locations': locations.map((item) => item.toJson()).toList(growable: false),
      'warehouses': warehouses.map((item) => item.toJson()).toList(growable: false),
      'financial_years': financialYears
          .map((item) => item.toJson())
          .toList(growable: false),
      'permission_codes': permissionCodes,
      'menu_modules': menuModules
          .map((item) => item.toJson())
          .toList(growable: false),
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
