import '../../screen.dart';

class AssetDepreciationLineModel implements JsonModel {
  const AssetDepreciationLineModel({
    this.id,
    this.assetDepreciationRunId,
    this.assetBookId,
    this.assetId,
    this.depreciationFromDate,
    this.depreciationToDate,
    this.openingBookValue,
    this.depreciationAmount,
    this.closingBookValue,
    this.accumulatedDepreciationBefore,
    this.accumulatedDepreciationAfter,
    this.lineStatus,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? assetDepreciationRunId;
  final int? assetBookId;
  final int? assetId;
  final String? depreciationFromDate;
  final String? depreciationToDate;
  final double? openingBookValue;
  final double? depreciationAmount;
  final double? closingBookValue;
  final double? accumulatedDepreciationBefore;
  final double? accumulatedDepreciationAfter;
  final String? lineStatus;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory AssetDepreciationLineModel.fromJson(Map<String, dynamic> json) {
    return AssetDepreciationLineModel(
      id: ModelValue.nullableInt(json['id']),
      assetDepreciationRunId: ModelValue.nullableInt(
        json['asset_depreciation_run_id'],
      ),
      assetBookId: ModelValue.nullableInt(json['asset_book_id']),
      assetId: ModelValue.nullableInt(json['asset_id']),
      depreciationFromDate: json['depreciation_from_date']?.toString(),
      depreciationToDate: json['depreciation_to_date']?.toString(),
      openingBookValue: ModelValue.nullableDouble(json['opening_book_value']),
      depreciationAmount: ModelValue.nullableDouble(
        json['depreciation_amount'],
      ),
      closingBookValue: ModelValue.nullableDouble(json['closing_book_value']),
      accumulatedDepreciationBefore: ModelValue.nullableDouble(
        json['accumulated_depreciation_before'],
      ),
      accumulatedDepreciationAfter: ModelValue.nullableDouble(
        json['accumulated_depreciation_after'],
      ),
      lineStatus: json['line_status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (assetDepreciationRunId != null)
      'asset_depreciation_run_id': assetDepreciationRunId,
    if (assetBookId != null) 'asset_book_id': assetBookId,
    if (assetId != null) 'asset_id': assetId,
    if (depreciationFromDate != null)
      'depreciation_from_date': depreciationFromDate,
    if (depreciationToDate != null) 'depreciation_to_date': depreciationToDate,
    if (openingBookValue != null) 'opening_book_value': openingBookValue,
    if (depreciationAmount != null) 'depreciation_amount': depreciationAmount,
    if (closingBookValue != null) 'closing_book_value': closingBookValue,
    if (accumulatedDepreciationBefore != null)
      'accumulated_depreciation_before': accumulatedDepreciationBefore,
    if (accumulatedDepreciationAfter != null)
      'accumulated_depreciation_after': accumulatedDepreciationAfter,
    if (lineStatus != null) 'line_status': lineStatus,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
