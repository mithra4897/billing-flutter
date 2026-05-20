import '../../screen.dart';

class AmcContractAssetModel extends JsonModel {
  const AmcContractAssetModel({
    super.id,
    this.amcContractId,
    this.assetId,
    this.coverageNotes,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  final int? amcContractId;
  final int? assetId;
  final String? coverageNotes;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory AmcContractAssetModel.fromJson(Map<String, dynamic> json) {
    return AmcContractAssetModel(
      id: JsonModel.nullableInt(json['id']),
      amcContractId: JsonModel.nullableInt(json['amc_contract_id']),
      assetId: JsonModel.nullableInt(json['asset_id']),
      coverageNotes: json['coverage_notes']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Amc Contract Asset';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (amcContractId != null) 'amc_contract_id': amcContractId,
    if (assetId != null) 'asset_id': assetId,
    if (coverageNotes != null) 'coverage_notes': coverageNotes,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
