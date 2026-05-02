import '../common/json_model.dart';
import 'jobwork_order_material_model.dart';
import 'jobwork_order_output_model.dart';

/// Header + lines for `/jobwork/orders` API.
class JobworkOrderModel implements JsonModel {
  const JobworkOrderModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.jobworkNo = '',
    this.jobworkDate = '',
    this.supplierPartyId,
    this.processName = '',
    this.processType = 'other',
    this.sourceType = 'manual',
    this.sourceDocumentType,
    this.sourceDocumentId,
    this.issueWarehouseId,
    this.receiptWarehouseId,
    this.expectedReturnDate,
    this.jobworkStatus = 'draft',
    this.notes,
    this.isActive = true,
    this.materials = const <JobworkOrderMaterialModel>[],
    this.outputs = const <JobworkOrderOutputModel>[],
    this.rawSupplier,
    this.materialsCount,
    this.outputsCount,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;

  final String jobworkNo;
  final String jobworkDate;

  final int? supplierPartyId;
  final String processName;
  final String processType;

  final String sourceType;
  final String? sourceDocumentType;
  final int? sourceDocumentId;

  final int? issueWarehouseId;
  final int? receiptWarehouseId;

  final String? expectedReturnDate;

  final String jobworkStatus;
  final String? notes;
  final bool isActive;

  final List<JobworkOrderMaterialModel> materials;
  final List<JobworkOrderOutputModel> outputs;

  /// Present on list responses; used for UI only.
  final Map<String, dynamic>? rawSupplier;

  final int? materialsCount;
  final int? outputsCount;

  factory JobworkOrderModel.fromJson(Map<String, dynamic> json) {
    final mats = json['materials'];
    final outs = json['outputs'];
    return JobworkOrderModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      branchId: _parseInt(json['branch_id']),
      locationId: _parseInt(json['location_id']),
      financialYearId: _parseInt(json['financial_year_id']),
      documentSeriesId: _parseInt(json['document_series_id']),
      jobworkNo: json['jobwork_no']?.toString() ?? '',
      jobworkDate: _datePart(json['jobwork_date']),
      supplierPartyId: _parseInt(json['supplier_party_id']),
      processName: json['process_name']?.toString() ?? '',
      processType: json['process_type']?.toString() ?? 'other',
      sourceType: json['source_type']?.toString() ?? 'manual',
      sourceDocumentType: json['source_document_type']?.toString(),
      sourceDocumentId: _parseInt(json['source_document_id']),
      issueWarehouseId: _parseInt(json['issue_warehouse_id']),
      receiptWarehouseId: _parseInt(json['receipt_warehouse_id']),
      expectedReturnDate: json['expected_return_date'] != null
          ? _datePart(json['expected_return_date'])
          : null,
      jobworkStatus: json['jobwork_status']?.toString() ?? 'draft',
      notes: json['notes']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      materials: mats is List
          ? mats
                .whereType<Map>()
                .map(
                  (e) => JobworkOrderMaterialModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const <JobworkOrderMaterialModel>[],
      outputs: outs is List
          ? outs
                .whereType<Map>()
                .map(
                  (e) => JobworkOrderOutputModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const <JobworkOrderOutputModel>[],
      rawSupplier: json['supplier'] is Map
          ? Map<String, dynamic>.from(json['supplier'] as Map)
          : null,
      materialsCount: _parseInt(json['materials_count']),
      outputsCount: _parseInt(json['outputs_count']),
    );
  }

  /// Save payload for POST/PUT jobwork orders.
  Map<String, dynamic> toDocumentPayload() {
    return <String, dynamic>{
      if (documentSeriesId != null) 'document_series_id': documentSeriesId,
      if (jobworkNo.trim().isNotEmpty) 'jobwork_no': jobworkNo.trim(),
      'jobwork_date': jobworkDate.trim(),
      'supplier_party_id': supplierPartyId,
      'process_name': processName.trim(),
      'process_type': processType,
      'source_type': sourceType,
      if (sourceDocumentType != null && sourceDocumentType!.trim().isNotEmpty)
        'source_document_type': sourceDocumentType!.trim(),
      if (sourceDocumentId != null) 'source_document_id': sourceDocumentId,
      'issue_warehouse_id': issueWarehouseId,
      'receipt_warehouse_id': receiptWarehouseId,
      if (expectedReturnDate != null && expectedReturnDate!.trim().isNotEmpty)
        'expected_return_date': expectedReturnDate!.trim(),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'is_active': isActive ? 1 : 0,
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'materials': materials.map((e) => e.toLinePayload()).toList(),
      'outputs': outputs.map((e) => e.toLinePayload()).toList(),
    };
  }

  /// Supplier display name when list/detail included `supplier` relation.
  String get supplierLabel {
    final map = rawSupplier;
    if (map == null || map.isEmpty) {
      return '';
    }
    final d = map['display_name'] ?? map['party_name'];
    return d?.toString().trim() ?? '';
  }

  @override
  Map<String, dynamic> toJson() => toDocumentPayload();

  @override
  String toString() =>
      jobworkNo.trim().isNotEmpty ? jobworkNo.trim() : 'New Jobwork Order';

  static int? _parseInt(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is int) {
      return v;
    }
    return int.tryParse(v.toString());
  }

  static String _datePart(dynamic v) {
    if (v == null) {
      return '';
    }
    final s = v.toString().trim();
    if (s.isEmpty) {
      return '';
    }
    return s.split('T').first.split(' ').first;
  }
}
