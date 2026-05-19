import '../../screen.dart';

class CrmOpportunityProductModel extends JsonModel {
  const CrmOpportunityProductModel({
    super.id,
    this.opportunityId,
    this.itemId,
    this.qty,
    this.estimatedPrice,
    this.createdAt,
    this.updatedAt,
  });
  final int? opportunityId;
  final int? itemId;
  final double? qty;
  final double? estimatedPrice;
  final String? createdAt;
  final String? updatedAt;

  factory CrmOpportunityProductModel.fromJson(Map<String, dynamic> json) {
    return CrmOpportunityProductModel(
      id: JsonModel.nullableInt(json['id']),
      opportunityId: JsonModel.nullableInt(json['opportunity_id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      qty: JsonModel.nullableDouble(json['qty']),
      estimatedPrice: JsonModel.nullableDouble(json['estimated_price']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Crm Opportunity Product';


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
