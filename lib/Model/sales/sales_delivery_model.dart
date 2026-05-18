import '../../screen.dart';

class SalesDeliveryModel implements JsonModel {
  const SalesDeliveryModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.salesOrderId,
    this.deliveryNo,
    this.deliveryDate,
    this.customerPartyId,
    this.billingAddressId,
    this.shippingAddressId,
    this.contactId,
    this.vehicleNo,
    this.transporterPartyId,
    this.lrNo,
    this.lrDate,
    this.voucherId,
    this.deliveryStatus,
    this.notes,
    this.postedBy,
    this.postedAt,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final int? salesOrderId;
  final String? deliveryNo;
  final String? deliveryDate;
  final int? customerPartyId;
  final int? billingAddressId;
  final int? shippingAddressId;
  final int? contactId;
  final String? vehicleNo;
  final int? transporterPartyId;
  final String? lrNo;
  final String? lrDate;
  final int? voucherId;
  final String? deliveryStatus;
  final String? notes;
  final int? postedBy;
  final String? postedAt;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory SalesDeliveryModel.fromJson(Map<String, dynamic> json) {
    return SalesDeliveryModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      salesOrderId: ModelValue.nullableInt(json['sales_order_id']),
      deliveryNo: json['delivery_no']?.toString(),
      deliveryDate: json['delivery_date']?.toString(),
      customerPartyId: ModelValue.nullableInt(json['customer_party_id']),
      billingAddressId: ModelValue.nullableInt(json['billing_address_id']),
      shippingAddressId: ModelValue.nullableInt(json['shipping_address_id']),
      contactId: ModelValue.nullableInt(json['contact_id']),
      vehicleNo: json['vehicle_no']?.toString(),
      transporterPartyId: ModelValue.nullableInt(json['transporter_party_id']),
      lrNo: json['lr_no']?.toString(),
      lrDate: json['lr_date']?.toString(),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      deliveryStatus: json['delivery_status']?.toString(),
      notes: json['notes']?.toString(),
      postedBy: ModelValue.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (salesOrderId != null) 'sales_order_id': salesOrderId,
    if (deliveryNo != null) 'delivery_no': deliveryNo,
    if (deliveryDate != null) 'delivery_date': deliveryDate,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    if (billingAddressId != null) 'billing_address_id': billingAddressId,
    if (shippingAddressId != null) 'shipping_address_id': shippingAddressId,
    if (contactId != null) 'contact_id': contactId,
    if (vehicleNo != null) 'vehicle_no': vehicleNo,
    if (transporterPartyId != null) 'transporter_party_id': transporterPartyId,
    if (lrNo != null) 'lr_no': lrNo,
    if (lrDate != null) 'lr_date': lrDate,
    if (voucherId != null) 'voucher_id': voucherId,
    if (deliveryStatus != null) 'delivery_status': deliveryStatus,
    if (notes != null) 'notes': notes,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
