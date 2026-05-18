import '../../screen.dart';

class CrmStageModel implements JsonModel {
  const CrmStageModel({
    this.id,
    this.stageName,
    this.stageType,
    this.sequenceNo,
    this.probabilityPercent,
    this.isDefault,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final String? stageName;
  final String? stageType;
  final int? sequenceNo;
  final double? probabilityPercent;
  final bool? isDefault;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory CrmStageModel.fromJson(Map<String, dynamic> json) {
    return CrmStageModel(
      id: ModelValue.nullableInt(json['id']),
      stageName: json['stage_name']?.toString(),
      stageType: json['stage_type']?.toString(),
      sequenceNo: ModelValue.nullableInt(json['sequence_no']),
      probabilityPercent: ModelValue.nullableDouble(
        json['probability_percent'],
      ),
      isDefault: json['is_default'] == null
          ? null
          : ModelValue.boolOf(json['is_default']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (stageName != null) 'stage_name': stageName,
    if (stageType != null) 'stage_type': stageType,
    if (sequenceNo != null) 'sequence_no': sequenceNo,
    if (probabilityPercent != null) 'probability_percent': probabilityPercent,
    if (isDefault != null) 'is_default': isDefault,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
