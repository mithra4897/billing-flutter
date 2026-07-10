import '../../../screen.dart';

class EmailRulesManagementController extends GetxController {
  EmailRulesManagementController();

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
  final TextEditingController recipientEmailsController =
      TextEditingController();
  final TextEditingController ccEmailsController = TextEditingController();
  final TextEditingController bccEmailsController = TextEditingController();
  final TextEditingController subjectOverrideController =
      TextEditingController();
  final TextEditingController bodyOverrideController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<AppDropdownItem<String>> documentTypeItems = const [
    AppDropdownItem(value: '', label: 'All'),
  ];
  List<EmailTemplateModel> templates = const <EmailTemplateModel>[];
  List<EmailRuleModel> records = const <EmailRuleModel>[];
  List<EmailRuleModel> filteredRecords = const <EmailRuleModel>[];
  EmailRuleModel? selectedRecord;
  int? contextCompanyId;
  int? companyId;
  int? templateId;
  String documentType = '';
  bool autoEnabled = true;
  bool manualEnabled = true;
  bool sendToPartyEmail = true;
  bool sendToContactEmail = false;
  bool sendToAssignedUser = false;
  bool sendToOwnerUser = false;
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
    recipientEmailsController.dispose();
    ccEmailsController.dispose();
    bccEmailsController.dispose();
    subjectOverrideController.dispose();
    bodyOverrideController.dispose();
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
      final templatesResponse = await _communicationService.emailTemplates(
        filters: const {'per_page': 100},
      );
      final rulesResponse = await _communicationService.emailRules(
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
      final nextTemplates =
          templatesResponse.data ?? const <EmailTemplateModel>[];
      final nextRules = rulesResponse.data ?? const <EmailRuleModel>[];
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
      templates = nextTemplates;
      records = nextRules;
      filteredRecords = _filterRecords(nextRules, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? nextRules.cast<EmailRuleModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedRecord == null
                ? (nextRules.isNotEmpty ? nextRules.first : null)
                : nextRules.cast<EmailRuleModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(selectedRecord?.toJson() ?? const {}, 'id'),
                    orElse: () => nextRules.isNotEmpty ? nextRules.first : null,
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

  List<EmailRuleModel> _filterRecords(
    List<EmailRuleModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (record) {
      return [
        stringValue(record.toJson(), 'rule_code'),
        stringValue(record.toJson(), 'rule_name'),
        stringValue(record.toJson(), 'module'),
        stringValue(record.toJson(), 'event_code'),
      ];
    });
  }

  void _applySearch() {
    filteredRecords = _filterRecords(records, searchController.text);
    update();
  }

  void selectRecord(EmailRuleModel record, {bool notify = true}) {
    final data = record.toJson();
    selectedRecord = record;
    companyId = intValue(data, 'company_id');
    templateId = intValue(data, 'template_id');
    codeController.text = stringValue(data, 'rule_code');
    nameController.text = stringValue(data, 'rule_name');
    moduleController.text = stringValue(data, 'module');
    documentType = stringValue(data, 'document_type');
    eventCodeController.text = stringValue(data, 'event_code');
    recipientEmailsController.text = stringValue(data, 'recipient_emails');
    ccEmailsController.text = stringValue(data, 'cc_emails');
    bccEmailsController.text = stringValue(data, 'bcc_emails');
    subjectOverrideController.text = stringValue(data, 'subject_override');
    bodyOverrideController.text = stringValue(data, 'body_override');
    autoEnabled = boolValue(data, 'auto_enabled', fallback: true);
    manualEnabled = boolValue(data, 'manual_enabled', fallback: true);
    sendToPartyEmail = boolValue(data, 'send_to_party_email', fallback: true);
    sendToContactEmail = boolValue(data, 'send_to_contact_email');
    sendToAssignedUser = boolValue(data, 'send_to_assigned_user');
    sendToOwnerUser = boolValue(data, 'send_to_owner_user');
    isActive = boolValue(data, 'is_active', fallback: true);
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedRecord = null;
    companyId = contextCompanyId;
    templateId = null;
    codeController.clear();
    nameController.clear();
    moduleController.clear();
    documentType = '';
    eventCodeController.clear();
    recipientEmailsController.clear();
    ccEmailsController.clear();
    bccEmailsController.clear();
    subjectOverrideController.clear();
    bodyOverrideController.clear();
    autoEnabled = true;
    manualEnabled = true;
    sendToPartyEmail = true;
    sendToContactEmail = false;
    sendToAssignedUser = false;
    sendToOwnerUser = false;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  List<AppDropdownItem<int>> get templateItems => templates
      .map(
        (template) => AppDropdownItem<int>(
          value: intValue(template.toJson(), 'id') ?? 0,
          label: stringValue(
            template.toJson(),
            'template_name',
            stringValue(template.toJson(), 'template_code', 'Template'),
          ),
        ),
      )
      .toList(growable: false);

  void setDocumentType(String? value) {
    documentType = value ?? '';
    update();
  }

  void setTemplateId(int? value) {
    templateId = value;
    update();
  }

  void setAutoEnabled(bool value) {
    autoEnabled = value;
    update();
  }

  void setManualEnabled(bool value) {
    manualEnabled = value;
    update();
  }

  void setSendToPartyEmail(bool value) {
    sendToPartyEmail = value;
    update();
  }

  void setSendToContactEmail(bool value) {
    sendToContactEmail = value;
    update();
  }

  void setSendToAssignedUser(bool value) {
    sendToAssignedUser = value;
    update();
  }

  void setSendToOwnerUser(bool value) {
    sendToOwnerUser = value;
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

    final body = EmailRuleModel.fromJson(normalizeDatePayload({
      if (intValue(selectedRecord?.toJson() ?? const {}, 'id') != null)
        'id': intValue(selectedRecord!.toJson(), 'id'),
      if (companyId != null) 'company_id': companyId,
      'rule_code': codeController.text.trim(),
      'rule_name': nameController.text.trim(),
      'module': moduleController.text.trim(),
      'document_type': nullIfEmpty(documentType),
      'event_code': eventCodeController.text.trim(),
      if (templateId != null) 'template_id': templateId,
      'auto_enabled': autoEnabled,
      'manual_enabled': manualEnabled,
      'send_to_party_email': sendToPartyEmail,
      'send_to_contact_email': sendToContactEmail,
      'send_to_assigned_user': sendToAssignedUser,
      'send_to_owner_user': sendToOwnerUser,
      'recipient_emails': nullIfEmpty(recipientEmailsController.text),
      'cc_emails': nullIfEmpty(ccEmailsController.text),
      'bcc_emails': nullIfEmpty(bccEmailsController.text),
      'subject_override': nullIfEmpty(subjectOverrideController.text),
      'body_override': nullIfEmpty(bodyOverrideController.text),
      'is_active': isActive,
    }));

    try {
      final id = intValue(selectedRecord?.toJson() ?? const {}, 'id');
      final response = id == null
          ? await _communicationService.createEmailRule(body)
          : await _communicationService.updateEmailRule(id, body);

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
      final response = await _communicationService.deleteEmailRule(id);
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

  void startNewRule({required bool isDesktop}) {
    resetForm();

    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}
