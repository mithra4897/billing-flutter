import '../common/json_model.dart';
import 'jobwork_charge_line_model.dart';

class JobworkChargeModel implements JsonModel {
  const JobworkChargeModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.chargeNo = '',
    this.chargeDate = '',
    this.jobworkOrderId,
    this.supplierPartyId,
    this.purchaseInvoiceId,
    this.chargeStatus = 'draft',
    this.subtotal = 0,
    this.discountAmount = 0,
    this.taxableAmount = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.cessAmount = 0,
    this.roundOffAmount = 0,
    this.totalAmount = 0,
    this.remarks,
    this.isActive = true,
    this.lines = const <JobworkChargeLineModel>[],
    this.rawSupplier,
    this.rawJobworkOrder,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String chargeNo;
  final String chargeDate;
  final int? jobworkOrderId;
  final int? supplierPartyId;
  final int? purchaseInvoiceId;
  final String chargeStatus;
  final double subtotal;
  final double discountAmount;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double roundOffAmount;
  final double totalAmount;
  final String? remarks;
  final bool isActive;
  final List<JobworkChargeLineModel> lines;
  final Map<String, dynamic>? rawSupplier;
  final Map<String, dynamic>? rawJobworkOrder;

  factory JobworkChargeModel.fromJson(Map<String, dynamic> json) {
    final ln = json['lines'];
    return JobworkChargeModel(
      id: _i(json['id']),
      companyId: _i(json['company_id']),
      branchId: _i(json['branch_id']),
      locationId: _i(json['location_id']),
      financialYearId: _i(json['financial_year_id']),
      documentSeriesId: _i(json['document_series_id']),
      chargeNo: json['charge_no']?.toString() ?? '',
      chargeDate: _date(json['charge_date']),
      jobworkOrderId: _i(json['jobwork_order_id']),
      supplierPartyId: _i(json['supplier_party_id']),
      purchaseInvoiceId: _i(json['purchase_invoice_id']),
      chargeStatus: json['charge_status']?.toString() ?? 'draft',
      subtotal: _d(json['subtotal']) ?? 0,
      discountAmount: _d(json['discount_amount']) ?? 0,
      taxableAmount: _d(json['taxable_amount']) ?? 0,
      cgstAmount: _d(json['cgst_amount']) ?? 0,
      sgstAmount: _d(json['sgst_amount']) ?? 0,
      igstAmount: _d(json['igst_amount']) ?? 0,
      cessAmount: _d(json['cess_amount']) ?? 0,
      roundOffAmount: _d(json['round_off_amount']) ?? 0,
      totalAmount: _d(json['total_amount']) ?? 0,
      remarks: json['remarks']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      lines: ln is List
          ? ln
                .whereType<Map>()
                .map(
                  (e) => JobworkChargeLineModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const <JobworkChargeLineModel>[],
      rawSupplier: json['supplier'] is Map
          ? Map<String, dynamic>.from(json['supplier'] as Map)
          : null,
      rawJobworkOrder: json['jobwork_order'] is Map
          ? Map<String, dynamic>.from(json['jobwork_order'] as Map)
          : null,
    );
  }

  String get supplierLabel {
    final m = rawSupplier;
    if (m == null || m.isEmpty) {
      return '';
    }
    final d = m['display_name'] ?? m['party_name'];
    return d?.toString().trim() ?? '';
  }

  String get jobworkOrderNoLabel {
    final m = rawJobworkOrder;
    if (m == null) {
      return '';
    }
    return m['jobwork_no']?.toString().trim() ?? '';
  }

  Map<String, dynamic> toDocumentPayload() => <String, dynamic>{
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (chargeNo.trim().isNotEmpty) 'charge_no': chargeNo.trim(),
    'charge_date': chargeDate.trim(),
    'jobwork_order_id': jobworkOrderId,
    'supplier_party_id': supplierPartyId,
    if (purchaseInvoiceId != null)
      'purchase_invoice_id': purchaseInvoiceId,
    if (remarks != null && remarks!.trim().isNotEmpty)
      'remarks': remarks!.trim(),
    'is_active': isActive ? 1 : 0,
    'company_id': companyId,
    'branch_id': branchId,
    'location_id': locationId,
    'financial_year_id': financialYearId,
    'lines': lines.map((e) => e.toLinePayload()).toList(),
  };

  @override
  Map<String, dynamic> toJson() => toDocumentPayload();

  @override
  String toString() =>
      chargeNo.trim().isNotEmpty ? chargeNo.trim() : 'New charge';

  static int? _i(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is int) {
      return v;
    }
    return int.tryParse(v.toString());
  }

  static double? _d(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is num) {
      return v.toDouble();
    }
    return double.tryParse(v.toString());
  }

  static String _date(dynamic v) {
    if (v == null) {
      return '';
    }
    return v.toString().trim().split('T').first.split(' ').first;
  }
}
