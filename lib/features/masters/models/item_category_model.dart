class ItemCategoryModel {
  const ItemCategoryModel({
    required this.id,
    required this.categoryCode,
    required this.categoryName,
    this.parentCategoryId,
    this.imagePath,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final String categoryCode;
  final String categoryName;
  final int? parentCategoryId;
  final String? imagePath;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory ItemCategoryModel.fromJson(Map<String, dynamic> json) {
    return ItemCategoryModel(
      id: _parseInt(json['id']),
      categoryCode: json['category_code']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      parentCategoryId: _nullableInt(json['parent_category_id']),
      imagePath: json['image_path']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed == null || parsed == 0 ? null : parsed;
  }
}
