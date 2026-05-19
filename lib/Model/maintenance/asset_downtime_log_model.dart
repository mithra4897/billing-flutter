import '../../screen.dart';

class AssetDowntimeLogModel extends JsonModel {
  const AssetDowntimeLogModel({
    super.id,
    this.assetId,
    this.maintenanceWorkOrderId,
    this.downtimeReason,
    this.downtimeStart,
    this.downtimeEnd,
    this.downtimeMinutes,
    this.productionImpactNotes,
    this.isPlanned,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? assetId;
  final int? maintenanceWorkOrderId;
  final String? downtimeReason;
  final String? downtimeStart;
  final String? downtimeEnd;
  final double? downtimeMinutes;
  final String? productionImpactNotes;
  final bool? isPlanned;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory AssetDowntimeLogModel.fromJson(Map<String, dynamic> json) {
    return AssetDowntimeLogModel(
      id: ModelValue.nullableInt(json['id']),
      assetId: ModelValue.nullableInt(json['asset_id']),
      maintenanceWorkOrderId: ModelValue.nullableInt(
        json['maintenance_work_order_id'],
      ),
      downtimeReason: json['downtime_reason']?.toString(),
      downtimeStart: json['downtime_start']?.toString(),
      downtimeEnd: json['downtime_end']?.toString(),
      downtimeMinutes: ModelValue.nullableDouble(json['downtime_minutes']),
      productionImpactNotes: json['production_impact_notes']?.toString(),
      isPlanned: json['is_planned'] == null
          ? null
          : ModelValue.boolOf(json['is_planned']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Asset Downtime Log';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (assetId != null) 'asset_id': assetId,
    if (maintenanceWorkOrderId != null)
      'maintenance_work_order_id': maintenanceWorkOrderId,
    if (downtimeReason != null) 'downtime_reason': downtimeReason,
    if (downtimeStart != null) 'downtime_start': downtimeStart,
    if (downtimeEnd != null) 'downtime_end': downtimeEnd,
    if (downtimeMinutes != null) 'downtime_minutes': downtimeMinutes,
    if (productionImpactNotes != null)
      'production_impact_notes': productionImpactNotes,
    if (isPlanned != null) 'is_planned': isPlanned,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
