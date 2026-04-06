import '../../../screen.dart';

List<T> filterMasterList<T>(
  List<T> items,
  String query,
  List<String> Function(T item) textBuilder,
) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return items;
  }

  return items
      .where((item) {
        final haystack = textBuilder(item).join(' ').toLowerCase();
        return haystack.contains(trimmed);
      })
      .toList(growable: false);
}

String? nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String companyNameById(List<CompanyModel> companies, int? id) {
  return companies
          .cast<CompanyModel?>()
          .firstWhere((item) => item?.id == id, orElse: () => null)
          ?.legalName ??
      '';
}

String branchNameById(List<BranchModel> branches, int? id) {
  return branches
          .cast<BranchModel?>()
          .firstWhere((item) => item?.id == id, orElse: () => null)
          ?.name ??
      '';
}

String locationNameById(List<BusinessLocationModel> locations, int? id) {
  return locations
          .cast<BusinessLocationModel?>()
          .firstWhere((item) => item?.id == id, orElse: () => null)
          ?.name ??
      '';
}

List<BranchModel> branchesForCompany(
  List<BranchModel> branches,
  int? companyId,
) {
  if (companyId == null) {
    return const <BranchModel>[];
  }

  return branches
      .where((branch) => branch.companyId == companyId)
      .toList(growable: false);
}

List<BusinessLocationModel> locationsForBranch(
  List<BusinessLocationModel> locations,
  int? branchId,
) {
  if (branchId == null) {
    return const <BusinessLocationModel>[];
  }

  return locations
      .where((location) => location.branchId == branchId)
      .toList(growable: false);
}
