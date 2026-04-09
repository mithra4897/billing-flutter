import '../common/json_model.dart';

class VoucherTypeModel implements JsonModel {
  const VoucherTypeModel({
    this.id,
    this.code,
    this.name,
    this.voucherCategory,
    this.documentType,
    this.autoPost = true,
    this.requiresApproval = false,
    this.allowsReferenceAllocation = true,
    this.isSystemType = false,
    this.isActive = true,
    this.raw,
  });

  final int? id;
  final String? code;
  final String? name;
  final String? voucherCategory;
  final String? documentType;
  final bool autoPost;
  final bool requiresApproval;
  final bool allowsReferenceAllocation;
  final bool isSystemType;
  final bool isActive;
  final Map<String, dynamic>? raw;

  @override
  String toString() => name ?? code ?? 'New Voucher Type';

  factory VoucherTypeModel.fromJson(Map<String, dynamic> json) {
    return VoucherTypeModel(
      id: _nullableInt(json['id']),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
      voucherCategory: json['voucher_category']?.toString(),
      documentType: json['document_type']?.toString(),
      autoPost: _bool(json['auto_post'], fallback: true),
      requiresApproval: _bool(json['requires_approval']),
      allowsReferenceAllocation: _bool(
        json['allows_reference_allocation'],
        fallback: true,
      ),
      isSystemType: _bool(json['is_system_type']),
      isActive: _bool(json['is_active'], fallback: true),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (voucherCategory != null) 'voucher_category': voucherCategory,
      'document_type': documentType,
      'auto_post': autoPost,
      'requires_approval': requiresApproval,
      'allows_reference_allocation': allowsReferenceAllocation,
      'is_system_type': isSystemType,
      'is_active': isActive,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    return value == true || value == 1 || value.toString() == '1';
  }
}
