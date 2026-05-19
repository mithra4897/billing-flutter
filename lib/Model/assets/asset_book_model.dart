import '../../screen.dart';

class AssetBookModel extends JsonModel {
  const AssetBookModel({
    super.id,
    this.assetId,
    this.bookType,
    this.depreciationMethod,
    this.usefulLifeMonths,
    this.depreciationRate,
    this.capitalizationValue,
    this.salvageValue,
    this.depreciableValue,
    this.accumulatedDepreciation,
    this.netBookValue,
    this.depreciationStartDate,
    this.depreciationEndDate,
    this.lastDepreciationDate,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  final int? assetId;
  final String? bookType;
  final String? depreciationMethod;
  final String? usefulLifeMonths;
  final double? depreciationRate;
  final double? capitalizationValue;
  final double? salvageValue;
  final double? depreciableValue;
  final double? accumulatedDepreciation;
  final double? netBookValue;
  final String? depreciationStartDate;
  final String? depreciationEndDate;
  final String? lastDepreciationDate;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory AssetBookModel.fromJson(Map<String, dynamic> json) {
    return AssetBookModel(
      id: ModelValue.nullableInt(json['id']),
      assetId: ModelValue.nullableInt(json['asset_id']),
      bookType: json['book_type']?.toString(),
      depreciationMethod: json['depreciation_method']?.toString(),
      usefulLifeMonths: json['useful_life_months']?.toString(),
      depreciationRate: ModelValue.nullableDouble(json['depreciation_rate']),
      capitalizationValue: ModelValue.nullableDouble(
        json['capitalization_value'],
      ),
      salvageValue: ModelValue.nullableDouble(json['salvage_value']),
      depreciableValue: ModelValue.nullableDouble(json['depreciable_value']),
      accumulatedDepreciation: ModelValue.nullableDouble(
        json['accumulated_depreciation'],
      ),
      netBookValue: ModelValue.nullableDouble(json['net_book_value']),
      depreciationStartDate: json['depreciation_start_date']?.toString(),
      depreciationEndDate: json['depreciation_end_date']?.toString(),
      lastDepreciationDate: json['last_depreciation_date']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Asset Book';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (assetId != null) 'asset_id': assetId,
    if (bookType != null) 'book_type': bookType,
    if (depreciationMethod != null) 'depreciation_method': depreciationMethod,
    if (usefulLifeMonths != null) 'useful_life_months': usefulLifeMonths,
    if (depreciationRate != null) 'depreciation_rate': depreciationRate,
    if (capitalizationValue != null)
      'capitalization_value': capitalizationValue,
    if (salvageValue != null) 'salvage_value': salvageValue,
    if (depreciableValue != null) 'depreciable_value': depreciableValue,
    if (accumulatedDepreciation != null)
      'accumulated_depreciation': accumulatedDepreciation,
    if (netBookValue != null) 'net_book_value': netBookValue,
    if (depreciationStartDate != null)
      'depreciation_start_date': depreciationStartDate,
    if (depreciationEndDate != null)
      'depreciation_end_date': depreciationEndDate,
    if (lastDepreciationDate != null)
      'last_depreciation_date': lastDepreciationDate,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
