import '../../screen.dart';

class SalesDeliveryReturnableDcModel extends JsonModel {
  const SalesDeliveryReturnableDcModel({
    super.id,
    this.salesDeliveryId,
    this.lineNo,
    this.itemId,
    this.itemName,
    this.uomId,
    this.description,
    this.qty,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? salesDeliveryId;
  final int? lineNo;
  final int? itemId;
  final String? itemName;
  final int? uomId;
  final String? description;
  final double? qty;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory SalesDeliveryReturnableDcModel.fromJson(Map<String, dynamic> json) {
    return SalesDeliveryReturnableDcModel(
      id: JsonModel.nullableInt(json['id']),
      salesDeliveryId: JsonModel.nullableInt(json['sales_delivery_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      itemName: json['item_name']?.toString(),
      uomId: JsonModel.nullableInt(json['uom_id']),
      description: json['description']?.toString(),
      qty: JsonModel.nullableDouble(json['qty']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (salesDeliveryId != null) 'sales_delivery_id': salesDeliveryId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (itemName != null) 'item_name': itemName,
    if (uomId != null) 'uom_id': uomId,
    if (description != null) 'description': description,
    if (qty != null) 'qty': qty,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
