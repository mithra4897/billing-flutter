import '../common/json_model.dart';

class PartyContactModel implements JsonModel {
  const PartyContactModel({
    this.id,
    this.partyId,
    this.contactName,
    this.designation,
    this.mobile,
    this.phone,
    this.email,
    this.isPrimary = false,
    this.isActive = true,
    this.raw,
  });

  final int? id;
  final int? partyId;
  final String? contactName;
  final String? designation;
  final String? mobile;
  final String? phone;
  final String? email;
  final bool isPrimary;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory PartyContactModel.fromJson(Map<String, dynamic> json) {
    return PartyContactModel(
      id: _parseInt(json['id']),
      partyId: _parseInt(json['party_id']),
      contactName: json['contact_name']?.toString() ?? json['name']?.toString(),
      designation: json['designation']?.toString(),
      mobile: json['mobile']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      isPrimary: json['is_primary'] == true || json['is_primary'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (partyId != null) 'party_id': partyId,
      if (contactName != null) 'contact_name': contactName,
      if (designation != null) 'designation': designation,
      if (mobile != null) 'mobile': mobile,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'is_primary': isPrimary,
      'is_active': isActive,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return int.tryParse(value.toString());
  }
}
