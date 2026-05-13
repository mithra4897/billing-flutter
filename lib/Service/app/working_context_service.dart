import 'package:flutter/foundation.dart';

import '../../core/storage/session_storage.dart';
import '../../model/masters/branch_model.dart';
import '../../model/masters/business_location_model.dart';
import '../../model/masters/company_model.dart';
import '../../model/masters/financial_year_model.dart';
import '../master/master_service.dart';

class WorkingContextSelection {
  const WorkingContextSelection({
    required this.companyId,
    required this.branchId,
    required this.locationId,
    required this.financialYearId,
  });

  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
}

class WorkingContextSnapshot {
  const WorkingContextSnapshot({
    required this.selection,
    required this.companies,
    required this.branches,
    required this.locations,
    required this.financialYears,
  });

  final WorkingContextSelection selection;
  final List<CompanyModel> companies;
  final List<BranchModel> branches;
  final List<BusinessLocationModel> locations;
  final List<FinancialYearModel> financialYears;
}

class WorkingContextService {
  WorkingContextService._();

  static final WorkingContextService instance = WorkingContextService._();
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  final MasterService _masterService = MasterService();

  Future<WorkingContextSnapshot> loadSnapshot() async {
    final responses = await Future.wait<dynamic>([
      _masterService.companies(
        filters: const {'per_page': 200, 'sort_by': 'legal_name'},
      ),
      _masterService.branches(
        filters: const {'per_page': 300, 'sort_by': 'name'},
      ),
      _masterService.businessLocations(
        filters: const {'per_page': 300, 'sort_by': 'name'},
      ),
      _masterService.financialYears(
        filters: const {'per_page': 300, 'sort_by': 'fy_name'},
      ),
    ]);

    final companies =
        responses[0].data
            .whereType<CompanyModel>()
            .where((CompanyModel item) => item.isActive)
            .toList(growable: false);
    final branches =
        responses[1].data
            .whereType<BranchModel>()
            .where((BranchModel item) => item.isActive)
            .toList(growable: false);
    final locations =
        responses[2].data
            .whereType<BusinessLocationModel>()
            .where((BusinessLocationModel item) => item.isActive)
            .toList(growable: false);
    final financialYears =
        responses[3].data
            .whereType<FinancialYearModel>()
            .where((FinancialYearModel item) => item.isActive)
            .toList(growable: false);

    final selection = await resolveSelection(
      companies: companies,
      branches: branches,
      locations: locations,
      financialYears: financialYears,
    );

    return WorkingContextSnapshot(
      selection: selection,
      companies: companies,
      branches: branches,
      locations: locations,
      financialYears: financialYears,
    );
  }

  Future<WorkingContextSelection> resolveSelection({
    required List<CompanyModel> companies,
    required List<BranchModel> branches,
    required List<BusinessLocationModel> locations,
    required List<FinancialYearModel> financialYears,
    int? companyId,
    int? branchId,
    int? locationId,
    int? financialYearId,
  }) async {
    final storedCompanyId = companyId ?? await SessionStorage.getCurrentCompanyId();
    final storedBranchId = branchId ?? await SessionStorage.getCurrentBranchId();
    final storedLocationId =
        locationId ?? await SessionStorage.getCurrentLocationId();
    final storedFinancialYearId =
        financialYearId ?? await SessionStorage.getCurrentFinancialYearId();

    final resolvedCompanyId = _resolveCompanyId(companies, storedCompanyId);
    final scopedBranches = branches
        .where((BranchModel item) => resolvedCompanyId == null || item.companyId == resolvedCompanyId)
        .toList(growable: false);
    final resolvedBranchId = _resolveBranchId(
      scopedBranches,
      storedBranchId,
      forceSingleOption: resolvedCompanyId != null,
    );
    final scopedLocations = locations
        .where(
          (BusinessLocationModel item) =>
              (resolvedCompanyId == null || item.companyId == resolvedCompanyId) &&
              (resolvedBranchId == null || item.branchId == resolvedBranchId),
        )
        .toList(growable: false);
    final resolvedLocationId = _resolveLocationId(
      scopedLocations,
      storedLocationId,
      forceSingleOption: resolvedBranchId != null || resolvedCompanyId != null,
    );
    final scopedFinancialYears = financialYears
        .where((FinancialYearModel item) => resolvedCompanyId == null || item.companyId == resolvedCompanyId)
        .toList(growable: false);
    final resolvedFinancialYearId = _resolveFinancialYearId(
      scopedFinancialYears,
      storedFinancialYearId,
    );

    await SessionStorage.saveSelectedContext(
      companyId: resolvedCompanyId,
      branchId: resolvedBranchId,
      locationId: resolvedLocationId,
      financialYearId: resolvedFinancialYearId,
    );

    return WorkingContextSelection(
      companyId: resolvedCompanyId,
      branchId: resolvedBranchId,
      locationId: resolvedLocationId,
      financialYearId: resolvedFinancialYearId,
    );
  }

  Future<void> saveSelection(WorkingContextSelection selection) async {
    await SessionStorage.saveSelectedContext(
      companyId: selection.companyId,
      branchId: selection.branchId,
      locationId: selection.locationId,
      financialYearId: selection.financialYearId,
    );
    version.value++;
  }

  int? _resolveCompanyId(List<CompanyModel> companies, int? preferredId) {
    if (preferredId != null &&
        companies.any((CompanyModel item) => item.id == preferredId)) {
      return preferredId;
    }
    if (companies.isEmpty) {
      return null;
    }
    return companies.first.id;
  }

  int? _resolveBranchId(
    List<BranchModel> branches,
    int? preferredId, {
    bool forceSingleOption = false,
  }) {
    if (forceSingleOption && branches.length == 1) {
      return branches.first.id;
    }
    if (preferredId != null && branches.any((BranchModel item) => item.id == preferredId)) {
      return preferredId;
    }
    if (branches.isEmpty) {
      return null;
    }
    return branches.first.id;
  }

  int? _resolveLocationId(
    List<BusinessLocationModel> locations,
    int? preferredId, {
    bool forceSingleOption = false,
  }) {
    if (forceSingleOption && locations.length == 1) {
      return locations.first.id;
    }
    if (preferredId != null &&
        locations.any((BusinessLocationModel item) => item.id == preferredId)) {
      return preferredId;
    }
    if (locations.isEmpty) {
      return null;
    }
    return locations.first.id;
  }

  int? _resolveFinancialYearId(
    List<FinancialYearModel> financialYears,
    int? preferredId,
  ) {
    if (preferredId != null &&
        financialYears.any((FinancialYearModel item) => item.id == preferredId)) {
      return preferredId;
    }
    final current = financialYears.cast<FinancialYearModel?>().firstWhere(
      (item) => item?.isCurrent == true,
      orElse: () => null,
    );
    if (current?.id != null) {
      return current!.id;
    }
    if (financialYears.isEmpty) {
      return null;
    }
    return financialYears.first.id;
  }
}
