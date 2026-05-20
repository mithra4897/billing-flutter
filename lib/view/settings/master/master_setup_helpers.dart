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

String stringValue(
  Map<String, dynamic> data,
  String key, [
  String fallback = '',
]) {
  final value = data[key];
  if (value == null) {
    return fallback;
  }

  return value.toString();
}

String? nullableStringValue(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? intValue(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null || value.toString().trim().isEmpty) {
    return null;
  }

  return int.tryParse(value.toString());
}

double? doubleValue(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null || value.toString().trim().isEmpty) {
    return null;
  }

  return double.tryParse(value.toString());
}

bool boolValue(Map<String, dynamic> data, String key, {bool fallback = false}) {
  final value = data[key];
  if (value == null) {
    return fallback;
  }

  if (value is bool) {
    return value;
  }

  final normalized = value.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
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

  final seenIds = <int>{};
  return branches
      .where((branch) => branch.companyId == companyId)
      .where((branch) {
        final id = branch.id;
        if (id == null) {
          return false;
        }
        return seenIds.add(id);
      })
      .toList(growable: false);
}

List<BusinessLocationModel> locationsForBranch(
  List<BusinessLocationModel> locations,
  int? branchId,
) {
  if (branchId == null) {
    return const <BusinessLocationModel>[];
  }

  final seenIds = <int>{};
  return locations
      .where((location) => location.branchId == branchId)
      .where((location) {
        final id = location.id;
        if (id == null) {
          return false;
        }
        return seenIds.add(id);
      })
      .toList(growable: false);
}

bool containsMasterId<T>(List<T> items, int? id, int? Function(T item) idOf) {
  if (id == null) {
    return false;
  }

  return items.any((item) => idOf(item) == id);
}

List<FinancialYearModel> financialYearsForCompany(
  List<FinancialYearModel> financialYears,
  int? companyId,
) {
  return financialYears
      .where(
        (item) =>
            companyId == null ||
            item.companyId == null ||
            item.companyId == companyId,
      )
      .toList(growable: false);
}

int? defaultFinancialYearIdForCompany(
  List<FinancialYearModel> financialYears,
  int? companyId, {
  int? current,
}) {
  final scoped = financialYearsForCompany(financialYears, companyId);
  if (containsMasterId(scoped, current, (item) => item.id)) {
    return current;
  }
  final active = scoped.cast<FinancialYearModel?>().firstWhere(
    (item) => item?.isCurrent == true,
    orElse: () => null,
  );
  return active?.id ?? (scoped.isNotEmpty ? scoped.first.id : null);
}

WorkingContextSelection normalizedWorkingContextSelection({
  required List<CompanyModel> companies,
  required List<BranchModel> branches,
  required List<BusinessLocationModel> locations,
  required List<FinancialYearModel> financialYears,
  required int? companyId,
  required int? branchId,
  required int? locationId,
  required int? financialYearId,
}) {
  final resolvedCompanyId =
      containsMasterId(companies, companyId, (item) => item.id)
      ? companyId
      : (companies.isNotEmpty ? companies.first.id : null);
  final scopedBranches = branchesForCompany(branches, resolvedCompanyId);
  final resolvedBranchId =
      containsMasterId(scopedBranches, branchId, (item) => item.id)
      ? branchId
      : (scopedBranches.isNotEmpty ? scopedBranches.first.id : null);
  final scopedLocations = locationsForBranch(locations, resolvedBranchId);
  final resolvedLocationId =
      containsMasterId(scopedLocations, locationId, (item) => item.id)
      ? locationId
      : (scopedLocations.isNotEmpty ? scopedLocations.first.id : null);
  final resolvedFinancialYearId = defaultFinancialYearIdForCompany(
    financialYears,
    resolvedCompanyId,
    current: financialYearId,
  );

  return WorkingContextSelection(
    companyId: resolvedCompanyId,
    branchId: resolvedBranchId,
    locationId: resolvedLocationId,
    financialYearId: resolvedFinancialYearId,
  );
}

List<String> workingContextLabels({
  required List<CompanyModel> companies,
  required List<BranchModel> branches,
  required List<BusinessLocationModel> locations,
  required List<FinancialYearModel> financialYears,
  required int? companyId,
  required int? branchId,
  required int? locationId,
  required int? financialYearId,
}) {
  return <String>[
    companyNameById(companies, companyId),
    branchNameById(branches, branchId),
    locationNameById(locations, locationId),
    financialYears
            .cast<FinancialYearModel?>()
            .firstWhere(
              (item) => item?.id == financialYearId,
              orElse: () => null,
            )
            ?.toString() ??
        '',
  ].where((value) => value.trim().isNotEmpty).toList(growable: false);
}

List<DocumentSeriesModel> documentSeriesForContext({
  required List<DocumentSeriesModel> documentSeries,
  required String documentType,
  required int? companyId,
  required int? branchId,
  required int? locationId,
  required int? financialYearId,
}) {
  final options = documentSeries
      .where(
        (item) =>
            item.documentType == null || item.documentType == documentType,
      )
      .toList(growable: false);
  final matchLevels = <List<DocumentSeriesModel> Function()>[
    () => _matchingDocumentSeries(
      options,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
    ),
    () => _matchingDocumentSeries(
      options,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
      matchFinancialYear: false,
    ),
    () => _matchingDocumentSeries(
      options,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
      matchLocation: false,
      matchFinancialYear: false,
    ),
    () => _matchingDocumentSeries(
      options,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
      matchBranch: false,
      matchLocation: false,
      matchFinancialYear: false,
    ),
    () => options,
  ];

  for (final buildMatches in matchLevels) {
    final matches = buildMatches();
    if (matches.isNotEmpty) {
      return _defaultDocumentSeriesFirst(matches);
    }
  }

  return const <DocumentSeriesModel>[];
}

List<DocumentSeriesModel> _matchingDocumentSeries(
  List<DocumentSeriesModel> options, {
  required int? companyId,
  required int? branchId,
  required int? locationId,
  required int? financialYearId,
  bool matchBranch = true,
  bool matchLocation = true,
  bool matchFinancialYear = true,
}) {
  return options
      .where((item) {
        if (companyId != null &&
            item.companyId != null &&
            item.companyId != companyId) {
          return false;
        }
        if (matchBranch &&
            branchId != null &&
            item.branchId != null &&
            item.branchId != branchId) {
          return false;
        }
        if (matchLocation &&
            locationId != null &&
            item.locationId != null &&
            item.locationId != locationId) {
          return false;
        }
        if (matchFinancialYear &&
            financialYearId != null &&
            item.financialYearId != null &&
            item.financialYearId != financialYearId) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}

List<DocumentSeriesModel> _defaultDocumentSeriesFirst(
  List<DocumentSeriesModel> options,
) {
  return List<DocumentSeriesModel>.from(options)..sort((a, b) {
    if (a.isDefault != b.isDefault) {
      return a.isDefault ? -1 : 1;
    }
    return (a.id ?? 0).compareTo(b.id ?? 0);
  });
}
