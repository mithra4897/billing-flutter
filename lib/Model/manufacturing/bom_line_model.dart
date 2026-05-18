import '../../screen.dart';

class BomLineModel implements JsonModel {
  const BomLineModel({
    this.id,
    this.bomId,
    this.lineNo,
    this.itemId,
    this.uomId,
    this.lineType,
    this.requiredQty,
    this.wastagePercent,
    this.netRequiredQty,
    this.issueStage,
    this.isBackflush,
    this.isOptional,
    this.standardRate,
    this.standardAmount,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? bomId;
  final int? lineNo;
  final int? itemId;
  final int? uomId;
  final String? lineType;
  final double? requiredQty;
  final double? wastagePercent;
  final double? netRequiredQty;
  final String? issueStage;
  final bool? isBackflush;
  final bool? isOptional;
  final double? standardRate;
  final double? standardAmount;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory BomLineModel.fromJson(Map<String, dynamic> json) {
    return BomLineModel(
      id: ModelValue.nullableInt(json['id']),
      bomId: ModelValue.nullableInt(json['bom_id']),
      lineNo: ModelValue.nullableInt(json['line_no']),
      itemId: ModelValue.nullableInt(json['item_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      lineType: json['line_type']?.toString(),
      requiredQty: ModelValue.nullableDouble(json['required_qty']),
      wastagePercent: ModelValue.nullableDouble(json['wastage_percent']),
      netRequiredQty: ModelValue.nullableDouble(json['net_required_qty']),
      issueStage: json['issue_stage']?.toString(),
      isBackflush: json['is_backflush'] == null
          ? null
          : ModelValue.boolOf(json['is_backflush']),
      isOptional: json['is_optional'] == null
          ? null
          : ModelValue.boolOf(json['is_optional']),
      standardRate: ModelValue.nullableDouble(json['standard_rate']),
      standardAmount: ModelValue.nullableDouble(json['standard_amount']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (bomId != null) 'bom_id': bomId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (uomId != null) 'uom_id': uomId,
    if (lineType != null) 'line_type': lineType,
    if (requiredQty != null) 'required_qty': requiredQty,
    if (wastagePercent != null) 'wastage_percent': wastagePercent,
    if (netRequiredQty != null) 'net_required_qty': netRequiredQty,
    if (issueStage != null) 'issue_stage': issueStage,
    if (isBackflush != null) 'is_backflush': isBackflush,
    if (isOptional != null) 'is_optional': isOptional,
    if (standardRate != null) 'standard_rate': standardRate,
    if (standardAmount != null) 'standard_amount': standardAmount,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
