import '../../screen.dart';

class UserLocationAccessModel implements JsonModel {
  const UserLocationAccessModel({
    this.id,
    this.userId,
    this.locationId,
    this.isDefault,
    this.canBill,
    this.canPurchase,
    this.canStockEntry,
    this.canAccountsEntry,
    this.canHrEntry,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? userId;
  final int? locationId;
  final bool? isDefault;
  final bool? canBill;
  final bool? canPurchase;
  final bool? canStockEntry;
  final bool? canAccountsEntry;
  final bool? canHrEntry;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory UserLocationAccessModel.fromJson(Map<String, dynamic> json) {
    return UserLocationAccessModel(
      id: ModelValue.nullableInt(json['id']),
      userId: ModelValue.nullableInt(json['user_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      isDefault: json['is_default'] == null
          ? null
          : ModelValue.boolOf(json['is_default']),
      canBill: json['can_bill'] == null
          ? null
          : ModelValue.boolOf(json['can_bill']),
      canPurchase: json['can_purchase'] == null
          ? null
          : ModelValue.boolOf(json['can_purchase']),
      canStockEntry: json['can_stock_entry'] == null
          ? null
          : ModelValue.boolOf(json['can_stock_entry']),
      canAccountsEntry: json['can_accounts_entry'] == null
          ? null
          : ModelValue.boolOf(json['can_accounts_entry']),
      canHrEntry: json['can_hr_entry'] == null
          ? null
          : ModelValue.boolOf(json['can_hr_entry']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'user_id': userId,
    if (locationId != null) 'location_id': locationId,
    if (isDefault != null) 'is_default': isDefault,
    if (canBill != null) 'can_bill': canBill,
    if (canPurchase != null) 'can_purchase': canPurchase,
    if (canStockEntry != null) 'can_stock_entry': canStockEntry,
    if (canAccountsEntry != null) 'can_accounts_entry': canAccountsEntry,
    if (canHrEntry != null) 'can_hr_entry': canHrEntry,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
