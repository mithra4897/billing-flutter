import '../../screen.dart';

class PostingRuleGroupModel extends JsonModel {
  const PostingRuleGroupModel({
    super.id,
    this.groupCode,
    this.groupName,
    this.documentType,
    this.triggerEvent,
    this.description,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final String? groupCode;
  final String? groupName;
  final String? documentType;
  final String? triggerEvent;
  final String? description;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory PostingRuleGroupModel.fromJson(Map<String, dynamic> json) {
    return PostingRuleGroupModel(
      id: JsonModel.nullableInt(json['id']),
      groupCode: json['group_code']?.toString(),
      groupName: json['group_name']?.toString(),
      documentType: json['document_type']?.toString(),
      triggerEvent: json['trigger_event']?.toString(),
      description: json['description']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Posting Rule Group';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (groupCode != null) 'group_code': groupCode,
    if (groupName != null) 'group_name': groupName,
    if (documentType != null) 'document_type': documentType,
    if (triggerEvent != null) 'trigger_event': triggerEvent,
    if (description != null) 'description': description,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
