import '../common/json_model.dart';
import 'jobwork_dispatch_line_model.dart';

class JobworkDispatchModel implements JsonModel {
  const JobworkDispatchModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.dispatchNo = '',
    this.dispatchDate = '',
    this.jobworkOrderId,
    this.supplierPartyId,
    this.warehouseId,
    this.dcNo,
    this.dcDate,
    this.vehicleNo,
    this.transporterPartyId,
    this.lrNo,
    this.lrDate,
    this.dispatchStatus = 'draft',
    this.remarks,
    this.isActive = true,
    this.lines = const <JobworkDispatchLineModel>[],
    this.rawSupplier,
    this.rawJobworkOrder,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String dispatchNo;
  final String dispatchDate;
  final int? jobworkOrderId;
  final int? supplierPartyId;
  final int? warehouseId;
  final String? dcNo;
  final String? dcDate;
  final String? vehicleNo;
  final int? transporterPartyId;
  final String? lrNo;
  final String? lrDate;
  final String dispatchStatus;
  final String? remarks;
  final bool isActive;
  final List<JobworkDispatchLineModel> lines;
  final Map<String, dynamic>? rawSupplier;
  final Map<String, dynamic>? rawJobworkOrder;

  factory JobworkDispatchModel.fromJson(Map<String, dynamic> json) {
    final ln = json['lines'];
    return JobworkDispatchModel(
      id: _i(json['id']),
      companyId: _i(json['company_id']),
      branchId: _i(json['branch_id']),
      locationId: _i(json['location_id']),
      financialYearId: _i(json['financial_year_id']),
      documentSeriesId: _i(json['document_series_id']),
      dispatchNo: json['dispatch_no']?.toString() ?? '',
      dispatchDate: _date(json['dispatch_date']),
      jobworkOrderId: _i(json['jobwork_order_id']),
      supplierPartyId: _i(json['supplier_party_id']),
      warehouseId: _i(json['warehouse_id']),
      dcNo: json['dc_no']?.toString(),
      dcDate: json['dc_date'] != null ? _date(json['dc_date']) : null,
      vehicleNo: json['vehicle_no']?.toString(),
      transporterPartyId: _i(json['transporter_party_id']),
      lrNo: json['lr_no']?.toString(),
      lrDate: json['lr_date'] != null ? _date(json['lr_date']) : null,
      dispatchStatus: json['dispatch_status']?.toString() ?? 'draft',
      remarks: json['remarks']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      lines: ln is List
          ? ln
                .whereType<Map>()
                .map(
                  (e) => JobworkDispatchLineModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const <JobworkDispatchLineModel>[],
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
    if (dispatchNo.trim().isNotEmpty) 'dispatch_no': dispatchNo.trim(),
    'dispatch_date': dispatchDate.trim(),
    'jobwork_order_id': jobworkOrderId,
    'supplier_party_id': supplierPartyId,
    'warehouse_id': warehouseId,
    if (dcNo != null && dcNo!.trim().isNotEmpty) 'dc_no': dcNo!.trim(),
    if (dcDate != null && dcDate!.trim().isNotEmpty) 'dc_date': dcDate!.trim(),
    if (vehicleNo != null && vehicleNo!.trim().isNotEmpty)
      'vehicle_no': vehicleNo!.trim(),
    if (transporterPartyId != null)
      'transporter_party_id': transporterPartyId,
    if (lrNo != null && lrNo!.trim().isNotEmpty) 'lr_no': lrNo!.trim(),
    if (lrDate != null && lrDate!.trim().isNotEmpty) 'lr_date': lrDate!.trim(),
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
      dispatchNo.trim().isNotEmpty ? dispatchNo.trim() : 'New dispatch';

  static int? _i(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is int) {
      return v;
    }
    return int.tryParse(v.toString());
  }

  static String _date(dynamic v) {
    if (v == null) {
      return '';
    }
    return v.toString().trim().split('T').first.split(' ').first;
  }
}
