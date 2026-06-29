import '../../screen.dart';
import 'stock_transfer_item_model.dart';

class StockTransferModel extends JsonModel {
  const StockTransferModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.transferNo,
    this.transferDate,
    this.fromWarehouseId,
    this.toWarehouseId,
    this.transferStatus,
    this.remarks,
    this.receivedBy,
    this.receivedAt,
    this.voucherId,
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
  final String? transferNo;
  final String? transferDate;
  final int? fromWarehouseId;
  final int? toWarehouseId;
  final String? transferStatus;
  final String? remarks;
  final int? receivedBy;
  final String? receivedAt;
  final int? voucherId;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final int? postedBy;
  final String? postedAt;
  final String? createdAt;
  final String? updatedAt;
  final List<StockTransferItemModel>? items;

  factory StockTransferModel.fromJson(Map<String, dynamic> json) {
    return StockTransferModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      transferNo: json['transfer_no']?.toString(),
      transferDate: json['transfer_date']?.toString(),
      fromWarehouseId: JsonModel.nullableInt(json['from_warehouse_id']),
      toWarehouseId: JsonModel.nullableInt(json['to_warehouse_id']),
      transferStatus: json['transfer_status']?.toString(),
      remarks: json['remarks']?.toString(),
      receivedBy: JsonModel.nullableInt(json['received_by']),
      receivedAt: json['received_at']?.toString(),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      items: json['items'] == null
          ? null
          : (json['items'] as List<dynamic>)
              .map((e) => StockTransferItemModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    transferNo,
    transferDate,
    transferStatus,
  ], defaultValue: 'Stock Transfer');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (transferNo != null) 'transfer_no': transferNo,
    if (transferDate != null) 'transfer_date': transferDate,
    if (fromWarehouseId != null) 'from_warehouse_id': fromWarehouseId,
    if (toWarehouseId != null) 'to_warehouse_id': toWarehouseId,
    if (transferStatus != null) 'transfer_status': transferStatus,
    if (remarks != null) 'remarks': remarks,
    if (receivedBy != null) 'received_by': receivedBy,
    if (receivedAt != null) 'received_at': receivedAt,
    if (voucherId != null) 'voucher_id': voucherId,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
    if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
  };
}
