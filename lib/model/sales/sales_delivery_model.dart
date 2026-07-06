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
    this.isDirectCustomer = false,
    this.directCustomerDetails,
    this.customerName,
    this.customer,
    this.billingAddressId,
    this.shippingAddressId,
    this.contactId,
    this.vehicleNo,
    this.transporterPartyId,
    this.lrNo,
    this.lrDate,
    this.deliveryKind,
    this.roundOffAmount,
    this.voucherId,
    this.deliveryStatus,
    this.cancelReason,
    this.notes,
    this.termsConditions,
    this.postedBy,
    this.postedAt,
    this.isActive,
    this.lines = const <Map<String, dynamic>>[],
    this.returnableDcs = const <Map<String, dynamic>>[],
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
  final bool isDirectCustomer;
  final String? directCustomerDetails;
  final String? customerName;
  final Map<String, dynamic>? customer;
  final int? billingAddressId;
  final int? shippingAddressId;
  final int? contactId;
  final String? vehicleNo;
  final int? transporterPartyId;
  final String? lrNo;
  final String? lrDate;
  final String? deliveryKind;
  final double? roundOffAmount;
  final int? voucherId;
  final String? deliveryStatus;
  final String? cancelReason;
  final String? notes;
  final String? termsConditions;
  final int? postedBy;
  final String? postedAt;
  final bool? isActive;
  final List<Map<String, dynamic>> lines;
  final List<Map<String, dynamic>> returnableDcs;
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
      isDirectCustomer:
          json['is_direct_customer'] == true || json['is_direct_customer'] == 1,
      directCustomerDetails: json['direct_customer_details']?.toString(),
      customerName: json['customer_name']?.toString(),
      customer: JsonModel.mapOf(json['customer']),
      billingAddressId: JsonModel.nullableInt(json['billing_address_id']),
      shippingAddressId: JsonModel.nullableInt(json['shipping_address_id']),
      contactId: JsonModel.nullableInt(json['contact_id']),
      vehicleNo: json['vehicle_no']?.toString(),
      transporterPartyId: JsonModel.nullableInt(json['transporter_party_id']),
      lrNo: json['lr_no']?.toString(),
      lrDate: json['lr_date']?.toString(),
      deliveryKind: json['delivery_kind']?.toString(),
      roundOffAmount: JsonModel.nullableDouble(json['round_off_amount']),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      deliveryStatus: json['delivery_status']?.toString(),
      cancelReason: json['cancel_reason']?.toString(),
      notes: json['notes']?.toString(),
      termsConditions: json['terms_conditions']?.toString(),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      lines: _mapLines(json['lines']),
      returnableDcs: _mapLines(json['returnable_dcs']),
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
    'is_direct_customer': isDirectCustomer,
    if (directCustomerDetails != null)
      'direct_customer_details': directCustomerDetails,
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
    if (deliveryKind != null) 'delivery_kind': deliveryKind,
    if (roundOffAmount != null) 'round_off_amount': roundOffAmount,
    if (voucherId != null) 'voucher_id': voucherId,
    if (deliveryStatus != null) 'delivery_status': deliveryStatus,
    if (cancelReason != null) 'cancel_reason': cancelReason,
    if (notes != null) 'notes': notes,
    if (termsConditions != null) 'terms_conditions': termsConditions,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (isActive != null) 'is_active': isActive,
    if (lines.isNotEmpty) 'lines': lines,
    'returnable_dcs': returnableDcs,
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
