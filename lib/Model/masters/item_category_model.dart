import '../common/json_model.dart';

class ItemCategoryModel implements JsonModel {
  const ItemCategoryModel({
    this.id,
    this.categoryCode = '',
    this.categoryName = '',
    this.parentCategoryId,
    this.imagePath,
    this.isActive = true,
    this.remarks,
    this.raw,
  });

  final int? id;
  final String categoryCode;
  final String categoryName;
  final int? parentCategoryId;
  final String? imagePath;
  final bool isActive;
  final String? remarks;
  final Map<String, dynamic>? raw;

  @override
  String toString() =>
      categoryName.isNotEmpty ? categoryName : 'New Item Category';

  factory ItemCategoryModel.fromJson(Map<String, dynamic> json) {
    return ItemCategoryModel(
      id: _nullableInt(json['id']),
      categoryCode: json['category_code']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      parentCategoryId: _nullableInt(json['parent_category_id']),
      imagePath: json['image_path']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'category_code': categoryCode,
      'category_name': categoryName,
      'parent_category_id': parentCategoryId,
      'image_path': imagePath,
      'is_active': isActive,
      'remarks': remarks,
    };
  }

  static int? _nullableInt(dynamic value) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed == null || parsed == 0 ? null : parsed;
  }
}
