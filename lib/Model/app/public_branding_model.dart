import '../../screen.dart';

class PublicBrandingModel extends JsonModel {
  const PublicBrandingModel({
    required this.companyName,
    this.legalName,
    this.tradeName,
    this.logoPath,
    this.letterHeadPath,
    this.currentYear,
  }) : super(id: null);

  final String companyName;
  final String? legalName;
  final String? tradeName;
  final String? logoPath;
  final String? letterHeadPath;
  final int? currentYear;

  factory PublicBrandingModel.fromJson(Map<String, dynamic> json) {
    return PublicBrandingModel(
      companyName: json['company_name']?.toString() ?? 'Billing ERP',
      legalName: json['legal_name']?.toString(),
      tradeName: json['trade_name']?.toString(),
      logoPath: json['logo_path']?.toString(),
      letterHeadPath: json['letter_head_path']?.toString(),
      currentYear: int.tryParse(json['current_year']?.toString() ?? ''),
    );
  }
  @override
  String toString() => tradeName ?? legalName ?? companyName;

  @override
  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'legal_name': legalName,
      'trade_name': tradeName,
      'logo_path': logoPath,
      'letter_head_path': letterHeadPath,
      'current_year': currentYear,
    };
  }
}
