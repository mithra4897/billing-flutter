import '../common/json_model.dart';
import '../common/model_value.dart';

class ModuleModel implements JsonModel {
  const ModuleModel({
    this.moduleCode,
    this.moduleName,
    this.moduleGroup,
    this.routePath,
    this.iconKey,
    this.description,
    this.sortOrder,
    this.userSortOrder,
    this.effectiveSortOrder,
    this.isHidden,
    this.isActive,
    this.raw,
  });

  final String? moduleCode;
  final String? moduleName;
  final String? moduleGroup;
  final String? routePath;
  final String? iconKey;
  final String? description;
  final int? sortOrder;
  final int? userSortOrder;
  final int? effectiveSortOrder;
  final bool? isHidden;
  final bool? isActive;
  final Map<String, dynamic>? raw;

  @override
  String toString() => moduleName ?? moduleCode ?? 'New Module';

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      moduleCode: json['module_code']?.toString(),
      moduleName: json['module_name']?.toString(),
      moduleGroup: json['module_group']?.toString(),
      routePath: json['route_path']?.toString(),
      iconKey: json['icon_key']?.toString(),
      description: json['description']?.toString(),
      sortOrder: ModelValue.nullableInt(json['sort_order']),
      userSortOrder: ModelValue.nullableInt(json['user_sort_order']),
      effectiveSortOrder: ModelValue.nullableInt(json['effective_sort_order']),
      isHidden: json['is_hidden'] == null
          ? null
          : ModelValue.boolOf(json['is_hidden']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (moduleCode != null) 'module_code': moduleCode,
      if (moduleName != null) 'module_name': moduleName,
      if (moduleGroup != null) 'module_group': moduleGroup,
      if (routePath != null) 'route_path': routePath,
      if (iconKey != null) 'icon_key': iconKey,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (userSortOrder != null) 'user_sort_order': userSortOrder,
      if (effectiveSortOrder != null)
        'effective_sort_order': effectiveSortOrder,
      if (isHidden != null) 'is_hidden': isHidden,
      if (isActive != null) 'is_active': isActive,
    };
  }
}
