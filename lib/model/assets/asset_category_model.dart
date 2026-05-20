import '../../screen.dart';

class AssetCategoryModel extends JsonModel {
  const AssetCategoryModel({
    super.id,
    this.companyId,
    this.categoryCode,
    this.categoryName,
    this.parentCategoryId,
    this.assetType,
    this.capitalizationThreshold,
    this.defaultAssetAccountId,
    this.defaultAccumDepreciationAccountId,
    this.defaultDepreciationExpenseAccountId,
    this.defaultDisposalGainAccountId,
    this.defaultDisposalLossAccountId,
    this.defaultDepreciationMethod,
    this.defaultUsefulLifeMonths,
    this.defaultSalvageValue,
    this.isTagRequired,
    this.isSerialRequired,
    this.isDepreciable,
    this.isActive,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final String? categoryCode;
  final String? categoryName;
  final int? parentCategoryId;
  final String? assetType;
  final double? capitalizationThreshold;
  final int? defaultAssetAccountId;
  final int? defaultAccumDepreciationAccountId;
  final int? defaultDepreciationExpenseAccountId;
  final int? defaultDisposalGainAccountId;
  final int? defaultDisposalLossAccountId;
  final String? defaultDepreciationMethod;
  final String? defaultUsefulLifeMonths;
  final double? defaultSalvageValue;
  final bool? isTagRequired;
  final bool? isSerialRequired;
  final bool? isDepreciable;
  final bool? isActive;
  final String? remarks;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory AssetCategoryModel.fromJson(Map<String, dynamic> json) {
    return AssetCategoryModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      categoryCode: json['category_code']?.toString(),
      categoryName: json['category_name']?.toString(),
      parentCategoryId: JsonModel.nullableInt(json['parent_category_id']),
      assetType: json['asset_type']?.toString(),
      capitalizationThreshold: JsonModel.nullableDouble(
        json['capitalization_threshold'],
      ),
      defaultAssetAccountId: JsonModel.nullableInt(
        json['default_asset_account_id'],
      ),
      defaultAccumDepreciationAccountId: JsonModel.nullableInt(
        json['default_accum_depreciation_account_id'],
      ),
      defaultDepreciationExpenseAccountId: JsonModel.nullableInt(
        json['default_depreciation_expense_account_id'],
      ),
      defaultDisposalGainAccountId: JsonModel.nullableInt(
        json['default_disposal_gain_account_id'],
      ),
      defaultDisposalLossAccountId: JsonModel.nullableInt(
        json['default_disposal_loss_account_id'],
      ),
      defaultDepreciationMethod: json['default_depreciation_method']
          ?.toString(),
      defaultUsefulLifeMonths: json['default_useful_life_months']?.toString(),
      defaultSalvageValue: JsonModel.nullableDouble(
        json['default_salvage_value'],
      ),
      isTagRequired: json['is_tag_required'] == null
          ? null
          : JsonModel.boolOf(json['is_tag_required']),
      isSerialRequired: json['is_serial_required'] == null
          ? null
          : JsonModel.boolOf(json['is_serial_required']),
      isDepreciable: json['is_depreciable'] == null
          ? null
          : JsonModel.boolOf(json['is_depreciable']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      remarks: json['remarks']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    categoryName,
    categoryCode,
    assetType,
  ], defaultValue: 'Asset Category');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (categoryCode != null) 'category_code': categoryCode,
    if (categoryName != null) 'category_name': categoryName,
    if (parentCategoryId != null) 'parent_category_id': parentCategoryId,
    if (assetType != null) 'asset_type': assetType,
    if (capitalizationThreshold != null)
      'capitalization_threshold': capitalizationThreshold,
    if (defaultAssetAccountId != null)
      'default_asset_account_id': defaultAssetAccountId,
    if (defaultAccumDepreciationAccountId != null)
      'default_accum_depreciation_account_id':
          defaultAccumDepreciationAccountId,
    if (defaultDepreciationExpenseAccountId != null)
      'default_depreciation_expense_account_id':
          defaultDepreciationExpenseAccountId,
    if (defaultDisposalGainAccountId != null)
      'default_disposal_gain_account_id': defaultDisposalGainAccountId,
    if (defaultDisposalLossAccountId != null)
      'default_disposal_loss_account_id': defaultDisposalLossAccountId,
    if (defaultDepreciationMethod != null)
      'default_depreciation_method': defaultDepreciationMethod,
    if (defaultUsefulLifeMonths != null)
      'default_useful_life_months': defaultUsefulLifeMonths,
    if (defaultSalvageValue != null)
      'default_salvage_value': defaultSalvageValue,
    if (isTagRequired != null) 'is_tag_required': isTagRequired,
    if (isSerialRequired != null) 'is_serial_required': isSerialRequired,
    if (isDepreciable != null) 'is_depreciable': isDepreciable,
    if (isActive != null) 'is_active': isActive,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
