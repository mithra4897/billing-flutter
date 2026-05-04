import '../common/json_model.dart';
import 'qc_plan_line_model.dart';

class QcPlanModel implements JsonModel {
  const QcPlanModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.planCode = '',
    this.planName = '',
    this.itemId,
    this.itemCategoryId,
    this.qcScope = 'all',
    this.samplingMethod,
    this.acceptanceBasis = 'all_pass',
    this.minPassPercent,
    this.approvalStatus = 'draft',
    this.effectiveFrom,
    this.effectiveTo,
    this.notes,
    this.isDefault = false,
    this.isActive = true,
    this.lines = const <QcPlanLineModel>[],
    this.rawItem,
    this.rawItemCategory,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final String planCode;
  final String planName;
  final int? itemId;
  final int? itemCategoryId;
  final String qcScope;
  final String? samplingMethod;
  final String acceptanceBasis;
  final double? minPassPercent;
  final String approvalStatus;
  final String? effectiveFrom;
  final String? effectiveTo;
  final String? notes;
  final bool isDefault;
  final bool isActive;
  final List<QcPlanLineModel> lines;
  final Map<String, dynamic>? rawItem;
  final Map<String, dynamic>? rawItemCategory;

  factory QcPlanModel.fromJson(Map<String, dynamic> json) {
    final ln = json['lines'];
    return QcPlanModel(
      id: _i(json['id']),
      companyId: _i(json['company_id']),
      branchId: _i(json['branch_id']),
      locationId: _i(json['location_id']),
      planCode: json['plan_code']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? '',
      itemId: _i(json['item_id']),
      itemCategoryId: _i(json['item_category_id']),
      qcScope: json['qc_scope']?.toString() ?? 'all',
      samplingMethod: json['sampling_method']?.toString(),
      acceptanceBasis: json['acceptance_basis']?.toString() ?? 'all_pass',
      minPassPercent: _d(json['min_pass_percent']),
      approvalStatus: json['approval_status']?.toString() ?? 'draft',
      effectiveFrom: _dateStr(json['effective_from']),
      effectiveTo: _dateStr(json['effective_to']),
      notes: json['notes']?.toString(),
      isDefault: _b(json['is_default']),
      isActive: json['is_active'] == null ? true : _b(json['is_active']),
      lines: ln is List
          ? ln
                .whereType<Map>()
                .map(
                  (e) => QcPlanLineModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const <QcPlanLineModel>[],
      rawItem: json['item'] is Map
          ? Map<String, dynamic>.from(json['item'] as Map)
          : null,
      rawItemCategory: json['item_category'] is Map
          ? Map<String, dynamic>.from(json['item_category'] as Map)
          : null,
    );
  }

  String get itemLabel {
    final m = rawItem;
    if (m == null || m.isEmpty) {
      return '';
    }
    final code = m['item_code']?.toString().trim() ?? '';
    final name = m['item_name']?.toString().trim() ?? '';
    if (code.isEmpty) {
      return name;
    }
    if (name.isEmpty) {
      return code;
    }
    return '$code · $name';
  }

  String get categoryLabel {
    final m = rawItemCategory;
    if (m == null || m.isEmpty) {
      return '';
    }
    final code = m['category_code']?.toString().trim() ?? '';
    final name = m['category_name']?.toString().trim() ?? '';
    if (code.isEmpty) {
      return name;
    }
    if (name.isEmpty) {
      return code;
    }
    return '$code · $name';
  }

  Map<String, dynamic> toDocumentPayload() => <String, dynamic>{
    'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    'plan_code': planCode.trim(),
    'plan_name': planName.trim(),
    if (itemId != null) 'item_id': itemId,
    if (itemCategoryId != null) 'item_category_id': itemCategoryId,
    'qc_scope': qcScope,
    if (samplingMethod != null && samplingMethod!.trim().isNotEmpty)
      'sampling_method': samplingMethod!.trim(),
    'acceptance_basis': acceptanceBasis,
    if (acceptanceBasis == 'min_pass_percent' && minPassPercent != null)
      'min_pass_percent': minPassPercent,
    if (approvalStatus.isNotEmpty) 'approval_status': approvalStatus,
    if (effectiveFrom != null && effectiveFrom!.trim().isNotEmpty)
      'effective_from': effectiveFrom!.trim(),
    if (effectiveTo != null && effectiveTo!.trim().isNotEmpty)
      'effective_to': effectiveTo!.trim(),
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    'is_default': isDefault ? 1 : 0,
    'is_active': isActive ? 1 : 0,
    'lines': lines.map((e) => e.toLinePayload()).toList(),
  };

  @override
  Map<String, dynamic> toJson() => toDocumentPayload();

  @override
  String toString() {
    final c = planCode.trim();
    if (c.isNotEmpty) {
      return c;
    }
    final n = planName.trim();
    if (n.isNotEmpty) {
      return n;
    }
    return 'New QC plan';
  }

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

  static bool _b(dynamic v) {
    if (v == null) {
      return false;
    }
    if (v is bool) {
      return v;
    }
    final s = v.toString();
    return s == '1' || s.toLowerCase() == 'true';
  }

  static String? _dateStr(dynamic v) {
    if (v == null) {
      return null;
    }
    return v.toString().trim().split('T').first.split(' ').first;
  }
}
