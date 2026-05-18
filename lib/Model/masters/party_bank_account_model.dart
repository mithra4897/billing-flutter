import '../../screen.dart';

class PartyBankAccountModel implements JsonModel {
  const PartyBankAccountModel({
    this.id,
    this.partyId,
    this.accountHolderName,
    this.bankName,
    this.branchName,
    this.accountNumber,
    this.ifscCode,
    this.swiftCode,
    this.iban,
    this.upiId,
    this.isDefault,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? partyId;
  final String? accountHolderName;
  final String? bankName;
  final String? branchName;
  final String? accountNumber;
  final String? ifscCode;
  final String? swiftCode;
  final String? iban;
  final int? upiId;
  final bool? isDefault;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory PartyBankAccountModel.fromJson(Map<String, dynamic> json) {
    return PartyBankAccountModel(
      id: ModelValue.nullableInt(json['id']),
      partyId: ModelValue.nullableInt(json['party_id']),
      accountHolderName: json['account_holder_name']?.toString(),
      bankName: json['bank_name']?.toString(),
      branchName: json['branch_name']?.toString(),
      accountNumber: json['account_number']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),
      swiftCode: json['swift_code']?.toString(),
      iban: json['iban']?.toString(),
      upiId: ModelValue.nullableInt(json['upi_id']),
      isDefault: json['is_default'] == null
          ? null
          : ModelValue.boolOf(json['is_default']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (partyId != null) 'party_id': partyId,
    if (accountHolderName != null) 'account_holder_name': accountHolderName,
    if (bankName != null) 'bank_name': bankName,
    if (branchName != null) 'branch_name': branchName,
    if (accountNumber != null) 'account_number': accountNumber,
    if (ifscCode != null) 'ifsc_code': ifscCode,
    if (swiftCode != null) 'swift_code': swiftCode,
    if (iban != null) 'iban': iban,
    if (upiId != null) 'upi_id': upiId,
    if (isDefault != null) 'is_default': isDefault,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
