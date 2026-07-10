import '../../../screen.dart';

class DocumentTaxLinesRegisterManagementController extends GetxController {
  DocumentTaxLinesRegisterManagementController();

  final TaxesService taxesService = TaxesService();
  final MasterService masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  bool initialLoading = true;
  bool loading = false;
  String? pageError;
  List<DocumentTaxLineModel> rows = const <DocumentTaxLineModel>[];
  PaginationMeta? meta;
  int page = 1;
  int perPage = 20;

  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  int? companyId;
  int? branchId;
  int? financialYearId;

  @override
  void onInit() {
    super.onInit();
    final today = displayTodayDate();
    dateFromController.text = today;
    dateToController.text = today;
    bootstrap();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    dateFromController.dispose();
    dateToController.dispose();
    searchController.dispose();
    super.onClose();
  }

  List<FinancialYearModel> get financialYearOptions => financialYears
      .where(
        (FinancialYearModel year) =>
            companyId == null ||
            year.companyId == null ||
            year.companyId == companyId,
      )
      .toList(growable: false);

  PaginationMeta get effectiveMeta =>
      meta ??
      PaginationMeta(
        currentPage: page,
        lastPage: 1,
        perPage: perPage,
        total: rows.length,
      );

  Future<void> bootstrap() async {
    initialLoading = true;
    pageError = null;
    update();
    try {
      final results = await Future.wait<dynamic>([
        masterService.companies(
          filters: const {'per_page': 200, 'sort_by': 'legal_name'},
        ),
        masterService.branches(
          filters: const {'per_page': 500, 'sort_by': 'name'},
        ),
        masterService.financialYears(
          filters: const {'per_page': 200, 'sort_by': 'start_date'},
        ),
      ]);

      final companies =
          (results[0] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (results[1] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final years =
          (results[2] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];

      final activeCompanies = companies
          .where((CompanyModel item) => item.isActive)
          .toList(growable: false);
      final activeBranches = branches
          .where((BranchModel item) => item.isActive)
          .toList(growable: false);
      final activeYears = years
          .where((FinancialYearModel item) => item.isActive != false)
          .toList(growable: false);

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: activeBranches,
            locations: const <BusinessLocationModel>[],
            financialYears: activeYears,
          );

      financialYears = activeYears;
      companyId = contextSelection.companyId;
      branchId = contextSelection.branchId;
      financialYearId = contextSelection.financialYearId;
      initialLoading = false;
      update();
      await fetch(resetPage: true);
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
      update();
    }
  }

  Future<void> fetch({bool resetPage = false}) async {
    if (companyId == null) {
      pageError = 'Company is required.';
      update();
      return;
    }
    if (resetPage) {
      page = 1;
    }
    loading = true;
    pageError = null;
    update();
    try {
      final filters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'company_id': companyId,
        'sort_by': 'document_date',
        'sort_order': 'desc',
      };
      if (branchId != null) {
        filters['branch_id'] = branchId;
      }
      if (financialYearId != null) {
        filters['financial_year_id'] = financialYearId;
      }
      final from = dateFromController.text.trim();
      final to = dateToController.text.trim();
      if (from.length == 10) {
        filters['document_date_from'] = from;
      }
      if (to.length == 10) {
        filters['document_date_to'] = to;
      }
      final query = searchController.text.trim();
      if (query.isNotEmpty) {
        filters['search'] = query;
      }

      final response = await taxesService.documentTaxLines(filters: filters);
      rows = response.data ?? const <DocumentTaxLineModel>[];
      meta = response.meta;
      loading = false;
    } catch (error) {
      loading = false;
      pageError = error.toString();
    }
    update();
  }

  void setFinancialYearId(int? value) {
    financialYearId = value;
    update();
  }

  void clearFilters() {
    branchId = null;
    financialYearId = null;
    dateFromController.clear();
    dateToController.clear();
    searchController.clear();
    update();
  }

  void setPerPage(int value) {
    perPage = value;
    update();
  }

  void setPage(int value) {
    page = value;
    update();
  }

  String cell(DocumentTaxLineModel row, String key) {
    final dynamic value = row.toJson()[key];
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  String itemLabel(DocumentTaxLineModel row) {
    final dynamic item = row.toJson()['item'];
    if (item is Map<String, dynamic>) {
      return item['item_name']?.toString() ??
          item['item_code']?.toString() ??
          '';
    }
    return '';
  }

  String taxLabel(DocumentTaxLineModel row) {
    final dynamic tax = row.toJson()['tax_code'];
    if (tax is Map<String, dynamic>) {
      return tax['tax_name']?.toString() ?? tax['tax_code']?.toString() ?? '';
    }
    return '';
  }
}
