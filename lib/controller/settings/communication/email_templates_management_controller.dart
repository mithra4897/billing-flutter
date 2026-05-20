import '../../../screen.dart';

class EmailTemplatesManagementController extends GetxController {
  EmailTemplatesManagementController();

  final CommunicationService _communicationService = CommunicationService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController moduleController = TextEditingController();
  final TextEditingController eventCodeController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<AppDropdownItem<String>> documentTypeItems = const [
    AppDropdownItem(value: '', label: 'All'),
  ];
  List<EmailTemplateModel> records = const <EmailTemplateModel>[];
  List<EmailTemplateModel> filteredRecords = const <EmailTemplateModel>[];
  EmailTemplateModel? selectedRecord;
  int? contextCompanyId;
  int? companyId;
  String documentType = '';
  bool isHtml = true;
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
    codeController.dispose();
    nameController.dispose();
    moduleController.dispose();
    eventCodeController.dispose();
    subjectController.dispose();
    bodyController.dispose();
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
      final recordsResponse = await _communicationService.emailTemplates(
        filters: const {'per_page': 100},
      );

      final companies = companiesResponse.data ?? const <CompanyModel>[];
      final documentTypes =
          (documentSeriesResponse.data ?? const <DocumentSeriesModel>[])
              .map((item) => (item.documentType ?? '').trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final nextRecords = recordsResponse.data ?? const <EmailTemplateModel>[];
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
          ? nextRecords.cast<EmailTemplateModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedRecord == null
                ? (nextRecords.isNotEmpty ? nextRecords.first : null)
                : nextRecords.cast<EmailTemplateModel?>().firstWhere(
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

  List<EmailTemplateModel> _filterRecords(
    List<EmailTemplateModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (record) {
      return [
        stringValue(record.toJson(), 'template_code'),
        stringValue(record.toJson(), 'template_name'),
        stringValue(record.toJson(), 'module'),
        stringValue(record.toJson(), 'event_code'),
      ];
    });
  }

  void _applySearch() {
    filteredRecords = _filterRecords(records, searchController.text);
    update();
  }

  void selectRecord(EmailTemplateModel record, {bool notify = true}) {
    final data = record.toJson();
    selectedRecord = record;
    companyId = intValue(data, 'company_id');
    codeController.text = stringValue(data, 'template_code');
    nameController.text = stringValue(data, 'template_name');
    moduleController.text = stringValue(data, 'module');
    documentType = stringValue(data, 'document_type');
    eventCodeController.text = stringValue(data, 'event_code');
    subjectController.text = stringValue(data, 'subject_template');
    bodyController.text = stringValue(data, 'body_template');
    isHtml = boolValue(data, 'is_html', fallback: true);
    isActive = boolValue(data, 'is_active', fallback: true);
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedRecord = null;
    companyId = contextCompanyId;
    codeController.clear();
    nameController.clear();
    moduleController.clear();
    documentType = '';
    eventCodeController.clear();
    subjectController.clear();
    bodyController.clear();
    isHtml = true;
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

  void setIsHtml(bool value) {
    isHtml = value;
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

    final body = EmailTemplateModel.fromJson({
      if (intValue(selectedRecord?.toJson() ?? const {}, 'id') != null)
        'id': intValue(selectedRecord!.toJson(), 'id'),
      if (companyId != null) 'company_id': companyId,
      'template_code': codeController.text.trim(),
      'template_name': nameController.text.trim(),
      'module': moduleController.text.trim(),
      'document_type': nullIfEmpty(documentType),
      'event_code': nullIfEmpty(eventCodeController.text),
      'subject_template': subjectController.text.trim(),
      'body_template': bodyController.text.trim(),
      'is_html': isHtml,
      'is_active': isActive,
    });

    try {
      final id = intValue(selectedRecord?.toJson() ?? const {}, 'id');
      final response = id == null
          ? await _communicationService.createEmailTemplate(body)
          : await _communicationService.updateEmailTemplate(id, body);

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

  Future<void> delete() async {
    final id = intValue(selectedRecord?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _communicationService.deleteEmailTemplate(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage();
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  void startNewTemplate({required bool isDesktop}) {
    resetForm();

    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}
