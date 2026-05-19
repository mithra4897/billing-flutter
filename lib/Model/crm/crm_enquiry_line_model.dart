import '../../screen.dart';

class CrmEnquiryLineModel extends JsonModel {
  const CrmEnquiryLineModel({
    super.id,
    this.enquiryId,
    this.itemId,
    this.description,
    this.qty,
    this.createdAt,
    this.updatedAt,
  });
  final int? enquiryId;
  final int? itemId;
  final String? description;
  final double? qty;
  final String? createdAt;
  final String? updatedAt;

  factory CrmEnquiryLineModel.fromJson(Map<String, dynamic> json) {
    return CrmEnquiryLineModel(
      id: ModelValue.nullableInt(json['id']),
      enquiryId: ModelValue.nullableInt(json['enquiry_id']),
      itemId: ModelValue.nullableInt(json['item_id']),
      description: json['description']?.toString(),
      qty: ModelValue.nullableDouble(json['qty']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Crm Enquiry Line';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (enquiryId != null) 'enquiry_id': enquiryId,
    if (itemId != null) 'item_id': itemId,
    if (description != null) 'description': description,
    if (qty != null) 'qty': qty,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
