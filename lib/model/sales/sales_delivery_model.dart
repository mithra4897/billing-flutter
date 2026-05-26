import '../../screen.dart';

class SalesDeliveryModel extends JsonModel {
  const SalesDeliveryModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.salesOrderId,
    this.deliveryNo,
    this.deliveryDate,
    this.customerPartyId,
    this.customerName,
    this.customer,
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
    this.lines = const <Map<String, dynamic>>[],
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final int? salesOrderId;
  final String? deliveryNo;
  final String? deliveryDate;
  final int? customerPartyId;
  final String? customerName;
  final Map<String, dynamic>? customer;
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
  final List<Map<String, dynamic>> lines;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory SalesDeliveryModel.fromJson(Map<String, dynamic> json) {
    return SalesDeliveryModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      salesOrderId: JsonModel.nullableInt(json['sales_order_id']),
      deliveryNo: json['delivery_no']?.toString(),
      deliveryDate: json['delivery_date']?.toString(),
      customerPartyId: JsonModel.nullableInt(json['customer_party_id']),
      customerName: json['customer_name']?.toString(),
      customer: JsonModel.mapOf(json['customer']),
      billingAddressId: JsonModel.nullableInt(json['billing_address_id']),
      shippingAddressId: JsonModel.nullableInt(json['shipping_address_id']),
      contactId: JsonModel.nullableInt(json['contact_id']),
      vehicleNo: json['vehicle_no']?.toString(),
      transporterPartyId: JsonModel.nullableInt(json['transporter_party_id']),
      lrNo: json['lr_no']?.toString(),
      lrDate: json['lr_date']?.toString(),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      deliveryStatus: json['delivery_status']?.toString(),
      notes: json['notes']?.toString(),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      lines: _mapLines(json['lines']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    deliveryNo,
    vehicleNo,
    deliveryDate,
  ], defaultValue: 'Sales Delivery');

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
    if (customerName != null) 'customer_name': customerName,
    if (customer != null) 'customer': customer,
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
    if (lines.isNotEmpty) 'lines': lines,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };

  static List<Map<String, dynamic>> _mapLines(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (line) => Map<String, dynamic>.from(
            line.map((key, entryValue) => MapEntry(key.toString(), entryValue)),
          ),
        )
        .toList(growable: false);
  }
}
