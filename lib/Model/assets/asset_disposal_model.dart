import '../../screen.dart';

class AssetDisposalModel implements JsonModel {
  const AssetDisposalModel({
    this.id,
    this.assetId,
    this.disposalNo,
    this.disposalDate,
    this.disposalType,
    this.salePartyId,
    this.salesInvoiceId,
    this.disposalValue,
    this.disposalExpense,
    this.bookValueAtDisposal,
    this.gainOrLossAmount,
    this.disposalStatus,
    this.voucherId,
    this.remarks,
    this.approvedBy,
    this.approvedAt,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? assetId;
  final String? disposalNo;
  final String? disposalDate;
  final String? disposalType;
  final int? salePartyId;
  final int? salesInvoiceId;
  final double? disposalValue;
  final double? disposalExpense;
  final double? bookValueAtDisposal;
  final double? gainOrLossAmount;
  final String? disposalStatus;
  final int? voucherId;
  final String? remarks;
  final int? approvedBy;
  final String? approvedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory AssetDisposalModel.fromJson(Map<String, dynamic> json) {
    return AssetDisposalModel(
      id: ModelValue.nullableInt(json['id']),
      assetId: ModelValue.nullableInt(json['asset_id']),
      disposalNo: json['disposal_no']?.toString(),
      disposalDate: json['disposal_date']?.toString(),
      disposalType: json['disposal_type']?.toString(),
      salePartyId: ModelValue.nullableInt(json['sale_party_id']),
      salesInvoiceId: ModelValue.nullableInt(json['sales_invoice_id']),
      disposalValue: ModelValue.nullableDouble(json['disposal_value']),
      disposalExpense: ModelValue.nullableDouble(json['disposal_expense']),
      bookValueAtDisposal: ModelValue.nullableDouble(
        json['book_value_at_disposal'],
      ),
      gainOrLossAmount: ModelValue.nullableDouble(json['gain_or_loss_amount']),
      disposalStatus: json['disposal_status']?.toString(),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      remarks: json['remarks']?.toString(),
      approvedBy: ModelValue.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (assetId != null) 'asset_id': assetId,
    if (disposalNo != null) 'disposal_no': disposalNo,
    if (disposalDate != null) 'disposal_date': disposalDate,
    if (disposalType != null) 'disposal_type': disposalType,
    if (salePartyId != null) 'sale_party_id': salePartyId,
    if (salesInvoiceId != null) 'sales_invoice_id': salesInvoiceId,
    if (disposalValue != null) 'disposal_value': disposalValue,
    if (disposalExpense != null) 'disposal_expense': disposalExpense,
    if (bookValueAtDisposal != null)
      'book_value_at_disposal': bookValueAtDisposal,
    if (gainOrLossAmount != null) 'gain_or_loss_amount': gainOrLossAmount,
    if (disposalStatus != null) 'disposal_status': disposalStatus,
    if (voucherId != null) 'voucher_id': voucherId,
    if (remarks != null) 'remarks': remarks,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
