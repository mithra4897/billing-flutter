import '../../screen.dart';

class AssetDepreciationRunModel extends JsonModel {
  const AssetDepreciationRunModel({
    super.id,
    this.companyId,
    this.runNo,
    this.runDate,
    this.depreciationFromDate,
    this.depreciationToDate,
    this.bookType,
    this.runStatus,
    this.voucherId,
    this.totalAssetsProcessed,
    this.totalDepreciationAmount,
    this.notes,
    this.errorMessage,
    this.createdBy,
    this.postedBy,
    this.postedAt,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final String? runNo;
  final String? runDate;
  final String? depreciationFromDate;
  final String? depreciationToDate;
  final String? bookType;
  final String? runStatus;
  final int? voucherId;
  final String? totalAssetsProcessed;
  final double? totalDepreciationAmount;
  final String? notes;
  final String? errorMessage;
  final int? createdBy;
  final int? postedBy;
  final String? postedAt;
  final String? createdAt;
  final String? updatedAt;

  factory AssetDepreciationRunModel.fromJson(Map<String, dynamic> json) {
    return AssetDepreciationRunModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      runNo: json['run_no']?.toString(),
      runDate: json['run_date']?.toString(),
      depreciationFromDate: json['depreciation_from_date']?.toString(),
      depreciationToDate: json['depreciation_to_date']?.toString(),
      bookType: json['book_type']?.toString(),
      runStatus: json['run_status']?.toString(),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      totalAssetsProcessed: json['total_assets_processed']?.toString(),
      totalDepreciationAmount: JsonModel.nullableDouble(
        json['total_depreciation_amount'],
      ),
      notes: json['notes']?.toString(),
      errorMessage: json['error_message']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    runNo,
    runDate,
    depreciationFromDate,
  ], defaultValue: 'Asset Depreciation Run');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (runNo != null) 'run_no': runNo,
    if (runDate != null) 'run_date': runDate,
    if (depreciationFromDate != null)
      'depreciation_from_date': depreciationFromDate,
    if (depreciationToDate != null) 'depreciation_to_date': depreciationToDate,
    if (bookType != null) 'book_type': bookType,
    if (runStatus != null) 'run_status': runStatus,
    if (voucherId != null) 'voucher_id': voucherId,
    if (totalAssetsProcessed != null)
      'total_assets_processed': totalAssetsProcessed,
    if (totalDepreciationAmount != null)
      'total_depreciation_amount': totalDepreciationAmount,
    if (notes != null) 'notes': notes,
    if (errorMessage != null) 'error_message': errorMessage,
    if (createdBy != null) 'created_by': createdBy,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
