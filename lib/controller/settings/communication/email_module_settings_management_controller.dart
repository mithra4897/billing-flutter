import '../../../screen.dart';

class EmailModuleSettingsManagementController extends GetxController {
  EmailModuleSettingsManagementController();

  final CommunicationService _communicationService = CommunicationService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController moduleController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<AppDropdownItem<String>> documentTypeItems = const [
    AppDropdownItem(value: '', label: 'All'),
  ];
  List<EmailModuleSettingModel> records = const <EmailModuleSettingModel>[];
  List<EmailModuleSettingModel> filteredRecords =
      const <EmailModuleSettingModel>[];
  EmailModuleSettingModel? selectedRecord;
  int? contextCompanyId;
  int? companyId;
  String documentType = '';
  bool autoEmailEnabled = true;
  bool manualEmailEnabled = true;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadPage();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    moduleController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = records.isEmpty;
    pageError = null;
    update();

    try {
      final companiesResponse = await _masterService.companies(
        filters: const {'per_page': 100, 'sort_by': 'legal_name'},
      );
      final documentSeriesResponse = await _masterService.documentSeries(
        filters: const {'per_page': 500},
      );
      final recordsResponse = await _communicationService.emailModuleSettings();

      final companies = companiesResponse.data ?? const <CompanyModel>[];
      final documentTypes =
          (documentSeriesResponse.data ?? const <DocumentSeriesModel>[])
              .map((item) => (item.documentType ?? '').trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final nextRecords =
          recordsResponse.data ?? const <EmailModuleSettingModel>[];
      final activeCompanies = companies
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      contextCompanyId = contextSelection.companyId;
      documentTypeItems = [
        const AppDropdownItem(value: '', label: 'All'),
        ...documentTypes.map(
          (item) => AppDropdownItem(value: item, label: item),
        ),
      ];
      records = nextRecords;
      filteredRecords = _filterRecords(nextRecords, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? nextRecords.cast<EmailModuleSettingModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedRecord == null
                ? (nextRecords.isNotEmpty ? nextRecords.first : null)
                : nextRecords.cast<EmailModuleSettingModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(selectedRecord?.toJson() ?? const {}, 'id'),
                    orElse: () =>
                        nextRecords.isNotEmpty ? nextRecords.first : null,
                  ));

      if (selected != null) {
        selectRecord(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
    }

    update();
  }

  List<EmailModuleSettingModel> _filterRecords(
    List<EmailModuleSettingModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (record) {
      return [
        stringValue(record.toJson(), 'module'),
        stringValue(record.toJson(), 'document_type'),
        stringValue(record.toJson(), 'remarks'),
      ];
    });
  }

  void _applySearch() {
    filteredRecords = _filterRecords(records, searchController.text);
    update();
  }

  void selectRecord(EmailModuleSettingModel record, {bool notify = true}) {
    final data = record.toJson();
    selectedRecord = record;
    companyId = intValue(data, 'company_id');
    moduleController.text = stringValue(data, 'module');
    documentType = stringValue(data, 'document_type');
    remarksController.text = stringValue(data, 'remarks');
    autoEmailEnabled = boolValue(data, 'auto_email_enabled', fallback: true);
    manualEmailEnabled = boolValue(
      data,
      'manual_email_enabled',
      fallback: true,
    );
    isActive = boolValue(data, 'is_active', fallback: true);
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedRecord = null;
    companyId = contextCompanyId;
    moduleController.clear();
    documentType = '';
    remarksController.clear();
    autoEmailEnabled = true;
    manualEmailEnabled = true;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setDocumentType(String? value) {
    documentType = value ?? '';
    update();
  }

  void setAutoEmailEnabled(bool value) {
    autoEmailEnabled = value;
    update();
  }

  void setManualEmailEnabled(bool value) {
    manualEmailEnabled = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final body = EmailModuleSettingModel.fromJson({
      if (intValue(selectedRecord?.toJson() ?? const {}, 'id') != null)
        'id': intValue(selectedRecord!.toJson(), 'id'),
      if (companyId != null) 'company_id': companyId,
      'module': moduleController.text.trim(),
      'document_type': nullIfEmpty(documentType),
      'auto_email_enabled': autoEmailEnabled,
      'manual_email_enabled': manualEmailEnabled,
      'is_active': isActive,
      'remarks': nullIfEmpty(remarksController.text),
    });

    try {
      final id = intValue(selectedRecord?.toJson() ?? const {}, 'id');
      final response = id == null
          ? await _communicationService.createEmailModuleSetting(body)
          : await _communicationService.updateEmailModuleSetting(id, body);

      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: intValue(saved.toJson(), 'id'));
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  void startNewModuleSetting({required bool isDesktop}) {
    resetForm();

    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}
