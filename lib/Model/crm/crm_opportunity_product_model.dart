import '../../screen.dart';

class CrmOpportunityProductModel implements JsonModel {
  const CrmOpportunityProductModel({
    this.id,
    this.opportunityId,
    this.itemId,
    this.qty,
    this.estimatedPrice,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? opportunityId;
  final int? itemId;
  final double? qty;
  final double? estimatedPrice;
  final String? createdAt;
  final String? updatedAt;

  factory CrmOpportunityProductModel.fromJson(Map<String, dynamic> json) {
    return CrmOpportunityProductModel(
      id: ModelValue.nullableInt(json['id']),
      opportunityId: ModelValue.nullableInt(json['opportunity_id']),
      itemId: ModelValue.nullableInt(json['item_id']),
      qty: ModelValue.nullableDouble(json['qty']),
      estimatedPrice: ModelValue.nullableDouble(json['estimated_price']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (opportunityId != null) 'opportunity_id': opportunityId,
    if (itemId != null) 'item_id': itemId,
    if (qty != null) 'qty': qty,
    if (estimatedPrice != null) 'estimated_price': estimatedPrice,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
