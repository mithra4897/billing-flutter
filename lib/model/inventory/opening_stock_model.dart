import '../common/json_model.dart';
import 'opening_stock_item_model.dart';

class OpeningStockModel extends JsonModel {
  const OpeningStockModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.openingNo,
    this.openingDate,
    this.voucherId,
    this.openingStatus,
    this.remarks,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.postedBy,
    this.postedAt,
    this.createdAt,
    this.updatedAt,
    this.items,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? openingNo;
  final String? openingDate;
  final int? voucherId;
  final String? openingStatus;
  final String? remarks;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final int? postedBy;
  final String? postedAt;
  final String? createdAt;
  final String? updatedAt;
  final List<OpeningStockItemModel>? items;

  factory OpeningStockModel.fromJson(Map<String, dynamic> json) {
    return OpeningStockModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      openingNo: json['opening_no']?.toString(),
      openingDate: json['opening_date']?.toString(),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      openingStatus: json['opening_status']?.toString(),
      remarks: json['remarks']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      items: (json['items'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(OpeningStockItemModel.fromJson)
          .toList(growable: false),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    openingNo,
    openingDate,
    openingStatus,
  ], defaultValue: 'Opening Stock');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (openingNo != null) 'opening_no': openingNo,
    if (openingDate != null) 'opening_date': openingDate,
    if (voucherId != null) 'voucher_id': voucherId,
    if (openingStatus != null) 'opening_status': openingStatus,
    if (remarks != null) 'remarks': remarks,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
    if (items != null)
      'items': items!.map((item) => item.toJson()).toList(growable: false),
  };
}
