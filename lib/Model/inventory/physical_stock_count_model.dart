import '../common/json_model.dart';
import 'physical_stock_count_line_model.dart';

class PhysicalStockCountModel implements JsonModel {
  const PhysicalStockCountModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.warehouseId,
    this.countNo,
    this.countDate,
    this.countScope,
    this.countStatus,
    this.remarks,
    this.isActive = true,
    this.items = const <PhysicalStockCountLineModel>[],
    this.companyName,
    this.branchName,
    this.locationName,
    this.financialYearName,
    this.documentSeriesName,
    this.warehouseName,
    this.itemsCount,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final int? warehouseId;
  final String? countNo;
  final String? countDate;
  final String? countScope;
  final String? countStatus;
  final String? remarks;
  final bool isActive;
  final List<PhysicalStockCountLineModel> items;
  final String? companyName;
  final String? branchName;
  final String? locationName;
  final String? financialYearName;
  final String? documentSeriesName;
  final String? warehouseName;
  final int? itemsCount;
  final Map<String, dynamic>? raw;

  @override
  String toString() => countNo ?? 'New Physical Count';

  factory PhysicalStockCountModel.fromJson(Map<String, dynamic> json) {
    final company = _asMap(json['company']);
    final branch = _asMap(json['branch']);
    final location = _asMap(
      json['business_location'] ?? json['businessLocation'],
    );
    final financialYear = _asMap(
      json['financial_year'] ?? json['financialYear'],
    );
    final documentSeries = _asMap(
      json['document_series'] ?? json['documentSeries'],
    );
    final warehouse = _asMap(json['warehouse']);
    final itemsJson = json['items'];

    return PhysicalStockCountModel(
      id: _nullableInt(json['id']),
      companyId: _nullableInt(json['company_id'] ?? company['id']),
      branchId: _nullableInt(json['branch_id'] ?? branch['id']),
      locationId: _nullableInt(json['location_id'] ?? location['id']),
      financialYearId: _nullableInt(
        json['financial_year_id'] ?? financialYear['id'],
      ),
      documentSeriesId: _nullableInt(
        json['document_series_id'] ?? documentSeries['id'],
      ),
      warehouseId: _nullableInt(json['warehouse_id'] ?? warehouse['id']),
      countNo: json['count_no']?.toString(),
      countDate: json['count_date']?.toString(),
      countScope: json['count_scope']?.toString(),
      countStatus: json['count_status']?.toString(),
      remarks: json['remarks']?.toString(),
      isActive: _bool(json['is_active'], fallback: true),
      items: itemsJson is List
          ? itemsJson
                .whereType<Map<String, dynamic>>()
                .map(PhysicalStockCountLineModel.fromJson)
                .toList(growable: false)
          : const <PhysicalStockCountLineModel>[],
      companyName:
          company['trade_name']?.toString() ??
          company['legal_name']?.toString(),
      branchName: branch['name']?.toString(),
      locationName: location['name']?.toString(),
      financialYearName:
          financialYear['fy_name']?.toString() ??
          financialYear['name']?.toString(),
      documentSeriesName:
          documentSeries['series_name']?.toString() ??
          documentSeries['name']?.toString(),
      warehouseName: warehouse['name']?.toString(),
      itemsCount: _nullableInt(json['items_count']),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      if (financialYearId != null) 'financial_year_id': financialYearId,
      if (documentSeriesId != null) 'document_series_id': documentSeriesId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (countNo != null) 'count_no': countNo,
      if (countDate != null) 'count_date': countDate,
      if (countScope != null) 'count_scope': countScope,
      if (countStatus != null) 'count_status': countStatus,
      if (remarks != null) 'remarks': remarks,
      'is_active': isActive,
      'items': items.map((line) => line.toJson()).toList(growable: false),
    };
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return <String, dynamic>{};
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) {
      return fallback;
    }
    return value == true || value == 1 || value.toString() == '1';
  }

  static int? _nullableInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }
    return int.tryParse(value.toString());
  }
}
